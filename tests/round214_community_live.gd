extends "res://tests/round211_sound_stage_live.gd"
## One focused native production check for the new community workbench.
var snapshots: Array[Dictionary] = []

func _run() -> void:
	output = "res://验证记录/round214_社区工作台/run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","actual_windows_opengl_wasapi")
	check(await until_frame(demo.clock.renderer.transport.sample_rate*5),"opening_reaches_device")
	var before := demo.model.world.snapshot()
	await tap(KEY_C)
	await create_timer(0.7).timeout
	var workbench = demo.community_workbench
	check(workbench.opened and not workbench.community_id.is_empty() and workbench.state["count"] > 0,"native_c_opens_an_actual_nonempty_community")
	check(demo.community_member_focus.visible and demo.community_member_focus.member_polygons.size() == workbench.state["count"],"workbench_draws_only_actual_heard_member_footprints")
	check(demo.model.world.snapshot() == before and demo.model.world.pending_actions.is_empty(),"opening_workbench_does_not_write_world")
	snapshots.append({"window":str(demo.size),"community":workbench.community_id,"name":workbench.state["name"],"count":workbench.state["count"],"panel":str(workbench.get_global_rect()),"focus_members":demo.community_member_focus.member_polygons.size()})
	await capture("00_800_实际街坊工作台")
	var cid: String = workbench.community_id
	await press_button(workbench.listen_button)
	await process_frame
	check(demo.model.sound_events.any(func(event: Dictionary) -> bool: return bool(event.get("workbench_listener",false)) and str(event.get("community", "")) == cid),"workbench_listen_requests_real_temporary_community_audio")
	await press_button(workbench.planning_button)
	await create_timer(0.3).timeout
	check(not workbench.opened and demo.planning_guide.opened and demo.planning_guide.stage == "charter","workbench_planning_returns_to_real_charter_flow")
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	check(demo.planning_guide.stage == "scope" and demo.planning_guide.scope == [cid],"planning_from_workbench_preserves_the_actual_community_scope")
	await capture("01_800_工作台回到真实社区规划")
	await tap(KEY_ESCAPE)
	check(not demo.planning_guide.opened and not demo.community_workbench.opened,"escape_closes_the_transient_workbench_and_planning_layers")
	check(demo.model.world.snapshot() == before,"workbench_and_planning_preview_do_not_write_world")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await create_timer(0.7).timeout
	await tap(KEY_C)
	await create_timer(0.5).timeout
	snapshots.append({"window":str(demo.size),"community":demo.community_workbench.community_id,"panel":str(demo.community_workbench.get_global_rect()),"focus_members":demo.community_member_focus.member_polygons.size()})
	check(demo.community_workbench.get_global_rect().position == Vector2(1072,76) and demo.community_workbench.size.y <= 800,"native_workbench_reflows_on_large_window")
	await capture("02_1440_实际街坊工作台")
	await tap(KEY_C)
	check(not demo.community_workbench.opened and not demo.community_member_focus.visible,"native_c_closes_and_clears_actual_member_focus")
	demo.clock.stop_output()
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"snapshots":snapshots,"scope":"Actual Windows/OpenGL/WASAPI community workbench only. It proves native C, temporary listen, planning scope handoff and 800/1440 layout. It does not prove bulk community retune, SP6 boundaries or human community fun."},"\t")+"\n")
	print("ROUND214_COMMUNITY_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
