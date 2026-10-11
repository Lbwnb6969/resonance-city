extends SceneTree
## Same-source route A/B through the production Guide and preview worker.
const World = preload("res://scripts/world/continuous_world.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const OUTPUT := "res://验证记录/round179_公交同源比较/transit_comparison_ui.json"
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

func _click_road(demo: Control,id: String) -> void:
	var p: Array = demo.model.world.nodes[id]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = demo.point(Vector2(float(p[0]),float(p[1])))
	demo._gui_input(event)

func _worker(demo: Control) -> void:
	var started := Time.get_ticks_msec()
	while demo.preview_thread != null and Time.get_ticks_msec()-started < 60000:
		await create_timer(0.02).timeout
		demo._process(0.0)

func _redraw(demo: Control,ids: Array) -> void:
	demo.planning_guide.transit_redraw_button.emit_signal("pressed")
	for id in ids: _click_road(demo,str(id))
	demo.planning_guide.sync()

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var frame := (city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"])
	var original := {"kind":"transit_line","source_topology":city.network.topology,
		"stop_positions":[city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate(),city.nodes["west-3"].duplicate()]}
	check(bool(city.request(original,frame).get("accepted",false)),"fixture_queues_real_authored_route")
	city.settle(frame)
	var line_id := str(city.authored_transit_lines[0]["id"])
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
	for button in demo.transit_edit_choices.get_children():
		if str(button.get_meta("line_id","")) == line_id: button.emit_signal("pressed")
	check(guide.stage == "transit_edit" and guide.transit_choice == "edit" and guide.transit_compare_row.visible,"station_line_choice_enters_two_variant_edit_stage")
	check(guide.actions.get_child_count() == 4 and guide.actions.get_child(1).get_meta("anchor_kind") == "none","comparison_keeps_existing_public_button_indices")
	_redraw(demo,["west-1","west-4"])
	var before: Dictionary = demo.model.capture_state()
	_key(demo,KEY_SPACE)
	check(demo.preview_thread != null and demo.preview_requested,"space_starts_one_real_two_variant_worker")
	await _worker(demo)
	check(demo.preview_started and guide.transit_comparison_is_current(),"real_A_B_worker_accepts_current_source_and_plays_default_edit")
	var comparison: Dictionary = guide.transit_comparison
	var source_key: Array = guide.transit_comparison_key.duplicate(true)
	var source_frame := int(comparison.get("source_frame",-1))
	var boundary := int(comparison.get("boundary_frame",-1))
	var keep: Dictionary = comparison.get("variants",{}).get("keep",{})
	var edit: Dictionary = comparison.get("variants",{}).get("edit",{})
	check(bool(keep.get("accepted",false)) and bool(edit.get("accepted",false)) and keep.get("revision",-1) == 0 and edit.get("revision",-1) == 1,"two_branches_render_real_retained_and_edited_line")
	check(boundary == demo.model.next_boundary and source_frame == demo.clock.renderer.transport.rendered_frames,"A_B_uses_one_captured_frame_and_real_next_boundary")
	check(keep["pcm"].size() == int(city.cfg["timing"]["sample_rate"])*3*4 and edit["pcm"].size() == keep["pcm"].size(),"both_choices_have_three_seconds_of_real_pcm")
	check(guide.detail.text.contains("保留原线") and guide.detail.text.contains("改站") and guide.detail.text.contains("实际覆盖"),"guide_shows_both_actual_coverage_choices")
	var music_message := str(edit.get("music_feedback",{}).get("message","实际客流")).replace("pulse_dense","密集脉冲节奏").replace("pulse","脉冲节奏")
	check(not keep.get("opportunities",[]).is_empty() and not edit.get("opportunities",[]).is_empty() and guide.detail.text.contains(music_message),"guide_reads_branch_specific_real_sound_conditions")
	guide.transit_keep_button.emit_signal("pressed")
	check(guide.transit_choice == "keep" and demo.preview_player.stream.data == keep["pcm"] and demo.preview_thread == null,"keep_button_switches_to_existing_keep_pcm_without_new_worker")
	guide.transit_change_button.emit_signal("pressed")
	check(guide.transit_choice == "edit" and demo.preview_player.stream.data == edit["pcm"] and guide.transit_comparison_key == source_key and int(guide.transit_comparison["source_frame"]) == source_frame and int(guide.transit_comparison["boundary_frame"]) == boundary,"edit_button_reuses_identical_source_and_boundary")
	check(guide.transit_comparison == comparison,"switching_choices_does_not_rebuild_private_payload")
	for window_size: Vector2 in [Vector2(1440,900),Vector2(800,600)]:
		root.size = Vector2i(window_size)
		demo.size = window_size
		guide.refresh()
		await process_frame
		await process_frame
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.get_global_rect()),"comparison_panel_fits_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.transit_compare_row.get_global_rect()) and Rect2(Vector2.ZERO,window_size).encloses(guide.confirm.get_global_rect()),"comparison_choices_and_confirm_fit_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
	_key(demo,KEY_SPACE,false)
	check(not demo.preview_requested and not demo.preview_started and demo.model.capture_state() == before,"space_release_restores_original_model_and_controls")
	guide.transit_keep_button.emit_signal("pressed")
	before = demo.model.capture_state()
	var event_count := city.events.size()
	_key(demo,KEY_ENTER)
	check(not guide.opened and not demo.transit_route_mode and demo.transit_edit_context.is_empty() and demo.model.capture_state() == before and city.events.size() == event_count,"keep_without_pending_closes_editor_without_model_or_event_mutation")
	# Cancel only this real queued edit, even after its draft has been emptied.
	demo._begin_transit_edit(line_id)
	_redraw(demo,["west-1","west-4"])
	_key(demo,KEY_ENTER)
	check(guide.next_action.get("state","") == "queued" and bool(guide.next_action.get("transit_edit",false)),"edit_choice_still_queues_actual_same_line_followup")
	demo.model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":[]})
	demo.model.submit({"kind":"retune","id":str(city.buildings[0]["district_id"]),"midi":52,"expression":"bright"})
	var independent: Array = []
	for pending in city.pending_actions:
		if str(pending.get("kind","")) != "transit_line": independent.append(pending.duplicate(true))
	demo._begin_transit_edit(line_id)
	_redraw(demo,[])
	guide.transit_keep_button.emit_signal("pressed")
	check(not guide.confirm.disabled and demo.transit_route_stops.is_empty(),"keep_confirmation_accepts_an_empty_edit_draft")
	_key(demo,KEY_ENTER)
	check(city.pending_actions == independent and guide.next_action.get("state","") == "consumed" and city.events.size() == event_count,"keep_cancels_only_same_line_pending_edit_without_new_event")
	# Invalid draft still renders keep from the same actual private source.
	demo._begin_transit_edit(line_id)
	_redraw(demo,[])
	guide.transit_keep_button.emit_signal("pressed")
	_key(demo,KEY_SPACE)
	await _worker(demo)
	check(demo.preview_started and bool(guide.transit_comparison["variants"]["keep"]["accepted"]) and not bool(guide.transit_comparison["variants"]["edit"]["accepted"]),"empty_draft_still_previews_valid_keep_and_rejects_edit")
	guide.transit_change_button.emit_signal("pressed")
	check(not demo.preview_started and demo.preview_requested and guide.confirm.disabled and not demo.preview_duck_owned,"invalid_edit_selection_restores_live_without_losing_held_comparison")
	guide.transit_keep_button.emit_signal("pressed")
	check(demo.preview_started and demo.preview_thread == null,"switching_back_to_keep_uses_same_cached_pcm")
	_key(demo,KEY_SPACE,false)
	_redraw(demo,["west-1","west-4"])
	_key(demo,KEY_SPACE)
	guide.hide_tool()
	await _worker(demo)
	check(not demo.preview_requested and not demo.preview_started and guide.transit_comparison.is_empty(),"closing_editor_rejects_in_flight_A_B_worker")
	demo._begin_transit_edit(line_id)
	_redraw(demo,["west-1","west-4"])
	_key(demo,KEY_SPACE)
	guide.transit_redraw_button.emit_signal("pressed")
	await _worker(demo)
	check(not demo.preview_requested and not demo.preview_started and guide.transit_comparison.is_empty() and demo.transit_route_stops.is_empty(),"redraw_rejects_old_worker_and_clears_comparison_source")
	_redraw(demo,["west-1","west-4"])
	_key(demo,KEY_SPACE)
	demo.model.submit({"kind":"focus","community":"west-1"})
	guide.sync()
	await _worker(demo)
	check(not demo.preview_requested and not demo.preview_started and guide.transit_comparison.is_empty(),"real_audio_control_change_invalidates_in_flight_comparison")
	_key(demo,KEY_SPACE)
	await _worker(demo)
	check(demo.preview_started and guide.transit_comparison_is_current(),"fresh_space_after_control_change_captures_current_source")
	demo.model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1"],"card_refs":[]})
	guide.sync()
	check(guide.transit_comparison.is_empty() and not demo.preview_requested and not demo.preview_started,"pending_change_invalidates_cached_A_B_and_restores_city")
	_key(demo,KEY_SPACE)
	var external_edit: Dictionary = demo.model.submit(demo._transit_route_operation(demo._transit_route_preview()))
	city.settle(int(external_edit["frame"]))
	demo.shown_world = city
	guide.sync()
	await _worker(demo)
	check(not guide.opened and demo.transit_edit_context.is_empty() and guide.transit_comparison.is_empty() and not demo.preview_started,"real_line_revision_change_closes_editor_and_rejects_old_comparison_worker")
	demo._start_world()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	check(guide.transit_comparison.is_empty() and demo.transit_edit_context.is_empty() and not demo.preview_requested,"city_switch_clears_transient_comparison")
	await _finish(demo)

func _finish(demo: Control) -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Production station menu, real road draft, Guide A/B buttons, worker PCM, keep/edit submissions and source invalidation. Dummy, no physical-device or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND179_TRANSIT_COMPARISON_UI "+JSON.stringify(report))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
