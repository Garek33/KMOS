@lazyglobal off.

local srcroot is scriptpath():parent.
if(exists("0:/boot/kmos")) {
    deletepath("0:/boot/kmos").
}
log "runpath(" + char(34) + srcroot + "/base/setup" + char(34) + "," + char(34) + srcroot + char(34) + ")." to "0:/boot/kmos.ks".