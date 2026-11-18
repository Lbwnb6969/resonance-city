extends "res://tools/check_creation_shape_palette_live.gd"
var light:Node3D
func face_house(yaw:float)->void:
	demo.yaw=yaw;demo.pitch=.1;demo.focus=Vector3(-25+sin(yaw)*6.,1.3,-20+cos(yaw)*6.);demo._update_camera()
	light.refresh();await process_frame
func strength()->float:return float(light.material.get_shader_parameter("strength"))
func paired_frame(label:String)->int:
	var on_strength:=strength();Engine.time_scale=0.;demo.ui_layer.hide()
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw;var on:Image=root.get_texture().get_image();on.save_png(OUT+"/"+label+"_on.png")
	light.material.set_shader_parameter("strength",0.)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw;var off:Image=root.get_texture().get_image();off.save_png(OUT+"/"+label+"_off.png")
	var changed:=0
	for y in range(on.get_height()):
		for x in range(on.get_width()):
			var a:=on.get_pixel(x,y);var b:=off.get_pixel(x,y)
			if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>1.01/255.:changed+=1
	Engine.time_scale=1.;light.material.set_shader_parameter("strength",on_strength);demo.ui_layer.show();return changed
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();check(city.add_house(Vector2(-25,-20)).ok and city.set_house_architecture("h1","portico").ok,"public colonnade for real dusk scene")
	await show(city,Vector2(-25,-20),"暮光镜头");await settle();quiet();demo._set_light_phase(1)
	for i in range(60):await process_frame
	light=demo.get_meta("waterfront_light");light.set_process(false);demo.town.set_process(false);demo.life.set_process(false)
	var author:Dictionary=demo.state.snapshot();var history:int=demo.state._undo.size()
	await key(KEY_V);demo.set_process(false)
	check(DisplayServer.get_name()!="headless" and demo.camera_rig.strolling and demo.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"native V enters actual perspective stroll")
	var sun:Vector3=demo.sun.global_basis.z;var back_yaw:=atan2(-sun.x,-sun.z)
	await face_house(back_yaw);var back:=strength();var shown:int=light.veils.filter(func(n):return n.visible).size()
	check(light.targets.size()>0 and shown>0,"real colonnade veil is visible from street")
	facts.back_changed_pixels=await paired_frame("backlight");check(facts.back_changed_pixels>0,"native GPU dusk veil changes visible pixels")
	await face_house(back_yaw+PI);var front:=strength();facts.front_changed_pixels=await paired_frame("frontlight")
	check(back>.8 and front<.3 and back-front>.5,"street view distinguishes backlit and frontlit atmosphere")
	facts.back_strength=back;facts.front_strength=front
	await key(KEY_V);demo.pitch=.3;demo._update_camera();light.refresh()
	var old_direction:Vector3=(demo.camera.global_position-demo.focus).normalized()
	var expected:float=(1.-smoothstep(.24,.35,demo.pitch))*(.25+.75*smoothstep(-.20,.75,-old_direction.dot(sun)))
	check(is_equal_approx(strength(),expected),"overview preserves existing directional strength")
	demo.pitch=.8;demo._update_camera();light.refresh();check(strength()==0. and light.veils.all(func(n):return not n.visible),"high overview keeps dusk cards hidden")
	demo._set_light_phase(0);demo.pitch=.3;demo._update_camera();light.refresh();check(strength()==0. and light.veils.all(func(n):return not n.visible),"day keeps atmospheric cards hidden")
	check(demo.state.snapshot()==author and demo.state._undo.size()==history,"view and lighting never write author world or history")
	facts.seconds=(Time.get_ticks_msec()-began)/1000.;demo.set_process(true);await complete_report(personal)
