extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var checks := {}
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000065")
	world.build_town()
	check(world.era == 1 and world.vehicle_kind() == "carriage","Classical era starts with horse carriages")
	check(world.transit_lines.size() == 2,"Classical public lines remain available")
	var carriage := Traveler.new("carriage",0)
	var first := carriage.advance(world,0.0)
	check(not first.is_empty() and carriage.kind == "carriage","Carriage follows a real line")
	var start := carriage.position
	carriage.advance(world,18.0)
	check(carriage.position.distance_to(start) > 0.01,"Carriage moves along the road")
	world.phrase_index = 12
	check(world.update_era(123),"Era advances at a musical boundary")
	check(world.era == 2 and world.vehicle_kind() == "carriage","Medieval era keeps carriage")
	world.phrase_index = 24
	world.update_era(456)
	check(world.era == 3 and world.vehicle_kind() == "carriage","Renaissance era keeps carriage")
	world.phrase_index = 36
	world.update_era(789)
	check(world.era == 4 and world.vehicle_kind() == "tram","Industrial era introduces tram")
	world.phrase_index = 48
	world.update_era(999)
	check(world.era == 5 and world.vehicle_kind() == "bus","Modern era introduces bus")
	var restored := World.new(world.rng.seed_hex,false)
	restored.restore(world.snapshot())
	check(restored.era == 5 and restored.vehicle_kind() == "bus","Era persists through city snapshot")
	print(JSON.stringify({"checks":checks,"failures":failures,"era":world.era,"vehicle":world.vehicle_kind(),"buildings":world.buildings.size(),"lines":world.transit_lines.size()}))
	if not failures.is_empty(): quit(1)
	quit(0)
