-- SPDX-License-Identifier: GPL-3.0-or-later
-- Traffic/bytes regression, not a music oracle or an Android frame measurement.
local repository=assert(arg[1],"Absolute repository path required")
package.path=repository.."/contingency/?.lua"
-- Exercise the packaged transport adapter, while explicitly simulating ART.
package.loaded.music=assert(loadfile(repository.."/contingency/managed-music.lua"))()
local application=require("app")
local source=("Am  C♯7\r\nOriginal text and whitespace remain here.\n"):rep(120)
local initial=application.encode({size=20,speed=24,instrument="Guitar",songs={
  {id="1",title="Synthetic long chart",source=source},
  {id="2",title="Second chart",source="Am\r\nSecond source\n"}},setlists={},
  session={id="1",screen="reading_song",shift=0,capo=0,scroll=0}})
local files={["library.txt"]=initial}
local calls={b=0,c=0,v=0,u=0,n=0,k=0,write=0,present=0}
local model,position=nil,0
local reject_validation,reject_render,reject_recognition=false,false,false
local function take_field(text,at)
  local colon=assert(text:find(":",at,true))
  local count=assert(tonumber(text:sub(at,colon-1)))
  local first=colon+1
  local next_byte=assert(utf8.offset(text,count+1,first))
  return text:sub(first,next_byte-1),next_byte
