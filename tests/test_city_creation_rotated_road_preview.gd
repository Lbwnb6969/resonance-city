extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Preview=preload("res://scripts/world/city_creation_chemistry_preview.gd")
const Old=preload("res://tests/fixtures/regression_baselines/road_preview_baseline.gd")
const Frame=preload("res://scripts/world/city_creation_house_frame.gd")
const Arcade=preload("res://scripts/world/city_creation_arcade_plan.gd")
const Shape=preload("res://scripts/world/city_creation_chemistry_shapes.gd")
var failures:Array=[]
var checks:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
static func fixture(yaw:float)->Dictionary:
	var city:=State.new();city.initialize_free();var cells:Array=[]
	for x:int in range(7):
		for level:int in range(2):cells.append({"x":x,"z":0,"level":level,"kind":"room"})
	var result:Dictionary=city.add_house_stroke(Vector2(-22,-10),cells)
	var ok:bool=result.ok and city.set_house_era("h1","pastoral").ok and city.rotate_house("h1",yaw).ok
	var house:Dictionary=city.houses[0];var center:Vector2=Frame.center(house,house.cells[-2])
	var normal:=Frame.direction(house,Vector2.DOWN);var tangent:=Frame.direction(house,Vector2.RIGHT)
	var points:Array[Vector2]=[center+normal*2.05-tangent*2.4,center+normal*2.05+tangent*2.4]
	return {"city":city,"ok":ok,"points":points,"focus":center,"yaw":yaw}
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var rows:Array=[]
	for yaw:float in [0.,PI*.5,PI,-PI*.5,.6]:
		var built:=fixture(yaw);check(built.ok,"public rotated two-storey long house "+str(yaw))
		var city:RefCounted=built.city;var before:Dictionary=city.snapshot();var history:int=city._undo.size()
		var old:Array=Old.road(city,built.points,2.1,"promenade",true).filter(func(r):return r.kind=="arcade")
		var promised:Array=Preview.road(city,built.points,2.1,"promenade",true).filter(func(r):return r.kind=="arcade")
		check(city.snapshot()==before and city._undo.size()==history,"preview never authors transactions "+str(yaw))
		var commit:Dictionary=city.add_road(built.points,"promenade","none",2.1);print("ROAD_COMMIT ",yaw," ",commit);check(commit.ok,"commit the same road "+str(yaw))
		var actual:Array=[]
		for face:Dictionary in Arcade.for_house(city,city.houses[0]):actual.append(Shape.arcade(city.houses[0],face))
		check(not actual.is_empty(),"actual frontage qualifies "+str(yaw))
		check(promised==actual,"preview exactly matches actual transformed frontage "+str(yaw))
		if absf(yaw)>1.:check(old.is_empty() and not actual.is_empty(),"frozen old path reproduces missed transformed end "+str(yaw))
		rows.append({"yaw":yaw,"old":old,"promised":promised,"actual":actual})
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"cases":rows}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROTATED_ROAD_PREVIEW ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}));quit(0 if report.ok else 1)
