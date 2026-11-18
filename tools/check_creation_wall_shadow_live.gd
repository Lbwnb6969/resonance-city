extends "res://tools/check_creation_shape_palette_live.gd"
var baseline_wall:=""
func geometry()->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
		for i in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.mesh.surface_get_arrays(i),mesh.global_transform]))
	return result
func shot(label:String)->void:
	for i in range(24):await process_frame
	await capture(label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-wall="):baseline_wall=arg.trim_prefix("--baseline-wall=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_style("h1","classic");city.set_house_era("h1","pastoral");city.set_house_architecture("h1","portico")
	await show(city,Vector2(-25,-20),"墙面阴影");await settle();quiet();demo._set_light_phase(0)
	demo.focus=Vector3(-25,.85,-20);demo.zoom=9.;demo.pitch=.5;demo.yaw=-.65;demo._update_camera()
	demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);demo.town.wildlife.hide();demo.ui_layer.hide();demo.weather_visual.hide();Engine.time_scale=0.
	var author:Dictionary=demo.state.snapshot();var shape:=geometry();var env:Environment=demo.environment_rig.environment
	await shot("baseline")
	facts.ssao_enabled=env.ssao_enabled;facts.shadow_distance=demo.sun.directional_shadow_max_distance;facts.camera_distance=demo.camera.position.distance_to(demo.focus)
	if "--diagnostic" in OS.get_cmdline_user_args():
		demo.sun.shadow_enabled=false;await shot("no_shadow");demo.sun.shadow_enabled=true
		env.ssao_enabled=false;await shot("no_ssao");env.ssao_enabled=true
		demo.sun.directional_shadow_max_distance=52.;await shot("near_distance")
		demo.sun.directional_shadow_max_distance=92.
		for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
			var material:=mesh.material_override
			if material is ShaderMaterial and material.get_meta("creation_wall_batch",false):material.set_shader_parameter("micro_normal_strength",0.)
		await shot("flat_normal")
	else:
		var materials:Array=[]
		for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
			var material:=mesh.material_override
			if material is ShaderMaterial and material.get_meta("creation_wall_batch",false) and material not in materials:materials.append(material)
		var shader:Shader=load("res://scripts/visual/shaders/creation_wall.gdshader")
		var old:Shader=shader if baseline_wall.is_empty() else load(baseline_wall)
		for size:float in [9.,4.]:
			demo.camera.size=size
			for phase in [0,1,2]:
				demo._set_light_phase(phase)
				for mat:ShaderMaterial in materials:mat.shader=old
				await shot("before_"+str(int(size))+"_"+str(phase))
				for mat:ShaderMaterial in materials:mat.shader=shader
				await shot("after_"+str(int(size))+"_"+str(phase))
	check(demo.state.snapshot()==author,"lighting diagnosis preserves author city")
	check(geometry()==shape,"wall shading preserves actual GPU construction arrays and transforms")
	Engine.time_scale=1.;demo.set_process(true);facts.seconds=(Time.get_ticks_msec()-began)/1000.;await complete_report(personal)
