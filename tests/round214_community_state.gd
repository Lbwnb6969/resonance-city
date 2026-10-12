extends SceneTree
## One production World/AudioModel contract; no Demo, GPU, or device playback.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Placement = preload("res://scripts/world/first_sound_placement.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Workbench = preload("res://scripts/world/community_workbench_state.gd")
const OUTPUT := "res://验证记录/round214_社区状态/state_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var model: ContinuousAudioModel
var state: Dictionary = {}
var rate: int

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _cross(frame: int) -> void:
	model.render_block(state,frame-1,2,rate)

func _query(frame: int,cid: String = "west-2") -> Dictionary:
	return Workbench.describe(model.presentation_world(frame),cid,frame,model.audible_pitches())

func _candidate(city: ContinuousWorld,key: String,cid: String) -> Dictionary:
	for candidate: Dictionary in First.opportunities(city)[key]:
		if str(candidate["community_id"]) == cid: return candidate
	return {}

func _finish() -> void:
	if model != null: model.close_background_settlement()
	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"One real 24-house starter, civic/warm/reserve/retune transactions and audible snapshots; read-only community query. No GPU/device, bulk tuning, SP6 completion, or human experience verdict."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("ROUND214_COMMUNITY_STATE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_only_no_device_playback")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	rate = int(city.cfg["timing"]["sample_rate"])
	var original := city.snapshot()
	var starters: Dictionary = {}
	var starter_ok := true
	var starter_ids: Array[String] = []
	for cid: String in First.COMMUNITY_IDS:
		var item := Workbench.describe(city,cid,0)
		starters[cid] = {"count":item["count"],"type_counts":item["type_counts"],"midi_counts":item["midi_counts"],"status":item["status"]}
		starter_ok = starter_ok and item["available"] and item["count"] == 8 and item["member_ids"].size() == 8 and item["authors"].is_empty() and item["reservations"].is_empty()
		var center := Vector2.ZERO
		for id: String in item["member_ids"]:
			starter_ok = starter_ok and city.by_id[id]["community_id"] == cid and not starter_ids.has(id)
			starter_ids.append(id)
			var p: Array = city.by_id[id]["position"]
			center += Vector2(float(p[0]),float(p[1]))
		starter_ok = starter_ok and item["center"].is_equal_approx(center/8.0) and item["status"]["theme_eligible"] == Rules.status(city,cid)["theme_eligible"]
	check(starter_ok and starter_ids.size() == 24 and city.snapshot() == original,"real_three_eight_house_communities_have_exact_members_centers_and_no_fake_authors")
	var empty := Workbench.describe(city,"west-3",0)
	var missing := Workbench.describe(city,"not-a-community",0)
	check(not empty["available"] and empty["count"] == 0 and empty["center"] == Vector2.ZERO and not missing["available"] and missing["member_ids"].is_empty(),"empty_and_invalid_communities_keep_an_empty_ui_contract")

	model = Model.new(city,1.3409036)
	var public_candidate := _candidate(city,"public_candidates","west-2")
	var civic := model.submit({"kind":"civic","position":public_candidate.get("position",[])})
	var civic_frame := model.next_boundary
	_cross(civic_frame)
	var raw_early := Workbench.describe(city,"west-2",civic_frame-1)
	var heard_early := _query(civic_frame-1)
	check(bool(civic.get("accepted",false)) and raw_early["public_sites"].is_empty() and heard_early["public_sites"].is_empty() and raw_early["status"]["mature"] == heard_early["status"]["mature"],"actual_civic_and_upgrade_maturity_are_hidden_before_the_heard_boundary")
	var civic_heard := _query(civic_frame)
	check(civic_heard["public_sites"].size() == 1 and civic_heard["public_sites"][0]["kind"] == "civic" and int(civic_heard["public_sites"][0]["frame"]) == civic_frame,"heard_active_civic_has_its_real_identity_and_commit_frame")

	var seed_candidate := _candidate(city,"seed_candidates","west-2")
	var recommendation := Placement.recommend(city,[seed_candidate],model.next_boundary)
	var warm := model.submit(PlayerExpression.operation("warm",recommendation.get("position",[0,0])))
	var warm_frame := model.next_boundary
	_cross(warm_frame)
	check(bool(warm.get("accepted",false)),"actual_warm_transaction_is_accepted_after_the_civic")
	if not bool(warm.get("accepted",false)): evidence["warm_request"] = warm; _finish(); return
	var old := _query(warm_frame-1)
	var raw_birth_early := Workbench.describe(city,"west-2",warm_frame-1)
	check(old["count"] == 8 and old["authors"].is_empty() and old["reservations"].is_empty() and raw_birth_early["member_ids"] == old["member_ids"] and raw_birth_early["authors"].is_empty() and raw_birth_early["reservations"].is_empty(),"render_ahead_birth_author_and_real_reservation_cannot_enter_the_workbench_early")
	var heard := _query(warm_frame)
	var root_id := str(heard["authors"][0]["root_id"]) if not heard["authors"].is_empty() else ""
	check(heard["count"] == 9 and heard["authors"].size() == 1 and heard["authors"][0]["expression"] == "warm" and heard["authors"][0]["current_midi"] == 48 and heard["reservations"].size() == 1 and heard["reservations"][0]["root_id"] == root_id and heard["reservations"][0]["frame"] == warm_frame,"heard_warm_root_and_family_owned_land_are_the_actual_transaction_results")
	if root_id.is_empty(): _finish(); return
	var expected_types: Dictionary = starters["west-2"]["type_counts"].duplicate()
	expected_types["residential"] = int(expected_types.get("residential",0))+1
	check(heard["authors"][0]["family_members"] == [root_id] and heard["member_ids"].size() > heard["authors"][0]["family_members"].size() and heard["authored_member_ids"] == [root_id] and heard["type_counts"] == expected_types,"player_source_family_is_distinct_from_the_mixed_nine_house_planning_community")

	var ordinary_candidate := _candidate(city,"public_candidates","west-1")
	var reserve := model.submit({"kind":"reserve","position":ordinary_candidate.get("position",[])})
	var reserve_frame := model.next_boundary
	_cross(reserve_frame)
	var after_growth := _query(reserve_frame)
	var western := _query(reserve_frame,"west-1")
	check(bool(reserve.get("accepted",false)) and city.planning_reservations.size() >= 2 and western["reservations"].is_empty() and western["authors"].is_empty() and after_growth["authors"].size() == 1 and after_growth["authors"][0]["family_members"].size() >= 2,"real_author_growth_stays_one_root_while_unrelated_reserved_land_is_not_claimed_as_player_sound")
	var qualified: bool = Rules.status(model.presentation_world(reserve_frame),"west-2")["theme_eligible"]
	var truthful_text: bool = after_growth["status_text"] == "主题可用" and after_growth["status"]["missing_conditions"].is_empty() if qualified else not after_growth["status"]["missing_conditions"].is_empty()
	check(after_growth["status"]["theme_eligible"] == qualified and truthful_text,"theme_qualification_and_short_missing_status_follow_production_music_rules")

	var shown := model.presentation_world(reserve_frame)
	var shown_before := shown.snapshot()
	var cache_before: Dictionary = shown.fabric_cache.duplicate(true)
	var inputs := model.audible_pitches().duplicate(true)
	var inputs_before := inputs.duplicate(true)
	var start := Time.get_ticks_usec()
	var observed := Workbench.describe(shown,"west-2",reserve_frame,inputs)
	var core_ms := float(Time.get_ticks_usec()-start)/1000.0
	for repeat in range(3): Workbench.describe(shown,"west-2",reserve_frame,inputs)
	check(shown.snapshot() == shown_before and shown.fabric_cache == cache_before and inputs == inputs_before,"repeated_queries_do_not_write_world_rng_pending_geometry_or_audible_pitches")
	observed["authors"][0]["current_midi"] = 99
	observed["public_sites"][0]["name"] = "mutated output"
	observed["reservations"][0]["polygon"][0] += Vector2(99,99)
	observed["member_ids"].clear()
	check(shown.snapshot() == shown_before and Workbench.describe(shown,"west-2",reserve_frame,inputs) == after_growth,"ui_owned_return_records_cannot_mutate_source_world")
	var copy: RefCounted = shown.fork()
	var copy_before: Dictionary = copy.snapshot()
	check(Workbench.describe(copy,"west-2",reserve_frame,inputs) == after_growth and copy.snapshot() == copy_before and shown.snapshot() == shown_before,"fork_has_the_same_heard_community_without_identity_or_rng_changes")

	var membership: Array[String] = after_growth["member_ids"].duplicate()
	var root_cid := str(city.by_id[root_id]["community_id"])
	var retune := model.submit({"kind":"retune","id":root_id,"midi":50})
	var beat := int(retune.get("sound_frame",-1))
	var unrendered := _query(reserve_frame)
	check(bool(retune.get("accepted",false)) and beat > reserve_frame and unrendered["authors"][0]["current_midi"] == 48,"queued_unheard_retune_does_not_change_workbench_pitch")
	_cross(beat)
	var before_beat := _query(beat-1)
	var at_beat := _query(beat)
	check(before_beat["authors"][0]["current_midi"] == 48 and at_beat["authors"][0]["current_midi"] == 50 and int(at_beat["midi_counts"].get(50,0)) == 1 and at_beat["member_ids"] == membership and str(city.by_id[root_id]["community_id"]) == root_cid and city.by_id[root_id]["current_midi"] == 48,"heard_pitch_override_updates_counts_and_author_without_changing_planning_membership_or_structure_early")
	var commit_frame := model.next_boundary
	_cross(commit_frame)
	var committed := _query(commit_frame)
	check(city.by_id[root_id]["current_midi"] == 50 and committed["authors"][0]["current_midi"] == 50 and committed["id"] == root_cid and committed["member_ids"].has(root_id),"real_retune_commit_preserves_the_community_and_authored_root")
	evidence = {"starter":starters,"civic_frame":civic_frame,"warm_frame":warm_frame,"root_id":root_id,"heard_family_members":after_growth["authors"][0]["family_members"],
		"heard_community_count":after_growth["count"],"civic_id":after_growth["public_sites"][0]["id"],"reservation_id":after_growth["reservations"][0]["id"],
		"retune_sound_frame":beat,"retune_structure_frame":commit_frame,"core_describe_ms":core_ms,"only_playback_driver":"Dummy"}
	_finish()
