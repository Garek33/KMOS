@lazyglobals off.

for local v in volumes {
	if v:exists(kmosrt) {
		switch to v.
		run once kmosrt.
		break.
	}
}
switch to 1.

kmos_load_all().
kmos_main().

clearscreen.
print "KMOS shut down".