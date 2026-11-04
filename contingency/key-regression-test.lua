-- Temporary contingency comparisons against actual compiled Key.idric rows.
local repository=assert(arg[1],"Absolute repository path required")
local rows=assert(arg[2],"Live checked Idriç key rows required")
package.path=repository.."/contingency/?.lua"
local music=require("music")
local count=0
for line in io.lines(rows) do
  local kind,source,third,expected,fifth=line:match("^(%w+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t?(.*)$")
  assert(kind,"Malformed checked key row")
  if kind == "degree" then
    local key=assert(music.parse_key(source))
    local note=music.diatonic_note(key,assert(tonumber(third)))
    assert((note and music.print_note(note) or "REJECT") == expected,"Key degree differs: "..line)
  else
    assert(kind == "interval","Unknown key row")
    local interval=music.key_interval(source,third)
    if expected == "REJECT" then assert(not interval,"Mode conversion must refuse: "..line)
    else assert(interval and interval.letters == tonumber(expected) and interval.semitones == tonumber(fifth),
      "Written key interval differs: "..line) end
  end
  count=count+1
end
assert(count == 2142,"The complete declared-key corpus did not execute")
print("PASS\t"..count.." live Idriç/Lua declared-key comparisons")
