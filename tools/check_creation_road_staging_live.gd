extends "res://tools/check_creation_road_publish_live.gd"
var watching:=false
var observations:=0
var partial_seen:=false
var hidden_ok:=true
var collision_ok:=true
func _process(delta:float)->bool:
	var value:=super._process(delta)
	if watching and demo!=null and demo.town.budget_rebuild!=null:
		var stage:Node3D=demo.town.budget_rebuild.staging
		if stage!=null:
			for node:Node3D in stage.road_roots.values():
				observations+=1;hidden_ok=hidden_ok and not node.is_visible_in_tree()
				partial_seen=partial_seen or int(node.get_meta("road_install_phase",0)) in range(1,12)
				for body:StaticBody3D in node.find_children("*","StaticBody3D",true,false):collision_ok=collision_ok and body.collision_layer==0
	return value
func command(result:Dictionary,kind:String,label:String)->Dictionary:
	observations=0;partial_seen=false;hidden_ok=true;collision_ok=true;watching=true
	var report:=await super.command(result,kind,label);watching=false
	check(observations>0 and partial_seen,"real partially installed road observed: "+label)
	check(hidden_ok and collision_ok,"partial staging remains invisible and unpickable: "+label)
	var published:=true
	for node:Node3D in demo.town.road_roots.values():
		for body:StaticBody3D in node.find_children("*","StaticBody3D",true,false):published=published and body.collision_layer==int(body.get_meta("pending_collision_layer",2))
	check(published,"published road restores actual collision layer: "+label)
	report.staging={"observations":observations,"partial_seen":partial_seen,"hidden":hidden_ok,"collision_disabled":collision_ok,"published_collision_restored":published};return report
