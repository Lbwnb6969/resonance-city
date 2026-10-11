extends SceneTree
## The production first composition uses physical audio and visible device time.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round180_第一段真实窗口"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var images: Dictionary = {}
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

func _click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(at)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	images[name] = demo.get_viewport().get_texture().get_image()

func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false

func _preview() -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.preview_started and not demo.expression_comparison.is_empty(): return true
	return false

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = demo.clock.renderer.transport.audible_frame
	start_skips = demo.clock.underruns
	var rate := demo.clock.renderer.transport.sample_rate
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","real_window_and_wasapi")
	check(demo.first_composition_mode and demo.shown_world.phrase_index == 0 and demo.shown_world.buildings.size() == 24 and demo.shown_world.buildings.all(func(b: Dictionary) -> bool: return b["form"] == "胚") and not demo.planning_guide.opened,"default_is_unsettled_24_house_river_composition")
	check(not demo.first_composition_guide.visible and demo.shown_world.public_sites.all(func(s: Dictionary) -> bool: return not bool(s["active"])),"overture_has_no_preset_public_anchor_or_choice")
	await _capture("first_overture")
	check(await _until(10*rate+rate/10),"ten_seconds_of_real_city_audio")
	check(demo.first_composition_guide.visible,"audible_overture_invites_first_charter")
	demo.first_composition_guide.emit_signal("pressed")
	var guide = demo.planning_guide
	check(guide.cards.get_child_count() == 3 and guide.scope.is_empty(),"player_chooses_one_of_three_charters_and_community")
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var choices := First.opportunities(demo.shown_world)
	var site: Dictionary = choices["public_candidates"][0]
	var public_position := Vector2(float(site["position"][0]),float(site["position"][1]))
	_click(public_position)
	guide.confirm.emit_signal("pressed")
	check(guide.stage == "anchor" and not guide.transit_anchor_button.visible,"first_planning_uses_one_public_anchor")
	guide.actions.get_child(3).emit_signal("pressed")
	_click(public_position)
	var public_request: Dictionary = guide.next_action.duplicate(true)
	check(public_request.get("state","") == "queued" and bool(public_request.get("first_composition_anchor",false)),"chosen_civic_waits_for_real_boundary")
	check(await _until(int(public_request["expected_boundary_frame"])+rate/10),"public_reveals_at_physical_audio_boundary")
	check(guide.next_action.get("state","") == "ready" and guide.opened,"matching_anchor_offers_sound_choice")
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and demo.context.get("community_id","") == site["community_id"] and demo.expression_choice.is_empty() and demo.expression_confirm.disabled,"sound_choice_opens_locally_without_selecting_or_submitting")
	if not demo.menu.visible or not demo.context.has("position"):
		await _finish()
		return
	var before := demo.model.world.snapshot()
	demo.expression_choices["deep"].emit_signal("pressed")
	check(demo.model.world.snapshot() == before,"candidate_button_does_not_submit")
	_key(KEY_SPACE)
	check(await _preview(),"three_actual_pcm_candidates_ready")
	if demo.expression_comparison.is_empty():
		await _finish()
		return
	check(demo.expression_comparison_summary.visible and demo.expression_comparison_summary.text.contains("高音短促，密集织拍") and demo.expression_comparison_summary.text.contains("保留1片空地"),"production_comparison_card_exposes_actual_register_rhythm_and_city_consequence")
	var comparison := demo.expression_comparison.duplicate(true)
	check(comparison["variants"].values().all(func(v: Dictionary) -> bool: return bool(v["accepted"]) and v["pcm"].size() == rate*4*4),"three_accepted_four_second_full_scores")
	var source_key := str(comparison["source_key"])
	for choice: String in ["weave","warm","deep","weave"]:
		demo.expression_choices[choice].emit_signal("pressed")
		check(demo.preview_player.stream.data == comparison["variants"][choice]["pcm"] and str(demo.expression_comparison["source_key"]) == source_key,"switch_"+choice+"_reuses_same_source_pcm")
	_key(KEY_SPACE,false)
	check(not demo.preview_started and not demo.model.synth.ducking,"release_restores_real_city")
	await _capture("first_three_expressions")
	DisplayServer.window_set_size(Vector2i(800,600))
	await process_frame
	await process_frame
	demo._show_context_menu()
	demo.expression_choices["weave"].emit_signal("pressed")
	await process_frame
	check(Rect2(Vector2.ZERO,demo.size).encloses(demo.menu.get_global_rect()) and Rect2(Vector2.ZERO,demo.size).encloses(demo.expression_confirm.get_global_rect()),"three_choices_and_confirmation_fit_small_window")
	await _capture("first_three_expressions_small")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await process_frame
	await process_frame
	var operation := demo.PlayerExpression.operation("weave",demo.context["position"])
	var boundary := demo.model.next_boundary
	_key(KEY_ENTER)
	check(not demo.menu.visible and demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return bool(op.get("player_expression",false)) and op["expression"] == "weave"),"enter_confirms_only_player_chosen_expression")
	check(await _until(boundary+rate/5),"chosen_expression_lands_at_audible_boundary")
	var root_id := ""
	for b: Dictionary in demo.shown_world.buildings:
		if b["position"] == operation["position"] and bool(b.get("player_expression",false)): root_id = str(b["district_id"])
	check(not root_id.is_empty() and demo.shown_world.by_id[root_id]["type"] == "commercial" and demo.shown_world.community_expression(str(site["community_id"])) == "weave","player_choice_is_real_commercial_family_and_community_voice")
	_key(KEY_P)
	check(not demo.model.audible_theme().is_empty() and guide.theme_rework_button.visible,"six_naturally_mature_houses_offer_authored_theme_edit")
	guide.theme_rework_button.emit_signal("pressed")
	var author_id := demo.selected_id
	check(demo.menu.visible and demo.context.get("kind","") == "retune" and not author_id.is_empty(),"theme_button_opens_real_source_without_auto_pitch")
	check(bool(demo.shown_world.by_id.get(author_id,{}).get("player_expression",false)),"theme_button_targets_the_player_authored_root")
	check(demo.menu_info.text.contains("实际路线结果") and demo.menu_info.text.contains("家族"),"theme_menu_exposes_actual_route_result_without_future_claim")
	if author_id.is_empty():
		await _finish()
		return
	var old_pitch := int(demo.shown_world.by_id[author_id]["current_midi"])
	var new_pitch := 52 if old_pitch != 52 else 55
	demo._choose_note(new_pitch)
	demo._verb("focus")
	var deadline := Time.get_ticks_msec()+24000
	var heard := false
	var heard_reply := false
	while Time.get_ticks_msec() < deadline and not (heard and heard_reply):
		await process_frame
		for mark: Dictionary in demo.music_activity_layer.marks:
			if int(mark["generation"]) == 0 and str(mark["source_id"]) == author_id and posmod(int(mark["pitch"]),12) == posmod(new_pitch,12):
				if not heard: await _capture("first_authored_note")
				heard = true
				evidence["new_lead"] = mark.duplicate(true)
			if int(mark["generation"]) == 1:
				if not heard_reply: await _capture("first_actual_reply")
				heard_reply = true
				evidence["actual_reply"] = mark.duplicate(true)
	check(heard,"one_house_new_pitch_is_actual_audible_lead_and_map_source")
	check(heard_reply,"natural_theme_has_actual_two_beat_reply_map_source")
	check(demo.capture_city()["view"]["first_composition_mode"],"new_opening_mode_is_saved_without_rewarming_world")
	evidence["public_request"] = public_request
	evidence["comparison"] = {"source_key":source_key,"source_frame":comparison["source_frame"],"boundary_frame":comparison["boundary_frame"]}
	evidence["voice_limit"] = demo.model.synth.max_voice_count
	evidence["houses"] = demo.shown_world.buildings.size()
	evidence["era"] = demo.shown_world.era
	evidence["device_frames"] = demo.clock.renderer.transport.audible_frame-start_frame
	evidence["new_underruns"] = demo.clock.underruns-start_skips
	check(evidence["new_underruns"] == 0 and evidence["device_frames"] > 32*rate,"physical_audio_continues_through_first_composition")
	await _finish()

func _finish() -> void:
	demo._stop_preview()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for name: String in images: images[name].save_png(OUTPUT+"/"+name+".png")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"Production UI, Windows/WASAPI physical frames and screenshots; no human fun, authorship or listening verdict."}
	var file := FileAccess.open(OUTPUT+"/first_composition_demo_live.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ROUND180_FIRST_COMPOSITION_LIVE ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
