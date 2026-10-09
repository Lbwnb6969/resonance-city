extends SceneTree
## Long-horizon probe for the 500–600 building target.
const World = preload("res://scripts/world/continuous_world.gd")
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000080",true,"river_valley")
	world.build_expanded_town()
	var start_buildings := world.buildings.size()
	var phrase_frames := int(world.cfg["timing"]["phrase_frames"])
	var milestones: Array = []
	for phrase in range(1,73):
		world.settle(phrase_frames*(phrase+1))
		if phrase % 6 == 0:
			milestones.append({"phrase":phrase,"buildings":world.buildings.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size()})
	check(start_buildings >= 90,"long horizon starts from authored expansion")
	check(world.buildings.size() >= 500,"sixty phrases reach five hundred buildings")
	check(world.buildings.size() <= 600,"sixty phrases stay inside the target envelope")
	check(world.fabric_cache.get("courtyards",[]).size() >= 40,"long horizon keeps readable courtyard geometry")
	print("LONG_SCALE_PROBE ",JSON.stringify({"failures":failures,"start_buildings":start_buildings,"buildings":world.buildings.size(),"communities":world.communities.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size(),"milestones":milestones}))
	quit(0 if failures.is_empty() else 1)
