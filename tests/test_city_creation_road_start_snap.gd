extends SceneTree
const Plan=preload("res://scripts/world/city_creation_road_endpoint_plan.gd")
const Old=preload("res://tests/fixtures/regression_baselines/road_start_baseline.gd")
const Fixture=preload("res://tests/test_city_creation_rotated_road_preview.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var rows:Array=[]
	for yaw:float in [0.,PI*.5,PI,-PI*.5,.6]:
		var built:=Fixture.fixture(yaw);var city:RefCounted=built.city;var a:Vector2=built.points[0];var b:Vector2=built.points[1];var before:Dictionary=city.snapshot()
		check(built.ok,"public rotated fixture "+str(yaw))
		check(Plan.start(city,a,true,2.1)==a,"first click never guesses door approach "+str(yaw))
		for mode:int in [0,1]:
			var path: Array[Vector2]=Plan.Geometry.straight(a,b)
			var result:=Plan.plan(city,path,b,Vector2.INF,mode,[],true,2.1,"promenade","")
			check(result.valid.ok and result.points[0]==a and result.points[-1]==b,"default wall-parallel road stays legal without Alt "+str(yaw)+"/"+str(mode))
			var old_start:Vector2=Old.start(city,a,true,2.1)
			rows.append({"yaw":yaw,"mode":mode,"raw_start":a,"old_start":old_start,"new_start":result.points[0]})
		var entry:Dictionary=city.house_entrances("h1")[0];var normal:Vector2=Plan.Targets.Frame.normal(entry)
		var door:Vector2=entry.wall_at+normal*Plan.Targets.Frontage.CONTACT
		var raw:Vector2=door+normal*.2;var far:Vector2=door+normal*5.
		for mode:int in [0,1]:
			var path:Array[Vector2]=Plan.Geometry.straight(raw,far)
			var result:=Plan.plan(city,path,far,Vector2.INF,mode,[],true,1.25,"path","")
			check(result.valid.ok and result.points[0].distance_to(door)<.00001,"outward start still joins real door after direction known "+str(yaw)+"/"+str(mode))
			var off:=Plan.plan(city,path,far,Vector2.INF,mode,[],false,1.25,"path","")
			check(off.points==path,"Alt retains exact authored start "+str(yaw)+"/"+str(mode))
		check(city.snapshot()==before,"all endpoint observations leave city unchanged "+str(yaw))
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":rows}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROAD_START_SNAP ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}));quit(0 if report.ok else 1)
