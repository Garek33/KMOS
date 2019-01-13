@lazyglobal off.

parameter _instroot is "1:".
global instroot is _instroot.

print "#############################################".
print "###### Kerbal Modular Operating System ######".
print "#############################################".

local core is list("logging", "coreutils", "event").
for s in core {
  runoncepath(instroot + "/base/" + s).
}

local tasks is list().
local dtd is list().
local lib is list().

global kmos is lexicon(
  "start", {
    parameter mod, args is list().
    dolog("kmos","start: " + mod + " " + args:join(" ")).
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
      dtd:add(lexicon()).
    } else {
      set tasks[pid] to task.
      set dtd[pid] to lexcion().
    }
    if(exists(path+"/exec")) {
      runpath(path+"/exec", task, dtd[pid]).
    }
    if(exists(path+"/run")) {
      runpath(path+"/run", task, dtd[pid]).
    }
    if(exists(path+"/loop")) {
      set task["state"] to "loop".
    } else if(task["state"] = "init") {
      set task["state"] to "empty".
    }
    st_tasks().
    return pid.
  },
  "stop",{
    parameter pid.
    local task is tasks[pid].
    local path is instroot+"/mod/" + task["mod"].
    dolog("kmos", "stop: <" + pid + "> " + task["mod"] + " " + task["args"]:join(" ")).
    if(exists(path+"/stop")) {
      runpath(path+"/stop", task, dtd[pid]).
    }
    if(task["state"] = "loop") {
      set task["state"] to "exit".
    } else {
      set task["state"] to "done".
    }
    event("kmos:stop:"+pid)["trigger"]().
    st_tasks().
  },
  "wait",{
    parameter waiter, waitee.
    dolog("kmos", "wait: <" + waiter + "> for <" + waitee + ">").
    set tasks[waiter]["state"] to "wait".
    event("kmos:stop:"+waitee)["sub"](
      "kmos:waiter:"+waiter,
      "kmos["+char(34)+"unwait"+char(34)+"]("+waiter+","+waitee+","+char(34)+tasks[waiter]["state"]+char(34)+")."
    ).
  },
  "unwait",{
    parameter waiter, waitee, rstate.
    dolog("kmos", "unwait: <" + waiter + "> for <" + waitee + ">, resetting to " + rstate).
    local t is tasks[waiter].
    if(t["state"] = "wait") {
      set t["state"] to rstate.
    }
    event("kmos:stop:"+waitee)["unsub"]("kmos:waiter:"+waiter).
  },
  "cmd", {
    parameter id, args is list().
    dolog("cmd: " + id + " " + args:join(" ")).
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
    dolog("kmos", "exit").
    for p in tasks {
      kmos["stop"](p["pid"]).
    }
  },
  "reboot",{
    kmos["exit"]().
    deletepath(instroot + "/run").
    reboot.
  }
).

local  function load {
  parameter file.
  local lfi is open(file):readall:iterator.
  until(not lfi:next) {
    local path is instroot+"/lib/"+lfi:value.
    if(not lib:contains(lfi:value)) {
      dolog("kmos","lib: " + lfi:value).
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
    dtd:add(lexicon()).
    if(exists(path + "/boot")) {
      runpath(path + "/boot", task, dtd[dtd:length-1]).
    }
    if(exists(path + "/run")) {
      runpath(path + "/run", task, dtd[dtd:length-1]).
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
      dolog("kmos","loop: <" + task["pid"] + "> " + task["mod"] + " " + task["args"]:join(" "), -1).
      runpath(path, task, dtd[task["pid"]]).
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