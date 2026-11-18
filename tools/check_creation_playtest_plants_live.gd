extends "res://tools/check_creation_playtest_edit_live.gd"
func plant_instances()->Array[Vector3]:
	var result:Array[Vector3]=[]
	for mesh:MultiMeshInstance3D in demo.town.vegetation_layer.find_children("*","MultiMeshInstance3D",true,false):
		for i in range(mesh.multimesh.instance_count):result.append((mesh.global_transform*mesh.multimesh.get_instance_transform(i)).origin)
	return result
func plant_trace(single:bool)->void:
	var label:="single" if single else "stroke"
	demo.select_tool(5);demo.vegetation_single=single;demo.vegetation_kind="olive" if single else "pink_flower";demo.vegetation_radius=1.4
	var start:=Vector2(-23,34.8) if single else Vector2(-24,33)
	var before:Dictionary=demo.state.snapshot();var history:int=demo.state._undo.size()
	await motion(start);await button(start,true);var events:Array=[];sample_frames.clear();collecting=true;previous_frame=Time.get_ticks_usec()
	for i in range(21):
		events.append(trace(start+Vector2(i*.42,.25*sin(i*.3))))
		await process_frame
	collecting=false
	check(demo.state.revision==before.revision and demo.state._undo.size()==history,"held plant brush does not author or add history "+label)
	var points:Array[Vector2]=demo.vegetation_points.duplicate();var row:={"input":summary(events),"frames":summary(sample_frames),"points":points.size()}
	var began:=Time.get_ticks_usec();await button(start+Vector2(8.4,.25*sin(6.)),false);row.release_ms=(Time.get_ticks_usec()-began)/1000.
	check(demo.state.plants.size()>before.plants.size() and demo.state._undo.size()==history+1,"native plant release authors one exact transaction "+label)
	row.added=demo.state.plants.size()-before.plants.size()
	var immediate:Array=[]
	if "--expect-pending" in OS.get_cmdline_user_args():
		var pending:Node=demo.get_meta("pending_plants");check(pending.rows.size()==row.added and pending.root.is_visible_in_tree(),"all accepted plants visible before background publication "+label)
		row.pending_keep_ms=pending.get_meta("keep_ms",0.)
		for item:Dictionary in pending.rows.values():
			for mesh:MeshInstance3D in item.node.get_children():immediate.append({"mesh":mesh.mesh,"material":mesh.material_override,"pose":mesh.global_transform})
		await capture("plants_"+label+"_immediate")
	began=Time.get_ticks_usec();row.wait=await publication_settle();row.settle_ms=(Time.get_ticks_usec()-began)/1000.;row.budget=demo.edit_budget_report();row.life=demo.life.budget_commit_stats.duplicate(true)
	var saved:Dictionary=demo.state.snapshot()
	var cold:=State.new();check(cold.restore(saved).ok and cold.plants==saved.plants,"plant source cold restores exact positions seeds and sizes "+label)
	var instances:=plant_instances();var all_visible:=true
	for plant:Dictionary in saved.plants:
		if before.plants.any(func(p):return p.id==plant.id):continue
		var at:=Vector2(plant.position[0],plant.position[1]);all_visible=all_visible and instances.any(func(p):return Vector2(p.x,p.z).distance_to(at)<.02)
	check(all_visible,"every new plant has an actual published MultiMesh instance "+label)
	if "--expect-pending" in OS.get_cmdline_user_args():
		var exact:=true
		for item:Dictionary in immediate:
			var found:=false
			for mesh:MultiMeshInstance3D in demo.town.vegetation_layer.find_children("*","MultiMeshInstance3D",true,false):
				if mesh.multimesh.mesh!=item.mesh or mesh.material_override!=item.material:continue
				for i in range(mesh.multimesh.instance_count):
					if (mesh.global_transform*mesh.multimesh.get_instance_transform(i)).is_equal_approx(item.pose):found=true;break
			exact=exact and found
		check(exact and demo.get_meta("pending_plants").rows.is_empty(),"atomic vegetation has identical mesh material and transform and retires pending copies "+label)
	await capture("plants_"+label)
	await key(KEY_Z,true);await settle();check(demo.state.plants==before.plants,"one Undo removes entire planting transaction "+label)
	await key(KEY_Y,true);await settle();check(demo.state.plants==saved.plants,"one Redo restores every exact plant "+label)
	facts[label]=row
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))
	var chosen:={"ok":true,"id":"plant300","title":"Plant Test 300","world":world,"view":{"focus":[-16.,.4,28.],"zoom":32.,"yaw":0.,"pitch":1.,"evening":false,"light_phase":0}}
	await demo.gallery._open_chosen(chosen);await settle();quiet()
	check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"all 300 real houses published")
	await plant_trace(true)
	await plant_trace(false)
	await complete_report(personal)
