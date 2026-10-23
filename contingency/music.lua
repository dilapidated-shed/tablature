-- SPDX-License-Identifier: GPL-3.0-or-later
-- C+Lua contingency. This is a separately tested execution implementation;
-- it is never counted as Idriç parsing. regression-test.lua compares it with
-- live RegressionRows.idric output from the maintained checked Idriç core.
local music = {}
local letters = {"C", "D", "E", "F", "G", "A", "B"}
local natural_pitch = {0, 2, 4, 5, 7, 9, 11}
local letter_index = {C=0, D=1, E=2, F=3, G=4, A=5, B=6}
local step_policy = {0,0,1,1,2,3,3,4,4,5,5,6}
local idric_up, idric_down, idric_symbol

function music.use_idric(up, down, symbol)
  assert(type(up) == "function" and type(down) == "function" and type(symbol) == "function",
    "Qualified Idriç DEX operations are required by this Android candidate")
  idric_up, idric_down, idric_symbol = up, down, symbol
end

local function characters(text)
  local result = {}
  local passed = pcall(function()
    for _, scalar in utf8.codes(text) do result[#result+1] = utf8.char(scalar) end
  end)
  return passed and result or nil
end
local function concat(characters, first, last)
  return table.concat(characters, "", first or 1, last or #characters)
end
local function accidental(characters, index)
  local count = 0
  while index <= #characters do
    local symbol = characters[index]
    if idric_symbol and (symbol == "#" or symbol == "b") then symbol = idric_symbol(symbol) end
    if symbol == "#" or symbol == "♯" then count = count + 1
    elseif symbol == "b" or symbol == "♭" then count = count - 1
    elseif symbol == "𝄪" then count = count + 2
    elseif symbol == "𝄫" then count = count - 2
    else break end
    index = index + 1
  end
  return count, index
end
local function note(characters, index)
  local letter = letter_index[characters[index]]
  if letter == nil then return nil end
  local alteration, ending = accidental(characters, index + 1)
  return {letter=letter, accidental=alteration}, ending
end
local function accidental_text(value)
  return string.rep(value < 0 and "♭" or "♯", math.abs(value))
end
function music.print_note(note)
  return letters[note.letter+1] .. accidental_text(note.accidental)
end
function music.pitch(note)
  return (natural_pitch[note.letter+1] + note.accidental) % 12
end
function music.interval(semitones)
  local magnitude = math.abs(semitones)
  local steps = math.floor(magnitude / 12) * 7 + step_policy[magnitude % 12 + 1]
  return {letters=semitones < 0 and -steps or steps, semitones=semitones}
end
function music.key_interval(source, destination)
  local from, from_end = note(assert(characters(source)), 1)
  local to, to_end = note(assert(characters(destination)), 1)
  if not from or not to or from_end ~= utf8.len(source)+1 or to_end ~= utf8.len(destination)+1 then
    return nil, "Enter two written tonics, for example C♯ and D"
  end
  local octave = to.letter < from.letter and 1 or 0
  return {letters=(to.letter-from.letter)%7,
    semitones=natural_pitch[to.letter+1]+to.accidental+12*octave-natural_pitch[from.letter+1]-from.accidental}
end
function music.transpose_note(interval, written)
  local absolute_letter = written.letter + interval.letters
  local target = absolute_letter % 7
  local octave = math.floor(absolute_letter / 7)
  local moved = {letter=target, accidental=natural_pitch[written.letter+1] + written.accidental +
    interval.semitones - natural_pitch[target+1] - 12 * octave}
  if idric_up then
    -- Actual Android pitch-class motion executes checked Idriç DEX. Written
    -- letter/accidental selection remains an explicitly identified contingency.
    local sounding = music.pitch(written)
    local count = math.abs(interval.semitones) % 12
    for _ = 1, count do sounding = (interval.semitones < 0 and idric_down or idric_up)(sounding) end
    assert(sounding == music.pitch(moved), "Written spelling disagrees with the qualified Idriç pitch operation")
  end
  return moved
end
function music.transpose(interval, chord)
  local moved = {}
  for key, value in pairs(chord) do moved[key] = value end
  moved.root = music.transpose_note(interval, chord.root)
  if chord.bass then moved.bass = music.transpose_note(interval, chord.bass) end
  return moved
end

local qualities = {
  {"diminished", "diminished"}, {"major", "major", true}, {"minor", "minor"},
  {"maj", "major", true}, {"Maj", "major", true}, {"min", "minor"},
  {"dim", "diminished"}, {"aug", "augmented"}, {"Δ", "major", true},
  {"M", "major", true}, {"m", "minor"}, {"-", "minor"}, {"°", "diminished"},
  {"o", "diminished"}, {"ø", "half_diminished"}, {"+", "augmented"}
}
local function starts_with(characters, index, text)
  local prefix = assert(_G.utf8 and utf8.len(text))
  return concat(characters, index, math.min(#characters, index+prefix-1)) == text, prefix
end
local function degree(characters, index)
  for _, value in ipairs {13,11,9,7,6,5,4,3,2} do
    local text = tostring(value)
    if concat(characters, index, math.min(#characters, index+#text-1)) == text then return value, index+#text end
  end
end
function music.parse(text)
  local raw = characters(text)
  if not raw then return nil, "Invalid UTF-8" end
  local source, depth = {}, 0
  for _, character in ipairs(raw) do
    if character == "(" then depth = depth+1
    elseif character == ")" then depth=depth-1; if depth < 0 then return nil, "Unmatched parenthesis" end
    elseif character ~= "," or depth == 0 then source[#source+1] = character end
  end
  if depth ~= 0 then return nil, "Unclosed parenthesis" end
  local root, index = note(source, 1)
  if not root then return nil, "Expected a chord root" end
  local chord = {root=root, quality="major", additions={}, alterations={}}
  for _, quality in ipairs(qualities) do
    local matches, length = starts_with(source, index, quality[1])
    if matches then chord.quality=quality[2]; chord.major_seventh=quality[3]; index=index+length; break end
  end
  local extension, ending = degree(source, index)
  if extension then chord.extension=extension; index=ending end
  while index <= #source do
    local is_add = starts_with(source, index, "add")
    local is_major = starts_with(source, index, "maj")
    local is_sus = starts_with(source, index, "sus")
    if is_add then
      local alteration; alteration, index = accidental(source, index+3)
      local value; value, index = degree(source, index)
      if not value then return nil, "Expected a degree after add" end
      chord.additions[#chord.additions+1] = {degree=value, accidental=alteration}
    elseif is_major or source[index] == "M" or source[index] == "Δ" then
      local value; value, index = degree(source, index+(is_major and 3 or 1))
      if not value then return nil, "Expected a major seventh degree" end
      chord.extension=value; chord.major_seventh=true
    elseif is_sus then
      if chord.suspension then return nil, "Duplicate suspension" end
      index=index+3
      local value, next_index = degree(source, index)
      if value == 2 or value == 4 then chord.suspension=value; index=next_index
      else chord.suspension=4 end
    elseif source[index] == "/" then
      if source[index+1] == "9" and chord.extension == 6 then
        chord.additions[#chord.additions+1] = {degree=9, accidental=0}; index=index+2
      else
        local bass, after_bass = note(source, index+1)
        if not bass or after_bass <= #source then return nil, "Expected a complete written slash bass" end
        chord.bass=bass; index=after_bass
      end
    else
      local alteration, after = accidental(source, index)
      if alteration == 0 then return nil, "Invalid chord suffix" end
      local value; value, index = degree(source, after)
      if not value then return nil, "Expected an altered degree" end
      chord.alterations[#chord.alterations+1] = {degree=value, accidental=alteration}
    end
  end
  if chord.quality == "minor" and chord.extension == 7 and #chord.alterations == 1 and
    chord.alterations[1].degree == 5 and chord.alterations[1].accidental == -1 then
    chord.quality="half_diminished"; chord.alterations={}
  end
  return chord
end
function music.print(chord)
  local quality = ({major="",minor="m",diminished="°",half_diminished="ø",augmented="+"})[chord.quality]
  local result = music.print_note(chord.root) .. quality
  if chord.major_seventh and chord.extension and chord.extension >= 7 then result=result.."Δ" end
  if chord.extension then result=result..chord.extension end
  for _, added in ipairs(chord.additions) do result=result.."add"..accidental_text(added.accidental)..added.degree end
  if chord.suspension then result=result.."sus"..chord.suspension end
  for _, altered in ipairs(chord.alterations) do result=result..accidental_text(altered.accidental)..altered.degree end
  if chord.bass then result=result.."/"..music.print_note(chord.bass) end
  return result
end

local function indexed_characters(text)
  local result, scalar, units = {}, 0, 0
  for byte, value in utf8.codes(text) do
    result[#result+1] = {text=utf8.char(value), byte=byte-1, scalar=scalar, units=units}
    scalar=scalar+1; units=units+(value >= 0x10000 and 2 or 1)
  end
  result.ending={byte=#text, scalar=scalar, units=units}
  return result
end
local function separator(text) return text:match("%s") or text == "[" or text == "]" or text == "|" end
function music.recognise(source)
  local passed, indexed = pcall(indexed_characters, source)
  if not passed then return {} end
  local found, starts, start, bracket_start = {}, {}, 1, nil
  local function append(first, ending)
    if first >= ending then return false end
    local begin = indexed[first] or indexed.ending
    local finish = indexed[ending] or indexed.ending
    local text = source:sub(begin.byte+1, finish.byte)
    local chord = music.parse(text)
    if not chord then return false end
    if not starts[begin.byte] then
      found[#found+1]={beginning=begin, ending=finish, original=text, chord=chord}; starts[begin.byte]=true
    end
    return true
  end
  local function line(first, ending)
    local tokens, word = {}, nil
    for index=first,ending do
      local boundary = index == ending or separator(indexed[index].text)
      if boundary and word then tokens[#tokens+1]={word,index}; word=nil
      elseif not boundary and not word then word=index end
    end
    if #tokens == 0 then return end
    for _, token in ipairs(tokens) do
      local first_position=indexed[token[1]]
      local end_position=indexed[token[2]] or indexed.ending
      if not music.parse(source:sub(first_position.byte+1,end_position.byte)) then return end
    end
    for _, token in ipairs(tokens) do append(token[1],token[2]) end
  end
  for index, character in ipairs(indexed) do
    if character.text == "[" then bracket_start=index+1
    elseif character.text == "]" then if bracket_start then append(bracket_start,index) end; bracket_start=nil
    elseif character.text == "\n" or character.text == "\r" then
      line(start,index); start=index+1; bracket_start=nil
    end
  end
  line(start,#indexed+1)
  table.sort(found, function(left,right) return left.beginning.byte < right.beginning.byte end)
  return found
end
function music.render(source, interval)
  local pieces, offset = {}, 1
  for _, located in ipairs(music.recognise(source)) do
    pieces[#pieces+1]=source:sub(offset,located.beginning.byte)
    pieces[#pieces+1]=music.print(music.transpose(interval,located.chord))
    offset=located.ending.byte+1
  end
  pieces[#pieces+1]=source:sub(offset)
  return table.concat(pieces)
end
return music
