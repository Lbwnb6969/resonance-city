extends "res://tests/round214_community_followup_live.gd"
## One actual window: joined roof comparison, optional partition UI and house hit.

func _run() -> void:
	output = "res://验证记录/round215_古典联合屋顶/live_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_nvidia_opengl_wasapi")
	check(await until_frame(rate*5),"actual_opening_reaches_device")
	var city_before := demo.model.world.snapshot()
	var diagnostics: Dictionary = demo.joined_classical_roofs.diagnostics()
	check(int(diagnostics["patches"]) > 0,"real_starter_has_actual_joint_roof_geometry")
	check(not demo.community_label_layer.visible and not demo.community_workbench.opened,"default_city_has_no_imposed_partition_labels_or_panel")
	var row: Dictionary = diagnostics["rows"][0] if not diagnostics["rows"].is_empty() else {}
	var center := Vector2.ZERO
	for id: String in row.get("ids",[]): center += demo.Coupling.position_of(demo.shown_world.by_id[id])
	if not row.is_empty(): center /= float(row["ids"].size())
	focus(center,3.0)
	await create_timer(0.8).timeout
	demo.set_process(false)
	var frozen_frame := int(demo.clock.renderer.transport.audible_frame)
	var frozen_view := {"pan":str(demo.pan),"zoom":demo.view_zoom,"window":str(demo.size),"frame":frozen_frame,"row":row.duplicate(true)}
	await capture("00_同镜头_真实联合古典屋顶")
	demo.joined_classical_roofs.visible = false
	await capture("01_同镜头_关闭联合层对照")
	demo.joined_classical_roofs.visible = true
	check(demo.model.world.snapshot() == city_before,"joint_roof_comparison_does_not_write_world_or_rng")
	demo.set_process(true)
	await create_timer(0.2).timeout
	var hit_ids: Array[String] = []
	for id: String in row.get("ids",[]):
		var sprite: Node2D = demo.sprites[id]
		var img: Image = demo.building_geometry[id]["image"]
		var target := Vector2.INF
		for y in range(0,img.get_height(),4):
			if target != Vector2.INF: break
			for x in range(0,img.get_width(),4):
				if img.get_pixel(x,y).a < 0.8: continue
				var p := sprite.to_global(sprite.offset+Vector2(x,y))
				if Rect2(Vector2(30,130),demo.size-Vector2(60,220)).has_point(p) and demo._hit(p) == id:
					target = p
					break
		if target != Vector2.INF:
			await click_map(target)
			await process_frame
			if demo.selected_id == id and demo.menu.visible: hit_ids.append(id)
			await tap(KEY_ESCAPE)
	check(hit_ids.size() >= 2,"joined_members_remain_separately_native_clickable")
	DisplayServer.window_set_size(Vector2i(800,600))
	await create_timer(0.4).timeout
	await tap(KEY_C)
	await create_timer(0.7).timeout
	check(demo.community_workbench.opened and demo.community_workbench.title_label.text.ends_with("规划片区"),"c_retains_explicit_optional_legacy_partition_tool")
	check(demo.community_label_layer.visible,"partition_labels_only_appear_in_the_optional_tool")
	await capture("02_800_按需规划片区辅助")
	await tap(KEY_C)
	await process_frame
	check(not demo.community_label_layer.visible and not demo.community_workbench.opened,"closing_optional_tool_restores_an_unlabelled_city")
	await capture("03_800_没有固定社区标签的河湾")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_of_actual_city_audio_reach_wasapi")
	var peak := 0.0
	var clipped := 0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1.0 or absf(sample.y) >= 1.0: clipped += 1
	check(recording.samples.size() == rate*4 and peak > 0.001 and clipped == 0 and demo.clock.underruns == underruns,"visual_change_preserves_real_device_audio_without_clipping_or_new_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"联合屋顶河湾_设备输入.wav")
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"geometry":diagnostics,"comparison_view":frozen_view,"native_hit_members":hit_ids,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns,"scope":"Actual joined roofs and optional legacy partition UI only. Individual IDs/house hits retained; self-defined selection/name/save not implemented. GPU screenshots need separate review. No human aesthetic/audio/fun verdict; PCM is renderer device input, not loopback."},"\t")+"\n")
	print("ROUND215_JOINED_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
