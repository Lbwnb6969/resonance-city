extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Budget=preload("res://scripts/visual/city_creation_budget_rebuild.gd")
const Pending=preload("res://scripts/visual/city_creation_pending_plants.gd")
class Town extends Node3D:
	var budget_rebuild:=Budget.new()
	var foliage=preload("res://scripts/visual/city_creation_foliage.gd").new()
	var vegetation_layer:=Node3D.new()
class Owner extends Node:
	var tool:=0
	var state:=State.new()
	var town:=Town.new()
var checks:=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out));var began:=Time.get_ticks_usec()
	var owner:=Owner.new();root.add_child(owner);owner.add_child(owner.town);owner.town.add_child(owner.town.vegetation_layer)
	var city:RefCounted=owner.state;city.initialize_free();city.prepare_ground_height();owner.town.budget_rebuild.record_published(city)
	var at:=Vector2(-20,30);var frozen:RefCounted=owner.town.budget_rebuild.published_ground;var y:float=frozen.height_at(at);var vertices:PackedFloat32Array=frozen.vertices.duplicate()
	check(Pending.can_paint(owner),"published exact source admits planting")
	check(city.add_terrain_stroke([at] as Array[Vector2],"raise",4.,.8,1).ok,"real terrain edit has an unpublished changed source")
	var raised:float=city.ground_height(at)
	check(raised>y+.1 and not Pending.can_paint(owner),"changed height source blocks continuous planting")
	check(frozen.vertices==vertices and frozen.height_at(at)==y,"published height copy survives a real synchronous prepare unchanged")
	check(city.undo().ok and Pending.can_paint(owner),"Undo recovers published author geometry before any new height preparation")
	check(city._ground_revision!=city.revision and city._ground_terrain.height_at(at)>y+.1,"test actually retains an unpublished stale CPU grid after Undo")
	var result:Dictionary=city.place_plant(at,"olive");check(result.ok,"real accepted plant authors its stable identity")
	Pending.keep(owner,result);var pending:Node=owner.get_meta("pending_plants");var id:String=str(result.plant_ids[0])
	check(is_equal_approx(pending.rows[id].pose.origin.y,y-State.Terrain.BASE_HEIGHT),"immediate plant uses frozen visible ground instead of stale live height cache")
	check(pending.rows[id].node.find_children("*","CollisionObject3D",true,false).is_empty(),"committed display copies have no physics or author proxies")
	var authored:Array=city.plants.duplicate(true);var n:int=city._undo.size();pending._process(0.)
	check(city.plants==authored and city._undo.size()==n,"display updates do not author more plants or history")
	check(city.undo().ok,"actual undo removes newly planted source")
	pending._process(0.);check(pending.rows.is_empty(),"author Undo withdraws only its committed display")
	owner.free()
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_usec()-began)/1000000.,"published_y":y,"unpublished_y":raised}
	FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("PENDING_PLANTS_CPU ",JSON.stringify(report));quit(0 if report.ok else 1)
