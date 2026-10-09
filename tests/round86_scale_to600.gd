extends SceneTree
## Long horizon follow-up: keep the expanding city inside the playable 500–600 band.
const World = preload("res://scripts/world/continuous_world.gd")
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000086",true,"river_valley")
	world.build_expanded_town()
	var start_buildings := world.buildings.size()
	var phrase_frames := int(world.cfg["timing"]["phrase_frames"])
	var reached_target_phrase := -1
	var milestones: Array = []
	var started := Time.get_ticks_usec()
	for phrase in range(1,91):
		world.settle(phrase_frames*(phrase+1))
		if phrase % 6 == 0:
			milestones.append({"phrase":phrase,"buildings":world.buildings.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size()})
		if reached_target_phrase < 0 and world.buildings.size() >= 580:
			reached_target_phrase = phrase
			break
	check(start_buildings >= 90,"scale follow-up starts from authored expansion")
	check(reached_target_phrase > 0,"scale follow-up reaches the 580-building playable band")
	check(world.buildings.size() <= 600,"scale follow-up stays below the 600-building target")
	check(world.communities.size() == 48,"scale follow-up keeps all planned communities")
	check(world.fabric_cache.get("courtyards",[]).size() >= 40,"scale follow-up keeps readable courtyard geometry")
	print("SCALE_TO_600 ",JSON.stringify({"failures":failures,"start_buildings":start_buildings,"buildings":world.buildings.size(),"communities":world.communities.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size(),"reached_target_phrase":reached_target_phrase,"elapsed_ms":roundf(float(Time.get_ticks_usec()-started)/1000.0),"milestones":milestones}))
	quit(0 if failures.is_empty() else 1)
