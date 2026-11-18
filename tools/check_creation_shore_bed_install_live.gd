extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd")
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var city:=State.new();var restored:Dictionary=city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json")))
	assert(restored.ok);var anchor:=Vector2(-38,38)
	for road:Dictionary in city.roads:
		for p:Array in road.points:
			if is_equal_approx(float(p[0]),-38.):anchor.y=minf(anchor.y,float(p[1]))
	var edited:Dictionary=city.add_road([anchor,Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none");assert(edited.ok)
	city.prepare_ground_height();city.road_junctions();var town:=Renderer.new();town.state=city;town.record_only=true;root.add_child(town);town._prepare_road_layout()
	var road:Dictionary=city.roads.filter(func(row):return row.id==edited.road_id)[0];var prepared:Dictionary=town._prepare_road_data(road);var data:Dictionary=prepared.earthworks.shore_bed
	var target:=Node3D.new();town.add_child(target);town.record_only=false;var phases:Dictionary={};var mark:=Time.get_ticks_usec()
	var mesh:MeshInstance3D=town._triangles(target,data.faces,Color("b9b49b"));phases.triangles_ms=(Time.get_ticks_usec()-mark)/1000.;mark=Time.get_ticks_usec()
	var bounds:=mesh.mesh.get_aabb();var material:=Bed.Walls.source(Color("b9b49b"),null,"component",Bed.Walls.Kind.STONE)
	mesh.material_override=Bed.Walls.merged(material,bounds.position.y,bounds.size.y,Bed.Walls.WallShader,Vector2(bounds.position.y,bounds.end.y));mesh.material_override.set_shader_parameter("albedo_color",Color("b9b49b"));phases.material_ms=(Time.get_ticks_usec()-mark)/1000.;mark=Time.get_ticks_usec()
	var shape:=mesh.mesh.create_trimesh_shape();phases.collision_ms=(Time.get_ticks_usec()-mark)/1000.
	var report:={"ok":personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"faces":data.faces.size(),"vertices":mesh.mesh.surface_get_array_len(0),"indices":mesh.mesh.surface_get_array_index_len(0),"phases":phases,"seconds":(Time.get_ticks_msec()-began)/1000.,"boundary":"Real original300-house derived road bed; only component creation, not full Scene installation or publication."};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SHORE_INSTALL_PROFILE ",JSON.stringify(report));Renderer.BudgetRebuild.new()._dispose_context(town);await process_frame;quit(0 if report.ok else 1)
