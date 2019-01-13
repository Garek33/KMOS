@lazyglobal off.

global loglevel is lexicon().
global logtoterm is true.
global logtofile is true.
global dolog is {
    parameter mod, msg, prio is 0.
    local mp is 0.
    if(loglevel:haskey(mod)) {
        set mp to loglevel[mod].
    }
    if(prio < mp) {
        return.
    }
    local ts is time:calendar + " @ " + time:clock.
    if(logtoterm) {
        print ts + " - " + mod + ": " + msg.
    }
    if(logtofile) {
        log ts + " - " + msg to instroot + "/log/" + mod.
    }
}.