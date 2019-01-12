@lazyglobal off.

parameter instroot is "1:".

print "#############################################".
print "###### Kerbal Modular Operating System ######".
print "#############################################".

local core is list("coreutils").
for s in core {
  runoncepath(instroot + "/base/" + s).
}

local ppi is list().
local lib is list().

global kmos is lexicon(
  "verbose", true,
  "start", {
    parameter bin, args is list().
    if(kmos["verbose"]) {
      print "KMOS - start: " + bin + " " + args:join(" ").
    }
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
    local path is instroot+"/mod/"+bin.
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
    local path is instroot+"/mod/" + proc["bin"].
    if(kmos["verbose"]) {
      print "KMOS - stop: <" + pid + "> " + proc["bin"] + " " + proc["args"]:join(" ").
    }
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
    if(kmos["verbose"]) {
      print "KMOS - cmd: " + bin + " " + args:join(" ").
    }
    local code is "runpath(" + char(34) + instroot+"/cmd/" + bin + char(34).
    for a in args {
      set code to code + "," + var2code(a).
    }
    set code to code + ").".
    exec(code).
  },
  "exec", {
    parameter bin, args is list().
    if(exists(instroot+"/mod/" + bin)) {
      kmos["start"](bin,args).
    } else {
      kmos["cmd"](bin,args).
    }
  },
  "exit", {
    if(kmos["verbose"]) {
      print "KMOS - exit".
    }
    for p in ppi {
      kmos["stop"](p["pid"]).
    }
  },
  "reboot",{
    kmos["exit"]().
    deletepath(instroot + "/run").
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

local  function load {
  parameter file.
  local lfi is open(file):readall:iterator.
  until(not lfi:next) {
    local path is instroot+"/lib/"+lfi:value.
    if(not lib:contains(lfi:value)) {
      if(kmos["verbose"]) {
        print "KMOS - lib: " + lfi:value.
      }
      lib:add(lfi:value).
      runoncepath(path).
    }
  }
  writejson(lib, instroot+"/run/lib").
}
local function st_proc {
  writejson(ppi, instroot+"/run/proc").
}


if(exists(instroot+"/run/proc")) {
  print "loading proc state...".
  if(exists(instroot+"/run/lib")) {
    load(instroot+"/run/lib").
  }
  set ppi to readjson(instroot+"/run/proc").
  for proc in ppi {
    print "> " + proc["bin"] + ":" + proc["pid"].
    local path is instroot+"/mod/"+proc["bin"].
    if(exists(path + "/boot")) {
      runpath(path + "/boot", proc).
    }
    if(exists(path + "/run")) {
      runpath(path + "run", proc).
    }
  }
} else {
  print "initializing...".
  for f in open(instroot + "/init"):list:keys {
    runpath(instroot + "/init/" + f).
  }
}
print "kmos booted.".

until ppi:length = 0 {
  for proc in ppi {
    local path is instroot+"/mod/" + proc["bin"] + "/loop".
    if(proc["state"] = "loop" and exists(path) and
      proc["last"] + proc["interval"] < time:seconds) {
      if(kmos["verbose"]) {
        print "KMOS - loop: <" + proc["pid"] + "> " + proc["bin"] + " " + proc["args"]:join(" ").
      }
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