extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)

func _count_type(world: ContinuousWorld,kind: String) -> int:
	var count := 0
	for building in world.buildings:
		if str(building.get("type","")) == kind: count += 1
	return count

func _run() -> void:
	var world := World.new("2026101000000116",true,"river_valley")
	world.build_expanded_town()
	var initial_industrial := _count_type(world,"industrial")
	var initial_commercial := _count_type(world,"commercial")
	var initial_residential := _count_type(world,"residential")
	_check(initial_industrial >= 4,"industrial anchors exist")
	_check(initial_commercial >= 2,"commercial anchors exist")
	for phrase in range(36):
		world.settle((phrase+1)*int(world.cfg["timing"]["phrase_frames"]))
	var final_industrial := _count_type(world,"industrial")
	var final_commercial := _count_type(world,"commercial")
	var final_residential := _count_type(world,"residential")
	_check(final_industrial > initial_industrial,"industrial quota keeps growing")
	_check(final_commercial > initial_commercial,"commercial quota keeps growing near commercial anchors")
	_check(final_residential > initial_residential,"residential growth continues beside use quotas")
	var commercial_zone := world.functional_zones.filter(func(zone: Dictionary) -> bool: return str(zone.get("role","")) == "commercial")
	_check(not commercial_zone.is_empty(),"commercial functional zone remains derived")
	var commercial_count := 0
	for zone in commercial_zone:
		commercial_count += int(zone.get("building_count",0))
	_check(commercial_count >= final_commercial,"commercial zone counts actual commercial buildings")
	var restored: ContinuousWorld = world.fork()
	_check(_count_type(restored,"commercial") == final_commercial,"commercial quota result survives fork")
	print("LAND_USE_QUOTAS ",JSON.stringify({"passed":failures.is_empty(),"initial_industrial":initial_industrial,"final_industrial":final_industrial,"initial_commercial":initial_commercial,"final_commercial":final_commercial,"initial_residential":initial_residential,"final_residential":final_residential,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
