extends "res://tests/round209_classical_night_live.gd"
## Focused repair check: retained geometry must bind to new actual sprite parents.
func _run() -> void:
	output += "reentry_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_window_and_output")
	demo.daylight_manual_phase = 0.53
	check(await until_frame(rate*6),"opening_reaches_actual_device_reveal")
	check(facade_count() == 24,"first_city_has_24_heard_facade_lights")
	var old_light_ids: Array = demo.facade_lights.values().map(func(light: Sprite2D) -> int: return light.get_instance_id())
	demo._start_world({},Sample.build())
	demo.clock.start_output(demo.model._mix_frame,{},demo.clock.renderer.snapshot())
	await create_timer(1.0).timeout
	var owned := demo.facade_lights.size() == demo.shown_world.buildings.size()
	for id: String in demo.facade_lights:
		owned = owned and demo.facade_lights[id].get_parent() == demo.sprites[id] and demo.facade_lights[id].texture == demo.building_catalog.emission_for(demo.building_geometry[id]["entry"])
	check(owned and facade_count() == 26,"reused_geometry_binds_all_26_current_masks_to_their_new_real_parents")
	check(demo.facade_lights.values().all(func(light: Sprite2D) -> bool: return light.get_instance_id() not in old_light_ids),"new_city_has_no_old_emission_nodes")
	await capture("00_切城后_两岸真实夜景")
	var civic: ValleyProp
	for prop: ValleyProp in demo.scenery.props.values():
		if prop.kind == "civic" and prop.visible: civic = prop; break
	check(civic != null and civic.classical_facade_light.is_visible_in_tree() and civic.classical_facade_light.texture == demo.building_catalog.emission_for(civic.art_entry),"legal_civic_keeps_its_actual_oriented_mask")
	if civic != null: focus(civic.get_meta("world_position"),3.6)
	await create_timer(0.7).timeout
	await capture("01_实际文化馆近景_古典窗洞与油灯")
	var before := demo.model.world.snapshot()
	input_key(KEY_B)
	await process_frame
	await process_frame
	check(facade_count() == 0 and not civic.classical_facade_light.is_visible_in_tree(),"black_mode_hides_new_city_houses_and_civic_together")
	input_key(KEY_B)
	demo.daylight_manual_phase = 0.0
	await process_frame
	await process_frame
	check(facade_count() == 0 and not civic.classical_facade_light.visible,"daylight_extinguishes_new_city_facades_and_civic")
	demo.daylight_manual_phase = 0.53
	await process_frame
	await process_frame
	check(facade_count() == 26 and civic.classical_facade_light.is_visible_in_tree() and demo.model.world.snapshot() == before,"night_returns_to_same_actual_city_without_writing_world")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_of_new_city_reach_device")
	var peak := 0.0
	var clipped := 0
	for sample_frame: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample_frame.x),absf(sample_frame.y)))
		if absf(sample_frame.x) >= 1 or absf(sample_frame.y) >= 1: clipped += 1
	check(recording.samples.size() == rate*4 and clipped == 0 and demo.clock.underruns == underruns,"new_city_device_input_is_complete_with_no_clip_or_added_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"切城夜景_设备输入.wav")
	demo.clock.stop_output()
	var evidence := {"houses":demo.shown_world.buildings.size(),"lit_facades":facade_count(),"civic_id":civic.art_entry["id"],"samples":recording.samples.size(),"sample_rate":rate,"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns}
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Focused actual window repair verification for switching city with retained geometry; human aesthetic/fun/listening judgements remain separate."},"\t")+"\n")
	print("ROUND209_NIGHT_REENTRY ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
