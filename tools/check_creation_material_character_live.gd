extends "res://tools/check_creation_lighting_comparison_live.gd"
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Batch=preload("res://scripts/visual/city_creation_mesh_batcher.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var world_path:=""
func paint_signature()->String:
	var rows:Array=[]
	for node:MeshInstance3D in demo.town.buildings.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null:continue
		for surface in range(node.mesh.get_surface_count()):
			var raw:Dictionary=RenderingServer.mesh_get_surface(node.mesh.get_rid(),surface)
			rows.append(var_to_bytes([raw.get("vertex_data"),raw.get("attribute_data"),raw.get("index_data")]).hex_encode().sha256_text())
	rows.sort();return var_to_bytes(rows).hex_encode().sha256_text()
func palette_roundtrip()->void:
	var before:=paint_signature();var houses:Array=demo.state.houses.duplicate(true);var old_shape:=building_shape();demo.set_process(true)
	var target:=posmod(int(demo.state.houses[3].get("palette",0))+1,4);var result:Dictionary=demo.state.set_house_palette("h4",target);demo._after_edit(result,"room",false);await settle();quiet();demo.life.set_process(false)
	var hot:=paint_signature();var changed:Array=demo.state.houses.duplicate(true)
	check(result.ok and hot!=before and old_shape==building_shape(),"real chalet palette updates native GPU bytes while triangle positions stay exact")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==houses and paint_signature()==before,"native Undo restores original material colour buffers")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses==changed and paint_signature()==hot,"native Redo restores exact painted colour buffers")
	var cold:=State.new();check(demo.state.save_city(OUT+"/painted.json").ok and cold.load_city(OUT+"/painted.json").ok,"painted work saves and cold loads inside isolated evidence")
	await show(cold,Vector2(-16,-12),"木构配方冷读");quiet();check(paint_signature()==hot and demo.state.houses==changed,"independent cold build reproduces every actual native painted GPU buffer")
func building_shape()->Dictionary:
	var rows:Array=[];var triangles:=0
	for house:Node3D in demo.town.house_roots.values():
		for node:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
			if node.mesh==null:continue
			var faces:PackedVector3Array=node.mesh.get_faces()
			for i in range(0,faces.size(),3):
				rows.append(var_to_bytes([node.global_transform*faces[i],node.global_transform*faces[i+1],node.global_transform*faces[i+2]]).hex_encode().sha256_text());triangles+=1
	rows.sort();return {"triangles":triangles,"sha256":var_to_bytes(rows).hex_encode().sha256_text()}
func board()->Node3D:
	var parent:=Node3D.new();parent.name="ValidationMaterialBoard";demo.town.add_child(parent)
	for kind in range(7):
		var source:StandardMaterial3D=Wall.source(Color(["e5dfcd","a9aaa0","ba7754","657d78","e0dacf","94734e","b69a62"][kind]),null,"component",kind)
		var sphere:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=.35;mesh.height=.7;sphere.mesh=mesh;sphere.material_override=source;parent.add_child(sphere)
		var at:=Vector2(-25.5+kind*1.1,9.);sphere.position=Vector3(at.x,demo.state.ground_height(at)+.65,at.y)
		var beam:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.75,.16,.16);beam.mesh=box;beam.material_override=source;parent.add_child(beam);beam.position=sphere.position+Vector3(0,-.5,.05);beam.rotation.z=.30
	Batch.new().merge(parent);return parent
