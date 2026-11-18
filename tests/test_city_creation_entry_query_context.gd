extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Net=preload("res://scripts/world/city_creation_network.gd")
const Zones=preload("res://scripts/world/city_creation_functional_zones.gd")
const Lane=preload("res://scripts/world/city_creation_lane_contract.gd")
const Before=preload("res://tests/fixtures/published_baselines/life_spatial_prepare_20261106/original_lane.gd")
const Fixture=preload("res://tools/fixtures/city_creation_slope_entry_fixture.gd")
const Context=preload("res://scripts/visual/city_creation_road_height_context.gd")
var checks:=0
var failures:Array=[]
var cases:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func compare(city:RefCounted,label:String,reverse:bool=false)->void:
	var network:=Net.new();network.state=city;network._build_graph();city.prepare_regional_echo(network)
	var report:Dictionary=city.functional_zones();var snapshot:Dictionary=city.snapshot()
	var water:=func(box):return Zones._water_distance(city,box)
	var started:=Time.get_ticks_usec();var expected:Array;var actual:Array;var before_ms:float;var after_ms:float
	if reverse:
		actual=Lane.derive(city,report,water);after_ms=(Time.get_ticks_usec()-started)/1000.;started=Time.get_ticks_usec()
		expected=Before.derive(city,report,water);before_ms=(Time.get_ticks_usec()-started)/1000.
	else:
		expected=Before.derive(city,report,water);before_ms=(Time.get_ticks_usec()-started)/1000.;started=Time.get_ticks_usec()
		actual=Lane.derive(city,report,water);after_ms=(Time.get_ticks_usec()-started)/1000.
	check(actual==expected,"exact frozen lane entries, rejections, heights and eligibility "+label)
	check(city.snapshot()==snapshot,"author data and receipts unchanged "+label)
	var context:=Context.new(city);var known_same:=true
	for road:Dictionary in city.roads:
		for point:Array in road.points:
			var at:=Vector2(point[0],point[1]);var surface:Dictionary=city._road_heights.surface_at(at)
			known_same=known_same and context.height_at(at,float(surface.get("y",NAN)))==preload("res://scripts/world/city_creation_street_height_query.gd").height(city,at,float(surface.get("y",NAN)))
	check(known_same,"known surface retains original public query precedence "+label)
	cases.append({"label":label,"rows":actual.size(),"before_ms":before_ms,"after_ms":after_ms})
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	for kind:String in ["flat","high","mismatch"]:
		for yaw:float in [0.,.4,PI*.5]:
			var fixture:=Fixture.build(kind,yaw);check(fixture.ok,"real public slope fixture "+kind+str(yaw));compare(fixture.city,kind+str(yaw),yaw==.4)
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))).ok,"original 300-house restore")
	compare(city,"original300")
	var low:=INF
	for road:Dictionary in city.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):low=minf(low,float(point[1]))
	check(is_finite(low) and city.add_road([Vector2(-38,low),Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none").ok,"same actual remote bridge command")
	compare(city,"changed300",true)
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("ENTRY_QUERY_CONTEXT ",JSON.stringify(result));quit(0 if result.ok else 1)
