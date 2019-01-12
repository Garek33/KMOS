@lazyglobal off.

parameter proc.
set proc["interval"] to proc["args"][0].
if(proc["args"]:length > 1) {
    proc:add("max", proc["args"][1]).
} else {
    proc:add("max", "-1").
}
proc:add("counter", 0).