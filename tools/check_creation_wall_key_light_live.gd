extends "res://tools/check_creation_shape_palette_live.gd"

func geometry()->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
		for i in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.mesh.surface_get_arrays(i),mesh.global_transform]))
	return result

func shot(label:String)->void:
	for i in range(20):await process_frame
	await capture(label)

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_style("h1","classic");city.set_house_era("h1","pastoral");city.set_house_architecture("h1","portico")
	await show(city,Vector2(-25,-20),"墙面定向主光");await settle();quiet();demo.focus=Vector3(-25,.85,-20);demo.zoom=4.;demo.pitch=.5;demo.yaw=-.65;demo._update_camera();demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false);demo.town.wildlife.hide();demo.ui_layer.hide();demo.weather_visual.hide();Engine.time_scale=0.
	var author:Dictionary=demo.state.snapshot();var shape:=geometry();var rotations:=[]
	for phase:int in [0,1,2]:
		demo._set_light_phase(phase);await settle();rotations.append(demo.sun.rotation_degrees);check(is_equal_approx(demo.sun.rotation_degrees.y,[-25.,-32.,25.][phase]),"phase uses calibrated key-light azimuth "+str(phase));await shot("wall_key_phase_"+str(phase))
	check(demo.state.snapshot()==author,"key-light change leaves authored city unchanged")
	check(geometry()==shape,"key-light change preserves GPU construction arrays and transforms")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	Engine.time_scale=1.;var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":{"rotations":rotations,"camera_size":4.0,"shadow_distance":demo.sun.directional_shadow_max_distance},"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("WALL_KEY_LIGHT_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
