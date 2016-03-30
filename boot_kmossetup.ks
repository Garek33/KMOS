@LAZYGLOBAL OFF.

print "starting KMOS setup".

switch to archive.
run once kmosrt.
run once kmos_update.
switch to 1.
kmos_store_state("kmos_mainmode", "kmos_update_main").
kmos_main().

clearscreen.
print "KMOS setup cancelled".