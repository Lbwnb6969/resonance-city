extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)

func _run() -> void:
	var world := World.new("2026101000000106",true,"river_valley")
	world.build_expanded_town()
	world.era = 5
	var car := Traveler.new("car",0)
	var first_car: Dictionary = car.advance(world,0.0)
	_check(not first_car.is_empty(),"modern car is active in era five")
	_check(car.path.size() > 1 and not car.destination.is_empty(),"car receives a physical destination path")
	_check(car.destination_kind in ["commercial","mixed","workshop","transit","cultural","civic_green"],"car destination belongs to a functional center")
	_check(not car.purpose.is_empty(),"car carries a readable journey purpose")
	var car_destination := car.destination
	for step in range(1,1201): car.advance(world,float(step)*0.1)
	_check(car.destination != car_destination or car.trip > 1,"car completes and chooses another center trip")
	var saved := car.snapshot()
	var restored := Traveler.new("car",0)
	restored.restore(saved)
	_check(restored.destination_kind == car.destination_kind and restored.purpose == car.purpose,"car intent survives snapshot")
	var walker_kinds: Dictionary = {}
	for ordinal in range(4):
		var walker := Traveler.new("walker",ordinal)
		var result: Dictionary = walker.advance(world,0.0)
		walker_kinds[str(result.get("destination_kind",""))] = true
		_check(not str(result.get("purpose","")).is_empty(),"walker carries a journey purpose")
		_check(str(result.get("destination_kind","")) in ["market","garden","civic","home","local"],"walker uses a semantic destination")
		_check(walker.path.size() > 1,"walker follows a real walking path")
	var early := World.new("2026101000000107",true,"river_valley")
	early.build_expanded_town()
	early.era = 4
	var sleeping_car := Traveler.new("car",0)
	_check(sleeping_car.advance(early,0.0).is_empty(),"car remains absent before modern era")
	print("TRAVEL_INTENTS ",JSON.stringify({"passed":failures.is_empty(),"car_destination_kind":car.destination_kind,"car_purpose":car.purpose,"walker_kinds":walker_kinds,"car_trip":car.trip,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
