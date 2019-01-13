@lazyglobal off.

parameter pd, dtd.

if(pd["step"] = 0) {
    if(ship:maxthrust > 0) {
        print "autostage: detected launch!".
        set pd["step"] to 1.
        dtd["use"]().
    }
} else if(pd["step"] = 1) {
    for e in dtd["se"] {
        if(e:flameout) {
            print "autostage: staging for flameout of engine <" + e:tag + "> (" + e:title + ")".
            set pd["step"] to 2.
            set pd["interval"] to 2.
            if(stage:ready) {
                stage.
            } else {
                print "autostage: stage unexpectedly not ready!".
            }
        }
    }
} else if(pd["step"] = 2) {
    print "autostage: check for empty stage".
    if(ship:maxthrust = 0) {
        if(stage:ready) {
            print "autostage: stage empty stage".
            stage. 
        } else {
            set pd["interval"] to 0.
        }
    } else {
        print "autostage: detected non-empty stage".
        set pd["interval"] to 0.
        set pd["step"] to 1.
        dtd["use"]().
    }
}