extends SceneTree
## Both choices are proved against real transactions from the same audible source.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const Compare = preload("res://scripts/world/transit_rework_preview.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")
const OUTPUT := "res://验证记录/round179_改站同源比较/transit_rework_comparison_audio.json"
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
		if str(item.get("id","")) == id: return item
	return {}

func _nodes(city: World,ids: Array) -> Array:
	var positions: Array = []
	for id in ids: positions.append(city.nodes[str(id)].duplicate())
	return positions

func _operation(city: World,id: String,positions: Array) -> Dictionary:
	var candidate := Rework.candidate(city,id)
	return {"kind":"transit_line","edit_id":id,"source_revision":candidate.get("source_revision",""),
		"source_topology":candidate.get("source_topology",""),"stop_positions":positions.duplicate(true)}

func _keep(operation: Dictionary) -> Dictionary:
	return {"kind":"transit_line","keep":true,"edit_id":operation["edit_id"],
		"source_revision":operation["source_revision"],"source_topology":operation["source_topology"]}

func _advance(model: Model,phases: Dictionary,begin: int,end: int) -> void:
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for at in range(begin,end,512): model.render_block(phases,at,mini(512,end-at),rate)

func _difference(a: PackedByteArray,b: PackedByteArray) -> float:
	var maximum := 0.0
	for offset in range(0,mini(a.size(),b.size()),2):
		maximum = maxf(maximum,absf(float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0))
	return maximum

func _passengers(city: World,ids: Array) -> int:
	var count := 0
	for id in ids:
		var memory: Dictionary = city.transit_demand.get(str(id),{})
		count += int(memory.get("boarded",0))+int(memory.get("alighted",0))+int(memory.get("transfers",0))
	return count

