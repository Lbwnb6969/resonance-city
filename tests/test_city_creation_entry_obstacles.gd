extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
const Corridor=preload("res://scripts/world/city_creation_entry_corridor.gd")
const Prepared=preload("res://scripts/world/city_creation_entry_obstacles.gd")
const Frame=Corridor.Frame
var checks:=0
var failures:Array=[]
var out:=""
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func compare(city:RefCounted,target:Vector2,extra:Array=[])->void:
	var entry:Dictionary=city.house_entrances("h1")[0]
	var rows:Array=Corridor.Obstacles.collect(city);rows.append_array(extra)
	var before:Dictionary=city.snapshot();var original:Array=rows.duplicate(true)
	var prepared:=Prepared.create(rows)
	var flat:=func(_at:Vector2)->Dictionary:return {"y":0.,"kind":"ground"}
	var full:=Corridor.assess(city,city.houses[0],entry,target,city.roads[0],flat,rows)
	var local:=Corridor.assess(city,city.houses[0],entry,target,city.roads[0],flat,prepared)
	check(local==full,"full blocker identity, sample count and diagnostics agree")
	check(rows==original and city.snapshot()==before,"preparation and query preserve inputs")
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec()
	for yaw:float in [0.,.4,-.65,PI*.5]:
		var city:=State.new();city.initialize_free();Brush.select(city,"pastoral","townhouse")
		var origin:=Vector2(-25,-20)
		check(city.add_house(origin).ok and city.rotate_house("h1",yaw).ok,"real rotated author geometry")
		var points:Array[Vector2]=[]
		for at:Vector2 in [Vector2(-3,2.2),Vector2(3,2.2)]:points.append(origin+at.rotated(-yaw))
		check(city.add_road(points,"path","none").ok,"real parallel street")
		var entry:Dictionary=city.house_entrances("h1")[0];var normal:=Frame.normal(entry);var tangent:=Vector2(-normal.y,normal.x)
		var target:=origin+Vector2(0,2.2).rotated(-yaw)
		compare(city,target);compare(city,target-tangent*.5)
		# Actual rectangle, oriented box and polygon blockers on both strip sides,
		# including the entry circle and the first/last exact strip boundaries.
		for side:float in [-1.,1.]:
			for offset:float in [.34999,.35,.35001,.3521]:
				var at:Vector2=entry.at+tangent*(side*offset)
				var shapes:Array=[Rect2(at-Vector2.ONE*.00001,Vector2.ONE*.00002),{"center":at,"half":Vector2(.015,.04),"angle":yaw+.37}]
				shapes.append({"polygon":PackedVector2Array([at-tangent*.01-normal*.03,at+tangent*.01-normal*.03,at+normal*.04])})
				for shape:Variant in shapes:compare(city,target-tangent*.5,[{"owner":"probe","attachment":true,"shape":shape}])
		var path:Array[Vector2]=[entry.wall_at+normal*.18,entry.at,target]
		var near:={"owner":"near","attachment":false,"shape":Rect2(entry.at-Vector2.ONE*.02,Vector2.ONE*.04)}
		var far:={"owner":"far","attachment":false,"shape":Rect2(Vector2(100,100),Vector2.ONE)}
		var rows:Array=[far,near,far.duplicate(true),near.duplicate(true)]
		check(Prepared.create(rows).along(path,.35)==[near,near],"local candidates retain duplicate values and original order")
		check(Prepared.create([]).along(path,.35).is_empty(),"empty obstacle input stays empty")
	var stoa:=State.new();stoa.initialize_free();Brush.select(stoa,"pastoral","ionic_stoa")
	check(stoa.add_house_stroke(Vector2(-25,-20),[{"x":0,"z":0,"level":0,"kind":"room"},{"x":1,"z":0,"level":0,"kind":"room"},{"x":2,"z":0,"level":0,"kind":"room"}]).ok,"real stoa column shell")
	check(stoa.add_road([Vector2(-29,-17.4),Vector2(-18,-17.4)],"path","none").ok,"real stoa street")
	var entry:Dictionary=stoa.house_entrances("h1")[0];compare(stoa,Vector2(entry.at.x,-17.4))
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ENTRY_OBSTACLES ",JSON.stringify(report));quit(0 if report.ok else 1)
