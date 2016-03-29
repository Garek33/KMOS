@lazyglobals off

{
	function kmos_restart {
		reboot.
	}

	function kmos_perf_task {
		if(_kmos_perf_lastclock = 0) {
			set _kmos_perf_lastclock to time:seconds.
		} else {
			if(time:seconds > _kmos_perf_lastclock) {
				local deltaT = time:seconds - _kmos_perf_lastclock.
				local sps = _kmos_perf_stepcount / deltaT.
				_kmos_perf_sps:push(sps).
				set _kmos_perf_stepcount to 0.
				set _kmos_perf_lastclock to time:seconds.
				until (_kmos_perf_sps:length < 61) {
					_kmos_perf_sps:pop().
				}
			} else {
				set _kmos_perf_stepcount to _kmos_perf_stepcount + 1.
			}
		}
		return true.
	}

	function kmos_status_step {
		clearscreen.
		print "Kerbal Modular Operating System - Status".
		print "Version: " + kmos_get_version.
		
		local sps_avg is 0.
		for local v in _kmos_perf_sps {
			set sps_avg to sps_avg + v.
		}
		set sps_avg to sps_avg / _kmos_perf_sps:length.
		
		print sps_avg + " steps per second".
		print _kmos_tasks:length + " active tasks".
		print _kmos_mode_stack:length + " modes stacked".
		print _kmos_mode_begin:keys:length + " modes available".
		print "1 - Back".
		if(kmos_checkAG(1)) {
			kmos_exit_mode.
		}
		return true.
	}

	function kmos_edit_task {
		parameter id.
		set _kmos_edit_task to id.
		kmos_enter_mode("kmos_edit_task").
		return true.
	}

	function kmos_taskmanager_step {
		local texts is list().
		local actions is list().
		local pers_tasks is kmos_require_state("kmos_persistent_tasks", lexicon()).
		from local i is 0 until i = _kmos_tasks:keys:length step {set i to i+1} do {
			if(pers_tasks:contains(_kmos_tasks:keys[i])) {
				texts:add(_kmos_tasks:keys + " [A/P]").
			} else {
				texts:add(_kmos_tasks:keys[i] + " [A]").
			}
			actions:add(kmos_edit_task@:bind(_kmos_tasks:keys[i])).
		}
		from local i is 0 until i = pers_tasks:keys:length step {set i to i+1} do {
			if(not kmos_has_task(pers_tasks:keys[i])) {
				texts:add(pers_tasks:keys[i] + " [P]").
				actions:add(kmos_edit_task@:bind(pers_tasks:keys[i])).
			}
		}
		return kmos_menu_step("Taskmanager", texts, actions).
	}

	function kmos_edit_task_step {
		local texts is list().
		local actions is list().
		if(kmos_has_task(_kmos_edit_task)) {
			texts:add("Kill").
			actions:add(kmos_delegate_nvl@:bind(kmos_kill_task@:bind(_kmos_edit_task))).
		}
		if(kmos_has_persistent_task(_kmos_edit_task)) {
			texts:add("Remove").
			actions:add(kmos_delegate_nvl@:bind(kmos_remove_persistent_task@:bind(_kmos_edit_task))).
			if(not kmos_has_task(_kmos_edit_task)) {
				texts:add("Restart").
				local pers_tasks is kmos_get_state("kmos_persistent_tasks").
				actions:add(kmos_delegate_nvl@:bind(kmos_start_task@:bind(_kmos_edit_task, evaluate(pers_tasks[_kmos_edit_task])))).
			}
		}
		if(texts:empty) {
			kmos_exit_mode.
		}
		local title is "Taskmanager - " + _kmos_edit_task.
		if(kmos_has_task(_kmos_edit_task) and kmos_has_persistent_task(_kmos_edit_task)) {
			set title to title + " [A/P]".
		} else if(kmos_has_task(_kmos_edit_task)) {
			set title to title + " [A]".
		} else {
			set title to title + " [P]".
		}
		return kmos_menu_step(title, texts, actions).
	}
	
	kmos_add_mode_withitem("kmos_status", "Show Status", kmos_mode_noop@, kmos_status_step@, kmos_noop@).
	kmos_add_mode_withitem("kmos_taskmanager", "Taskmanager", kmos_menu_begin@, kmos_taskmanager_step@, kmos_menu_end@).
	kmos_add_item(kmos_toggle_desc@:bind(kmos_has_boot@, "Unset Boot", "Set Boot"), kmos_delegate_nvl@:bind(kmos_toggle_boot@)).
	kmos_add_item("Restart", kmos_delegate_nvl@:bind(kmos_restart@)).
	kmos_add_mode("kmos_edit_task", kmos_menu_begin@, kmos_edit_task_step@, kmos_menu_step@).
	kmos_start_task("kmos_perf", kmos_perf_task@).
}