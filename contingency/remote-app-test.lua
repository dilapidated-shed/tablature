-- SPDX-License-Identifier: GPL-3.0-or-later
-- Exercise the actual Lua UI/transport wiring without Android or Idriç compiler.
package.path="contingency/?.lua;"..package.path
package.preload.music=function()
  return {use_idric=function() end}
end
local app_module=require("app")
local remote=require("remote")
local files,screen,requests={},nil,{}
local platform={
  read=function(path) return files[path] end,
  write=function(path,data) files[path]=data; return true end,
  present=function(packet) screen=packet end,
  scroll=function() end,
  scroll_position=function() return 0 end,
  remote_request=function(verb,url,token,payload)
    requests[#requests+1]={verb=verb,url=url,token=token,payload=payload}
    return true
  end
}
local app=app_module.new(platform)
app.event("new","","")
app.event("save","Practice","C\n")
local local_bytes=files["library.txt"]
assert(local_bytes and app_module.decode(local_bytes).songs[1].source=="C\n")
app.event("remote","","")
assert(screen.body:find("No remote configured",1,true))
app.event("remote-config","","")
assert(screen.editable and not screen.secret)
app.event("save","owner/private-songbook","main\nchordreader/library.txt")
assert(files["remote-config.txt"] and screen.body:find("GitHub:",1,true))
app.event("remote-token","","")
assert(screen.secret,"Remote token must be password-masked")
local token="github_pat_session_secret_example"
app.event("save","Token",token)
assert(not screen.editable and not screen.secret)
assert(not files["remote-config.txt"]:find(token,1,true))
assert(not files["library.txt"]:find(token,1,true))
assert(not (screen.body or ""):find(token,1,true))
app.event("remote-upload","","")
assert(#requests==1 and requests[1].verb=="GET")
app.event("remote_reply","404","")
assert(#requests==2 and requests[2].verb=="PUT")
app.event("remote_reply","201",'{"commit":{"sha":"abc"}}')
assert(screen.notice:find("saved on GitHub",1,true))
assert(files["remote-base.txt"])
assert(not files["remote-base.txt"]:find(token,1,true))
local remote_bytes=local_bytes:gsub("C\n","D\n",1)
assert(remote_bytes~=local_bytes)
assert(app_module.decode(remote_bytes).songs[1].source=="D\n")
app.event("remote-restore","","")
app.event("remote_reply","200",'{"type":"file","encoding":"base64","sha":"'..
  string.rep("a",40)..'","size":'..#remote_bytes..',"content":"'..
  remote.base64_encode(remote_bytes)..'"}')
assert(screen.notice:find("Confirm Restore",1,true) and files["library.txt"]==local_bytes)
app.event("remote-confirm","","")
assert(files["library-recovery.txt"]==local_bytes)
assert(files["library.txt"]==remote_bytes,"Restore must not be rewritten by trailing UI save")
assert(screen.notice:find("downloaded",1,true))
assert(app_module.decode(files["library.txt"]).songs[1].source=="D\n")
app.event("remote-clear-token","","")
assert(screen.body:find("not entered",1,true))
print("PASS\tActual Lua UI, token masking, asynchronous GitHub upload, confirmed restore and recovery")
