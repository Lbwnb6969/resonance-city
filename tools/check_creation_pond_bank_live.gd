extends "res://tools/check_creation_wall_shadow_live.gd"
const Terrain=preload("res://scripts/world/city_creation_terrain.gd")

func geometry_signature()->String:
	var rows:Array=[]
	for branch:Node in [demo.town.terrain_surface,demo.town.water_layer]:
		for mesh:MeshInstance3D in branch.find_children("*","MeshInstance3D",true,false):
			for i in range(mesh.mesh.get_surface_count()):rows.append([str(mesh.get_path()),mesh.global_transform,mesh.mesh.surface_get_arrays(i)])
	return var_to_bytes(rows).hex_encode().sha256_text()

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();check(city.add_water([Vector2(-25,-20)] as Array[Vector2],2.,"pond").ok,"public two metre pond")
	await show(city,Vector2(-25,-20),"小池塘岸色诊断");quiet();demo._set_light_phase(0);demo.ui_layer.hide();demo.town.wildlife.hide();demo.weather_visual.hide();demo.town.clear_preview()
	for material:Material in demo.town.foliage._materials.values():
		if material is ShaderMaterial:material.set_shader_parameter("wind_time_override",0.)
	for key:String in ["lawn","grass"]:demo.town.meadow.materials[key].set_shader_parameter("meadow_time_override",0.)
	demo.process_mode=Node.PROCESS_MODE_DISABLED;Engine.time_scale=0.
	var author:=var_to_bytes(demo.state.snapshot());var shape:=geometry_signature();var env:Environment=demo.environment_rig.environment;var intensity:=env.ssao_intensity
	var sections:Array=[];var raised:=false
	for axis:Vector2 in [Vector2.RIGHT,Vector2.DOWN,Vector2(1,1).normalized()]:
		var values:Array=[]
		for i in range(21):
			var at:=Vector2(-25,-20)+axis*float(i)*.1;var height:float=demo.state.ground_height(at);raised=raised or height>Terrain.BASE_HEIGHT+.00001;values.append([i*.1,height,demo.state.water_clearance(at)])
		sections.append({"axis":axis,"samples":values})
	check(not raised,"actual pond ground never rises above surrounding flat base")
	for size:float in [9.,4.]:
		demo.focus=Vector3(-25,-.02,-20);demo.zoom=9.;demo.pitch=.55;demo.yaw=-.65;demo._update_camera();demo.camera.size=size
		for mode:String in ["baseline","zero_ao","no_sand"]:
			env.ssao_intensity=0. if mode=="zero_ao" else intensity
			demo.town.ground_material.set_shader_parameter("bank_sand_enabled",mode!="no_sand");demo.town._water_surface_material().set_shader_parameter("bank_sand_enabled",mode!="no_sand")
			for i in range(18):await process_frame
			await capture(str(int(size))+"_"+mode)
	check(shape==geometry_signature() and author==var_to_bytes(demo.state.snapshot()),"water/terrain GPU geometry and authored city remain identical")
	check(not demo.persistence and personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	Engine.time_scale=1.
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"sections":sections,"water_level":Terrain.WATER_LEVEL,"base_height":Terrain.BASE_HEIGHT,"seconds":(Time.get_ticks_msec()-began)/1000.,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Diagnostic only, SSAO stays enabled. No water/terrain edit or candidate adoption."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("POND_BANK_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
