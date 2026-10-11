extends SceneTree
## Round 166 UI evidence for a player-authored second line joining an existing
## authored line.  The test stays at the production route/tooltip helpers and
## does not change the world or transit planning contracts.

const TransitPlanning = preload("res://scripts/world/transit_planning.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _road_candidates(demo: Control) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	var seen: Array[String] = []
	for road in demo.shown_world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var stop := TransitPlanning.stop_preview(demo.model.world,path[path.size()/2])
		if not bool(stop.get("accepted",false)): continue
		var id := str(stop.get("id",""))
		if id.is_empty() or seen.has(id): continue
		seen.append(id)
		candidates.append(Vector2(float(stop["position"][0]),float(stop["position"][1])))
	return candidates

func _find_route(demo: Control, candidates: Array[Vector2]) -> Array[Vector2]:
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			for k in range(j+1,candidates.size()):
				var preview := TransitPlanning.preview(demo.model.world,[candidates[i],candidates[j],candidates[k]])
				if bool(preview.get("accepted",false)): return [candidates[i],candidates[j],candidates[k]]
	return []

func _find_second_route(demo: Control, anchor: Vector2, candidates: Array[Vector2]) -> Array[Vector2]:
	for i in range(candidates.size()):
		if candidates[i].distance_to(anchor) <= 0.18: continue
		for j in range(i+1,candidates.size()):
			if candidates[j].distance_to(anchor) <= 0.18: continue
			var preview := TransitPlanning.preview(demo.model.world,[anchor,candidates[i],candidates[j]])
			if bool(preview.get("accepted",false)): return [anchor,candidates[i],candidates[j]]
	return []

func _append_route(demo: Control, route: Array[Vector2]) -> void:
	for position in route: demo._append_transit_stop(position)

func _pending_line(world: RefCounted) -> Dictionary:
	for operation in world.pending_actions:
		if str(operation.get("kind","")) == "transit_line": return operation
	return {}

func _authored_lines(world: RefCounted) -> Array[Dictionary]:
	return world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored",false)))

func _settle_pending(demo: Control) -> bool:
	var operation := _pending_line(demo.model.world)
	if operation.is_empty(): return false
	demo.model.world.settle(int(operation.get("frame",-1)))
	demo.shown_world = demo.model.world
	return not _authored_lines(demo.model.world).is_empty()

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)

	var candidates := _road_candidates(demo)
	var first_route := _find_route(demo,candidates)
	check(first_route.size() == 3,"finds_first_authored_route")
	if first_route.size() != 3:
		demo.queue_free()
		await process_frame
		quit(1)
		return

	demo._verb("plan_transit")
	_append_route(demo,first_route)
	check(bool(demo._transit_route_preview().get("accepted",false)),"first_route_preview_is_valid")
	demo._submit_transit_route()
	check(_settle_pending(demo),"first_authored_line_settles")
	var first_lines := _authored_lines(demo.model.world)
	var first_line_name := str(first_lines.back().get("name","自定线路 1")) if not first_lines.is_empty() else ""

	var second_route := _find_second_route(demo,first_route[1],candidates)
	check(second_route.size() == 3,"finds_second_route_sharing_first_station")
	if second_route.size() == 3:
		demo._verb("plan_transit")
		_append_route(demo,second_route)
		var preview: Dictionary = demo._transit_route_preview()
		var summary: Dictionary = demo.planning_guide.transit_preview_feedback(preview)
		var transfer: Dictionary = demo._transit_transfer_feedback(preview,summary)
		check(bool(preview.get("accepted",false)),"second_route_preview_is_valid")
		check(not transfer.get("transfer_stop_ids",[]).is_empty(),"preview_marks_existing_station_as_transfer")
		check(not transfer.get("line_ids",[]).is_empty(),"preview_exposes_existing_line_ids")
		check(str(transfer.get("route_role","")) == "换乘走廊","preview_route_role_is_transfer_corridor")
		check(str(transfer.get("line_names",[])).contains(first_line_name),"preview_names_first_authored_line")
		check(demo._transit_next_phrase_text(transfer,summary).contains("下一乐句"),"preview_explains_next_phrase")
		check(demo._transit_transfer_stop_ids(preview,summary).size() == transfer.get("transfer_stop_ids",[]).size(),"preview_transfer_marker_contract_matches_text")
		demo._submit_transit_route()
		check(_settle_pending(demo),"second_authored_line_settles")
		var station_id := str(transfer["transfer_stop_ids"][0]) if not transfer.get("transfer_stop_ids",[]).is_empty() else ""
		var station: Dictionary = {}
		if not station_id.is_empty(): station = demo._transit_station_at(demo.model.world.transit_stop_position(station_id))
		check(station.get("line_ids",[]).size() >= 2,"settled_shared_station_has_two_lines")
		check(station.get("line_names",[]).size() >= 2,"settled_shared_station_lists_two_line_names")

	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"first_line":first_line_name,"first_route_stops":first_route.size(),"second_route_stops":second_route.size()}
	print("ROUND166_TRANSIT_TRANSFER_UI ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
