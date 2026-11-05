-- SPDX-License-Identifier: GPL-3.0-or-later
-- Replaceable remote songbook transport. No musical rules or Android APIs.
-- The canonical library is always local; GitHub is the first remote backend.
local json=require("json")
local M={}
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64encode(data)
  local out={}
  for i=1,#data,3 do
    local a,b,c=data:byte(i,i+2)
    local x=a*65536+(b or 0)*256+(c or 0)
    out[#out+1]=alphabet:sub((x//262144)%64+1,(x//262144)%64+1)
    out[#out+1]=alphabet:sub((x//4096)%64+1,(x//4096)%64+1)
    out[#out+1]=b and alphabet:sub((x//64)%64+1,(x//64)%64+1) or "="
    out[#out+1]=c and alphabet:sub(x%64+1,x%64+1) or "="
  end
  return table.concat(out)
end
local function b64decode(encoded)
  if type(encoded)~="string" then return nil end
  local source=encoded:gsub("[\r\n]","")
  if #source%4~=0 or #source==0 then return nil end
  local out={}
  for i=1,#source,4 do
    local block=source:sub(i,i+3)
    if block:sub(3,3)=="=" and block:sub(4,4)~="=" then return nil end
    local padding=block:sub(3,4)=="==" and 2 or (block:sub(4,4)=="=" and 1 or 0)
    if padding>0 and i+3~=#source then return nil end
    local values={}
    for j=1,4 do
      local ch=block:sub(j,j)
      local p=alphabet:find(ch,1,true)
      if not p and ch~="=" then return nil end
      if ch=="=" and j<3 then return nil end
      values[j]=(p or 1)-1
    end
    if padding==2 and values[2]%16~=0 then return nil end
    if padding==1 and values[3]%4~=0 then return nil end
    local bits=values[1]*262144+values[2]*4096+values[3]*64+values[4]
    out[#out+1]=string.char((bits//65536)%256)
    if padding<2 then out[#out+1]=string.char((bits//256)%256) end
    if padding<1 then out[#out+1]=string.char(bits%256) end
  end
  return table.concat(out)
end
M.base64_encode=b64encode
M.base64_decode=b64decode

local function component(s)
  return type(s)=="string" and #s>0 and #s<=80 and
    s:match("^[%w._%-]+$") and s~="." and s~=".." and not s:find("..",1,true)
end
local function hierarchical(s,limit)
  if type(s)~="string" or #s==0 or #s>limit or s:sub(1,1)=="/" or
      s:sub(-1)=="/" or s:find("//",1,true) then return false end
  for part in s:gmatch("[^/]+") do if not component(part) then return false end end
  return true
end
local function config_ok(c)
  if type(c)~="table" or c.provider~="github" then return false end
  if type(c.repository)~="string" then return false end
  local owner,repo=c.repository:match("^([^/]+)/([^/]+)$")
  return component(owner) and component(repo) and hierarchical(c.branch,120) and
    hierarchical(c.path,220) and c.path:sub(-4)==".txt"
end
local function identity(c)
  return table.concat({c.provider,c.repository,c.branch,c.path},"\n").."\n"
end
local config_header="ChordReader/remote-config/1\n"
local base_header="ChordReader/remote-base/1\n"
local function serialize(c) return config_header..identity(c) end
local function parse_config(raw)
  if not raw then return nil end
  if raw:sub(1,#config_header)~=config_header then return nil,"Invalid remote configuration" end
  local provider,repository,branch,path,rest=raw:sub(#config_header+1):
    match("^([^\n]*)\n([^\n]*)\n([^\n]*)\n([^\n]*)\n(.*)$")
  local c={provider=provider,repository=repository,branch=branch,path=path}
  if rest~="" or not config_ok(c) then return nil,"Invalid remote configuration" end
  return c
end
local function quote(s)
  return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('[\r\n\t]',function(ch)
    return ({["\r"]="\\r",["\n"]="\\n",["\t"]="\\t"})[ch]
  end)..'"'
end
local function url(c)
  return "https://api.github.com/repos/"..c.repository.."/contents/"..c.path.."?ref="..c.branch
end
local function put_url(c)
  return "https://api.github.com/repos/"..c.repository.."/contents/"..c.path
end
local function parse_github(body)
  local object=json.decode(body)
  if type(object)~="table" or object.type~="file" or object.encoding~="base64" or
      type(object.sha)~="string" or not object.sha:match("^[a-f0-9]+$") or
      #object.sha~=40 or type(object.content)~="string" then
    return nil,nil,"GitHub returned an invalid file record"
  end
  local data=b64decode(object.content)
  if not data or #data>8*1024*1024 or object.size~=#data then
    return nil,nil,"GitHub returned invalid or oversized songbook bytes"
  end
  return data,object.sha
end

-- A backend supplies the endpoint, reply decoding and revision-protected write.
-- A future SDF adapter can implement this contract using its own transport,
-- without changing the local library or the reader.
local providers={github={
  read=function(c) return "GET",url(c),"" end,
  decode=parse_github,
  write=function(c,data,sha)
    local payload='{"message":"Update ChordReader songbook","branch":'..quote(c.branch)..
      ',"content":'..quote(b64encode(data))..(sha and ',"sha":'..quote(sha) or "").."}"
    return "PUT",put_url(c),payload
  end,
}}

function M.new(platform,validate,apply,current)
  assert(type(platform.read)=="function" and type(platform.write)=="function")
  assert(type(validate)=="function" and type(apply)=="function" and type(current)=="function")
  local self={config=nil,token=nil,pending=nil,confirmation=nil}
  local stored=platform.read("remote-config.txt")
  local config,problem=parse_config(stored)
  self.config=config
  self.configuration_error=problem
  local function base()
    if not self.config then return nil end
    local stored_base=platform.read("remote-base.txt")
    local prefix=base_header..identity(self.config)
    if stored_base and stored_base:sub(1,#prefix)==prefix then
      return stored_base:sub(#prefix+1)
    end
  end
  local function track(data)
    return platform.write("remote-base.txt",base_header..identity(self.config)..data)
  end
  local function safe(data)
    if type(data)~="string" or #data>8*1024*1024 or data:find("\0",1,true) or
        not utf8.len(data) then return false end
    local ok,valid=pcall(validate,data)
    return ok and valid==true
  end
  function self:description()
    if self.configuration_error then return self.configuration_error.."; saved bytes were retained" end
    if not self.config then return "No remote configured" end
    return "GitHub: "..self.config.repository.." ["..self.config.branch..
      "] / "..self.config.path.."\nCredential: "..(self.token and "available this session" or "not entered")..
      "\nLocal songbook remains usable offline."
  end
  function self:configure(repository,branch,path)
    local next_config={provider="github",repository=repository,branch=branch,path=path}
    if not config_ok(next_config) then return false,"Use owner/repo, a branch and a .txt path without spaces or .." end
    if not platform.write("remote-config.txt",serialize(next_config)) then
      return false,"Could not save remote configuration"
    end
    self.config=next_config
    self.configuration_error=nil
    self.confirmation=nil
    self.token=nil -- credentials cannot be carried to another remote silently
    return true,"Remote configured. Enter a fine-grained GitHub token for this session."
  end
  function self:set_token(token)
    if type(token)~="string" or #token<16 or #token>255 or
        not token:match("^[%w_.%-]+$") then return false,"Invalid token format" end
    self.token=token
    return true,"GitHub credential loaded for this session, never written to disk"
  end
  function self:forget_token() self.token=nil; return "Session credential cleared" end
  function self:can_confirm() return self.confirmation~=nil end
  local function finish(message)
    self.pending=nil
    return message
  end
  local function transfer(method,endpoint,payload)
    return platform.remote_request and platform.remote_request(method,endpoint,self.token,payload)
  end
  function self:start(operation)
    if operation~="sync" and operation~="upload" and operation~="restore" then return "Unsupported remote operation" end
    if self.pending then return "A remote request is already running" end
    if not self.config then return self.configuration_error or "Configure a remote first" end
    if not self.token then return "Enter a GitHub token first" end
    self.confirmation=nil
    local snapshot=current()
    if not safe(snapshot) then return "Local library failed validation; remote operation refused" end
    local backend=providers[self.config.provider]
    if not backend then return "No transport installed for this remote provider" end
    local method,endpoint,payload=backend.read(self.config)
    self.pending={operation=operation,stage="get",snapshot=snapshot}
    if not transfer(method,endpoint,payload) then return finish("Remote transport unavailable") end
    return "Checking GitHub revision…"
  end
  local function import(self,snapshot,data)
    if current()~=snapshot then return "Local songbook changed during the download; retry" end
    if not safe(data) then return "Downloaded songbook failed validation; local data was retained" end
    if data==snapshot then
      if not track(data) then return "Songbook matches GitHub, but sync baseline could not be saved" end
      return "Local songbook already matches GitHub"
    end
    if not apply(data) then return "Local restore failed; local songbook retained" end
    if not track(data) then return "Restored locally, but could not store sync baseline; subsequent sync will refuse conflicts" end
    return "GitHub songbook downloaded; previous local library saved as recovery copy"
  end
  function self:confirm_restore()
    local c=self.confirmation
    if not c then return "No restore is awaiting confirmation" end
    self.confirmation=nil
    return import(self,c.snapshot,c.data)
  end
  function self:failure()
    if not self.pending then return "No remote operation in progress" end
    return finish("GitHub request failed or timed out; local songbook retained")
  end
  function self:reply(status,body)
    local p=self.pending
    if not p then return "Ignoring an unsolicited remote response" end
    local backend=providers[self.config.provider]
    status=tonumber(status)
    if not status then return finish("Invalid network status; local data retained") end
    if p.stage=="put" then
      if status~=200 and status~=201 then
        return finish("GitHub upload refused (HTTP "..status.."); local data retained; retry after resolving conflicts")
      end
      local response=json.decode(body)
      if type(response)~="table" or type(response.commit)~="table" or
          type(response.commit.sha)~="string" then
        return finish("Unverified upload response; check GitHub before retrying")
      end
      if not track(p.snapshot) then return finish("Uploaded to GitHub, but local sync baseline could not be saved") end
      return finish("Songbook saved on GitHub")
    end
    if p.stage~="get" then return finish("Invalid request state") end
    local remote,sha=nil,nil
    if status==200 then
      local problem
      remote,sha,problem=backend.decode(body)
      if not remote or not safe(remote) then
        return finish(problem or "GitHub songbook failed validation; existing files retained")
      end
    elseif status~=404 then
      return finish("GitHub download refused (HTTP "..status.."); no local change")
    end
    local local_now=current()
    if local_now~=p.snapshot then return finish("Local songbook changed while checking GitHub; retry") end
    if p.operation=="restore" then
      if not remote then return finish("No songbook exists at the configured GitHub path") end
      if remote==p.snapshot then
        local message=import(self,p.snapshot,remote)
        return finish(message)
      end
      self.confirmation={snapshot=p.snapshot,data=remote}
      return finish("Remote version differs. Confirm Restore to replace local data (a recovery copy is retained).")
    end
    local ancestor=base()
    if remote==p.snapshot then
      if not track(p.snapshot) then return finish("GitHub matches local; could not save sync baseline") end
      return finish("Local songbook already matches GitHub")
    end
    if p.operation=="sync" and ancestor and p.snapshot==ancestor and remote then
      local message=import(self,p.snapshot,remote)
      return finish(message)
    end
    -- No unknown-revision overwrite. A new file may be created, or a known
    -- unchanged remote revision may be updated. GitHub enforces the SHA CAS.
    if not ((not remote and not ancestor) or (remote and ancestor and remote==ancestor)) then
      return finish("Sync conflict: both sides differ or the remote was deleted. No data overwritten.")
    end
    local method,endpoint,payload=backend.write(self.config,p.snapshot,sha)
    p.stage="put"
    if not transfer(method,endpoint,payload) then return finish("GitHub upload could not start; local data retained") end
    return "Uploading local songbook to GitHub…"
  end
  return self
end

return M
