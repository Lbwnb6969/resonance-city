extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Terrain = preload("res://scripts/world/valley_terrain.gd")

var checks := {}
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	var families := Terrain.family_ids()
	var widths: Dictionary = {}
	var terrace_x: Dictionary = {}
	for family in families:
		var world := World.new("2026101000000067",true,family)
		check(world.terrain.family == family,"family selected: "+family)
		check(world.terrain.water.size() > 10 and world.terrain.buildable_ratio() >= 0.45,"continuous land/water contract: "+family)
		check(world.lots.size() >= 50 and world.communities.size() == 10,"playable planned city survives: "+family)
		var expanded := World.new("2026101000000067",true,family)
		expanded.expand_plan()
		check(expanded.communities.size() == 36 and expanded.roads.size() >= 90,"expanded road plan survives: "+family)
		check(expanded.green_corridors.size() == 2 and expanded.green_corridors.all(func(corridor: Dictionary) -> bool: return corridor["path"].size() >= 8),"greenways survive terrain family: "+family)
		terrace_x[family] = float(expanded.nodes["west-terrace-node-4"][0])
		var sample := world.terrain.river_width(14.0)
		widths[family] = sample
		var saved := world.snapshot()
		var restored := World.new("2026101000000067",false,family)
		restored.restore(saved)
		check(restored.terrain.family == family and restored.snapshot()["terrain_state"]["family"] == family,"snapshot restores family: "+family)
	check(widths["lake_basin"] > widths["river_valley"] and widths["forest_ridge"] < widths["river_valley"],"families change water geometry")
	check(terrace_x["lake_basin"] != terrace_x["river_valley"] and terrace_x["forest_ridge"] != terrace_x["river_valley"] and terrace_x["coastal_plain"] != terrace_x["river_valley"],"families change terrace road geometry")
	print("TERRAIN_FAMILY ",JSON.stringify({"checks":checks,"failures":failures,"widths":widths}))
	quit(0 if failures.is_empty() else 1)
