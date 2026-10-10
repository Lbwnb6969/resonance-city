extends SceneTree

const World = preload("res://scripts/world/continuous_world.gd")
const TransitPlan = preload("res://scripts/world/transit_planning.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _road_positions(world: ContinuousWorld) -> Array:
	for road in world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2 or path[0].distance_to(path[-1]) < 1.2: continue
		return [path[0].lerp(path[-1],0.25),path[0].lerp(path[-1],0.75)]
	return []

func _run() -> void:
	var world := World.new("2026101100000164",true,"river_valley")
	world.build_expanded_town()
	var positions := _road_positions(world)
	_check(positions.size() == 2,"fixture exposes a long real road for non-node stations")
	if positions.size() != 2:
		print("AUTHORED_TRANSIT_TRAVELERS ",JSON.stringify({"passed":false,"failures":failures}))
		quit(1)
		return
	var operation := {"event_id":16401,"source_topology":world.network.topology,"stop_positions":positions}
	var committed := TransitPlan.commit(world,operation,0)
	_check(bool(committed.get("accepted",false)),"authored line commits from real road positions")
	world._refresh_public_network()
	var line_id := str(committed.get("id",""))
	var line: Dictionary = {}
	for candidate in world.transit_lines:
		if str(candidate.get("id","")) == line_id: line = candidate
	_check(bool(line.get("authored",false)),"runtime transit lines include authored line")
	_check(line.get("legs",[]).size() >= 2,"authored line keeps out-and-back legs")
	var non_node := false
	for stop_id in line.get("stops",[]):
		var record := world.transit_stop_record(str(stop_id))
		_check(not record.is_empty(),"every authored stop has a stable record")
		_check(world.transit_stop_position(str(stop_id)).distance_to(Vector2(record["position"][0],record["position"][1])) < 0.0001,"stop position comes from record")
		if not world.network.nodes.has(str(stop_id)): non_node = true
	_check(non_node,"author line retains a station between road nodes")
	var bus := Traveler.new("bus",0)
	bus.service_line_id = line_id
	bus.assigned_line_id = line_id
	var moved := false
	var saw_stop := false
	var boarded := 0
	for step in range(1,2401):
		var result: Dictionary = bus.advance(world,float(step)*0.1)
		if result.is_empty(): continue
		_check(str(result.get("line_id","")) == line_id,"authored vehicle retains stable line identity")
		if bus.position.distance_to(bus.path[0]) > 0.08: moved = true
		if not str(result.get("stop_id","" )).is_empty():
			saw_stop = true
			boarded += int(result.get("boarded",0))
	_check(moved,"authored vehicle moves along its physical leg")
	_check(saw_stop,"authored vehicle exposes a real stop id")
	_check(boarded > 0,"authored vehicle records passenger boarding")
	var saved := bus.snapshot()
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	_check(restored.service_line_id == line_id and restored.assigned_line_id == line_id,"authored service identity survives snapshot")
	var result := {"passed":failures.is_empty(),"line_id":line_id,"stops":line.get("stops",[]),"legs":line.get("legs",[]).size(),"non_node":non_node,"failures":failures}
	print("AUTHORED_TRANSIT_TRAVELERS ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
