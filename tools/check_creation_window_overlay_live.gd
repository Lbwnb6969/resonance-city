extends "res://tools/check_creation_shape_palette_live.gd"
func pair(label:String,rig:MeshInstance3D)->int:
	rig.show();await RenderingServer.frame_post_draw;var on:=root.get_texture().get_image();on.save_png(OUT+"/"+label+"_on.png")
	rig.hide();await RenderingServer.frame_post_draw;var off:=root.get_texture().get_image();off.save_png(OUT+"/"+label+"_off.png")
	var changed:=0
	for y in range(on.get_height()):
		for x in range(on.get_width()):
			if on.get_pixel(x,y)!=off.get_pixel(x,y):changed+=1
	return changed
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_era("h1","pastoral");city.set_house_style("h1","classic");city.set_house_architecture("h1","portico")
	await show(city,Vector2(-25,-20),"窗灯贴合");await settle();quiet();demo.zoom=9.;demo.yaw=-.65;demo.pitch=.5;demo._update_camera()
	demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);demo.ui_layer.hide();Engine.time_scale=0.
	var authored:Dictionary=demo.state.snapshot();var row:Dictionary=demo.town.resonance.rigs.h1;var rig:MeshInstance3D=row.mesh
	var panes:Array=[]
	for recorded:Dictionary in demo.town.house_roots.h1.get_meta("ancient_window_panes",[]):
		for pane:Dictionary in recorded.windows:panes.append({"at":recorded.frame*Vector3(pane.at),"size":pane.size})
	var lights:Array=rig.get_meta("windows")
	facts.house=demo.state.houses[0];facts.panes=panes.size();facts.lights=lights.size()
	check(panes.size()>0 and panes.size()==lights.size(),"one glow pane per actual ancient shutter")
	check(lights.all(func(w):return panes.any(func(p):return Vector3(p.at).distance_to(w.at)<.0001 and p.size==w.size)),"all glow centers and sizes match actual facade panes")
	var material:ShaderMaterial=row.material;var original:=material.shader;var only_windows:=Shader.new();only_windows.code=original.code.replace("void fragment() {","void fragment() {\n if(part>.5) discard;");material.shader=only_windows
	material.set_shader_parameter("response",1.);material.set_shader_parameter("afterglow",1.);material.set_shader_parameter("pluck_strength",1.);material.set_shader_parameter("pluck_progress",.5)
	for phase in [0,2]:
		demo._set_light_phase(phase);material.set_shader_parameter("night_glow",0. if phase==0 else .35)
		for i in range(60):await process_frame
		var changed:=await pair("day" if phase==0 else "night",rig);facts["pixels_"+str(phase)]=changed
		check(changed==0 if phase==0 else changed>0,"window overlay hidden by day despite active music; visible by night "+str(phase))
	material.shader=original;check(demo.state.snapshot()==authored,"lighting keeps author world unchanged")
	Engine.time_scale=1.;demo.set_process(true);await complete_report(personal)
