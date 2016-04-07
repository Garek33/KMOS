@LAZYGLOBAL OFF.

//!id=KMOS Bootloader
//!category=KMOS Runtime
//!dependencies=KMOS Core
//!files=kmos_boot

{
	print "KMOS startup...".
	local bootorder is list().
	local vol is list().
	list volumes in vol.
	
	print "scanning volumes".
	for v in vol {
		print "<" + v:name + ">".
		if v:exists("kmos_boot_stage2.ks") {
			switch to v.
			run kmos_boot_stage2.
		}
	}
	switch to 1.
	kmos_main().
	
	clearscreen.
	print "KMOS shut down".
}