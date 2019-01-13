@lazyglobal off.

parameter _srcroot.
global srcroot is _srcroot.
global instroot is "1:".
global setupid is "".
global instdbg is false.

//extract parameters from tag
{
    local p is "".
    local i is 0.
    local n is 0.
    local k is 0.
    local t is core:tag.
    if(t = "@") {
        set i to 1.
        set instdbg to true.
        set t to t:substring(1,t:length-1).
    } else {
        set i to 2.
    }
    for c in t {
        if(c = ":") {
            if(i = 1) {
                set instroot to p.
            } else {
                set setupid to p.
                set k to n+2.
            }
            set p to "".
            set i to i+1.
        } else if(i = 2 and p = "" and c = "!") {
            set instdbg to true.
        } else {
            set p to p + c.
        }
        set n to n+1.
    }
    if(i = 2) {
        set setupid to p.
    }
    set core:part:tag to t:substring(k, t:length-k).
}

terminal:put("KMOS: Setup <" + setupid + "> from <" + srcroot + "> in <" + instroot).
if(instdbg) {
    print "> in debug mode".
} else {
    print "> in release mode".
}

local mods is uniqueset().
local cmds is uniqueset().
local libs is uniqueset().

global install is {
    parameter id.
    if(exists(srcroot + "/mod/" + id)) {
        mods:add(id).
        addlst(srcroot + "/mod/" + id + "/lib").
        addlst(srcroot + "/mod/" + id + "/dep").
    } else if(exists(srcroot + "/cmd/" + id)) {
        cmds:add(id).
        addlst(srcroot + "/cmd/" + id + ".dep").
    } else if(exists(srcroot + "/lib/" + id)) {
        libs:add(id).
        addlst(srcroot + "/lib/" + id + ".dep").
    } else {
        //TODO: ERROR!
    }
}.

local function addlst {
    parameter fn.
    if(not exists(fn)) {
        return.
    }
    local lst is open(fn):readall:iterator.

    until not lst:next {
        install(lst:value).   
    }
}

global instfile is {
    parameter srcpath, destpath.
    set srcpath to path(srcpath:tostring).
    set destpath to path(destpath:tostring).
    local f is open(srcpath).
    if(srcpath:extension = "" and f:extension = "ks") { //hasextension returns true in this case
        set srcpath to srcpath:changeextension("ks").
        if(destpath:extension = "") {
            set destpath to destpath:changeextension("ks").
        }
    }
    if(not f:isfile) {
        for c in f:list:keys {
            instfile(srcpath:combine(c), destpath:combine(c)).
        }
    } else {
        if(srcpath:extension = "ks" and not instdbg) {
            local cdest is destpath:changeextension("ksm").
            compile srcpath to cdest.
            local cf is open(cdest).
            if(cf:size >= f:size) {
                deletepath(cdest).
                copypath(srcpath, destpath).
            }
        } else {
            copypath(srcpath, destpath).
        }
    }
}.

global init is {
    parameter fn.
    instfile(srcroot + "/init/" + fn, instroot + "/base/init").
}.

runpath(srcroot + "/setup/" + setupid).

local rss is {
    parameter path.
    if(exists(path)) {
        runpath(path, srcroot, instroot).
    }
}.

local kmoscore is list("/base/kmos", "/base/coreutils", "/base/event").

for f in kmoscore {
    instfile(srcroot + f, instroot + f).
}

for mod in mods {
    instfile(srcroot + "/mod/" + mod, instroot + "/mod/" + mod).
    rss(srcroot + "/mod/" + mod + "/setup").
}

for cmd in cmds {
    instfile(srcroot + "/cmd/" + cmd, instroot + "/cmd/" + cmd).
    rss(srcroot + "/cmd/" + cmd + ".setup").
}

for lib in libs {
    instfile(srcroot + "/lib/" + lib, instroot + "/lib/" + lib).
    rss(srcroot + "/lib/" + lib + ".setup").
}

local bootpath is instroot + "/base/kmos".
if(bootpath:matchespattern("^[^/]:/")) {
    local index is bootpath:find(":").
    set bootpath to bootpath:substring(index+2, bootpath:length -index -2).
}
set core:bootfilename to bootpath.

reboot.