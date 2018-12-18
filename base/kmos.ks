@lazyglobal off.

print "#############################################".
print "###### KMOS Startup #########################".
print "#############################################".

if(not exists("1:/run/proc")) {
  print "rebooting...".
  if(not exists("1:/boot/proc")) {
    local proc is lexicon(
      "sh",
      lexicon(
        "args", 0,
        "interval", 0,
        "last", 0
      )
    ).
    writejson(proc, "1:/boot/proc").
    print "FATAL: no proc found. example json written to /boot/proc".
    print "will work with sh. otherwise edit to fit. Also consider /boot/lib".
    exit.
  }
  copypath("1:/boot/proc", "1:/run/proc").
  if(exists("1:/boot/lib")) {
    copypath("1:/boot/lib", "1:/run/lib").
  }
  print "run info initialised.".
}

local ppi is readjson("1:/run/proc").
local dpi is lexicon().
local lib is list().

if(exists("1:/run/lib")) {
  print "loading libraries...".
  set lib to readjson("1:/run/lib").
  for l in lib {
     print "> " + l.
     runoncepath(l).
  }
  print "libraries loaded.".
}

print "booting...".
for pid in ppi:keys {
  print "> " + pid.
  local proc is lexicon(
    "id", pid,
    "ppi", ppi[pid]
  ).
  dpi:add(pid, proc).
  local path is "1:/bin/" + pid.
  if(exists(path + "/boot")) {
    runpath(path + "/boot", proc).
  }
  if(exists(path + "/run")) {
    runpath(path + "/run", proc).
  }
}
print "done.".

local st_proc is {
  writejson(ppi, "1:/run/proc").
}.
local st_lib is {
  writejson(lib, "1:/run/lib").
}.

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

local load is {
  parameter _lib.
  if(not lib:contains(_lib)) {
    lib:add(_lib).
    runoncepath(_lib).
    st_lib().
  }
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
  "start", {
    parameter id, args.
    local path is "1:/bin/" + id.
    if(not exists(path)) {
      return error("kmos:start:bin_missing", "Missing path 1:/bin/"+id).
    }
    local proc is lexicon(
      "id", id,
      "ppi", lexicon(
        "args", args,
        "interval", 0,
        "last", 0
      )
    ).
    ppi:add(id, proc["ppi"]).
    dpi:add(id, proc).
    if(exists(path+"/lib")) {
      local lib is open(path+"/lib"):readall:iterator.
      until(not lib:next) {
        load(lib:value).
      }
    }
    if(exists(path+"/exec")) {
      runpath(path+"/exec", proc).
    }
    if(exists(path+"/run")) {
      runpath(path+"/run", proc).
    }
    if(not exists(path+"/stop") and
       not exists(path+"/loop")) {
      ppi:remove(id).
      dpi:remove(id).
    } else {
      st_proc().
    }
  },
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