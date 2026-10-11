extends SceneTree
## Passenger qualification remains a truthful readout of the existing pulse roles.
## This test deliberately uses world settlement only; the production UI/audio
## runner remains the root agent's serial responsibility.
const World = preload("res://scripts/world/continuous_world.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _line(city: World, id: String) -> Dictionary:
	for line in city.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _event(city: World, id: String, kind: String = "transit_line") -> Dictionary:
	for event in city.events:
		if str(event.get("kind","")) == kind and str(event.get("id","")) == id: return event
	return {}

func _positions(city: World) -> Array:
	var result: Array = []
	for road_id: String in ["west-road-1","west-road-2","west-road-3"]:
		for road in city.roads:
			if str(road.get("id","")) != road_id: continue
			var path: PackedVector2Array = road["path"]
			var point := path[path.size()/2]
			result.append([point.x,point.y])
	return result

func _run() -> void:
	var city := World.new("2026101100000165",true,"river_valley")
	city.build_starter("bright")
	var positions := _positions(city)
	var preview := city.transit_plan_preview(positions)
	_check(bool(preview.get("accepted",false)),"real_road_stops_make_a_feedback_route")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	var queued := city.request({"kind":"transit_line","stop_positions":positions,"source_topology":preview["source_topology"]},int(city.cfg["timing"]["phrase_frames"]))
	_check(bool(queued.get("accepted",false)),"route_request_is_accepted_before_boundary")
	var frame := int(queued.get("frame",0))
	city.settle(frame)
	var line_id := "player-line-%d" % int(queued.get("event_id",0))
	var line := _line(city,line_id)
	var route_event := _event(city,line_id)
	var initial := city.transit_music_feedback(line_id)
	_check(not line.is_empty() and not route_event.is_empty(),"settled_route_has_authoritative_event")
	_check(route_event.get("music_feedback",{}) == initial,"route_event_exposes_the_same_feedback_summary")
	_check(str(initial.get("state","")) == "coverage_only","coverage_does_not_claim_passenger_qualification")
	_check(not bool(initial.get("passenger_qualified",true)) and int(initial.get("passenger_visits",-1)) == 0,"no_vehicle_arrival_means_no_music_qualification")
	_check(str(initial.get("functional_role","")) in ["","pulse","pulse_dense"],"feedback_reuses_only_existing_pulse_roles")
	var feedback_events_before := city.events.filter(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "transit_feedback").size()
	for stop_id in line.get("stops",[]): city.record_transit_flow(str(stop_id),6,4,2)
	var next_frame := frame+int(city.cfg["timing"]["phrase_frames"])
	city.settle(next_frame)
	var after := city.transit_music_feedback(line_id)
	_check(bool(after.get("passenger_qualified",false)),"committed_vehicle_arrivals_qualify_the_existing_condition")
	_check(float(after.get("passenger_peak",0.0)) > 0.0 and int(after.get("passenger_visits",0)) > 0,"feedback_reports_real_committed_passenger_memory")
	_check(str(after.get("functional_role","")) in ["pulse","pulse_dense"],"qualified_feedback_stays_on_existing_pulse_roles")
	_check(str(after.get("qualified_role","")) in ["pulse","pulse_dense"],"qualified_feedback_reports_the_role_reached_by_passengers")
	_check(str(after.get("state","")) in ["pulse_active","pulse_dense_active","passenger_memory"],"qualified_feedback_has_an_explicit_state")
	var transit_zone: Dictionary = {}
	for candidate in city.functional_zones:
		if str(candidate.get("role","")) == "transit": transit_zone = candidate; break
	_check(bool(transit_zone.get("passenger_qualified",false)) and float(transit_zone.get("passenger_peak",0.0)) > 0.0,"functional_zone_exposes_committed_passenger_condition")
	_check(city.events.filter(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "transit_feedback").size() > feedback_events_before,"qualification_change_emits_a_lightweight_feedback_event")
	var feedback_event := _event(city,line_id,"transit_feedback")
	_check(feedback_event.get("music_feedback",{}).get("passenger_qualified",false),"feedback_event_carries_the_committed_condition")
	var saved := city.snapshot()
	var restored := World.new(saved["seed_hex"],false)
	restored.restore(saved)
	_check(restored.transit_music_feedback(line_id) == after,"feedback_summary_survives_world_snapshot_restore")
	_check(restored.events.filter(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "transit_feedback").size() == city.events.filter(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "transit_feedback").size(),"feedback_event_history_survives_snapshot_restore")
	_finish()

func _finish() -> void:
	print("ROUND165_TRANSIT_AUDIO_FEEDBACK ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
