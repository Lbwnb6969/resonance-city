extends SceneTree
## Round 167 UI evidence: a shared station explains its two authored lines,
## committed passenger state, and the next planning action. Clicking the station
## opens the ordinary planning menu with that station preloaded as stop one.

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

func _settle_pending(demo: Control) -> bool:
	var operation := _pending_line(demo.model.world)
	if operation.is_empty(): return false
	demo.model.world.settle(int(operation.get("frame",-1)))
	demo.shown_world = demo.model.world
	return true

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
	demo._submit_transit_route()
	check(_settle_pending(demo),"first_line_settles")

	var second_route := _find_second_route(demo,first_route[1],candidates)
	check(second_route.size() == 3,"finds_second_route")
	if second_route.size() == 3:
		demo._verb("plan_transit")
		_append_route(demo,second_route)
		demo._submit_transit_route()
		check(_settle_pending(demo),"second_line_settles")
		var station_position := second_route[0]
		var station: Dictionary = demo._transit_station_at(station_position)
		var feedback: Dictionary = demo._transit_station_feedback(station)
		var context_text: String = demo._transit_station_context_text(station)
		check(feedback.get("line_ids",[]).size() >= 2,"shared_station_feedback_has_two_lines")
		check(feedback.get("line_names",[]).size() >= 2,"shared_station_feedback_names_two_lines")
		check(str(feedback.get("state","")) == "shared_station_waiting","shared_station_exposes_waiting_state_before_passengers")
		check(str(feedback.get("next_text","" )).contains("第三条线路"),"shared_station_exposes_next_composable_action")
		check(context_text.contains("线路：") and context_text.contains("当前换乘：") and context_text.contains("下一乐句"),"station_context_text_is_causal")
		var click := InputEventMouseButton.new()
		click.position = demo.point(station_position)
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		demo._gui_input(click)
		check(str(demo.context.get("kind","")) == "transit_station","click_opens_station_context")
		check(demo.menu.visible and demo.menu_info.text.contains("规划公交线路"),"click_opens_action_menu")
		check(not demo.planning_buttons["plan_transit"].disabled,"station_context_keeps_transit_action_enabled")
		# The action must carry the clicked stable station into the next route draft.
		demo.planning_buttons["plan_transit"].emit_signal("pressed")
		check(demo.transit_route_mode and demo.transit_route_stops.size() == 1,"planning_action_prefills_clicked_station")
		check(demo.transit_route_stops[0].distance_to(station_position) < 0.001,"prefilled_station_keeps_authoritative_position")

	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	print("ROUND167_STATION_INTERACTION_UI ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
