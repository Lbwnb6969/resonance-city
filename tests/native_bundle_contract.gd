extends SceneTree
## External probe: current continuous Demo and native DLL from an isolated pack.
var checks: Array[Dictionary] = []
var failed := false
var output := ""

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks.append({"passed":ok,"description":label})
	if not ok:
		failed = true
		push_error("NATIVE_BUNDLE_FAIL "+label)

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--result="): output = argument.trim_prefix("--result=")
	assert(not output.is_empty())
	_check(not root.has_node("MCPRuntimeServer"),"development server stripped")
	_check(ClassDB.class_exists("CityPadMixer"),"native DLL loaded outside source checkout")
	_check(not FileAccess.file_exists("res://tests/round120_native_audio.gd"),"test sources excluded")
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed: PackedScene = load(main_scene)
	var demo: ContinuousValleyDemo = packed.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	demo.clock.stop_output()
	demo.set_process(false)
	_check(demo.model.world.buildings.size() == 18 and demo.sprites.size() == 18,"current continuous main scene builds opening city")
	_check(demo.model.synth.native_mixer != null and demo.model.synth.native_enabled,"opening score uses native mixer")
	_check(ClassDB.class_exists("CityMaskUnion") and demo.shadow_layer.mask_merger != null and demo.shadow_layer.native_batches > 0,"opening shadows use native batch merger")
	var native_audio := ContinuousAudioModel.from_state(demo.model.capture_state())
	var script_audio := ContinuousAudioModel.from_state(demo.model.capture_state())
	script_audio.synth.native_enabled = false
	var audio_frame: int = demo.clock.renderer.transport.rendered_frames
	var audio_rate: int = demo.model.world.cfg["timing"]["sample_rate"]
	_check(native_audio.render_block(demo.clock.renderer.state.duplicate(true),audio_frame,256,audio_rate) == script_audio.render_block(demo.clock.renderer.state.duplicate(true),audio_frame,256,audio_rate),"rebuilt native mixer preserves opening PCM against script")
	native_audio.close_background_settlement()
	script_audio.close_background_settlement()
	var textures_ok := true
	for texture in demo.textures.values(): textures_ok = textures_ok and texture.get_image().has_mipmaps()
	_check(textures_ok,"packed era textures have mipmaps")
	var point := Vector2.ZERO
	var found := false
	for lot in demo.model.world.lots:
		point = Vector2(lot["center"][0],lot["center"][1])
		if demo.model.world.placement(point)["allowed"]:
			found = true
			break
	_check(found,"playable seed location")
	if found:
		_check(demo._hover_placement(point) == demo.model.world.placement(point),"hover matches placement before change")
		var accepted := demo.model.submit({"kind":"seed","position":[point.x,point.y],"midi":48})
		_check(accepted["accepted"],"packed player operation accepted")
		var boundary := demo.model.next_boundary
		demo.model.enable_background_settlement()
		demo.model.prepare_settlement(boundary-22050,22050)
		while not demo.model.settlement_job.completed(): await process_frame
		demo.model.prepare_settlement(boundary-22050,22050)
		demo._sync_buildings()
		await RenderingServer.frame_post_draw
		var old_ground_updates: int = demo.city_ground_layer.update_count
		var old_building_syncs: int = demo.building_sync_count
		demo.clock.renderer.transport.rendered_frames = boundary
		demo.clock.renderer.render(512)
		_check(demo.model.settlement_stats["adopted"] == 1 and demo.model.settlement_stats["fallbacks"] == 0,"packed worker result adopted at original phrase frame")
		var old_shown := demo.model.presentation_world(boundary-1)
		_check(demo.model.presentation_stats["prepared"] == 1 and demo.model.presentation_stats["reconstructed"] == 0 and old_shown.phrase_index == 0,"packed prepared old city used before audible boundary")
		demo.clock.renderer.transport.audible_frame = boundary-1
		demo.shown_world = old_shown
		demo._sync_buildings()
		await RenderingServer.frame_post_draw
		_check(demo.city_ground_layer.update_count == old_ground_updates and demo.building_sync_count == old_building_syncs and demo.city_ground_layer.city == old_shown,"packed old-world view retains geometry while rebinding data")
		var history: Array = demo.model.capture_state()["presentation_history"]
		_check(not history.is_empty() and history.all(func(entry: Dictionary) -> bool: return not entry.has("view") and not entry.has("derived")),"packed runtime view excluded from DNA")
		demo.clock.renderer.transport.audible_frame = boundary+33075
		demo.shown_world = demo.model.presentation_world(boundary+33075)
		demo._sync_buildings()
		_check(not demo._hover_placement(point)["allowed"] and demo._hover_placement(point) == demo.model.world.placement(point),"growth invalidates hover placement")
		_check(demo.shown_world.phrase_index == 1 and demo.sprites.size() == demo.shown_world.buildings.size(),"committed city revealed at audible frame")
	var screen_error := 0.0
	demo.view_zoom = 0.54
	demo.pan = Vector2(100,-150)
	demo._sync_buildings()
	for id in demo.sprites:
		screen_error = maxf(screen_error,demo.sprites[id].global_position.distance_to(demo.point(WorldCoupling.position_of(demo.shown_world.by_id[id]))))
	_check(screen_error < 0.001,"packed camera projection")
	await RenderingServer.frame_post_draw
	var terrain_draws: int = demo.terrain_layer.rebuild_count
	var ground_draws: int = demo.city_ground_layer.rebuild_count
	demo.pan += Vector2(12,-6)
	demo._sync_buildings()
	await RenderingServer.frame_post_draw
	_check(demo.terrain_layer.rebuild_count == terrain_draws and demo.city_ground_layer.rebuild_count == ground_draws,"packed camera pan reuses retained ground commands")
	# Sorting is reused, while alpha and reveal progress are checked per hit.
	var sprite: Sprite2D = demo.sprites.values()[0]
	var id: String = demo.sprites.keys()[0]
	var image: Image = demo.asset_images[demo.shown_world.by_id[id]["type"]]
	var hit := ""
	for y in range(image.get_height()/2,image.get_height(),7):
		for x in range(0,image.get_width(),7):
			if image.get_pixel(x,y).a <= 0.9: continue
			hit = demo._hit(sprite.to_global(sprite.offset+Vector2(x,y)))
			if not hit.is_empty(): break
		if not hit.is_empty(): break
	_check(not hit.is_empty(),"cached depth order preserves alpha hit after camera move")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.get_base_dir()+"/运行包Demo.png")
	demo.queue_free()
	await process_frame
	FileAccess.open(output.get_base_dir()+"/Godot及第三方许可.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"engine_license":Engine.get_license_text(),"third_party_licenses":Engine.get_license_info(),"third_party_copyright":Engine.get_copyright_info()},"\t")+"\n")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"status":"FAIL" if failed else "PASS","engine":Engine.get_version_info()["string"],"checks":checks,"scope":"Current continuous Demo, native pad mixer and simulated audible boundary in isolated GPU pack; Dummy output, no physical listening or long stress"},"\t")+"\n")
	print("NATIVE_BUNDLE_ISOLATED ","FAIL" if failed else "PASS"," checks=",checks.size())
	quit(1 if failed else 0)
