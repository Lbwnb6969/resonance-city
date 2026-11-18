extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Plan=preload("res://scripts/world/city_creation_road_connection_feedback.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
static func fixture()->RefCounted:
 var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));return city
static func published(city)->Dictionary:
 var network:=Plan.Network.new();network.state=city;network._build_graph();return Plan.capture(network)
static func request(points:Array[Vector2])->Dictionary:return {"points":points,"width":1.25,"style":"cobble","candidate":{"decoration":"none","connected":{}}}
func worker(city,query:Dictionary)->Array:return Plan.preview(city,query)
func run()->void:
 var out:=""
 for arg:String in OS.get_cmdline_user_args():
  if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
 if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
 var city:=fixture();var points:Array[Vector2]=[Vector2(-25,-14),Vector2(-25,-18.55)];var before:Dictionary=city.snapshot();var history:int=city._undo.size();var query:=request(points)
 var preview:=Plan.preview(city,query);check(preview.size()==1 and preview[0].valid and preview[0].house_id=="h1","real detached road reaches actual ground door")
 check(city.snapshot()==before and city._undo.size()==history and city.roads.is_empty(),"preview leaves complete author snapshot and history untouched")
 var thread:=Thread.new();check(thread.start(worker.bind(Plan.Fork.fork(city),query))==OK,"real background connection preview thread starts");var threaded:Array=thread.wait_to_finish();check(threaded==preview and city.snapshot()==before,"background and independent cold preview identical and pure")
 var baseline:=published(city);check(baseline.is_empty(),"unserved doorway has no published port")
 var result:Dictionary=city.add_road(points,"cobble");check(result.ok,"commit same actual preview road");var after:=published(city);var rows:=Plan.changes(city,baseline,after)
 check(after.has("h1") and rows.size()==1 and rows[0].valid and rows[0].entry==after.h1,"success references actual selected published door")
 check(preview[0].lines==rows[0].lines,"same preview and published doorway outlines")
 check(Plan.changes(city,after,after).is_empty(),"unchanged connected state never repeats")
 city.remove_road(str(result.road_id));var disconnected:=published(city);rows=Plan.changes(city,after,disconnected);check(disconnected.is_empty() and rows.size()==1 and not rows[0].valid,"real road deletion emits disconnection at prior actual doorway")
 for spec:Array in [[Vector2(-24.0,-18.1),false],[Vector2(-25,-18.55),true]]:
  city=fixture();var path:Array[Vector2]=[Vector2(spec[0].x,-14),spec[0]];var r:=Plan.preview(city,request(path));var p:=State.new();p.restore(city.snapshot());var reply:Dictionary=p.add_road(path,"cobble");var actual:=published(p)
  check(reply.ok and r.size()==1 and bool(r[0].valid)==actual.has("h1"),"nearby candidate reports exact production connectivity "+str(spec[0]))
 city=fixture();city.houses[0].base_y=2.;city.revision+=1;preview=Plan.preview(city,query);var high:=State.new();high.restore(city.snapshot());high.add_road(points,"cobble");after=published(high);check(preview.size()==1 and bool(preview[0].valid)==after.has("h1"),"height-sensitive candidate uses production graph instead of planar proximity")
 check(FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal,"personal save bytes untouched")
 var entry:Dictionary=city.house_entrances("h1")[0].duplicate(true);entry.sill_y=3.4;var elevated:=Plan.row(city,"h1",entry,true);check(is_equal_approx(elevated.lines[0][0].y,3.5),"upper-stoop marker uses actual published sill elevation")
 city=fixture();var road:Dictionary=city.add_road(points,"cobble");baseline=published(city);city.rotate_house("h1",PI*.5);city.remove_road(road.road_id);after=published(city);rows=Plan.changes(city,baseline,after)
 check(rows.size()==1 and rows[0].entry.wall_at==city.house_entrances("h1")[0].wall_at,"rotated disconnection follows current actual door instead of stale world position")
 var upper:Dictionary=preload("res://tests/test_city_creation_upper_stoop.gd").fixture(.4,1.8);var upper_ports:=published(upper.city);var upper_row:=Plan.row(upper.city,"h1",upper_ports.h1,true)
 check(upper.ok and upper_ports.h1.upper_stoop and is_equal_approx(upper_row.lines[0][0].y,float(upper_ports.h1.sill_y)+.1),"real rotated second-floor street marker follows production sill elevation")
 var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_CONNECTION_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
