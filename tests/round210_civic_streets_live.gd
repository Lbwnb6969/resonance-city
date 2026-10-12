extends "res://tests/round209_classical_night_live.gd"
## Two civic buildings placed through the actual first-composition UI.
const First = preload("res://scripts/world/first_composition.gd")
const Facing = preload("res://scripts/visual/building_street_orientation.gd")
var civic_evidence: Array[Dictionary] = []

func click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	demo._gui_input(event)

func place_civic(cid: String,plan_index: int) -> int:
	var guide = demo.planning_guide
	guide.cards.get_child(plan_index).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var candidate: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == cid: candidate = possible; break
	check(not candidate.is_empty(),cid+"_has_actual_legal_public_site")
	if candidate.is_empty(): return -1
	var raw: Array = candidate["position"]
	var at := Vector2(float(raw[0]),float(raw[1]))
	click(demo.point(at))
	guide.confirm.emit_signal("pressed")
	for button: Control in guide.actions.get_children():
		if str(button.get_meta("anchor_kind","")) == "civic": button.emit_signal("pressed"); break
	click(demo.point(at))
	await process_frame
	await process_frame
	check(demo.pending_composition_choice.get("kind","") == "civic" and str(demo.pending_composition_choice.get("community_id","")) == cid,cid+"_production_ui_queues_actual_civic")
	return int(guide.next_action.get("expected_boundary_frame",-1))

func civics() -> Array[ValleyProp]:
	var result: Array[ValleyProp] = []
	for prop: ValleyProp in demo.scenery.props.values():
		if prop.kind == "civic" and prop.is_visible_in_tree() and prop.reveal >= 1.0: result.append(prop)
	return result

func inspect_civic(cid: String) -> ValleyProp:
	var selected: ValleyProp
	for prop: ValleyProp in civics():
		var site: Dictionary = demo.scenery.sites[str(prop.get_meta("site"))]
		if str(site["community_id"]) == cid: selected = prop; break
	check(selected != null,cid+"_heard_civic_is_revealed")
	if selected == null: return null
	var site: Dictionary = demo.scenery.sites[str(selected.get_meta("site"))]
	var at: Vector2 = selected.get_meta("world_position")
	var raw: Array = site["entrance"]
	var entrance := Vector2(float(raw[0]),float(raw[1]))
	var orientation := Facing.street_orientation(demo.shown_world,at,entrance)
	var expected := "refined_civic_loggia"+("_o"+str(orientation) if orientation > 0 else "")
	check(str(selected.art_entry["id"]) == expected and selected.art_entry["orientation"] == orientation,cid+"_actual_road_entrance_selects_its_geometric_template")
	check(selected.classical_facade_light.texture == demo.building_catalog.emission_for(selected.art_entry) and selected.classical_facade_light.get_parent() == selected,cid+"_night_mask_matches_actual_oriented_civic")
	check(demo.city_ground_layer.civic_court.courts.has(str(site["id"])) and not demo.city_ground_layer.civic_court.courts[str(site["id"])].is_empty(),cid+"_actual_heard_public_site_owns_its_court")
	civic_evidence.append({"community":cid,"site_id":site["id"],"position":site["position"],"entrance":site["entrance"],"frame":site["frame"],"orientation":orientation,"entry_id":selected.art_entry["id"],"scale":selected.scale.x})
	return selected

