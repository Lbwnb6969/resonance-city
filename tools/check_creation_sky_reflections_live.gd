extends "res://tools/check_creation_shape_palette_live.gd"
func construction()->Array:
	var result:Array=[]
	for house:Node3D in demo.town.house_roots.values():
		for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
			for s in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.global_transform,mesh.mesh.surface_get_arrays(s)]))
	return result
func gpu_sample()->float:
	var values:Array=[]
	for i in range(24):
		await process_frame;await RenderingServer.frame_post_draw
		values.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
	values.sort();return values[values.size()/2]
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free()
	var subjects:Array=[["pastoral","portico",Vector2(-28,-24)],["clockwork","iron_conservatory",Vector2(-20,-24)],["modern_eco","chalet",Vector2(-28,-15)]]
	for row:Array in subjects:
		check(Brush.select(city,row[0],row[1]) and city.add_house_stroke(row[2],[{"x":0,"z":0,"level":0,"kind":"room"},{"x":1,"z":0,"level":0,"kind":"room"},{"x":0,"z":1,"level":0,"kind":"room"},{"x":1,"z":1,"level":0,"kind":"room"}]).ok,"public actual representative "+row[1])
	await show(city,Vector2(-24,-20),"天空反射");await settle();quiet()
	demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);demo.town.wildlife.hide();demo.ui_layer.hide();demo.weather_visual.hide();Engine.time_scale=0.
	var author:Dictionary=demo.state.snapshot();var geometry:=construction();var env:Environment=demo.environment_rig.environment
	facts.default_reflections=env.reflected_light_source;facts.background=env.background_mode
	var production:= "--production" in OS.get_cmdline_user_args()
	if production:check(env.reflected_light_source==Environment.REFLECTION_SOURCE_SKY and env.background_mode==Environment.BG_COLOR,"production setup uses sky reflections and preserves painted background")
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for row:Array in subjects:
		if production and row[1]!="iron_conservatory":continue
		demo.focus=Vector3(row[2].x+.9,1.,row[2].y+.9);demo.zoom=10.;demo.pitch=.45;demo.yaw=-.65;demo._update_camera()
		for phase in range(3):
			demo._set_light_phase(phase)
			if production:check(env.reflected_light_source==Environment.REFLECTION_SOURCE_SKY,"actual phase switch retains production reflection source "+str(phase))
			for mode in [Environment.REFLECTION_SOURCE_SKY] if production else [Environment.REFLECTION_SOURCE_BG,Environment.REFLECTION_SOURCE_SKY]:
				env.reflected_light_source=mode
				for i in range(48):await process_frame
				await capture(str(row[1])+"_"+str(phase)+"_"+str(mode))
				if row[1]=="iron_conservatory" and phase==0:facts["gpu_median_"+str(mode)]=await gpu_sample()
	check(construction()==geometry and demo.state.snapshot()==author,"reflection source preserves actual construction GPU arrays/transforms and author world")
	facts.seconds=(Time.get_ticks_msec()-began)/1000.;Engine.time_scale=1.;demo.set_process(true);await complete_report(personal)