func _different_fields(actual: Dictionary,expected: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = actual.keys()
	for key in expected:
		if not keys.has(key): keys.append(key)
	for key in keys:
		if actual.get(key) != expected.get(key): result[key] = {"preview":actual.get(key),"formal":expected.get(key)}
	return result

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var phases: Dictionary = {}
	var cursor := city.phrase_index*int(city.cfg["timing"]["phrase_frames"])
	var charter := model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1","west-2"],"card_refs":["road_echo"]})
	var charter_id := "charter-%05d" % int(charter.get("event_id",-1))
	var created := model.submit({"kind":"transit_line","charter_id":charter_id,"stop_positions":_nodes(city,["west-1","west-2","west-3"]),"source_topology":city.network.topology})
	check(bool(charter.get("accepted",false)) and bool(created.get("accepted",false)),"fixture_queues_real_authored_charter_route")
	if not bool(created.get("accepted",false)):
		_finish()
		return
	var first_boundary := model.next_boundary
	_advance(model,phases,cursor,first_boundary+rate*3)
	cursor = first_boundary+rate*3
	var line_id := "player-line-%d" % int(created["event_id"])
	var original := _record(city.authored_transit_lines,line_id).duplicate(true)
	check(not original.is_empty(),"fixture_contains_a_settled_real_line")
	if original.is_empty():
		_finish()
		return
	var bus := Traveler.new(city.vehicle_kind(),179)
	bus.service_line_id = line_id
	bus.assigned_line_id = line_id
	for tick in range(401): bus.advance(city,float(tick)*0.25)
	var exchanges := 0
	for observation in city.transit_flow_pending:
		exchanges += int(observation.get("boarded",0))+int(observation.get("alighted",0))+int(observation.get("transfers",0))
	check(exchanges > 0,"source_has_actual_uncommitted_traveler_arrivals")
	_advance(model,phases,cursor,model.next_boundary-128)
	cursor = model.next_boundary-128
	var house_id := str(city.buildings[0]["district_id"])
	var before_midi := int(city.by_id[house_id]["current_midi"])
	var replacement := model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1","west-2"]})
	var retune := model.submit({"kind":"retune","id":house_id,"midi":before_midi+2})
	var earlier_edit := model.submit(_operation(city,line_id,_nodes(city,["west-outer-1","west-outer-2"])))
	check(bool(replacement.get("accepted",false)) and bool(retune.get("accepted",false)) and bool(earlier_edit.get("accepted",false)),"source_keeps_independent_charter_retune_and_an_earlier_pending_edit")
	var operation := _operation(city,line_id,_nodes(city,["west-outer-3","west-outer-2","west-outer-1"]))
	var source := model.capture_state()
	var source_phases := phases.duplicate(true)
	var source_rng := city.rng.snapshot()
	var flow := city.transit_flow_pending.duplicate(true)
	var previous_passengers := _passengers(city,original["stop_ids"])
	var comparison := Compare.build(model,operation,phases,cursor)
	check(str(comparison.get("contract","")) == "P12-TRANSIT-REWORK-COMPARE/v1" and int(comparison.get("source_frame",-1)) == cursor and int(comparison.get("boundary_frame",-1)) == model.next_boundary and int(comparison.get("sample_rate",0)) == rate and float(comparison.get("gain",0.0)) == gain,"comparison_uses_one_source_boundary_actual_rate_and_gain")
	check(model.capture_state() == source and phases == source_phases and city.rng.snapshot() == source_rng,"both_private_branches_preserve_live_model_rng_phases_and_pending_arrivals")
	var variants: Dictionary = comparison.get("variants",{})
	check(variants.size() == 2 and bool(variants.get("keep",{}).get("accepted",false)) and bool(variants.get("edit",{}).get("accepted",false)),"same_source_keep_and_edit_are_both_available")
	if not bool(variants.get("keep",{}).get("accepted",false)) or not bool(variants.get("edit",{}).get("accepted",false)):
		evidence = {"keep_reason":variants.get("keep",{}).get("reason",""),"edit_reason":variants.get("edit",{}).get("reason","")}
		_finish()
		return
	var formal_models: Dictionary = {}
	var branch_evidence: Dictionary = {}
	for choice: String in ["keep","edit"]:
		var formal := Model.from_state(source)
		var formal_phases := source_phases.duplicate(true)
		formal.rendered_until = cursor
		var serial := formal.world.action_serial
		var events := formal.world.events.duplicate(true)
		var request := formal.submit(_keep(operation) if choice == "keep" else operation)
		check(bool(request.get("accepted",false)),choice+"_formal_transaction_accepts_same_current_source")
		if not bool(request.get("accepted",false)): continue
		if choice == "keep":
			check(formal.world.action_serial == serial and formal.world.events == events and _record(formal.world.authored_transit_lines,line_id) == original and not formal.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line" and str(op.get("edit_id","")) == line_id),"keep_immediately_withdraws_only_the_earlier_edit_without_new_event_or_revision")
		check(formal.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "charter") and formal.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "retune") and formal.sound_events == source["sound_events"] and formal.world.transit_flow_pending == flow,choice+"_decision_preserves_independent_intent_and_real_pending_passengers")
		var boundary := formal.next_boundary
		_advance(formal,formal_phases,cursor,boundary)
		var pcm := Renderer.pcm16(formal.render_block(formal_phases,boundary,rate*3,rate))
		var variant: Dictionary = variants[choice]
		var line := _record(formal.world.transit_lines,line_id)
		var intent := _record(formal.world.authored_transit_lines,line_id)
		# Coverage describes the just-settled demand, not the runtime route's
		# earlier cached passenger feedback. Historical source fields remain.
		var coverage_line := line.duplicate(true)
		coverage_line.erase("music_feedback")
		var actual_coverage := formal.world.transit_line_coverage_summary(coverage_line)
		var metadata_differences := {
			"score":_different_fields(variant["score"],formal.synth.score_snapshot()),
			"coverage":_different_fields(variant["coverage"],actual_coverage),
			"line":_different_fields(variant["line"],line),
			"music_feedback":_different_fields(variant["music_feedback"],formal.world.transit_music_feedback(line_id))}
		check(variant["pcm"].size() == rate*3*4 and variant["pcm"] == pcm,choice+"_preview_matches_formal_three_second_pcm_byte_for_byte")
		check(metadata_differences.values().all(func(fields: Dictionary) -> bool: return fields.is_empty()),choice+"_score_coverage_route_and_passenger_feedback_match_actual_formal_world")
		check(variant["coverage"].get("music_feedback",{}) == variant["music_feedback"],choice+"_coverage_and_music_feedback_describe_the_same_committed_passengers")
		var opportunities: Array = []
		for raw_cid in variant.get("community_ids",[]): opportunities.append(Rules.opportunity(formal.world,str(raw_cid),formal.synth.score_snapshot()))
		check(not opportunities.is_empty() and variant["opportunities"] == opportunities,choice+"_opportunities_use_actual_branch_world_and_scheduled_score")
		var actual_revision := int(intent.get("revision",0))
		check(formal.world.authored_transit_lines.size() == 1 and intent.get("charter_id","") == charter_id and int(intent.get("event_id",-1)) == int(created["event_id"]) and actual_revision == (0 if choice == "keep" else 1) and int(variant.get("revision",-1)) == actual_revision,choice+"_retains_one_stable_historical_line_with_the_correct_revision")
		if choice == "keep":
			check(not formal.world.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "transit_line" and str(event.get("id","")) == line_id and int(event.get("frame",-1)) == boundary),"kept_route_has_no_fake_transit_edit_event_at_the_real_boundary")
		check(int(formal.world.by_id[house_id]["current_midi"]) == before_midi+2 and formal.world.development_charters.any(func(item: Dictionary) -> bool: return int(item.get("source_operation",-1)) == int(replacement["event_id"])) and formal.world.transit_flow_pending.is_empty() and _passengers(formal.world,original["stop_ids"]) == previous_passengers+exchanges,choice+"_boundary_applies_independent_intent_and_consumes_arrivals_once")
		check(formal.synth.gain == gain and int(formal.synth.score["render_voice_limit"]) == 70 and formal.synth.max_voice_count <= 70 and int(variant.get("max_voices",71)) == formal.synth.max_voice_count,choice+"_keeps_existing_gain_and_voice_budget")
		formal_models[choice] = formal
		branch_evidence[choice] = {"pcm_max_abs":_difference(variant["pcm"],pcm),"revision":actual_revision,"covered_buildings":line.get("covered_building_ids",[]).size(),
			"community_ids":variant["community_ids"],"max_voices":formal.synth.max_voice_count,"passenger_exchanges":_passengers(formal.world,original["stop_ids"])-previous_passengers,"metadata_differences":metadata_differences}
	if formal_models.size() == 2:
		var expected_ids: Array[String] = []
		for choice: String in ["keep","edit"]:
			var branch: Model = formal_models[choice]
			for raw_id in branch.world.transit_line_coverage_summary(_record(branch.world.transit_lines,line_id)).get("community_ids",[]):
				if not expected_ids.has(str(raw_id)): expected_ids.append(str(raw_id))
		expected_ids.sort()
		check(variants["keep"]["community_ids"] == expected_ids and variants["edit"]["community_ids"] == expected_ids,"both_choices_compare_the_same_real_affected_community_union")
	var difference := _difference(variants["keep"]["pcm"],variants["edit"]["pcm"])
	check(bool(comparison.get("pcm_changed",false)) == (variants["keep"]["pcm"] != variants["edit"]["pcm"]) and is_equal_approx(float(comparison.get("max_pcm_abs_diff",-1.0)),difference),"reported_sound_difference_comes_only_from_actual_branch_pcm")
	for stale_field: String in ["source_revision","source_topology"]:
		var stale := operation.duplicate(true)
		stale[stale_field] = "obsolete-source"
		var rejected := Compare.build(model,stale,phases,cursor)
		var denied: Dictionary = rejected.get("variants",{})
		check(denied.size() == 2 and not bool(denied.get("keep",{}).get("accepted",true)) and not bool(denied.get("edit",{}).get("accepted",true)) and not str(denied.get("keep",{}).get("reason","")).is_empty() and not str(denied.get("edit",{}).get("reason","")).is_empty() and denied["keep"]["pcm"].is_empty() and denied["edit"]["pcm"].is_empty(),"stale_"+stale_field+"_rejects_both_choices_without_fake_pcm")
	check(model.capture_state() == source and phases == source_phases and city.rng.snapshot() == source_rng,"rejected_comparisons_also_preserve_source_pending_edit_and_all_independent_state")
	evidence = {"line_id":line_id,"charter_id":charter_id,"source_frame":cursor,"boundary_frame":model.next_boundary,"sample_rate":rate,"duration_frames":rate*3,"gain":gain,
		"real_pending_passenger_exchanges":exchanges,"branches":branch_evidence,"pcm_changed":comparison["pcm_changed"],"keep_edit_pcm_max_abs":difference,
		"audibility_condition":"The choices compare actual next-phrase scores and PCM. Existing role selection may produce equal audio despite different coverage; no dedicated transit voice or human-listening claim."}
	_finish()

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"Dummy same-source keep/edit comparison against actual formal model transactions, with existing authored line, independent intent and actual pending Traveler arrivals."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND179_TRANSIT_REWORK_COMPARISON_AUDIO "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
