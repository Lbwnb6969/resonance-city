extends SceneTree
## The first composition is an ordinary young World; planning, maturation and
## player expressions are fulfilled by the same requests and growth as play.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const SEED := "2026100900000062"
const OUTPUT := "res://验证记录/round180_第一段作品/first_composition_model.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)
func _record(items: Array,id: String) -> Dictionary:
	for item in items:
		if str(item.get("id",item.get("district_id",""))) == id: return item
	return {}
func _settle(world: World) -> void: world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
func _world(snapshot: Dictionary) -> World:
	var world := World.new(SEED,false,"river_valley")
	world.restore(snapshot)
	return world
func _family(world: World,expression: String) -> Dictionary:
	for intent in world.families.values():
		if bool(intent.get("player_expression",false)) and str(intent.get("expression","")) == expression: return intent
	return {}
func _members(world: World,family: Dictionary) -> Array:
	if family.is_empty(): return []
	var root: Dictionary = world.by_id.get(str(family.get("root","")),{})
	return world.buildings.filter(func(house: Dictionary) -> bool: return str(house["family_id"]) == str(root.get("family_id","")))
func _houses(world: World) -> Array:
	var result: Array = []
	for house in world.buildings: result.append([house["district_id"],house["position"],house["current_midi"],house["type"],house["expression"],house["form"],house.get("player_expression",false)])
	return result
func _same_land(a: Dictionary,b: Dictionary) -> bool:
	if str(a.get("source_site_id","")) != str(b.get("source_site_id","")) or a.get("source_lot_ids",[]) != b.get("source_lot_ids",[]): return false
	if First.polygon(a["polygon"]) != First.polygon(b["polygon"]): return false
	return Vector2(float(a["position"][0]),float(a["position"][1])) == Vector2(float(b["position"][0]),float(b["position"][1]))
func _restore_models(model: Model,label: String = "new_opening") -> Array:
	var directory := "user://round180_first_composition_%d" % Time.get_ticks_usec()
	var captured := {"model":model.capture_state(),"renderer":{},"view":{"first_composition_mode":true}}
	var result: Array = []
	var binary := Archive.save(captured,"Round180 first composition",directory)
	if bool(binary.get("ok",false)):
		var loaded := Archive.read(str(binary["path"]))
		check(bool(loaded.get("ok",false)),"binary_"+label+"_and_pending_expression_read")
		if bool(loaded.get("ok",false)): result.append({"format":"binary","model":Model.from_state(loaded["city"]["model"])})
		DirAccess.remove_absolute(str(binary["path"]))
	else: check(false,"binary_"+label+"_and_pending_expression_read")
	var dna := Archive.export_dna(captured,directory)
	if bool(dna.get("ok",false)):
		var loaded := Archive.read_dna(str(dna["path"]))
		check(bool(loaded.get("ok",false)),"dna_"+label+"_and_pending_expression_read")
		if bool(loaded.get("ok",false)): result.append({"format":"dna","model":Model.from_state(loaded["model"])})
		DirAccess.remove_absolute(str(dna["path"]))
	else: check(false,"dna_"+label+"_and_pending_expression_read")
	DirAccess.remove_absolute(directory)
	return result
