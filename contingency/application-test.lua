-- SPDX-License-Identifier: GPL-3.0-or-later
-- Host state tests with an explicitly simulated Android platform. Numeric
-- bindings are live Idriç host results, not a claim of ART/device execution.
local repository=assert(arg[1],"Absolute repository path required")
local pitch_file=assert(arg[2],"Live Idriç pitch rows required")
local library_file=assert(arg[3],"Live Idriç library bytes required")
package.path=repository.."/contingency/?.lua"
local application=require("app")
local json=require("json")
local up,down,symbols={},{},{}
for line in io.lines(pitch_file) do
  local pitch,above,below=line:match("^(%d+)\t(%-?%d+)\t(%-?%d+)$")
  if pitch then up[tonumber(pitch)]=tonumber(above); down[tonumber(pitch)]=tonumber(below)
  else local input,output=line:match("^(.)\t(.+)$"); assert(input and output); symbols[input]=output end
end
local function read(path) local file=assert(io.open(path,"rb")); local text=file:read("a"); file:close(); return text end
local files,model,scroll,up_calls,down_calls={},{},0,0,0
local exported_name,exported_source,chosen=nil,nil,0
local platform={
  read=function(name) return files[name] end,
  write=function(name,text) files[name]=text; return true end,
  present=function(packet) model=packet end,
  asset=function(name) return read(repository.."/app/src/main/res/raw/"..name) end,
  scroll=function(position) scroll=position end,
  scroll_position=function() return scroll end,
  pitch_up=function(pitch) up_calls=up_calls+1; return assert(up[pitch]) end,
  pitch_down=function(pitch) down_calls=down_calls+1; return assert(down[pitch]) end,
  accidental_symbol=function(input) return symbols[input] or input end,
  fetch=function(url) assert(url == "https://example.invalid/chart"); return true end,
  browse=function() end, share=function() end,
  export=function(name,source) exported_name=name; exported_source=source; return true end,
  choose_file=function() chosen=chosen+1; return true end
}
local app=application.new(platform)
app.event("new","",""); app.event("save","One","C#7b9\tFΔ7\r\nA song in Am\n")
app.event("new","",""); app.event("save","Two","Bø7\n")
app.event("new-setlist","",""); app.event("save","Practice","Two.txt\nOne.txt\nTwo.txt\n")
assert(app.snapshot() == read(library_file),"Idriç/Lua persistence framing or state differs")
app.event("open:1","",""); app.event("up","","")
assert(model.body == "C♯♯7♭9\tF♯Δ7\r\nA song in Am\n" and up_calls > 0,
  "Augmented-unison spelling or checked pitch motion differs")
app.event("export","","")
assert(exported_name == "One.txt" and exported_source == "C#7b9\tFΔ7\r\nA song in Am\n","Export changed source to the transposed display")
app.event("down","",""); app.event("down","","")
assert(down_calls > 0 and model.body:find("C7♭9",1,true))
app.event("written-key","",""); app.event("save","C#","D")
assert(model.body == "D7♭9\tG♭Δ7\r\nA song in Am\n","Written key context lost letter distance")
local contextual=application.new(platform)
assert(model.body == "D7♭9\tG♭Δ7\r\nA song in Am\n","Written key interval did not survive restart")
app.event("chord:C","",""); assert(model.frets and #model.frets == 6,"Original guitar lookup failed")
app.event("chord:C♯♯","",""); assert(model.frets and #model.frets == 6,"Enharmonic guitar lookup failed")
app.event("chord:C","","")
app.event("instrument","",""); assert(model.frets and #model.frets == 4,"Original ukulele lookup failed")
app.event("custom","",""); app.event("save","C","0 0 0 3")
assert(files["custom-ukulele.crd"] and model.frets[4] == 3)
app.event("back-reader","",""); app.event("scroll","","")
for _=1,100 do app.tick(10) end
assert(scroll == 24,"Scrolling loses fractional ticks")
app.event("scroll","",""); app.tick(1000); assert(scroll == 24,"Paused scrolling moved")
app.event("settings","",""); app.event("font-up","",""); app.event("suspend","","")
local restarted=application.new(platform)
assert(model.body:find("Text size: 22",1,true),"Settings did not survive restart")
restarted.event("open:1","",""); restarted.event("chord:C","","")
assert(model.frets and model.frets[4] == 3,"Custom fingering did not survive restart")
local decoded=application.decode(files["library.txt"])
assert(#decoded.songs == 2 and #decoded.setlists[1].ids == 3)
assert(decoded.songs[1].source == "C#7b9\tFΔ7\r\nA song in Am\n","Transposition changed stored source")
assert(application.online_chart("<html><pre>C#7b9\tFΔ7\n</pre></html>") == "C#7b9\tFΔ7\n")
app.event("import","",""); app.event("choose-file","Draft","C#7")
app.event("resume","",""); assert(model.body == "C#7" and model.edit_title == "Draft" and chosen == 1,"Document picker resume lost the draft")
local intact=files["library.txt"]
app.event("incoming","Bad.txt","\255"); assert(files["library.txt"] == intact and model.notice:find("UTF-8",1,true))
assert(json.decode('"\\ud834\\udd2a"') == "𝄪")
assert(not json.decode('"\\ud834"') and not json.decode('{"x":1,"x":2}'))
local other_window=application.new(platform)
other_window.event("new","",""); other_window.event("save","Three","C\n")
restarted.event("resume","","")
assert(#application.decode(restarted.snapshot()).songs == 3,"Resuming an old window lost a new song")
local before=files["library.txt"]; files["library.txt"]="corrupt"
application.new(platform); assert(files["library.txt"] == "corrupt","Corrupt library was overwritten")
files["library.txt"]=before
print("PASS\tC+Lua state, live Idriç persistence comparison, original dictionaries, restart, scrolling and import checks")
