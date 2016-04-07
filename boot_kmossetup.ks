@LAZYGLOBAL OFF.

print "starting KMOS setup".

switch to archive.
run once kmosrt.
run once kmos_update.
switch to 1.
kmos_store_state("kmos_mainmode", "kmos_updater_main").
kmos_main().

print "KMOS setup cancelled".