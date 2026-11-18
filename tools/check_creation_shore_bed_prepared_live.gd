extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd")
const OldBed=preload("res://tests/fixtures/published_baselines/road_install_stages_20261106/reference/shore_road_bed.gd")
const Triangles=preload("res://scripts/visual/city_creation_road_triangle_data.gd")
const Fixture=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func ray(town:Node3D,data:Dictionary)->Dictionary:
	var piece:Dictionary=data.pieces[0];var at:=Vector3.ZERO
	for p:Vector3 in piece.top:at+=p/float(piece.top.size())
	var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP,Vector3(at.x,piece.bottom-1.,at.z),2)
	return town.get_world_3d().direct_space_state.intersect_ray(query)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var rows:Array=[]
	for kind:String in ["bend","junction","slope","cross"]:
		var fixture:=Fixture.build(kind,.4);check(fixture.ok,"real rotated shore geometry "+kind);var city:RefCounted=fixture.city;var original:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions()
		var town:=Renderer.new();town.state=city;town.record_only=true;root.add_child(town);town._prepare_road_layout();var road:Dictionary=city.roads.filter(func(row):return row.id==fixture.road_id)[0];var data:Dictionary=town._prepare_road_data(road).earthworks.shore_bed
		var job:=Thread.new();job.start(func():return Triangles.prepare(data.faces))
		while job.is_alive():await process_frame
		var prepared:Dictionary=job.wait_to_finish();check(not prepared.arrays.is_empty(),"actual worker prepares indexed arrays only")
		var old_root:=Node3D.new();town.add_child(old_root);town.record_only=false;var mark:=Time.get_ticks_usec();OldBed.install(town,old_root,data,road);var old_ms:=(Time.get_ticks_usec()-mark)/1000.
		var old_mesh:MeshInstance3D=old_root.get_node("ShoreRoadBed");var old_shape:ConcavePolygonShape3D=old_root.get_node("ShoreRoadBedGroundPick").get_child(0).shape
		await physics_frame;await process_frame;var old_hit:=ray(town,data);check(not old_hit.is_empty() and old_hit.collider.get_meta("road_id")==road.id,"original bed supplies actual ground ray pick")
		old_root.get_node("ShoreRoadBedGroundPick").collision_layer=0;await physics_frame;await process_frame
		var new_root:=Node3D.new();town.add_child(new_root);mark=Time.get_ticks_usec();var current:MeshInstance3D=Bed.mesh_for(new_root,data,road,prepared);Bed.collide(new_root,road,prepared);var new_ms:=(Time.get_ticks_usec()-mark)/1000.
		var shape:ConcavePolygonShape3D=new_root.get_node("ShoreRoadBedGroundPick").get_child(0).shape
		check(current.mesh.surface_get_arrays(0)==old_mesh.mesh.surface_get_arrays(0),"exact original mesh positions normals and indices "+kind)
		check(shape.get_faces()==old_shape.get_faces() and shape.backface_collision==old_shape.backface_collision and shape.margin==old_shape.margin,"exact original collision faces and shape policy "+kind)
		await physics_frame;await process_frame;var hit:=ray(town,data)
		check(not hit.is_empty() and hit.collider.get_meta("ground",false) and hit.collider.get_meta("road_id")==road.id and hit.position.is_equal_approx(old_hit.get("position",Vector3.INF)),"prepared bed restores same real ground pick "+kind)
		var first:=-1
		for i in range(mini(shape.get_faces().size(),old_shape.get_faces().size())):
			if shape.get_faces()[i]!=old_shape.get_faces()[i]:first=i;break
		var debug:={"old_count":old_shape.get_faces().size(),"new_count":shape.get_faces().size(),"first":first,"old_face":old_shape.get_faces()[first] if first>=0 else Vector3.ZERO,"new_face":shape.get_faces()[first] if first>=0 else Vector3.ZERO,"old_margin":old_shape.margin,"new_margin":shape.margin,"old_backface":old_shape.backface_collision,"new_backface":shape.backface_collision,"old_hit":old_hit.get("position",Vector3.INF),"new_hit":hit.get("position",Vector3.INF)}
		check(city.snapshot()==original,"worker and installation preserve author data");rows.append({"kind":kind,"faces":data.faces.size(),"old_install_ms":old_ms,"new_install_ms":new_ms,"debug":debug});Renderer.BudgetRebuild.new()._dispose_context(town);await process_frame
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal default save bytes unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"rows":rows};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SHORE_PREPARED_LIVE ",JSON.stringify(report));quit(0 if report.ok else 1)
