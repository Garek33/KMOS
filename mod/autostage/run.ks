@lazyglobal off.

parameter pd, dtd.

set dtd["use"] to {
    local ae is 0.
    list engines in ae.
    set dtd["se"] to list().
    for e in ae {
        if(e:ignition) {
            print "autostage: registerd engine <" + e:tag + "> (" + e:title + ")".
            dtd["se"]:add(e).
        }
    }
}.

dtd["use"]().