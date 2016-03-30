@LAZYGLOBAL OFF.

run once lib_exec.

global _kmos_item_desc is list().
global _kmos_item_action is list().
global _kmos_mode_begin is lexicon().
global _kmos_mode_step is lexicon().
global _kmos_mode_end is lexicon().
global _kmos_mode_stack is stack().
global _kmos_tasks is lexicon().
global _kmos_errors is list().
global _kmos_showerrors_pos is 0.
global _kmos_perf_lastclock is 0.
global _kmos_perf_stepcount is 0.
global _kmos_perf_sps is queue().
global _kmos_menu_page is stack().
global _kmos_last_ag_state is list().
global _kmos_stored_state is lexicon().
global _kmos_edit_task is "".

function kmos_add_error {
	parameter error.
	local message is time:clock + ": " + error.
	log message to "errors.log".
	_kmos_errors:add(message).
}

function kmos_delgate_nvl {
	parameter action, nvl is true.
	action:call().
	return nvl.
}

function kmos_ag_init {
	from {local i is 0.} until i = 10 step {set i to i+1.} do {
		_kmos_last_ag_state:add(false).
	}
}

function kmos_ag_byindex {
	parameter n.
	if(n = 0) return AG0.
	if(n = 1) return AG1.
	if(n = 2) return AG2.
	if(n = 3) return AG3.
	if(n = 4) return AG4.
	if(n = 5) return AG5.
	if(n = 6) return AG6.
	if(n = 7) return AG7.
	if(n = 8) return AG8.
	if(n = 9) return AG9.
}

function kmos_ag_task {
	from {local i is 0.} until i = 10 step {set i to i+1.} do {
		set _kmos_last_ag_state[i] to kmos_ag_byindex(i).
	}
	return true.
}

function kmos_checkAG {
	parameter n.
	return kmos_ag_byindex(n) <> _kmos_last_ag_state(n).
}
	
function kmos_get_version {
	return "0.1".
}

function kmos_add_item {
	parameter desc, action.
	_kmos_item_desc:add(desc).
	_kmos_item_action:add(action).
}

function kmos_enter_mode {
	parameter id.
	if(_kmos_mode_begin[id]:call()) {
		_kmos_mode_stack:push(id).
	} else if(not _kmos_errors:empty()) {
		kmos_enter_mode("kmos_showerrors").
	}
}

function kmos_exit_mode {
	local id is _kmos_mode_stack:pop().
	if(not _kmos_mode_end[id]:call() and not _kmos_errors:empty()) {
		kmos_enter_mode("kmos_showerrors").
	}
}

function kmos_add_mode {
	parameter id, begin, step, end.
	_kmos_mode_begin:add(id, begin).
	_kmos_mode_step:add(id, step).
	_kmos_mode_end:add(id, end).
}

function kmos_add_mode_withitem {
	parameter id, desc, begin, step, end.
	kmos_add_mode(id, begin, step, end).
	local action is kmos_delegate_nvl@:bind(kmos_enter_mode@:bind(id)).
	kmos_add_item(desc, action).
}

function kmos_start_task {
	parameter id, step.
	_kmos_tasks:add(id, step).
}

function kmos_kill_task {
	parameter id.
	_kmos_tasks:remove(id).
}

function kmos_has_task {
	parameter id.
	return _kmos_tasks:contains(id).
}

function kmos_toggle_task {
	parameter id, step.
	if(_kmos_tasks:contains(id)) {
		kmos_kill_task(id).
	} else {
		kmos_start_task(id, step).
	}
}

function kmos_taskitem_desc {
	parameter id.
	if(_kmos_tasks:contains(id)) {
		return "Kill " + id.
	} else {
		return "Start " + id.
	}
}

function kmos_add_taskitem {
	parameter id, step.
	local desc is kmos_taskitem_desc@:bind(id).
	local action is kmos_delegate_nvl@:bind(kmos_toggle_task@:bind(id, step)).
	kmos_add_item(desc, action).
}

function kmos_mode_noop {
	return true.
}

function kmos_store_state {
	parameter key, value.
	if(not value:isserializable) {
		kmos_add_error("state <" + key + "> = <" + value + "> is not serializable").
	} else {
		set _kmos_stored_state[key] to value.
		writejson(_kmos_stored_state, "kmos_state.js").
	}
}

function kmos_remove_state {
	parameter key.
	_kmos_stored_state:remove(key).
	writejson(_kmos_stored_state, "kmos_state.js").
}

