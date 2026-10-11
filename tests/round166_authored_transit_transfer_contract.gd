extends SceneTree
## Round166: two player-authored lines share a real station, expose a stable
## transfer/coverage contract, and keep it through current and legacy restore.
const World = preload("res://scripts/world/continuous_world.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _midpoints(world: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for road in world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var point := path[0].lerp(path[-1],0.5)
		result.append({"id":str(road.get("id","")),"position":[point.x,point.y]})
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	return result

func _fixture(world: RefCounted, ids: Array[String]) -> Array:
	var by_id: Dictionary = {}
	for road in _midpoints(world): by_id[str(road["id"])] = road["position"]
	var result: Array = []
	for id in ids:
		if not by_id.has(id): return []
		result.append(by_id[id].duplicate(true))
	return result

func _route(world: RefCounted, positions: Array) -> Dictionary:
	return world.transit_plan_preview(positions)

func _line(world: RefCounted,id: String) -> Dictionary:
	for line in world.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _event(world: RefCounted,id: String) -> Dictionary:
	for event in world.events:
		if str(event.get("kind","")) == "transit_line" and str(event.get("id","")) == id: return event
	return {}

func _run() -> void:
	var world := World.new("2026101100000166",true,"river_valley")
	world.build_expanded_town()
	var first_positions := _fixture(world,["west-road-1","west-road-2","west-road-3"])
	var first_preview := _route(world,first_positions)
	_check(bool(first_preview.get("accepted",false)),"first_authored_route_uses_real_roads")
	if not bool(first_preview.get("accepted",false)):
		_finish()
		return
	var first_request := world.request({"kind":"transit_line","stop_positions":first_preview["stop_positions"],"source_topology":first_preview["source_topology"]},int(world.cfg["timing"]["phrase_frames"]))
	_check(bool(first_request.get("accepted",false)),"first_authored_route_queues")
	world.settle(int(first_request.get("frame",world.cfg["timing"]["phrase_frames"])))
	var first_id := "player-line-%d" % int(first_request.get("event_id",0))
	var first_line := _line(world,first_id)
	_check(not first_line.is_empty(),"first_authored_route_settles")
	if first_line.is_empty():
		_finish()
		return

	# Search the existing real road graph for a distinct second itinerary that
	# starts at the first line's physical station and remains connected.
	var second_positions: Array = []
	var second_preview: Dictionary = {}
	var shared_position: Variant = first_preview["stop_positions"][0].duplicate(true)
	var candidates := _midpoints(world)
	for a in candidates:
		for b in candidates:
			if str(a["id"]) == str(b["id"]): continue
			var candidate_positions: Array = [shared_position.duplicate(true),a["position"].duplicate(true),b["position"].duplicate(true)]
			var candidate := _route(world,candidate_positions)
			if not bool(candidate.get("accepted",false)): continue
			if candidate.get("stop_ids",[]) == first_line.get("stops",[]): continue
			second_positions = candidate_positions
			second_preview = candidate
			break
		if not second_preview.is_empty(): break
	_check(not second_preview.is_empty(),"second_route_finds_a_connected_distinct_itinerary")
	if second_preview.is_empty():
		_finish()
		return
	var first_stop_id := str(first_line.get("stops",[""])[0])
	var second_stops: Array = second_preview.get("stops",[])
	var second_first_stop: Dictionary = second_stops[0] if not second_stops.is_empty() else {}
	_check(str(second_first_stop.get("id",second_preview.get("stop_ids",[""])[0])) == first_stop_id,"second_preview_reuses_the_existing_station_identity")
	_check(second_preview.get("transfer_stop_ids",[]).has(first_stop_id),"preview_exposes_shared_transfer_stop")
	_check(second_preview.get("line_ids",[]).has(first_id),"preview_exposes_existing_line_id")
	_check(str(second_preview.get("route_role","")) == "换乘走廊","preview_exposes_transfer_route_role")
	var first_coverage: Dictionary = first_line.get("coverage",{})
	var second_coverage: Dictionary = second_preview.get("coverage",{})
	_check(second_coverage.get("covered_building_ids",[]) != first_coverage.get("covered_building_ids",[]) or second_coverage.get("community_ids",[]) != first_coverage.get("community_ids",[]),"second_preview_reports_coverage_change")

	var second_request := world.request({"kind":"transit_line","stop_positions":second_positions,"source_topology":second_preview["source_topology"]},int(world.cfg["timing"]["phrase_frames"]))
	_check(bool(second_request.get("accepted",false)),"second_authored_route_queues")
	world.settle(int(second_request.get("frame",world.cfg["timing"]["phrase_frames"])))
	var second_id := "player-line-%d" % int(second_request.get("event_id",0))
	var second_line := _line(world,second_id)
	var second_event := _event(world,second_id)
	_check(not second_line.is_empty(),"second_authored_route_settles")
	_check(second_line.get("transfer_stop_ids",[]).has(first_stop_id),"settled_line_exposes_shared_transfer_stop")
	_check(second_line.get("line_ids",[]).has(first_id) and second_line.get("line_ids",[]).has(second_id),"settled_line_exposes_both_line_ids")
	_check(str(second_line.get("route_role","")) == "换乘走廊","settled_line_exposes_transfer_route_role")
	_check(second_line.get("coverage",{}).get("transfer_stop_ids",[]) == second_line.get("transfer_stop_ids",[]),"line_coverage_mirrors_transfer_contract")
	_check(second_event.get("transfer_stop_ids",[]).has(first_stop_id) and second_event.get("line_ids",[]).has(first_id),"settled_event_exposes_transfer_and_line_contract")
	_check(second_event.get("coverage",{}).get("route_role","") == "换乘走廊" and second_event.get("music_feedback",{}) is Dictionary,"settled_event_keeps_coverage_role_and_feedback")

	var saved := world.snapshot()
	var restored := World.new("2026101100000166",true,"river_valley")
	restored.restore(saved)
	var restored_line := _line(restored,second_id)
	var restored_event := _event(restored,second_id)
	_check(restored_line.get("transfer_stop_ids",[]).has(first_stop_id) and restored_line.get("line_ids",[]).has(first_id),"snapshot_restore_keeps_authored_transfer_relation")
	_check(restored_event.get("coverage",{}).get("route_role","") == "换乘走廊" and restored_event.get("transfer_stop_ids",[]).has(first_stop_id),"snapshot_restore_keeps_event_contract")

	# Simulate a pre-Round166 save by removing only the new derived fields. The
	# route intent, station geometry, and event identity remain authoritative.
	var legacy := saved.duplicate(true)
	for line in legacy.get("transit_lines",[]):
		for key in ["line_ids","transfer_stop_ids","coverage","route_role","music_feedback"]: line.erase(key)
	for intent in legacy.get("authored_transit_lines",[]):
		for key in ["line_ids","transfer_stop_ids","route_role"]: intent.erase(key)
	for event in legacy.get("events",[]):
		if str(event.get("kind","")) != "transit_line": continue
		for key in ["line_ids","transfer_stop_ids","coverage","route_role","music_feedback"]: event.erase(key)
	var legacy_restored := World.new("2026101100000166",true,"river_valley")
	legacy_restored.restore(legacy)
	var legacy_line := _line(legacy_restored,second_id)
	var legacy_event := _event(legacy_restored,second_id)
	_check(legacy_line.get("transfer_stop_ids",[]).has(first_stop_id) and legacy_line.get("line_ids",[]).has(first_id),"legacy_save_rehydrates_authored_transfer_relation")
	_check(legacy_event.get("coverage",{}).get("route_role","") == "换乘走廊" and legacy_event.get("transfer_stop_ids",[]).has(first_stop_id),"legacy_save_rehydrates_event_contract")
	_finish()

func _finish() -> void:
	print("ROUND166_AUTHORED_TRANSIT_TRANSFER_CONTRACT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
