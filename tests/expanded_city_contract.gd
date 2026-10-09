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
	var authored_buildings := world.buildings.size()
	var phrase_frames := int(world.cfg["timing"]["phrase_frames"])
	world.settle(phrase_frames)
	world.settle(phrase_frames*2)
	check(world.expanded_plan,"expanded plan has stable state")
	check(world.communities.size() >= 26,"twenty-six planned communities")
	check(world.lots.size() >= 95,"expanded legal lot inventory")
	check(world.buildings.size() >= 90,"expanded town creates a larger playable start")
	check(world.buildings.size() > 100,"expanded city grows beyond the authored start after two phrases")
	check(world.roads.size() >= 30,"terrace roads are part of the road graph")
	check(world.transit_lines.size() == 3 and world.transit_lines.any(func(line: Dictionary) -> bool: return line["id"] == "terrace-line"),"expanded city adds a real terrace transit line")
	check(world.transit_lines.any(func(line: Dictionary) -> bool: return float(line["legs"][0]["length"]) > 0.0),"terrace transit has measured road legs")
	check(world.public_sites.size() >= 8,"expanded city adds terrain-aware parks and civic facilities")
	check(world.public_sites.any(func(site: Dictionary) -> bool: return str(site["id"]).contains("terrace-park")),"expanded city has green corridor parks")
	check(world.public_sites.any(func(site: Dictionary) -> bool: return str(site["id"]).contains("terrace-civic")),"expanded city has community civic facilities")
	check(world.green_corridors.size() == 2,"expanded city has one green corridor on each bank")
	check(world.green_corridors.all(func(corridor: Dictionary) -> bool: return bool(corridor["active"]) and corridor["path"].size() >= 8),"green corridors connect the terrace communities")
	check(world.centers.size() == 20,"expanded city has primary, secondary and terrace centers")
	check(world.center_rank("west-2") == 0 and world.center_rank("west-garden-1") == 1 and world.center_rank("west-terrace-1") == 2,"center hierarchy drives stable ranks")
	check(world.fabric_cache.get("courtyards",[]).size() >= 16,"expanded city forms readable courtyards")
	check(world.fabric_cache.get("courtyards",[]).all(func(court: Dictionary) -> bool: return court.get("polygon",PackedVector2Array()).size() >= 3 and float(court.get("clear_diameter",0.0)) >= 0.8),"courtyard geometry keeps the approved clear diameter")
	check(world.public_sites.all(func(site: Dictionary) -> bool: return bool(site["active"]) and site.has("covered")),"expanded public facilities have active service coverage")
	var terrace_members := 0
	for cid in world.communities:
		if str(cid).contains("-terrace-") and not world.communities[cid]["members"].is_empty(): terrace_members += 1
	check(terrace_members >= 12,"most terrace communities have authored buildings")
	var saved := world.snapshot()
	var restored := World.new("2026101000000068",false,"river_valley")
	restored.restore(saved)
	check(restored.expanded_plan and restored.communities.size() == world.communities.size() and restored.buildings.size() == world.buildings.size() and restored.green_corridors.size() == world.green_corridors.size() and restored.centers.size() == world.centers.size(),"expanded plan survives snapshot")
	print("EXPANDED_CITY ",JSON.stringify({"checks":checks,"failures":failures,"authored_buildings":authored_buildings,"buildings":world.buildings.size(),"lots":world.lots.size(),"roads":world.roads.size(),"communities":world.communities.size(),"public_sites":world.public_sites.size(),"courtyards":world.fabric_cache.get("courtyards",[]).size(),"terrace_members":terrace_members}))
	quit(0 if failures.is_empty() else 1)
