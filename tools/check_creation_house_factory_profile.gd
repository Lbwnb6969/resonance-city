extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
class TimedRenderer extends "res://scripts/visual/city_creation_renderer.gd":
	var calls:Dictionary={}
	var walls:Array=[]
	func record(key:String,began:int)->void:
		var row:Dictionary=calls.get(key,{"count":0,"ms":0.});row.count+=1;row.ms+=float(Time.get_ticks_usec()-began)/1000.;calls[key]=row
	func _box(parent:Node3D,size:Vector3,at:Vector3,material:Material)->MeshInstance3D:
		var began:=Time.get_ticks_usec();var result:=super._box(parent,size,at,material);record("box",began);return result
	func _triangles(parent:Node3D,vertices:Array,color:Color)->MeshInstance3D:
		var began:=Time.get_ticks_usec();var result:=super._triangles(parent,vertices,color);record("triangles",began);return result
	func _cylinder(parent:Node3D,bottom:float,top:float,height:float,at:Vector3,material:Material,sides:int=8)->MeshInstance3D:
		var began:=Time.get_ticks_usec();var result:=super._cylinder(parent,bottom,top,height,at,material,sides);record("cylinder",began);return result
	func _house_cell_wall(job:HouseAssembly,frame:HouseAssembly.Cell,direction:Vector2i)->void:
		var began:=Time.get_ticks_usec();var before:Dictionary=calls.duplicate(true);super._house_cell_wall(job,frame,direction);var delta:Dictionary={}
		for key:String in calls:delta[key]={"count":calls[key].count-int(before.get(key,{}).get("count",0)),"ms":calls[key].ms-float(before.get(key,{}).get("ms",0.))}
		walls.append({"cell":frame.cell.id,"direction":direction,"ms":float(Time.get_ticks_usec()-began)/1000.,"factories":delta})
func _initialize()->void:call_deferred("run")
func run()->void:
	var out:="";var expected:="forward_plus"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--expected-renderer="):expected=arg.trim_prefix("--expected-renderer=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/M85/policy_scale_20261104/cafe_300_fixture/quiet.json"));var state:=State.new();var restored:Dictionary=state.restore(world)
	var town:=TimedRenderer.new();root.add_child(town);town.setup(state,true);town.set_process(false)
	var rows:Array=[]
	for index:int in [0,6,9]:
		town.calls={};town.walls=[];var start:=Time.get_ticks_usec();var house:Node3D=town._house(state.houses[index])
		rows.append({"id":state.houses[index].id,"ms":float(Time.get_ticks_usec()-start)/1000.,"factory":town.calls.duplicate(true),"walls":town.walls.duplicate(true),"assembly":house.get_meta("house_assembly",{}).duplicate(true)})
	var report:={"ok":restored.ok and FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal and RenderingServer.get_current_rendering_method()==expected,"renderer":RenderingServer.get_current_rendering_method(),"rows":rows,"seconds":(Time.get_ticks_msec()-began)/1000.,"scope":"Three original houses in full300 author context; factory method timing excludes subsequent material batching/color prep, no author or personal writes","source_sha256":FileAccess.get_sha256("res://scripts/visual/city_creation_renderer.gd"),"tool_sha256":FileAccess.get_sha256("res://tools/check_creation_house_factory_profile.gd")}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t",true,true));print("HOUSE_FACTORY ",JSON.stringify(report));town.queue_free();await process_frame;quit(0 if report.ok else 1)
