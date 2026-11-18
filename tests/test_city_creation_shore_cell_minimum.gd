extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd")
const OldBed=preload("res://tests/fixtures/published_baselines/shore_cell_minimum_20261106/original_bed.gd")
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var city:=State.new();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	assert(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))).ok)
	var anchor:=Vector2(-38,38)
	for road:Dictionary in city.roads:
		for p:Array in road.points:
			if is_equal_approx(float(p[0]),-38.):anchor.y=minf(anchor.y,float(p[1]))
	var added:Dictionary=city.add_road([anchor,Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none");assert(added.ok)
	var original:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions();var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout();var rows:Array=[];var equal:=true
	for id:String in ["r7",str(added.road_id)]:
		var road:Dictionary=city.roads.filter(func(row):return row.id==id)[0];var data:Dictionary=town._prepare_road_data(road)
		var mark:=Time.get_ticks_usec();var before:=OldBed.prepare(town,road,data.arrays);var old_ms:=(Time.get_ticks_usec()-mark)/1000.
		mark=Time.get_ticks_usec();var after:=Bed.prepare(town,road,data.arrays);var new_ms:=(Time.get_ticks_usec()-mark)/1000.
		var matches:bool=before==after;equal=equal and matches;rows.append({"id":id,"faces":before.faces.size(),"pieces":before.pieces.size(),"exact_equal":matches,"old_ms":old_ms,"new_ms":new_ms})
	var report:={"ok":equal and city.snapshot()==original and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"checks":4,"rows":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"boundary":"Same real300-house road arrays; exact full faces/pieces equality; each timing one warm local preparation, not total publication."};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SHORE_CELL_MINIMUM ",JSON.stringify(report));Renderer.BudgetRebuild.new()._dispose_context(town);quit(0 if report.ok else 1)
