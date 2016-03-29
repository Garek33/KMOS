@lazyglobals off

parameter compile_level is 1, //0 = none, 1 = main runtime, 2 = main runtime and script files, 3 = everything
		have_runtime is true, //install runtime?
		have_boot is true.	  //set bootfile
		keep_setup is true.   //keep setup or delete?
		
local scripts is list().
local runtime is list("kmosrt", "kmos_ui", "spec_char", "lib_exec").

function add_script {
	parameter name.
	
	if(compile_level > 1) {
		switch to archive.
		compile name.
		switch to 1.
	}
	copy name from archive.
	
	if(not scripts:contains(name)) {
		scripts:add(name).
	}
}

function finalize {
	if(compile_level > 2) {
		switch to archive.
		compile kmos_boot.
		switch to 1.
	}
	copy kmos_boot from archive.
	if(have_boot) {
		set core:bootfilename to kmos_boot.
	}

	if(have_runtime) {
		for file in runtime {
			if(compile_level > 0) {
				switch to archive.
				compile file.
				switch to 1.
			}
			copy file from archive.
		}
	}
	
	if(volume 1:exists("kmos_load.ks") {
		delete "kmos_load.ks".
	}
	
	for script in scripts {
		log "run once " + script + "." + to "kmos_load.ks".
	}
	
	if(compile_level > 2) {
		compile "kmos_load".
		delete "kmos_load.ks".
	}
	
	if(not keep_setup) {
		delete "kmos_setup.ks".
	}
	
	restart.
}