func _run() -> void:
	output = "res://验证记录/round210_古典公共建筑/run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_windows_gpu_and_audio")
	check(await until_frame(rate*6),"opening_reaches_device")
	check(demo.shown_world.buildings.size() == 24 and civics().is_empty(),"new_city_keeps_24_houses_and_no_gifted_civic")
	demo.planning_guide.open_tool()
	var boundary: int = await place_civic("west-2",0)
	if boundary < 0: quit(1); return
	check(await until_frame(boundary-rate/10),"first_civic_reaches_render_ahead")
	check(civics().is_empty() and demo.city_ground_layer.civic_court.courts.is_empty(),"render_ahead_does_not_reveal_future_civic_or_court")
	check(await until_frame(boundary+rate),"first_civic_reaches_audible_reveal")
	await process_frame
	var west := inspect_civic("west-2")
	if west != null: focus(west.get_meta("world_position"),3.6)
	await create_timer(0.7).timeout
	demo.planning_guide.hide_tool()
	await capture("00_亲建文化馆_西岸白昼柱廊与真实院地")
	demo.daylight_manual_phase = 0.53
	await process_frame
	await process_frame
	check(west != null and west.classical_facade_light.is_visible_in_tree(),"heard_civic_sparse_window_light_appears_at_night")
	await capture("01_西岸文化馆_实际侧背朝向夜景")
	DisplayServer.window_set_size(Vector2i(800,600))
	await process_frame
	await process_frame
	demo.planning_guide.open_tool()
	demo.planning_guide.next_action_button.emit_signal("pressed")
	demo.expression_choices["warm"].emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+8000
	while not demo.preview_started and Time.get_ticks_msec() < deadline: await process_frame
	check(demo.preview_started and demo.preview_player.playing,"civic_to_actual_warm_four_second_audition")
	var voice: Dictionary = demo.expression_comparison["variants"]["warm"]
	check(demo.preview_player.stream.data == voice["pcm"],"audition_plays_the_actual_context_pcm")
	var preview_wav := AudioStreamWAV.new()
	preview_wav.format = AudioStreamWAV.FORMAT_16_BITS
	preview_wav.mix_rate = rate
	preview_wav.stereo = true
	preview_wav.data = voice["pcm"]
	preview_wav.save_to_wav(output+"文化馆后暖庭_点击试听.wav")
	await create_timer(0.7).timeout
	var target_raw: Array = demo.context["position"]
	var target := demo.point(Vector2(float(target_raw[0]),float(target_raw[1])))
	check(Rect2(Vector2.ZERO,demo.size).encloses(demo.menu.get_global_rect()) and not demo.menu.get_global_rect().intersects(Rect2(target-Vector2(90,100),Vector2(180,170))),"800_voice_ui_keeps_actual_target_clear")
	await capture("02_800x600_公建到声音_真实暖庭试听")
	demo.expression_confirm.emit_signal("pressed")
	boundary = demo.model.next_boundary
	check(await until_frame(boundary+rate),"confirmed_author_house_reaches_device")
	var root_id := str(demo._first_authored_state().get("root_id",""))
	check(not root_id.is_empty() and demo.shown_world.buildings.size() == 25 and demo.shown_world.by_id.has(root_id) and int(demo.shown_world.by_id[root_id]["birth_frame"]) <= demo.clock.renderer.transport.audible_frame and float(demo.sprites[root_id].progress) >= 1.0,"player_civic_and_warm_voice_create_actual_revealed_author_root")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await process_frame
	await process_frame
	demo._home_city()
	await create_timer(0.7).timeout
	demo.first_composition_guide.emit_signal("pressed")
	(demo.menu.get_meta("compose_more") as Button).emit_signal("pressed")
	boundary = await place_civic("east-2",2)
	if boundary < 0: quit(1); return
	check(await until_frame(boundary+rate),"opposite_civic_reaches_audible_reveal")
	await process_frame
	var east := inspect_civic("east-2")
	demo.planning_guide.hide_tool()
	demo.daylight_manual_phase = 0.0
	if east != null: focus(east.get_meta("world_position"),3.6)
	await create_timer(0.7).timeout
	await capture("03_继续下一段_东岸实际朝向白昼")
	var before := demo.model.world.snapshot()
	demo.daylight_manual_phase = 0.53
	await process_frame
	await process_frame
	check(civics().size() == 2 and east != null and east.classical_facade_light.is_visible_in_tree(),"both_actual_civics_keep_their_own_night_masks")
	check(civic_evidence.size() == 2 and civic_evidence[0]["orientation"] != civic_evidence[1]["orientation"],"two_real_street_sites_exercise_distinct_geometric_angles")
	await capture("04_东岸文化馆_柱廊与石院夜景")
	var court_rebuilds: int = demo.city_ground_layer.civic_court.rebuild_count
	demo._home_city()
	await create_timer(0.7).timeout
	await capture("05_两岸公共建筑与作者街坊_全景")
	check(demo.city_ground_layer.civic_court.rebuild_count == court_rebuilds,"camera_pan_and_zoom_reuse_actual_court_geometry")
	check(demo.model.world.snapshot() == before,"day_night_and_camera_review_keep_same_city")
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
	check(recording.samples.size() == rate*4 and clipped == 0 and demo.clock.underruns == underruns,"actual_city_pcm_has_no_clipping_or_added_underrun")
	var city_wav := AudioStreamWAV.new()
	city_wav.format = AudioStreamWAV.FORMAT_16_BITS
	city_wav.mix_rate = rate
	city_wav.stereo = true
	city_wav.data = Renderer.pcm16(recording.samples)
	city_wav.save_to_wav(output+"两岸文化馆与暖庭_设备输入.wav")
	demo.clock.stop_output()
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"civics":civic_evidence,"root_id":root_id,"houses":demo.shown_world.buildings.size(),"sample_rate":rate,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns},"scope":"Actual Windows/OpenGL/WASAPI; two production-UI civic choices, distinct actual road orientations, true warm audition and author root, day/night/camera review. Human aesthetic/fun/listening judgements remain unverified."},"\t")+"\n")
	print("ROUND210_CIVIC_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
