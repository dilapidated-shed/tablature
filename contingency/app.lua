-- SPDX-License-Identifier: GPL-3.0-or-later
-- Application state/presentation for the documented C+Lua contingency.
local music=require("music")
local json=require("json")
local header="ChordReader/Idric/1\n"
local function field(text) return assert(utf8.len(text))..":"..text end
local function basename(name) return name:gsub("^.*[/\\:]",""):gsub("%.txt$",""):gsub("%.pl$","") end
local function lines(text)
  local result={}
  for line in (text:gsub("\r\n","\n"):gsub("\r","\n").."\n"):gmatch("(.-)\n") do
    if line ~= "" then result[#result+1]=line end
  end
  return result
end
local function encode(state)
  local pieces={header,"P",field(tostring(state.size)),field(tostring(state.speed)),field(state.instrument)}
  for _, song in ipairs(state.songs) do
    pieces[#pieces+1]="S"..field(song.id)..field(song.title)..field(song.source)
  end
  for _, list in ipairs(state.setlists) do
    pieces[#pieces+1]="L"..field(list.name)..field(tostring(#list.ids))
    for _, id in ipairs(list.ids) do pieces[#pieces+1]=field(id) end
  end
  if state.session then
    local session=state.session
    pieces[#pieces+1]="R"..field(session.id or "")..field(session.screen or "song_library")..
      field(tostring(session.shift or 0))..field(tostring(session.capo or 0))..field(tostring(session.scroll or 0))
  end
  if state.key_interval then
    pieces[#pieces+1]="K"..field(tostring(state.key_interval.letters))..field(tostring(state.key_interval.semitones))
  end
  return table.concat(pieces)
end
local function decode(raw)
  assert(raw:sub(1,#header) == header,"Unrecognised library header")
  local state={songs={},setlists={},size=20,speed=24,instrument="Guitar"}
  local position=#header+1
  local function read_field()
    local ending=assert(raw:find(":",position,true),"Missing field length")
    local count=assert(tonumber(raw:sub(position,ending-1):match("^%d+$")),"Invalid field length")
    local first=ending+1
    local after=assert(utf8.offset(raw,count+1,first),"Truncated field")
    local result=raw:sub(first,after-1)
    assert(utf8.len(result) == count,"Truncated UTF-8 field")
    position=after
    return result
  end
  local identifiers={}
  while position <= #raw do
    local kind=raw:sub(position,position); position=position+1
    if kind == "P" then
      state.size=assert(tonumber(read_field())); state.speed=assert(tonumber(read_field())); state.instrument=read_field()
    elseif kind == "S" then
      local id=read_field(); assert(not identifiers[id],"Duplicate song identifier")
      state.songs[#state.songs+1]={id=id,title=read_field(),source=read_field()}; identifiers[id]=true
    elseif kind == "L" then
      local list={name=read_field(),ids={}}
      local count=assert(tonumber(read_field()))
      assert(count >= 0 and math.floor(count) == count,"Invalid setlist length")
      for _=1,count do list.ids[#list.ids+1]=read_field() end
      state.setlists[#state.setlists+1]=list
    elseif kind == "R" then
      state.session={id=read_field(),screen=read_field(),shift=assert(tonumber(read_field())),
        capo=assert(tonumber(read_field())),scroll=assert(tonumber(read_field()))}
      assert(state.session.id == "" or identifiers[state.session.id],"Stored reader refers to an unknown song")
    elseif kind == "K" then
      state.key_interval={letters=assert(tonumber(read_field())),semitones=assert(tonumber(read_field()))}
    else error("Unknown stored library record "..kind) end
  end
  assert(state.size >= 8 and state.size <= 96 and state.speed >= 0,"Invalid reader settings")
  assert(state.instrument == "Guitar" or state.instrument == "Ukulele","Invalid instrument")
  return state
end
local function html_entities(text)
  local named={amp="&",lt="<",gt=">",quot='"',apos="'",nbsp=" "}
  return (text:gsub("&(#?[%w]+);",function(entity)
    if named[entity] then return named[entity] end
    local scalar=entity:match("^#x(%x+)$") or entity:match("^#X(%x+)$")
    scalar=scalar and tonumber(scalar,16) or tonumber(entity:match("^#(%d+)$"))
    if scalar and scalar <= 0x10ffff and not (scalar >= 0xd800 and scalar <= 0xdfff) then return utf8.char(scalar) end
    return "&"..entity..";"
  end))
end
local function online_chart(raw)
  local lower=raw:lower()
  if not lower:find("<html",1,true) and not lower:find("<!doctype",1,true) then return raw end
  local first,ending=lower:find("<pre[^>]*>")
  if first then
    local closing=lower:find("</pre%s*>",ending+1)
    if closing then return html_entities(raw:sub(ending+1,closing-1):gsub("<[^>]+>","")) end
  end
  local encoded=raw:match('data%-content="(.-)"')
  if encoded then
    local content=json.decode(html_entities(encoded))
    local store=content and content.store and content.store.page
    local tab=store and store.data and store.data.tab_view
    local source=tab and tab.wiki_tab and tab.wiki_tab.content
    if type(source) == "string" then return source:gsub("%[ch%]","["):gsub("%[/ch%]","]"):gsub("%[/?tab%]","") end
  end
  return nil,"This page has no supported preformatted chord chart; share or paste the chart text"
end
local function url_encode(text) return (text:gsub("[^%w%-._~]",function(character) return string.format("%%%02X",character:byte()) end)) end

local function new(platform)
  music.use_idric(platform.pitch_up,platform.pitch_down,platform.accidental_symbol)
  local state={songs={},setlists={},size=20,speed=24,instrument="Guitar"}
  local raw=platform.read("library.txt")
  local locked,notice=false,""
  if raw then
    local passed,loaded=pcall(decode,raw)
    if passed then state=loaded else locked=true; notice="Stored library could not be read. Its bytes have been preserved: "..tostring(loaded) end
  end
  local session=state.session or {}
  local selected=session.id and session.id ~= "" and session.id or nil
  local mode,current_setlist=selected and "reader" or "library",nil
  if session.screen == "preferences" then mode="settings"
  elseif session.screen == "setlist_library" then mode="setlists"
  elseif session.screen == "song_library" then mode="library" end
  local shift,capo,scrolling,scroll,remainder=session.shift or 0,session.capo or 0,false,session.scroll or 0,0
  local draft_title,draft_body,editing_id="","",nil
  local selected_chord,variation=nil,1
  local dictionaries,custom={},{}
  local function custom_name(instrument) return instrument == "Guitar" and "custom-guitar.crd" or "custom-ukulele.crd" end
  for _,instrument in ipairs {"Guitar","Ukulele"} do
    custom[instrument]={}
    local content=platform.read(custom_name(instrument))
    if content then for _,line in ipairs(lines(content)) do
      local spelling,positions=line:match("^(.-):%s*(.-)$")
      local chord=spelling and music.parse(spelling)
      if chord then
        local frets={}
        for fret in positions:gmatch("[^%-]+") do frets[#frets+1]=tonumber(fret) or -1 end
        local key=music.print(chord)
        if #frets == (instrument == "Guitar" and 6 or 4) then
          custom[instrument][key]=custom[instrument][key] or {}
          table.insert(custom[instrument][key],frets)
        end
      end
    end end
  end
  local function save_custom()
    local output,keys={},{}
    for key in pairs(custom[state.instrument]) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do
      for _,frets in ipairs(custom[state.instrument][key]) do
        local values={}
        for _,fret in ipairs(frets) do values[#values+1]=fret < 0 and "x" or tostring(fret) end
        output[#output+1]=key..": "..table.concat(values,"-")
      end
    end
    return platform.write(custom_name(state.instrument),table.concat(output,"\n").."\n")
  end
  local left_handed=platform.read("laterality.txt") == "left"
  local function song_by_id(id)
    for _,song in ipairs(state.songs) do if song.id == id then return song end end
  end
  local function selected_song() return song_by_id(selected) end
  local function save()
    if locked then return false end
    local screens={library="song_library",reader="reading_song",diagram="reading_song",settings="preferences",
      setlists="setlist_library",setlist="setlist_library",["setlist-edit"]="setlist_library",custom="reading_song",
      edit="editing_song",import="online_search"}
    state.session={id=selected,screen=screens[mode] or "song_library",shift=shift,capo=capo,scroll=scroll}
    local encoded=encode(state)
    if encoded == raw then return true end
    if not platform.write("library.txt",encoded) then notice="Saving failed; existing data was retained"; return false end
    raw=encoded
    return true
  end
  local function dictionary()
    if dictionaries[state.instrument] then return dictionaries[state.instrument] end
    local asset=state.instrument == "Guitar" and "guitar_chords.json" or "ukulele_chords.json"
    local data,problem=json.decode(assert(platform.asset(asset),"Missing original chord dictionary"))
    assert(data,problem)
    local entries={}
    if state.instrument == "Guitar" then
      for spelling,positions in pairs(data) do
        local chord=music.parse(spelling)
        if chord then
          local variants={}
          for _,position in ipairs(positions) do
            local frets={}
            for _,fret in ipairs(position.positions or {}) do frets[#frets+1]=tonumber(fret) or -1 end
            if #frets == 6 then variants[#variants+1]=frets end
          end
          local key=music.fingering_lookup_key(chord)
          entries[key]=entries[key] or {}
          for _,frets in ipairs(variants) do entries[key][#entries[key]+1]=frets end
        end
      end
    else
      for _,group in pairs(data.chords or {}) do
        for _,entry in ipairs(group) do
          local chord=music.parse(entry.key..entry.suffix)
          if chord then
            local variants={}
            for _,position in ipairs(entry.positions or {}) do
              local frets={}
              for _,fret in ipairs(position.frets or {}) do
                frets[#frets+1]=fret > 0 and fret+(position.baseFret or 1)-1 or fret
              end
              if #frets == 4 then variants[#variants+1]=frets end
            end
            local key=music.fingering_lookup_key(chord)
            entries[key]=entries[key] or {}
            for _,frets in ipairs(variants) do entries[key][#entries[key]+1]=frets end
          end
        end
      end
    end
    dictionaries[state.instrument]=entries
    return entries
  end
  local function add(actions,id,label) actions[#actions+1]={id=id,label=label} end
  local function present()
    local model={title="ChordReader",notice=notice,body="",size=state.size,actions={}}
    local actions=model.actions
    if locked then model.body=notice; platform.present(model); return end
    add(actions,"library","Songs"); add(actions,"setlists","Setlists"); add(actions,"settings","Settings")
    if mode == "library" then
      add(actions,"new","New song"); add(actions,"import","Import / Search")
      model.body=#state.songs == 0 and "No songs saved. Create a song or import a plain-text chart." or ""
      for _,song in ipairs(state.songs) do add(actions,"open:"..song.id,song.title) end
    elseif mode == "reader" then
      local song=selected_song()
      if not song then mode="library"; return present() end
      model.title=song.title
      model.notice=notice..string.format("\nTranspose %+d   Capo %d   Speed %d px/s",shift,capo,state.speed)
      add(actions,"down","− semitone"); add(actions,"up","+ semitone"); add(actions,"edit","Edit")
      add(actions,"written-key","Transpose by key")
      add(actions,"capo-down","Capo −"); add(actions,"capo-up","Capo +"); add(actions,"share","Share")
      add(actions,"export","Save file")
      add(actions,"scroll",scrolling and "Pause" or "Auto scroll"); add(actions,"slower","Slower"); add(actions,"faster","Faster")
      local interval=state.key_interval or music.interval(shift)
      local capo_interval=music.interval(-capo)
      model.body=music.render(song.source,{letters=interval.letters+capo_interval.letters,
        semitones=interval.semitones-capo})
      model.spans={}
      local seen={}
      for _,located in ipairs(music.recognise(model.body)) do
        model.spans[#model.spans+1]={located.beginning.units,located.ending.units}
        local spelling=music.print(located.chord)
        if not seen[spelling] then add(actions,"chord:"..spelling,spelling); seen[spelling]=true end
      end
    elseif mode == "edit" or mode == "import" or mode == "setlist-edit" or mode == "custom" or mode == "written-key" then
      model.editable=true; model.edit_title=draft_title; model.body=draft_body
      model.title=mode == "written-key" and "Source tonic above; destination tonic below" or
        mode == "setlist-edit" and "Setlist: one song title per line" or
        mode == "custom" and "Fingering: x or fret, separated by spaces" or "Song title and chart text / URL"
      add(actions,"save","Save"); add(actions,"cancel","Cancel")
      if mode == "import" then
        add(actions,"fetch","Import URL"); add(actions,"search-web","Search web"); add(actions,"as-setlist","Import .pl setlist")
        add(actions,"choose-file","Choose file")
      end
    elseif mode == "setlists" then
      add(actions,"new-setlist","New setlist")
      for index,list in ipairs(state.setlists) do add(actions,"setlist:"..index,list.name) end
      model.body=#state.setlists == 0 and "No setlists saved." or ""
    elseif mode == "setlist" then
      local list=state.setlists[current_setlist]
      if not list then mode="setlists"; return present() end
      model.title=list.name; add(actions,"edit-setlist","Edit setlist"); add(actions,"share-setlist","Share .pl")
      add(actions,"export-setlist","Save .pl file")
      for _,id in ipairs(list.ids) do local song=song_by_id(id); if song then add(actions,"open:"..id,song.title) end end
    elseif mode == "settings" then
      model.body=string.format("Text size: %d\nScroll speed: %d px/s\nInstrument: %s\nHand: %s\n\nOriginal ChordReader resources and GPLv3+ attribution are retained.",state.size,state.speed,state.instrument,left_handed and "left" or "right")
      add(actions,"font-down","Smaller text"); add(actions,"font-up","Larger text"); add(actions,"instrument",state.instrument)
      add(actions,"slower","Slower scroll"); add(actions,"faster","Faster scroll"); add(actions,"hand","Left / right hand")
    elseif mode == "diagram" then
      model.title=selected_chord.." — "..state.instrument
      add(actions,"back-reader","Back to song"); add(actions,"previous-variation","Previous"); add(actions,"next-variation","Next")
      add(actions,"instrument",state.instrument); add(actions,"custom","Custom fingering")
      local variants=(custom[state.instrument] or {})[selected_chord] or
        dictionary()[music.fingering_lookup_key(assert(music.parse(selected_chord)))] or {}
      if #variants > 0 then
        variation=(variation-1)%#variants+1
        local frets={table.unpack(variants[variation])}
        if left_handed then for index=1,math.floor(#frets/2) do frets[index],frets[#frets-index+1]=frets[#frets-index+1],frets[index] end end
        model.frets=frets; model.base_fret=99
        for _,fret in ipairs(frets) do if fret > 0 then model.base_fret=math.min(model.base_fret,fret) end end
        model.base_fret=model.base_fret == 99 and 1 or model.base_fret
        model.body=string.format("Variation %d of %d\n",variation,#variants)
      else model.body="No stored fingering for this written chord. Add a custom fingering." end
    end
    platform.present(model)
    if mode == "reader" then platform.scroll(scroll) end
  end
  local function start_edit(target,title,body,id)
    scrolling=false; mode=target; draft_title=title or ""; draft_body=body or ""; editing_id=id
  end
  local function event(id,title,body)
    if locked then return end
    if id ~= "resume" and id ~= "suspend" then notice="" end
    if mode == "reader" then scroll=platform.scroll_position() end
    if id ~= "downloaded" and id ~= "download_failed" and id ~= "incoming" and id ~= "resume" and
      id ~= "exported" and id ~= "export_failed" and id ~= "import_failed" and
      (mode == "edit" or mode == "import" or mode == "setlist-edit" or mode == "custom" or mode == "written-key") then
      draft_title=title; draft_body=body
    end
    if id == "library" or id == "setlists" or id == "settings" then mode=id; scrolling=false
    elseif id == "new" or id == "import" then start_edit(id == "new" and "edit" or "import")
    elseif id:sub(1,5) == "open:" then
      selected=id:sub(6); mode="reader"; shift=0; capo=0; scroll=0; scrolling=false; state.key_interval=nil
    elseif id == "incoming" then
      if utf8.len(body) and not body:find("\0",1,true) then
        start_edit(title:lower():match("%.pl$") and "setlist-edit" or "import",basename(title),body)
      else notice="Import requires valid UTF-8 text without NUL bytes" end
    elseif id == "edit" then local song=assert(selected_song()); start_edit("edit",song.title,song.source,song.id)
    elseif id == "written-key" then start_edit("written-key","","")
    elseif id == "cancel" then mode=selected and "reader" or "library"
    elseif id == "as-setlist" then mode="setlist-edit"
    elseif id == "save" then
      if draft_title == "" then notice="Enter a title first"
      elseif mode == "written-key" then
        local interval,problem=music.key_interval(draft_title,draft_body)
        if interval then state.key_interval=interval; shift=interval.semitones; mode="reader"
        else notice=problem end
      elseif mode == "setlist-edit" then
        local ids,problem={},nil
        for _,name in ipairs(lines(draft_body)) do
          local found
          for _,song in ipairs(state.songs) do if basename(song.title) == basename(name) then found=song.id; break end end
          if not found then problem="Import the missing song first: "..name; break end
          ids[#ids+1]=found
        end
        if problem then notice=problem else
          local list={name=draft_title,ids=ids}
          if editing_id then state.setlists[editing_id]=list else state.setlists[#state.setlists+1]=list end
          if save() then mode="setlists" end
        end
      elseif mode == "custom" then
        local chord=music.parse(draft_title); local frets={}
        for fret in draft_body:gmatch("%S+") do frets[#frets+1]=fret == "x" and -1 or tonumber(fret) end
        local count=state.instrument == "Guitar" and 6 or 4
        if not chord or #frets ~= count then notice="Enter a valid chord and one fret or x per string"
        else
          local spelling=music.print(chord); custom[state.instrument]=custom[state.instrument] or {}
          custom[state.instrument][spelling]={frets}; selected_chord=spelling; variation=1
          if save_custom() then mode="diagram" else notice="Custom fingering could not be saved" end
        end
      else
        local song=editing_id and song_by_id(editing_id)
        if not song then
          local number=1; while song_by_id(tostring(number)) do number=number+1 end
          song={id=tostring(number)}; state.songs[#state.songs+1]=song
        end
        song.title=draft_title; song.source=draft_body; selected=song.id
        if save() then mode="reader"; scroll=0; shift=0; capo=0; state.key_interval=nil end
      end
    elseif id == "fetch" then
      if platform.fetch(draft_body) then notice="Downloading chart…" else notice="Enter an HTTPS chart URL in the text box" end
    elseif id == "downloaded" then
      local chart,problem=online_chart(body)
      if chart and utf8.len(chart) and not chart:find("\0",1,true) then draft_body=chart; if draft_title == "" then draft_title="Imported chart" end; mode="import"; notice="Review the imported text, then Save"
      elseif chart then notice="Import requires valid UTF-8 text without NUL bytes"
      else notice=problem end
    elseif id == "download_failed" then notice=body
    elseif id == "choose-file" then
      if not platform.choose_file() then notice="The Android document picker could not be opened" end
    elseif id == "import_failed" then notice="The selected document could not be read; existing songs were retained"
    elseif id == "exported" then notice="File saved"
    elseif id == "export_failed" then notice="The selected document could not be written; the song remains saved here"
    elseif id == "search-web" then platform.browse("https://www.startpage.com/sp/search?q="..url_encode(draft_title.." chords"))
    elseif id == "up" then shift=shift+1; state.key_interval=nil; scroll=platform.scroll_position()
    elseif id == "down" then shift=shift-1; state.key_interval=nil; scroll=platform.scroll_position()
    elseif id == "capo-up" then capo=capo+1; scroll=platform.scroll_position()
    elseif id == "capo-down" then capo=math.max(0,capo-1); scroll=platform.scroll_position()
    elseif id == "scroll" then scrolling=not scrolling; scroll=platform.scroll_position()
    elseif id == "slower" then state.speed=math.max(0,state.speed-4); save()
    elseif id == "faster" then state.speed=state.speed+4; save()
    elseif id == "font-down" then state.size=math.max(8,state.size-2); save()
    elseif id == "font-up" then state.size=math.min(96,state.size+2); save()
    elseif id == "instrument" then state.instrument=state.instrument == "Guitar" and "Ukulele" or "Guitar"; variation=1; save()
    elseif id == "hand" then left_handed=not left_handed; platform.write("laterality.txt",left_handed and "left" or "right")
    elseif id == "share" then local song=assert(selected_song()); platform.share(song.title..".txt",song.source)
    elseif id == "export" then
      local song=assert(selected_song())
      if not platform.export(song.title..".txt",song.source) then notice="The Android save dialog could not be opened" end
    elseif id == "new-setlist" then start_edit("setlist-edit")
    elseif id:sub(1,8) == "setlist:" then current_setlist=tonumber(id:sub(9)); mode="setlist"
    elseif id == "edit-setlist" then
      local list=state.setlists[current_setlist]; local titles={}
      for _,identifier in ipairs(list.ids) do local song=song_by_id(identifier); if song then titles[#titles+1]=song.title..".txt" end end
      start_edit("setlist-edit",list.name,table.concat(titles,"\n"),current_setlist)
    elseif id == "share-setlist" or id == "export-setlist" then
      local list=state.setlists[current_setlist]; local titles={}
      for _,identifier in ipairs(list.ids) do local song=song_by_id(identifier); if song then titles[#titles+1]=song.title..".txt" end end
      local source=table.concat(titles,"\n").."\n"
      if id == "share-setlist" then platform.share(list.name..".pl",source)
      elseif not platform.export(list.name..".pl",source) then notice="The Android save dialog could not be opened" end
    elseif id:sub(1,6) == "chord:" then selected_chord=id:sub(7); variation=1; mode="diagram"; scrolling=false
    elseif id == "previous-variation" then variation=variation-1
    elseif id == "next-variation" then variation=variation+1
    elseif id == "custom" then start_edit("custom",selected_chord,"")
    elseif id == "back-reader" then mode="reader"
    elseif id == "resume" then
      local latest=platform.read("library.txt")
      if latest and latest ~= raw then
        local valid,loaded=pcall(decode,latest)
        if valid then
          state.songs=loaded.songs; state.setlists=loaded.setlists
          state.size=loaded.size; state.speed=loaded.speed; state.instrument=loaded.instrument
          raw=latest
          if selected and not selected_song() then selected=nil; mode="library"; scrolling=false end
        else locked=true; notice="Stored library changed to an unreadable format; its bytes were preserved"; present(); return end
      end
    elseif id == "suspend" then scrolling=false; save(); return end
    save()
    present()
  end
  local function tick(elapsed)
    if not locked and scrolling and mode == "reader" then
      local distance=elapsed*state.speed+remainder
      remainder=distance%1000
      scroll=platform.scroll_position()+math.floor(distance/1000)
      platform.scroll(scroll)
    end
  end
  present()
  return {event=event,tick=tick,stop=save, snapshot=function() return encode(state) end}
end
return {new=new,encode=encode,decode=decode,online_chart=online_chart}
