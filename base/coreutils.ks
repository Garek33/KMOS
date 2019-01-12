@lazyglobal off.

local tmpidx is 0.
deletepath("1:/tmp").
createdir("1:/tmp").
global getTmpFn is {
    local fn is "1:/tmp/_" + tmpidx.
    set tmpidx to tmpidx+1.
    return fn.
}.

global var2code is {
    parameter x.
    if(x:typename = "":typename) {
        return char(34) + x:replace(char(34), char(34)+"+char(34)+"+char(34)) + char(34).
    } else if(x:typename = 1:typename or x:typename = true:typename) {
        return x:tostring.
    } else {
        local tfn is getTmpFn().
        writejson(x, tfn).
        return "readjson(" + char(34) + tfn + char(34) + ")".
    }
}.

global __eval__helper__ is {return 0.}.
global make_dlg is {
    parameter code.
    local fn is getTmpFn().
    create(fn).
    local f is open(fn).
    f:writeln("@lazyglobal off.").
    f:writeln("set __eval__helper__ to {").
    f:writeln(code).
    f:writeln("}.").
    runpath(fn).
    deletepath(fn).
    return __eval__helper__.
}.
global eval is {
    parameter code.
    return make_dlg("return (" + code + ").")().
}.
global exec is {
    parameter code.
    return make_dlg(code)().
}.