@lazyglobal off.

parameter name, srcroot, instroot is "1:".

local mods is uniqueset().
local cmds is uniqueset().
local libs is uniqueset().

local addlst is {
    parameter fn.
    if(not exists(fn)) {
        return.
    }
    local lst is open(fn):readall:iterator.

    until not lst:next {
        local id is lst:value.
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
    }
}.

addlst(srcroot + "/setup/" + name + ".ksl").

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

copypath(srcroot + "/setup/" + name + ".ae", instroot + "/base/autoexec").

local bootpath is instroot + "/base/kmos".
if(bootpath:matchespattern("^[^/]:/")) {
    local index is bootpath:find(":").
    set bootpath to bootpath:substring(index+2, bootpath:length -index -2).
}
set core:bootfilename to bootpath.

reboot.