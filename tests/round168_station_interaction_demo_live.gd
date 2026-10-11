extends SceneTree
## Round 168 real-window evidence.
##
## This keeps the rendered-window part deterministic: the two authored lines
## are settled through the real World model before the station is clicked, so
## the evidence does not depend on a long wall-clock audio run.  The station
## click, menu rendering and route prefill still use the production Demo code.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")

var demo: Control
var checks: Dictionary = {}
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _road_candidates() -> Array[Vector2]:
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

func _find_route(candidates: Array[Vector2]) -> Array[Vector2]:
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			for k in range(j+1,candidates.size()):
				var preview := TransitPlanning.preview(demo.model.world,[candidates[i],candidates[j],candidates[k]])
				if bool(preview.get("accepted",false)): return [candidates[i],candidates[j],candidates[k]]
	return []

func _find_second_route(anchor: Vector2,candidates: Array[Vector2]) -> Array[Vector2]:
	for i in range(candidates.size()):
		if candidates[i].distance_to(anchor) <= 0.18: continue
		for j in range(i+1,candidates.size()):
			if candidates[j].distance_to(anchor) <= 0.18: continue
			var preview := TransitPlanning.preview(demo.model.world,[anchor,candidates[i],candidates[j]])
			if bool(preview.get("accepted",false)): return [anchor,candidates[i],candidates[j]]
	return []

func _append_route(route: Array[Vector2]) -> void:
	for position in route: demo._append_transit_stop(position)

func _settle_pending() -> bool:
	for operation in demo.model.world.pending_actions:
		if str(operation.get("kind","")) != "transit_line": continue
		demo.model.world.settle(int(operation.get("frame",-1)))
		demo.shown_world = demo.model.world
		return true
	return false

func _click_world(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(position)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _hover_world(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = demo.point(position)
	event.global_position = event.position
	demo._gui_input(event)

func _write_evidence() -> void:
	var directory := "res://验证记录/round168_共享站窗口"
	DirAccess.make_dir_recursive_absolute(directory)
	var image := demo.get_viewport().get_texture().get_image()
	check(image.get_width() >= 800 and image.get_height() >= 600,"window_renders_map")
	image.save_png(directory+"/station_context_live.png")
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"screenshot":directory+"/station_context_live.png"}
	FileAccess.open(directory+"/station_context_live.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND168_STATION_INTERACTION_DEMO_LIVE ",JSON.stringify(evidence))

func _finish() -> void:
	_write_evidence()
	if is_instance_valid(demo): demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	if demo.has_method("_sync_map_labels"): demo._sync_map_labels()
	demo.clock.stop_output()

	var candidates := _road_candidates()
	var first_route := _find_route(candidates)
	check(first_route.size() == 3,"finds_first_authored_route")
	if first_route.size() != 3:
		await _finish()
		return
	demo._verb("plan_transit")
	_append_route(first_route)
	demo._submit_transit_route()
	check(_settle_pending(),"first_line_settles")

	var second_route := _find_second_route(first_route[1],candidates)
	check(second_route.size() == 3,"finds_second_route")
	if second_route.size() != 3:
		await _finish()
		return
	demo._verb("plan_transit")
	_append_route(second_route)
	demo._submit_transit_route()
	check(_settle_pending(),"second_line_settles")

	var station: Dictionary = demo._transit_station_at(second_route[0])
	var feedback: Dictionary = demo._transit_station_feedback(station)
	check(feedback.get("line_ids",[]).size() >= 2,"station_has_two_authored_lines")
	check(feedback.get("line_names",[]).size() >= 2,"station_names_two_authored_lines")
	check(str(feedback.get("state","")) == "shared_station_waiting","station_shows_waiting_transfer_state")
	check(str(feedback.get("next_text","")).contains("第三条线路"),"station_shows_next_composable_action")

	_hover_world(second_route[0])
	await process_frame
	check(demo.tooltip.text.contains("站点 ·") and demo.tooltip.text.contains("下一乐句"),"station_hover_explains_next_action")

	_click_world(second_route[0])
	await process_frame
	await process_frame
	check(demo.menu.visible,"station_context_menu_visible")
	check(str(demo.context.get("kind","")) == "transit_station","station_click_sets_station_context")
	check(demo.menu_info.text.contains("线路：") and demo.menu_info.text.contains("当前换乘："),"station_context_explains_lines_and_transfer")
	check(demo.menu_info.text.contains("下一乐句"),"station_context_explains_next_action")
	check(demo.menu_info.text.contains("成长：") and demo.menu_info.text.contains("合法空地"),"station_context_explains_growth_followup")
	check(not demo.transit_station_focus_id.is_empty(),"station_focus_ring_selected")
	check(not demo.planning_buttons["plan_transit"].disabled,"station_keeps_plan_action_enabled")

	# Pressing the production action button carries the clicked station into the
	# next route draft, matching the offline interaction contract.
	demo.planning_buttons["plan_transit"].emit_signal("pressed")
	check(demo.transit_route_mode,"station_action_enters_transit_planning")
	check(demo.transit_route_stops.size() == 1,"station_action_prefills_first_stop")
	if demo.transit_route_stops.size() == 1:
		check(demo.transit_route_stops[0].distance_to(second_route[0]) < 0.001,"prefilled_stop_keeps_authoritative_position")

	_write_evidence()
	if is_instance_valid(demo): demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
