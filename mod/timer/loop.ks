@lazyglobal off.

parameter proc.

print proc["pid"] + ":" + proc["interval"] + ":" + proc["max"] + ":" + proc["counter"].
set proc["counter"] to proc["counter"] + proc["interval"].
if(proc["max"] > 0 and proc["counter"] > proc["max"]) {
    print proc["pid"] + ": done".
    kmos["stop"](proc["pid"]).
}