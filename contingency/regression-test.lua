-- SPDX-License-Identifier: GPL-3.0-or-later
local root = assert(arg[0]:match("^(.*)/"), "Invoke with the absolute test path")
local music = assert(loadfile(root.."/music.lua"))()
local count = 0
local regression_path=assert(arg[1], "Live Idriç regression rows are required")
for line in io.lines(regression_path) do
  local kind, shift, source, expected = line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$")
  assert(kind == "chord", "Malformed Idriç comparison record")
  local chord = music.parse(source)
  local actual = chord and music.print(music.transpose(music.interval(assert(tonumber(shift))),chord)) or "ERROR"
  assert(actual == expected, string.format("%s shift=%s expected=%q (%d bytes) actual=%q (%d bytes)",
    source,shift,expected,#expected,actual,#actual))
  count=count+1
end
assert(count >= 1000, "Idriç comparison corpus is incomplete")
local located = music.recognise("🧪 [A/C♯] la\n")
assert(#located == 1 and located[1].beginning.scalar == 3 and located[1].ending.scalar == 7)
assert(located[1].beginning.byte == 6 and located[1].ending.byte == 12)
assert(located[1].beginning.units == 4 and located[1].ending.units == 8)
assert(#music.recognise("A song in Am\n") == 0)
assert(music.render("C#7b9\tFΔ7\r\nA song in Am\n",music.interval(2)) == "D♯7♭9\tGΔ7\r\nA song in Am\n")
print("PASS\t"..count.." live Idriç/Lua musical comparisons and Unicode/chart checks")
