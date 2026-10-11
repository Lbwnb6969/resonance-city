extends SceneTree
## Charter anchor forecast and formal continuation, then actual Traveler demand.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")
const OUTPUT := "res://验证记录/round177_公交章程锚点/transit_charter_audio.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _line(city: World, id: String) -> Dictionary:
	for line in city.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _advance(model: Model, phases: Dictionary, begin: int, end: int) -> void:
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for at in range(begin,end,512): model.render_block(phases,at,mini(512,end-at),rate)

func _difference(a: PackedByteArray,b: PackedByteArray) -> float:
	var maximum := 0.0
	for offset in range(0,mini(a.size(),b.size()),2):
		maximum = maxf(maximum,absf(float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0))
	return maximum

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var phases: Dictionary = {}
	var cursor := city.phrase_index*phrase
	_advance(model,phases,cursor,model.next_boundary-128)
	cursor = model.next_boundary-128
	var charter := model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1","west-2"],"card_refs":["road_echo"]})
	var charter_id := "charter-%05d" % int(charter.get("event_id",-1))
	var house: Dictionary = city.buildings[0]
	var retune := model.submit({"kind":"retune","id":house["district_id"],"midi":int(house["current_midi"])+2})
	check(bool(charter.get("accepted",false)) and bool(retune.get("accepted",false)),"source_has_pending_charter_card_and_independent_real_retune")
	var operation := {"kind":"transit_line","stop_positions":[city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate(),city.nodes["west-3"].duplicate()],"source_topology":city.network.topology,"charter_id":charter_id}
	var source := model.capture_state()
	var before_phases := phases.duplicate(true)
	var rng := city.rng.snapshot()
	var forecast := Renderer.pcm16(model.forecast(operation,phases,cursor,rate*3))
	check(forecast.size() == rate*3*4,"production_forecast_keeps_pending_charter_and_renders_three_seconds")
	check(model.capture_state() == source and phases == before_phases and city.rng.snapshot() == rng,"forecast_preserves_live_world_rng_audio_and_phases")
	var formal := Model.from_state(source)
	var formal_phases := before_phases.duplicate(true)
	formal.rendered_until = cursor
	var queued := formal.submit(operation)
	check(bool(queued.get("accepted",false)),"same_charter_route_is_accepted_by_formal_submission")
	if not bool(queued.get("accepted",false)):
		_finish()
		return
	var boundary := formal.next_boundary
	_advance(formal,formal_phases,cursor,boundary)
	var pcm := Renderer.pcm16(formal.render_block(formal_phases,boundary,rate*3,rate))
	check(forecast == pcm,"charter_anchor_forecast_matches_formal_pcm_exactly")
	var line_id := "player-line-%d" % int(queued["event_id"])
	var line := _line(formal.world,line_id)
	check(not line.is_empty() and str(line.get("charter_id","")) == charter_id,"formal_boundary_keeps_real_author_line_charter_identity")
	check(formal.world.development_charters.size() == city.development_charters.size()+1 and int(formal.world.by_id[house["district_id"]]["current_midi"]) == int(house["current_midi"])+2,"forecast_formal_boundary_preserves_independent_charter_card_and_retune")
	var before: Dictionary = formal.world.transit_music_feedback(line_id)
	check(str(before.get("state","")) == "coverage_only","new_anchor_coverage_does_not_claim_passenger_music")
	if line.is_empty():
		_finish()
		return
	var baseline := formal.freeze()
	var baseline_phases := formal_phases.duplicate(true)
	var stop_id := str(line["stops"][0])
	var position := formal.world.transit_stop_position(stop_id)
	var growth_before := formal.world._transit_growth_bonus(position,"commercial")
	var bus := Traveler.new("bus",177)
	bus.assigned_line_id = line_id
	var rng_before := formal.world.rng.snapshot()
	for tick in range(1201): bus.advance(formal.world,float(tick)*0.25)
	var passengers := 0
	for observation in formal.world.transit_flow_pending:
		if line["stops"].has(str(observation.get("stop_id",""))):
			passengers += int(observation.get("boarded",0))+int(observation.get("alighted",0))+int(observation.get("transfers",0))
	check(passengers > 0,"assigned_real_vehicle_visits_anchor_stations_and_exchanges_passengers")
	check(formal.world.rng.snapshot() == rng_before and formal.world.transit_demand_score(stop_id) == 0.0 and is_equal_approx(formal.world._transit_growth_bonus(position,"commercial"),growth_before),"actual_arrivals_wait_for_boundary_without_immediate_growth_or_rng_change")
	var current := boundary+rate*3
	var flow_boundary := formal.next_boundary
	_advance(formal,formal_phases,current,flow_boundary+1)
	_advance(baseline,baseline_phases,current,flow_boundary+1)
	check(formal.world.transit_flow_pending.is_empty() and formal.world.transit_demand_score(stop_id) > 0.0,"real_flow_commits_once_at_the_next_phrase")
	var growth_after := formal.world._transit_growth_bonus(position,"commercial")
	check(growth_after > growth_before,"committed_passengers_strengthen_existing_local_station_growth")
	var music_boundary := formal.next_boundary
	_advance(formal,formal_phases,flow_boundary+1,music_boundary)
	_advance(baseline,baseline_phases,flow_boundary+1,music_boundary)
	var heard := Renderer.pcm16(formal.render_block(formal_phases,music_boundary,rate*3,rate))
	var without := Renderer.pcm16(baseline.render_block(baseline_phases,music_boundary,rate*3,rate))
	var feedback := formal.world.transit_music_feedback(line_id)
	check(str(feedback.get("qualified_role","")) in ["pulse","pulse_dense"] and float(feedback.get("passenger_peak",0.0)) > 0.0,"real_passenger_memory_enters_existing_pulse_qualification")
	check(str(_line(formal.world,line_id).get("charter_id","")) == charter_id,"later_growth_and_audio_keep_original_charter_anchor")
	check(formal.synth.max_voice_count <= 70 and int(formal.synth.score["render_voice_limit"]) == 70 and formal.synth.gain == gain,"anchor_and_passenger_audio_keep_existing_gain_and_voice_budget")
	evidence = {"charter_id":charter_id,"line_id":line_id,"boundary":boundary,"preview_formal_pcm_max_abs":_difference(forecast,pcm),"passengers":passengers,"growth_before":growth_before,"growth_after":growth_after,"feedback":feedback,"passenger_pcm_max_abs":_difference(heard,without),"max_voices":formal.synth.max_voice_count,"audibility_condition":"Real demand enters existing pulse eligibility; current services and score slots still select the audible arrangement. PCM equality is allowed."}
	_finish()

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Same-source production forecast and formal PCM; actual assigned Traveler exchange and real phrase commits. No physical device or human listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND177_TRANSIT_CHARTER_AUDIO "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
