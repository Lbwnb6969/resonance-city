extends SceneTree
## Round 168 contract: committed station demand becomes a bounded, local
## growth preference and remains readable in the existing music feedback.

const World = preload("res://scripts/world/continuous_world.gd")

var failures: Array[String] = []
var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _first_line_and_stop(world: RefCounted) -> Dictionary:
	for line in world.transit_lines:
		for raw_stop in line.get("stops",[]):
			var stop_id := str(raw_stop)
			var record: Dictionary = world.transit_stop_record(stop_id)
			if not record.is_empty(): return {"line":line,"stop_id":stop_id,"stop":record}
	return {}

func _near_and_far(world: RefCounted,station: Vector2) -> Dictionary:
	var near := Vector2.INF
	var far := station+Vector2(40.0,40.0)
	for lot in world.lots:
		if not str(lot.get("occupant","" )).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if near == Vector2.INF and p.distance_to(station) <= 4.5 and world.network.walking_distance(p,station) <= 4.5:
			near = p
		if p.distance_to(station) >= 12.0 and world.network.walking_distance(p,station) > 8.0:
			far = p
	if near == Vector2.INF: near = station
	return {"near":near,"far":far}

func _run() -> void:
	var world := World.new("2026101100000168",true,"river_valley")
	world.build_expanded_town()
	var selected := _first_line_and_stop(world)
	check(not selected.is_empty(),"expanded_city_exposes_line_and_station")
	if selected.is_empty():
		print("ROUND168_TRANSIT_GROWTH_DEMAND ",JSON.stringify({"passed":false,"checks":checks,"failures":failures}))
		quit(1)
		return
	var line: Dictionary = selected["line"]
	var stop_id := str(selected["stop_id"])
	var stop: Dictionary = selected["stop"]
	var station := Vector2(float(stop["position"][0]),float(stop["position"][1]))
	var positions := _near_and_far(world,station)
	var near: Vector2 = positions["near"]
	var far: Vector2 = positions["far"]
	var before := world._transit_growth_bonus(near,"commercial")
	var far_before := world._transit_growth_bonus(far,"commercial")
	check(world.transit_demand_score(stop_id) == 0.0,"unobserved_station_has_no_demand_memory")
	check(before >= far_before,"station_proximity_is_existing_growth_signal")

	# The observation is intentionally committed through the same boundary-side
	# merge used by settle(): pending flow never affects growth immediately.
	world.record_transit_flow(stop_id,6,4,2)
	var pending_bonus := world._transit_growth_bonus(near,"commercial")
	check(world.transit_demand_score(stop_id) == 0.0,"pending_flow_does_not_change_growth_before_boundary")
	check(is_equal_approx(pending_bonus,before),"pending_flow_keeps_growth_stable_before_boundary")
	world._commit_transit_flow()
	var score := world.transit_demand_score(stop_id)
	var after := world._transit_growth_bonus(near,"commercial")
	var far_after := world._transit_growth_bonus(far,"commercial")
	check(score > 0.0,"committed_station_flow_creates_demand_memory")
	check(after > before,"committed_demand_nudges_nearby_legal_growth")
	check(is_equal_approx(far_after,far_before),"demand_does_not_create_global_growth_bonus")

	var feedback := world.transit_music_feedback(str(line.get("id","")))
	var growth_action: Dictionary = feedback.get("growth_action",{})
	check(str(growth_action.get("kind","")) == "prioritize_near_station","feedback_exposes_executable_growth_action")
	check(str(feedback.get("growth_hint","" )).contains("附近合法空地"),"feedback_explains_spatial_growth_cause")
	check(float(growth_action.get("demand_peak",0.0)) > 0.0,"growth_action_reports_committed_demand")
	check(bool(growth_action.get("bounded",false)),"growth_action_declares_bounded_effect")
	check(str(feedback.get("state","")) in ["passenger_memory","pulse_active","pulse_dense_active","coverage_only"],"existing_music_feedback_state_is_preserved")

	var forked: World = world.fork()
	check(is_equal_approx(forked.transit_demand_score(stop_id),score),"demand_memory_survives_world_fork")
	check(forked.transit_music_feedback(str(line.get("id",""))).get("growth_action",{}).get("kind","") == "prioritize_near_station","growth_action_survives_world_fork")
	print("ROUND168_TRANSIT_GROWTH_DEMAND ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"line_id":line.get("id",""),"stop_id":stop_id,"before":before,"after":after,"far_before":far_before,"far_after":far_after,"score":score}))
	quit(0 if failures.is_empty() else 1)
