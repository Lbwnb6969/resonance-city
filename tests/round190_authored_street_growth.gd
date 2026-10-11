extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const OUTPUT := "res://验证记录/round190_作者沿街成长/"
const SEED := "2026100900000062"
var checks: Dictionary = {}
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)
func _settle(city: World) -> void: city.settle((city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))
func _family_members(city: World,family: String) -> Array:
	return city.buildings.filter(func(house: Dictionary) -> bool: return str(house["family_id"]) == family)
func _view(city: World,family: String) -> Dictionary:
	var houses := _family_members(city,family)
	var rows: Array = []
	var worst_neighbor := 0.0
	var worst_road := 0.0
	var minimum_gap := INF
	var all_land := true
	var exclusion_clear := true
	var authored_ids: Array = houses.map(func(house: Dictionary) -> String: return str(house["district_id"]))
	var shared: Array = city.fabric_cache.get("shared_walls",[]).filter(func(wall: Dictionary) -> bool: return authored_ids.has(str(wall["a"])) and authored_ids.has(str(wall["b"])))
	for house: Dictionary in houses:
		var p := Vector2(float(house["position"][0]),float(house["position"][1]))
		var road := Fabric.nearest_road(city,p)
		var nearest := INF
		for other: Dictionary in houses:
			if other == house: continue
			var q := Vector2(float(other["position"][0]),float(other["position"][1]))
			nearest = minf(nearest,p.distance_to(q))
		for other: Dictionary in city.buildings:
			if other == house: continue
			var q := Vector2(float(other["position"][0]),float(other["position"][1]))
			minimum_gap = minf(minimum_gap,p.distance_to(q)-float(house["radius"])-float(other["radius"]))
		all_land = all_land and city.terrain.valid_footprint(city.building_polygon(p))
		exclusion_clear = exclusion_clear and Spatial.exclusion(city,city.building_polygon(p)).is_empty()
		if houses.size() > 1: worst_neighbor = maxf(worst_neighbor,nearest)
		worst_road = maxf(worst_road,float(road["gap"]))
		rows.append({"id":house["district_id"],"position":house["position"],"type":house["type"],"lot":house["lot_id"],"community":house["community_id"],"road":road["road"],"road_gap":road["gap"],"nearest_family":nearest if houses.size() > 1 else -1,"birth_frame":house["birth_frame"]})
	return {"phrase":city.phrase_index,"count":houses.size(),"city_count":city.buildings.size(),"houses":rows,"shared_walls":shared,"worst_family_neighbor":worst_neighbor,"worst_road_gap":worst_road,"minimum_building_gap":minimum_gap,"valid_land":all_land,"exclusion_clear":exclusion_clear}
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var opening := World.new(SEED,true,"river_valley")
	opening.build_first_composition_starter()
	var frame := int(opening.cfg["timing"]["phrase_frames"])
	var public_site: Dictionary = First.opportunities(opening)["public_candidates"][0]
	check(bool(opening.request({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":["infill_pulse"]},frame).get("accepted",false)),"actual_compact_charter_and_variation")
	check(bool(opening.request({"kind":"civic","position":public_site["position"]},frame).get("accepted",false)),"actual_player_cultural_anchor")
	_settle(opening)
	var source := opening.snapshot()
	var position: Array = First.opportunities(opening)["seed_candidates"][0]["position"]
	var routes: Dictionary = {}
	for expression: String in PlayerExpression.IDS:
		var city := World.new(SEED,false,"river_valley")
		city.restore(source)
		check(bool(city.request(PlayerExpression.operation(expression,position),frame*2).get("accepted",false)),expression+"_actual_seed_accepted")
		_settle(city)
		var family := ""
		for fid: String in city.families:
			if bool(city.families[fid].get("player_expression",false)): family = fid
		var history: Array = [_view(city,family)]
		while city.phrase_index < 8:
			_settle(city)
			history.append(_view(city,family))
		var final: Dictionary = history[-1]
		var preserved_clear := true
		for reservation: Dictionary in city.planning_reservations:
			for house: Dictionary in city.buildings:
				var p := Vector2(float(house["position"][0]),float(house["position"][1]))
				if Spatial.disc_hits(reservation["polygon"],p,float(house["radius"])): preserved_clear = false
		check(bool(final["valid_land"]) and bool(final["exclusion_clear"]) and float(final["minimum_building_gap"]) >= -0.000001,expression+"_all_actual_houses_keep_legal_land_and_clear_occupancy")
		check(_family_members(city,family).all(func(house: Dictionary) -> bool: return str(house["type"]) == ("commercial" if expression == "weave" else "residential")),expression+"_real_descendants_keep_route_use")
		check(preserved_clear and (city.planning_reservations.size() == 1 if expression == "warm" else city.planning_reservations.is_empty()),expression+"_real_reservation_stays_clear")
		check(float(final["worst_family_neighbor"]) <= 1.15 and float(final["worst_road_gap"]) <= 1.35,expression+"_authored_houses_form_adjacent_road_frontage")
		check(int(final["city_count"]) >= 26 and int(final["city_count"]) <= 30,expression+"_two_minute_core_keeps_player_growth_visible")
		routes[expression] = {"family":family,"history":history,"final":final,"reservations":city.planning_reservations.duplicate(true)}
	check(int(routes["deep"]["final"]["count"]) >= 2 and int(routes["deep"]["final"]["count"]) < int(routes["weave"]["final"]["count"]),"deep_remains_slower_than_weave")
	check(routes["weave"]["final"]["shared_walls"].size() >= int(routes["weave"]["final"]["count"])-1 and routes["deep"]["final"]["shared_walls"].size() >= int(routes["deep"]["final"]["count"])-1,"actual_commercial_and_stone_family_roofs_join")
	# Compare unchanged ordinary families against the preserved source, without
	# adding a second production class or touching any player work.
	var reference_script := GDScript.new()
	reference_script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-11_作者沿街成长前/continuous_world.gd").replace("class_name ContinuousWorld","")
	var compiled := reference_script.reload() == OK
	var ordinary_identical := compiled
	if compiled:
		var reference: RefCounted = reference_script.new(SEED,true,"river_valley")
		var ordinary := World.new(SEED,true,"river_valley")
		reference.build_starter()
		ordinary.build_starter()
		for phrase in range(1,9):
			reference.settle(phrase*frame)
			ordinary.settle(phrase*frame)
			ordinary_identical = ordinary_identical and reference.snapshot() == ordinary.snapshot()
	check(ordinary_identical,"ordinary_family_eight_phrase_snapshots_match_preserved_source_exactly")
	var report := {"seed":SEED,"checks":checks,"failures":failures,"root_position":position,"routes":routes,"ordinary_reference_identical":ordinary_identical}
	var output := FileAccess.open(OUTPUT+"authored_street_growth.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	print("AUTHORED_STREET ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
