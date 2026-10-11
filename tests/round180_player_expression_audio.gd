extends SceneTree
## Real full-score candidates, compared with the same formal transaction.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Preview = preload("res://scripts/world/expression_preview.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const OUTPUT := "res://验证记录/round180_首作三种表达/"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _advance(model: Model,phases: Dictionary,begin: int,end: int) -> void:
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for at in range(begin,end,512): model.render_block(phases,at,mini(512,end-at),rate)

func _difference(a: PackedByteArray,b: PackedByteArray) -> float:
	var maximum := 0.0
	for offset in range(0,mini(a.size(),b.size()),2): maximum = maxf(maximum,absf(float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0))
	return maximum

func _pending(model: Model,kind: String) -> bool:
	return model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op["kind"]) == kind)

func _node(model: Model,answer: bool) -> Dictionary:
	for node in model.synth.musical_nodes.values():
		if bool(node["active"]) and bool(node["answer"]) == answer: return node
	return {}

func _activity(model: Model,source_id: String,generation: int,onset: int,probe: int) -> Dictionary:
	for row in model.audible_music_activity(probe):
		if row["source_id"] == source_id and int(row["generation"]) == generation and int(row["onset"]) == onset: return row
	return {}

func _reply_pcm(model: Model,state: Dictionary,begin: int,count: int,rate: int) -> PackedByteArray:
	# This is the actual immutable event waveform used by render_block, taken
	# from the established Reply slot after its real control ramp reaches one.
	var node := _node(model,true)
	var samples := PackedVector2Array()
	samples.resize(count)
	if node.is_empty(): return Renderer.pcm16(samples)
	var wave := model.synth._musical_block(node,begin,count,rate)
	var level := float(state.get("_theme_level_"+str(node["key"]),0.0))
	var amplitude := float(model.synth.score["response_gain"])*model.synth.gain*level
	for at in range(count): samples[at] = wave[at]*amplitude*node["part"]["stereo"]
	return Renderer.pcm16(samples)

