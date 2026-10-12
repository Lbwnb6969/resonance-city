extends "res://tests/round213_planning_live.gd"
## Focused supplement: the one failed public facade clearance and changing report.
var clearances: Array[Dictionary] = []

func _run() -> void:
	output = "res://验证记录/round213_公共规划净空/run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","actual_gpu_and_audio")
	check(await until_frame(demo.clock.renderer.transport.sample_rate*5),"actual_opening_reaches_device")
	await tap(KEY_P)
	await create_timer(0.5).timeout
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	await create_timer(0.2).timeout
	await tap(KEY_ENTER)
	var guide = demo.planning_guide
	var scope_at := Vector2.ZERO
	var count := 0
	for building: Dictionary in demo.shown_world.buildings:
		if str(building["community_id"]) != "west-2": continue
		scope_at += demo.Coupling.position_of(building)
		count += 1
	await click_map(demo.point(scope_at/count))
	await tap(KEY_ENTER)
	await create_timer(0.7).timeout
	check(guide.stage == "anchor" and guide.scope == ["west-2"],"actual_native_planning_reaches_selected_community")
	var candidate: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": candidate = possible; break
	check(not candidate.is_empty(),"same_actual_legal_public_candidate")
	if candidate.is_empty(): quit(1); return
	var at := Vector2(float(candidate["position"][0]),float(candidate["position"][1]))
	for window_size: Vector2i in [Vector2i(800,600),Vector2i(1440,900)]:
		DisplayServer.window_set_size(window_size)
		await create_timer(0.7).timeout
		for button: Button in guide.actions.get_children():
			if str(button.get_meta("anchor_kind","")) == "civic": await press_button(button); break
		await at_pointer(demo.point(at))
		await process_frame
		var label := str(window_size.x)
		var bounds := Rect2(demo.point(at)-Vector2(80,85),Vector2(160,145))
		check(Rect2(Vector2.ZERO,demo.size).encloses(bounds) and not guide.get_global_rect().intersects(bounds),label+"_whole_actual_public_facade_has_clearance")
		key_event(KEY_SPACE,true)
		check(await playing(),label+"_actual_native_public_preview_plays")
		check(guide.comparison.has("variants") and demo.preview_player.stream.data == guide.comparison["variants"]["civic"]["pcm"],label+"_real_civic_pcm_is_preserved")
		await create_timer(0.5).timeout
		var viewport: Rect2 = guide.content_scroll.get_global_rect()
		var visible_choices := 0
		for button: Button in guide.actions.get_children():
			if button.visible and viewport.encloses(button.get_global_rect()): visible_choices += 1
		check(visible_choices == 4,label+"_all_four_uses_visible_during_actual_comparison")
		check(guide.size.x == 356 and Rect2(Vector2.ZERO,demo.size).encloses(guide.get_global_rect()),label+"_changing_report_remains_inside_window")
		clearances.append({"window":str(window_size),"panel":str(guide.get_global_rect()),"facade":str(bounds),"actions":str(guide.actions.get_global_rect()),"visible_choices":visible_choices})
		await capture(label+"_公共用途与真实文化馆净空")
		key_event(KEY_SPACE,false)
		await process_frame
	check(demo.pending_composition_choice.is_empty() and not demo.model.world.public_sites.any(func(site: Dictionary) -> bool: return bool(site.get("active",false))),"layout_and_preview_do_not_commit_a_public_choice")
	await tap(KEY_P)
	check(not guide.opened and guide.unfinished_public_choice(),"close_keeps_the_actual_unfinished_public_draft")
	demo.clock.stop_output()
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"clearances":clearances,"scope":"Focused actual Windows/OpenGL/WASAPI supplement to preserved 38/39 complete native journey. It validates the failed facade clearance plus visible public tools during real PCM comparison; it does not repeat or relabel that full run. No human verdict."},"\t")+"\n")
	print("ROUND213_PUBLIC_CLEARANCE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
