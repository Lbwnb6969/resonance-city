extends SceneTree
## External GPU probe for the exported 24-building opening; Dummy output only.
var checks: Array[Dictionary] = []
var failed := false
var output := ""

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks.append({"passed":ok,"description":label})
	if not ok:
		failed = true
		push_error("CORE_SLICE_BUNDLE_FAIL "+label)

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--result="): output = argument.trim_prefix("--result=")
	assert(not output.is_empty())
	_check(not root.has_node("MCPRuntimeServer"),"development server excluded")
	_check(not FileAccess.file_exists("res://tests/native_bundle_contract.gd"),"tests excluded from playable pack")
	_check(ClassDB.class_exists("CityPadMixer") and ClassDB.class_exists("CityMaskUnion"),"external native audio and shadow DLL loaded")
	var packed: PackedScene = load(str(ProjectSettings.get_setting("application/run/main_scene")))
	var demo = packed.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await RenderingServer.frame_post_draw
	_check(demo.first_composition_mode and demo.shown_world.phrase_index == 0,"main scene enters fresh core composition")
	_check(demo.model.world.buildings.size() == 24 and demo.sprites.size() == 24,"opening has 24 rendered buildings")
	var settled_communities: Array = demo.shown_world.communities.values().filter(func(c: Dictionary) -> bool: return not c["members"].is_empty())
	_check(settled_communities.size() == 3 and settled_communities.all(func(c: Dictionary) -> bool: return c["members"].size() == 8),"opening has three eight-building communities")
	_check(demo.shown_world.public_sites.all(func(site: Dictionary) -> bool: return not bool(site.get("active",false))) and demo.shown_world.planning_reservations.is_empty(),"opening has no prebuilt public space or reservation")
	_check(demo.model.synth.native_mixer != null and demo.model.synth.native_enabled,"opening audio uses packaged native mixer")
	_check(demo.textures.values().all(func(texture: Variant) -> bool: return texture is Texture2D and texture.get_width() > 0),"packed opening textures are usable")
	_check(not demo.first_composition_guide.visible and not demo.planning_guide.opened,"first choice waits during audible overture")
	var opening_names = demo.community_label_layer
	_check(opening_names.visible and opening_names.labels.size() == 3,"three community nameplates appear at opening camera")
	var started := Time.get_ticks_msec()
	var rate: int = demo.clock.renderer.transport.sample_rate
	while demo.clock.renderer.transport.audible_frame-demo.first_composition_guide.origin_frame < 5.0*rate and Time.get_ticks_msec()-started < 12000:
		await process_frame
	demo.first_composition_guide.sync()
	var audible_seconds: float = (demo.clock.renderer.transport.audible_frame-demo.first_composition_guide.origin_frame)/float(rate)
	_check(audible_seconds >= 5.0 and demo.first_composition_guide.visible and demo.first_composition_guide.text.contains("塑造第一段"),"five audible seconds expose the first composition entry")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.get_base_dir()+"/运行包首屏.png")
	demo.clock.set_process(false)
	demo.set_process(false)
	demo.first_composition_guide.emit_signal("pressed")
	_check(demo.planning_guide.opened and demo.planning_guide.stage == "charter" and demo.planning_guide.cards.get_child_count() == 3,"first entry opens three development choices")
	_check(demo.planning_guide.flow_hint.text.contains("流程 1/5"),"packed planning retains five-step progress hint")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.get_base_dir()+"/运行包发展方向.png")
	var opening := {"houses":demo.shown_world.buildings.size(),"communities":settled_communities.size(),"registered_community_areas":demo.shown_world.communities.size(),"community_names":opening_names.labels.map(func(label: Dictionary) -> String: return label["name"]),"audible_seconds":audible_seconds,"native_mixer":demo.model.synth.native_enabled,"driver":AudioServer.get_driver_name(),"display":DisplayServer.get_name()}
	demo.queue_free()
	await process_frame
	FileAccess.open(output.get_base_dir()+"/Godot及第三方许可.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"engine_license":Engine.get_license_text(),"third_party_licenses":Engine.get_license_info(),"third_party_copyright":Engine.get_copyright_info()},"\t")+"\n")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"status":"FAIL" if failed else "PASS","engine":Engine.get_version_info()["string"],"checks":checks,"opening":opening,"scope":"Exported 24-building core opening with real GPU and Dummy clock; no physical listening or long stress"},"\t")+"\n")
	print("CORE_SLICE_BUNDLE ","FAIL" if failed else "PASS"," checks=",checks.size())
	quit(1 if failed else 0)
