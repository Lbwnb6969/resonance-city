extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")

var failures: Array[String] = []
var checks: Dictionary = {}

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000075",true,"river_valley")
	world.build_expanded_town()
	var bus := Traveler.new("bus",0)
	var first: Dictionary = bus.advance(world,0.0)
	check(not first.is_empty() and not str(first.get("stop_id","")).is_empty(),"bus announces its current stop")
	check(int(first.get("passengers",0)) > 0 and int(first.get("passengers",0)) < int(first.get("capacity",0)),"bus boards a deterministic nonzero load")
	var stop_count := 0
	var loads: Array[int] = []
	var previous_stop: String = str(first.get("stop_id",""))
	var previous: Vector2 = first.get("position",Vector2.ZERO)
	var max_step := 0.0
	for step in range(1,2401):
		var result: Dictionary = bus.advance(world,float(step)*0.1)
		if result.is_empty(): continue
		max_step = maxf(max_step,Vector2(result["position"]).distance_to(previous))
		previous = result["position"]
		var current_stop: String = str(result.get("stop_id",""))
		if current_stop != previous_stop:
			stop_count += 1
			previous_stop = current_stop
			loads.append(int(result.get("passengers",0)))
	check(stop_count >= 2,"bus reaches multiple stops instead of teleporting")
	check(loads.all(func(load: int) -> bool: return load > 0 and load < 12),"each stop has a bounded passenger load")
	check(max_step <= 0.181,"boarding dwell does not create a position jump")
	var access: Dictionary = world.network.access(bus.position)
	var road: String = str(access.get("road",""))
	var blocker: Array = [{"kind":"bus","ordinal":0,"position":bus.position+bus.direction.normalized()*0.24,
		"direction":bus.direction,"road":road,"priority":0}]
	var follower := Traveler.new("bus",7)
	follower.position = bus.position
	follower.direction = bus.direction
	var capped: float = follower._traffic_distance(world,0.20,blocker)
	check(not road.is_empty() and capped < 0.20,"same-road follower yields inside the safety gap")
	var saved: Dictionary = bus.snapshot()
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	check(restored.stop_id == bus.stop_id and restored.passenger_load == bus.passenger_load and restored.line_index == bus.line_index,"stop and passenger state survives traveler snapshot")
	print("TRAFFIC_BEHAVIOR ",JSON.stringify({"checks":checks,"failures":failures,"stops":stop_count,"loads":loads,"max_step":max_step,"capped":capped,"road":road}))
	quit(0 if failures.is_empty() else 1)
