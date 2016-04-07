@LAZYGLOBAL OFF.

//!id=KMOS Updater
//!category=KMOS Runtime
//!dependencies=KMOS Core

{
	local available_pkg is lexicon().
	local installed_pkg is lexicon().
	local categories is list().
	local bootorder is list().
	local listfields is list("files","dependencies").
	
	//returns a list(base filename, extension)
	function split_filename {
		parameter filename.
		local pos is filename:findlast(".").
		if(pos > 0) {
			return list(filename:substring(0,pos), filename:substring(pos +1,filename:length - pos -1)).
		} else {
			return list(filename, "").
		}
	}
	
	function parse_value {
		parameter line.
		local kv is line:split("=").
		if(kv:length <> 2) {
			kmos_add_error("could not parse line: " + line).
			return list().
		}
		local key is kv[0].
		local val is kv[1].
		if(listfields:contains(key)) {
			set val to kv[1]:split(",").
		}
		return list(key,val).
	}
	
	function add_pkg {
		parameter pkg, filename.
		//mandatory fields
		local basename is split_filename(filename)[0].
		if(not pkg:haskey("id")) {
			pkg:add("id",basename).
		}
		if(not pkg:haskey("files")) {
			pkg:add("files",list(basename)).
		}
		if(not pkg:haskey("category")) {
			pkg:add("category","Uncategorized").
		}
		if(not pkg:haskey("dependencies")) {
			pkg:add("dependencies",list()).
		}
		if(not pkg:haskey("source")) {
			pkg:add("source",archive).
		}
		available_pkg:add(pkg["id"],pkg).
		if(not categories:contains(pkg["category"])) {
			categories:add(pkg["category"]).
		}
	}
	
	function scan_kpm {
		parameter filename.
		local pkg is lexicon().
		local lines is open(filename):readall:string:split(char(10)).
		for line in lines {
			local kv is parse_value(line).
			if(kv:length = 2) {
				pkg:add(kv[0],kv[1]).
			}
		}
		add_pkg(pkg, filename).
	}
	
	function scan_ks {
		parameter filename.
		local pkg is lexicon().
		local iter is open(filename):readall:iterator.
		local ispkg is false.
		until not iter:next {
			local line is iter:value.
			local pos is line:find("//!").
			if(pos >= 0) {
				local code is line:substring(pos +3, line:length - pos -3).
				if(code:contains("=")) { //check it isn't non-value to force entry with default metadata
					local kv is parse_value(code).
					if(kv:length = 2) {
						pkg:add(kv[0],kv[1]).
					}
				}
				set ispkg to true.
			}
		}
		if(ispkg) add_pkg(pkg, filename).
	}
	
	function scan_file {
		parameter filename, source is archive.
		switch to source.
		local prts is split_filename(filename).
		if(prts[1] = "ks") {
			scan_ks(filename).
		} else if(prts[1] = "kpm") {
			scan_kpm(filename).
		}
		switch to 1.
	}
	
	function check_dep_consistency {
		local has_error is false.
		for pkg in available_pkg:values {
			for depname in pkg["dependencies"] {
				if(not available_pkg:haskey(depname)) {
					kmos_add_error("package consistency check failed: dependency <" + depname + "> of <" + pkg["id"] + "> not available").
					set has_error to true.
				}
			}
		}
		return not has_error.
	}
	
	function add_bootorder {
		parameter pkg.
		local todo is false.
		for fname in pkg["files"] {
			if(not bootorder:contains(fname)) {
				set todo to true.
				break.
			}
		}
		if(not todo) return.
		
		for dep in pkg["dependencies"] {
			add_bootorder(available_pkg[dep]).
		}
		for fname in pkg["files"] {
			if(not bootorder:contains(fname)) bootorder:add(fname).
		}
	}
	
	function uninstall {
		parameter pkg.
		for fname in pkg["files"] {
			if(core:volume:exists(fname + ".ks")) {
				core:volume:delete(fname + ".ks").
			}
			if(core:volume:exists(fname + ".ksm")) {
				core:volume:delete(fname + ".ksm").
			}
		}
		if(installed_pkg:haskey(pkg["id"])) {
			installed_pkg:remove(pkg["id"]).
		}
		return true.
	}
	
	function install {
		parameter pkg, compile, inst_deps, cls is true.
		if(cls) clearscreen.
		print "installing " + pkg["id"].
		if(installed_pkg:haskey(pkg["id"])) {
			uninstall(pkg).
		}
		if(inst_deps) {
			print "checking dependencies".
			for dep in pkg["dependencies"] {
				print "<" + dep + ">".
				local required is false.
				for fname in available_pkg[dep]["files"] {
					if(not core:volume:exists(fname)) {
						set required to true.
						break.
					}
				}
				if(required) install(available_pkg[dep],compile,true,false).
			}
			print "dependencies done, back at " + pkg["id"].
		}
		for fname in pkg["files"] {
			print "<" + fname + ">".
			if(compile) {
				switch to pkg["source"].
				compile fname + ".ks" to fname + ".ksm".
				switch to 1.
				copy fname + ".ksm" from pkg["source"].
			} else {
				copy fname + ".ks" from pkg["source"].
			}
		}
		if(not installed_pkg:haskey(pkg["id"])) {
			installed_pkg:add(pkg["id"],pkg).
		}
		set installed_pkg[pkg["id"]]["compiled"] to compile.
		return true.
	}
	
	local main_labels is list().
	local main_actions is list().
	local current_cat is "".

	function choose_cat {
		parameter cat.
		set current_cat to cat.
		kmos_enter_mode("kmos_updater_category").
		return true.
	}
	
	function finalize {
		bootorder:clear().
		for pkg in installed_pkg:values {
			add_bootorder(pkg).
		}
		log "" to kmos_boot_stage2.ks.
		delete kmos_boot_stage2.ks.
		log "{" +
			"local vol is list(). " +
			"list volumes in vol. " to kmos_boot_stage2.ks.
		for fname in bootorder {
			log "for v in vol {" +
				"if(v:exists(" + char(34) + fname + char(34) + ")){" +
				"print " + char(34) + "<" + fname + ">" + char(34) + ". " +
				"run once " + fname + ". " +
				"break.}}" to kmos_boot_stage2.ks.
		}
		log "}" to kmos_boot_stage2.ks.
		writejson(installed_pkg,"kmos_pkg.json").
		if(kmos_require_state("kmos_mainmode", "kmos_main") = "kmos_updater_main") {
			kmos_store_state("kmos_mainmode", "kmos_main").
		}
		reboot.
	}
	
	function main_begin {
		//clearscreen.
		print "loading package management".
		if(exists("kmos_pkg.json")) {
			set installed_pkg to readjson("kmos_pkg.json").
		}
		if(kmos_has_archive) {
			print "scanning files".
			for fname in archive:files:keys {
				print "<" + fname + ">".
				scan_file(fname).
			}
		} else {
			print "archive unreacheable, scanning local volumes".
			for v in volumes {
				switch to v.
				if(v:exists("kmos_pkg.json")) {
					local other_pkgs is readjson("kmos_pkg.json").
					for id in other_pkgs:keys {
						if(not available_pkg:haskey(id)) {
							available_pkg:add(id,other_pkgs[id]).
							available_pkg[id]:add("source",v).
						}
					}
				}
			}
			switch to 1.
		}
		if(not _kmos_errors:empty or not check_dep_consistency) {
			return false.
		}
		for cat in categories {
			main_labels:add(cat).
			main_actions:add(choose_cat@:bind(cat)).
		}
		main_labels:add(kmos_toggle_desc@:bind(kmos_has_boot@, "Unset Boot", "Set Boot")).
		main_actions:add(kmos_delegate_nvl@:bind(kmos_toggle_boot@)).
		main_labels:add("finalize and reboot").
		main_actions:add(finalize@).
		return kmos_menu_begin.
	}
	
	function main_step {
		return kmos_menu_step("KMOS Updater",main_labels, main_actions).
	}
	
	function main_end {
		main_labels:clear.
		main_actions:clear.
		return kmos_menu_end.
	}
	
	kmos_add_mode_withitem("kmos_updater_main", "KMOS Updater", main_begin@, main_step@, main_end@).
	
	local category_labels is list().
	local category_actions is list().
	local current_pkg is lexicon().
	
	function edit_pkg {
		parameter pkg.
		set current_pkg to pkg.
		kmos_enter_mode("kmos_updater_pkg").
		return true.
	}
	
	function category_begin {
		for pkg in available_pkg:values {
			if(pkg["category"] = current_cat) {
				category_labels:add(pkg["id"]).
				category_actions:add(edit_pkg@:bind(pkg)).
			}
		}
		return kmos_menu_begin.
	}
	
	function category_step {
		return kmos_menu_step(current_cat,category_labels,category_actions).
	}
	
	function category_end {
		category_labels:clear.
		category_actions:clear.
		return kmos_menu_end.
	}
	
	kmos_add_mode("kmos_updater_category", category_begin@, category_step@, category_end@).
	
	function pkg_begin {
		return kmos_menu_begin.
	}
	
	function pkg_step {
		if(not available_pkg:haskey(current_pkg["id"]) and not installed_pkg:haskey(current_pkg["id"])) {
			kmos_exit_mode.
			return true.
		}
		local status is "uninst".
		if(installed_pkg:haskey(current_pkg["id"])) {
			if(installed_pkg[current_pkg["id"]]["compiled"]) {
				set status to "compiled".
			} else {
				set status to "installed".
			}
		}
		local labels is list().
		local actions is list().
		if(status <> "uninst") {
			labels:add("remove").
			actions:add(uninstall@:bind(current_pkg)).
		}
		if(status <> "installed") {
			labels:add("install (source, with dependencies)").
			actions:add(install@:bind(current_pkg,false,true)).
			labels:add("install (source, w/o dependencies)").
			actions:add(install@:bind(current_pkg,false,false)).
		}
		if(status <> "compiled") {
			labels:add("install (compiled, with dependencies)").
			actions:add(install@:bind(current_pkg,true,true)).
			labels:add("install (compiled, w/o dependencies)").
			actions:add(install@:bind(current_pkg,true,false)).
		}
		local title_ext is lexicon("uninst", " - not installed", "installed", " - installed (source)", "compiled", " - installed (compiled)").
		return kmos_menu_step(current_pkg["id"] + title_ext[status], labels, actions).
	}
	
	function pkg_end {
		return kmos_menu_end.
	}
	
	kmos_add_mode("kmos_updater_pkg", pkg_begin@, pkg_step@, pkg_end@).
}