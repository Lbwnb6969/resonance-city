extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Grove = preload("res://scripts/visual/classical_grove_layout.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
var checks: Dictionary = {}
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var before := city.snapshot()
	var records := Grove.build(city)
	check(records.size() >= 10,"real_banks_supply_visible_natural_groves")
	check(records == Grove.build(city),"same_terrain_produces_stable_cluster_positions_and_scales")
	var clustered := 0
	var clear_parcels := true
	var clear_roads := true
	for record: Dictionary in records:
		var p: Vector2 = record["position"]
		if records.any(func(other: Dictionary) -> bool: return other["id"] != record["id"] and p.distance_to(other["position"]) < 1.75): clustered += 1
		for lot: Dictionary in city.lots:
			clear_parcels = clear_parcels and not Planning.disc_hits(lot["polygon"],p,0.4)
		for site: Dictionary in city.public_sites:
			clear_parcels = clear_parcels and not Planning.point_in_footprint(site,p)
		var access: Dictionary = city.network.access(p)
		clear_roads = clear_roads and (access.is_empty() or float(access["gap"]) >= 0.65)
	check(clustered >= ceili(records.size()*0.7),"most_trees_form_local_groves_instead_of_even_grid_spacing")
	check(clear_parcels and clear_roads,"tree_feet_clear_real_future_parcels_public_spaces_and_road_access")
	check(city.buildings.all(func(house: Dictionary) -> bool: return not Grove.clear(city,Vector2(float(house["position"][0]),float(house["position"][1])))),"actual_heard_houses_cannot_keep_a_decorative_tree_at_their_foot")
	check(not Grove.clear(city,city.terrain.water[0].lerp(city.terrain.water[-1],0.5)),"groves_cannot_extend_into_real_water")
	check(city.snapshot() == before,"natural_grove_queries_preserve_world_rng_occupancy_sound_and_archive_state")
	var output := "res://验证记录/round208_古典街景/grove_contract.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"count":records.size(),"clustered":clustered,"records":records},"\t")+"\n")
	print("ROUND208_GROVES ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," count=",records.size())
	quit(0 if failures.is_empty() else 1)
