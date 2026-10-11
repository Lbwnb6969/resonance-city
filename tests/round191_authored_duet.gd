extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Duet = preload("res://scripts/world/authored_duet.gd")
const River = preload("res://scripts/world/river_call_response.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const OUTPUT := "res://验证记录/round191_真实双社区空间/"
var checks: Dictionary = {}
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)
func _settle(city: World) -> void: city.settle((city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))
func _public(city: World,cid: String) -> Dictionary:
	for candidate: Dictionary in First.opportunities(city)["public_candidates"]:
		if str(candidate["community_id"]) == cid: return candidate
	return {}
func _sound(city: World,cid: String) -> Array:
	for candidate: Dictionary in First.opportunities(city)["seed_candidates"]:
		if str(candidate["community_id"]) == cid: return candidate["position"]
	return []
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var openings: Dictionary = {}
	for cid: String in First.COMMUNITY_IDS:
		var city := World.new("2026100900000062",true,"river_valley")
		city.build_first_composition_starter()
		var phrase := int(city.cfg["timing"]["phrase_frames"])
		city.request({"kind":"charter","plan_id":"compact","community_ids":[cid],"card_refs":["infill_pulse"]},phrase)
		city.request({"kind":"civic","position":_public(city,cid)["position"]},phrase)
		_settle(city)
		var first_position := _sound(city,cid)
		check(bool(city.request(PlayerExpression.operation("deep",first_position),phrase*2).get("accepted",false)),cid+"_first_real_author_accepted")
		_settle(city)
		var root := Duet.roots(city)[0]
		var before := city.snapshot()
		var opportunities: Array = Duet.candidates(city,str(root["root_id"]),"",12)
		check(not opportunities.is_empty(),cid+"_real_first_root_has_an_opposite_street_opportunity")
		check(city.snapshot() == before,cid+"_duet_query_is_read_only")
		var candidates_legal := true
		for candidate: Dictionary in opportunities:
			var raw: Array = candidate["position"]
			var p := Vector2(float(raw[0]),float(raw[1]))
			var source: Dictionary = city.by_id[str(candidate["source_member_id"])]
			var actual_bank := signf(p.x-city.terrain.river_x(p.y))
			var actual_source_bank := signf(float(source["position"][0])-city.terrain.river_x(float(source["position"][1])))
			if not bool(city.placement(p)["allowed"]) or actual_bank*actual_source_bank >= 0.0 or p.distance_to(Coupling.position_of(source)) >= 8.0 or float(candidate["near_house_distance"]) > 2.4 or candidate.has("midi"): candidates_legal = false
		check(candidates_legal,cid+"_candidates_use_real_legal_opposite_street_and_no_chosen_pitch")
		var opening := {"first_root":root,"initial_candidates":opportunities,"second_real_author":{},"relations":[]}
		if not opportunities.is_empty():
			var target := str(opportunities[0]["community_id"])
			var anchor := _public(city,target)
			check(not anchor.is_empty(),cid+"_opposite_public_anchor_exists")
			if not anchor.is_empty():
				city.request({"kind":"civic","position":anchor["position"]},phrase*3)
				_settle(city)
			var after_public := Duet.candidates(city,str(root["root_id"]),target,1)
			opening["after_public_candidates"] = after_public
			check(not after_public.is_empty(),cid+"_opposite_street_remains_legal_after_real_public_build")
			if not after_public.is_empty():
				var second_request: Dictionary = city.request(PlayerExpression.operation("weave",after_public[0]["position"]),phrase*4)
				check(bool(second_request.get("accepted",false)),cid+"_second_real_author_accepted")
				_settle(city)
				var roots := Duet.roots(city)
				var relations := Duet.relations(city)
				var actual_river := River.pairs(city)
				check(roots.size() == 2 and city.buildings.size() <= 30,cid+"_two_actual_authors_keep_small_city")
				check(not relations.is_empty() and relations.any(func(pair: Dictionary) -> bool: return bool(pair["qualified"])),cid+"_actual_authored_banks_form_existing_river_relation")
				var same_rules := true
				for pair: Dictionary in relations:
					if bool(pair["qualified"]) != actual_river.any(func(actual: Dictionary) -> bool: return actual["a"] == pair["a"] and actual["b"] == pair["b"] and is_equal_approx(float(actual["distance"]),float(pair["distance"]))): same_rules = false
				check(same_rules,cid+"_authored_relations_match_existing_river_rules")
				opening["second_real_author"] = roots[-1]
				opening["relations"] = relations
				opening["houses"] = city.buildings.size()
				var source_id := str(root["root_id"])
				var receiver_id := str(roots[-1]["root_id"])
				var receiver_family_id := str(roots[-1]["family_id"])
				var source_retune := city.request({"kind":"retune","id":source_id,"midi":40},phrase*5)
				var receiver_retune := city.request({"kind":"retune","id":receiver_id,"midi":69},phrase*5)
				check(bool(source_retune.get("accepted",false)) and bool(receiver_retune.get("accepted",false)),cid+"_real_E40_A69_choices_accepted")
				_settle(city)
				var source_ids: Array = city.community_theme_sources(cid)
				var reply := River.reply(city,{"cid":cid,"source_ids":source_ids},River.pairs(city))
				var source_index := source_ids.find(source_id)
				var actual_receiver := "" if reply.is_empty() or source_index < 0 else str(reply["receiver_ids"][source_index])
				opening["reply"] = {"source_id":source_id,"expected_receiver_id":receiver_id,"expected_receiver_family_id":receiver_family_id,"actual_receiver_id":actual_receiver,"source_index":source_index,"source_midi":city.by_id[source_id]["current_midi"],"receiver_midi":city.by_id[receiver_id]["current_midi"],"actual_receiver":city.by_id.get(actual_receiver,{}),"reply":reply}
				check(not actual_receiver.is_empty() and str(city.by_id.get(actual_receiver,{}).get("family_id","")) == receiver_family_id,cid+"_actual_reply_from_first_root_reaches_second_author_family")
		openings[cid] = opening
	var report := {"checks":checks,"failures":failures,"openings":openings}
	FileAccess.open(OUTPUT+"authored_duet.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("AUTHORED_DUET ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
