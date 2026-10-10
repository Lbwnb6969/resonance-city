extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000113",true,"river_valley")
	world.build_expanded_town()
	world.era = 5

	var car := Traveler.new("car",0)
	var first := car.advance(world,0.0)
	_check(bool(first.get("stopped",false)),"car pauses at its first destination")
	_check(car.wait >= 0.3,"car destination dwell is visible")
	var semantic_kinds: Dictionary = {}
	var stop_frames := 0
	var last_trip := car.trip
	var completed_trips := 0
	for step in range(1,2401):
		var movement := car.advance(world,float(step)*0.1)
		if movement.is_empty(): continue
		semantic_kinds[str(movement.get("destination_kind",""))] = true
		if bool(movement.get("stopped",false)): stop_frames += 1
		if car.trip != last_trip:
			completed_trips += 1
			last_trip = car.trip
	_check(completed_trips >= 3,"car completes several purposeful trips")
	_check(stop_frames >= 3,"car has repeated destination pauses")
	_check(semantic_kinds.size() >= 2,"car visits more than one destination role")

	var walker := Traveler.new("walker",0)
	walker.advance(world,0.0)
	var target_sequence: Array[String] = [str(walker.walk_target)]
	var last_walker_trip := walker.trip
	for step in range(1,2401):
		walker.advance(world,float(step)*0.1)
		if walker.trip != last_walker_trip:
			target_sequence.append(str(walker.walk_target))
			last_walker_trip = walker.trip
	_check(target_sequence.size() >= 4,"walker completes several destination journeys")
	var immediate_repeat := false
	for i in range(2,target_sequence.size()):
		if target_sequence[i] == target_sequence[i-2]: immediate_repeat = true
	_check(not immediate_repeat,"walker avoids immediate destination ping-pong")
	var saved := walker.snapshot()
	var restored := Traveler.new("walker",0)
	restored.restore(saved)
	_check(restored.previous_walk_target == walker.previous_walk_target,"walker journey memory survives snapshot")

	print("TRANSPORT_DWELL ",JSON.stringify({"passed":failures.is_empty(),"car_trips":completed_trips,"car_stop_frames":stop_frames,"roles":semantic_kinds,"walker_targets":target_sequence.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
