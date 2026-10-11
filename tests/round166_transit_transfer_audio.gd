extends SceneTree
## Two authored lines reuse the same physical stops.  Real Traveler transfer
## observations stay pending until a phrase boundary, then enter the existing
## pulse/pulse_dense summary on both lines without allocating a new voice.
const World = preload("res://scripts/world/continuous_world.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _positions(city: World, roads: Array[String]) -> Array:
	var result: Array = []
	for road_id in roads:
		for road in city.roads:
			if str(road.get("id","")) != road_id: continue
			var path: PackedVector2Array = road["path"]
			var point := path[path.size()/2]
			result.append([point.x,point.y])
	return result

func _line(city: World, id: String) -> Dictionary:
	for line in city.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _event(city: World, id: String, kind: String = "transit_line") -> Dictionary:
	for event in city.events:
		if str(event.get("kind","")) == kind and str(event.get("id","")) == id: return event
	return {}

func _queue(city: World, positions: Array, frame: int) -> Dictionary:
	var preview := city.transit_plan_preview(positions)
	_check(bool(preview.get("accepted",false)),"authored_route_preview_accepts_real_stops")
	if not bool(preview.get("accepted",false)): return {}
	return city.request({"kind":"transit_line","stop_positions":positions,"source_topology":preview["source_topology"]},frame)

func _run() -> void:
	var city := World.new("2026101100000166",true,"river_valley")
	city.build_starter("bright")
	var first_positions := _positions(city,["west-road-1","west-road-2","west-road-3"])
	var second_positions := _positions(city,["west-road-2","west-road-3","west-road-1"])
	_check(first_positions.size() == 3 and second_positions.size() == 3,"two_authored_routes_have_three_real_stops")
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var first := _queue(city,first_positions,phrase)
	_check(bool(first.get("accepted",false)),"first_authored_line_queues")
	city.settle(phrase)
	var first_id := "player-line-%d" % int(first.get("event_id",-1))
	var first_line := _line(city,first_id)
	_check(not first_line.is_empty(),"first_authored_line_settles")
	var first_feedback_before: Dictionary = city.transit_music_feedback(first_id)
	_check(str(first_feedback_before.get("state","")) == "coverage_only" and not bool(first_feedback_before.get("transfer_qualified",true)),"first_line_coverage_does_not_claim_transfer_music")
	var second := _queue(city,second_positions,phrase*2)
	_check(bool(second.get("accepted",false)),"second_authored_line_queues_on_the_next_boundary")
	city.settle(phrase*2)
	var second_id := "player-line-%d" % int(second.get("event_id",-1))
	var second_line := _line(city,second_id)
	_check(not second_line.is_empty(),"second_authored_line_settles")
	var shared_stops: Array = []
	for stop_id in first_line.get("stops",[]):
		if second_line.get("stops",[]).has(stop_id) and not shared_stops.has(str(stop_id)): shared_stops.append(str(stop_id))
	# Refresh the dictionary after the network rebuild; authored lines are
	# replaced by the complete runtime contract when a second line is added.
	first_line = _line(city,first_id)
	second_line = _line(city,second_id)
	_check(shared_stops.size() >= 2,"authored_lines_share_physical_stop_ids")
	_check(first_line.get("transfer_stop_ids",[]).size() >= 1 and second_line.get("transfer_stop_ids",[]).size() >= 1,"runtime_lines_expose_shared_transfer_metadata")
	var second_feedback_before: Dictionary = city.transit_music_feedback(second_id)
	_check(not bool(second_feedback_before.get("transfer_qualified",true)) and str(second_feedback_before.get("transfer_state","")) in ["coverage_only","shared_station_waiting"],"shared_station_coverage_waits_for_real_transfer")

	# Force one real vehicle onto each authored line.  Traveler.advance() owns
	# boarding, alighting, transfer selection, and the pending demand records.
	var buses: Array[Traveler] = []
	for pair in [[first_id,101],[second_id,103]]:
		var bus := Traveler.new("bus",int(pair[1]))
		bus.assigned_line_id = str(pair[0])
		buses.append(bus)
	var transfer_result_count := 0
	for tick in range(1,4801):
		var seconds := float(tick)*0.1
		for bus in buses:
			var result: Dictionary = bus.advance(city,seconds)
			if int(result.get("transfer_passengers",0)) > 0: transfer_result_count += int(result.get("transfer_passengers",0))
	var pending_transfers := 0
	for observation in city.transit_flow_pending: pending_transfers += int(observation.get("transfers",0))
	_check(transfer_result_count > 0 and pending_transfers > 0,"real_authored_vehicles_record_transfer_passengers")
	var pending_feedback: Dictionary = city.transit_music_feedback(first_id)
	_check(not bool(pending_feedback.get("transfer_qualified",true)),"pending_transfer_observations_do_not_claim_music_qualification")
	var feedback_frame := phrase*3
	city.settle(feedback_frame)
	var first_feedback: Dictionary = city.transit_music_feedback(first_id)
	var second_feedback: Dictionary = city.transit_music_feedback(second_id)
	_check(bool(first_feedback.get("transfer_qualified",false)) and bool(second_feedback.get("transfer_qualified",false)),"committed_transfer_memory_qualifies_both_shared_lines")
	_check(int(first_feedback.get("transfer_count",0)) > 0 and int(second_feedback.get("transfer_count",0)) > 0,"both_feedback_summaries_report_committed_transfer_count")
	_check(first_feedback.get("transfer_stop_ids",[]) == second_feedback.get("transfer_stop_ids",[]),"shared_lines_report_the_same_transfer_stops")
	_check(str(first_feedback.get("transfer_state","")) == "passenger_transfer" and str(second_feedback.get("transfer_state","")) == "passenger_transfer","transfer_state_requires_real_passenger_exchange")
	_check(str(first_feedback.get("qualified_role","")) in ["pulse","pulse_dense"] and str(second_feedback.get("qualified_role","")) in ["pulse","pulse_dense"],"transfer_qualification_reuses_existing_pulse_roles")
	_check(str(first_feedback.get("state","")) in ["pulse_active","pulse_dense_active","passenger_memory"] and str(second_feedback.get("state","")) in ["pulse_active","pulse_dense_active","passenger_memory"],"transfer_feedback_enters_existing_music_condition")
	var first_event := _event(city,first_id)
	var second_event := _event(city,second_id)
	_check(bool(first_event.get("music_feedback",{}).get("transfer_qualified",false)) and bool(second_event.get("music_feedback",{}).get("transfer_qualified",false)),"transit_feedback_metadata_carries_transfer_qualification")
	var saved := city.snapshot()
	var restored := World.new(saved["seed_hex"],false)
	restored.restore(saved)
	_check(restored.transit_music_feedback(first_id) == first_feedback and restored.transit_music_feedback(second_id) == second_feedback,"snapshot_restore_preserves_transfer_feedback")
	var restored_transfer_ids: Array = restored.transit_music_feedback(first_id).get("transfer_stop_ids",[])
	var restored_shared := shared_stops.all(func(stop_id: String) -> bool: return restored_transfer_ids.has(stop_id))
	_check(restored_shared,"snapshot_restore_preserves_shared_transfer_stops")

	# A transfer is a metadata/demand update.  Rendering the resulting city uses
	# the existing score budget and must not create a dedicated transit voice.
	var model := Model.new(city,1.0)
	var renderer := Renderer.new(int(city.cfg["timing"]["sample_rate"]))
	renderer.source = model._mix_frame
	var voice_budget := int(model.synth.score["render_voice_limit"])
	renderer.render(4096)
	_check(int(model.synth.score["render_voice_limit"]) == voice_budget and model.synth.max_voice_count <= voice_budget,"transfer_feedback_keeps_existing_voice_budget")
	evidence = {"shared_stops":shared_stops,"pending_transfer_count":pending_transfers,"transfer_result_count":transfer_result_count,
		"first_feedback":first_feedback,"second_feedback":second_feedback,"voice_budget":voice_budget,"max_voices":model.synth.max_voice_count}
	_finish()

func _finish() -> void:
	print("ROUND166_TRANSIT_TRANSFER_AUDIO ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"evidence":evidence,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