function kmos_get_state {
	parameter key.
	if(_kmos_stored_state:contains(key)) {
		return _kmos_stored_state[key].
	} else {
		kmos_add_error("key " + key " not found in stored state").
		return false.
	}
}

function kmos_has_state {
	parameter key.
	return _kmos_stored_state:contains(key).
}

function kmos_require_state {
	parameter key, default.
	if(kmos_has_state(key)) {
		return kmos_get_state(key).
	} else {
		kmos_store_state(key, default).
		return default.
	}
}

function kmos_load_state {
	if(volume 1:exists("kmos_state.json")) {
		set _kmos_stored_state to readjson("kmos_state.json").
	}
}

function kmos_add_persistent_task {
	parameter id, action_as_string.
	local pers_tasks is kmos_require_state("kmos_persistent_tasks", lexicon()).
	set pers_tasks[id] to action_as_string.
	kmos_store_state("kmos_persistent_tasks", pers_tasks).
}

function kmos_start_persistent_task {
	parameter id, action_as_string.
	kmos_add_persistent_task(id, action_as_string).
	kmos_start_task(id, evaluate(action_as_string)).
}

function kmos_remove_persistent_task {
	parameter id.
	kmos_kill_task(id).
	if(not kmos_has_state("kmos_persistent_tasks")) {
		return.
	}
	local pers_tasks is kmos_get_state("kmos_persistent_tasks").
	pers_tasks:remove(id).
	kmos_store_state("kmos_persistent_tasks", pers_tasks).
}

function kmos_has_persistent_task {
	parameter id.
	if(not kmos_has_state("kmos_persistent_tasks")) {
		return false.
	}
	local pers_tasks is kmos_get_state("kmos_persistent_tasks").
	return pers_tasks:contains(id).
}

function kmos_run_once_task {
	parameter id, action.
	kmos_kill_task(id).
	return action().
}

function kmos_run_once {
	parameter id, action.
	kmos_start_task(id, kmos_run_once_task@:bind(id, action)).
}

function kmos_toggle_desc {
	parameter testfunc, ontrue, onfalse.
	if(testfunc()) return ontrue.
	return onfalse.
}

function kmos_check_equal {
	parameter getfunc, value.
	return (getfunc() = value).
}

function kmos_has_terminal {
	return core:allevents:contains("Close Terminal").
}

function kmos_has_boot {
	return (core:bootfilename = "kmos_boot").
}

function kmos_toggle_boot {
	if(kmos_has_boot) {
		set core:bootfilename to "".
	} else {
		set core:bootfilename to "kmos_boot".
	}
}

function kmos_menu_singlepage {
	parameter title, texts, actions.
	local pagesize is min(terminal:height-1, 10).
	if(texts:length > pagesize) {
		kmos_add_error("too many items for single page").
		return false.
	}
	if(texts:length <> actions:length) {
		kmos_add_error("mismatched number of texts and actions").
		return false.
	}
	
	clearscreen.
	print title.
	from {local i is 0.} until i = texts:length step {set i to i+1.} do {
		local ag is i+1.
		if(ag = 10) set ag to 0.
		print "" + ag + " - " + texts[i].
		if(kmos_checkAG(ag)) {
			if(not actions[i]:call()) {
				return false.
			}
		}
	}
	
	return true.
}

function kmos_menu_nextpage {
	parameter max.
	if(_kmos_menu_page:peek() < max) {
		_kmos_menu_page:push(_kmos_menu_page:pop() +1).
	}
	return true.
}

