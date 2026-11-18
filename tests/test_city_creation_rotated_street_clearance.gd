extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Promenade=preload("res://scripts/visual/city_creation_promenade.gd")
const Old=preload("res://tests/fixtures/regression_baselines/rotated_clearance_baseline.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
static func fixture(yaw:float,gap:float=2.4)->Dictionary:
	var city:=State.new();city.initialize_free();var cells:Array=[]
	for x:int in range(7):cells.append({"x":x,"z":0,"level":0,"kind":"room"})
	var ok:bool=city.add_house_stroke(Vector2(-22,-10),cells).ok and city.rotate_house("h1",yaw).ok
	var house:Dictionary=city.houses[0];var a:=Frame.origin(house);var b:Vector2=Frame.center(house,house.cells[-1]);var side:=Frame.direction(house,Vector2.DOWN)
	var road:Dictionary=city.add_road([a+side*gap,b+side*gap] as Array[Vector2],"avenue","none",2.1)
	return {"city":city,"ok":ok and road.ok,"road_result":road,"focus":(a+b)*.5}
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var cases:Array=[];var reproduced:=false
	for yaw:float in [0.,PI*.5,PI,-PI*.5,.6]:
		for gap:float in [2.4,3.5]:
			var built:=fixture(yaw,gap);check(built.ok,"public roadside house "+str(yaw)+"/"+str(gap))
			if not built.ok:continue
			var city:RefCounted=built.city;var before:Dictionary=city.snapshot();var planner:=Promenade.new();var old:=Old.new();var road:Dictionary=city.roads[0]
			var fresh:Array=planner.prepare({"state":city},road);var baseline:Array=old.prepare({"state":city},road)
			var offenders:Array=[];var old_offenders:Array=[]
			for pair:Array in [[fresh,offenders],[baseline,old_offenders]]:
				for row:Dictionary in pair[0]:
					var radius:float=.65 if row.kind=="tree" else .45 if row.kind=="flower" else .20
					for cell:Dictionary in city.houses[0].cells:
						if Frame.distance(Frame.footprint(city.houses[0],cell),row.at)<radius+.1199:
							pair[1].append({"kind":row.kind,"at":row.at,"cell":cell.id});break
			check(offenders.is_empty(),"all street furniture clears actual rotated wall "+str(yaw)+"/"+str(gap))
			if yaw==0.:check(fresh==baseline,"axis aligned records exactly preserved "+str(gap))
			if fresh.size()>baseline.size():reproduced=true
			var restored:=State.new();check(restored.restore(before).ok,"cold authored city")
			check(Promenade.new().prepare({"state":restored},restored.roads[0])==fresh and city.snapshot()==before,"cold records equal incremental and query is read-only")
			cases.append({"yaw":yaw,"gap":gap,"before_count":baseline.size(),"after_count":fresh.size(),"old_offenders":old_offenders,"new_offenders":offenders})
	check(reproduced,"frozen old planner omits valid furniture beside rotated house")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROTATED_STREET_CLEARANCE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}));quit(0 if report.ok else 1)
