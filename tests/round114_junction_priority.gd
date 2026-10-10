extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)

func _point_near_node(world: ContinuousWorld,road: Dictionary,node_id: String) -> Vector2:
	var path: PackedVector2Array = road["path"]
	var node_point := Vector2(float(world.network.nodes[node_id][0]),float(world.network.nodes[node_id][1]))
	var anchor := Vector2.ZERO
	if str(road["from"]) == node_id and path.size() > 1:
		anchor = path[1]
	elif str(road["to"]) == node_id and path.size() > 1:
		anchor = path[path.size()-2]
	else:
		return node_point
	var tangent := (anchor-node_point).normalized()
	return node_point+tangent*0.25

func _run() -> void:
	var world := World.new("2026101000000114",true,"river_valley")
	world.build_expanded_town()
	var roads: Array = world.network.roads
	var found := false
	var road_a: Dictionary = {}
	var road_b: Dictionary = {}
	var shared := ""
	for a in roads:
		for b in roads:
			if a["id"] == b["id"]: continue
			for node_id in [str(a["from"]),str(a["to"])]:
				if node_id == str(b["from"]) or node_id == str(b["to"]):
					road_a = a
					road_b = b
					shared = node_id
					found = true
					break
			if found: break
		if found: break
	_check(found,"expanded road graph has a real shared junction")
	if found:
		var node_point := Vector2(float(world.network.nodes[shared][0]),float(world.network.nodes[shared][1]))
		var current_position := _point_near_node(world,road_a,shared)
		var other_position := _point_near_node(world,road_b,shared)
		var follower := Traveler.new("bus",7)
		follower.position = current_position
		follower.direction = (node_point-current_position).normalized()
		var access := {"road":str(road_a["id"]),"from":str(road_a["from"]),"to":str(road_a["to"])}
		var blocker := {"kind":"car","ordinal":0,"position":other_position,"direction":(node_point-other_position).normalized(),
			"road":str(road_b["id"]),"road_from":str(road_b["from"]),"road_to":str(road_b["to"]),"priority":0}
		_check(follower._junction_conflict(world,access,blocker),"lower-priority traveler yields at shared junction")
		_check(follower._traffic_distance(world,0.2,[blocker]) <= 0.000001,"junction conflict caps movement before crossing")
		blocker["priority"] = follower._priority()+1
		_check(not follower._junction_conflict(world,access,blocker),"higher-priority traveler keeps junction right-of-way")
	print("JUNCTION_PRIORITY ",JSON.stringify({"passed":failures.is_empty(),"shared":shared,"road_a":road_a.get("id",""),"road_b":road_b.get("id",""),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
