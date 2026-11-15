-- SPDX-License-Identifier: GPL-3.0-or-later
-- Prove the transport regression rejects omitted cache dependencies and checks.
-- These are in-memory source mutations; production files are never modified.
local repository=assert(arg[1],"Absolute repository path required")
local file=assert(io.open(repository.."/contingency/app.lua","rb"))
local source=file:read("a"); file:close()
local cases={
  {"repeated-validation","if raw_checked and encoded == raw then return true end","",
    "Read-only toggles must not validate/write"},
  {"unverified-restored-snapshot","local raw_checked=false","local raw_checked=true",
    "Restored snapshot must be checked once before reuse"},
  {"shift","cached_chart.shift ~= shift or","",
    "Shift must invalidate the checked chart"},
  {"capo","cached_chart.capo ~= capo or","",
    "Stale cached chart after capo-up"},
  {"source","cached_chart.song_source ~= song.source or","",
    "Stale cached chart after resume"},
  {"written-interval","cached_chart.interval_key ~= interval_key or","",
    "Stale cached chart after save"},
  {"display-key","cached_chart.display_key ~= display_key","false",
    "Stale cached chart after save"},
  {"external-snapshot","raw_checked=false\n          if selected","raw_checked=true\n          if selected",
    "Externally loaded snapshot must be rechecked"},
}
for _,case in ipairs(cases) do
  local first,last=source:find(case[2],1,true)
  assert(first,"Missing mutation target: "..case[1])
  assert(not source:find(case[2],last+1,true),"Ambiguous mutation target: "..case[1])
  local mutant=source:sub(1,first-1)..case[3]..source:sub(last+1)
  local compiled=assert(load(mutant,"@transport-mutant-"..case[1],"t"))
  package.loaded.app=nil
  package.preload.app=compiled
  local passed,problem=pcall(assert(loadfile(repository.."/contingency/latency-regression-test.lua")))
  assert(not passed,"Accepted transport mutant: "..case[1])
  assert(tostring(problem):find(case[4],1,true),"Wrong refusal for "..case[1]..": "..tostring(problem))
  print("PASS\tRejected transport mutant: "..case[1].." / "..case[4])
end
package.loaded.app=nil
package.preload.app=nil
