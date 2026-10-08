extends SceneTree
## External probe: load only packed game dependencies from an empty directory.
var checks: Array[Dictionary] = []
var failed := false
var output := ""
func _initialize() -> void: call_deferred("run_check")
func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"description":label})
	if not ok:
		failed = true
		push_error("DEMO_BUNDLE_FAIL "+label)
func frames() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
func run_check() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--result="): output = arg.trim_prefix("--result=")
	assert(not output.is_empty(),"External absolute result path required")
	check(root.has_node("AudioClock") and not root.has_node("MCPRuntimeServer"),"Packed audio singleton without MCP server")
	check(not FileAccess.file_exists("res://tests/picking_contract.gd") and not FileAccess.file_exists("res://project.godot") and not FileAccess.file_exists("res://资产/许可记录/CityKits/packages.json"),"Source checkout, tests and production assets unavailable")
	for folder in ["Demo城市","风格小景","古典建筑候选"]:
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/"+folder+"/manifest.json"))
		var valid := not manifest.is_empty()
		for entry in manifest.get("entries",[]):
			var texture: Texture2D = load("res://"+str(entry["texture"]))
			valid = valid and texture != null and texture.get_image().has_mipmaps()
		check(valid,"Packed manifest and all imported mipmapped textures: "+folder)
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.set("start_audio_on_ready",false)
	root.add_child(main)
	await frames()
	check(main.model.session.city.size() == 9 and main.city_view.sprites.size() == 9,"Packed main scene builds actual initial city")
	check(main.focus_button.visible and main.map_tool.item_count == 4 and main.diagnosis_button != null,"Latest focus, map tools and diagnosis are present")
	var cell: Array = main.model.session._empty_cells()[0]
	main.release_armed = true
	main._select_empty(Vector2i(cell[0],cell[1]))
	var at: int = main.model.next_boundary
	main.clock.renderer.transport.rendered_frames = at
	var pcm: PackedVector2Array = main.clock.renderer.render(17)
	main.clock.renderer.transport.audible_frame = at+2*main.clock.renderer.transport.beat_frame(1)
	await frames()
	check(pcm.size() == 17 and main.model.session.city.size() > 9 and main.city_view.sprites.size() == main.model.session.city.size(),"Packed release settles and grows visible routed city")
	var before: Dictionary = main.model.session.snapshot()
	check(main.city_view.focus_selected(),"Packed selected building accepts focus")
	await create_timer(float(main.city_view.camera_cfg["smooth_seconds"])+0.05).timeout
	check(main.model.session.snapshot() == before and main.city_view.view_zoom > 1.0,"Packed focus runs without changing city")
	get_root().get_texture().get_image().save_png(output.get_base_dir()+"/运行包Demo.png")
	main.queue_free()
	await process_frame
	var art: Control = load("res://scenes/style_frame.tscn").instantiate()
	root.add_child(art)
	await frames()
	check(art.sprites.size() == 6 and art.capture_prefix == "古典建筑小景","Packed historical SVG scene builds six placements")
	get_root().get_texture().get_image().save_png(output.get_base_dir()+"/运行包古典小景.png")
	art.queue_free()
	await process_frame
	var license_file := FileAccess.open(output.get_base_dir()+"/Godot及第三方许可.json",FileAccess.WRITE)
	license_file.store_string(JSON.stringify({"engine":Engine.get_version_info(),"engine_license":Engine.get_license_text(),"third_party_licenses":Engine.get_license_info(),"third_party_copyright":Engine.get_copyright_info()},"\t")+"\n")
	license_file.close()
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rule_id":"ASSET-001","status":"FAIL" if failed else "PASS","engine":Engine.get_version_info()["string"],"checks":checks,"scope":"Actual portable engine, exported pack and GPU scenes from isolated directory; simulated boundary/Dummy, no physical listening or long stress"},"\t")+"\n")
	file.close()
	print("DEMO_BUNDLE_ISOLATED %s checks=%d" % ["FAIL" if failed else "PASS",checks.size()])
	quit(1 if failed else 0)
