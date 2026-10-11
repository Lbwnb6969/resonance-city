extends SceneTree
## Production planning callbacks and device-time route settlement/continuation.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT := "res://验证记录/round177_公交章程窗口"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var screenshots: Dictionary = {}
var start_frame := 0.0
var start_skips := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(code: Key, pressed := true) -> void:
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

func _scope_point(cid: String) -> Vector2:
	for house in demo.shown_world.buildings:
		if str(house["community_id"]) != cid: continue
		var p := Vector2(float(house["position"][0]),float(house["position"][1]))
		if demo._transit_station_at(p).is_empty(): return p
	return Vector2.INF

func _shift(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SHIFT
	event.physical_keycode = KEY_SHIFT
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func _line(id: String) -> Dictionary:
	for line in demo.shown_world.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	screenshots[name] = demo.get_viewport().get_texture().get_image()

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = demo.clock.renderer.transport.audible_frame
	start_skips = demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","physical_window_and_wasapi_are_active")
	_key(KEY_H)
	_key(KEY_P)
	var guide = demo.planning_guide
	guide.cards.get_child(1).emit_signal("pressed")
	check(guide.stage == "card" and guide.plan_id == "corridor","production_plan_button_selects_corridor")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var west_one := _scope_point("west-1")
	var west_two := _scope_point("west-2")
	check(west_one != Vector2.INF and west_two != Vector2.INF,"real_houses_supply_two_selectable_community_positions")
	if west_one == Vector2.INF or west_two == Vector2.INF:
		await _finish()
		return
	_click_world(west_one)
	await _shift(true)
	_click_world(west_two)
	await _shift(false)
	check(guide.stage == "scope" and guide.scope.has("west-1") and guide.scope.has("west-2") and guide.scope.size() == 2,"production_click_and_shift_click_select_the_two_real_communities")
	guide.confirm.emit_signal("pressed")
	var charter_id := str(guide.committed_charter_id)
	check(guide.stage == "anchor" and guide.transit_anchor_button.is_visible_in_tree() and not charter_id.is_empty(),"confirmed_scope_exposes_bus_as_a_planning_anchor")
	await _capture("transit_anchor_choices")
	guide.transit_anchor_button.emit_signal("pressed")
	check(demo.transit_route_mode and guide.stage == "transit_anchor" and str(demo.transit_charter_context.get("charter_id","")) == charter_id,"bus_button_enters_the_real_road_tool_with_same_charter")
	var positions: Array[Vector2] = []
	for road_id in ["west-road-1","west-road-2","west-road-3"]:
		for road in demo.shown_world.roads:
			if str(road.get("id","")) == road_id:
				var path: PackedVector2Array = road["path"]
				positions.append(path[path.size()/2])
	for position in positions: _click_world(position)
	var preview := demo._transit_route_preview()
	var association: Dictionary = preview.get("charter_anchor",{})
	check(demo.transit_route_stops.size() == 3 and bool(preview.get("accepted",false)) and bool(association.get("accepted",false)),"three_mouse_placed_road_stops_cover_the_real_charter_scope")
	evidence["preview"] = association.duplicate(true)
	await _capture("transit_charter_route_preview")
	_key(KEY_SPACE)
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started and guide.opened and guide.stage == "transit_anchor","space_plays_route_forecast_with_planning_guide_open")
	_key(KEY_SPACE,false)
	await process_frame
	check(not demo.preview_started and not demo.transit_charter_context.is_empty(),"release_restores_live_playback_and_retains_route_context")
	_key(KEY_ENTER)
	var queued: Dictionary = guide.next_action.duplicate(true)
	var boundary := int(queued.get("expected_boundary_frame",-1))
	var event_id := int(queued.get("event_id",-1))
	var line_id := "player-line-%d" % event_id
	check(bool(queued.get("transit_anchor",false)) and str(queued.get("state","")) == "queued" and str(queued.get("charter_id","")) == charter_id and not demo.transit_route_mode,"enter_queues_one_route_anchor_and_clears_drawing")
	if boundary < 0:
		await _finish()
		return
	_click_world(west_one)
	_key(KEY_3)
	check(str(demo.context.get("kind","")) == "retune" and str(demo.model.decisions.back().get("operation",{}).get("kind","")) == "retune","player_can_retune_a_real_house_while_the_bus_anchor_waits")
	await process_frame
	check(str(guide.next_action.get("state","")) == "queued" and demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line" and int(op.get("event_id",-1)) == event_id),"independent_real_retune_keeps_the_same_bus_followup_queued")
	var rate: int = demo.clock.renderer.transport.sample_rate
	deadline = Time.get_ticks_msec()+roundi(maxf(0.0,float(boundary-demo.clock.renderer.transport.audible_frame)/rate)*1000.0)+6000
	var future_clean := true
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var af := float(demo.clock.renderer.transport.audible_frame)
		if af < boundary:
			future_clean = future_clean and _line(line_id).is_empty()
			continue
		if not _line(line_id).is_empty() and str(guide.next_action.get("state","")) == "ready": break
	var line := _line(line_id)
	check(future_clean,"visible_route_waits_for_the_real_device_phrase_boundary")
	check(not line.is_empty() and int(line.get("frame",-1)) == boundary and str(line.get("charter_id","")) == charter_id,"physical_boundary_reveals_the_same_authored_route_and_charter")
	check(guide.opened and guide.stage == "feedback" and str(guide.next_action.get("line_id","")) == line_id and guide.next_combo_button.is_visible_in_tree(),"actual_route_event_opens_actionable_station_and_scope_feedback")
	evidence["settled"] = {"boundary":boundary,"audible_frame":demo.clock.renderer.transport.audible_frame,"line_id":line_id,"charter_id":line.get("charter_id",""),"stop_ids":line.get("stops",[]).duplicate(),"covered_buildings":line.get("covered_building_ids",[]).size(),"next_action":guide.next_action.duplicate(true)}
	await _capture("transit_charter_settled_feedback")
	guide.next_combo_button.emit_signal("pressed")
	check(guide.opened and guide.stage == "charter" and guide.scope_seed.has("west-1") and guide.scope_seed.has("west-2"),"continue_button_reopens_normal_planning_for_the_same_real_scope")
	guide.cards.get_child(1).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	check(guide.stage == "scope" and guide.scope.has("west-1") and guide.scope.has("west-2"),"continued_plan_and_card_keep_editable_community_scope")
	await _capture("transit_charter_continue_scope")
	_key(KEY_P)
	if not line.is_empty():
		_click_world(demo.shown_world.transit_stop_position(str(line["stops"][0])))
		check(str(demo.context.get("kind","")) == "transit_station" and demo.menu.visible,"landed_anchor_station_remains_clickable_for_line_composition")
	check(demo.clock.underruns == start_skips,"planning_preview_boundary_and_continuation_add_no_underrun")
	check(demo.model.synth.last_voice_count <= 70,"physical_anchor_playback_keeps_existing_voice_budget")
	await _finish()

func _finish() -> void:
	var after := float(demo.clock.renderer.transport.audible_frame)
	var output := {"before":start_frame,"after":after,"advanced_frames":after-start_frame,"underruns_before":start_skips,"underruns_after":demo.clock.underruns}
	demo.clock.stop_output()
	demo.light_player.stop()
	demo.preview_player.stop()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for name in screenshots: check(screenshots[name].save_png(OUTPUT+"/"+name+".png") == OK,name+"_screenshot_saved")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"output":output,"audio_driver":AudioServer.get_driver_name(),"display_backend":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),"scope":"Production P/plan/card/mouse+Shift scope/bus anchor/station/Space/Enter callbacks, actual device phrase and scope continuation; no manual model render/settlement or saved user work; no human-listening claim."}
	FileAccess.open(OUTPUT+"/transit_charter_demo_live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND177_TRANSIT_CHARTER_DEMO_LIVE "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
