extends "res://tools/check_creation_pond_bank_live.gd"
const CANDIDATE_ROOT="res://验证记录/PlayTest/pond_bank_readability_20261109/"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var rows:Array=[]
	for scene_name:String in ["pond","natural"]:
		demo.process_mode=Node.PROCESS_MODE_INHERIT;Engine.time_scale=1.
		var city:=State.new();city.initialize_free()
		if scene_name=="pond":check(city.add_water([Vector2(-25,-20)] as Array[Vector2],2.,"pond").ok,"public two metre pond")
		else:check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/PlayTest/mixed_natural_review_20261107/before_v3/world.json"))).ok,"frozen mixed natural city")
		await show(city,Vector2(-25,-20) if scene_name=="pond" else Vector2(-6,4),"自然岸色候选");quiet();demo.ui_layer.hide();demo.town.wildlife.hide();demo.weather_visual.hide();demo.town.clear_preview()
		for material:Material in demo.town.foliage._materials.values():
			if material is ShaderMaterial:material.set_shader_parameter("wind_time_override",0.)
		for key:String in ["lawn","grass"]:demo.town.meadow.materials[key].set_shader_parameter("meadow_time_override",0.)
		demo.process_mode=Node.PROCESS_MODE_DISABLED;Engine.time_scale=0.
		var author:=var_to_bytes(demo.state.snapshot());var shape:=geometry_signature();var materials:Array=[demo.town.ground_material,demo.town._water_surface_material(),demo.town.meadow._material("lawn"),demo.town.meadow._material("grass")]
		var originals:Array=materials.map(func(material):return material.shader);var candidates:Array=[]
		for file:String in ["creation_ground.gdshader","creation_water.gdshader","creation_lawn.gdshader","creation_lawn.gdshader"]:candidates.append(load(CANDIDATE_ROOT+"candidate_"+file))
		for subject:String in (["normal_day","close_day","normal_night"] if scene_name=="pond" else ["pond_day","river_day"]):
			demo.focus=Vector3(-25,-.02,-20) if scene_name=="pond" else (Vector3(12.2,.2,7.8) if subject=="pond_day" else Vector3(3,.2,4));demo.zoom=9. if scene_name=="pond" else (10. if subject=="pond_day" else 16.);demo.pitch=.55;demo.yaw=-.65;demo._update_camera()
			if subject=="close_day":demo.camera.size=4.
			demo._set_light_phase(2 if subject=="normal_night" else 0)
			for stage:String in ["baseline","candidate"]:
				for i in range(materials.size()):materials[i].shader=originals[i] if stage=="baseline" else candidates[i]
				for i in range(18):await process_frame
				await capture(scene_name+"_"+subject+"_"+stage)
			rows.append({"scene":scene_name,"subject":subject,"camera_size":demo.camera.size})
		for i in range(materials.size()):materials[i].shader=originals[i]
		check(shape==geometry_signature() and author==var_to_bytes(demo.state.snapshot()),"water/terrain GPU and authored city unchanged "+scene_name)
	check(not demo.persistence and personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save byte-identical")
	Engine.time_scale=1.
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"views":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"renderer":RenderingServer.get_current_rendering_method(),"persistence":demo.persistence,"scope":"Shared shore sand mask only; unchanged metric terrain, water, state, sun and SSAO."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("POND_BANK_COMPARE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
