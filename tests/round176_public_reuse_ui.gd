extends SceneTree
## Production public menu -> fixed reuse comparison -> real World reveal.
## Dummy proves UI/model behavior; the parent owns physical-device evidence.
const Reuse = preload("res://scripts/world/public_site_reuse.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")
const OUTPUT := "res://验证记录/round176_公共空间原位改用/public_reuse_ui.json"
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

func _open(demo: Control,id: String) -> void:
	var site := Reuse._site(demo.model.world,id)
	demo.context = {"kind":str(site["kind"]),"id":id}
	demo._show_context_menu()
	demo.planning_buttons["reuse_public"].emit_signal("pressed")

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
	var site := Reuse.candidate(demo.model.world,"west-civic")
	check(bool(site.get("allowed",false)) and site.get("current_kind","") == "civic","production_starter_has_active_civic_to_reuse")
	if not bool(site.get("allowed",false)):
		await _finish(demo)
		return
	var source: Dictionary = demo.model.capture_state()
	demo.context = {"kind":"civic","id":"west-civic"}
	demo._show_context_menu()
	check(demo.planning_buttons["reuse_public"].visible and not demo.planning_buttons["reuse_public"].disabled,"active_public_menu_has_direct_reuse_entry")
	check(not demo.planning_buttons["civic"].disabled,"original_cultural_expansion_entry_stays_enabled")
	demo.planning_buttons["reuse_public"].emit_signal("pressed")
	check(guide.opened and guide.stage == "reuse_anchor" and not demo.menu.visible,"menu_opens_fixed_public_reuse_panel")
	check(guide.anchor_kind == "none" and guide.actions.get_child(1).text == "保留当前用途","reuse_defaults_to_retaining_current_use")
	check(guide.plan_id.is_empty() and guide.card_id.is_empty() and guide.scope.is_empty(),"existing_public_reuse_does_not_require_or_replay_charter_scope")
	check(Planning.footprint_components(guide.candidate) == Planning.footprint_components(site) and Planning.footprint_holes(guide.candidate) == Planning.footprint_holes(site),"fixed_candidate_preserves_complete_authored_footprint")
	var identity: Array = guide.comparison_identity()
	demo.pointer += Vector2(130,-70)
	guide.update_candidate(Vector2(-100,-100))
	check(guide.comparison_identity() == identity and guide.candidate == site,"pointer_motion_cannot_replace_original_public_target")
	guide.map_click(Vector2(-100,-100),false)
	check(demo.model.capture_state() == source,"opening_and_offsite_map_click_do_not_mutate_city_or_saved_model")
	guide.confirm.emit_signal("pressed")
	check(not guide.opened and guide.reuse_site.is_empty() and demo.model.capture_state() == source,"confirming_retain_closes_draft_without_city_operation")
	_open(demo,"west-civic")
	guide.choose_anchor("park")
	_key(demo,KEY_SPACE)
	check(demo.preview_public and demo.preview_requested and demo.preview_thread != null,"holding_space_uses_production_public_compare_worker")
	var expired_key: Array = demo.preview_context_key.duplicate(true)
	var focus: Dictionary = demo.model.submit({"kind":"focus","community":"west-1"})
	check(bool(focus.get("accepted",false)) and expired_key != guide.comparison_identity() and guide.public_reuse_is_current(),"real_focus_intent_expires_worker_source_without_invalidating_public_site")
	source = demo.model.capture_state()
	var restarted := false
	var started := Time.get_ticks_msec()
	while demo.preview_thread != null and Time.get_ticks_msec()-started < 60000:
		await create_timer(0.02).timeout
		demo._process(0.0)
		if demo.preview_thread != null and demo.preview_context_key != expired_key and demo.preview_requested: restarted = true
	check(restarted,"held_space_automatically_restarts_stale_reuse_comparison")
	check(not guide.comparison.is_empty() and demo.preview_started,"reuse_worker_accepts_same_source_and_starts_selected_pcm")
	if guide.comparison.is_empty():
		await _finish(demo)
		return
	check(guide.comparison_key == guide.comparison_identity() and guide.comparison_key != expired_key,"restarted_comparison_accepts_only_current_real_source")
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = guide.comparison["variants"][kind]
		check(bool(variant.get("accepted",false)) and variant.get("pcm",PackedByteArray()).size() == int(demo.model.world.cfg["timing"]["sample_rate"])*3*4,kind+"_fixed_reuse_branch_has_real_three_second_pcm")
		check(str(variant.get("anchor",{}).get("id","")) == "west-civic",kind+"_comparison_keeps_real_public_identity")
	var comparison_before: Dictionary = guide.comparison.duplicate(true)
	guide.actions.get_child(3).emit_signal("pressed")
	check(guide.anchor_kind == "civic" and demo.preview_player.stream.data == guide.comparison["variants"]["civic"]["pcm"],"civic_button_replays_its_captured_branch_while_space_is_held")
	guide.actions.get_child(2).emit_signal("pressed")
	check(guide.anchor_kind == "park" and guide.comparison == comparison_before,"switching_use_keeps_all_captured_comparison_branches")
	_key(demo,KEY_SPACE,false)
	check(not demo.preview_requested and not demo.preview_started and demo.model.capture_state() == source,"releasing_space_restores_original_model_and_mix")
	check(guide.detail.text.contains("保留当前用途") and guide.detail.text.contains("原占地") and not guide.detail.text.contains("占用这片空地"),"comparison_explains_retention_and_same_public_footprint")
	guide.begin_public_reuse(site)
	guide.choose_anchor("park")
	_key(demo,KEY_SPACE)
	expired_key = demo.preview_context_key.duplicate(true)
	demo.model.submit({"kind":"focus","community":"east-1"})
	check(expired_key != guide.comparison_identity(),"second_real_focus_expires_inflight_comparison")
	_key(demo,KEY_SPACE,false)
	started = Time.get_ticks_msec()
	while demo.preview_thread != null and Time.get_ticks_msec()-started < 60000:
		await create_timer(0.02).timeout
		demo._process(0.0)
	check(demo.preview_thread == null and not demo.preview_requested and not demo.preview_started and guide.comparison.is_empty(),"released_space_does_not_restart_or_play_stale_worker")
	for window_size: Vector2 in [Vector2(1440,900),Vector2(800,600)]:
		root.size = Vector2i(window_size)
		demo.size = window_size
		guide.refresh()
		await process_frame
		await process_frame
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.confirm.get_global_rect()),"confirm_button_fits_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.actions.get_global_rect()),"reuse_choices_fit_"+str(int(window_size.x))+"x"+str(int(window_size.y)))
	guide.confirm.emit_signal("pressed")
	var action: Dictionary = guide.next_action.duplicate(true)
	check(action.get("state","") == "queued" and action.get("contract","") == NextAction.CONTRACT and bool(action.get("reuse",false)),"confirmation_queues_existing_next_action_contract")
	check(not guide.opened and guide.reuse_site.is_empty() and guide.candidate.is_empty(),"confirmation_clears_transient_fixed_target")
	var operation: Dictionary = demo.model.world.pending_actions.back()
	check(bool(operation.get("reuse",false)) and operation.get("id","") == "west-civic" and operation.get("position",[]) == site["position"],"confirmation_submits_exact_original_public_site_without_old_scope")
	check(Reuse._site(demo.model.world,"west-civic")["kind"] == "civic","queued_reuse_does_not_change_facility_before_boundary")
	var boundary := int(action["expected_boundary_frame"])
	var wrong := {"kind":"park","reuse":true,"id":"other","source_revision":action["source_revision"],"event_id":action["event_id"],"frame":boundary}
	check(not guide._next_action_event_matches(wrong),"another_public_identity_cannot_activate_reuse_feedback")
	demo.model.world.settle(boundary)
	demo.shown_world = demo.model.world
	var landed: Dictionary = {}
	for event in demo.shown_world.events:
		if bool(event.get("reuse",false)) and event.get("id","") == "west-civic": landed = event
	check(not landed.is_empty() and guide._next_action_event_matches(landed),"authoritative_same_site_reuse_event_matches_queued_transaction")
	guide.sync()
	check(guide.next_action.get("state","") == "ready" and guide.next_action.get("public_id","") == "west-civic","next_boundary_reopens_real_public_followup")
	check(guide.detail.text.contains("原位改用") and not guide.detail.text.contains("剩余留地") and not guide.next_reservation_button.visible,"reuse_feedback_avoids_unrelated_residual_land")
	guide.next_action_button.emit_signal("pressed")
	check(demo.context.get("kind","") == "park" and demo.context.get("id","") == "west-civic" and demo.menu.visible,"followup_locates_changed_use_of_same_real_public_site")
	_open(demo,"west-civic")
	var reopened := Reuse.candidate(demo.model.world,"west-civic")
	check(guide.reuse_site["current_kind"] == "park" and guide.anchor_kind == "none","changed_facility_can_immediately_be_compared_again")
	# Change the actual source through the production World request/settle path;
	# it must invalidate the already open draft without inventing a new target.
	var next_boundary := boundary+int(demo.model.world.cfg["timing"]["phrase_frames"])
	var changed: Dictionary = demo.model.world.request({"kind":"civic","reuse":true,"id":"west-civic","position":reopened["position"],"source_revision":reopened["source_revision"]},next_boundary)
	check(bool(changed.get("accepted",false)),"real_source_edit_can_be_queued_independently")
	demo.model.world.settle(next_boundary)
	guide.sync()
	check(not guide.opened and guide.reuse_site.is_empty() and guide.comparison.is_empty(),"changed_source_revision_closes_old_reuse_draft")
	_open(demo,"west-civic")
	guide.hide_tool()
	check(guide.reuse_site.is_empty() and guide.comparison_key.is_empty(),"cancel_clears_fixed_target_and_comparison_identity")
	_open(demo,"west-civic")
	guide.reset_for_city()
	check(guide.reuse_site.is_empty() and guide.candidate.is_empty() and guide.stage == "charter","city_reset_clears_public_reuse_state")
	_open(demo,"west-civic")
	guide.choose_anchor("park")
	guide.confirm.emit_signal("pressed")
	check(demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return bool(op.get("reuse",false)) and op.get("id","") == "west-civic"),"same_site_reuse_is_really_queued_before_retaining")
	var city = demo.model.world
	var seed_position := Vector2.INF
	var reserve_site: Dictionary = {}
	for lot in city.lots:
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if seed_position == Vector2.INF and bool(city.placement(p).get("allowed",false)):
			seed_position = p
			continue
		if p == seed_position: continue
		var other: Dictionary = city.planning_candidate(p)
		if reserve_site.is_empty() and bool(other.get("allowed",false)) and not other.has("public_id") and not other.has("reservation_id"):
			reserve_site = other
	var charter: Dictionary = demo.model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":["infill_pulse"]})
	var seeded: Dictionary = demo.model.submit({"kind":"seed","position":[seed_position.x,seed_position.y],"midi":48,"expression":"bright"})
	var transit: Dictionary = demo.model.submit({"kind":"transit_line","stop_positions":[city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate()],"source_topology":city.network.topology})
	check(bool(charter.get("accepted",false)) and bool(seeded.get("accepted",false)) and bool(transit.get("accepted",false)),"unrelated_charter_seed_and_transit_intents_queue_through_production")
	var independent: Array = city.pending_actions.filter(func(op: Dictionary) -> bool: return not bool(op.get("reuse",false))).duplicate(true)
	_open(demo,"west-civic")
	guide.confirm.emit_signal("pressed")
	check(city.pending_actions == independent and not city.pending_actions.any(func(op: Dictionary) -> bool: return bool(op.get("reuse",false)) and op.get("id","") == "west-civic"),"retaining_cancels_only_same_site_reuse_and_preserves_independent_intents")
	check(guide.next_action.is_empty() and Reuse._site(city,"west-civic")["kind"] == "civic","retaining_cancel_removes_queued_followup_and_keeps_current_facility")
	check(not reserve_site.is_empty(),"another_real_legal_plot_is_available_for_independent_land_intent")
	if not reserve_site.is_empty():
		var reserved: Dictionary = demo.model.submit({"kind":"reserve","position":reserve_site["position"].duplicate()})
		check(bool(reserved.get("accepted",false)),"independent_other_plot_planning_queues_through_production")
		var with_reserve: Dictionary = demo.model.capture_state()
		_open(demo,"west-civic")
		guide.confirm.emit_signal("pressed")
		check(demo.model.capture_state() == with_reserve,"retaining_without_same_site_reuse_preserves_other_plot_plan_and_full_model")
	await _finish(demo)

func _finish(demo: Control) -> void:
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Production Demo controls and real preview PCM; direct World boundary settlement verifies UI reveal only. Dummy audio, no physical-device or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(evidence,"  ")+"\n")
	print("ROUND176_PUBLIC_REUSE_UI "+JSON.stringify(evidence))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
