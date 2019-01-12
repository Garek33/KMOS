@lazyglobal off.

parameter name, srcroot, instroot is "1:".

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

global init is {
    parameter fn.
    copypath(srcroot + "/init/" + fn, instroot + "/base/init").
}.

runpath(srcroot + "/setup/" + name).

local rss is {
    parameter path.
    if(exists(path)) {
        runpath(path, srcroot, instroot).
    }
}.

copypath(srcroot + "/base/kmos", instroot + "/base/kmos").
copypath(srcroot + "/base/coreutils", instroot + "/base/coreutils").

for mod in mods {
    copypath(srcroot + "/mod/" + mod, instroot + "/mod/" + mod).
    rss(srcroot + "/mod/" + mod + "/setup").
}

for cmd in cmds {
    copypath(srcroot + "/cmd/" + cmd, instroot + "/cmd/" + cmd).
    rss(srcroot + "/cmd/" + cmd + ".setup").
}

for lib in libs {
    copypath(srcroot + "/lib/" + lib, instroot + "/lib/" + lib).
    rss(srcroot + "/lib/" + lib + ".setup").
}

local bootpath is instroot + "/base/kmos".
if(bootpath:matchespattern("^[^/]:/")) {
    local index is bootpath:find(":").
    set bootpath to bootpath:substring(index+2, bootpath:length -index -2).
}
set core:bootfilename to bootpath.

reboot.