extends SceneTree
## P12 authoring stays in the Guide through real road input and actual reveal.
const CharterAnchor = preload("res://scripts/world/transit_charter_anchor.gd")
const OUTPUT := "res://验证记录/round177_公交章程锚点/transit_charter_ui.json"
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

func _click_road(demo: Control,node_id: String) -> void:
	var raw: Array = demo.model.world.nodes[node_id]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = demo.point(Vector2(float(raw[0]),float(raw[1])))
	demo._gui_input(event)

func _choose_scope(demo: Control,ids: Array) -> String:
	var guide = demo.planning_guide
	guide.open_tool()
	guide.cards.get_child(1).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	for index in ids.size():
		var raw: Array = demo.model.world.nodes[str(ids[index])]
		guide.map_click(Vector2(float(raw[0]),float(raw[1])),index > 0)
	guide.confirm.emit_signal("pressed")
	return guide.committed_charter_id

func _settle(demo: Control,check_ahead := false) -> Dictionary:
	var guide = demo.planning_guide
	var frame := int(guide.next_action["expected_boundary_frame"])
	var event_id := int(guide.next_action["event_id"])
	var previous = demo.model.freeze().world if check_ahead else null
	demo.model.world.settle(frame)
	if check_ahead:
		demo.shown_world = previous
		guide.sync()
		check(guide.next_action.get("state","") == "queued","model_settlement_before_audible_boundary_keeps_exact_line_followup_queued")
	demo.shown_world = demo.model.world
	var landed: Dictionary = {}
	for event in demo.shown_world.events:
		if str(event.get("kind","")) == "transit_line" and int(event.get("event_id",-1)) == event_id: landed = event
	guide.sync()
	return landed

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var guide = demo.planning_guide
	var charter_id := _choose_scope(demo,["west-1","east-1"])
	check(guide.stage == "anchor" and guide.scope.size() == 2 and guide.scope.has("east-1") and guide.scope.has("west-1"),"production_charter_card_and_scope_reach_anchor_stage")
	check(not charter_id.is_empty() and bool(CharterAnchor.source(demo.model.world,charter_id).get("accepted",false)),"scope_commit_exposes_real_pending_charter_identity")
	check(guide.actions.get_child_count() == 4 and guide.actions.get_child(1).get_meta("anchor_kind") == "none" and guide.actions.get_child(2).get_meta("anchor_kind") == "park" and guide.actions.get_child(3).get_meta("anchor_kind") == "civic","transit_entry_preserves_existing_three_public_button_indices")
	check(guide.transit_anchor_button.visible and not guide.transit_anchor_button.disabled,"anchor_stage_offers_direct_bus_connection_choice")
	var before: Dictionary = demo.model.capture_state()
	guide.transit_anchor_button.emit_signal("pressed")
	check(guide.opened and guide.stage == "transit_anchor" and demo.transit_route_mode and not demo.menu.visible,"bus_choice_keeps_guide_and_enters_existing_route_input")
	check(demo.transit_charter_context.get("charter_id","") == charter_id and demo.model.capture_state() == before,"bus_draft_binds_selected_charter_without_new_world_operation")
	check(guide.confirm.visible and guide.confirm.disabled,"route_confirmation_waits_for_two_real_covered_stops")
	_click_road(demo,"west-1")
	_click_road(demo,"west-2")
	_click_road(demo,"west-3")
	check(demo.transit_route_stops.size() == 3,"production_mouse_input_places_three_real_road_stops")
	_key(demo,KEY_BACKSPACE)
	check(demo.transit_route_stops.size() == 2,"backspace_reuses_existing_route_editing")
	_click_road(demo,"west-3")
	var preview: Dictionary = demo._transit_route_preview()
	var anchor: Dictionary = preview.get("charter_anchor",{})
	check(bool(preview.get("accepted",false)) and anchor.get("charter_id","") == charter_id,"route_preview_uses_current_charter_association")
	check(anchor.get("covered_scope_community_ids",[]).has("west-1") and anchor.get("uncovered_scope_community_ids",[]).has("east-1"),"preview_distinguishes_actual_scope_coverage_from_missing_community")
	guide.sync()
	check(not guide.confirm.disabled and guide.detail.text.contains("实际覆盖") and guide.detail.text.contains("尚未覆盖") and guide.detail.text.contains("实际客流"),"guide_explains_real_coverage_and_conditional_sound")
	var operation: Dictionary = demo._transit_route_operation(preview)
	check(operation.get("charter_id","") == charter_id and operation.get("stop_positions",[]).size() == 3,"formal_and_preview_operation_builder_share_charter_and_stops")
	before = demo.model.capture_state()
	_key(demo,KEY_SPACE)
	check(demo.preview_requested and demo.preview_thread != null and demo.preview_context_key.has(demo.transit_charter_context),"space_worker_identity_includes_transient_charter_context")
	var started := Time.get_ticks_msec()
	while demo.preview_thread != null and Time.get_ticks_msec()-started < 60000:
		await create_timer(0.02).timeout
		demo._process(0.0)
	check(demo.preview_started and guide.opened and guide.stage == "transit_anchor","actual_route_pcm_plays_while_planning_guide_stays_open")
	check(demo.preview_player.stream != null and demo.preview_player.stream.data.size() == int(demo.model.world.cfg["timing"]["sample_rate"])*3*4,"transit_anchor_preview_contains_three_seconds_of_real_pcm")
	_key(demo,KEY_SPACE,false)
	check(not demo.preview_started and demo.model.capture_state() == before,"space_release_restores_live_model_and_keeps_pending_charter")
	for window_size: Vector2 in [Vector2(1440,900),Vector2(800,600)]:
		root.size = Vector2i(window_size)
		demo.size = window_size
		guide.refresh()
		await process_frame
		await process_frame
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.get_global_rect()),"bus_panel_fits_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.confirm.get_global_rect()),"bus_confirm_fits_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
	_key(demo,KEY_ENTER)
	var action: Dictionary = guide.next_action.duplicate(true)
	var submitted: Dictionary = {}
	for pending in demo.model.world.pending_actions:
		if str(pending.get("kind","")) == "transit_line": submitted = pending
	check(submitted.get("charter_id","") == charter_id and submitted.get("stop_positions",[]) == operation["stop_positions"],"enter_submits_the_same_charter_route_as_preview")
	check(demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "charter"),"transit_submission_retains_selected_pending_charter")
	check(bool(action.get("transit_anchor",false)) and action.get("state","") == "queued" and action.get("event_id",-1) == submitted.get("event_id",-2),"transit_anchor_followup_queues_exact_authored_transaction")
	check(not demo.transit_route_mode and demo.transit_charter_context.is_empty() and not guide.opened,"submission_clears_transient_route_context")
	check(not guide._next_action_event_matches({"kind":"birth","district_id":str(demo.model.world.buildings[0]["district_id"]),"frame":action["expected_boundary_frame"],"plan_id":"corridor"}),"birth_cannot_complete_transit_anchor_followup")
	check(not guide._next_action_event_matches({"kind":"transit_line","charter_id":"other","event_id":action["event_id"],"frame":action["expected_boundary_frame"]}),"another_charter_cannot_complete_transit_followup")
	var retune: Dictionary = demo.model.submit({"kind":"retune","id":str(demo.model.world.buildings[0]["district_id"]),"midi":52,"expression":"bright"})
	guide.sync()
	check(bool(retune.get("accepted",false)) and guide.next_action.get("state","") == "queued","independent_real_retune_does_not_expire_queued_transit_followup")
	var landed := _settle(demo,true)
	check(not landed.is_empty() and guide._next_action_event_matches(landed) == false and guide.next_action.get("state","") == "ready","real_transit_event_reveals_ready_followup_once")
	check(guide.next_action.get("line_id","") == landed.get("id","") and not guide.next_action.get("stop_ids",[]).is_empty(),"followup_binds_actual_line_and_real_stop_identities")
	check(guide.detail.text.contains("实际覆盖") and guide.detail.text.contains("尚未覆盖") and not guide.next_reservation_button.visible,"transit_feedback_retains_scope_coverage_without_public_land_actions")
	var current_anchor := CharterAnchor.preview(demo.shown_world,landed,charter_id)
	check(guide.next_action.get("scope_covered_building_ids",[]) == current_anchor["scope_covered_building_ids"] and guide.detail.text.contains("%d栋房屋" % current_anchor["scope_covered_building_ids"].size()),"landed_feedback_counts_current_houses_inside_actual_charter_scope")
	var ready: Dictionary = guide.next_action.duplicate(true)
	guide.next_action_button.emit_signal("pressed")
	check(demo.context.get("kind","") == "transit_station" and ready["stop_ids"].has(demo.context.get("id","")) and demo.menu.visible,"followup_button_locates_a_real_station_on_landed_line")
	guide.next_action = ready.duplicate(true)
	guide.stage = "feedback"
	guide.opened = true
	guide.refresh()
	before = demo.model.capture_state()
	guide.next_combo_button.emit_signal("pressed")
	check(guide.stage == "charter" and guide.scope_seed == ["east-1","west-1"] and guide.scope_source.get("kind","") == "transit_charter","transit_combo_continuation_enters_normal_planning_with_original_scope")
	check(demo.model.capture_state() == before,"continuation_does_not_replay_old_charter_or_line")
	guide.cards.get_child(1).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	check(guide.stage == "scope" and guide.scope == ["east-1","west-1"],"continuation_scope_stays_editable_after_charter_and_card")
	# A fresh production city gives one-community reveal the same real chain.
	demo._start_world()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	charter_id = _choose_scope(demo,["west-1"])
	guide.transit_anchor_button.emit_signal("pressed")
	_click_road(demo,"west-1")
	_click_road(demo,"west-2")
	_key(demo,KEY_ENTER)
	landed = _settle(demo)
	check(not landed.is_empty() and guide.next_combo_button.visible and guide._combo_community_ids() == ["west-1"],"one_real_charter_community_also_offers_continuation")
	check(guide.detail.text.contains("所选社区已全部接入") and not guide.detail.text.contains("尚未覆盖"),"fully_connected_scope_has_clear_connected_feedback")
	guide.next_combo_button.emit_signal("pressed")
	check(guide.stage == "charter" and guide.scope_seed == ["west-1"],"single_community_continuation_preserves_ordinary_P_entry")
	charter_id = _choose_scope(demo,["west-1"])
	guide.transit_anchor_button.emit_signal("pressed")
	_click_road(demo,"west-1")
	_click_road(demo,"west-2")
	_key(demo,KEY_SPACE)
	guide.transit_anchor_button.emit_signal("pressed")
	demo._stop_preview()
	check(guide.stage == "anchor" and demo.transit_charter_context.is_empty() and not demo.transit_route_mode and not demo.preview_requested,"switching_back_to_public_choice_invalidates_route_worker_and_context")
	guide.transit_anchor_button.emit_signal("pressed")
	_key(demo,KEY_ESCAPE)
	check(guide.stage == "anchor" and not demo.transit_route_mode and demo.transit_charter_context.is_empty() and guide.committed_charter_id == charter_id,"escape_cancels_bus_draft_and_returns_to_usable_anchor_choice")
	guide.transit_anchor_button.emit_signal("pressed")
	guide.hide_tool()
	check(demo.transit_charter_context.is_empty() and not demo.transit_route_mode,"closing_guide_clears_charter_route_context")
	demo._verb("plan_transit")
	check(demo.transit_route_mode and demo.transit_charter_context.is_empty(),"ordinary_bus_tool_has_no_stale_charter_context")
	demo._clear_transit_route()
	charter_id = _choose_scope(demo,["west-1"])
	guide.transit_anchor_button.emit_signal("pressed")
	_click_road(demo,"west-1")
	_click_road(demo,"west-2")
	_key(demo,KEY_ENTER)
	demo._verb("plan_transit")
	_click_road(demo,"west-1")
	_click_road(demo,"west-3")
	_key(demo,KEY_ENTER)
	guide.sync()
	check(guide.next_action.get("state","") == "expired" and guide.detail.text.contains("撤回或替换"),"replacing_real_pending_line_expires_its_old_transit_followup")
	charter_id = _choose_scope(demo,["west-1"])
	guide.transit_anchor_button.emit_signal("pressed")
	demo.model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":[]})
	guide.sync()
	check(not guide.opened and demo.transit_charter_context.is_empty() and not demo.transit_route_mode,"replaced_charter_closes_its_old_route_draft")
	await _finish(demo)

func _finish(demo: Control) -> void:
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Production Guide, route mouse/key input and real three-second PCM worker; direct World settlement proves reveal/continuation UI. Dummy, no physical-device or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(evidence,"  ")+"\n")
	print("ROUND177_TRANSIT_CHARTER_UI "+JSON.stringify(evidence))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
