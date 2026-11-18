extends SceneTree
const State=preload("res://scripts/world/city_creation_state.gd")
const Neo=preload("res://scripts/visual/city_creation_neoclassical.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func fixture(blocker:bool)->RefCounted:
	var c:=State.new();c.initialize_free();c.add_house(Vector2(-25,-20));c.add_cell("h1",1,0,0);c.add_cell("h1",1,0,1)
	c.set_house_era("h1","renaissance")
	var south:Array[Vector2]=[Vector2(-27,-17.5),Vector2(-19,-17.5)]
	var east:Array[Vector2]=[Vector2(-21.4,-24),Vector2(-21.4,-16)]
	check(c.add_road(south,"path","none").ok and c.add_road(east,"path","none").ok,"actual two street fixture")
	if blocker:
		check(c.add_house(Vector2(-21.4,-20)).ok and c.add_cell("h2",0,0,1).ok,"actual neighbour with legal ground passage")
	return c
func rotate_all(snapshot:Dictionary,angle:float)->Dictionary:
	var result:=snapshot.duplicate(true);var pivot:=Vector2(-25,-20)
	for house:Dictionary in result.houses:
		var at:=pivot+(Vector2(house.origin[0],house.origin[1])-pivot).rotated(-angle)
		house.origin=[at.x,at.y];house.yaw=wrapf(angle,-PI,PI)
	for road:Dictionary in result.roads:
		for i in range(road.points.size()):
			var at:=pivot+(Vector2(road.points[i][0],road.points[i][1])-pivot).rotated(-angle);road.points[i]=[at.x,at.y]
	return result
func _initialize()->void:
	if not "--isolated-session" in OS.get_cmdline_user_args():quit(1);return
	for blocker:bool in [false,true]:
		var c:=fixture(blocker);var before:Dictionary=c.snapshot();var depth:int=c._undo.size()
		var expected:Array=[] if blocker else [Vector2i.RIGHT,Vector2i.DOWN]
		check(Neo.corner_sides(c,c.houses[0],c.houses[0].cells[-1])==expected,"unrotated street/occlusion recipe remains intact")
		for angle:float in [0.,PI*.5,PI,-PI*.5,.37,-.83]:
			var copy:=State.new();var restored:Dictionary=copy.restore(rotate_all(before,angle))
			check(restored.ok,"actual rotated snapshot restores "+str(angle)+" "+str(restored.message))
			if not restored.ok:continue
			var saved:Dictionary=copy.snapshot()
			check(Neo.corner_sides(copy,copy.houses[0],copy.houses[0].cells[-1])==expected,"local corner invariant under common house/road/neighbour rotation "+str(angle)+" blocker="+str(blocker))
			preload("res://scripts/world/city_creation_frontage_neighborhoods.gd").build(copy)
			check(Neo.corner_sides(copy,copy.houses[0],copy.houses[0].cells[-1])==expected,"prepared neighbourhood agrees with complete scene")
			check(copy.snapshot()==saved,"corner query does not write author data")
		check(c.snapshot()==before and c._undo.size()==depth,"original city and history remain untouched")
		if not blocker:
			var signature:Array=Neo.corner_signature(c,c.houses[0]);c.remove_road("r2")
			check(Neo.corner_signature(c,c.houses[0])!=signature,"derived geometry signature changes when corner street disappears")
	print("ORIEL_WORLD_FRAME ",JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
