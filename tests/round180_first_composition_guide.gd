extends SceneTree
## Young-city planning remains authored, and first sound follows a real public reveal.
const World = preload("res://scripts/world/continuous_world.gd")
const FirstComposition = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round180_第一段作品/first_composition_guide.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _click(demo: Control,position: Array) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = demo.point(Vector2(float(position[0]),float(position[1])))
	demo._gui_input(event)

func _run() -> void:
	var city := World.new("2026101100000180",true,"river_valley")
	city.build_first_composition_starter()
	var available := FirstComposition.opportunities(city)
	check(city.phrase_index == 0 and city.buildings.size() == 24 and available["community_ids"].size() == 3 and city.public_sites.all(func(site: Dictionary) -> bool: return not bool(site["active"])),"fixture_is_real_young_three_community_city_without_active_anchor")
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.first_composition_mode = true
	var guide = demo.planning_guide
	guide.reset_for_city()
	var invitation = demo.first_composition_guide
	invitation.reset_for_city()
	var before := city.snapshot()
	var rate := int(city.cfg["timing"]["sample_rate"])
	demo.clock.renderer.transport.rendered_frames = 30*rate
	demo.clock.renderer.transport.audible_frame = invitation.origin_frame+float(9*rate)
	invitation.sync()
	check(not invitation.visible and not guide.opened,"render_ahead_does_not_skip_audible_ten_second_overture")
	demo.clock.renderer.transport.audible_frame = invitation.origin_frame+float(10*rate)
	invitation.sync()
	check(invitation.visible and invitation.text == "写第一段 · 选择发展章程","overture_offers_one_small_planning_invitation")
	invitation.emit_signal("pressed")
	check(guide.opened and guide.stage == "charter" and guide.cards.get_child_count() == 3 and guide.scope.is_empty() and city.snapshot() == before,"invitation_opens_three_charters_without_selecting_scope_or_mutating_city")
	for window_size: Vector2 in [Vector2(1440,900),Vector2(800,600)]:
		root.size = Vector2i(window_size)
		demo.size = window_size
		guide.refresh()
		await process_frame
		await process_frame
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.get_global_rect()),"first_charter_choices_fit_"+str(int(window_size.x)))
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	check(guide.stage == "scope" and guide.scope.is_empty(),"chosen_charter_and_card_leave_community_to_player")
	var target: Dictionary = available["public_candidates"][0]
	_click(demo,target["position"])
	check(guide.scope == [target["community_id"]],"actual_map_click_selects_player_community")
	guide.confirm.emit_signal("pressed")
	check(guide.stage == "anchor" and not guide.transit_anchor_button.visible and guide.actions.get_child(1).get_meta("anchor_kind") == "none" and guide.actions.get_child(3).get_meta("anchor_kind") == "civic","first_anchor_keeps_public_choices_without_default_transit_detour")
	guide.actions.get_child(3).emit_signal("pressed")
	_click(demo,target["position"])
	var pending: Dictionary = guide.next_action.duplicate(true)
	check(not guide.opened and bool(pending.get("first_composition_anchor",false)) and pending.get("state","") == "queued" and pending.get("choice","") == "civic","player_public_anchor_queues_precise_first_sound_followup")
	# An independent house edit must not erase the promised anchor reveal.
	demo.model.submit({"kind":"retune","id":str(city.buildings[0]["district_id"]),"midi":48,"expression":"warm"})
	guide.sync()
	check(guide.next_action.get("state","") == "queued","independent_house_tuning_does_not_expire_anchor_handoff")
	var old_presentation := World.new(city.rng.seed_hex,true,"river_valley")
	old_presentation.restore(city.snapshot())
	city.settle(int(pending["expected_boundary_frame"]))
	demo.shown_world = old_presentation
	guide.sync()
	check(not guide.opened and guide.next_action.get("state","") == "queued","future_model_settlement_does_not_show_sound_choice_before_audible_world")
	var anchor_event: Dictionary = {}
	for event: Dictionary in city.events:
		if str(event.get("id","")) == str(pending["public_id"]) and str(event.get("kind","")) == "civic": anchor_event = event
	var unrelated := anchor_event.duplicate(true)
	unrelated["id"] = "other-public-anchor"
	check(not anchor_event.is_empty() and not guide._next_action_event_matches(unrelated),"handoff_rejects_another_facility_at_the_same_boundary")
	demo.shown_world = city
	guide.sync()
	check(guide.opened and guide.stage == "feedback" and guide.next_action.get("state","") == "ready" and guide.next_action["community_id"] == target["community_id"] and guide.next_action_button.text == "选一个声音，沿这个社区继续" and not guide.next_combo_button.visible,"real_matching_public_reveal_offers_one_local_sound_choice")
	for window_size: Vector2 in [Vector2(1440,900),Vector2(800,600)]:
		root.size = Vector2i(window_size)
		demo.size = window_size
		guide.refresh()
		await process_frame
		await process_frame
		check(Rect2(Vector2.ZERO,window_size).encloses(guide.get_global_rect()) and Rect2(Vector2.ZERO,window_size).encloses(guide.next_action_button.get_global_rect()),"first_sound_handoff_fits_"+str(int(window_size.x)))
	before = city.snapshot()
	guide.next_action_button.emit_signal("pressed")
	var sound_handoff := {"opened":guide.opened,"state":guide.next_action.get("state",""),"menu_visible":demo.menu.visible,"context":demo.context.duplicate(true),"notice":demo.notice,"seed_candidates":FirstComposition.opportunities(city)["seed_candidates"]}
	check(not guide.opened and guide.next_action.get("state","") == "consumed" and demo.menu.visible and bool(demo.context.get("first_composition",false)) and demo.context.get("community_id","") == target["community_id"],"sound_handoff_opens_existing_demo_choice_for_actual_anchor_community")
	check(demo.expression_choices.size() == 3 and demo.expression_choices.has_all(["deep","weave","warm"]) and demo.expression_choice.is_empty() and city.snapshot() == before,"handoff_offers_three_expressions_without_auto_selecting_or_submitting")
	demo.first_composition_mode = false
	guide.open_tool()
	guide.choose_plan("compact")
	guide.choose_card(guide.card_id)
	guide.scope = [target["community_id"]]
	guide.stage = "anchor"
	guide.refresh()
	check(guide.transit_anchor_button.visible,"existing_non_first_planning_keeps_transit_entry")
	guide.reset_for_city()
	invitation.reset_for_city()
	invitation.sync()
	check(guide.next_action.is_empty() and not invitation.visible,"city_reset_clears_first_handoff_and_non_first_invitation")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"sound_handoff":sound_handoff,"scope":"Dummy production Guide and real young World authoring/reveal; controlled presentation frames test overture and render-ahead separation, no physical-device or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND180_FIRST_COMPOSITION_GUIDE "+JSON.stringify(report))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