func _retune_cause(source: Model,source_state: Dictionary) -> Dictionary:
	var rate := int(source.world.cfg["timing"]["sample_rate"])
	var begin := source.rendered_until
	var lead := _node(source,false)
	var answer := _node(source,true)
	var target: Dictionary = {}
	var minimum := (begin/source.beat_frames+1)*source.beat_frames
	for event in source.synth.musical_events(answer,minimum,rate*4,rate):
		var house: Dictionary = source.world.by_id.get(str(event["source_id"]),{})
		if house.is_empty() or int(house["current_midi"]) != 48 or int(event["source_onset"]) < minimum: continue
		var receiver: Dictionary = source.world.by_id.get(str(event["receiver_id"]),{})
		if not receiver.is_empty() and float(source.world.coupling.interval(52,int(receiver["current_midi"]))["score"]) < 0.85:
			target = event
			break
	check(not target.is_empty() and not lead.is_empty(),"natural_theme_has_a_real_later_c_source_whose_legal_e_breaks_a_reply_pair")
	if target.is_empty(): return {}
	var source_id := str(target["source_id"])
	var receiver_id := str(target["receiver_id"])
	var baseline := source.freeze()
	var edited := source.freeze()
	baseline.enable_music_activity()
	edited.enable_music_activity()
	var baseline_state := source_state.duplicate(true)
	var edited_state := source_state.duplicate(true)
	var receiver_pitch := int(edited.world.by_id[receiver_id]["current_midi"])
	var request := edited.submit({"kind":"retune","id":source_id,"midi":52})
	check(bool(request["accepted"]) and int(request["sound_frame"]) == minimum,"one_normal_c_to_e_retune_uses_the_first_writable_beat")
	var lead_onset := int(target["source_onset"])
	var lead_probe := lead_onset+256
	_advance(baseline,baseline_state,begin,lead_probe+1)
	_advance(edited,edited_state,begin,lead_probe+1)
	var old_lead := _activity(baseline,source_id,0,lead_onset,lead_probe)
	var new_lead := _activity(edited,source_id,0,lead_onset,lead_probe)
	check(not old_lead.is_empty() and not new_lead.is_empty() and int(old_lead["pitch"]) == 60 and int(new_lead["pitch"]) == 64 and float(new_lead["strength"]) > 0.0 and edited.synth.pitch_overrides[source_id] == 52,"actual_audible_lead_source_changes_from_c60_to_e64")
	var reply_onset := int(target["onset"])
	_advance(baseline,baseline_state,lead_probe+1,reply_onset)
	_advance(edited,edited_state,lead_probe+1,reply_onset)
	var old_node := _node(baseline,true)
	var new_node := _node(edited,true)
	check(float(baseline_state.get("_theme_level_"+str(old_node["key"]),0.0)) == 1.0 and float(edited_state.get("_theme_level_"+str(new_node["key"]),0.0)) == 1.0,"reply_pcm_probe_uses_actual_fully_audible_existing_slot_levels")
	var count := 1024
	var old_reply_pcm := _reply_pcm(baseline,baseline_state,reply_onset,count,rate)
	var new_reply_pcm := _reply_pcm(edited,edited_state,reply_onset,count,rate)
	var old_full_pcm := Renderer.pcm16(baseline.render_block(baseline_state,reply_onset,count,rate))
	var new_full_pcm := Renderer.pcm16(edited.render_block(edited_state,reply_onset,count,rate))
	var old_reply := _activity(baseline,source_id,1,reply_onset,reply_onset+256)
	var new_reply := _activity(edited,source_id,1,reply_onset,reply_onset+256)
	var next_events := edited.synth.musical_events(_node(edited,true),reply_onset,count,rate)
	check(not old_reply.is_empty() and int(old_reply["generation"]) == 1 and old_reply["receiver_id"] == receiver_id and new_reply.is_empty() and not next_events.any(func(event: Dictionary) -> bool: return event["source_id"] == source_id and int(event["onset"]) == reply_onset),"one_retune_changes_the_next_actual_generation_one_reply_relation_and_schedule")
	check(_difference(old_reply_pcm,new_reply_pcm) > 0.005 and _difference(old_full_pcm,new_full_pcm) > 0.005,"changed_reply_is_a_measured_rendered_pcm_difference_not_only_new_event_identity")
	check(int(edited.world.by_id[receiver_id]["current_midi"]) == receiver_pitch and int(baseline.world.by_id[receiver_id]["current_midi"]) == receiver_pitch and source.world.by_id[source_id]["current_midi"] == 48,"receiver_pitch_and_original_source_world_remain_unchanged")
	return {"operation":{"kind":"retune","id":source_id,"midi":52},"request":request,"receiver_id":receiver_id,"receiver_midi":receiver_pitch,
		"old_lead":old_lead,"new_lead":new_lead,"old_reply":old_reply,"new_reply":new_reply,"old_reply_score":source.world.coupling.interval(48,receiver_pitch)["score"],
		"new_reply_score":source.world.coupling.interval(52,receiver_pitch)["score"],"reply_pcm_max_abs":_difference(old_reply_pcm,new_reply_pcm),"full_score_pcm_max_abs":_difference(old_full_pcm,new_full_pcm),
		"scope":"This one legal C-to-E retune changes an actual river pair and its next generation-one reply. It does not assert that every retune changes every reply."}

