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
	bus.advance(world,0.0)
	var samples: Array[float] = []
	var headings: Array[Vector2] = []
	var stop_ids: Array[String] = []
	for step in range(1,181):
		var result: Dictionary = bus.advance(world,float(step)*0.1)
		if result.is_empty(): continue
		samples.append(bus.motion_speed)
		headings.append(result["direction"])
		stop_ids.append(str(result.get("stop_id","")))
	var cruise := bus._speed(world)
	var max_accel_step := 0.0
	for i in range(1,samples.size()):
		max_accel_step = maxf(max_accel_step,samples[i]-samples[i-1])
	check(samples.size() > 20,"bus produces continuous motion samples")
	check(samples.all(func(value: float) -> bool: return value >= -0.0001 and value <= cruise+0.0001),"speed stays within cruise limit")
	check(max_accel_step <= bus._acceleration()*0.1+0.001,"acceleration is bounded per frame")
	var min_heading_dot := 1.0
	for i in range(1,headings.size()):
		if stop_ids[i-1] != stop_ids[i]: continue
		var heading_dot := headings[i-1].dot(headings[i])
		min_heading_dot = minf(min_heading_dot,heading_dot)
	check(min_heading_dot > -0.25,"turning avoids instantaneous reverse")
	var saved: Dictionary = bus.snapshot()
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	check(is_equal_approx(restored.motion_speed,bus.motion_speed),"motion speed survives traveler snapshot")
	print("MOTION_REALISM ",JSON.stringify({"checks":checks,"failures":failures,"samples":samples.size(),"cruise":cruise,"max_accel_step":max_accel_step,"min_heading_dot":min_heading_dot}))
	quit(0 if failures.is_empty() else 1)
