extends SceneTree
## Production create/select/redraw/audition/edit on device time, retaining vehicle.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT := "res://验证记录/round178_公交改站窗口"
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

func _wait_ready(boundary: int,id: String,revision: int) -> bool:
	var rate: int = demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,float(boundary-demo.clock.renderer.transport.audible_frame)/rate)*1000.0)+6000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if float(demo.clock.renderer.transport.audible_frame) >= boundary and not _line(id).is_empty() and int(_line(id).get("edit_revision",0)) == revision and demo.planning_guide.next_action.get("state","") == "ready": return true
	return false

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = demo.clock.renderer.transport.audible_frame
	start_skips = demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","actual_window_and_device_are_active")
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
	check(house_point != Vector2.INF,"real_house_supplies_charter_scope")
	if house_point == Vector2.INF:
		await _finish()
		return
	_click_world(house_point)
	guide.confirm.emit_signal("pressed")
	var charter_id := str(guide.committed_charter_id)
	guide.transit_anchor_button.emit_signal("pressed")
	var positions: Array[Vector2] = []
	for road_id in ["west-road-1","west-road-2","west-road-3"]:
		for road in demo.shown_world.roads:
			if str(road.get("id","")) == road_id:
				var path: PackedVector2Array = road["path"]
				positions.append(path[path.size()/2])
	for p in positions: _click_world(p)
	check(demo.transit_route_stops.size() == 3 and bool(demo._transit_route_preview().get("accepted",false)),"production_road_clicks_create_three_station_charter_line")
	_key(KEY_ENTER)
	var first: Dictionary = guide.next_action.duplicate(true)
	var id := "player-line-%d" % int(first.get("event_id",-1))
	check(await _wait_ready(int(first.get("expected_boundary_frame",-1)),id,0),"first_line_appears_at_actual_device_boundary")
	var original := _line(id).duplicate(true)
	if original.is_empty():
		await _finish()
		return
	var vehicle_key := "vehicle-line-"+id
	check(demo.scenery.props.has(vehicle_key),"real_authored_line_has_a_retained_vehicle_prop")
	var prop = demo.scenery.props.get(vehicle_key)
	var traveler = prop.get_meta("traveler")
	guide.hide_tool()
	_click_world(demo.shown_world.transit_stop_position(str(original["stops"][0])))
	var selected: Button
	for button in demo.transit_edit_choices.get_children():
		if str(button.get_meta("line_id","")) == id: selected = button
	check(demo.menu.visible and selected != null and selected.is_visible_in_tree(),"station_first_screen_exposes_the_actual_authored_line")
	await _capture("transit_edit_station_choice")
	if selected == null:
		await _finish()
		return
	selected.emit_signal("pressed")
	check(guide.stage == "transit_edit" and demo.transit_route_stops.size() == 3 and str(demo.transit_edit_context.get("id","")) == id,"line_button_loads_original_stations_for_same_service")
	guide.transit_redraw_button.emit_signal("pressed")
	_click_world(positions[1])
	_click_world(positions[2])
	var preview := demo._transit_route_preview().duplicate(true)
	check(bool(preview.get("accepted",false)) and bool(preview.get("edit",false)) and demo.transit_route_stops.size() == 2,"redraw_and_real_road_clicks_prepare_same_line_two_station_edit")
	evidence["preview"] = preview
	await _capture("transit_edit_preview")
	_key(KEY_SPACE)
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started and guide.opened and guide.stage == "transit_edit","space_auditions_edit_with_guide_open")
	_key(KEY_SPACE,false)
	await process_frame
	check(not demo.preview_started and str(demo.transit_edit_context.get("id","")) == id,"release_keeps_edit_draft_and_resumes_live_city")
	_key(KEY_ENTER)
	var queued: Dictionary = guide.next_action.duplicate(true)
	var boundary := int(queued.get("expected_boundary_frame",-1))
	check(bool(queued.get("transit_edit",false)) and str(queued.get("edit_id","")) == id and queued.get("state","") == "queued" and not demo.transit_route_mode,"enter_queues_same_line_edit_and_clears_draft")
	if boundary < 0:
		await _finish()
		return
	var rate: int = demo.clock.renderer.transport.sample_rate
	deadline = Time.get_ticks_msec()+roundi(maxf(0.0,float(boundary-demo.clock.renderer.transport.audible_frame)/rate)*1000.0)+6000
	var future_clean := true
	var same_vehicle := true
	var maximum_step := 0.0
	var previous: Vector2 = traveler.position
	var mid_leg_retained := true
	var boundary_checked_mid_leg := false
	var before_path: PackedVector2Array = traveler.path.duplicate()
	var before_destination: String = traveler.destination
	var before_remaining: float = traveler.total-traveler.distance
	var before_wait: float = traveler.wait
	var visible_edited := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		maximum_step = maxf(maximum_step,previous.distance_to(traveler.position))
		previous = traveler.position
		same_vehicle = same_vehicle and demo.scenery.props.get(vehicle_key) == prop and prop.get_meta("traveler") == traveler
		var af := float(demo.clock.renderer.transport.audible_frame)
		var line := _line(id)
		if af < boundary:
			future_clean = future_clean and int(line.get("edit_revision",0)) == 0 and line["stops"] == original["stops"]
			before_path = traveler.path.duplicate()
			before_destination = traveler.destination
			before_remaining = traveler.total-traveler.distance
			before_wait = traveler.wait
			continue
		if int(line.get("edit_revision",0)) == 1:
			if not visible_edited and before_wait <= 0.0 and before_remaining > 0.2:
				boundary_checked_mid_leg = true
				mid_leg_retained = traveler.path == before_path and traveler.destination == before_destination
			visible_edited = true
			if guide.next_action.get("state","") == "ready": break
	var edited := _line(id)
	check(future_clean,"visible_original_stations_remain_until_device_edit_boundary")
	check(visible_edited and int(edited.get("edited_frame",-1)) == boundary and str(edited.get("charter_id","")) == charter_id and int(edited.get("frame",-1)) == int(original["frame"]),"device_boundary_updates_same_line_and_preserves_creation_and_charter")
	check(same_vehicle and demo.shown_world.authored_transit_lines.size() == 1,"actual_boundary_retains_vehicle_object_traveler_and_one_authored_line")
	check(mid_leg_retained,"device_boundary_does_not_reset_an_existing_mid_leg_path")
	check(guide.stage == "feedback" and str(guide.next_action.get("line_id","")) == id and int(guide.next_action.get("event_id",-1)) == int(queued.get("event_id",-2)) and guide.next_combo_button.is_visible_in_tree(),"real_edit_event_opens_exact_line_and_historical_scope_feedback")
	await _capture("transit_edit_settled_feedback")
	evidence["vehicle_at_edit"] = {"position":traveler.position,"destination":traveler.destination,"remaining":traveler.total-traveler.distance,"wait":traveler.wait,"line_key":traveler.line_key,"kind":traveler.kind}
	deadline = Time.get_ticks_msec()+45000
	while Time.get_ticks_msec() < deadline and not str(traveler.line_key).contains(":edit-1:"):
		await process_frame
		maximum_step = maxf(maximum_step,previous.distance_to(traveler.position))
		previous = traveler.position
	check(str(traveler.line_key).contains(":edit-1:") and traveler.service_line_id == id and demo.scenery.props.get(vehicle_key) == prop,"retained_actual_vehicle_adopts_edited_route_at_completed_stop")
	check(maximum_step < 0.3,"actual_edit_travel_has_no_position_jump")
	evidence["vehicle_after_old_leg"] = {"position":traveler.position,"destination":traveler.destination,"remaining":traveler.total-traveler.distance,"wait":traveler.wait,"line_key":traveler.line_key,"kind":traveler.kind}
	guide.next_combo_button.emit_signal("pressed")
	check(guide.stage == "charter" and guide.scope_seed == ["west-1"],"edit_feedback_continues_original_charter_scope")
	await _capture("transit_edit_continue_scope")
	guide.hide_tool()
	_click_world(demo.shown_world.transit_stop_position(str(edited["stops"][0])))
	check(demo.context.get("kind","") == "transit_station" and edited["stops"].has(str(demo.context.get("id",""))),"updated_station_remains_clickable_for_next_same_line_edit")
	check(demo.clock.underruns == start_skips,"create_audition_edit_and_vehicle_continuation_add_no_underrun")
	check(demo.model.synth.last_voice_count <= 70,"actual_edit_keeps_voice_budget")
	evidence["settled"] = {"line_id":id,"charter_id":charter_id,"boundary":boundary,"original_stops":original["stops"],"edited_stops":edited["stops"],"revision":edited.get("edit_revision",0),"mid_leg_observed_at_boundary":boundary_checked_mid_leg,"max_position_step":maximum_step,"next_action":guide.next_action.duplicate(true)}
	await _finish()

func _finish() -> void:
	var after: float = demo.clock.renderer.transport.audible_frame
	var output := {"before":start_frame,"after":after,"advanced_frames":after-start_frame,"underruns_before":start_skips,"underruns_after":demo.clock.underruns}
	demo.clock.stop_output()
	demo.light_player.stop()
	demo.preview_player.stop()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for name in screenshots: check(screenshots[name].save_png(OUTPUT+"/"+name+".png") == OK,name+"_screenshot_saved")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"output":output,"audio_driver":AudioServer.get_driver_name(),"display_backend":DisplayServer.get_name(),"adapter":RenderingServer.get_video_adapter_name(),"scope":"Production P/charter/road mouse/Enter, station line button/redraw/Space/Enter, real device boundaries and retained vehicle; no manual model render or settlement, no saved user work, no human listening claim."}
	FileAccess.open(OUTPUT+"/transit_rework_demo_live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND178_TRANSIT_REWORK_DEMO_LIVE "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