function kmos_menu_prevpage {
	if(_kmos_menu_page > 0) {
		_kmos_menu_page:push(_kmos_menu_page:pop(_kmos_menu_page - 1).
	}
	return true.
}

function kmos_menu_begin {
	_kmos_menu_page:push(0).
	return true.
}

function kmos_menu_end {
	if(_kmos_menu_page:length = 0) {
		kmos_add_error("mismatched kmos_menu_end").
		return false.
	}
	_kmos_menu_page:pop().
	return true.
}

function kmos_menu_step {
	parameter title, descs, actions.
	if(not kmos_has_terminal()) {
		return true. //only operate menu on active terminal
	}
	local act_texts is list().
	local act_actions is list().
	from { local i is 0.} until i = descs:length step {set i to i+1.} {
		if(descs[i]:typename() = "KOSDelegate") {
			act_texts:add(descs[i]:call()).
		} else {
			act_texts:add(descs[i]).
		}
		if(i < actions:length) {
			kmos_add_error("missing action for menu item " + act_texts[i]).
			return false.
		} else {
			act_actions:add(actions[i]).
		}
	}
	act_texts:add("exit").
	act_actions:add(kmos_exit_mode@).
	
	local pagesize is min(terminal:height-1, 10).
	local page is _kmos_menu_page:peek().
	if(act_texts:length <= pagesize) {
		if(not kmos_menu_singlepage(title, act_texts, act_actions)) {
			return false.
		}
	} else {
		local itemspp is terminal:height - 3.
		local ptexts is list().
		local pactions is list().
		from {local i is page * itemspp.} until i = (page+1) * itemspp step {set i to i+1.} do {
			ptexts:add(act_texts[i]).
			pactions:add(act_actions[i]).
		}
		ptexts:add("next page", kmos_menu_nextpage@:bind(ceiling(act_texts:length/itemspp))).
		ptexts:add("previous page", kmos_menu_prevpage@).
		if(not kmos_menu_singlepage(title, ptexts, pactions)) {
			return false.
		}
	}
	
	return true.
}

function kmos_showerrors_begin {
	clearscreen.
	if(_kmos_errors:length + 2 <= terminal:height) {
		if(_kmos_errors:length > 1) {
			print "The following errors occured:".
			for local e in _kmos_errors {
				print e.
			}
			print "1 - Back".
		} else if(_kmos_errors:length = 1) {
			print "Error: ".
			print _kmos_errors[0].
			print "1 - Back".
		} else {
			print "No new errors since the last display.".
			print "There may be old errors, see error.log.".
			print "1 - Back".
		}
	}
	return true.
}

function kmos_showerrors_step {
	if(kmos_checkAG(1)) {
		kmos_exit_mode().
		_kmos_errors:clear().
	} else if(_kmos_errors:length + 2 > terminal:height) {
		clearscreen.
		local pos is 0.
		if(_kmos_showerrors_pos = 0) {
			print "The following errors occured:".
		}
		from {local i is _kmos_showerrors_pos.} until pos = terminal:height - 3 or i = _kmos_errors:length
		step {set i to i + 1. set pos to pos + 1.} do {
			print e[i].
		}
		print "1 - Back".
		print "2 - Up".
		print "3 - Down".
		if(kmos_checkAG(2) and _kmos_showerrors_pos > 0) {
			set _kmos_showerrors_pos to _kmos_showerrors_pos -1.
		}
		if(kmos_checkAG(3) and _kmos_showerrors_pos < _kmos_errors:length - 2) {
			set _kmos_showerrors_pos to _kmos_showerrors_pos +1.
		}
	}
	return true.
}

function kmos_main_menu {
	return kmos_menu_step("Kerbal Modular Operating System", _kmos_item_desc, _kmos_item_action).
}

function kmos_load_all {
	kmos_load_state().
	for local v in volumes {
		if(not v = archive) {
			switch to v.
			if(v:exists("kmos_load")) {
				run kmos_load.
			}
			for local f in list("kmos_ui", "kmos_update") {
				if(v:exists(f)) {
					execute("run once " + f).
				}
			}
		}
	}
	switch to 1.
}

function kmos_main {
	kmos_add_mode_withitem("kmos_showerrors", "Check Errors", kmos_mode_showerrors_begin@, kmos_showerrors_step@, kmos_noop@).
	kmos_add_mode("kmos_main", kmos_menu_begin@, kmos_main_menu@, kmos_menu_end@).
	kmos_ag_init().
	kmos_enter_mode(kmos_require_state("kmos_mainmode", "kmos_main")).
	kmos_start_task("kmos_ag", kmos_ag_task@).
	local pers_tasks is kmos_require_state("kmos_persistent_tasks", lexicon()).
	for local t in pers_tasks:keys {
		kmos_start_task(t, pers_tasks[t]).
	}
	until _kmos_mode_stack:empty() {
		if(not _kmos_mode_step[_kmos_mode_stack:peek()]:call() and not _kmos_errors:empty()) {
			kmos_enter_mode("kmos_showerrors").
		}
		for local t in _kmos_tasks:values {
			if(not t() and not _kmos_errors:empty()) {
				kmos_enter_mode("kmos_showerrors").
				break.
			}
		}
		wait until true.
	}
}