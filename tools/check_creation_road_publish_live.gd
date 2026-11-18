extends "res://tools/check_creation_policy_scale_live.gd"
## One actual 300-house road publication; no unrelated economics or song wait.
func mesh_signatures()->Dictionary:
	var result:Dictionary={}
	for id:String in demo.town.road_roots:
		var meshes:Array=[]
		for child:Node in demo.town.road_roots[id].find_children("*","MeshInstance3D",true,false):
			var surfaces:Array=[]
			if child.mesh is ArrayMesh:
				for index in range(child.mesh.get_surface_count()):surfaces.append(hash(child.mesh.surface_get_arrays(index)))
			meshes.append({"kind":child.get_class(),"transform":child.transform,"surfaces":surfaces})
		result[id]=hash(meshes)
	return result
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var began:=Time.get_ticks_usec()
	var path:="res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json";var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	var loaded:=await open_scale(data,"300屋道路发布");check(demo.state.houses.size()==300 and demo.town.house_roots.size()==300,"original 300-house city actually publishes");demo.life.set_process(false)
	var before:Dictionary=demo.state.snapshot();var old_meshes:=mesh_signatures();frame_samples.clear();last_frame_usec=Time.get_ticks_usec();sampling=true
	var record:=Span.start();var at:=Time.get_ticks_usec();var result:Dictionary=demo.state.add_road(remote_bridge_points(),"promenade","none");var author_ms:=(Time.get_ticks_usec()-at)/1000.
	var publication:=await command(result,"road","actual remote connected bridge road")
	publication.install_stages=demo.town.rebuild_stats.get("road_install_stages",{}).duplicate(true)
	var road:Dictionary=demo.state.roads.filter(func(row):return row.id==result.road_id)[0]
	check(road.bridge and not demo.state.road_profile(road).bridge_runs.is_empty(),"new stone span has actual bridge profile")
	var current_meshes:=mesh_signatures();var network:RefCounted=demo.life._network
	check(not network._route(network.connected_houses.h1,network._key(Vector2(16,-38.5))).is_empty(),"real home route reaches remote endpoint")
	var undo:Dictionary={};var redo:Dictionary={}
	if OS.get_cmdline_user_args().has("--verify-undo"):
		undo=await command(demo.state.undo(),"history","public Undo road");undo.mesh_signatures=mesh_signatures();check(undo.mesh_signatures==old_meshes,"Undo restores original exact road mesh signatures")
		redo=await command(demo.state.redo(),"history","public Redo road");redo.mesh_signatures=mesh_signatures();check(redo.mesh_signatures==current_meshes,"Redo restores exact published road meshes")
	sampling=false;var frames:=distribution(frame_samples);var pcm:=Span.finish(record,OUT+"/road_Master.wav");check(pcm.ok,"actual continuous Master PCM unclipped")
	check(demo.state.houses==before.houses and demo.state.waters==before.waters and demo.state.terrain_strokes==before.terrain_strokes,"road operation preserves houses water and terrain author data")
	check(pool()==voices and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"player pool and personal save unchanged")
	demo.focus=Vector3(-20,0,-25);demo.zoom=75.;demo._update_camera();await capture("road_publication")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"source":path,"source_sha256":FileAccess.get_sha256(path),"seconds":(Time.get_ticks_usec()-began)/1000000.,"load":loaded,"road_command_ms":author_ms,"road_publish":publication,"undo":undo,"redo":redo,"frames":frames,"mesh_signatures":current_meshes,"pcm":pcm,"works":demo.collection_directory,"boundary":"Frame sampling excludes PCM analysis and image export; cold opening measured separately. No fixed frame threshold or subjective audio claim."};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_PUBLICATION ",JSON.stringify({"ok":report.ok,"checks":checks,"seconds":report.seconds,"publish_ms":publication.publish_wall_ms,"frames":frames}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
