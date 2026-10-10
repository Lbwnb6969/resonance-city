extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition:
		failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000118",true,"river_valley")
	world.build_expanded_town()
	var bus := Traveler.new("bus",0)
	var destination_seen := false
	var destination_alighted := false
	var transfer_seen := false
	var exchanges := 0
	var invalid_destination := false
	for step in range(2401):
		var result: Dictionary = bus.advance(world,float(step)*0.1)
		if result.is_empty(): continue
		var destinations: Array = result.get("passenger_destinations",[])
		_check(destinations.size() == int(result.get("passengers",0)),"destination list matches passenger load")
		for destination in destinations:
			if str(destination).is_empty(): continue
			destination_seen = true
			var valid_on_some_line := false
			for line in world.transit_lines:
				if line.get("stops",[]).has(str(destination)):
					valid_on_some_line = true
					break
			if not valid_on_some_line: invalid_destination = true
		if int(result.get("alighted",0)) > 0 and destination_seen: destination_alighted = true
		if int(result.get("transfer_count",0)) > 0: transfer_seen = true
		exchanges += int(result.get("boarded",0))+int(result.get("alighted",0))
	_check(destination_seen,"passengers receive concrete destination stops")
	_check(destination_alighted,"passengers alight after reaching a destination")
	_check(not invalid_destination,"passenger destinations belong to the active transit topology")
	_check(transfer_seen,"destination state survives a line transfer")
	_check(exchanges > 0,"destination-aware stops continue to exchange passengers")
	var saved := bus.snapshot()
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	_check(restored.passenger_destinations == bus.passenger_destinations,"passenger destinations survive traveler snapshot")
	print("PASSENGER_DESTINATIONS ",JSON.stringify({"passed":failures.is_empty(),"destinations":bus.passenger_destinations,"load":bus.passenger_load,"exchanges":exchanges,"transfer_count":bus.transfer_count,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
