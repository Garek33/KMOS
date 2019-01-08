@lazyglobal off.

print "#############################################".
print "###### KMOS Startup #########################".
print "#############################################".

runpath("1:/base/coreutils").

local ppi is list().
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


global kmos is lexicon(
  "start", {
    parameter bin, args is list().
    local pid is ppi:length().
    for m in ppi {
      if(m["state"] = "done") {
        set pid to m["pid"].
      }
    }
    local proc is lexicon(
      "pid", pid,
      "bin", bin,
      "args", args,
      "state", "init",
      "interval", 0,
      "last", 0
    ).
    local path is "1:/mod/"+bin.
    if(exists(path+"/lib")) {
      load(path+"/lib").
    }
    if(pid = ppi:length()) {
      ppi:add(proc).
    } else {
      set ppi[pid] to proc.
    }
    if(exists(path+"/exec")) {
      runpath(path+"/exec", proc).
    }
    if(exists(path+"/run")) {
      runpath(path+"/run", proc).
    }
    if(exists(path+"/loop")) {
      set proc["state"] to "loop".
    } else if(proc["state"] = "init") {
      set proc["pii"]["state"] to "wait".
    }
    st_proc().
  },
  "stop",{
    parameter pid.
    local proc is ppi[pid].
    local path is "1:/mod/" + proc["bin"].
    if(exists(path+"/stop")) {
      runpath(path+"/stop", proc).
    }
    if(proc["state"] = "loop") {
      set proc["state"] to "exit".
    } else {
      set proc["state"] to "done".
    }
    st_proc().
  },
  "cmd", {
    parameter bin, args is list().
    local code is "runpath(" + char(34) + "1:/cmd/" + bin + char(34).
    for a in args {
      set code to code + "," + var2code(a).
    }
    set code to code + ").".
    make_dlg(code)().
  },
  "exec", {
    parameter cl.
    local args is list().
    local cur is "".
    local istr is false.
    local iesc is false.
    for c in cl {
      if(iesc) {
        set cur to cur+c.
        set iesc to false.
      } else if(c = "\") {
        set iesc to true.
      } else if(c = char(34)) {
        toggle istr.
      } else if(c = " " and not istr) {
        args:add(cur).
        set cur to "".
      } else {
        set cur to cur+c.
      }
    }
    if(cur:length > 0) {
      args:add(cur).
    }
    if(args:length < 1) {
      //TODO: error?!
      return.
    }
    local bin is args[0].
    args:remove(0).
    if(exists("1:/mod/" + bin)) {
      kmos["start"](bin,args).
    } else {
      kmos["cmd"](bin,args).
    }
  },
  "exit", {
    for p in ppi {
      kmos["stop"](p["pid"]).
    }
  },
  "reboot",{
    kmos["exit"]().
    deletepath("1:/run/proc").
    deletepath("1:/run/lib").
    reboot.
  },
  "info",{
    return lexicon(
      "version", "0.1",
      "proc", ppi:copy,
      "lib", lib:copy
    ).
  }
).


if(exists("1:/run/proc")) {
  print "loading proc state...".
  if(exists("1:/run/lib")) {
    load("1:/run/lib").
  }
  set ppi to readjson("1:/run/proc").
  for proc in ppi {
    print "> " + proc["bin"] + ":" + proc["pid"].
    local path is "1:/mod/"+proc["bin"].
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
      local cmd is ae:value.
      print "> " + cmd.
      kmos["exec"](cmd).
    }
  }
}
print "kmos booted.".

until ppi:length = 0 {
  for proc in ppi {
    local path is "1:/mod/" + proc["bin"] + "/loop".
    if(proc["state"] = "loop" and exists(path) and
       proc["last"] + proc["interval"] < time:seconds) {
      runpath(path, proc).
      set proc["last"] to time:seconds.
      if(proc["state"] = "exit") {
        set proc["state"] to "done".
      }
      st_proc().
    }
  }
  until ppi:length = 0 or ppi[ppi:length-1]["state"] <> "done" {
    ppi:remove(ppi:length-1).
  }
  wait 0.
}