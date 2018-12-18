@lazyglobal off.

print "#############################################".
print "###### KMOS Startup #########################".
print "#############################################".

local ppi is lexicon().
local dpi is lexicon().
local lib is list().


local load is {
  parameter file.
  local lfi is open(file):readall:iterator.
  until(not lfi:next) {
    local path is "1:/lib/"+lfi:value.
    if(not lib:contains(lfi:value)) {
      lib:add(lfi:value).
      runoncepath(path).
    }
  }
  writejson(lib, "1:/run/lib").
}.
local st_proc is {
  writejson(ppi, "1:/run/proc").
}.
local nproc is {
  parameter pid, args is list().
  local proc is lexicon(
    "id", pid,
    "ppi", lexicon(
      "args", args,
      "interval", 0,
      "last", 0
    )
  ).
  local path is "1:/bin/"+pid.
  if(exists(path+"/lib")) {
    load(path+"/lib").
  }
  dpi:add(pid,proc).
  ppi:add(pid,proc["ppi"]).
  if(exists(path+"/exec")) {
    runpath(path+"/exec", proc).
  }
  if(exists(path+"/run")) {
    runpath(path+"/run", proc).
  }
  st_proc().
}.

if(exists("1:/run/proc")) {
  print "loading proc state...".
  if(exists("1:/run/lib")) {
    load("1:/run/lib").
  }
  set ppi to readjson("1:/run/proc").
  for pid in ppi:keys {
    print "> " + pid.
    local proc is lexicon(
      "id", pid,
      "ppi", ppi[pid]
    ).
    dpi:add(pid, proc).
    local path is "1:/bin/"+pid.
    if(exists(path + "/boot")) {
      runpath(path + "/boot", proc).
    }
    if(exists(path + "/run")) {
      runpath(path + "run", proc).
    }
  }
} else {
  if(not exists("1:/base/autoexec")) {
    print "FATAL: missing base/autoexec!".
  } else {
    print "autoexec...".
    local ae is open("1:/base/autoexec"):readall:iterator.
    until(not ae:next) {
      local pid is ae:value.
      print "> " + pid.
      nproc(pid).
    }
  }
}
print "kmos booted.".

local ok is lexicon(
  "tag", "OK",
  "msg", "OK"
).
local logerror is {
  parameter tag, msg.
  log tag + ": " + msg to "1:/log/kmos.errors".
  return lexicon(
    "tag", tag,
    "msg", msg
  ).
}.

local stop is {
  parameter id.
  local proc is dpi[id].
  local path is "1:/bin/" + id.
  if(not exists(path)) {
    return error("kmos:stop:bin_missing", "Missing path 1:/bin/"+id).
  }
  if(exists(path+"/stop")) {
    runpath(path+"/stop", proc).
  }
  ppi:remove(id).
  dpi:remove(id).
  st_proc().
}.
local do_exit is {
  for p in dpi:keys {
    stop(p).
  }
}.

global kmos is lexicon(
  "load", load,
  "start", nproc,
  "stop", stop,
  "exit", do_exit,
  "reboot", {
    do_exit.
    deletepath("1:/run/proc").
    deletepath("1:/run/lib").
    reboot.
  },
  "info", {
    return lexicon(
      "version", "0.1",
      "proc", dpi:copy,
      "lib", lib:copy
    ).
  }
).

until dpi:length = 0 {
  for p in dpi:keys {
    local path is "1:/bin/" + p + "/loop".
    local proc is dpi[p].
    if(exists(path) and
       proc["ppi"]["last"] + proc["ppi"]["interval"] < time:seconds) {
      set proc["ppi"]["last"] to time:seconds.
      runpath(path, proc).
      st_proc().
    }
  }
  wait 0.
}