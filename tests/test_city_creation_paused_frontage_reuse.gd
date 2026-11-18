extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Life=preload("res://scripts/world/city_creation_life.gd")
const History=preload("res://scripts/world/city_creation_paused_counter_history.gd")
const Before=preload("res://tests/fixtures/published_baselines/paused_geometry_queries_20261106/original_history.gd")
const Frontages=preload("res://scripts/visual/city_creation_prepared_frontages.gd")
const Snapshot=preload("res://scripts/world/city_creation_paused_counter_snapshot.gd")
var checks:=0
var failures:Array=[]
var cases:Array=[]
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
	var city:=State.new();check(city.restore(JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"))).ok,"original paused300 restore")
	var life:=Life.new();root.add_child(life);life.set_process(false);life.setup(city)
	var low:=INF
	for road:Dictionary in city.roads:
		for point:Array in road.points:
			if is_equal_approx(float(point[0]),-38.):low=minf(low,float(point[1]))
	check(city.add_road([Vector2(-38,low),Vector2(-38,-38.5),Vector2(16,-38.5)] as Array[Vector2],"promenade","none").ok,"actual remote bridge command")
	var sources:=History.capture(city);check(sources.size()==1,"real retained off-period source")
	var source:Dictionary=sources[0];var fresh:RefCounted=Snapshot.restore(source.world);Frontages.prepare(fresh)
	var seed:=Frontages.capture(fresh);var seed_before:=seed.duplicate(true);var author:Dictionary=city.snapshot();var world:Dictionary=source.world.duplicate(true);var region:Dictionary=source.region.duplicate(true)
	var started:=Time.get_ticks_usec();var expected:=Before.derive(source);var before_ms:=(Time.get_ticks_usec()-started)/1000.;started=Time.get_ticks_usec()
	var actual:=History.derive(source,seed);var after_ms:=(Time.get_ticks_usec()-started)/1000.
	check(actual==expected,"complete original paused counters equal with prepared doors")
	check(seed==seed_before and source.world==world and source.region==region and city.snapshot()==author,"door seed retained input and author data unchanged")
	check(source.region_revision!=source.world.revision,"pending source keeps original unjoined road graph")
	check(History.derive(source,source.frontage_seed)==expected,"stale previous road doors recompute exact original counters")
	var empty:=State.new();empty.initialize_free();Frontages.prepare(empty)
	check(History.derive(source,Frontages.capture(empty))==expected,"unrelated city seed cannot bypass original signature")
	check(History.derive(source)==expected,"flush default preserves original source seed path")
	# A later edit changes actual doors while the old source must remain exact.
	check(city.remove_house("h1").ok,"real later house removal")
	var changed:RefCounted=Snapshot.restore(city.Serializer.snapshot(city,false));Frontages.prepare(changed)
	check(History.derive(source,Frontages.capture(changed))==expected,"later changed house seed cannot overwrite older off-period geometry")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	cases.append({"source_revision":source.world.revision,"region_revision":source.region_revision,"counters":expected.size(),"before_ms":before_ms,"after_ms":after_ms})
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("PAUSED_FRONTAGE_REUSE ",JSON.stringify(result));life.free();quit(0 if result.ok else 1)
