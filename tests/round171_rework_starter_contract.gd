extends SceneTree
## Round 171: the playable rework opening is exactly the existing starter plus
## two real settlements. Mature theme eligibility comes from that real city;
## the entry never fabricates a charter, public facility or tuning operation.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const SEED := "2026100900000062"

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _pitch_map(world: World) -> Dictionary:
	var result: Dictionary = {}
	for building in world.buildings:
		result[str(building["district_id"])] = [int(building["base_midi"]),int(building["current_midi"])]
	return result

func _facility_intent(world: World) -> Array:
	var result: Array = []
	for site in world.public_sites:
		result.append({"id":str(site["id"]),"kind":str(site["kind"]),"active":bool(site["active"]),"frame":int(site.get("frame",0))})
	return result

func _legal_vacant_count(world: World) -> int:
	var result := 0
	for lot in world.lots:
		if not str(lot.get("occupant","" )).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if bool(world.placement(p).get("allowed",false)): result += 1
	return result

func _eligible_ids(world: World) -> Array[String]:
	var result: Array[String] = []
	for raw_cid in world.communities:
		var cid := str(raw_cid)
		var status: Dictionary = MusicRules.status(world,cid)
		if bool(status.get("theme_eligible",false)): result.append(cid)
	result.sort()
	return result

func _saved_runtime_keeps_opening(restored: Model,source: Model) -> bool:
	return restored.world.phrase_index == source.world.phrase_index \
		and restored.next_boundary == source.next_boundary \
		and restored.rendered_until == source.rendered_until \
		and _pitch_map(restored.world) == _pitch_map(source.world) \
		and _facility_intent(restored.world) == _facility_intent(source.world) \
		and JSON.stringify(restored.world.rng.snapshot()) == JSON.stringify(source.world.rng.snapshot()) \
		and _eligible_ids(restored.world) == _eligible_ids(source.world) \
		and restored.world.development_charters.is_empty() and restored.decisions.is_empty()

