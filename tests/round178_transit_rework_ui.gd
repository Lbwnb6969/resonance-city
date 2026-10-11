extends SceneTree
## Production station selection and same-line editing; Dummy device only.
const World = preload("res://scripts/world/continuous_world.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const CharterAnchor = preload("res://scripts/world/transit_charter_anchor.gd")
const OUTPUT := "res://验证记录/round178_作者线路改站/transit_rework_ui.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(demo: Control,code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _click_road(demo: Control,id: String,button := MOUSE_BUTTON_LEFT) -> void:
	var p: Array = demo.model.world.nodes[id]
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = demo.point(Vector2(float(p[0]),float(p[1])))
	demo._gui_input(event)

func _route(city: RefCounted,ids: Array) -> Dictionary:
	var positions: Array = []
	for id in ids: positions.append(city.nodes[id].duplicate())
	return {"kind":"transit_line","stop_positions":positions,"source_topology":city.network.topology}

func _button(demo: Control,line_id: String) -> Button:
	for child in demo.transit_edit_choices.get_children():
		if str(child.get_meta("line_id","")) == line_id: return child
	return null

func _current_line(city: RefCounted,id: String) -> Dictionary:
	for line in city.transit_lines:
		if str(line["id"]) == id: return line
	return {}

func _settle(demo: Control) -> Dictionary:
	var guide = demo.planning_guide
	var action: Dictionary = guide.next_action.duplicate(true)
	var previous = demo.model.freeze().world
	demo.model.world.settle(int(action["expected_boundary_frame"]))
	demo.shown_world = previous
	guide.sync()
	check(guide.next_action.get("state","") == "queued","model_ahead_keeps_edit_followup_waiting_for_real_boundary")
	var line_id := str(action["edit_id"])
	var old_source := Rework.candidate(previous,line_id)
	var old_last: Array = old_source["stop_positions"].back()
	var audible_station: Dictionary = demo._transit_station_at(Vector2(float(old_last[0]),float(old_last[1])))
	check(audible_station.get("line_ids",[]).has(line_id),"ahead_model_keeps_old_station_visible_line_membership")
	var audible_feedback: Dictionary = demo._transit_station_feedback(audible_station)
	check(float(audible_feedback["demand"]) == previous.transit_demand_score(str(audible_station["id"])) and audible_feedback.get("line_ids",[]).has(line_id),"ahead_model_station_feedback_reads_audible_demand_and_line")
	demo.context = {"kind":"transit_station","id":str(_current_line(previous,line_id)["stops"][0])}
	demo._refresh_transit_edit_choices()
	var button := _button(demo,line_id)
	check(button != null and button.disabled and button.text.ends_with("%d站" % old_source["stop_positions"].size()),"ahead_model_menu_retains_visible_station_count_and_waits_for_device")
	demo._begin_transit_edit(line_id)
	check(not demo.transit_route_mode and demo.transit_edit_context.is_empty() and guide.next_action.get("state","") == "queued","ahead_model_cannot_load_future_original_stations_into_editor")
	demo.shown_world = demo.model.world
	demo._refresh_transit_edit_choices()
	check(_button(demo,line_id) != null and not _button(demo,line_id).disabled,"audible_edit_boundary_reenables_same_line_editing")
	var found: Dictionary = {}
	for event in demo.shown_world.events:
		if str(event.get("kind","")) == "transit_line" and int(event.get("event_id",-1)) == int(action["event_id"]): found = event
	guide.sync()
	return found

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var frame := (city.phrase_index+1)*phrase
	var charter := city.request({"kind":"charter","plan_id":"corridor","community_ids":["west-1","east-1"],"card_refs":[]},frame)
	var charter_id := "charter-%05d" % int(charter["event_id"])
	var first := _route(city,["west-1","west-2","west-3"])
	first["charter_id"] = charter_id
	check(bool(city.request(first,frame).get("accepted",false)),"first_real_author_line_queues_under_charter")
	city.settle(frame)
	var line_id := str(city.authored_transit_lines[0]["id"])
	frame += phrase
	check(bool(city.request(_route(city,["west-1","west-4"]),frame).get("accepted",false)),"second_real_author_line_shares_station")
	check(bool(city.request({"kind":"charter","plan_id":"compact","community_ids":["west-1","east-1"],"card_refs":[]},frame).get("accepted",false)),"new_real_charter_replaces_original_scope")
	city.settle(frame)
	var second_id := str(city.authored_transit_lines[1]["id"])
	check(not bool(CharterAnchor.source(city,charter_id).get("accepted",false)) and bool(Rework.candidate(city,line_id).get("accepted",false)),"historical_line_edit_remains_valid_after_new_charter")
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	await process_frame
	var guide = demo.planning_guide
	_click_road(demo,"west-1")
	check(demo.context.get("kind","") == "transit_station" and demo.menu.visible,"production_mouse_click_opens_real_station_menu")
	check(_button(demo,line_id) != null and _button(demo,second_id) != null and demo.transit_edit_choices.get_child_count() == 2,"shared_station_lists_both_real_editable_author_lines")
	check(_button(demo,line_id).text != _button(demo,second_id).text,"shared_station_requires_a_distinguishable_line_choice")
	var auto_count := 0
	for line in city.transit_lines:
		if not bool(line.get("authored",false)):
			auto_count += 1
			check(_button(demo,str(line["id"])) == null,"automatic_line_is_not_editable_"+str(line["id"]))
	check(auto_count > 0,"fixture_includes_real_automatic_services")
	var before: Dictionary = demo.model.capture_state()
	_button(demo,line_id).emit_signal("pressed")
	var source := Rework.candidate(demo.model.world,line_id)
	var operation: Dictionary = demo._transit_route_operation({})
	check(guide.opened and guide.stage == "transit_edit" and demo.transit_edit_context.get("id","") == line_id,"line_choice_opens_same_line_editor")
	check(operation["stop_positions"] == source["stop_positions"] and demo.model.capture_state() == before,"original_real_stop_order_prefills_without_world_mutation")
	check(operation.get("edit_id","") == line_id and operation.get("source_revision","") == source["source_revision"] and not operation.has("charter_id"),"unified_edit_operation_keeps_identity_without_fresh_charter")
	check(guide.actions.get_child_count() == 4 and guide.actions.get_child(1).get_meta("anchor_kind") == "none" and not guide.transit_anchor_button.visible,"edit_stage_preserves_three_public_button_indices")
	_key(demo,KEY_BACKSPACE)
	_click_road(demo,"west-4")
	var preview: Dictionary = demo._transit_route_preview()
	guide.sync()
	check(demo.transit_route_stops.size() == 3 and bool(preview.get("accepted",false)) and preview.get("edit_id","") == line_id,"backspace_and_real_road_click_rework_original_station_order")
	check(preview.has("old_coverage") and preview.has("new_coverage") and guide.detail.text.contains("新接入") and guide.detail.text.contains("实际客流"),"editor_explains_actual_coverage_delta_and_conditional_sound")
	check(demo._transit_transfer_stop_ids(preview,preview["coverage"]) == preview["coverage"]["transfer_stop_ids"],"edit_map_transfer_markers_do_not_treat_same_line_as_second_service")
	before = demo.model.capture_state()
	_key(demo,KEY_SPACE)
	check(demo.preview_requested and demo.preview_thread != null and demo.preview_context_key.has(demo.transit_edit_context),"space_worker_identity_includes_same_line_source_context")
	var started := Time.get_ticks_msec()
	while demo.preview_thread != null and Time.get_ticks_msec()-started < 60000:
		await create_timer(0.02).timeout
		demo._process(0.0)
	check(demo.preview_started and guide.opened and guide.stage == "transit_edit","actual_edit_pcm_plays_while_editor_stays_open")
	check(demo.preview_player.stream != null and demo.preview_player.stream.data.size() == int(city.cfg["timing"]["sample_rate"])*3*4,"same_line_edit_preview_has_real_three_second_pcm")
	_key(demo,KEY_SPACE,false)
	check(not demo.preview_requested and not demo.preview_started and demo.model.capture_state() == before,"release_restores_live_and_keeps_world_unchanged")
	guide.transit_redraw_button.emit_signal("pressed")
	check(demo.transit_route_stops.is_empty() and demo.transit_edit_context.get("id","") == line_id and guide.confirm.disabled,"redraw_clears_only_stop_draft_and_keeps_same_line_identity")
	for id: String in ["west-1","west-2","west-4"]: _click_road(demo,id)
	for window_size: Vector2 in [Vector2(1440,900),Vector2(800,600)]:
		root.size = Vector2i(window_size)
		demo.size = window_size
		guide.refresh()
		await process_frame
		await process_frame
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.get_global_rect()),"edit_panel_fits_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.confirm.get_global_rect()) and Rect2(Vector2.ZERO,window_size).encloses(guide.transit_edit_cancel_button.get_global_rect()),"edit_controls_fit_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
	operation = demo._transit_route_operation(demo._transit_route_preview())
	var authors := city.authored_transit_lines.size()
	_key(demo,KEY_ENTER)
	var action: Dictionary = guide.next_action.duplicate(true)
	var pending: Dictionary = {}
	for intent in demo.model.world.pending_actions:
		if str(intent.get("kind","")) == "transit_line": pending = intent
	check(pending.get("edit_id","") == line_id and pending.get("stop_positions",[]) == operation["stop_positions"],"enter_submits_same_edit_identity_and_preview_station_order")
	check(bool(action.get("transit_edit",false)) and action.get("event_id",-1) == pending.get("event_id",-2) and action.get("edit_id","") == line_id,"edit_followup_binds_current_transaction_and_existing_line")
	check(not demo.transit_route_mode and demo.transit_edit_context.is_empty() and not guide.opened and city.authored_transit_lines.size() == authors,"submit_clears_draft_without_creating_second_line")
	var wrong := {"kind":"transit_line","edit":true,"id":second_id,"event_id":action["event_id"],"frame":action["expected_boundary_frame"]}
	check(not guide._next_action_event_matches(wrong),"other_line_cannot_complete_edit_followup")
	wrong["id"] = line_id
	wrong["edit"] = false
	check(not guide._next_action_event_matches(wrong),"fresh_line_event_cannot_complete_same_line_edit")
	demo.model.submit({"kind":"retune","id":str(city.buildings[0]["district_id"]),"midi":52,"expression":"bright"})
	guide.sync()
	check(guide.next_action.get("state","") == "queued","independent_house_retune_retains_edit_followup")
	var landed := _settle(demo)
	check(bool(landed.get("edit",false)) and landed.get("id","") == line_id and city.authored_transit_lines.size() == authors,"real_boundary_updates_existing_line_in_place")
	check(guide.next_action.get("state","") == "ready" and guide.next_action.get("line_id","") == line_id and guide.detail.text.contains("已更新原线路"),"actual_same_line_event_reveals_edit_feedback")
	check(guide.next_action.get("charter_id","") == charter_id and guide._combo_community_ids() == ["east-1","west-1"],"feedback_keeps_original_charter_scope_after_replacement")
	var ready: Dictionary = guide.next_action.duplicate(true)
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and _current_line(city,line_id)["stops"].has(demo.context.get("id","")),"feedback_locates_actual_station_of_updated_line")
	guide.next_action = ready.duplicate(true)
	guide.stage = "feedback"
	guide.opened = true
	guide.refresh()
	before = demo.model.capture_state()
	guide.next_combo_button.emit_signal("pressed")
	check(guide.stage == "charter" and guide.scope_seed == ["east-1","west-1"] and demo.model.capture_state() == before,"original_scope_continues_into_editable_P_without_replaying_old_charter")
	guide.hide_tool()
	demo.shown_world = city
	_click_road(demo,"west-1")
	await process_frame
	await process_frame
	check(Rect2(Vector2.ZERO,demo.size).encloses(demo.menu.get_global_rect()),"station_menu_fits_800x600")
	check(Rect2(Vector2.ZERO,demo.size).encloses(_button(demo,line_id).get_global_rect()) and Rect2(Vector2.ZERO,demo.size).encloses(_button(demo,second_id).get_global_rect()),"shared_station_edit_choices_visible_on_first_screen_800x600")
	_button(demo,second_id).emit_signal("pressed")
	check(demo.transit_edit_context.get("id","") == second_id,"reopening_shared_station_selects_other_author_line")
	before = demo.model.capture_state()
	_key(demo,KEY_ESCAPE)
	check(not guide.opened and demo.transit_edit_context.is_empty() and not demo.transit_route_mode and demo.model.capture_state() == before,"escape_discards_edit_draft_without_world_mutation")
	demo._begin_transit_edit(second_id)
	guide.transit_edit_cancel_button.emit_signal("pressed")
	check(demo.transit_edit_context.is_empty() and not demo.transit_route_mode,"explicit_cancel_clears_same_line_context")
	demo._begin_transit_edit(second_id)
	demo.model.submit({"kind":"retune","id":str(city.buildings[0]["district_id"]),"midi":55,"expression":"bright"})
	before = demo.model.capture_state()
	_click_road(demo,"west-1",MOUSE_BUTTON_RIGHT)
	check(demo.transit_edit_context.is_empty() and not guide.opened and demo.model.capture_state() == before,"right_click_cancels_only_edit_draft_and_retains_independent_intents")
	demo._begin_transit_edit(second_id)
	demo._verb("plan_transit")
	check(demo.transit_edit_context.is_empty() and demo.transit_route_mode and demo.transit_charter_context.is_empty(),"fresh_bus_entry_cannot_reuse_stale_edit_identity")
	demo._clear_transit_route()
	demo._begin_transit_edit(second_id)
	var updated: Dictionary = demo._transit_route_operation(demo._transit_route_preview())
	updated["stop_positions"] = [city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate()]
	var accepted: Dictionary = demo.model.submit(updated)
	city.settle(int(accepted["frame"]))
	demo.shown_world = city
	guide.sync()
	check(not guide.opened and demo.transit_edit_context.is_empty() and not demo.transit_route_mode,"real_same_line_revision_change_closes_stale_editor")
	await _finish(demo)

func _finish(demo: Control) -> void:
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Production station mouse input, explicit shared-line buttons, editing controls and real three-second PCM worker. Direct World settlement proves exact same-line reveal and historical-scope UI; Dummy, no physical-device or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(evidence,"  ")+"\n")
	print("ROUND178_TRANSIT_REWORK_UI "+JSON.stringify(evidence))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
