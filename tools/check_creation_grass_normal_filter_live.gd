extends "res://tools/check_creation_lighting_comparison_live.gd"
const Garden=preload("res://tools/fixtures/city_creation_space_contract_fixture.gd")
var shader_path:=""
var baseline_path:=""

func buffers()->String:
	var rows:Array=[]
	for node:MultiMeshInstance3D in demo.town.meadow.find_children("*","MultiMeshInstance3D",true,false):rows.append([str(demo.town.meadow.get_path_to(node)),node.multimesh.buffer,node.multimesh.mesh.surface_get_arrays(0)])
	return var_to_bytes(rows).hex_encode().sha256_text()

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--candidate-shader="):shader_path=arg.trim_prefix("--candidate-shader=")
		if arg.begins_with("--baseline-shader="):baseline_path=arg.trim_prefix("--baseline-shader=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:RefCounted=Garden.courtyard("ring","none").city
	check(city.add_road([Vector2(-33,-10),Vector2(-26,-9),Vector2(-17,-10)] as Array[Vector2],"path","none").ok,"public curved path")
	check(city.add_water([Vector2(-33,-17)] as Array[Vector2],2.,"pond").ok,"public pond")
	for at:Vector2 in [Vector2(-20,-8),Vector2(-17,-14),Vector2(-32,-12)]:check(city.place_plant(at,"shrub").ok,"public shrub skirt")
	await show(city,Vector2(-24,-13),"草地法线分辨率对照");quiet();demo.ui_layer.hide();demo.town.clear_preview();demo.town.wildlife.hide();demo.weather_visual.hide()
	for node:GPUParticles3D in demo.find_children("*","GPUParticles3D",true,false):node.hide()
	freeze_wind(0.);demo.process_mode=Node.PROCESS_MODE_DISABLED;Engine.time_scale=0.
	var author:=var_to_bytes(demo.state.snapshot());var original:Shader=demo.town.meadow._material("lawn").shader if baseline_path.is_empty() else load(baseline_path);var candidate:Shader=load(shader_path)
	check(candidate!=null,"candidate shader loaded")
	check(original.code.split("void fragment()")[0]==candidate.code.split("void fragment()")[0] and original.code.split("void light()")[1]==candidate.code.split("void light()")[1],"vertex geometry/wind and direct light equation unchanged")
	var rows:Array=[]
	for subject:String in ["close_day","court_day","far_day","close_night"]:
		var close:=subject.begins_with("close");demo.focus=Vector3(-20,.20,-8) if close else Vector3(-24,.3,-10);demo.yaw=.25;demo.pitch=.38 if close else .8;demo.zoom=5. if close else (36. if subject=="far_day" else 18.);demo._update_camera()
		demo._set_light_phase(2 if subject=="close_night" else 0);var signature:=buffers()
		for stage:String in ["baseline","candidate"]:
			for part:String in ["lawn","grass"]:demo.town.meadow._material(part).shader=original if stage=="baseline" else candidate
			for i in range(24):await process_frame
			await capture(subject+"_"+stage)
		check(buffers()==signature,"actual grass instance buffers/mesh arrays remain identical "+subject)
		rows.append({"subject":subject,"zoom":demo.zoom,"pitch":demo.pitch,"lawn_detail":demo.town.meadow.detail})
	check(var_to_bytes(demo.state.snapshot())==author,"authored city unchanged")
	check(not demo.persistence and personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"isolated test keeps personal save bytes")
	Engine.time_scale=1.
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"views":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"renderer":RenderingServer.get_current_rendering_method(),"persistence":demo.persistence,"scope":"Fragment normal A/B only; no density/geometry changes or temporal/performance claim."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("GRASS_NORMAL_FILTER ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
