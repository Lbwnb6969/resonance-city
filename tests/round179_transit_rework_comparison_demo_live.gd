extends SceneTree
## Production UI A/B, cancel an actual queued edit, then land the chosen edit.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT := "res://验证记录/round179_改站同源窗口"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var screenshots: Dictionary = {}
var start_frame := 0.0
var start_skips := 0

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _click_world(at: Vector2) -> void:
	var screen := demo.point(at)
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	demo._gui_input(motion)
	var event := InputEventMouseButton.new()
	event.position = screen
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _line(id: String) -> Dictionary:
	for line in demo.shown_world.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	screenshots[name] = demo.get_viewport().get_texture().get_image()

func _wait_boundary(boundary: int) -> bool:
	var rate: int = demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,float(boundary-demo.clock.renderer.transport.audible_frame)/rate)*1000.0)+6000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if float(demo.clock.renderer.transport.audible_frame) >= boundary: return true
	return false

func _wait_preview() -> bool:
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.preview_started and demo.planning_guide.transit_comparison_is_current(): return true
	return false

func _open_edit(id: String) -> bool:
	demo.planning_guide.hide_tool()
	var line := _line(id)
	if line.is_empty(): return false
	_click_world(demo.shown_world.transit_stop_position(str(line["stops"][0])))
	for button in demo.transit_edit_choices.get_children():
		if str(button.get_meta("line_id","")) == id:
			if button.disabled: return false
			button.emit_signal("pressed")
			return demo.planning_guide.stage == "transit_edit"
	return false

