extends "res://tests/round211_sound_stage_live.gd"
## One native planning-to-public-space-to-authored-voice production journey.
const First = preload("res://scripts/world/first_composition.gd")
var planning_layouts: Array[Dictionary] = []

func at_pointer(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await process_frame

func click_map(at: Vector2) -> void:
	await at_pointer(at)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		await process_frame

func planning_layout(label: String) -> void:
	var guide = demo.planning_guide
	var panel: Rect2 = guide.get_global_rect()
	check(panel.size.x <= 366 and panel.size.x >= 348 and Rect2(Vector2.ZERO,demo.size).encloses(panel),label+"_native_narrow_panel_stays_in_window")
	check(guide.scale == Vector2.ONE and demo.core_slice_hud.visible and not demo.core_slice_hud.legend_visible,label+"_native_pixels_title_and_no_duplicate_legend")
	planning_layouts.append({"label":label,"stage":guide.stage,"window":str(demo.size),"panel":str(panel),"scroll_height":guide.content_scroll.size.y,"plan":guide.plan_id,"card":guide.card_id,"scope":guide.scope.duplicate()})

func _run() -> void:
	output = "res://验证记录/round213_规划到首作/run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","real_windows_gpu_and_audio")
	check(await until_frame(rate*5),"opening_city_reaches_device")
	check(demo.shown_world.buildings.size() == 24 and not demo.shown_world.public_sites.any(func(site: Dictionary) -> bool: return bool(site.get("active",false))),"true_24_house_opening_without_gifted_public_space")
	await tap(KEY_P)
	await create_timer(0.7).timeout
	var guide = demo.planning_guide
	planning_layout("1440_charter")
	await capture("00_1440_发展方向与真实城市")
	DisplayServer.window_set_size(Vector2i(800,600))
	await create_timer(0.7).timeout
	planning_layout("800_charter")
	check(guide.stage == "charter" and guide.plan_id.is_empty(),"opening_does_not_choose_a_growth_direction")
	var before := demo.model.world.snapshot()
	var first_focus := root.gui_get_focus_owner()
	await tap(KEY_TAB)
	check(root.gui_get_focus_owner() != first_focus and guide.cards.is_ancestor_of(root.gui_get_focus_owner()) and demo.model.synth.listener_community.is_empty(),"real_native_tab_changes_plan_focus_without_city_solo")
	await tap(KEY_SPACE)
	check(guide.stage == "charter" and demo.model.world.snapshot() == before,"space_does_not_accidentally_choose_a_focused_growth_card")
	await capture("01_800_原生三行章程与地图")
	await tap(KEY_ENTER)
	await create_timer(0.3).timeout
	check(guide.stage == "card" and guide.plan_id == "corridor","enter_selects_the_actually_focused_corridor")
	planning_layout("800_card")
	await capture("02_800_真实变化卡与持续句数")
	await tap(KEY_ENTER)
	check(guide.stage == "scope" and guide.scope.is_empty(),"chosen_change_card_reaches_empty_scope")
	var candidate: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": candidate = possible; break
	check(not candidate.is_empty(),"actual_west_community_has_legal_public_land")
	if candidate.is_empty(): quit(1); return
	var raw: Array = candidate["position"]
	var at := Vector2(float(raw[0]),float(raw[1]))
	var scope_at := Vector2.ZERO
	var scope_count := 0
	for building: Dictionary in demo.shown_world.buildings:
		if str(building["community_id"]) == "west-2":
			scope_at += demo.Coupling.position_of(building)
			scope_count += 1
	scope_at /= scope_count
	await click_map(demo.point(scope_at))
	check(guide.scope == ["west-2"],"actual_native_map_click_selects_true_community")
	await press_button(guide.back_button)
	await create_timer(0.2).timeout
	check(guide.stage == "card" and guide.scope == ["west-2"] and demo.model.world.pending_actions.is_empty(),"back_keeps_uncommitted_scope_without_world_writes")
	await press_button(guide.card_choices.get_child(0))
	check(guide.stage == "scope" and guide.scope == ["west-2"],"real_change_card_reselection_keeps_draft_community")
	await tap(KEY_ENTER)
	await create_timer(0.7).timeout
	check(guide.stage == "anchor" and demo.model.world.pending_actions.size() == 1 and demo.model.world.pending_actions[0]["kind"] == "charter","native_scope_enter_queues_one_real_charter")
	for button: Button in guide.actions.get_children():
		if str(button.get_meta("anchor_kind","")) == "civic": await press_button(button); break
	await at_pointer(demo.point(at))
	await create_timer(0.2).timeout
	planning_layout("800_public")
	var bounds := Rect2(demo.point(at)-Vector2(80,85),Vector2(160,145))
	check(Rect2(Vector2.ZERO,demo.size).encloses(bounds) and not guide.get_global_rect().intersects(bounds),"actual_public_target_and_its_facade_have_map_clearance")
	key_event(KEY_SPACE,true)
	check(await playing(),"actual_space_plays_selected_public_comparison")
	check(guide.comparison.has("variants") and demo.preview_player.stream.data == guide.comparison["variants"]["civic"]["pcm"],"actual_civic_comparison_uses_the_same_world_pcm")
	await create_timer(0.7).timeout
	await capture("03_800_文化馆真实范围与公共试听")
	key_event(KEY_SPACE,false)
	await process_frame
	await tap(KEY_ENTER)
	var boundary: int = guide.next_action.get("expected_boundary_frame",-1)
	check(boundary > 0 and demo.pending_composition_choice.get("kind","") == "civic","enter_confirms_the_actual_public_pointer_once")
	check(await until_frame(boundary+rate),"player_public_space_reaches_heard_boundary")
	if not guide.opened: await tap(KEY_P)
	await create_timer(0.3).timeout
	check(guide.next_action.get("state","") == "ready" and demo.shown_world.public_sites.filter(func(site: Dictionary) -> bool: return bool(site.get("active",false))).size() == 1,"actual_public_result_offers_sound_continuation")
	planning_layout("800_feedback")
	await capture("04_800_文化馆落成与声音接续")
	await tap(KEY_ENTER)
	await create_timer(0.7).timeout
	check(demo.menu.visible and demo._expression_context() and not guide.opened,"native_feedback_enter_opens_actual_sound_choice")
	await press_button(demo.expression_choices["warm"])
	check(await playing(),"actual_warm_four_second_audition_after_planning")
	await create_timer(0.7).timeout
	layout("planning_to_voice_800")
	await capture("05_800_规划之后亲自选暖庭")
	await tap(KEY_ENTER)
	boundary = int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(await until_frame(boundary+rate),"confirmed_authored_house_reaches_device")
	var root_id := str(demo._first_authored_state().get("root_id",""))
	check(not root_id.is_empty() and demo.shown_world.by_id.has(root_id) and demo.shown_world.buildings.size() == 25,"complete_native_journey_has_real_public_and_author_house")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await process_frame
	await process_frame
	demo._home_city()
	await create_timer(0.7).timeout
	await capture("06_完整第一段_文化馆与自己的暖庭")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_of_actual_city_reach_device")
	var peak := 0.0
	var clipped := 0
	for sample_frame: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample_frame.x),absf(sample_frame.y)))
		if absf(sample_frame.x) >= 1.0 or absf(sample_frame.y) >= 1.0: clipped += 1
	check(recording.samples.size() == rate*4 and clipped == 0 and demo.clock.underruns == underruns,"actual_city_device_input_has_no_clipping_or_new_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"完整第一段_实际设备输入.wav")
	demo.clock.stop_output()
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"planning":planning_layouts,"voice":layouts,"root_id":root_id,"samples":recording.samples.size(),"sample_rate":rate,"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns},"scope":"Actual Windows/OpenGL/WASAPI. Native P/Tab/Enter/Space/buttons/map complete planning, draft back, real public comparison/commit/heard result, actual warm voice and author. Technical and screenshot review are separate from unverified human usability/aesthetic/listening/fun verdict."},"\t")+"\n")
	print("ROUND213_PLANNING_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
