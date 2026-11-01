-- Transport adapter only. Music, chart and key decisions execute checked Idriç.
local music={}
local request
local function field(text) return assert(utf8.len(text))..":"..text end
local function call(command)
  local response=assert(request(command),"Checked Idriç application call failed")
  local status=response:sub(1,1)
  assert(status == "0" or status == "1","Invalid checked application reply")
  if status == "0" then return nil,response:sub(2) end
  return response:sub(2)
end
function music.use_idric(up,down,symbol,application_request)
  assert(type(application_request) == "function","Checked managed application export is required")
  request=application_request
end
function music.parse(source)
  local canonical,problem=call("p"..source)
  if not canonical then return nil,problem end
  return {source=source,canonical=canonical}
end
function music.print(chord) return chord.canonical end
function music.fingering_lookup_key(chord) return assert(call("f"..chord.source)) end
function music.interval(semitones)
  return {letters=assert(tonumber(assert(call("i"..tostring(semitones))))),semitones=semitones}
end
function music.render(source,interval)
  return assert(call("r"..field(tostring(interval.letters))..field(tostring(interval.semitones))..field(source)))
end
function music.recognise(source)
  local rows=assert(call("c"..source))
  local found={}
  for row in rows:gmatch("([^\n]+)\n") do
    local first,last,byte_first,byte_last,unit_first,unit_last,canonical,fingering=
      row:match("^(%d+)\t(%d+)\t(%d+)\t(%d+)\t(%d+)\t(%d+)\t([^\t]+)\t(.+)$")
    assert(first,"Invalid checked chart span reply")
    local beginning={scalar=tonumber(first),byte=tonumber(byte_first),units=tonumber(unit_first)}
    local ending={scalar=tonumber(last),byte=tonumber(byte_last),units=tonumber(unit_last)}
    local original=source:sub(beginning.byte+1,ending.byte)
    found[#found+1]={beginning=beginning,ending=ending,original=original,
      chord={source=original,canonical=canonical,fingering=fingering}}
  end
  return found
end
function music.parse_key(source)
  local canonical,problem=call("n"..source)
  if not canonical then return nil,problem end
  return {source=canonical}
end
function music.print_key(key) return key.source end
function music.key_interval(source,destination)
  local result,problem=call("k"..field(source)..field(destination))
  if not result then return nil,problem end
  local letters,semitones,from,to=result:match("^(%-?%d+)\t(%-?%d+)\t([^\t]+)\t([^\t]+)$")
  assert(letters,"Invalid checked key interval reply")
  return {letters=tonumber(letters),semitones=tonumber(semitones),
    source_key={source=from},destination_key={source=to}}
end
return music
