extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition:
		failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000115",true,"river_valley")
	world.build_expanded_town()
	var transfer_position := Vector2.ZERO
	var transfer_stop := ""
	for line in world.transit_lines:
		for transfer in line.get("transfer_stops",[]):
			transfer_stop = str(transfer.get("stop_id",""))
			break
		if not transfer_stop.is_empty(): break
	if world.network.nodes.has(transfer_stop):
		var node: Array = world.network.nodes[transfer_stop]
		transfer_position = Vector2(float(node[0]),float(node[1]))
	var far_position := transfer_position+Vector2(20.0,20.0)
	var near_bonus := world._transit_growth_bonus(transfer_position+Vector2(0.8,0.8),"commercial")
	var far_bonus := world._transit_growth_bonus(far_position,"commercial")
	_check(not transfer_stop.is_empty(),"expanded town exposes a transfer stop")
	_check(near_bonus > far_bonus,"transit proximity raises commercial growth priority")
	var before := world.buildings.size()
	world.settle(1)
	var grown: Array[Dictionary] = []
	for building in world.buildings:
		if world.buildings.find(building) >= before:
			grown.append(building)
	var transit_grown := 0
	var max_growth_bonus := 0.0
	for building in grown:
		var position := Coupling.position_of(building)
		var bonus := world._transit_growth_bonus(position,str(building.get("type","residential")))
		max_growth_bonus = maxf(max_growth_bonus,bonus)
		if bonus > 0.0: transit_grown += 1
	_check(not grown.is_empty(),"city grows after a phrase")
	_check(transit_grown > 0,"at least one new building responds to transit proximity")
	_check(max_growth_bonus > 0.0,"grown building records a transit-linked placement signal")
	var snapshot := world.snapshot()
	var restored: World = world.fork()
	_check(restored.snapshot().get("transit_lines",[]) == snapshot.get("transit_lines",[]),"transit growth topology survives fork")
	print("TRANSIT_GROWTH ",JSON.stringify({"passed":failures.is_empty(),"transfer_stop":transfer_stop,"near_bonus":near_bonus,"far_bonus":far_bonus,"grown":grown.size(),"transit_grown":transit_grown,"max_growth_bonus":max_growth_bonus,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