func _redraw(positions: Array[Vector2]) -> void:
	demo.planning_guide.transit_redraw_button.emit_signal("pressed")
	for p in positions: _click_world(p)

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = demo.clock.renderer.transport.audible_frame
	start_skips = demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","real_window_and_wasapi_are_active")
	_key(KEY_H)
	_key(KEY_P)
	var guide = demo.planning_guide
	guide.cards.get_child(1).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var house_point := Vector2.INF
	for house in demo.shown_world.buildings:
		if str(house["community_id"]) != "west-1": continue
		var p := Vector2(float(house["position"][0]),float(house["position"][1]))
		if demo._transit_station_at(p).is_empty():
			house_point = p
			break
	if house_point == Vector2.INF:
		check(false,"real_scope_house_exists")
		await _finish()
		return
	_click_world(house_point)
	guide.confirm.emit_signal("pressed")
	guide.transit_anchor_button.emit_signal("pressed")
	var positions: Array[Vector2] = []
	for road_id in ["west-road-1","west-road-2","west-road-3"]:
		for road in demo.shown_world.roads:
			if str(road.get("id","")) == road_id:
				var path: PackedVector2Array = road["path"]
				positions.append(path[path.size()/2])
	for p in positions: _click_world(p)
	_key(KEY_ENTER)
	var created: Dictionary = guide.next_action.duplicate(true)
	var id := "player-line-%d" % int(created.get("event_id",-1))
	check(await _wait_boundary(int(created.get("expected_boundary_frame",-1))) and not _line(id).is_empty(),"production_charter_and_road_clicks_land_an_authored_line")
	var original := _line(id).duplicate(true)
	if original.is_empty():
		await _finish()
		return
	var prop = demo.scenery.props.get("vehicle-line-"+id)
	check(_open_edit(id),"real_station_button_enters_edit_comparison")
	if guide.stage != "transit_edit":
		await _finish()
		return
	_redraw([positions[1],positions[2]])
	_key(KEY_SPACE)
	check(await _wait_preview(),"space_builds_two_real_pcm_branches_with_guide_open")
	if guide.transit_comparison.is_empty():
		await _finish()
		return
	var packet: Dictionary = guide.transit_comparison.duplicate(true)
	var source_key: Array = guide.transit_comparison_key.duplicate(true)
	var source_at := int(packet["source_frame"])
	var source_boundary := int(packet["boundary_frame"])
	var rate := int(packet["sample_rate"])
	check(bool(packet["variants"]["keep"]["accepted"]) and bool(packet["variants"]["edit"]["accepted"]) and packet["variants"]["keep"]["pcm"].size() == rate*3*4 and packet["variants"]["edit"]["pcm"].size() == rate*3*4,"both_choices_have_same_rate_three_second_pcm")
	await _capture("transit_compare_edit")
	guide.transit_keep_button.emit_signal("pressed")
	await process_frame
	check(demo.preview_started and guide.transit_choice == "keep" and demo.preview_player.stream.data == packet["variants"]["keep"]["pcm"],"keep_button_plays_cached_original_route_pcm")
	check(demo.preview_thread == null and guide.transit_comparison_key == source_key and int(guide.transit_comparison["source_frame"]) == source_at and int(guide.transit_comparison["boundary_frame"]) == source_boundary,"switch_to_keep_retains_same_source_phase_time_and_boundary")
	await _capture("transit_compare_keep")
	root.size = Vector2i(800,600)
	await process_frame
	await process_frame
	await _capture("transit_compare_small")
	var window_rect := Rect2(Vector2.ZERO,Vector2(root.size))
	check(window_rect.encloses(guide.transit_keep_button.get_global_rect()) and window_rect.encloses(guide.transit_change_button.get_global_rect()) and window_rect.encloses(guide.confirm.get_global_rect()),"small_window_keeps_both_choices_and_confirmation_visible")
	root.size = Vector2i(1440,900)
	await process_frame
	await process_frame
	guide.transit_change_button.emit_signal("pressed")
	check(demo.preview_thread == null and guide.transit_comparison_key == source_key and demo.preview_player.stream.data == packet["variants"]["edit"]["pcm"],"edit_button_returns_to_same_source_edit_pcm_without_worker")
	_key(KEY_SPACE,false)
	check(not demo.preview_started and not demo.preview_duck_owned,"space_release_restores_live_city_and_owns_no_duck")
	_key(KEY_ENTER)
	var abandoned: Dictionary = guide.next_action.duplicate(true)
	var cancel_boundary := int(abandoned.get("expected_boundary_frame",-1))
	check(bool(abandoned.get("transit_edit",false)) and abandoned.get("state","") == "queued","enter_queues_selected_actual_edit")
	check(_open_edit(id),"pending_edit_can_be_reopened_before_rendered_boundary")
	if guide.stage != "transit_edit":
		await _finish()
		return
	guide.transit_keep_button.emit_signal("pressed")
	var serial_before := demo.model.world.action_serial
	_key(KEY_ENTER)
	check(not demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("edit_id","")) == id) and demo.model.world.action_serial == serial_before and not guide.opened,"enter_keep_cancels_only_the_queued_line_edit_without_new_operation")
	check(await _wait_boundary(cancel_boundary) and _line(id).get("stops",[]) == original["stops"] and int(_line(id).get("edit_revision",0)) == 0,"actual_next_phrase_preserves_original_stations_and_revision_after_keep")
	check(not demo.model.world.events.any(func(event: Dictionary) -> bool: return bool(event.get("edit",false)) and str(event.get("id","")) == id),"keep_produces_no_fake_edit_event_at_real_boundary")
	check(_open_edit(id),"preserved_original_station_still_offers_edit_entry")
	_redraw([positions[1],positions[2]])
	_key(KEY_SPACE)
	check(await _wait_preview(),"a_new_source_comparison_is_available_in_next_phrase")
	_key(KEY_SPACE,false)
	_key(KEY_ENTER)
	var queued: Dictionary = guide.next_action.duplicate(true)
	var boundary := int(queued.get("expected_boundary_frame",-1))
	check(await _wait_boundary(boundary) and int(_line(id).get("edit_revision",0)) == 1 and _line(id).get("stops",[]) != original["stops"],"chosen_edit_lands_on_actual_device_phrase_as_same_service")
	check(demo.scenery.props.get("vehicle-line-"+id) == prop and str(_line(id).get("charter_id","")) == str(original.get("charter_id","")),"final_edit_retains_actual_vehicle_and_historical_charter")
	check(guide.next_action.get("state","") == "ready","final_edit_feedback_matches_actual_device_boundary")
	await _capture("transit_compare_settled")
	check(demo.clock.underruns == start_skips,"whole_comparison_keep_and_edit_chain_adds_no_underrun")
	check(demo.model.synth.max_voice_count <= 70,"same_source_compare_retains_render_voice_budget")
	evidence = {"line_id":id,"source_frame":source_at,"comparison_boundary":source_boundary,"sample_rate":rate,
		"pcm_changed":packet["pcm_changed"],"max_pcm_abs_diff":packet["max_pcm_abs_diff"],"keep_coverage":packet["variants"]["keep"]["coverage"],"edit_coverage":packet["variants"]["edit"]["coverage"],
		"canceled_event_id":abandoned.get("event_id",-1),"canceled_boundary":cancel_boundary,"actual_edit_boundary":boundary,"original_stops":original["stops"],"final_line":_line(id),"max_voices":demo.model.synth.max_voice_count}
	await _finish()

func _finish() -> void:
	var after: float = demo.clock.renderer.transport.audible_frame
	var output := {"before":start_frame,"after":after,"advanced_frames":after-start_frame,"underruns_before":start_skips,"underruns_after":demo.clock.underruns}
	demo.clock.stop_output()
	demo.light_player.stop()
	demo.preview_player.stop()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for name in screenshots: check(screenshots[name].save_png(OUTPUT+"/"+name+".png") == OK,name+"_screenshot_saved")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"output":output,
		"audio_driver":AudioServer.get_driver_name(),"display_backend":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"scope":"Actual production P/charter/road clicks/station choice/Space/keep-edit buttons/Enter; actual device boundaries and canceled pending edit. No manual model render or settlement, no saved user work, no human listening claim."}
	FileAccess.open(OUTPUT+"/transit_rework_comparison_demo_live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND179_TRANSIT_REWORK_COMPARISON_DEMO_LIVE "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
