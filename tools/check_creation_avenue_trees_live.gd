extends "res://tools/check_creation_wall_shadow_live.gd"
const Trees=preload("res://scripts/visual/city_creation_avenue_trees.gd")
const Old=preload("res://tests/fixtures/regression_baselines/avenue_promenade_baseline.gd")
const Footprints=preload("res://scripts/visual/city_creation_street_furniture_footprints.gd")

func tree_signature()->Array:
	var rows:Array=[]
	for node:MultiMeshInstance3D in demo.town.find_children("Avenue*","MultiMeshInstance3D",true,false):
		var transforms:Array=[]
		for i:int in range(node.multimesh.visible_instance_count):transforms.append(node.multimesh.get_instance_transform(i))
		rows.append([str(node.name),node.multimesh.mesh.surface_get_arrays(0),transforms])
	return rows

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free()
	check(city.add_house(Vector2(-30,-26)).ok and city.set_house_era("h1","renaissance").ok,"real renaissance neighbor")
	check(city.apply_terrain_target(city.plan_terrain_target([Vector2(-20,-8)] as Array[Vector2],6.,.9,true)).ok,"public gentle hillside")
	check(city.add_road([Vector2(-34,-20),Vector2(-10,-20)] as Array[Vector2],"avenue","none").ok,"public straight avenue")
	check(city.add_road([Vector2(-34,-8),Vector2(-25,-9),Vector2(-18,-6),Vector2(-10,-7)] as Array[Vector2],"avenue","none").ok,"public curved hillside avenue")
	await show(city,Vector2(-23,-20),"林荫道枝叶");quiet();demo.ui_layer.hide();demo.weather_visual.hide();demo.town.clear_preview()
	var author:Dictionary=demo.state.snapshot();var footprints:Array=Footprints.plans(demo.state).duplicate(true)
	var old:=Old.new();var baseline:=Node3D.new();demo.add_child(baseline)
	var candidate:Array=demo.town.find_children("Avenue*","MultiMeshInstance3D",true,false)
	var records:Array=[];var timing:Dictionary={}
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	for road:Dictionary in demo.state.roads:
		var before:Array=old.prepare(demo.town,road);var current:Array=demo.town.promenade.prepare(demo.town,road)
		check(before==current,"same exact tree/lamp/bench records and ground heights "+road.id)
		records.append_array(current);var holder:=Node3D.new();baseline.add_child(holder);old.install(demo.town,holder,before)
		var detail:Node=holder.get_node("PromenadeDetails")
		for name:String in ["AvenueCrowns","AvenueTrunks"]:detail.get_node(name).reparent(holder)
		detail.free()
	check(candidate.size()==4,"two cached mesh batches per avenue")
	var meshes:=Trees.parts(demo.town.foliage);var valid:=true;var counts:Dictionary={}
	for part:String in meshes:
		var arrays:Array=meshes[part].surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		for i:int in range(vertices.size()):valid=valid and vertices[i].is_finite() and normals[i].is_finite() and absf(normals[i].length()-1.)<.001 and vertices[i].y<=2.726 and Vector2(vertices[i].x,vertices[i].z).length()<=.621
		counts[part]={"vertices":vertices.size(),"triangles":arrays[Mesh.ARRAY_INDEX].size()/3}
	check(valid,"finite geometry/unit normals stays within former crown envelope")
	check(Trees.parts(demo.town.foliage).canopy==meshes.canopy,"all street trees share cached canopy mesh")
	demo.town.foliage.material("canopy").set_shader_parameter("wind_time_override",0.);demo.town.foliage.material("trunk").set_shader_parameter("wind_time_override",0.)
	demo.set_process(false);demo.life.set_process(false);demo.town.set_process(false)
	for view:Array in [["near",Vector2(-23,-20),10.,.38],["normal",Vector2(-23,-20),24.,.65],["slope",Vector2(-22,-8),24.,.5]]:
		demo.focus=Vector3(view[1].x,.5,view[1].y);demo.zoom=view[2];demo.pitch=view[3];demo.yaw=.25;demo._update_camera()
		for phase:int in ([0,2] if view[0]=="normal" else [0]):
			demo._set_light_phase(phase)
			for stage:String in ["baseline","candidate"]:
				baseline.visible=stage=="baseline"
				for node:Node3D in candidate:node.visible=stage=="candidate"
				for i:int in range(18):await process_frame
				await capture(str(view[0])+"_"+str(phase)+"_"+stage)
				if view[0]=="normal" and phase==0:
					var gpu:Array=[];var draws:Array=[]
					for frame:int in range(36):
						await process_frame;gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()));draws.append(root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
					gpu.sort();draws.sort();timing[stage]={"gpu_median_ms":gpu[18],"draw_calls_median":draws[18],"frames":36}
	baseline.free()
	for node:Node3D in candidate:node.show()
	var hot:=tree_signature();demo.set_process(true);demo.town.set_process(true)
	check(demo.state.snapshot()==author and Footprints.plans(demo.state)==footprints,"visual change preserves author city and exact ground obstacles")
	demo._after_edit(demo.state.remove_road("r2"),"history");await settle();quiet()
	check(demo.town.find_children("Avenue*","MultiMeshInstance3D",true,false).size()==2,"actual road deletion removes its tree batches")
	await key(KEY_Z,true);await settle();quiet();check(tree_signature()==hot,"native Undo restores exact tree transforms and meshes")
	var cold:=State.new();check(demo.state.save_city(OUT+"/avenue.json").ok and cold.load_city(OUT+"/avenue.json").ok,"isolated work disk roundtrip")
	await show(cold,Vector2(-23,-20),"林荫道冷读");quiet();check(tree_signature()==hot,"cold mesh arrays and all tree transforms equal incremental")
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save bytes unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"geometry":counts,"timing":timing,"trees":records.filter(func(r):return r.kind=="tree").size(),"scope":"Street tree visuals; spacing, ground obstacles, authored city and music unchanged."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("AVENUE_TREES ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
