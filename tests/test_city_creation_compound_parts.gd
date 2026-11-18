extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Parts=preload("res://scripts/world/city_creation_compound_parts.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:run.call_deferred()
static func fixture()->RefCounted:
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",1,0,0);city.add_cell("h1",0,1,0);city.add_cell("h1",1,1,0);city.add_cell("h1",0,0,1);city.add_cell("h1",1,0,1);city.set_house_architecture("h1","townhouse");city.set_house_roof_pitch("h1",45.);return city
func run()->void:
	var out:=""
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):out=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not out.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(out):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var city:=fixture();var before:Dictionary=city.snapshot();var depth:int=city._undo.size();var plan:=Parts.plan(city,"h1",Vector2i.RIGHT,"round_tower",3)
	check(plan.ok and city.snapshot()==before and city._undo.size()==depth,"actual compound preview keeps authors, history and issued IDs unchanged")
	if not plan.ok:print(plan);quit(1);return
	var result:Dictionary=city.add_compound_part("h1",Vector2i.RIGHT,"round_tower",3);var round:Dictionary=Parts.Round.for_house(city.houses[-1],city.houses,city.roads)
	check(result.ok and city.houses[0]==before.houses[0] and city._undo.size()==depth+1 and city.snapshot().schema==37,"adding independently editable part preserves big main building in one transaction")
	check(result.before_upgrade==before and not round.is_empty() and round.joins.size()==2 and round.cells.size()==3,"explicit upgrade retains old city and joins real cylinder at both main floors")
	var saved:Dictionary=city.snapshot();var cold:=State.new();check(cold.restore(saved).ok and cold.houses==city.houses and Parts.Round.for_house(cold.houses[-1],cold.houses,cold.roads)==round,"complete compound and exact physical seam cold restore")
	check(city.undo().ok and city.houses==before.houses and city.redo().ok and city.houses==saved.houses,"one Undo/Redo returns entire compound part including roof recipe")
	check(city.save_city(out+"/castle.json").ok and cold.load_city(out+"/castle.json").ok and cold.houses==city.houses,"schema37 actual disk round trip retains separate roof choices")
	for angle:float in [0.,78.]:
		check(city.set_house_roof_pitch(str(result.house_id),angle).ok and city.houses[0]==before.houses[0] and not Parts.Round.for_house(city.houses[-1],city.houses,city.roads).is_empty(),"tower independently goes flat to steep without changing main roof "+str(angle))
	var collision_city:=fixture();collision_city.add_compound_part("h1",Vector2i.RIGHT,"round_tower",3);var initial:Dictionary=collision_city.snapshot();check(not collision_city.set_house_roof_pitch("h1",78.).ok and collision_city.snapshot()==initial,"raising main roof into tower eave rejects without losing cylinder or author choices")
	var added:Dictionary=city.houses[-1].duplicate(true);check(city.set_house_roof_pitch("h1",0.).ok and city.houses[-1]==added,"main roof may become flat while tower remains steep")
	var ctx:=Parts.Context.new();ctx.prepare(city.houses,city.roads)
	var host:Dictionary=city.houses[0];var touching:Dictionary=host.cells.filter(func(c):return c.x==1 and c.z==0 and c.level==0)[0]
	check(ctx.neighbor(host,touching,Vector2i.RIGHT).is_empty(),"circular tangent contact never deletes an entire square main wall")
	var alone:=Parts.Context.new();alone.prepare([host],city.roads)
	check(ctx.roof_patches("h1")==alone.roof_patches("h1"),"round tower does not merge a square fake roof into flat main roof")
	var at:Dictionary=city.snapshot();depth=city._undo.size();check(not city.add_compound_part("h1",Vector2i.RIGHT,"round_tower",3).ok and city.snapshot()==at and city._undo.size()==depth,"occupied side rejects without losing prior parts or consuming IDs")
	check(not Parts.plan(city,"h1",Vector2i.LEFT,"round_tower",1).ok,"low tower roof cannot occupy upper main room")
	check(not Parts.plan(city,"h1",Vector2i.RIGHT,"round_tower",9).ok and not Parts.plan(city,"h1",Vector2i(1,1),"round_tower",3).ok,"out of range height and diagonal attachment reject")
	var square:Dictionary=city.add_compound_part("h1",Vector2i.LEFT,"classic",2);check(square.ok and city.houses[-1].roof_pitch.degrees==0. and city.set_house_roof_pitch(str(square.house_id),65.).ok and city.houses[1]==added,"flat square wing independently gets a steep gable alongside circular tower")
	var invalid:Dictionary=city.snapshot();invalid.schema=36;check(not cold.restore(invalid).ok,"new physical joining marker cannot silently enter old schema")
	invalid=city.snapshot();invalid.houses[-1].assembly_part.version=2;check(not cold.restore(invalid).ok,"unknown joining recipes reject")
	check(city.remove_house("h1").ok and not Parts.Round.for_house(city.houses[0],city.houses,city.roads).is_empty() and Parts.Round.for_house(city.houses[0],city.houses,city.roads).joins.is_empty() and State.new().restore(city.snapshot()).ok,"removing main leaves an independently valid tower without ghost seam or broken parent reference")
	var rotated:=fixture();rotated.rotate_house("h1",.35);var r:=Parts.plan(rotated,"h1",Vector2i.RIGHT,"round_tower",3);check(r.ok and rotated.add_compound_part("h1",Vector2i.RIGHT,"round_tower",3).ok and not Parts.Round.for_house(rotated.houses[-1],rotated.houses,rotated.roads).is_empty(),"rotated main joins using its own real frame")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures};FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("COMPOUND_CPU ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
