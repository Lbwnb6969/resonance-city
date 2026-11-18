extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://tests/fixtures/published_baselines/road_geometry_queries_20261106/profile_renderer.gd")
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var city:=State.new();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	assert(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))).ok);var anchor:=Vector2(-38,38)
	for road:Dictionary in city.roads:
		for p:Array in road.points:
			if is_equal_approx(float(p[0]),-38.):anchor.y=minf(anchor.y,float(p[1]))
	var added:Dictionary=city.add_road([anchor,Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none");assert(added.ok)
	var author:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions();var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout();var rows:Dictionary={}
	for id:String in ["r7","r20",str(added.road_id)]:
		var road:Dictionary=city.roads.filter(func(row):return row.id==id)[0];town._prepare_road_data(road);rows[id]=town.get_meta("profile_"+id)
	var report:={"ok":city.snapshot()==author and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"rows":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"boundary":"Diagnostic subclass instruments the actual current function; street query microtimers add overhead. No publication or GPU measurement."};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_GEOMETRY_PROFILE ",JSON.stringify(report));town.BudgetRebuild.new()._dispose_context(town);quit(0 if report.ok else 1)
