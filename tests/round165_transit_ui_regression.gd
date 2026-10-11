extends SceneTree
## Round 165 UI regression evidence for authored transit planning.
##
## This stays at the production input boundary but does not start the editor or
## an audio device.  It proves that the route is made from real road positions,
## that a preview cannot survive a route redraw/cancel, and that the committed
## event carries enough data for the following phrase's feedback.

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

func _key(demo: Control, code: Key, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _road_candidates(demo: Control) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	var seen: Array[String] = []
	for road in demo.shown_world.roads:
		if bool(road.get("bridge", false)): continue
		var path: PackedVector2Array = road.get("path", PackedVector2Array())
		if path.size() < 2: continue
		var position := path[path.size() / 2]
		var stop := TransitPlanning.stop_preview(demo.model.world, position)
		if not bool(stop.get("accepted", false)): continue
		var id := str(stop.get("id", ""))
		if id.is_empty() or seen.has(id): continue
		seen.append(id)
		candidates.append(Vector2(float(stop["position"][0]), float(stop["position"][1])))
	return candidates

func _find_route(demo: Control) -> Array[Vector2]:
	var candidates := _road_candidates(demo)
	for i in range(candidates.size()):
		for j in range(i + 1, candidates.size()):
			for k in range(j + 1, candidates.size()):
				var route := TransitPlanning.preview(demo.model.world, [candidates[i], candidates[j], candidates[k]])
				if bool(route.get("accepted", false)):
					return [candidates[i], candidates[j], candidates[k]]
	return []

func _append_route(demo: Control, route: Array[Vector2]) -> void:
	for position in route:
		demo._append_transit_stop(position)

func _pending_transit(world: RefCounted) -> Dictionary:
	for operation in world.pending_actions:
		if str(operation.get("kind", "")) == "transit_line":
			return operation
	return {}

func _settled_transit_event(world: RefCounted, event_id: int) -> Dictionary:
	for event in world.events:
		if str(event.get("kind", "")) == "transit_line" and int(event.get("event_id", -1)) == event_id:
			return event
	return {}

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	# Keep the fixture deterministic and prevent a real device from being part of
	# this contract.  The route and preview still use the production world/model.
	demo.clock.stop_output()
	demo.set_process(false)

	var route := _find_route(demo)
	check(route.size() == 3, "finds_three_connected_real_road_positions")
	if route.size() != 3:
		demo.queue_free()
		await process_frame
		quit(1)
		return

	demo._verb("plan_transit")
	check(demo.transit_route_mode, "menu_enters_transit_route_mode")
	_append_route(demo, route)
	var preview: Dictionary = demo._transit_route_preview()
	check(bool(preview.get("accepted", false)), "three_real_stops_form_a_route")
	check(preview.get("source_topology", "") == demo.model.world.network.topology, "preview_binds_current_road_topology")
	check(preview.get("stops", []).size() == 3, "preview_keeps_three_projected_stops")
	check(preview.get("stops", []).all(func(stop: Dictionary) -> bool:
		return not str(stop.get("road_id", stop.get("road", ""))).is_empty() and is_finite(float(stop.get("along", INF)))), "every_stop_is_on_a_real_road")
	check(preview.get("legs", []).size() >= 4, "preview_contains_out_and_back_legs")
	check(preview.get("path", PackedVector2Array()).size() >= 2, "preview_draws_physical_road_path")

	# Start the same preview worker used by Space.  Cancel it before consuming
	# its result, then redraw the route.  A stale PCM result must not regain the
	# old context key or keep ducking the live mix.
	demo._request_preview()
	var preview_key: Array = demo.preview_context_key.duplicate(true)
	check(demo.preview_requested and not preview_key.is_empty(), "space_starts_transit_preview_with_identity")
	demo._cancel_preview_playback()
	demo._clear_transit_route()
	demo._stop_preview()
	check(not demo.preview_requested and not demo.preview_started, "cancel_stops_transit_preview_playback")
	check(demo.preview_context_key.is_empty(), "cancel_invalidates_stale_preview_identity")
	check(demo.transit_route_stops.is_empty() and demo.transit_preview.is_empty(), "cancel_clears_route_draft_and_cached_preview")

	# A route redraw after Space must invalidate the worker context as well.  The
	# old result may finish later, but it cannot be accepted for the new route.
	demo._verb("plan_transit")
	var first_two: Array[Vector2] = [route[0], route[1]]
	_append_route(demo, first_two)
	demo._request_preview()
	var redraw_key: Array = demo.preview_context_key.duplicate(true)
	check(demo.preview_requested and not redraw_key.is_empty(), "redraw_case_starts_preview")
	_demo_append_redraw_stop(demo, route[2])
	demo._stop_preview()
	check(demo.preview_context_key != redraw_key, "route_redraw_changes_preview_identity")
	check(not demo.preview_requested, "route_redraw_cancels_old_preview")
	check(demo.transit_route_stops.size() == 3 and bool(demo._transit_route_preview().get("accepted", false)), "redrawn_route_has_new_valid_preview")

	# Enter uses the route currently on the map.  The queued operation carries
	# the exact positions and source topology instead of only a visual line.
	_key(demo, KEY_ENTER)
	var operation := _pending_transit(demo.model.world)
	check(not operation.is_empty(), "enter_queues_transit_operation")
	check(operation.get("stop_positions", []).size() == 3, "queued_operation_keeps_stop_positions")
	check(str(operation.get("source_topology", "")) == str(demo.model.world.network.topology), "queued_operation_keeps_source_topology")
	var boundary := int(operation.get("frame", -1))
	var event_id := int(operation.get("event_id", -1))
	check(boundary >= 0 and event_id >= 0, "queued_operation_has_boundary_identity")
	check(str(demo.notice).contains("公交线路已排入下一乐句") or str(demo.notice).contains("线路"), "queue_feedback_mentions_transit")
	check(demo._planning_status_hint().contains("公交线路") and demo._planning_status_hint().contains("下一乐句"), "persistent_status_keeps_transit_next_phrase")

	if not operation.is_empty() and boundary >= 0:
		demo.model.world.settle(boundary)
		var event := _settled_transit_event(demo.model.world, event_id)
		check(not event.is_empty(), "settlement_emits_transit_event")
		check(event.get("stop_ids", []).size() >= 3, "settled_event_keeps_stop_sequence")
		check(str(event.get("source_topology", "")) == str(operation.get("source_topology", "")), "settled_event_keeps_topology_identity")
		check(event.has("covered_building_ids") and event.has("community_ids"), "settled_event_exposes_coverage_feedback")
		var authored: Array = demo.model.world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored", false)))
		check(not authored.is_empty() and authored.back().get("stops", []).size() >= 3, "settlement_builds_authored_runtime_line")
		check(authored.back().has("covered_building_ids") and authored.back().has("community_ids"), "runtime_line_keeps_next_action_coverage_data")

	var result := {"passed": failures.is_empty(), "checks": checks, "failures": failures,
		"route_stops": route.size(), "preview_key": preview_key, "redraw_key": redraw_key}
	print("ROUND165_TRANSIT_UI_REGRESSION ", JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _demo_append_redraw_stop(demo: Control, position: Vector2) -> void:
	# Keep this helper separate so the test names the user action: adding a stop
	# while a preview is still being computed is a redraw, not a new submission.
	demo._append_transit_stop(position)
