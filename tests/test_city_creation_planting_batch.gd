extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Life=preload("res://scripts/world/city_creation_life.gd")
const Network=preload("res://scripts/world/city_creation_network.gd")
class Unbatched extends State:
	func _plant_geometry_compatible(plant:Dictionary,extra:Array,include_existing:bool=false,_entrances:Dictionary={})->bool:
		return super._plant_geometry_compatible(plant,extra,include_existing)
var checks:=0
var failures:Array=[]
var timings:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func prime(city:RefCounted)->void:
	city.road_junctions();var network:=Network.new();network.state=city;network._build_graph();city.prepare_regional_echo(network);city.functional_zones()
func same(a:RefCounted,b:RefCounted,label:String)->void:
	check(a.plants==b.plants and a._high_watermark==b._high_watermark,label+": exact identities positions kinds sizes seeds and issued watermarks")
	check(a.snapshot()==b.snapshot(),label+": complete independent source save including paused counter high-water matches")
func run()->void:
	var out:="";var source:="";var oracle:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--fixture="):source=arg.trim_prefix("--fixture=")
		if arg.begins_with("--oracle="):oracle=arg.trim_prefix("--oracle=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec()
	for warm:bool in [true,false]:
		var a:=State.new();var b:RefCounted=Unbatched.new() if oracle.is_empty() else load(oracle).new()
		if source.is_empty():
			a.initialize_free();b.initialize_free()
			check(a.add_house(Vector2(-24,-20)).ok and b.add_house(Vector2(-24,-20)).ok,"actual small cold house source")
		else:
			var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source));check(a.restore(data).ok and b.restore(data).ok,"same actual source independently restores")
		var owners:Array[Node3D]=[]
		for city:RefCounted in [a,b]:
			var life:=Life.new();root.add_child(life);life.set_process(false);life.setup(city,true);owners.append(life)
			if warm:prime(city)
		var before:=a.snapshot();var history:=a._undo.size()
		for action:String in ["single","stroke","erase"]:
			var points:Array[Vector2]=[]
			for i in range(21):points.append(Vector2(-24+i*.42,33+.25*sin(i*.3)))
			var results:Array=[];var ms:Array=[]
			for city:RefCounted in [a,b]:
				var at:=Time.get_ticks_usec();var result:Dictionary
				if action=="single":result=city.place_plant(Vector2(-14.6,34.8),"olive")
				elif action=="stroke":result=city.add_vegetation_stroke(points,"pink_flower",1.4)
				else:result=city.erase_vegetation_stroke([Vector2(-20,33)] as Array[Vector2],2.5)
				ms.append((Time.get_ticks_usec()-at)/1000.);results.append(result)
			check(results[0].ok and results[0]==results[1],action+": original transaction result and candidate acceptance match")
			same(a,b,action+" warm="+str(warm));timings.append({"warm":warm,"action":action,"new_ms":ms[0],"oracle_ms":ms[1],"added":results[0].get("added_count",0)})
		check(a._undo.size()==history+3,"three exact plant transactions retain three history entries")
		var saved:=a.snapshot()
		for i in range(3):check(a.undo().ok and b.undo().ok,"actual whole-transaction Undo");same(a,b,"Undo "+str(i))
		check(a.plants==before.plants,"all original plants return after three Undo")
		for i in range(3):check(a.redo().ok and b.redo().ok,"actual whole-transaction Redo");same(a,b,"Redo "+str(i))
		check(a.plants==saved.plants,"Redo restores exact complete plants")
		var cold:=State.new();check(cold.restore(saved).ok and cold.plants==saved.plants,"independent source cold restore retains all planted records")
		var denied:=a.snapshot();check(not a.place_plant(Vector2(0,0),"invalid").ok and a.snapshot()==denied,"invalid plant does not alter authored values")
		for life:Node3D in owners:life.free()
	frontage_values()
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"timings":timings,"fixture":source,"oracle":oracle,"seconds":(Time.get_ticks_usec()-began)/1000000.}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("PLANTING_BATCH ",JSON.stringify(result));quit(0 if result.ok else 1)
func frontage_values()->void:
	var city:=State.new();city.initialize_free();check(city.add_house(Vector2(-24,-20)).ok,"actual frontage ownership source")
	city.road_junctions();var first:Dictionary=city._junctions.planting_frontages(city)
	check(not first.is_empty() and first.h1==city.house_entrances("h1"),"primed snapshot contains exact original entrance records")
	first.h1.clear();check(not city._junctions.planting_frontages(city).h1.is_empty(),"transaction cannot mutate published source frontier records")
	city.houses[0]=city.houses[0].duplicate(true);city.houses[0].origin[0]+=4.
	check(city._junctions.planting_frontages(city,false).is_empty(),"same-revision relocated house rejects old frontage snapshot")
	check(city._junctions.planting_frontages(city).h1==city.house_entrances("h1"),"unprimed relocation resolves original complete frontage algorithm")
	city.road_junctions();city.roads.append({"id":"rprobe","points":[[-20.,-18.1],[-16.,-18.1]],"width":1.25})
	check(city._junctions.planting_frontages(city,false).is_empty() and city._junctions.planting_frontages(city).h1==city.house_entrances("h1"),"same-revision road edit rejects stale geometry and derives exact replacement")
