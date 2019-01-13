@lazyglobal off.

parameter instroot is "1:".

print "#############################################".
print "###### Kerbal Modular Operating System ######".
print "#############################################".

local core is list("coreutils").
for s in core {
  runoncepath(instroot + "/base/" + s).
}

local tasks is list().
local lib is list().

global kmos is lexicon(
  "verbose", true,
  "start", {
    parameter mod, args is list().
    if(kmos["verbose"]) {
      print "KMOS - start: " + mod + " " + args:join(" ").
    }
    local pid is tasks:length().
    for m in tasks {
      if(m["state"] = "done") {
        set pid to m["pid"].
      }
    }
    local task is lexicon(
      "pid", pid,
      "mod", mod,
      "args", args,
      "state", "init",
      "interval", 0,
      "last", 0
    ).
    local path is instroot+"/mod/"+mod.
    if(exists(path+"/lib")) {
      load(path+"/lib").
    }
    if(pid = tasks:length()) {
      tasks:add(task).
    } else {
      set tasks[pid] to task.
    }
    if(exists(path+"/exec")) {
      runpath(path+"/exec", task).
    }
    if(exists(path+"/run")) {
      runpath(path+"/run", task).
    }
    if(exists(path+"/loop")) {
      set task["state"] to "loop".
    } else if(task["state"] = "init") {
      set task["pii"]["state"] to "wait".
    }
    st_tasks().
  },
  "stop",{
    parameter pid.
    local task is tasks[pid].
    local path is instroot+"/mod/" + task["mod"].
    if(kmos["verbose"]) {
      print "KMOS - stop: <" + pid + "> " + task["mod"] + " " + task["args"]:join(" ").
    }
    if(exists(path+"/stop")) {
      runpath(path+"/stop", task).
    }
    if(task["state"] = "loop") {
      set task["state"] to "exit".
    } else {
      set task["state"] to "done".
    }
    st_tasks().
  },
  "cmd", {
    parameter id, args is list().
    if(kmos["verbose"]) {
      print "KMOS - cmd: " + id + " " + args:join(" ").
    }
    local code is "runpath(" + char(34) + instroot+"/cmd/" + id + char(34).
    for a in args {
      set code to code + "," + var2code(a).
    }
    set code to code + ").".
    exec(code).
  },
  "exec", {
    parameter id, args is list().
    if(exists(instroot+"/mod/" + id)) {
      kmos["start"](id,args).
    } else {
      kmos["cmd"](id,args).
    }
  },
  "exit", {
    if(kmos["verbose"]) {
      print "KMOS - exit".
    }
    for p in tasks {
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
      "tasks", tasks:copy,
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
local function st_tasks {
  writejson(tasks, instroot+"/run/tasks").
}


if(exists(instroot+"/run/tasks")) {
  print "loading task state...".
  if(exists(instroot+"/run/lib")) {
    load(instroot+"/run/lib").
  }
  set tasks to readjson(instroot+"/run/tasks").
  for task in tasks {
    print "> " + task["mod"] + ":" + task["pid"].
    local path is instroot+"/mod/"+task["mod"].
    if(exists(path + "/boot")) {
      runpath(path + "/boot", task).
    }
    if(exists(path + "/run")) {
      runpath(path + "run", task).
    }
  }
} else {
  print "initializing...".
  runpath(instroot+"/base/init").
}
print "kmos booted.".

until tasks:length = 0 {
  for task in tasks {
    local path is instroot+"/mod/" + task["mod"] + "/loop".
    if(task["state"] = "loop" and exists(path) and
      task["last"] + task["interval"] < time:seconds) {
      if(kmos["verbose"]) {
        print "KMOS - loop: <" + task["pid"] + "> " + task["mod"] + " " + task["args"]:join(" ").
      }
      runpath(path, task).
      set task["last"] to time:seconds.
      if(task["state"] = "exit") {
        set task["state"] to "done".
      }
      st_tasks().
    }
  }
  until tasks:length = 0 or tasks[tasks:length-1]["state"] <> "done" {
    tasks:remove(tasks:length-1).
  }
  wait 0.
}