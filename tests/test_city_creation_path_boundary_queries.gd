extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Edge=preload("res://scripts/visual/city_creation_path_edge.gd")
const Before=preload("res://tests/fixtures/published_baselines/large_publish_20261108/before_path_edge.gd")
const Shore=preload("res://tools/fixtures/city_creation_shore_road_fixture.gd")
const Banks=preload("res://tools/fixtures/city_creation_bridge_banks_fixture.gd")
var checks:=0
var failures:Array=[]
var cases:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func compare(city:RefCounted,id:String,label:String)->void:
	var author:Dictionary=city.snapshot();city.prepare_ground_height();city.road_junctions()
	var town:=Renderer.new();town.state=city;town.record_only=true;town._prepare_road_layout()
	var road:Dictionary=city.roads.filter(func(r):return r.id==id)[0];var cuts:Array=city.road_profile(road).stepping_cuts
	var started:=Time.get_ticks_usec();var expected:Dictionary=Before.new().prepare(town,road,cuts);var before_ms:=(Time.get_ticks_usec()-started)/1000.;started=Time.get_ticks_usec()
	var actual:Dictionary=Edge.new().prepare(town,road,cuts);var after_ms:=(Time.get_ticks_usec()-started)/1000.
	check(actual==expected,"exact entire vertex normal UV custom and index arrays "+label)
	check(city.snapshot()==author,"read-only author data and receipts "+label)
	cases.append({"label":label,"stats":actual.stats,"before_ms":before_ms,"after_ms":after_ms})
	Renderer.BudgetRebuild.new()._dispose_context(town)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	for kind:String in ["straight","bend","junction","middle_pond","slope","cross"]:
		var f:=Shore.build(kind,.4);check(f.ok,"actual rotated shoreline "+kind)
		if f.ok:compare(f.city,f.road_id,kind)
	for kind:String in ["slope","bank_bend"]:
		var city:RefCounted=Banks.build(kind);compare(city,str(city.roads[0].id),"bridge_"+kind)
	var loop:=State.new();loop.initialize();loop.houses.clear();loop.roads.clear();loop.plants.clear()
	for points:Array in [[Vector2(-15,-10),Vector2(-8,-10)],[Vector2(-11,-13),Vector2(-11,-7)],[Vector2(-17,3),Vector2(-13,3),Vector2(-13,8),Vector2(-17,8),Vector2(-17,3)],[Vector2(-15,0),Vector2(-15,5)],[Vector2(-12,5),Vector2(-16,5)]]:
		var typed:Array[Vector2]=[];typed.assign(points)
		check(loop.add_road(typed).ok,"public overlapping loop fixture")
	for road:Dictionary in loop.roads:compare(loop,str(road.id),"loop_"+str(road.id))
	var large:=State.new();check(large.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))).ok,"original300 restore")
	compare(large,"r7","original300_r7");compare(large,"r20","original300_r20")
	var low:=INF
	for road:Dictionary in large.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):low=minf(low,float(point[1]))
	check(large.add_road([Vector2(-38,low),Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none").ok,"actual300 remote bridge")
	compare(large,"r7","changed300_r7");compare(large,"r20","changed300_r20")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("PATH_BOUNDARY_QUERIES ",JSON.stringify(result));quit(0 if result.ok else 1)