func _run() -> void:
	var city := World.new(SEED,true,"river_valley")
	var initial_rng := city.rng.snapshot()
	city.build_first_composition_starter()
	var snapshot := city.snapshot()
	var repeated := World.new(SEED,true,"river_valley")
	repeated.build_first_composition_starter()
	check(city.snapshot() == repeated.snapshot() and city.rng.snapshot() == initial_rng,"same_seed_opening_is_deterministic_without_growth_random_draws")
	var occupied: Array = []
	for cid in city.communities:
		if not city.communities[cid]["members"].is_empty(): occupied.append(str(cid))
	occupied.sort()
	check(city.phrase_index == 0 and city.buildings.size() == 24 and occupied == ["east-2","west-1","west-2"],"new_river_bend_starts_with_24_houses_and_exactly_three_populated_communities")
	check(city.buildings.all(func(house: Dictionary) -> bool: return str(house["form"]) == "胚" and int(house["form_count"]) == 0 and int(house["birth_frame"]) == 0 and float(house["vitality"]) == float(city.cfg["harmony"]["initial_vitality"])),"opening_houses_are_young_real_births_without_maturity_or_vitality_gifts")
	check(city.public_sites.all(func(site: Dictionary) -> bool: return not bool(site["active"])) and city.development_charters.is_empty() and city.authored_transit_lines.is_empty() and city.pending_actions.is_empty() and city.action_serial == 0 and city.events.all(func(event: Dictionary) -> bool: return str(event["kind"]) == "birth" and int(event["frame"]) == 0),"opening_has_no_free_facilities_charters_routes_or_preheated_settlement")
	check(occupied.all(func(cid: String) -> bool: return not bool(Rules.status(city,cid)["theme_eligible"]) and city.community_expression(cid) == "warm"),"initial_communities_have_no_mature_theme_and_default_warm_material")
	var opening_model := Model.new(city)
	check(opening_model.next_boundary == int(city.cfg["timing"]["phrase_frames"]) and opening_model.synth.score_snapshot().get("theme",{}).is_empty(),"audio_starts_at_the_first_real_boundary_without_a_fabricated_theme")
	var opportunity := First.opportunities(city)
	check(city.snapshot() == snapshot and opportunity["community_ids"] == ["west-1","west-2","east-2"] and opportunity["public_candidates"].size() == 3 and opportunity["seed_candidates"].size() == 3,"opportunities_query_only_the_current_world_without_committing_anything")
	var distinct := true
	for i in range(3):
		var public_site: Dictionary = opportunity["public_candidates"][i]
		var sound_site: Dictionary = opportunity["seed_candidates"][i]
		if not bool(public_site["allowed"]) or not bool(sound_site["allowed"]) or public_site["source_site_id"] == sound_site["lot_id"]: distinct = false
	check(distinct,"each_community_offers_different_legal_public_and_sound_lots")
	var copied := opportunity.duplicate(true)
	copied["seed_candidates"][0]["position"][0] += 1.0
	check(city.snapshot() == snapshot,"opportunity_data_does_not_alias_city_house_or_lot_positions")
	var plans: Dictionary = {}
	for plan: String in ["compact","corridor","bluegreen"]:
		var branch := _world(snapshot)
		var first_site: Dictionary = First.opportunities(branch)["public_candidates"][0]
		var frame := int(branch.cfg["timing"]["phrase_frames"])
		var charter := branch.request({"kind":"charter","plan_id":plan,"community_ids":["west-1"]},frame)
		var civic := branch.request({"kind":"civic","position":first_site["position"]},frame)
		check(bool(charter.get("accepted",false)) and bool(civic.get("accepted",false)),plan+"_uses_real_player_charter_and_facility_requests")
		var first_theme := 0
		for phrase in range(4):
			_settle(branch)
			if first_theme == 0 and bool(Rules.status(branch,"west-1")["theme_eligible"]) and bool(Rules.facilities(branch,"west-1")["civic"]): first_theme = branch.phrase_index
		var state := Rules.status(branch,"west-1")
		check(first_theme >= 2 and first_theme <= 4 and int(state["mature"]) >= 6 and bool(state["formed"]) and bool(Rules.facilities(branch,"west-1")["civic"]) and branch.buildings.size() > 24,plan+"_ordinary_two_to_four_phrases_fulfill_real_maturity_street_courtyard_and_culture_support")
		plans[plan] = {"first_theme_phrase":first_theme,"status":state,"buildings":branch.buildings.size(),"facility":Rules.facilities(branch,"west-1")}
	var grown := _world(snapshot)
	grown.request({"kind":"charter","plan_id":"compact","community_ids":["west-1"]},int(grown.cfg["timing"]["phrase_frames"]))
	grown.request({"kind":"civic","position":First.opportunities(grown)["public_candidates"][0]["position"]},int(grown.cfg["timing"]["phrase_frames"]))
	_settle(grown)
	var grown_snapshot := grown.snapshot()
	var grown_opportunities := First.opportunities(grown)
	check(grown_opportunities["seed_candidates"].size() == 3 and grown_opportunities["seed_candidates"][0]["community_id"] == "west-1" and grown_opportunities["seed_candidates"].all(func(site: Dictionary) -> bool: return bool(site["allowed"])) and grown.snapshot() == grown_snapshot,"first_real_public_anchor_and_natural_growth_keep_a_legal_sound_choice_in_each_community")
	var grown_position: Array = grown_opportunities["seed_candidates"][0]["position"]
	for expression: String in ["deep","weave","warm"]:
		var branch := _world(grown_snapshot)
		var queued := branch.request({"kind":"seed","position":grown_position,"midi":{"deep":36,"weave":60,"warm":48}[expression],"expression":expression,"player_expression":true},2*int(branch.cfg["timing"]["phrase_frames"]))
		check(bool(queued.get("accepted",false)),expression+"_remains_a_real_choice_after_the_first_anchor_fills_the_lots")
	var warm_model := Model.new(_world(grown_snapshot))
	var warm_request := warm_model.submit({"kind":"seed","position":grown_position,"midi":48,"expression":"warm","player_expression":true})
	var warm_pending: Dictionary = warm_model.world.pending_actions[0]
	var reserved_intent: Dictionary = warm_pending["expression_reservation"].duplicate(true)
	var reserve_center := Vector2(float(reserved_intent["position"][0]),float(reserved_intent["position"][1]))
	check(bool(warm_request.get("accepted",false)) and warm_model.world.pending_actions.size() == 1 and warm_model.world.action_serial == grown.action_serial+1 and str(reserved_intent["source_site_id"]).begins_with("expression-clear:") and Spatial.site_reason(warm_model.world,{"polygon":First.polygon(reserved_intent["polygon"])}).is_empty(),"warm_is_one_seed_intent_with_an_exact_legitimate_continuous_empty_footprint")
	var blocked_seed := warm_model.world.request({"kind":"seed","position":reserved_intent["position"],"midi":48},warm_model.next_boundary)
	check(not bool(blocked_seed.get("accepted",false)) and warm_model.world.pending_actions.size() == 1,"pending_warm_land_cannot_be_covered_by_a_second_seed")
	for entry: Dictionary in _restore_models(warm_model,"grown_continuous_land"):
		var restored: Model = entry["model"]
		var format := str(entry["format"])
		check(_same_land(restored.world.pending_actions[0]["expression_reservation"],reserved_intent) and restored.world.planning_reservations.is_empty(),format+"_restores_the_exact_private_pending_land_without_revealing_it_early")
		var old_lots := restored.world.lots.size()
		_settle(restored.world)
		var reservation: Dictionary = Spatial.reservation_at(restored.world,reserve_center)
		var family := _family(restored.world,"warm")
		check(reservation.size() > 0 and reservation.get("polygon",PackedVector2Array()) == First.polygon(reserved_intent["polygon"]) and Vector2(float(reservation["position"][0]),float(reservation["position"][1])) == reserve_center and family.get("expression_reservation_id","") == reservation.get("id","") and restored.world.planning_reservations.size() == 1 and restored.world.lots.size() == old_lots and _members(restored.world,family).size() == 1,format+"_warm_atomically_lands_one_actual_root_and_one_standard_reservation_without_fabricating_a_lot")
		for phrase in range(2): _settle(restored.world)
		var clear := restored.world.buildings.all(func(house: Dictionary) -> bool: return not Spatial.disc_hits(reservation["polygon"],Vector2(float(house["position"][0]),float(house["position"][1])),float(house["radius"])))
		var again := Model.from_state(restored.capture_state())
		check(clear and again.world.planning_reservations == restored.world.planning_reservations and again.world.families == restored.world.families,format+"_natural_growth_respects_the_land_and_landed_state_restores_again")
		var released := restored.world.request({"kind":"release_reservation","id":reservation["id"]},(restored.world.phrase_index+1)*int(restored.world.cfg["timing"]["phrase_frames"]))
		_settle(restored.world)
		check(bool(released.get("accepted",false)) and restored.world.planning_reservations.is_empty() and not _family(restored.world,"warm").is_empty(),format+"_standard_release_frees_the_real_land_without_erasing_the_authored_family")
	var expression_worlds: Dictionary = {}
	var expression_evidence: Dictionary = {}
	for expression: String in ["deep","weave","warm"]:
		var branch := _world(snapshot)
		var position: Array = First.opportunities(branch)["seed_candidates"][0]["position"]
		var pitch: int = {"deep":36,"weave":60,"warm":48}[expression]
		var queued := branch.request({"kind":"seed","position":position,"midi":pitch,"expression":expression,"player_expression":true},int(branch.cfg["timing"]["phrase_frames"]))
		_settle(branch)
		var family := _family(branch,expression)
		var members := _members(branch,family)
		check(bool(queued.get("accepted",false)) and members.size() == 1 and bool(family.get("player_expression",false)) and members[0].get("current_midi",0) == pitch and members[0].get("type","") == ("commercial" if expression == "weave" else "residential") and bool(members[0].get("player_expression",false)) and branch.community_expression("west-1") == expression,expression+"_seed_is_real_family_material_type_and_current_community_expression")
		_settle(branch)
		var second_count := _members(branch,family).size()
		check(second_count == 1 if expression == "deep" else second_count >= 2,expression+"_growth_respects_the_chosen_slow_or_normal_cadence")
		for i in range(2): _settle(branch)
		members = _members(branch,family)
		check(members.size() >= 2 and members.all(func(house: Dictionary) -> bool: return house["expression"] == expression and bool(house.get("player_expression",false)) and str(house["type"]) == ("commercial" if expression == "weave" else "residential")),expression+"_natural_descendants_keep_the_actual_expression_and_use")
		expression_worlds[expression] = branch
		expression_evidence[expression] = {"second_phrase_family_houses":second_count,"fourth_phrase_family_houses":members.size(),"root_midi":pitch,"root_type":members[0].get("type","") if not members.is_empty() else "","community_expression":branch.community_expression("west-1")}
	check(_members(expression_worlds["deep"],_family(expression_worlds["deep"],"deep")).size() < _members(expression_worlds["weave"],_family(expression_worlds["weave"],"weave")).size(),"same_seed_deep_and_weave_have_distinct_real_growth_and_land_use_consequences")
	var legacy_seed := _world(snapshot)
	var legacy_position: Array = First.opportunities(legacy_seed)["seed_candidates"][0]["position"]
	legacy_seed.request({"kind":"seed","position":legacy_position,"midi":36,"expression":"deep"},int(legacy_seed.cfg["timing"]["phrase_frames"]))
	_settle(legacy_seed)
	var legacy_family: Dictionary = legacy_seed.families.values()[-1]
	check(not bool(legacy_family.get("player_expression",false)) and int(legacy_family["next_growth_phrase"]) == legacy_seed.phrase_index+1 and legacy_seed.community_expression("west-1") == "warm","legacy_seed_without_flag_keeps_old_cadence_and_does_not_override_community_grammar")
	var before_invalid := city.snapshot()
	check(not bool(city.request({"kind":"seed","position":legacy_position,"midi":48,"expression":"unknown","player_expression":true},int(city.cfg["timing"]["phrase_frames"])).get("accepted",false)) and city.snapshot() == before_invalid,"unknown_player_expression_rejects_without_writing_world_or_pending")
	var pending_model := Model.new(_world(snapshot))
	for i in range(3):
		var expression: String = ["deep","weave","warm"][i]
		var position: Array = First.opportunities(pending_model.world)["seed_candidates"][i]["position"]
		pending_model.submit({"kind":"seed","position":position,"midi":{"deep":36,"weave":60,"warm":48}[expression],"expression":expression,"player_expression":true})
	var restored_models := _restore_models(pending_model)
	for entry: Dictionary in restored_models:
		var restored: Model = entry["model"]
		var format := str(entry["format"])
		check(restored.world.phrase_index == 0 and restored.next_boundary == int(city.cfg["timing"]["phrase_frames"]) and restored.world.pending_actions.size() == 3 and restored.world.public_sites.all(func(site: Dictionary) -> bool: return not bool(site["active"])),format+"_restores_a_new_young_city_and_three_pending_player_choices")
		var boundary := restored.next_boundary
		restored.render_block({},boundary-1,2,int(city.cfg["timing"]["sample_rate"]))
		check(_family(restored.world,"deep").get("player_expression",false) and _family(restored.world,"weave").get("player_expression",false) and _family(restored.world,"warm").get("player_expression",false) and restored.world.community_expression("west-1") == "deep" and restored.world.community_expression("west-2") == "weave" and restored.world.community_expression("east-2") == "warm",format+"_pending_choices_land_with_persisted_families_and_true_community_sources")
		var again := Model.from_state(restored.capture_state())
		check(_houses(again.world) == _houses(restored.world) and again.world.families == restored.world.families and again.world.rng.snapshot() == restored.world.rng.snapshot(),format+"_landed_expression_state_can_restore_again_without_an_opening_rebuild")
	var legacy := World.new(SEED,true,"river_valley")
	legacy.build_starter("bright")
	check(legacy.phrase_index == 0 and legacy.buildings.size() == 18 and legacy.public_sites.filter(func(site: Dictionary) -> bool: return bool(site["active"])).size() == 2 and legacy.community_expression("west-1") == "bright","old_starter_remains_an_independent_compatible_entry")
	var legacy_saved := Model.new(legacy).capture_state()
	check(Model.from_state(legacy_saved).world.snapshot() == legacy.snapshot(),"old_city_save_is_restored_without_conversion_to_the_new_opening")
	evidence = {"opening_houses":24,"populated_communities":occupied,"plans":plans,"expressions":expression_evidence,"scope":"Model and natural settlement evidence; no human enjoyment or listening judgment."}
	_finish()
func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND180_FIRST_COMPOSITION_MODEL "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
