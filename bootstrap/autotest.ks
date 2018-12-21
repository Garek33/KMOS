@lazyglobal off.

local vol is open("1:/").
for f in vol:list:values {
  deletepath("1:/"+f:name).
}

copypath("0:/kmos/base/kmos.ks", "1:/base/kmos.ks").
copypath("0:/kmos/bin/timer", "1:/bin/timer").

log "timer 10 60" to "1:/base/autoexec".
log "timer 2 20" to "1:/base/autoexec".

reboot.