func fixture()->RefCounted:
	var city:=State.new();city.initialize_free()
	for row:Array in [["pastoral","portico",Vector2(-28,-24)],["renaissance","belvedere_villa",Vector2(-16,-24)],["clockwork","iron_conservatory",Vector2(-28,-12)],["modern_eco","chalet",Vector2(-16,-12)],["modern_eco","panorama",Vector2(-28,0)],["modern_eco","twin_gable",Vector2(-16,0)]]:
		check(Brush.select(city,row[0],row[1]),"public era/prototype brush "+row[1]);var cells:Array=[{"x":0,"z":0,"level":0,"kind":"room"},{"x":1,"z":0,"level":0,"kind":"room"},{"x":0,"z":1,"level":0,"kind":"room"},{"x":1,"z":1,"level":0,"kind":"room"}]
		check(city.add_house_stroke(row[2],cells).ok and city.houses[-1].get("architecture","")==row[1],"real prototype house "+row[1])
	return city
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--world="):world_path=arg.trim_prefix("--world=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var city:RefCounted
	if world_path.is_empty():city=fixture();world_path=OUT+"/world.json";FileAccess.open(world_path,FileAccess.WRITE).store_string(JSON.stringify(city.snapshot(),"\t",true,true))
	city=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string(world_path))).ok,"same frozen author fixture restored")
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();await show(city,Vector2(-22,-12),"材质三态对照");quiet();demo.life.set_process(false);demo.set_process(false);demo.town.set_process(false);demo.town.wildlife.hide();demo.ui_layer.hide();demo.weather_visual.hide();demo.town.clear_preview()
	check(demo.state.houses.size()==6 and demo.town.house_roots.size()==6,"all six real houses published")
	var author:=var_to_bytes(demo.state.snapshot());var shape:=building_shape();var samples:=board();var rows:Array=[]
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var biases:=OS.get_cmdline_user_args().has("--bias-candidates")
	var normal_biases:=OS.get_cmdline_user_args().has("--normal-candidates")
	var maps:=OS.get_cmdline_user_args().has("--map-candidates")
	var diagnostic:=OS.get_cmdline_user_args().has("--shadow-diagnostics") or biases or normal_biases or maps
	var subjects:Array=["map2048_16","map2048_32","map4096_32","map4096_32_four"] if maps else ["normal065","normal150","normal300","normal500","reversed"] if normal_biases else ["bias012","bias035","bias070","bias120"] if biases else ["reference","no_shadow","wall_flat"] if diagnostic else ["town","classic","wood","glass","samples"]
	for subject:String in subjects:
		samples.visible=subject=="samples";demo.focus=Vector3(-22,1,-12);demo.zoom=40.;demo.pitch=.7;demo.yaw=.2
		if subject=="classic" or diagnostic:demo.focus=Vector3(-27,1.0,-23);demo.zoom=9.;demo.pitch=.35;demo.yaw=-.6
		elif subject=="wood":demo.focus=Vector3(-15,1.0,-11);demo.zoom=7.;demo.pitch=.30;demo.yaw=.6
		elif subject=="glass":demo.focus=Vector3(-27,1.0,-11);demo.zoom=7.;demo.pitch=.28;demo.yaw=.6
		elif subject=="samples":demo.focus=Vector3(-22.2,.9,9);demo.zoom=8.;demo.pitch=.30;demo.yaw=.1
		demo._update_camera()
		demo.sun.shadow_enabled=subject!="no_shadow"
		if biases:demo.sun.shadow_bias={"bias012":.012,"bias035":.035,"bias070":.070,"bias120":.120}[subject]
		if normal_biases:demo.sun.shadow_normal_bias={"normal065":.65,"normal150":1.5,"normal300":3.,"normal500":5.,"reversed":.65}[subject];demo.sun.shadow_reverse_cull_face=subject=="reversed"
		if maps:
			RenderingServer.directional_shadow_atlas_set_size(4096 if subject.begins_with("map4096") else 2048,subject.ends_with("_16"))
			demo.sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if subject.ends_with("four") else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		if subject=="wall_flat":
			for node:MeshInstance3D in demo.town.buildings.find_children("*","MeshInstance3D",true,false):
				var material:=node.material_override as ShaderMaterial
				if material!=null and material.get_meta("creation_wall_batch",false):material.set_shader_parameter("micro_normal_strength",0.)
		for phase in ([0] if diagnostic and not biases and not normal_biases and not maps else range(3)):
			demo._set_light_phase(phase);freeze_wind(0.)
			for i in range(18):await process_frame
			await capture(subject+"_"+str(phase));var row:={"subject":subject,"phase":phase,"settings":settings()}
			if subject=="town" and phase==0:row.static=await measure(false);freeze_wind(-1.);row.moving=await measure(true)
			rows.append(row)
	check(shape==building_shape(),"lighting and sample board leave actual building triangle positions unchanged")
	check(author==var_to_bytes(demo.state.snapshot()) and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"author and personal save bytes unchanged")
	if OS.get_cmdline_user_args().has("--interaction"):await palette_roundtrip()
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"interaction tests preserve personal save boundary")
	var hashes:Dictionary={}
	for name:String in ["scripts/visual/city_creation_wall_material.gd","scripts/visual/shaders/creation_wall.gdshader","scripts/visual/shaders/creation_joined_roof.gdshader","scripts/visual/city_creation_facade_glass.gd","scripts/visual/city_creation_alpine_modern.gd","scripts/visual/city_creation_alpine_lodge.gd","scripts/visual/city_creation_archway_instruments.gd","scripts/visual/city_creation_modern.gd","scripts/visual/city_creation_environment.gd","project.godot"]:hashes[name]=FileAccess.get_sha256("res://"+name)
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"world_sha256":FileAccess.get_sha256(world_path),"shape":shape,"views":rows,"source_sha256":hashes,"persistence":demo.persistence,"collection_directory":demo.collection_directory,"scope":"six real fixture houses and separate material board; frozen actor updates/foliage screenshots, other shader TIME remains live; only town/day72-frame performance; subjective art quality separate"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("MATERIAL_CHARACTER ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
