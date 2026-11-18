extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Junctions=preload("res://scripts/world/city_creation_junctions.gd")
const Before=preload("res://tests/fixtures/published_baselines/road_input_under_load_20261106/original_junctions.gd")
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))).ok,"original300 restore")
	city.prepare_ground_height();city.road_junctions();var low:=INF
	for road:Dictionary in city.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):low=minf(low,float(point[1]))
	check(city.add_road([Vector2(-38,low),Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none").ok,"actual pending-world road change")
	check(city._junctions._frontage_input!=[city.houses,city.roads],"published baseline is genuinely stale")
	var author:Dictionary=city.Serializer.snapshot(city,false);var source_cache:Dictionary=city._junctions._cache.duplicate(true)
	var old:=Before.new();var current:=Junctions.new();var rows:Array=[]
	for i in range(1,5):
		old.copy_cache_from(city._junctions);current.copy_cache_from(city._junctions)
		var path:Array[Vector2]=[Vector2(-34,35),Vector2(-34+i,35)];var mark:=Time.get_ticks_usec()
		var expected:Array=old.preview_additions(city,path,1.25);var before_ms:=(Time.get_ticks_usec()-mark)/1000.;mark=Time.get_ticks_usec()
		var actual:Array=current.preview_additions(city,path,1.25);var after_ms:=(Time.get_ticks_usec()-mark)/1000.
		check(actual==expected,"exact frozen preview output "+str(i))
		check(current._preview_frontages.size()==city.houses.size(),"current actual baseline contains all300 doors "+str(i))
		rows.append({"i":i,"before_ms":before_ms,"after_ms":after_ms,"parts":actual.size()})
	var original:Array=city.houses[0].origin;city.houses[0].origin=[-34.,35.]
	var path:Array[Vector2]=[Vector2(-34,35),Vector2(-30,35)]
	old.copy_cache_from(city._junctions);current.copy_cache_from(city._junctions)
	check(current.preview_additions(city,path,1.25)==old.preview_additions(city,path,1.25),"same-revision external geometry change invalidates preview baseline")
	check(current._preview_frontage_input==[city.houses,city.roads],"cache retains exact new values rather than revision")
	city.houses[0].origin=original
	check(current.preview_additions(city,path,1.25)==old.preview_additions(city,path,1.25),"restored actual source geometry restores exact output")
	check(city.Serializer.snapshot(city,false)==author and city._junctions._cache==source_cache,"preview never mutates author data or published junction cache")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"rows":rows,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("JUNCTION_PREVIEW_BASELINE ",JSON.stringify(result));quit(0 if result.ok else 1)
