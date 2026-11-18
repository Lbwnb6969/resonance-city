extends SceneTree
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Fixture=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(Fixture.State.DEFAULT_PATH)
	var fixture:=Fixture.build("bend",.4);check(fixture.ok,"actual shore fixture");var town:=Renderer.new();root.add_child(town);town.setup(fixture.city,true);town.request_budget_rebuild()
	var partial:Node3D;var deadline:=Time.get_ticks_msec()+30000
	while partial==null and Time.get_ticks_msec()<deadline:
		town.poll_budget_rebuild(.01,false)
		var stage:Node3D=town.budget_rebuild.staging
		if stage!=null:
			for node:Node3D in stage.road_roots.values():
				if int(node.get_meta("road_install_phase",0)) in range(7,12):partial=node;break
		await process_frame
	check(partial!=null,"real worker result reaches incomplete shore collision installation")
	if partial==null:town.queue_free();quit(1);return
	var bodies:=partial.find_children("*","StaticBody3D",true,false);check(not partial.is_visible_in_tree() and not bodies.is_empty(),"partial stage contains actual hidden collider")
	check(bodies.all(func(body):return body.collision_layer==0 and body.has_meta("pending_collision_layer")),"partial ground never participates in active picking")
	var phase:int=partial.get_meta("road_install_phase");town.cancel_budget_rebuild()
	check(not is_instance_valid(partial) and town.budget_rebuild.staging==null and town.road_roots.is_empty(),"cancel frees partial root without publication")
	var other:=Fixture.State.new();other.initialize_free();check(other.add_road([Vector2(-32,-16),Vector2(-24,-16)] as Array[Vector2],"path","none").ok,"new city reuses road id with different geometry")
	town.state=other;town.request_budget_rebuild();deadline=Time.get_ticks_msec()+30000;var ready:=false
	while not ready and Time.get_ticks_msec()<deadline:
		ready=not town.poll_budget_rebuild(3.5,true).pending;await process_frame
	check(ready and town.state==other and town.road_roots.keys()==["r1"],"only latest city road publishes after cancellation")
	var mesh:MeshInstance3D=town.road_roots.r1.get_node("PathSurface");check(mesh.mesh.get_aabb().end.x< -20.,"same-id stale shore geometry cannot overwrite replacement")
	check(personal==FileAccess.get_file_as_bytes(Fixture.State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cancelled_phase":phase,"hidden_bodies":bodies.size(),"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_PARTIAL_CANCEL ",JSON.stringify(report));town.queue_free();await process_frame;quit(0 if report.ok else 1)
