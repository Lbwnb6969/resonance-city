extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Fork=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Prepared=preload("res://scripts/visual/city_creation_prepared_frontages.gd")
var reference_roads
var reference_city
var checks:=0
var failures:Array=[]
var cases:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func compare(source:RefCounted,label:String)->void:
 var snapshot:Dictionary=source.snapshot();var fast:=Fork.fork(source);var full=reference_city.new();check(full.restore(snapshot).ok,"reference restore "+label);full._road_heights=reference_roads.new();full._ground_revision=-1;full.prepare_ground_height()
 Prepared.prepare(fast);fast._prepare_raw_height();fast._road_heights.prepare(fast)
 check(fast._road_heights.profiles==full._road_heights.profiles,"every sample/tread/bridge/stepping profile equals previous full solver "+label)
 check(fast._road_heights._bins==full._road_heights._bins and fast._road_heights._query_bins==full._road_heights._query_bins and fast._road_heights._constant_bins==full._road_heights._constant_bins,"coarse and fine query candidates retain original exact order "+label)
 var frontage_ok:=true
 for house:Dictionary in fast.houses:
  var id:=str(house.id);frontage_ok=frontage_ok and fast.house_entrances(id)==full.house_entrances(id) and fast._frontage_cache[id].passages==full._frontage_cache[id].passages
 check(frontage_ok,"all prepared entrances and passages equal unfiltered live inputs "+label)
 var points:Array[Vector2]=[Vector2(-39,-39),Vector2(-25,-20),Vector2.ZERO]
 for profile:Dictionary in full._road_heights.profiles.values():
  for i:int in [0,profile.samples.size()/2,profile.samples.size()-1]:
   var at:Vector2=profile.samples[i].xz;points.append_array([at,at+Vector2(float(profile.width)*.5-.000001,.000001),at+Vector2(float(profile.width)*.5+.000001,-.000001)])
 var exact:=true;var max_error:=0.
 for at:Vector2 in points:
  var a:float=fast.street_height(at);var b:float=full.street_height(at);max_error=maxf(max_error,absf(a-b));exact=exact and a==b
 check(exact,"road boundaries and off-road street heights exactly equal previous query "+label)
 check(source.snapshot()==snapshot,"private preparation leaves source author data unchanged "+label)
 cases.append({"label":label,"houses":source.houses.size(),"roads":source.roads.size(),"queries":points.size(),"max_height_error":max_error,"road_stats":fast._road_heights.stats.duplicate(true)})
func run()->void:
 var out:=""
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
  if arg.begins_with("--reference-roads="):reference_roads=load(arg.trim_prefix("--reference-roads="))
  if arg.begins_with("--reference-city="):reference_city=load(arg.trim_prefix("--reference-city="))
 if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out) or reference_roads==null or reference_city==null:quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var began:=Time.get_ticks_usec()
 for path:String in ["数据/高地河湾样例.json","数据/汀步河湾样例.json","验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"]:
  var source:=State.new();check(source.restore(JSON.parse_string(FileAccess.get_file_as_string("res://"+path))).ok,"actual authored fixture "+path);source.prepare_ground_height();compare(source,path)
  if source.houses.size()==300:
   var points:Array[Vector2]=[Vector2(-25,32),Vector2(-23,33),Vector2(-20,32.5),Vector2(-17,33)]
   check(source.add_road(points,"path","none",1.25).ok,"actual new curved road in 300-house town");compare(source,"300 newly added road")
   check(source.undo().ok,"native road Undo");compare(source,"300 road Undo")
 var upper:Dictionary=preload("res://tests/test_city_creation_upper_stoop.gd").fixture(.4,1.8);check(upper.ok,"actual rotated upper-stoop fixture");compare(upper.city,"rotated upper-stoop")
 check(cases.size()==6,"all six full comparisons completed without script skips")
 check(FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal,"personal save bytes unchanged")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_PREPARE_EQUIVALENCE ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