func _run() -> void:
	var manual := World.new(SEED,true,"river_valley")
	manual.build_starter("bright")
	var original_pitches := _pitch_map(manual)
	var original_facilities := _facility_intent(manual)
	var original_count := manual.buildings.size()
	var phrase := int(manual.cfg["timing"]["phrase_frames"])
	for index in range(2): manual.settle((manual.phrase_index+1)*phrase)
	var opening := World.new(SEED,true,"river_valley")
	opening.build_rework_starter("bright")
	check(opening.snapshot() == manual.snapshot(),"opening_matches_two_manual_real_settlements")
	check(opening.rng.snapshot() == manual.rng.snapshot(),"opening_keeps_exact_manual_random_streams")
	check(opening.rng.seed_hex == SEED and opening.terrain.family == "river_valley","opening_uses_production_seed_and_terrain")
	check(opening.phrase_index == 2 and opening.buildings.size() > original_count,"opening_contains_two_phrases_of_real_growth")
	check(original_pitches.keys().all(func(raw_id: Variant) -> bool:
		var id := str(raw_id)
		return opening.by_id.has(id) and [int(opening.by_id[id]["base_midi"]),int(opening.by_id[id]["current_midi"])] == original_pitches[id]
	),"opening_does_not_retune_existing_houses")
	check(_facility_intent(opening) == original_facilities,"opening_does_not_invent_or_activate_extra_public_facilities")
	check(opening.action_serial == 0 and opening.pending_actions.is_empty() and opening.pending.is_empty(),"opening_has_no_fabricated_player_operations")
	check(opening.development_charters.is_empty() and opening.planning_reservations.is_empty() and opening.authored_transit_lines.is_empty(),"opening_has_no_fabricated_charter_reservation_or_route")
	var forbidden := ["charter","retune","reserve","release_reservation","relocate_public","park","civic","bridge","transit_line"]
	check(not opening.events.any(func(event: Dictionary) -> bool: return forbidden.has(str(event.get("kind","")))),"opening_events_only_include_real_growth_and_natural_state_changes")
	check(opening.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "birth" and int(event.get("frame",-1)) >= phrase),"opening_retains_real_boundary_growth_events")
	var eligible := _eligible_ids(opening)
	check(not eligible.is_empty(),"opening_has_real_mature_theme_eligibility")
	check(eligible.all(func(cid: String) -> bool:
		var status: Dictionary = MusicRules.status(opening,cid)
		return bool(status.get("formed",false)) and int(status.get("mature",0)) >= 6 and int(status.get("courtyards",0)) > 0
	),"theme_eligibility_comes_from_mature_street_and_courtyard_conditions")
	var vacant_count := _legal_vacant_count(opening)
	check(vacant_count > 0,"opening_keeps_legal_vacant_ground_for_player_planning")

	var model := Model.new(opening)
	var rate := int(opening.cfg["timing"]["sample_rate"])
	var start := opening.phrase_index*phrase
	check(model.world.phrase_index == 2 and model.next_boundary == start+phrase,"audio_model_starts_from_opening_phrase_with_next_real_boundary")
	check(model.decisions.is_empty() and model.sound_events.is_empty() and model.sound_overrides.is_empty(),"audio_model_has_no_fabricated_tuning_or_planning_decisions")
	var score: Dictionary = model.synth.score_snapshot()
	var theme_cid := str(score.get("theme",{}).get("cid",""))
	check(not theme_cid.is_empty() and eligible.has(theme_cid),"initial_score_schedules_a_really_qualified_community_theme")
	check(not theme_cid.is_empty() and score.get("theme",{}).get("notes",[]) == opening.community_theme(theme_cid),"initial_theme_uses_real_house_pitch_order")
	var initial_pcm: PackedVector2Array = model.render_block({},start,64,rate)
	check(initial_pcm.size() == 64 and model.rendered_until == start+64 and opening.phrase_index == 2,"opening_audio_can_start_without_replaying_old_growth_boundaries")

	# One small save/read per format proves the new entry is ordinary world
	# state. It does not add a special save schema or synthetic opening marker.
	var directory := "user://round171_rework_starter_%d" % Time.get_ticks_usec()
	var state: Dictionary = model.capture_state()
	var city := {"model":state,"renderer":{},"view":{"expression":"bright","starter":true}}
	var binary := Archive.save(city,"Round171 isolated contract",directory)
	check(bool(binary.get("ok",false)),"opening_binary_save_writes")
	if bool(binary.get("ok",false)):
		var loaded := Archive.read(str(binary["path"]))
		check(bool(loaded.get("ok",false)) and loaded.get("city",{}).get("model",{}) == state,"opening_binary_save_reads_exact_runtime_state")
		if bool(loaded.get("ok",false)):
			check(_saved_runtime_keeps_opening(Model.from_state(loaded["city"]["model"]),model),"opening_binary_restore_keeps_maturity_random_streams_and_audio_cursor")
		DirAccess.remove_absolute(str(binary["path"]))
	var dna := Archive.export_dna(city,directory)
	check(bool(dna.get("ok",false)),"opening_dna_export_writes")
	if bool(dna.get("ok",false)):
		var imported := Archive.read_dna(str(dna["path"]))
		check(bool(imported.get("ok",false)),"opening_dna_reads_ordinary_runtime")
		if bool(imported.get("ok",false)):
			check(_saved_runtime_keeps_opening(Model.from_state(imported["model"]),model),"opening_dna_restore_keeps_maturity_random_streams_and_audio_cursor")
		DirAccess.remove_absolute(str(dna["path"]))
	DirAccess.remove_absolute(directory)

	var boundary := model.next_boundary
	var boundary_pcm: PackedVector2Array = model.render_block({},boundary-1,2,rate)
	manual.settle(boundary)
	check(boundary_pcm.size() == 2 and opening.phrase_index == 3 and model.next_boundary == boundary+phrase,"first_official_boundary_continues_real_growth_and_audio")
	check(opening.snapshot() == manual.snapshot() and opening.rng.snapshot() == manual.rng.snapshot(),"first_official_boundary_keeps_manual_settlement_world_and_randomness")
	print("ROUND171_REWORK_STARTER_CONTRACT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"seed":SEED,"opening_buildings":state["world"]["buildings"].size(),"eligible_communities":eligible,"legal_vacant_lots":vacant_count}))
	quit(0 if failures.is_empty() else 1)
