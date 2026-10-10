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
	var world := World.new("2026101000000114",true,"river_valley")
	world.build_expanded_town()
	var bus := Traveler.new("bus",0)
	var loads: Array[int] = []
	var boarded_total := 0
	var alighted_total := 0
	var transfer_passengers := 0
	var transfer_boarded := 0
	var transfer_alighted := 0
	var max_load := 0
	var min_load := 99
	for step in range(2401):
		var result: Dictionary = bus.advance(world,float(step)*0.1)
		if result.is_empty(): continue
		var load := int(result.get("passengers",0))
		loads.append(load)
		max_load = maxi(max_load,load)
		min_load = mini(min_load,load)
		boarded_total += int(result.get("boarded",0))
		alighted_total += int(result.get("alighted",0))
		if int(result.get("transfer_passengers",0)) > 0:
			transfer_passengers += int(result.get("transfer_passengers",0))
			transfer_boarded = int(result.get("boarded",0))
			transfer_alighted = int(result.get("alighted",0))
	_check(max_load > min_load,"station demand changes vehicle load")
	_check(boarded_total > 0 and alighted_total > 0,"passenger flow records boarding and alighting")
	_check(max_load < 12 and min_load > 0,"passenger load stays inside bus capacity")
	_check(transfer_passengers > 0,"transfer station carries connecting passengers")
	_check(transfer_boarded >= 0 and transfer_alighted > 0,"transfer stop records a meaningful exchange")
	var saved := bus.snapshot()
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	_check(restored.passengers_boarded == bus.passengers_boarded and restored.passengers_alighted == bus.passengers_alighted and restored.transfer_passengers == bus.transfer_passengers,"passenger flow survives traveler snapshot")
	print("TRANSIT_CAPACITY ",JSON.stringify({"passed":failures.is_empty(),"min_load":min_load,"max_load":max_load,"boarded":boarded_total,"alighted":alighted_total,"transfer_passengers":transfer_passengers,"transfer_boarded":transfer_boarded,"transfer_alighted":transfer_alighted,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
