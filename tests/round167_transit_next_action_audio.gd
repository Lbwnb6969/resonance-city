extends SceneTree
## Round167: a real authored-line transfer produces a truthful next-action
## contract.  The hint points back to shared physical stops and existing line
## IDs, survives a snapshot, and does not create an extra audio voice.
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
			result.append([path[path.size()/2].x,path[path.size()/2].y])
	return result

func _line(city: World, id: String) -> Dictionary:
	for line in city.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _queue(city: World, positions: Array, frame: int) -> Dictionary:
	var preview := city.transit_plan_preview(positions)
	_check(bool(preview.get("accepted",false)),"route_preview_accepts_real_stops")
	if not bool(preview.get("accepted",false)): return {}
	return city.request({"kind":"transit_line","stop_positions":positions,"source_topology":preview["source_topology"]},frame)

func _run() -> void:
	var city := World.new("2026101100000167",true,"river_valley")
	city.build_starter("bright")
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var first_positions := _positions(city,["west-road-1","west-road-2","west-road-3"])
	var second_positions := _positions(city,["west-road-2","west-road-3","west-road-1"])
	var third_positions := _positions(city,["west-road-3","west-road-1","west-road-2"])
	_check(first_positions.size() == 3 and second_positions.size() == 3 and third_positions.size() == 3,"three_authored_routes_have_real_stops")
	var first := _queue(city,first_positions,phrase)
	_check(bool(first.get("accepted",false)),"first_line_queues")
	city.settle(phrase)
	var first_id := "player-line-%d" % int(first.get("event_id",-1))
	var first_feedback := city.transit_music_feedback(first_id)
	_check(str(first_feedback.get("next_action",{}).get("kind","")) == "observe_passengers","single_line_next_action_waits_for_passengers")
	var second := _queue(city,second_positions,phrase*2)
	_check(bool(second.get("accepted",false)),"second_line_queues_at_shared_stops")
	city.settle(phrase*2)
	var second_id := "player-line-%d" % int(second.get("event_id",-1))
	var second_before := city.transit_music_feedback(second_id)
	var shared: Array = second_before.get("transfer_stop_ids",[])
	_check(shared.size() >= 2,"settled_second_line_exposes_shared_stops")
	_check(str(second_before.get("next_action",{}).get("kind","")) == "observe_transfer","before_exchange_next_action_waits_truthfully")
	_check(second_before.get("next_action",{}).get("transfer_stop_ids",[]) == shared,"next_action_points_to_same_shared_stops")

	var buses: Array[Traveler] = []
	for pair in [[first_id,167],[second_id,169]]:
		var bus := Traveler.new("bus",int(pair[1]))
		bus.assigned_line_id = str(pair[0])
		buses.append(bus)
	var transfer_result_count := 0
	for tick in range(1,4801):
		var seconds := float(tick)*0.1
		for bus in buses:
			var result: Dictionary = bus.advance(city,seconds)
			transfer_result_count += int(result.get("transfer_passengers",0))
	var pending_transfer_count := 0
	for observation in city.transit_flow_pending:
		pending_transfer_count += int(observation.get("transfers",0))
	_check(transfer_result_count > 0 and pending_transfer_count > 0,"real_travelers_record_transfer_before_boundary")
	city.settle(phrase*3)
	var first_after := city.transit_music_feedback(first_id)
	var second_after := city.transit_music_feedback(second_id)
	for feedback in [first_after,second_after]:
		var action: Dictionary = feedback.get("next_action",{})
		_check(str(action.get("kind","")) == "continue_composition","real_transfer_unlocks_continue_composition_action")
		_check(action.get("transfer_stop_ids",[]) == feedback.get("transfer_stop_ids",[]),"continue_action_keeps_authoritative_transfer_stops")
		_check(str(action.get("qualified_role","")) in ["pulse","pulse_dense"],"continue_action_reports_existing_pulse_role")
	_check(first_after.get("next_action",{}).get("line_ids",[]).has(first_id) and first_after.get("next_action",{}).get("line_ids",[]).has(second_id),"continue_action_names_both_authored_lines")
	_check(str(first_after.get("transfer_state","")) == "passenger_transfer" and bool(first_after.get("transfer_qualified",false)),"next_action_requires_committed_passenger_exchange")

	var transit_zone: Dictionary = {}
	for zone in city.functional_zones:
		if str(zone.get("role","")) == "transit": transit_zone = zone; break
	_check(str(transit_zone.get("next_action_kind","")) == "continue_composition","functional_zone_surfaces_post_transfer_action")
	_check(transit_zone.get("next_action",{}).get("transfer_stop_ids",[]) == first_after.get("transfer_stop_ids",[]),"functional_zone_action_matches_line_feedback")
	var feedback_events := city.events.filter(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "transit_feedback")
	_check(not feedback_events.is_empty() and feedback_events.back().get("music_feedback",{}).get("next_action",{}).get("kind","") == "continue_composition","feedback_event_carries_next_action_contract")

	var saved := city.snapshot()
	var restored := World.new(saved["seed_hex"],false)
	restored.restore(saved)
	_check(restored.transit_music_feedback(first_id) == first_after and restored.transit_music_feedback(second_id) == second_after,"snapshot_restore_keeps_next_action_feedback")
	var continuation_preview := restored.transit_plan_preview(third_positions)
	_check(bool(continuation_preview.get("accepted",false)),"after_transfer_player_can_preview_a_third_line")
	_check(continuation_preview.get("transfer_stop_ids",[]).size() >= 2,"third_line_preview_keeps_existing_transfer_opportunity")
	_check(continuation_preview.get("line_ids",[]).has(first_id) and continuation_preview.get("line_ids",[]).has(second_id),"third_line_preview_names_existing_lines")

	var model := Model.new(city,1.0)
	var renderer := Renderer.new(int(city.cfg["timing"]["sample_rate"]))
	renderer.source = model._mix_frame
	var voice_budget := int(model.synth.score["render_voice_limit"])
	renderer.render(4096)
	_check(int(model.synth.score["render_voice_limit"]) == voice_budget and model.synth.max_voice_count <= voice_budget,"next_action_feedback_keeps_existing_voice_budget")
	evidence = {"shared_stops":shared,"transfer_result_count":transfer_result_count,"pending_transfer_count":pending_transfer_count,
		"first_feedback":first_after,"second_feedback":second_after,"third_preview_line_ids":continuation_preview.get("line_ids",[]),
		"voice_budget":voice_budget,"max_voices":model.synth.max_voice_count}
	_finish()

func _finish() -> void:
	print("ROUND167_TRANSIT_NEXT_ACTION_AUDIO ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"evidence":evidence,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
