@lazyglobal off.

local vol is open("1:/").
for f in vol:list:values {
  deletepath("1:/"+f:name).
}

copypath("0:/kmos/base/kmos.ks", "1:/base/kmos.ks").
copypath("0:/kmos/bin/60s_test", "1:/bin/60s_test").

local proc is lexicon(
  "60s_test",
  lexicon(
    "args", 0,
    "interval", 5,
    "last", 0,
    "counter", 0
  )
).
writejson(proc, "1:/boot/proc").

reboot.