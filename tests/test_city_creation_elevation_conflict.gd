extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Conflict=preload("res://scripts/world/city_creation_elevation_conflict.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize()->void:
	if not "--isolated-session" in OS.get_cmdline_user_args():quit(1);return
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/city_creation_elevation_overlap.json"))
	var c:=State.new();check(c.restore(source.before).ok,"original valid raised-ground fixture restores")
	var before:Dictionary=c.snapshot();var depth:int=c._undo.size();var at:=Vector2(-23.2,-20)
	check(is_equal_approx(c.sample_house_base_y(at),1.4),"candidate uses actual raised-ground datum")
	check(not c.validate_add_house(at).ok and not c.add_house(at).ok,"single new house cannot cross existing terrace at a different authored level")
	check(c.snapshot()==before and c._undo.size()==depth,"rejected house issues no identity or history")
	var stroke:Array=[{"x":0,"z":0,"level":0,"kind":"room"}]
	check(not c.preview_house_stroke(at,stroke).ok and not c.add_house_stroke(at,stroke).ok,"full-stroke preview and commit refuse same physical collision")
	check(c.snapshot()==before and c._undo.size()==depth,"rejected stroke leaves complete world unchanged")
	check(c.add_house(Vector2(-29,-20)).ok,"separate legal new house remains buildable")
	var built:Array=c.houses.duplicate(true);check(c.undo().ok and c.houses==before.houses,"Undo removes legal house")
	check(c.redo().ok and c.houses==built,"Redo preserves legal house and elevations")
	var cold:=State.new();check(cold.restore(c.snapshot()).ok and cold.houses==c.houses,"new legal world cold restores")
	var old:=State.new();check(old.restore(source.after).ok and old.houses.size()==2 and is_equal_approx(float(old.houses[1].base_y),1.4) and Conflict.houses(old.houses[0],old.houses[1]),"historical overlap snapshot still reads without migration")
	var old_copy:=State.new();check(old_copy.restore(old.snapshot()).ok and old_copy.houses==old.houses,"normalized historical data remains stable on repeated reads")
	var houses:Array=old.houses.duplicate(true)
	check(old.set_house_palette("h2",2).ok and old.undo().ok and old.houses==houses,"historical author's appearance remains editable and undoable")
	var first:Dictionary=source.after.houses[0].duplicate(true);var second:Dictionary=source.after.houses[1].duplicate(true)
	check(Conflict.houses(first,second) and Conflict.houses(second,first),"new-edit physical guard is symmetric")
	second.base_y=0.;check(not Conflict.houses(first,second),"same-datum historical inter-storey rule unchanged")
	second.base_y=1.88;check(not Conflict.houses(first,second),"touching vertical surfaces do not overlap")
	second.base_y=3.5;check(not Conflict.houses(first,second),"vertically separated solids do not overlap")
	second.base_y=1.4
	for angle:float in [.37,PI*.5,-.83]:
		first.yaw=angle;var center:=Conflict.Frame.center(first,{"x":1,"z":0,"level":1})
		second.origin=[center.x,center.y];second.yaw=-.21
		check(Conflict.houses(first,second),"rotated polygons keep actual height collision "+str(angle))
	var reverse:=State.new();reverse.initialize_free()
	check(reverse.apply_terrain_target(reverse.plan_terrain_target([at] as Array[Vector2],2.,1.4,true)).ok,"reverse-order terrain fixture")
	check(reverse.add_house(at).ok and reverse.add_house(Vector2(-25,-20)).ok,"adjacent houses at different datums retain grid contact tolerance")
	check(reverse.add_cell("h2",0,0,1).ok,"legal lower-house upper room")
	before=reverse.snapshot();depth=reverse._undo.size()
	check(not reverse.add_cell("h2",1,0,1,"terrace").ok,"later terrace cannot grow through existing raised house")
	check(reverse.snapshot()==before and reverse._undo.size()==depth,"rejected terrace preserves author and history")
	print("ELEVATION_CONFLICT ",JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
