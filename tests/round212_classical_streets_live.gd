extends "res://tests/round211_sound_stage_live.gd"
## One actual road-surface review, same-city A/B and one heard author birth.
var street_evidence: Dictionary = {}

func _run() -> void:
	output = "res://验证记录/round212_古典石街/run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
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
	check(await until_frame(rate*6),"real_opening_reaches_device")
	check(demo.shown_world.buildings.size() == 24,"true_24_house_city_without_decorative_fixture")
	var surface = demo.city_ground_layer.classical_street_surface
	var frontages = demo.city_ground_layer.classical_frontage_ground
	check(not surface.material["paving"].is_empty() and not surface.material["stones"].is_empty() and not surface.material["curbs"].is_empty(),"actual_occupied_roads_have_stone_faces_and_low_curbs")
	check(not frontages.pads.is_empty(),"actual_heard_houses_have_clipped_threshold_material")
	street_evidence["opening_surface"] = surface.material["diagnostics"].duplicate(true)
	street_evidence["opening_pads"] = frontages.pads.size()
	var at := demo.Coupling.position_of(demo.shown_world.buildings[8])
	focus(at,2.8)
	demo.daylight_manual_phase = 0.0
	await create_timer(0.7).timeout
	var before := demo.model.world.snapshot()
	var road_part = demo.city_ground_layer.urban_parts["roads"]
	var lot_part = demo.city_ground_layer.urban_parts["lots"]
	demo.set_process(false)
	road_part.refined_streets_visible = false
	lot_part.refined_frontages_visible = false
	road_part.queue_redraw()
	lot_part.queue_redraw()
	await capture("00_同城同镜头_原石街线稿")
	road_part.refined_streets_visible = true
	lot_part.refined_frontages_visible = true
	road_part.queue_redraw()
	lot_part.queue_redraw()
	await capture("01_同城同镜头_暖石错缝与低路沿")
	check(demo.model.world.snapshot() == before,"same_camera_material_comparison_keeps_world")
	demo.set_process(true)
	var surface_rebuilds: int = surface.rebuild_count
	var frontage_rebuilds: int = frontages.rebuild_count
	demo._home_city()
	await create_timer(0.7).timeout
	await capture("02_实际开局_连续石街与古典街坊")
	check(surface.rebuild_count == surface_rebuilds and frontages.rebuild_count == frontage_rebuilds,"pan_and_zoom_reuse_world_surface_and_threshold_geometry")
	DisplayServer.window_set_size(Vector2i(800,600))
	await process_frame
	await process_frame
	check(demo._begin_first_sound_choice("west-2"),"actual_sound_entry_remains_playable")
	# Native hit coordinates need the newly opened Container's real layout.
	await create_timer(0.7).timeout
	await press_button(demo.expression_choices["warm"])
	check(await playing(),"actual_warm_four_second_pcm_starts")
	await create_timer(0.7).timeout
	layout("stone_street_800")
	check(demo.preview_player.stream.data == demo.expression_comparison["variants"]["warm"]["pcm"],"road_material_does_not_replace_selected_pcm")
	await capture("03_800_石街上的真实暖庭试听")
	await tap(KEY_ENTER)
	var boundary := int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(boundary > 0,"actual_seed_is_queued_at_its_real_boundary")
	check(await until_frame(boundary-rate/10),"render_ahead_before_heard_birth")
	check(surface.rebuild_count == surface_rebuilds and frontages.rebuild_count == frontage_rebuilds,"future_house_cannot_pave_or_add_threshold_before_heard_frame")
	check(await until_frame(boundary+rate),"chosen_author_house_reaches_device")
	var root_id := str(demo._first_authored_state().get("root_id",""))
	check(not root_id.is_empty() and demo.shown_world.by_id.has(root_id) and surface.rebuild_count > surface_rebuilds,"actual_heard_house_refreshes_its_true_street_source")
	check(frontages.rebuild_count > frontage_rebuilds,"actual_revealed_house_refreshes_threshold_cache")
	street_evidence["heard_surface"] = surface.material["diagnostics"].duplicate(true)
	street_evidence["heard_pads"] = frontages.pads.size()
	street_evidence["surface_build_ms"] = surface.last_build_ms
	DisplayServer.window_set_size(Vector2i(1440,900))
	await process_frame
	await process_frame
	if not root_id.is_empty(): focus(demo.Coupling.position_of(demo.shown_world.by_id[root_id]),2.8)
	await create_timer(0.7).timeout
	await capture("04_真实暖庭落成_门前石阈与坡街")
	before = demo.model.world.snapshot()
	surface_rebuilds = surface.rebuild_count
	frontage_rebuilds = frontages.rebuild_count
	demo.daylight_manual_phase = 0.53
	await process_frame
	await process_frame
	await capture("05_同街夜色_稀疏门洞光与石路")
	check(demo.model.world.snapshot() == before and surface.rebuild_count == surface_rebuilds and frontages.rebuild_count == frontage_rebuilds,"day_night_keeps_same_world_and_geometry")
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
	check(recording.samples.size() == rate*4 and clipped == 0 and demo.clock.underruns == underruns,"actual_pcm_has_no_clipping_or_added_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"古典石街_实际设备输入.wav")
	demo.clock.stop_output()
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"streets":street_evidence,"layouts":layouts,"root_id":root_id,"sample_rate":rate,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns},"scope":"Actual Windows/OpenGL/WASAPI; same-city same-camera legacy/refined street comparison, true 24-house opening, actual warm input/confirm/heard birth, future surface gate, camera/day-night caches, small-window clearance. Human aesthetic/listening/fun verdict unverified."},"\t")+"\n")
	print("ROUND212_STREET_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
