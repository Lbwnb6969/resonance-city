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
	for family in families:
		var world := World.new("2026101000000067",true,family)
		check(world.terrain.family == family,"family selected: "+family)
		check(world.terrain.water.size() > 10 and world.terrain.buildable_ratio() >= 0.45,"continuous land/water contract: "+family)
		check(world.lots.size() >= 50 and world.communities.size() == 10,"playable planned city survives: "+family)
		var sample := world.terrain.river_width(14.0)
		widths[family] = sample
		var saved := world.snapshot()
		var restored := World.new("2026101000000067",false,family)
		restored.restore(saved)
		check(restored.terrain.family == family and restored.snapshot()["terrain_state"]["family"] == family,"snapshot restores family: "+family)
	check(widths["lake_basin"] > widths["river_valley"] and widths["forest_ridge"] < widths["river_valley"],"families change water geometry")
	print("TERRAIN_FAMILY ",JSON.stringify({"checks":checks,"failures":failures,"widths":widths}))
	quit(0 if failures.is_empty() else 1)
