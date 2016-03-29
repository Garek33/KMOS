@lazyglobals off

{
	local core_runtime is list("kmosrt", "lib_exec").
	local runtime_features is lexicon("Control UI", "kmos_ui", "Updater", "kmos_update").
	local script_texts is list().
	local script_actions is list().
	local feature_texts is list().
	local feature_actions is list().
	local main_texts is list().
	local main_actions is list().
	
	function have_any_core {
		for local vol in volumes {
			for local file in core_runtime {
				if(not vol:exists(file)) {
					return false.
				}
			}
		}
		return true.
	}
	
	function setup_desc {
		parameter base, file.
		if(volume 1:exists(file + ".ks")) {
			return base + " - installed [ks]".
		} else if(volume 1:exists(file + ".ksm")) {
			return base + " - installed [ksm]".
		} else {
			return base + " - not installed".
		}
	}
	
	function setup_action {
		parameter file.
		if(volume 1:exists(file + ".ks")) {
			compile file.
			delete file + ".ks".
		} else if(volume 1:exists(file + ".ksm")) {
			delete file + ".ksm".
		} else {
			if(not archive:exists(file)) {
				kmos_add_error("Script " + file + " missing from archive").
				return false.
			}
			copy file + ".ks" from archive.
		}
		return true.
	}
	
	function core_desc {
		local ext is " - installed [ksm]".
		for local fname in core_runtime {
			if(not volume 1:exists(fname)) {
				set ext to " - not installed".
			} else if(not volume 1:exists(fname + ".ksm")) {
				set ext to " - installed [ks]".
			}
		}
		return "Core Runtime" + ext.
	}
	
	function core_action {
		local act is 2. //0 - copy, 1 - compile, 2 - remove
		for local fname in core_runtime {
			if(not volume 1:exists(fname)) {
				set act to 0.
			} else if(not volume 1:exists(fname + ".ksm")) {
				set ext to 1.
			}
		}
		for local fname in core_runtime {
			if(act = 0) {
				copy fname + ".ks" from archive.
			} else if(act = 1) {
				compile fname.
				delete fname + ".ks".
			} else {
				delete fname + ".ksm".
			}
		}
		return true.
	}
	
	function main_begin {
		main_texts:add("Select runtime features").
		main_actions:add(kmos_delegate_nvl@:bind(kmos_enter_mode@:bind("kmos_update_runtime"))).
		main_texts:add("Select additional scripts").
		main_actions:add(kmos_delegate_nvl@:bind(kmos_enter_mode@:bind("kmos_update_scripts"))).
		main_texts:add("Finalize and reboot").
		main_actions:add(kmos_delegate_nvl@:bind(kmos_enter_mode@:bind("kmos_update_finalize"))).
		
		return kmos_menu_begin().
	}
	
	function main_step {
		return kmos_menu_step("KMOS Updater",main_texts,main_actions).
	}
	
	kmos_add_mode_withitem("kmos_update_main", "Update", main_begin@, main_step@, kmos_menu_end@).
	
	function runtime_begin {
		feature_texts:add(core_desc@).
		feature_actions:add(core_action@).
		for desc in runtime_features:keys {
			feature_texts:add(setup_desc@:bind(desc, runtime_features[desc])).
			feature_actions:add(setup_action@:bind(runtime_features[desc])).
		}
		return kmos_menu_begin().
	}
	
	function runtime_step {
		return kmos_menu_step("KMOS Updater",feature_texts,feature_actions).
	}
	
	kmos_add_mode("kmos_update_runtime", runtime_begin@, runtime_step@, kmos_menu_end@).
	
	function scripts_begin {
		for fname in archive:files:keys {
			if(not core_runtime:contains(fname) and not fname:contains("kmos_")) {
				script_texts:add(setup_desc@:bind(fname,fname)).
				script_actions:add(setup_action@:bind(fname)).
			}
		}
		return kmos_menu_begin.
	}
	
	function scripts_step {
		return kmos_menu_step("KMOS_Updater",script_texts,script_actions).
	}
	
	kmos_add_mode("kmos_update_scripts", scripts_begin@, scripts_step@, kmos_menu_end@).
	
	function finalize {
		copy kmos_boot from archive.
		set core:bootfilename to kmos_require_state("kmos_bootfile", "kmos_boot").
		if(volume 1:exists("kmos_load.ks")) {
			delete kmos_load.ks.
		}
		for local fname in volume 1:files:keys {
			if(not core_runtime:contains(fname)) {
				log "run once " + fname + "." to "kmos_load.ks".
			}
		}
		if(kmos_require_state("kmos_mainmode", "kmos_main") = "kmos_update_main") {
			kmos_store_state("kmos_mainmode", "kmos_main").
		}
		reboot.
	}
	
	function finalize_step {
		if(have_any_core) {
			finalize().
			return true.
		} else {
			local texts is list("Ignore and Continue", "Install and Continue", "Back").
			local actions is list(kmos_delegate_nvl@:bind(finalize@),kmos_delegate_nvl@:bind(finalize@:bind(true)),kmos_delegate_nvl@:bind(kmos_exit_mode@)).
			return kmos_menu_step("NO CORE RUNTIME FOUND!", texts, actions).
		}
	}
	
	kmos_add_mode("kmos_update_finalize", kmos_menu_begin@, finalize_step@, kmos_menu_end@).
}