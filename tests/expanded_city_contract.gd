extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")

var checks := {}
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000068",true,"river_valley")
	world.build_expanded_town()
	var phrase_frames := int(world.cfg["timing"]["phrase_frames"])
	world.settle(phrase_frames)
	world.settle(phrase_frames*2)
	check(world.expanded_plan,"expanded plan has stable state")
	check(world.communities.size() >= 26,"twenty-six planned communities")
	check(world.lots.size() >= 95,"expanded legal lot inventory")
	check(world.buildings.size() >= 90,"expanded town creates a larger playable start")
	check(world.buildings.size() > 100,"expanded city grows beyond the authored start after two phrases")
	check(world.roads.size() >= 30,"terrace roads are part of the road graph")
	var terrace_members := 0
	for cid in world.communities:
		if str(cid).contains("-terrace-") and not world.communities[cid]["members"].is_empty(): terrace_members += 1
	check(terrace_members >= 12,"most terrace communities have authored buildings")
	var saved := world.snapshot()
	var restored := World.new("2026101000000068",false,"river_valley")
	restored.restore(saved)
	check(restored.expanded_plan and restored.communities.size() == world.communities.size() and restored.buildings.size() == world.buildings.size(),"expanded plan survives snapshot")
	print("EXPANDED_CITY ",JSON.stringify({"checks":checks,"failures":failures,"buildings":world.buildings.size(),"lots":world.lots.size(),"roads":world.roads.size(),"communities":world.communities.size(),"terrace_members":terrace_members}))
	quit(0 if failures.is_empty() else 1)