end
local function checked(command)
  local op=command:sub(1,1)
  assert(calls[op] ~= nil,"Unexpected managed request: "..op)
  calls[op]=calls[op]+1
  if op == "v" then
    if reject_validation then return "0Simulated validation refusal" end
    return "1"..command:sub(2)
  end
  if op == "n" then return "1"..command:sub(2) end
  if op == "k" then return "12\t2\tC major\tD major" end
  if op == "b" then
    if reject_render then return "0Simulated render refusal" end
    local state=application.decode(command:sub(2))
    local song
    for _,candidate in ipairs(state.songs) do
      if candidate.id == state.session.id then song=candidate end
    end
    local interval=state.key_interval
    return "1"..assert(song).source.." [shift="..state.session.shift..
      ";capo="..state.session.capo..";interval="..
      (interval and interval.letters..","..interval.semitones or "none")..
      ";display="..(state.display_key and state.display_key.source or "none").."]"
  end
  if op == "c" then
    if reject_recognition then return "0Simulated recognition refusal" end
    return "10\t2\t0\t2\t0\t2\tAm\tAm\n"
  end
  local encoded,at=take_field(command,2)
  local event; event,at=take_field(command,at)
  local first; first,at=take_field(command,at)
  local second; second,at=take_field(command,at)
  local third; third,at=take_field(command,at)
  assert(at == #command+1)
  local state=application.decode(encoded)
  if event == "speed" then state.speed=assert(tonumber(first))
  elseif event == "size" then state.size=assert(tonumber(first))
  elseif event == "instrument" then state.instrument=first
  elseif event == "up" then state.session.shift=state.session.shift+1
  elseif event == "down" then state.session.shift=state.session.shift-1
  elseif event == "capo-up" then state.session.capo=state.session.capo+1
  elseif event == "capo-down" then state.session.capo=math.max(0,state.session.capo-1)
  elseif event == "open" then state.session.id=first
  elseif event == "display-key" then state.display_key={source=first}
  elseif event == "clear-display-key" then state.display_key=nil
  elseif event == "key" then
    state.key_interval={letters=2,semitones=2,
      source_key={source=first},destination_key={source=second}}
  elseif event == "save-chart" then
    for _,song in ipairs(state.songs) do
      if song.id == first then song.title=second; song.source=third end
    end
  else error("Unsupported mock transition: "..event) end
  return "1"..application.encode(state)
end
local failed=false
local platform={
  read=function(name) return files[name] end,
  write=function(name,bytes)
    calls.write=calls.write+1
    if failed then failed=false; return false end
    files[name]=bytes; return true
  end,
  present=function(packet) calls.present=calls.present+1; model=packet end,
  scroll=function(value) position=value end,
  scroll_position=function() return position end,
  application_request=checked,
  pitch_up=function() error("Not reached") end,
  pitch_down=function() error("Not reached") end,
  accidental_symbol=function() error("Not reached") end,
}
local app=application.new(platform)
assert(calls.b == 1 and calls.c == 1 and model.body:find("Original text",1,true))
app.event("scroll","","") -- first save checks a restored snapshot once
assert(calls.v == 1 and calls.write == 0,"Restored snapshot must be checked once before reuse")
for _=1,100 do app.event("scroll","","") end
assert(calls.v == 1 and calls.write == 0,"Read-only toggles must not validate/write")
assert(calls.b == 1 and calls.c == 1,"Scroll toggles must reuse checked chart/spans")
app.event("faster","","")
assert(calls.v == 2 and calls.write == 1,"Speed must durably persist exactly once")
assert(calls.b == 1 and calls.c == 1,"Speed does not alter chart rendering")
app.event("up","","")
assert(calls.v == 3 and calls.write == 2)
assert(calls.b == 2 and calls.c == 2 and model.body:find("shift=1",1,true),"Shift must invalidate the checked chart")
assert(application.decode(files["library.txt"]).songs[1].source == source,"Original bytes changed")
failed=true
local previous=files["library.txt"]
app.event("down","","")
assert(files["library.txt"] == previous,"Failed durable write replaced the library")
app.event("suspend","","") -- retry the failed state, no UI re-render
assert(files["library.txt"] ~= previous and calls.write == 4,"Failed write was not retried")
assert(application.decode(files["library.txt"]).songs[1].source == source)
local external=application.decode(files["library.txt"])
external.size=22
files["library.txt"]=application.encode(external)
local validations=calls.v
app.event("resume","","")
assert(calls.v == validations+1,"Externally loaded snapshot must be rechecked")
assert(files["library.txt"] == application.encode(external))
local writes=calls.write
app.stop()
assert(calls.write == writes,"Stop without changes must not fsync")
files["library.txt"]="corrupt"
local locked=application.new(platform)
locked.event("up","","")
assert(files["library.txt"] == "corrupt","Unreadable library was overwritten")
-- The cache must follow all reader_text inputs, independent of state table identity.
files["library.txt"]=app.snapshot()
app=application.new(platform)
local function rerenders(event,title,body,fragment)
  local renders,recognitions=calls.b,calls.c
  app.event(event,title or "",body or "")
  assert(calls.b == renders+1 and calls.c == recognitions+1,"Stale cached chart after "..event)
  assert(model.body:find(fragment,1,true),"Wrong mock render after "..event)
  assert(model.spans[1][1] == 0 and model.spans[1][2] == 2,"Checked span transport changed")
end
rerenders("capo-up",nil,nil,"capo=1")
rerenders("capo-down",nil,nil,"capo=0")
app.event("display-key","","")
rerenders("save","D major","","display=D major")
rerenders("clear-display-key",nil,nil,"display=none")
app.event("written-key","","")
rerenders("save","C major","D major","interval=2,2")
app.event("edit","","")
rerenders("save","Edited title",source.."New bytes\n","New bytes")
rerenders("open:2",nil,nil,"Second source")
rerenders("open:1",nil,nil,"New bytes")
local renders,recognitions=calls.b,calls.c
app.event("settings","","")
app.event("font-up","","")
app.event("cancel","","")
assert(calls.b == renders and calls.c == recognitions,"Font/navigation invalidated the chart")
assert(model.size == 24,"Cached chart hid updated text size")
position=41
app.event("scroll","","")
assert(position == 41 and calls.b == renders,"Cached chart lost the viewport")

-- A validation refusal may not install a durable snapshot or suppress a retry.
local durable=files["library.txt"]
reject_validation=true
app.event("up","","")
assert(files["library.txt"] == durable and model.notice:find("refusal",1,true))
reject_validation=false
local validations=calls.v
app.stop()
assert(calls.v == validations+1 and files["library.txt"] ~= durable)

-- Failed render/recognition must not poison the last complete cache entry.
reject_render=true
assert(not pcall(app.event,"up","",""),"Render refusal was ignored")
reject_render=false
renders,recognitions=calls.b,calls.c
app.event("resume","","")
assert(calls.b == renders+1 and calls.c == recognitions+1,"Render refusal cached partial output")
reject_recognition=true
assert(not pcall(app.event,"up","",""),"Recognition refusal was ignored")
reject_recognition=false
renders,recognitions=calls.b,calls.c
app.event("resume","","")
assert(calls.b == renders+1 and calls.c == recognitions+1,"Recognition refusal cached partial output")

-- Same identifier, changed source from another window must miss the cache.
external=application.decode(files["library.txt"])
external.songs[1].source="Am\nExternally replaced source\n"
files["library.txt"]=application.encode(external)
rerenders("resume",nil,nil,"Externally replaced source")
files["library.txt"]="corrupt"
local writes=calls.write
app.event("resume","","")
app.event("up","","")
app.stop()
assert(files["library.txt"] == "corrupt" and calls.write == writes,"Corrupt external reload was overwritten")
print("PASS\tMOCK transport: 100 scroll toggles avoid redundant v/b/c/write; cache invalidation, validation/render/recognition refusals, failed-write retry, source bytes, viewport and corrupt reload")
