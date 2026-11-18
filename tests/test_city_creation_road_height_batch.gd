extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Heights=preload("res://scripts/visual/city_creation_road_surface_heights.gd")
const Old=preload("res://tests/fixtures/published_baselines/road_geometry_queries_20261106/reference/road_surface_heights.gd")
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
	var edited:Dictionary=city.add_road([anchor,Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none");assert(edited.ok)
	var original:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions();var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout();var rows:Array=[];var exact:=true
	for id:String in ["r7","r20",str(edited.road_id)]:
		var road:Dictionary=city.roads.filter(func(row):return row.id==id)[0];var data:Dictionary=town._prepare_road_data(road);var profile:Dictionary=city.road_profile(road);var samples:Array[Vector2]=town._road_geometry(road).samples
		var a:Array[Vector3]=[];a.assign(data.arrays[Mesh.ARRAY_VERTEX]);var b:Array[Vector3]=a.duplicate()
		for i in range(a.size()):a[i].y=0.;b[i].y=0.
		var spans:Array[Vector2]=town.Bridges.paving_spans(profile);var stone:Array[Vector2]=town.Bridges.paving_spans(profile,true)
		var mark:=Time.get_ticks_usec();var old:=Old.prepare(town,samples,a,road.width,spans,stone);var old_ms:=(Time.get_ticks_usec()-mark)/1000.;town.rebuild_stats={}
		mark=Time.get_ticks_usec();var current:=Heights.prepare(town,samples,b,road.width,spans,stone);var new_ms:=(Time.get_ticks_usec()-mark)/1000.;var same:bool=a==b and old==current;exact=exact and same
		rows.append({"id":id,"vertices":a.size(),"same":same,"before_ms":old_ms,"after_ms":new_ms,"queries":town.rebuild_stats.road_height_queries})
	var report:={"ok":exact and city.snapshot()==original and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"checks":5,"rows":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"boundary":"Same real300 road indexed positions; exact heights/paving/UV, one warm run each. Native unindexed pipeline measured separately."};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_HEIGHT_BATCH ",JSON.stringify(report));town.BudgetRebuild.new()._dispose_context(town);quit(0 if report.ok else 1)
