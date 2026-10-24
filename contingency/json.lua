-- SPDX-License-Identifier: GPL-3.0-or-later
-- Strict data-only JSON boundary for the authorised Lua contingency. No
-- imported text is evaluated as Lua. Idriç's Language.JSON remains the core's
-- parser; its calls/collections do not yet execute through the Android backend.
local json = {null={}}
function json.decode(source)
  local position, length = 1, #source
  local function fail(message) error(message.." at byte "..position, 0) end
  local function space()
    while source:sub(position,position):match("[ \t\r\n]") do position=position+1 end
  end
  local function code_unit()
    local text=source:sub(position,position+3)
    if #text ~= 4 or not text:match("^%x%x%x%x$") then fail("Invalid Unicode escape") end
    position=position+4
    return tonumber(text,16)
  end
  local function text()
    if source:sub(position,position) ~= '"' then fail("Expected a string") end
    position=position+1
    local pieces={}
    while position <= length do
      local character=source:sub(position,position); position=position+1
      if character == '"' then
        local value=table.concat(pieces)
        if not utf8.len(value) then fail("Invalid UTF-8 string") end
        return value
      elseif character == "\\" then
        local escaped=source:sub(position,position); position=position+1
        local known={['"']='"',["\\"]="\\",["/"]="/",b="\b",f="\f",n="\n",r="\r",t="\t"}
        if known[escaped] then pieces[#pieces+1]=known[escaped]
        elseif escaped == "u" then
          local scalar=code_unit()
          if scalar >= 0xd800 and scalar <= 0xdbff then
            if source:sub(position,position+1) ~= "\\u" then fail("Missing low surrogate") end
            position=position+2
            local low=code_unit()
            if low < 0xdc00 or low > 0xdfff then fail("Invalid low surrogate") end
            scalar=0x10000+(scalar-0xd800)*1024+low-0xdc00
          elseif scalar >= 0xdc00 and scalar <= 0xdfff then fail("Isolated low surrogate") end
          pieces[#pieces+1]=utf8.char(scalar)
        else fail("Invalid escape") end
      elseif character:byte() < 32 then fail("Unescaped control character")
      else pieces[#pieces+1]=character end
    end
    fail("Unclosed string")
  end
  local function number()
    local first=position
    if source:sub(position,position) == "-" then position=position+1 end
    local digit=source:sub(position,position)
    if digit == "0" then
      position=position+1
      if source:sub(position,position):match("%d") then fail("Leading zero") end
    elseif digit:match("[1-9]") then
      repeat position=position+1 until not source:sub(position,position):match("%d")
    else fail("Expected a number") end
    if source:sub(position,position) == "." then
      position=position+1
      if not source:sub(position,position):match("%d") then fail("Missing fractional digit") end
      repeat position=position+1 until not source:sub(position,position):match("%d")
    end
    if source:sub(position,position):match("[eE]") then
      position=position+1
      if source:sub(position,position):match("[+-]") then position=position+1 end
      if not source:sub(position,position):match("%d") then fail("Missing exponent digit") end
      repeat position=position+1 until not source:sub(position,position):match("%d")
    end
    local value=tonumber(source:sub(first,position-1))
    if not value or value ~= value or math.abs(value) == math.huge then fail("Nonfinite JSON number") end
    return value
  end
  local value
  value=function(depth)
    if depth > 256 then fail("JSON nesting exceeds 256 levels") end
    space()
    local first=source:sub(position,position)
    if first == '"' then return text()
    elseif first == "[" then
      position=position+1; space()
      local array={}
      if source:sub(position,position) == "]" then position=position+1; return array end
      repeat
        array[#array+1]=value(depth+1); space()
        local ending=source:sub(position,position); position=position+1
        if ending == "]" then return array end
        if ending ~= "," then fail("Expected comma or closing bracket") end
      until false
    elseif first == "{" then
      position=position+1; space()
      local object={}
      if source:sub(position,position) == "}" then position=position+1; return object end
      repeat
        space(); local key=text(); space()
        if source:sub(position,position) ~= ":" then fail("Expected colon") end
        position=position+1
        if object[key] ~= nil then fail("Duplicate object key") end
        object[key]=value(depth+1); space()
        local ending=source:sub(position,position); position=position+1
        if ending == "}" then return object end
        if ending ~= "," then fail("Expected comma or closing brace") end
      until false
    elseif source:sub(position,position+3) == "true" then position=position+4; return true
    elseif source:sub(position,position+4) == "false" then position=position+5; return false
    elseif source:sub(position,position+3) == "null" then position=position+4; return json.null
    else return number() end
  end
  local passed, result=pcall(function()
    local parsed=value(0); space()
    if position <= length then fail("Trailing input") end
    return parsed
  end)
  if passed then return result end
  return nil, result
end
return json
