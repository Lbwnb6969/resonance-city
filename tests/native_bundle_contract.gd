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
	_check(demo.model.world.buildings.size() == 18 and demo.sprites.size() == 18,"current continuous main scene builds opening city")
	_check(demo.model.synth.native_mixer != null and demo.model.synth.native_enabled,"opening score uses native mixer")
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
		demo.clock.renderer.transport.rendered_frames = boundary
		demo.clock.renderer.render(512)
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
