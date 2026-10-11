extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
func _initialize() -> void:
	call_deferred("_run")

var checks: Dictionary = {}
var evidence: Dictionary = {}
var failures: Array[String] = []
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	var rng := city.rng.snapshot()
	var lot_count := city.lots.size()
	var roads := city.roads.duplicate(true)
	city.build_first_composition_starter()
	var repeated := World.new("2026100900000062",true,"river_valley")
	repeated.build_first_composition_starter()
	check(city.snapshot() == repeated.snapshot() and city.rng.snapshot() == rng,"deterministic_without_new_random_draws")
	check(city.buildings.size() == 24 and city.phrase_index == 0 and city.public_sites.all(func(site: Dictionary) -> bool: return not bool(site["active"])) and city.pending_actions.is_empty(),"24_young_houses_phrase_zero_no_prebuilt_public_or_pending")
	check(city.buildings.all(func(house: Dictionary) -> bool: return str(house["form"]) == "胚" and int(house["birth_frame"]) == 0 and int(house["form_count"]) == 0 and float(house["vitality"]) == float(city.cfg["harmony"]["initial_vitality"])),"all_real_births_without_maturity_or_vitality_gifts")
	check(city.lots.size() == lot_count and city.roads == roads,"existing_lots_roads_and_transport_geometry_preserved")
	var snapshot := city.snapshot()
	var opportunities := First.opportunities(city)
	check(opportunities["public_candidates"].size() == 3 and opportunities["seed_candidates"].size() == 3 and city.snapshot() == snapshot,"three_current_public_and_sound_opportunities_without_query_mutation")
	var layout: Dictionary = {}
	for cid: String in First.COMMUNITY_IDS:
		var rows: Array = []
		var max_neighbor := 0.0
		var min_distance := INF
		var bounds := Rect2()
		for house: Dictionary in city.buildings:
			if str(house["community_id"]) != cid: continue
			var p := Vector2(float(house["position"][0]),float(house["position"][1]))
			bounds = Rect2(p,Vector2.ZERO) if rows.is_empty() else bounds.expand(p)
			rows.append({"id":house["district_id"],"lot":house["lot_id"],"p":house["position"],"type":house["type"]})
			var nearest := INF
			for other: Dictionary in city.buildings:
				if str(other["community_id"]) != cid or other == house: continue
				var q := Vector2(float(other["position"][0]),float(other["position"][1]))
				nearest = minf(nearest,p.distance_to(q))
			min_distance = minf(min_distance,nearest)
			max_neighbor = maxf(max_neighbor,nearest)
		check(rows.size() == 8 and max_neighbor <= 1.05 and min_distance >= 0.9 and bounds.size.x < 3.2 and bounds.size.y < 4.0,cid+"_eight_legal_houses_in_compact_adjacent_street_segments")
		layout[cid] = {"houses":rows,"nearest_neighbor_max":max_neighbor,"nearest_neighbor_min":min_distance,"bounds_size":[bounds.size.x,bounds.size.y]}
	var paths: Array = []
	for cid: String in First.COMMUNITY_IDS:
		for kind: String in ["park","civic"]:
			var branch := World.new("2026100900000062",false,"river_valley")
			branch.restore(snapshot)
			var public_site: Dictionary = {}
			for item: Dictionary in First.opportunities(branch)["public_candidates"]:
				if str(item["community_id"]) == cid: public_site = item
			var frame := int(branch.cfg["timing"]["phrase_frames"])
			var charter: Dictionary = branch.request({"kind":"charter","plan_id":"compact","community_ids":[cid]},frame)
			var public_action: Dictionary = branch.request({"kind":kind,"position":public_site["position"]},frame)
			branch.settle(frame)
			var sound_site: Dictionary = {}
			var remaining_lots: Array = []
			for lot: Dictionary in branch.lots:
				if str(lot["community_id"]) != cid or not str(lot["occupant"]).is_empty(): continue
				var raw: Array = lot["center"]
				remaining_lots.append({"id":lot["id"],"placement":branch.placement(Vector2(float(raw[0]),float(raw[1])))})
			for item: Dictionary in First.opportunities(branch)["seed_candidates"]:
				if str(item["community_id"]) == cid: sound_site = item
			check(bool(charter.get("accepted",false)) and bool(public_action.get("accepted",false)) and branch.public_sites.any(func(site: Dictionary) -> bool: return bool(site["active"]) and str(site.get("source_site_id","")) == str(public_site["source_site_id"])) and not sound_site.is_empty(),cid+"_"+kind+"_charter_public_and_natural_growth_keep_a_real_sound_site")
			var expressions: Dictionary = {}
			for expression: String in ["deep","weave","warm"]:
				var expression_world := World.new("2026100900000062",false,"river_valley")
				expression_world.restore(branch.snapshot())
				var request: Dictionary = expression_world.request({"kind":"seed","position":sound_site.get("position",[]),"midi":{"deep":36,"weave":60,"warm":48}[expression],"expression":expression,"player_expression":true},frame*2)
				expressions[expression] = request
				check(bool(request.get("accepted",false)),cid+"_"+kind+"_"+expression+"_accepted_after_first_public_anchor")
			paths.append({"community":cid,"public_kind":kind,"public_position":public_site["position"],"houses_after_first_phrase":branch.buildings.size(),"new_houses":branch.buildings.slice(24),"remaining_lots":remaining_lots,"sound_site":sound_site,"expressions":expressions})
	evidence = {"seed":"2026100900000062","checks":checks,"failures":failures,"layout":layout,"shared_walls":city.fabric_cache["shared_walls"],"paths":paths}
	DirAccess.make_dir_recursive_absolute("res://验证记录/round188_核心街坊")
	var output := FileAccess.open("res://验证记录/round188_核心街坊/starter_street_layout.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(evidence,"\t"))
	print("STARTER_STREET ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
