@lazyglobal off.

parameter srcroot.

deletepath("0:/boot/kmos_byptag.ks").
log "runpath(" + char(34) + srcroot + "/base/setup" + char(34) + ", core:tag, " + char(34) + srcroot + char(34) + ")." to "0:/boot/kmos_byptag.ks".

deletepath("0:/boot/kmos_byvname.ks").
log "runpath(" + char(34) + srcroot + "/base/setup" + char(34) + ", ship:name, " + char(34) + srcroot + char(34) + ")." to "0:/boot/kmos_byvname.ks".