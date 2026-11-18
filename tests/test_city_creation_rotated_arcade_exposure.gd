extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Plan=preload("res://scripts/world/city_creation_arcade_plan.gd")
static func old_blocked(city:RefCounted)->bool:
	var h:Dictionary=city.houses[0];var other:Dictionary=city.houses[1];var normal:=Plan.Frame.direction(h,Vector2.RIGHT);var tangent:=Vector2(normal.y,-normal.x)
	var wall:=Plan.Frame.center(h,h.cells[0])+normal*.9;var half:=tangent.abs()*.88+normal.abs()*.025
	var face:=Rect2(wall+normal*.02-half,half*2.)
	var box:=Rect2(Plan.Frame.center(other,other.cells[0])-Vector2.ONE*.9,Vector2.ONE*1.8).grow(-.002)
	return box.intersects(face)
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
static func fixture(yaw:float,distance:float)->Dictionary:
	var city:=State.new();city.initialize_free();var cells:Array=[]
	for level:int in range(2):cells.append({"x":0,"z":0,"level":level,"kind":"room"})
	var origin:=Vector2(-25,-20);var at:=origin+Vector2(distance,0).rotated(-yaw)
	var a:Dictionary=city.add_house_stroke(origin,cells);var b:Dictionary=city.set_house_era("h1","renaissance");var c:Dictionary=city.rotate_house("h1",yaw)
	var d:Dictionary=city.add_house_stroke(at,cells);var e:Dictionary=city.rotate_house("h2",yaw) if d.ok else {"ok":false}
	return {"city":city,"ok":a.ok and b.ok and c.ok and d.ok and e.ok,"focus":(origin+at)*.5}
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var cases:Array=[]
	for yaw:float in [0.,.3,.6,PI*.25,PI*.5]:
		var built:=fixture(yaw,2.6);check(built.ok,"public non-overlapping pair "+str(yaw))
		if not built.ok:continue
		var city:RefCounted=built.city;var before:Dictionary=city.snapshot();var old:bool=old_blocked(city);var current:Array=Plan.for_house(city,city.houses[0])
		check(current.size()==4,"all four unobstructed sides remain exposed "+str(yaw))
		check(city.snapshot()==before,"query does not mutate city")
		var cold:=State.new();check(cold.restore(before).ok and Plan.for_house(cold,cold.houses[0])==current,"cold result identical")
		cases.append({"yaw":yaw,"old_blocked":old,"after":current.size()})
	check(cases.any(func(row):return row.old_blocked and row.after==4),"old implementation demonstrably drops exposed wall")
	var joined:=State.new();joined.initialize_free();var cells:Array=[]
	for x:int in range(2):
		for level:int in range(2):cells.append({"x":x,"z":0,"level":level,"kind":"room"})
	check(joined.add_house_stroke(Vector2(-25,-20),cells).ok and joined.set_house_era("h1","renaissance").ok and joined.rotate_house("h1",.6).ok,"public rotated joined rooms")
	check(Plan.for_house(joined,joined.houses[0]).size()==6,"shared walls remain blocked and six exterior sides survive")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":cases};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROTATED_ARCADE_EXPOSURE ",JSON.stringify(report));quit(0 if report.ok else 1)
