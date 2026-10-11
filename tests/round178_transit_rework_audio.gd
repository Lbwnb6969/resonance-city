extends SceneTree
## Same-source next-phrase audio for a real authored route edited in place.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const CharterAnchor = preload("res://scripts/world/transit_charter_anchor.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")
const OUTPUT := "res://验证记录/round178_公交改站/transit_rework_audio.json"
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

func _event(city: World,event_id: int) -> Dictionary:
	for event in city.events:
		if str(event.get("kind","")) == "transit_line" and int(event.get("event_id",-1)) == event_id: return event
	return {}

func _nodes(city: World,ids: Array) -> Array:
	var positions: Array = []
	for id in ids: positions.append(city.nodes[str(id)].duplicate())
	return positions

func _advance(model: Model,phases: Dictionary,begin: int,end: int) -> void:
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for at in range(begin,end,512): model.render_block(phases,at,mini(512,end-at),rate)

func _difference(a: PackedByteArray,b: PackedByteArray) -> float:
	var maximum := 0.0
	for offset in range(0,mini(a.size(),b.size()),2):
		maximum = maxf(maximum,absf(float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0))
	return maximum

func _origin_kept(before: Dictionary,after: Dictionary) -> bool:
	for key in ["id","name","event_id","frame","charter_id","plan_id","scope_community_ids"]:
		if before.get(key) != after.get(key): return false
	return true

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var phases: Dictionary = {}
	var cursor := city.phrase_index*phrase
	var charter := model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1","west-2"],"card_refs":["road_echo"]})
	var charter_id := "charter-%05d" % int(charter.get("event_id",-1))
	var created := model.submit({"kind":"transit_line","charter_id":charter_id,"stop_positions":_nodes(city,["west-1","west-2","west-3"]),"source_topology":city.network.topology})
	check(bool(charter.get("accepted",false)) and bool(created.get("accepted",false)),"fixture_queues_real_charter_and_author_line")
	if not bool(created.get("accepted",false)):
		_finish()
		return
	var created_boundary := model.next_boundary
	_advance(model,phases,cursor,created_boundary+rate*3)
	cursor = created_boundary+rate*3
	var line_id := "player-line-%d" % int(created["event_id"])
	var original := _record(city.authored_transit_lines,line_id).duplicate(true)
	check(not original.is_empty() and city.authored_transit_lines.size() == 1,"fixture_lands_one_real_author_line")
	if original.is_empty():
		_finish()
		return
	# This supplies actual exchange observations; route handoff details have their
	# own Traveler contract and are deliberately not re-tested here.
	var bus := Traveler.new(city.vehicle_kind(),178)
	bus.service_line_id = line_id
	bus.assigned_line_id = line_id
	var arrival_rng := city.rng.snapshot()
	for tick in range(401): bus.advance(city,float(tick)*0.25)
	var passengers := 0
	for observation in city.transit_flow_pending:
		passengers += int(observation.get("boarded",0))+int(observation.get("alighted",0))+int(observation.get("transfers",0))
	check(passengers > 0 and city.rng.snapshot() == arrival_rng,"real_service_vehicle_supplies_pending_passengers_without_rng_use")
	_advance(model,phases,cursor,model.next_boundary-128)
	cursor = model.next_boundary-128
	var house: Dictionary = city.buildings[0]
	var house_id := str(house["district_id"])
	var before_midi := int(house["current_midi"])
	var replacement := model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1","west-2"]})
	var retune := model.submit({"kind":"retune","id":house_id,"midi":before_midi+2})
	check(bool(replacement.get("accepted",false)) and bool(retune.get("accepted",false)) and not bool(CharterAnchor.source(city,charter_id).get("accepted",false)),"independent_pending_charter_replaces_scope_without_erasing_line_history")
	var candidate := Rework.candidate(city,line_id)
	var operation := {"kind":"transit_line","edit_id":candidate.get("edit_id",""),"source_revision":candidate.get("source_revision",""),
		"source_topology":candidate.get("source_topology",""),"stop_positions":_nodes(city,["west-outer-3","west-outer-2","west-outer-1"])}
	var preview := Rework.preview(city,operation)
	check(bool(candidate.get("accepted",false)) and bool(preview.get("accepted",false)) and preview.get("charter_id","") == charter_id,"current_rework_preview_keeps_historical_charter_and_real_road_route")
	if not bool(preview.get("accepted",false)):
		evidence = {"candidate":candidate,"preview":preview}
		_finish()
		return
	operation["stop_positions"] = preview["stop_positions"].duplicate(true)
	operation["source_topology"] = preview["source_topology"]
	var source := model.capture_state()
	var source_phases := phases.duplicate(true)
	var source_rng := city.rng.snapshot()
	var source_flow := city.transit_flow_pending.duplicate(true)
	var forecast := Renderer.pcm16(model.forecast(operation,phases,cursor,rate*3))
	check(forecast.size() == rate*3*4,"production_edit_forecast_renders_three_seconds")
	check(model.capture_state() == source and phases == source_phases and city.rng.snapshot() == source_rng,"forecast_preserves_live_world_pending_flow_audio_and_phases")
	var formal := Model.from_state(source)
	var formal_phases := source_phases.duplicate(true)
	formal.rendered_until = cursor
	var queued := formal.submit(operation)
	check(bool(queued.get("accepted",false)),"same_source_formal_submission_accepts_the_previewed_edit")
	if not bool(queued.get("accepted",false)):
		evidence = {"queued":queued}
		_finish()
		return
	check(formal.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "charter") and formal.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "retune"),"formal_edit_keeps_independent_pending_charter_and_retune")
	check(_record(formal.world.authored_transit_lines,line_id) == original and formal.world.transit_flow_pending == source_flow,"pending_edit_keeps_original_route_and_real_uncommitted_passengers")
	var boundary := formal.next_boundary
	_advance(formal,formal_phases,cursor,boundary)
	var pcm := Renderer.pcm16(formal.render_block(formal_phases,boundary,rate*3,rate))
	check(forecast == pcm,"edit_forecast_matches_same_source_formal_pcm_byte_for_byte")
	var edited := _record(formal.world.authored_transit_lines,line_id)
	var line := _record(formal.world.transit_lines,line_id)
	var event := _event(formal.world,int(queued["event_id"]))
	check(formal.world.authored_transit_lines.size() == 1 and formal.world.transit_lines.filter(func(item: Dictionary) -> bool: return str(item.get("id","")) == line_id).size() == 1 and _origin_kept(original,edited),"formal_edit_preserves_one_stable_line_and_its_creation_source")
	check(int(edited.get("revision",0)) == 1 and int(line.get("edit_revision",0)) == 1 and line.get("source_revision","") == Rework.candidate(formal.world,line_id).get("source_revision","") and edited.get("stop_ids",[]) != original.get("stop_ids",[]),"actual_boundary_changes_station_order_and_runtime_revision")
	check(bool(event.get("edit",false)) and event.get("id","") == line_id and int(event.get("frame",-1)) == boundary and int(event.get("original_event_id",-1)) == int(created["event_id"]) and int(event.get("edit_revision",0)) == 1 and event.get("charter_id","") == charter_id,"real_edit_event_connects_new_operation_to_original_line_and_charter")
	check(int(formal.world.by_id[house_id]["current_midi"]) == before_midi+2 and formal.world.development_charters.any(func(item: Dictionary) -> bool: return int(item.get("source_operation",-1)) == int(replacement["event_id"])),"formal_boundary_applies_independent_retune_and_replacement_charter")
	var committed_passengers := 0
	for stop_id in original.get("stop_ids",[]):
		var memory: Dictionary = formal.world.transit_demand.get(str(stop_id),{})
		committed_passengers += int(memory.get("boarded",0))+int(memory.get("alighted",0))+int(memory.get("transfers",0))
	check(formal.world.transit_flow_pending.is_empty() and committed_passengers == passengers,"edit_boundary_commits_original_real_arrivals_once_without_replay")
	check(formal.synth.gain == gain and int(formal.synth.score["render_voice_limit"]) == 70 and formal.synth.max_voice_count <= 70,"route_edit_keeps_existing_mix_gain_and_render_voice_budget")
	evidence = {"sample_rate":rate,"duration_frames":rate*3,"line_id":line_id,"charter_id":charter_id,"created_frame":created_boundary,"edit_frame":boundary,
		"source_revision":operation["source_revision"],"edit_revision":edited.get("revision",0),"preview_formal_pcm_max_abs":_difference(forecast,pcm),
		"real_passenger_exchanges":passengers,"committed_passenger_exchanges":committed_passengers,"max_voices":formal.synth.max_voice_count,"gain":gain,
		"old_station_ids":original.get("stop_ids",[]),"new_station_ids":edited.get("stop_ids",[]),"feedback":formal.world.transit_music_feedback(line_id),
		"audibility_condition":"An authored route uses existing services, passenger memory and score selection. Editing does not add a new sound layer or guarantee a new audible role."}
	_finish()

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"Dummy same-source production forecast and formal PCM, with actual authored route and Traveler arrivals. No physical-device or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND178_TRANSIT_REWORK_AUDIO "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