func _envelope_activity(source: Model,state: Dictionary,choice: String) -> Dictionary:
	var model := source.freeze()
	var phases := state.duplicate(true)
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	var node := _node(model,false)
	var boundary := model.world.phrase_index*model.phrase_frames
	var first: Dictionary = model.synth.musical_events(node,boundary,512,rate)[0]
	var probe := int(first["onset"])+roundi(rate*(2.0 if choice == "warm" else 0.30))
	model.enable_music_activity()
	_advance(model,phases,source.rendered_until,probe+1)
	var row := _activity(model,str(first["source_id"]),0,int(first["onset"]),probe)
	var actual_wave := model.synth._musical_block(node,probe,512,rate)
	var peak := 0.0
	for sample in actual_wave: peak = maxf(peak,absf(sample))
	check((not row.is_empty() and float(row["strength"]) > 0.0 and peak > 0.01) if choice == "warm" else (row.is_empty() and peak == 0.0),choice+"_map_activity_follows_the_real_long_or_short_rendered_envelope")
	return {"event":first,"probe_frame":probe,"actual_wave_peak":peak,"actual_activity":row}

func _continuous_warm(gain: float) -> Dictionary:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var source := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var phases: Dictionary = {}
	var public_position: Array = First.opportunities(city)["public_candidates"][0]["position"]
	source.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"]})
	source.submit({"kind":"civic","position":public_position})
	var first_boundary := source.next_boundary
	_advance(source,phases,0,first_boundary+512)
	var cursor := source.next_boundary-128
	_advance(source,phases,first_boundary+512,cursor)
	var choice: Dictionary = {}
	for candidate in First.opportunities(city)["seed_candidates"]:
		if str(candidate["community_id"]) == "west-1": choice = candidate
	check(not choice.is_empty() and str(choice.get("lot_id","")) == "" and city.phrase_index == 1 and not city.development_charters.is_empty() and bool(Rules.facilities(city,"west-1")["civic"]),"after_real_first_phrase_planning_and_growth_sound_seed_uses_actual_continuous_land")
	if choice.is_empty(): return {"reason":"no continuous seed candidate"}
	var position: Array = choice["position"]
	var id := str(city.buildings[0]["district_id"])
	source.submit({"kind":"retune","id":id,"midi":50})
	source.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1"]})
	var captured := source.capture_state()
	var original_phases := phases.duplicate(true)
	var preview := Preview.build(source,position,phases,cursor)
	var variant: Dictionary = preview["variants"]["warm"]
	check(bool(variant["accepted"]),"warm_can_reserve_real_continuous_empty_space_when_first_phrase_consumed_all_lots")
	if not bool(variant["accepted"]): return {"reason":variant["reason"],"candidate":choice}
	var operation := PlayerExpression.operation("warm",position)
	var formal := Model.from_state(captured)
	var formal_phases := phases.duplicate(true)
	var request := formal.submit(operation)
	check(bool(request["accepted"]) and _pending(formal,"retune") and _pending(formal,"charter"),"continuous_warm_preserves_the_new_independent_charter_and_retune")
	var boundary := formal.next_boundary
	_advance(formal,formal_phases,cursor,boundary)
	var actual_pcm := Renderer.pcm16(formal.render_block(formal_phases,boundary,rate*4,rate))
	var forecast_pcm := Renderer.pcm16(source.forecast(operation,phases,cursor,rate*4))
	check(actual_pcm == variant["pcm"] and forecast_pcm == actual_pcm,"continuous_warm_formal_native_forecast_and_comparison_pcm_match_byte_for_byte")
	var reservations: Array = variant["consequences"]["reservations"]
	var reserved: Dictionary = reservations[0] if not reservations.is_empty() else {}
	var actual_reservation: Dictionary = {}
	for record in formal.world.planning_reservations:
		if str(record.get("id","")) == str(reserved.get("id","")): actual_reservation = record
	check(not reserved.is_empty() and reserved == actual_reservation and formal.world.buildings.all(func(house: Dictionary) -> bool:
		return not Planning.disc_hits(reserved["polygon"],Vector2(float(house["position"][0]),float(house["position"][1])),float(house["radius"]))),"continuous_warm_consequence_is_an_actual_empty_reserved_polygon_after_real_growth")
	check(source.capture_state() == captured and phases == original_phases,"continuous_warm_private_comparison_forecast_and_formal_leave_live_source_unchanged")
	return {"candidate":choice,"reservation":reserved,"preview_formal_pcm_max_abs":_difference(variant["pcm"],actual_pcm),"forecast_formal_pcm_max_abs":_difference(forecast_pcm,actual_pcm),"consequences":variant["consequences"],"sample_rate":rate}

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var opportunities := First.opportunities(city)
	var position: Array = opportunities["seed_candidates"][0]["position"]
	var public_position: Array = opportunities["public_candidates"][0]["position"]
	var phases: Dictionary = {}
	var cursor := model.next_boundary-128
	_advance(model,phases,0,cursor)
	var charter := model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"]})
	var civic := model.submit({"kind":"civic","position":public_position})
	var id := str(city.buildings[0]["district_id"])
	var retune := model.submit({"kind":"retune","id":id,"midi":52})
	var focus := model.submit({"kind":"focus","community":"west-1"})
	check(city.phrase_index == 0 and city.buildings.size() == 24 and model.synth.theme.is_empty(),"source_is_a_real_young_24_house_three_community_opening")
	check(bool(charter["accepted"]) and bool(civic["accepted"]) and bool(retune["accepted"]) and bool(focus["accepted"]),"source_keeps_real_pending_charter_anchor_retune_and_focus")
	var captured := model.capture_state()
	var original_phases := phases.duplicate(true)
	var rng := city.rng.snapshot()
	var comparison := Preview.build(model,position,phases,cursor)
	check(comparison["contract"] == "P12-EXPRESSION-COMPARE/v1" and int(comparison["sample_rate"]) == rate and int(comparison["duration_frames"]) == rate*4 and int(comparison["source_frame"]) == cursor and int(comparison["boundary_frame"]) == model.next_boundary and float(comparison["gain"]) == gain and comparison["source_key"] == Preview.source_key(model,position,phases,cursor),"three_candidates_share_one_source_real_rate_gain_and_next_boundary")
	check(model.capture_state() == captured and phases == original_phases and city.rng.snapshot() == rng,"candidate_generation_preserves_source_rng_all_intent_and_oscillator_phases")
	var variants: Dictionary = comparison["variants"]
	check(variants.size() == 3 and PlayerExpression.IDS.all(func(choice: String) -> bool: return bool(variants[choice]["accepted"])),"all_three_are_accepted_formal_seeds_at_the_same_legal_position")
	if not PlayerExpression.IDS.all(func(choice: String) -> bool: return bool(variants[choice]["accepted"])):
		for choice: String in PlayerExpression.IDS: evidence[choice] = variants[choice]["reason"]
		_finish()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var branches: Dictionary = {}
	var metrics: Dictionary = {}
	var formal_models: Dictionary = {}
	var formal_states: Dictionary = {}
	for choice: String in PlayerExpression.IDS:
		var formal := Model.from_state(captured)
		var formal_phases := original_phases.duplicate(true)
		var variant: Dictionary = variants[choice]
		var request := formal.submit(PlayerExpression.operation(choice,position))
		check(bool(request["accepted"]) and _pending(formal,"charter") and _pending(formal,"civic") and _pending(formal,"retune") and formal.sound_events == captured["sound_events"],choice+"_formal_seed_preserves_independent_planning_and_sound_requests")
		var boundary := formal.next_boundary
		_advance(formal,formal_phases,cursor,boundary)
		var samples := formal.render_block(formal_phases,boundary,rate*4,rate)
		var pcm := Renderer.pcm16(samples)
		check(variant["pcm"].size() == rate*4*4 and pcm == variant["pcm"],choice+"_preview_is_byte_identical_to_formal_four_second_full_score")
		check(Renderer.pcm16(model.forecast(PlayerExpression.operation(choice,position),original_phases,cursor,rate*4)) == pcm,choice+"_native_forecast_preserves_same_pending_intent_and_matches_actual_pcm")
		var birth: Dictionary = variant["birth"]["building"]
		var actual: Dictionary = formal.world.by_id.get(str(birth["district_id"]),{})
		var actual_family: Dictionary = formal.world.families.get(str(birth["family_id"]),{})
		check(birth == actual and variant["birth"]["family"] == actual_family and bool(actual["player_expression"]) and bool(actual_family["player_expression"]) and actual["position"] == position and actual["expression"] == choice and int(actual["current_midi"]) == int(PlayerExpression.definition(choice)["midi"]) and actual["type"] == PlayerExpression.definition(choice)["type"],choice+"_sound_is_real_saved_family_pitch_land_use_and_birth")
		check(variant["score"] == formal.synth.score_snapshot() and variant["opportunities"] == [Rules.opportunity(formal.world,"west-1",formal.synth.score_snapshot())] and formal.world.community_expression("west-1") == choice and int(variant["consequences"]["next_growth_phrase"]) == int(actual_family["next_growth_phrase"]),choice+"_opportunities_and_growth_are_current_branch_world_results")
		var reservations: Array = formal.world.planning_reservations.filter(func(item: Dictionary) -> bool: return str(item.get("id","")) == str(actual_family.get("expression_reservation_id","")))
		check(variant["consequences"]["reservations"] == reservations and int(variant["consequences"]["reservation_count"]) == (1 if choice == "warm" else 0) and (choice != "warm" or formal.world.buildings.all(func(house: Dictionary) -> bool: return not reservations[0]["source_lot_ids"].has(str(house.get("lot_id",""))))),choice+"_reports_only_actual_reserved_empty_land_and_no_building_on_it")
		var part: Dictionary = formal.synth.rhythms.filter(func(item: Dictionary) -> bool: return str(item["cid"]) == "west-1")[0]
		var profile := formal.synth.rhythm_profile(part,rate)
		check(bool(part["player_expression"]) and part["source_id"] == actual["district_id"] and part["expression"] == choice and variant["metrics"]["rhythm_profiles"] == [profile] and variant["metrics"]["pulse_events"] == formal.synth.rhythm_events(part,boundary,rate*4,rate),choice+"_actual_existing_rhythm_slot_uses_the_new_root_and_real_events")
		check(formal.synth.gain == gain and int(formal.synth.score["render_voice_limit"]) == 70 and formal.synth.max_voice_count <= 70 and variant["peak"] > 0.0 and variant["peak"] < 1.0,choice+"_full_score_keeps_gain_headroom_and_seventy_voice_budget")
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = rate
		wav.stereo = true
		wav.data = pcm
		check(wav.save_to_wav(OUTPUT+choice+".wav") == OK,choice+"_exports_only_the_actual_formal_full_score_pcm")
		var saved := formal.capture_state()
		var restored := Model.from_state(saved)
		var restored_phases := formal_phases.duplicate(true)
		var resumed := formal.freeze()
		var resumed_phases := formal_phases.duplicate(true)
		var at := boundary+rate*4
		check(Renderer.pcm16(restored.render_block(restored_phases,at,777,rate)) == Renderer.pcm16(resumed.render_block(resumed_phases,at,777,rate)) and restored_phases == resumed_phases,choice+"_saved_player_expression_resumes_with_identical_real_pcm_and_phases")
		formal_models[choice] = formal
		formal_states[choice] = formal_phases
		metrics[choice] = {"profile":profile,"events":variant["metrics"]["pulse_events"],"consequences":variant["consequences"]}
		branches[choice] = {"preview_formal_pcm_max_abs":_difference(pcm,variant["pcm"]),"peak":variant["peak"],"max_voices":variant["max_voices"],"wav":OUTPUT+choice+".wav","root_id":birth["district_id"],"metrics":metrics[choice]}
	var differences: Dictionary = {}
	for pair in [["deep","weave"],["deep","warm"],["weave","warm"]]:
		var difference := _difference(variants[pair[0]]["pcm"],variants[pair[1]]["pcm"])
		differences[pair[0]+"_"+pair[1]] = difference
		check(difference > 0.005,pair[0]+"_"+pair[1]+"_full_scores_have_a_measured_pcm_difference")
	check(int(metrics["deep"]["profile"]["pitch"]) < int(metrics["warm"]["profile"]["pitch"]) and int(metrics["warm"]["profile"]["pitch"]) < int(metrics["weave"]["profile"]["pitch"]) and int(metrics["weave"]["profile"]["spacing_frames"]) < int(metrics["deep"]["profile"]["spacing_frames"]) and int(metrics["deep"]["profile"]["spacing_frames"]) < int(metrics["warm"]["profile"]["spacing_frames"]) and float(metrics["weave"]["profile"]["tail"]) < float(metrics["deep"]["profile"]["tail"]) and float(metrics["deep"]["profile"]["tail"]) < float(metrics["warm"]["profile"]["tail"]),"real_render_profiles_differ_in_register_interval_and_envelope_duration")
	check(variants["deep"]["consequences"]["next_growth_phrase"] > variants["weave"]["consequences"]["next_growth_phrase"] and variants["weave"]["consequences"]["type"] == "commercial" and variants["warm"]["consequences"]["type"] == "residential","same_source_choices_have_real_slow_growth_and_commercial_or_residential_consequences")
	var matured: Dictionary = {}
	for choice: String in PlayerExpression.IDS:
		var formal: Model = formal_models[choice]
		var state: Dictionary = formal_states[choice]
		var begin := int(comparison["boundary_frame"])+rate*4
		var boundary := formal.next_boundary
		_advance(formal,state,begin,boundary)
		formal.render_block(state,boundary,512,rate)
		var status := Rules.status(formal.world,"west-1")
		var score := formal.synth.score_snapshot()
		var actual_events: Array[Dictionary] = []
		for node in formal.synth.musical_nodes.values():
			if bool(node["active"]) and not bool(node["answer"]): actual_events.append_array(formal.synth.musical_events(node,boundary,formal.phrase_frames,rate))
		check(int(status["mature"]) >= 6 and bool(status["theme_eligible"]) and str(score.get("theme",{}).get("cid","")) == "west-1" and str(score["theme"]["expression"]) == choice and bool(score["theme"]["player_expression"]) and not actual_events.is_empty(),choice+"_ordinary_maturation_forms_an_actual_authored_theme_from_at_least_six_houses")
		matured[choice] = {"phrase":formal.world.phrase_index,"status":status,"theme":score.get("theme",{}),"actual_events":actual_events,"response":score.get("response",{})}
	var retune_cause := _retune_cause(formal_models["weave"],formal_states["weave"])
	var envelope_activity := {"warm":_envelope_activity(formal_models["warm"],formal_states["warm"],"warm"),"weave":_envelope_activity(formal_models["weave"],formal_states["weave"],"weave")}
	var continuous_warm := _continuous_warm(gain)
	check(model.capture_state() == captured and phases == original_phases and city.rng.snapshot() == rng,"formal_validation_and_maturation_leave_the_live_source_untouched")
	evidence = {"sample_rate":rate,"source_frame":cursor,"boundary_frame":comparison["boundary_frame"],"duration_frames":rate*4,"gain":gain,"branches":branches,"pair_pcm_max_abs":differences,"matured":matured,"retune_cause":retune_cause,"envelope_activity":envelope_activity,"continuous_warm":continuous_warm,
		"interpretation":"Technical equality, actual rendering profiles and saved city consequences only. These three full-score WAVs are for human evaluation; no human fun or sound-quality verdict is asserted."}
	_finish()

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	FileAccess.open(OUTPUT+"player_expression_audio.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND180_PLAYER_EXPRESSION_AUDIO "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures,"evidence":evidence}))
	quit(0 if failures.is_empty() else 1)
