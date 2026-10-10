extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var base := 71
	var synchronous := "--sync" in OS.get_cmdline_user_args()
	var reference := "--baseline-shadow" in OS.get_cmdline_user_args()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--base="): base = int(argument.trim_prefix("--base="))
	var world := World.new("2026100900000062")
	world.build_expanded_town()
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	for index in range(1,base+1):
		world.settle(index*phrase)
		if index%12 == 0: print("LARGE_SUPPLY_PREP phrase=",index," buildings=",world.buildings.size()," profile=",JSON.stringify(world.settle_profile))
	var demo: Control = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	# Benchmark receives no player input; another game can keep running.
	root.set_disable_input(true)
	demo.clock.stop_output()
	demo.model = Model.new(world,demo.fixed_gain)
	if reference:
		var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第125轮阴影扩展前/city_shadow_layer.gd.txt")
		var old_update := "func update_records"+source.get_slice("func update_records",1).get_slice("func _merge",0)
		var script := GDScript.new()
		script.source_code = "extends \"res://scripts/visual/city_shadow_layer.gd\"\n"+old_update
		assert(script.reload() == OK)
		var old_layer: CityShadowLayer = demo.shadow_layer
		var layer_index := old_layer.get_index()
		demo.remove_child(old_layer)
		old_layer.queue_free()
		demo.shadow_layer = script.new()
		demo.shadow_layer.name = "GroundShadows"
		demo.add_child(demo.shadow_layer)
		demo.move_child(demo.shadow_layer,layer_index)
		demo.shadow_layer.mask_images = old_layer.mask_images.duplicate()
	demo.shown_world = world
	demo.last_birth_count = world.buildings.size()
	demo.last_checkpoint_phrase = base
	demo.scenery.rebuild(demo)
	demo.clock.renderer.transport.rendered_frames = base*phrase
	demo.clock.renderer.transport.audible_frame = float(base*phrase)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	await RenderingServer.frame_post_draw
	var opening_count := world.buildings.size()
	var opening_era := world.era
	var start_frame := base*phrase
	demo.clock.start_output(demo.model._mix_frame,{},{"transport":{"sample_rate":int(world.cfg["timing"]["sample_rate"]),"rendered_frames":start_frame,"audible_frame":float(start_frame),"pending":[],"accepted_events":[],"approved_proposals":{}},"state":{}})
	if synchronous: demo.model.close_background_settlement()
	await create_timer(2.0).timeout
	var steady_skips: int = demo.clock.underruns
	var steady_profile: Dictionary = demo.frame_profile.duplicate()
	var steady_fps := Engine.get_frames_per_second()
	print("LARGE_SUPPLY_STEADY skips=",steady_skips)
	var boundary: int = demo.model.next_boundary
	var frame_times: Array[float] = []
	var cpu_times: Array[float] = []
	var previous := Time.get_ticks_usec()
	while demo.clock.renderer.transport.audible_frame < boundary+4410:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_times.append(float(now-previous)/1000.0)
		cpu_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		previous = now
	await RenderingServer.frame_post_draw
	frame_times.sort()
	cpu_times.sort()
	var checks := {"target_scale":opening_count >= 400,"grows":world.buildings.size() > opening_count,"audible_reveal":demo.shown_world.phrase_index == base+1,"no_underruns":demo.clock.underruns == 0,"voice_budget":int(demo.model.synth.max_voice_count) <= 70}
	if base == 47: checks["modern_era"] = opening_era == 4 and demo.shown_world.era == 5
	var max_projection_error := 0.0
	for id in demo.sprites:
		max_projection_error = maxf(max_projection_error,demo.sprites[id].global_position.distance_to(demo.point(WorldCoupling.position_of(demo.shown_world.by_id[id]))))
	for prop in demo.scenery.props.values():
		max_projection_error = maxf(max_projection_error,prop.global_position.distance_to(demo.point(prop.get_meta("world_position"))))
	checks["camera_projection"] = max_projection_error < 0.001
	checks["native_audio"] = demo.model.synth.native_mixer != null and demo.model.synth.native_enabled
	if not synchronous: checks["background_adoption"] = demo.model.settlement_stats["adopted"] > 0 and demo.model.settlement_stats["fallbacks"] == 0
	var retained := {"terrain_rebuilds":demo.terrain_layer.rebuild_count,"city_rebuilds":demo.city_ground_layer.rebuild_count,"terrain_max_ms":demo.terrain_layer.max_draw_ms,"city_max_ms":demo.city_ground_layer.max_draw_ms,"water_frames":demo.water_flow.draws}
	var evidence := {"baseline_shadow":reference,"retained_shadow_resizes":demo.shadow_layer.retained_resize_count,"static_shadow_merges":demo.shadow_layer.static_merge_count,"retained_ground":retained,"synchronous":synchronous,"background":demo.model.settlement_stats.duplicate(),"concurrent_load":"User reports another game may be running; no other apps stopped","logical_processors":OS.get_processor_count(),"frame_samples":frame_times.size(),"frame_p50_ms":frame_times[frame_times.size()/2],"frame_p95_ms":frame_times[int(frame_times.size()*0.95)],"frame_max_ms":frame_times[-1],"cpu_p50_ms":cpu_times[cpu_times.size()/2],"cpu_p95_ms":cpu_times[int(cpu_times.size()*0.95)],"cpu_max_ms":cpu_times[-1],"supply_block":demo.clock.largest_block,"max_projection_error":max_projection_error,"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"before":opening_count,"after":world.buildings.size(),"era":world.era,"skips":demo.clock.underruns,"steady_skips":steady_skips,"steady_frame_ms":steady_profile,"steady_fps":steady_fps,"max_settle_ms":demo.model.max_settle_ms,"max_render_ms":demo.model.max_render_ms,"max_voices":demo.model.synth.max_voice_count,"profile":world.settle_profile,"fabric_profile":world.fabric_profile,"frame_peaks_ms":demo.frame_peaks,"frame_last_ms":demo.frame_profile,"shadow_rebuild_ms":float(demo.shadow_layer.rebuild_usec)/1000.0}
	var path := "res://验证记录/连续河谷/第125轮_大城供音_%d_%s" % [base,"旧阴影" if reference else "保留阴影"]
	FileAccess.open(path+".json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path+".png")
	print("LARGE_SUPPLY_LIVE ",JSON.stringify(evidence))
	demo.queue_free()
	await process_frame
	quit(0 if evidence["passed"] else 1)
