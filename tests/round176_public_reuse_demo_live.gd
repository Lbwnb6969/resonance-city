extends SceneTree
## Production mouse/menu/preview/confirm callbacks and two physical boundaries.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT := "res://验证记录/round176_公共空间原位改用窗口"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var observations: Dictionary = {}
var screenshots: Dictionary = {}
var original: Dictionary = {}
var start_frame := 0.0
var start_skips := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _site() -> Dictionary:
	for site in demo.shown_world.public_sites:
		if str(site.get("id","")) == "west-civic": return site
	return {}

func _key(code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _open_reuse() -> bool:
	if demo.planning_guide.opened: demo.planning_guide.hide_tool()
	var at: Array = _site()["position"]
	var screen := demo.point(Vector2(float(at[0]),float(at[1])))
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	demo._gui_input(motion)
	var click := InputEventMouseButton.new()
	click.position = screen
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	demo._gui_input(click)
	var button: Button = demo.planning_buttons["reuse_public"]
	check(str(demo.context.get("id","")) == "west-civic" and button.is_visible_in_tree() and not button.disabled,"production_public_click_exposes_reuse_on_first_menu_screen")
	if str(demo.context.get("id","")) != "west-civic" or button.disabled: return false
	button.emit_signal("pressed")
	var guide = demo.planning_guide
	check(guide.opened and guide.stage == "reuse_anchor" and guide.anchor_kind == "none" and str(guide.candidate.get("public_id","")) == "west-civic","production_menu_opens_fixed_reuse_target_and_default_retention")
	return guide.opened and guide.stage == "reuse_anchor"

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	screenshots[name] = demo.get_viewport().get_texture().get_image()

func _queue(kind: String) -> int:
	if not _open_reuse(): return -1
	var guide = demo.planning_guide
	for button in guide.actions.get_children():
		if button is Button and str(button.get_meta("anchor_kind","")) == kind:
			button.emit_signal("pressed")
	var before := demo.model.decisions.size()
	guide.confirm.emit_signal("pressed")
	var action: Dictionary = demo.model.decisions.back() if demo.model.decisions.size() > before else {}
	check(action.get("operation",{}).get("reuse",false) and str(action.get("operation",{}).get("kind","")) == kind and not guide.opened,kind+"_real_confirmation_queues_reuse_without_relocating")
	return int(action.get("structure_frame",-1))

func _wait_boundary(kind: String,boundary: int) -> void:
	var rate: int = demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,float(boundary-demo.clock.renderer.transport.audible_frame)/rate)*1000.0)+6500
	var future_clean := true
	var heard := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var af := float(demo.clock.renderer.transport.audible_frame)
		var site := _site()
		if af < boundary:
			future_clean = future_clean and str(site.get("kind","")) != kind
			continue
		if str(site.get("kind","")) != kind or int(site.get("frame",-1)) != boundary: continue
		if demo.planning_guide.opened and demo.planning_guide.stage == "feedback": _key(KEY_P)
		var rows := demo.model.audible_music_activity(af)
		var source_row: Dictionary = {}
		for row in rows:
			if str(row.get("cid","")) == "west-1" and int(row.get("onset",0)) >= boundary:
				source_row = row
				break
		if source_row.is_empty(): continue
		var tags: Array = source_row.get("public_site_ids",[])
		var marked := false
		for mark in demo.public_space_activity_layer.marks:
			if str(mark.get("site_id","")) == "west-civic" and str(mark.get("site_kind","")) == kind and float(mark.get("alpha",0.0)) >= 0.1: marked = true
		if kind == "civic" and not marked: continue
		check(tags.has("west-civic") == (kind == "civic"),kind+"_actual_theme_metadata_tracks_current_cultural_service")
		check(kind != "park" or not marked,"park_conversion_does_not_invent_a_foreign_community_theme_mark")
		check(site["position"] == original["position"] and site["polygon"] == original["polygon"] and site.get("service_level",1) == original.get("service_level",1),kind+"_physical_boundary_preserves_identity_land_and_investment")
		observations[kind] = {"audible_frame":af,"boundary":boundary,"site_kind":site["kind"],"site_id":site["id"],"served":site.get("served",[]).size(),"theme_event":source_row["event_id"],"public_ids":tags.duplicate(),"marked":marked}
		await _capture("reuse_"+kind+"_live")
		heard = true
		break
	check(future_clean,kind+"_visible_use_waits_for_real_device_boundary")
	check(heard,kind+"_real_device_reaches_reused_site_and_actual_theme")

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = demo.clock.renderer.transport.audible_frame
	start_skips = demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","real_window_uses_physical_wasapi")
	_key(KEY_P)
	demo.planning_guide.theme_rework_button.emit_signal("pressed")
	check(not demo.selected_id.is_empty() and str(demo.shown_world.by_id.get(demo.selected_id,{}).get("community_id","")) == "west-1","production_rework_selects_real_mature_theme_source")
	_key(KEY_F)
	_key(KEY_H)
	original = _site().duplicate(true)
	check(not original.is_empty() and str(original["kind"]) == "civic","default_city_has_real_existing_culture_site")
	if not _open_reuse():
		await _finish()
		return
	await _capture("reuse_choices_live")
	_key(KEY_SPACE)
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started and demo.preview_public and not demo.planning_guide.comparison.is_empty(),"production_space_starts_fixed_reuse_three_branch_preview")
	_key(KEY_SPACE,false)
	await process_frame
	check(not demo.preview_started and _site() == original,"releasing_space_restores_live_audio_and_retains_real_site")
	demo.planning_guide.confirm.emit_signal("pressed")
	check(_site() == original and not demo.planning_guide.opened,"retention_confirmation_changes_no_public_site")
	var park_boundary := _queue("park")
	if park_boundary >= 0: await _wait_boundary("park",park_boundary)
	var civic_boundary := _queue("civic")
	check(civic_boundary == park_boundary+demo.model.phrase_frames,"second_reuse_continues_in_same_city_next_phrase")
	if civic_boundary >= 0: await _wait_boundary("civic",civic_boundary)
	check(demo.clock.underruns == start_skips,"reuse_preview_and_two_real_settlements_add_no_underrun")
	check(demo.model.synth.last_voice_count <= 70,"reuse_keeps_existing_render_voice_budget")
	await _finish()

func _finish() -> void:
	var end_frame := float(demo.clock.renderer.transport.audible_frame)
	var output := {"before":start_frame,"after":end_frame,"advanced_frames":end_frame-start_frame,"underruns_before":start_skips,"underruns_after":demo.clock.underruns}
	demo.clock.stop_output()
	demo.light_player.stop()
	demo.preview_player.stop()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for name in screenshots: check(screenshots[name].save_png(OUTPUT+"/"+name+".png") == OK,name+"_screenshot_saved")
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"output":output,
		"display_backend":DisplayServer.get_name(),"audio_driver":AudioServer.get_driver_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"scope":"Production default city mouse/menu/Space/choice/confirmation callbacks and physical culture→park→culture boundaries; no manual model render, settlement, saved user work or human listening claim"}
	var file := FileAccess.open(OUTPUT+"/public_reuse_demo_live.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(evidence,"  ")+"\n")
	print("ROUND176_PUBLIC_REUSE_DEMO_LIVE "+JSON.stringify(evidence))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
