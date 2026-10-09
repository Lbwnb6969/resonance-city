extends SceneTree
## Long-horizon scale probe: verifies that the 48-community plan reaches the
## lower bound of the intended 400–600 building city without a fixed cap.
const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000077",true,"river_valley")
	world.build_expanded_town()
	var start_buildings := world.buildings.size()
	var phrase_frames := int(world.cfg["timing"]["phrase_frames"])
	check(world.communities.size() == 48,"scale plan keeps forty-eight communities")
	check(start_buildings >= 90,"scale probe has a substantial authored start")
	for phrase in range(1,37):
		world.settle(phrase_frames*(phrase+1))
	check(world.buildings.size() >= 400,"thirty-six phrases continue organic growth past 400 buildings")
	check(world.fabric_cache.get("courtyards",[]).size() >= 40,"long growth keeps readable courtyard geometry")
	print("SCALE_PROBE ",JSON.stringify({"failures":failures,"start_buildings":start_buildings,"buildings":world.buildings.size(),"communities":world.communities.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size()}))
	quit(0 if failures.is_empty() else 1)
