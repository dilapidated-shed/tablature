-- SPDX-License-Identifier: GPL-3.0-or-later
-- Host contract tests. No credentials, GitHub write, Android or network needed.
package.path="contingency/?.lua;"..package.path
local remote=require("remote")
local json=require("json")
local function valid(data)
  return type(data)=="string" and data:sub(1,20)=="ChordReader/Idric/1\n"
end
local function lib(song)
  return "ChordReader/Idric/1\n"..song
end
local first=lib("P2:202:246:GuitarS1:13:One2:C\n")
local second=lib("P2:202:246:GuitarS1:13:One2:D\n")
local third=lib("P2:202:246:GuitarS1:13:One2:E\n")
local sha=string.rep("a",40)
local function github_file(data)
  local encoded=remote.base64_encode(data)
  return '{"type":"file","encoding":"base64","sha":"'..sha..
    '","size":'..#data..',"content":"'..encoded..'"}'
end
assert(remote.base64_decode(remote.base64_encode("a"))=="a")
assert(remote.base64_decode(remote.base64_encode("ab"))=="ab")
assert(remote.base64_decode(remote.base64_encode("abc"))=="abc")
assert(remote.base64_decode(remote.base64_encode("B♭\0𝄪"))=="B♭\0𝄪")
assert(not remote.base64_decode("Zg=a"))
assert(not remote.base64_decode("Zg==AAAA"))
assert(not remote.base64_decode("%%%="))
local files={["library.txt"]=first}
local requests={}
local platform={
  read=function(name) return files[name] end,
  write=function(name,data) files[name]=data; return true end,
  remote_request=function(method,url,token,data)
    requests[#requests+1]={method=method,url=url,token=token,data=data}
    return true
  end
}
local function apply(data)
  files["library-recovery.txt"]=files["library.txt"]
  files["library.txt"]=data
  return true
end
local store=remote.new(platform,valid,apply,function() return files["library.txt"] end)
assert(store:start("sync"):find("Configure",1,true))
assert(not store:configure("owner/repo","../branch","chordreader/library.txt"))
assert(not store:configure("owner/repo","main","../library.txt"))
assert(store:configure("owner/repo","main","chordreader/library.txt"))
assert(not store:set_token("bad\ninjection"))
assert(store:start("upload"):find("token",1,true))
local token="github_pat_example_secret_token_123456"
assert(store:set_token(token))
assert(not files["remote-config.txt"]:find(token,1,true))
assert(not store:description():find(token,1,true))
local message=store:start("sync")
assert(message:find("Checking",1,true))
assert(requests[1].method=="GET" and requests[1].url==
  "https://api.github.com/repos/owner/repo/contents/chordreader/library.txt?ref=main")
assert(store:start("sync"):find("already",1,true))
assert(store:reply(404,""):find("Uploading",1,true))
assert(requests[2].method=="PUT" and requests[2].token==token)
local uploaded=json.decode(requests[2].data)
assert(uploaded and uploaded.branch=="main" and remote.base64_decode(uploaded.content)==first)
assert(uploaded.sha==nil)
assert(store:reply(201,'{"commit":{"sha":"123"}}'):find("saved on GitHub",1,true))
assert(files["remote-base.txt"]:find(first,1,true))
assert(not files["remote-base.txt"]:find(token,1,true))
assert(store:start("sync"):find("Checking",1,true))
assert(store:reply(200,github_file(first)):find("already matches",1,true))

files["library.txt"]=second
assert(store:start("upload"):find("Checking",1,true))
assert(store:reply(200,github_file(first)):find("Uploading",1,true))
uploaded=json.decode(requests[#requests].data)
assert(uploaded.sha==sha and remote.base64_decode(uploaded.content)==second)
assert(store:reply(409,'{"message":"SHA mismatch"}'):find("refused",1,true))
assert(files["library.txt"]==second and files["remote-base.txt"]:find(first,1,true))

-- Another device changed the remote: no overwrite or optimistic merge.
assert(store:start("sync"):find("Checking",1,true))
assert(store:reply(200,github_file(third)):find("conflict",1,true))
assert(requests[#requests].method=="GET")
assert(files["library.txt"]==second)

-- A fresh app without any baseline does not overwrite an existing remote.
files["remote-base.txt"]=nil
local fresh=remote.new(platform,valid,apply,function() return files["library.txt"] end)
assert(fresh:start("sync"):find("token",1,true))
assert(fresh:set_token(token))
assert(fresh:start("sync"):find("Checking",1,true))
assert(fresh:reply(200,github_file(first)):find("conflict",1,true))

-- Restore is explicitly confirmed; source remains local until then.
assert(fresh:start("restore"):find("Checking",1,true))
assert(fresh:reply(200,github_file(first)):find("Confirm Restore",1,true))
assert(files["library.txt"]==second and fresh:can_confirm())
assert(fresh:confirm_restore():find("downloaded",1,true))
assert(files["library-recovery.txt"]==second and files["library.txt"]==first)
assert(not fresh:can_confirm())

-- Sync with unchanged local baseline pulls a newer remote revision.
assert(fresh:start("sync"):find("Checking",1,true))
assert(fresh:reply(200,github_file(third)):find("downloaded",1,true))
assert(files["library.txt"]==third and files["library-recovery.txt"]==first)

-- Wrong JSON / malformed base64 / unauthorized status must leave local data alone.
for _,body in ipairs {
  '{"type":"file","encoding":"base64","sha":"'..sha..'","size":3,"content":"%%%="}',
  '{"type":"file","encoding":"base64","sha":"'..sha..'","size":1,"content":"YQ=="}',
  '{"type":"file","encoding":"utf-8","sha":"'..sha..'","size":1,"content":"x"}',
  '{"type":"file","encoding":"base64","sha":"'..sha..'","size":1,"content":"YQ="}'
} do
  assert(fresh:start("restore"):find("Checking",1,true))
  local response=fresh:reply(200,body)
  assert(response:find("invalid",1,true) or response:find("failed validation",1,true),response)
  assert(files["library.txt"]==third)
end
assert(fresh:start("sync"):find("Checking",1,true))
assert(fresh:reply(401,'{"message":"bad credentials"}'):find("401",1,true))
assert(files["library.txt"]==third)
files["library.txt"]="corrupt"
assert(fresh:start("sync"):find("validation",1,true))
assert(#requests>0)
fresh:forget_token()
assert(not fresh:description():find(token,1,true))
print("PASS\tGitHub local-first backup, downloads, baseline sync, SHA conflicts, credential isolation and refusal controls")
