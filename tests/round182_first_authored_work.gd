extends SceneTree
## Actual World requests and eight ordinary settlements; score identity uses
## the production scheduler. PCM and the live UI are verified by other tasks.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Work = preload("res://scripts/world/first_authored_work.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Card = preload("res://scripts/world/planning_card.gd")
const Synth = preload("res://scripts/audio/continuous_synth.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const SEED := "2026100900000062"
const OUTPUT := "res://验证记录/round182_首作经营/first_authored_work.json"
var checks: Dictionary = {}
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)
func _settle(world: World) -> void: world.settle((world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"]))
func _position(world: World,kind: String,cid: String) -> Array:
	for item in First.opportunities(world)[kind]:
		if str(item["community_id"]) == cid: return item["position"].duplicate()
	return []
func _restore(saved: Dictionary) -> World:
	var world := World.new(SEED,false,"river_valley")
	world.restore(saved)
	return world
func _score(world: World) -> Dictionary:
	var synth := Synth.new(world.buildings)
	synth.score = world.cfg["score"]
	synth.update_city(world.buildings,{}, {},[])
	synth.configure_score(world)
	return synth.score_snapshot()
func _run() -> void:
	var source := World.new(SEED,true,"river_valley")
	source.build_first_composition_starter()
	check(Work.state(source,{"theme":{"cid":"east-2","source_ids":[]}}).is_empty(),"no_authored_family_returns_empty_even_when_an_unrelated_community_has_a_theme")
	var young := _restore(source.snapshot())
	young.request(PlayerExpression.operation("deep",_position(young,"seed_candidates","west-1")),int(young.cfg["timing"]["phrase_frames"]))
	check(Work.state(young,{}).is_empty(),"pending_sound_is_not_reported_as_a_surviving_authored_root")
	_settle(young)
	var young_state := Work.state(young,_score(young))
	check(not young_state["theme_eligible"] and not young_state["missing_conditions"].is_empty() and young_state["missing_conditions"] == Rules.opportunity(young,str(young_state["community_id"]),_score(young))["missing_conditions"],"young_authored_root_reports_the_existing_qualification_gaps")
	var offers := Card.choices(source,"compact")
	var chosen := "infill_pulse" if offers.has("infill_pulse") else str(offers[0])
	var civic_position := _position(source,"public_candidates","west-1")
	var frame := int(source.cfg["timing"]["phrase_frames"])
	var charter := source.request({"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":[chosen]},frame)
	var civic := source.request({"kind":"civic","position":civic_position},frame)
	_settle(source)
	var source_saved := source.snapshot()
	var sound_position := _position(source,"seed_candidates","west-1")
	check(bool(charter.get("accepted",false)) and bool(civic.get("accepted",false)) and not sound_position.is_empty() and source.development_charters[0]["card_refs"] == [chosen],"all_routes_share_the_same_seed_real_offered_card_civic_anchor_and_continuous_sound_position")
	var routes: Dictionary = {}
	var worlds: Dictionary = {}
	for choice: String in PlayerExpression.IDS:
		var world := _restore(source_saved)
		var queued := world.request(PlayerExpression.operation(choice,sound_position),2*frame)
		var history: Array = []
		for phrase in range(2,9):
			_settle(world)
			var score := _score(world)
			var before := world.snapshot()
			var state := Work.state(world,score)
			check(world.snapshot() == before,choice+"_state_query_keeps_world_and_random_stream_at_phrase_"+str(phrase))
			history.append({"phrase":phrase,"city_houses":world.buildings.size(),"work":state,"lead_cid":str(score.get("theme",{}).get("cid",""))})
		var state: Dictionary = history[-1]["work"]
		var members := world.buildings.filter(func(building: Dictionary) -> bool: return str(building["family_id"]) == str(state["family_id"]))
		check(bool(queued.get("accepted",false)) and state["root_id"] == str(world.families[state["family_id"]]["root"]) and state["community_id"] == str(world.by_id[state["root_id"]]["community_id"]) and state["expression"] == choice and int(state["family_houses"]) == members.size() and int(state["next_growth_phrase"]) == int(world.families[state["family_id"]]["next_growth_phrase"]),choice+"_eight_phrase_summary_keeps_the_real_root_family_community_and_growth_schedule")
		check(bool(state["theme_eligible"]) and int(state["mature"]) >= 6 and state["missing_conditions"].is_empty() and bool(state["civic_support"]),choice+"_authored_community_has_real_mature_theme_qualification_and_civic_support")
		check(members.all(func(building: Dictionary) -> bool: return str(building["type"]) == ("commercial" if choice == "weave" else "residential")),choice+"_descendant_land_use_is_the_existing_formal_expression_consequence")
		var score := _score(world)
		var restored := _restore(world.snapshot())
		check(Work.state(restored,score) == state,choice+"_restored_world_derives_the_same_author_without_new_saved_progress")
		worlds[choice] = world
		routes[choice] = {"history":history,"family_positions":members.map(func(building: Dictionary) -> Array: return building["position"].duplicate()),"final_score":score,"reservations":world.planning_reservations.duplicate(true)}
	check(int(routes["deep"]["history"][-1]["work"]["family_houses"]) < int(routes["weave"]["history"][-1]["work"]["family_houses"]),"eight_ordinary_phrases_keep_actual_slow_deep_versus_faster_commercial_weave_growth")
	check(not str(routes["warm"]["history"][-1]["work"]["reservation_id"]).is_empty() and worlds["warm"].planning_reservations.size() == 1 and worlds["deep"].planning_reservations.is_empty() and worlds["weave"].planning_reservations.is_empty(),"only_warm_keeps_its_actual_live_reserved_land_through_eight_phrases")
	var world: World = worlds["weave"]
	var authored := Work.state(world,_score(world))
	var root_id := str(authored["root_id"])
	var other_score := {"theme":{"cid":"east-2","source_ids":[world.communities["east-2"]["members"][0]]}}
	var other := Work.state(world,other_score)
	check(other["root_id"] == root_id and other["community_id"] == authored["community_id"] and other["theme_eligible"] and not other["theme_playing"] and not other["root_in_theme"],"rotating_theme_in_another_community_does_not_redirect_the_authored_work")
	var score := {"theme":{"cid":authored["community_id"],"source_ids":[root_id]},"muted_communities":{}}
	var own := Work.state(world,score)
	check(own["theme_playing"] and own["root_in_theme"],"root_in_theme_requires_the_actual_supplied_theme_source_identity")
	score["theme"]["source_ids"] = []
	check(Work.state(world,score)["theme_playing"] and not Work.state(world,score)["root_in_theme"],"a_community_theme_does_not_invent_a_missing_root_source")
	score["muted_communities"][authored["community_id"]] = true
	check(not Work.state(world,score)["theme_playing"],"muted_authored_community_is_not_claimed_as_audibly_playing")
	var current := int(authored["current_midi"])
	var heard := {root_id:current+4}
	var before := world.snapshot()
	var retuned := Work.state(world,score,heard)
	check(int(retuned["current_midi"]) == current+4 and int(retuned["base_midi"]) == current and retuned["retuned"] and world.snapshot() == before and heard[root_id] == current+4,"current_root_pitch_and_retune_status_use_the_caller_audible_pitch_without_mutating_world")
	retuned["position"][0] += 5.0
	retuned["missing_conditions"].append("test")
	check(world.snapshot() == before,"returned_position_and_qualification_arrays_do_not_alias_the_city")
	var reservation_id := str(Work.state(worlds["warm"],{})["reservation_id"])
	worlds["warm"].request({"kind":"release_reservation","id":reservation_id},9*frame)
	_settle(worlds["warm"])
	check(str(Work.state(worlds["warm"],{})["reservation_id"]).is_empty() and str(worlds["warm"].families[Work.state(worlds["warm"],{})["family_id"]]["expression_reservation_id"]) == reservation_id,"released_land_is_not_reported_as_live_even_while_family_provenance_is_preserved")
	var latest_world := _restore(world.snapshot())
	var next_position := _position(latest_world,"seed_candidates","east-2")
	latest_world.request(PlayerExpression.operation("deep",next_position),9*frame)
	check(Work.state(latest_world,{})["root_id"] == root_id,"a_new_pending_family_does_not_replace_the_surviving_author_before_settlement")
	_settle(latest_world)
	var latest := Work.state(latest_world,{})
	check(latest["root_id"] != root_id and latest["community_id"] == "east-2" and latest["expression"] == "deep","latest_surviving_authored_root_is_selected_from_actual_settled_families")
	latest_world._remove_building_for_landmark(str(latest["root_id"]),"contract-removed-root")
	check(Work.state(latest_world,{})["root_id"] == root_id,"a_stale_missing_root_cannot_hide_the_previous_surviving_authored_work")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"seed":SEED,"plan":"compact","card":chosen,"civic_position":civic_position,"sound_position":sound_position,"routes":routes,"scope":"World growth and score-source identity only; full PCM and player-facing operation are verified separately."}}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	var summary: Dictionary = {}
	for choice: String in routes: summary[choice] = routes[choice]["history"][-1]
	print("ROUND182_FIRST_AUTHORED_WORK "+JSON.stringify({"passed":report["passed"],"checks":checks.size(),"failures":failures,"card":chosen,"routes":summary}))
	quit(0 if failures.is_empty() else 1)
