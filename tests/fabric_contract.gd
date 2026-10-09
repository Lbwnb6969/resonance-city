extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")

var checks := {}
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000066")
	world.build_town()
	check(world.fabric_cache.has("shared_walls") and world.fabric_cache.has("rows") and world.fabric_cache.has("courtyards"),"fabric cache is derived and present")
	check(world.fabric_cache.get("community_wall",{}).size() == world.communities.size(),"community wall tiers cover planned communities")
	var placement_world := World.new("2026101000000066")
	var all_tiered := true
	for building in world.buildings:
		all_tiered = all_tiered and str(building.get("placement_tier","")).begins_with("L")
	check(all_tiered,"every building stores a placement tier without changing identity")
	var lot: Dictionary = {}
	for candidate in placement_world.lots:
		if str(candidate["occupant"]).is_empty(): lot = candidate; break
	var lot_check := placement_world.placement(Vector2(lot["center"][0],lot["center"][1])) if not lot.is_empty() else {}
	check(not lot_check.is_empty() and lot_check["allowed"] and lot_check["tier"] == "L1" and str(lot_check["preview"]).contains("沿街"),"street frontage previews L1")
	var isolated := Vector2.ZERO
	var isolated_check: Dictionary = {}
	var tier_counts := {"L1":0,"L2":0,"L3":0}
	for y in range(-6,38):
		for x in range(-6,39):
			var candidate := Vector2(float(x)+0.37,float(y)+0.41)
			var result := placement_world.placement(candidate)
			if result["allowed"]:
				tier_counts[result["tier"]] = int(tier_counts.get(result["tier"],0))+1
			if result["allowed"] and result["tier"] == "L3" and isolated_check.is_empty():
				isolated = candidate
				isolated_check = result
	check(tier_counts["L2"] > 0,"legal side street land previews L2")
	check(not isolated_check.is_empty() and str(isolated_check["preview"]).contains("孤屋"),"legal open land previews L3 instead of being rejected")
	var before_seed := placement_world.buildings.size()
	var seed := placement_world.request({"kind":"seed","position":[isolated.x,isolated.y],"midi":48},9000)
	placement_world.settle(9000)
	check(seed["accepted"] and placement_world.buildings.size() == before_seed+1 and str(placement_world.buildings.back().get("placement_tier","")) == "L3","L3 seed commits and remains an independent building without a global size cap")
	var a := {"district_id":"a","position":[0.0,0.0],"radius":0.45,"type":"residential"}
	var b := {"district_id":"b","position":[1.0,0.0],"radius":0.45,"type":"residential"}
	var c := {"district_id":"c","position":[1.01,0.0],"radius":0.45,"type":"residential"}
	check(absf(Fabric.gap(a,b)-0.1) < 1e-6 and Fabric.gap(a,c) > 0.1,"shared wall threshold is 0.10")
	var ordinary := a.duplicate(true)
	var isolated_building := b.duplicate(true)
	isolated_building["placement_tier"] = "L3"
	var coupling := WorldCoupling.new()
	var plain := coupling.coefficient(ordinary,b)
	var solitary := coupling.coefficient(ordinary,isolated_building)
	check(solitary < plain and plain > 0.0,"L3 sigma consequence is acoustic attenuation only")
	check(ordinary["district_id"] == "a" and isolated_building["district_id"] == "b","fabric relation leaves building identity intact")
	print("FABRIC ",JSON.stringify({"checks":checks,"failures":failures,"buildings":world.buildings.size(),"l3":isolated if not isolated_check.is_empty() else []}))
	quit(0 if failures.is_empty() else 1)
