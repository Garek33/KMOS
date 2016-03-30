@LAZYGLOBAL OFF.

{
	print "KMOS startup...".
	local vol is list().
	list volumes in vol.
	for v in vol {
		if v:exists("kmosrt") {
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
}