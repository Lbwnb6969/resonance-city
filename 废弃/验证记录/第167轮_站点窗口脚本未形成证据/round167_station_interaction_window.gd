extends SceneTree
## Fast OpenGL evidence: settle two authored lines through the real scene,
## click their shared station, and capture the actionable station context.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")

var demo: ContinuousValleyDemo
var checks: Dictionary = {}

func _road_candidates() -> Array[Vector2]:
	var result: Array[Vector2] = []
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
		result.append(Vector2(float(stop["position"][0]),float(stop["position"][1])))
	return result

func _route(points: Array[Vector2]) -> Array[Vector2]:
	for i in range(points.size()):
		for j in range(i+1,points.size()):
			for k in range(j+1,points.size()):
				var preview := TransitPlanning.preview(demo.model.world,[points[i],points[j],points[k]])
				if bool(preview.get("accepted",false)): return [points[i],points[j],points[k]]
	return []

func _queue_and_settle(route: Array[Vector2]) -> bool:
	demo._verb("plan_transit")
	for position in route: demo._append_transit_stop(position)
	demo._submit_transit_route()
	for operation in demo.model.world.pending_actions:
		if str(operation.get("kind","")) != "transit_line": continue
		demo.model.world.settle(int(operation.get("frame",-1)))
		demo.shown_world = demo.model.world
		return true
	return false

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var candidates := _road_candidates()
	var first := _route(candidates)
	checks["first_route_found"] = first.size() == 3
	var second: Array[Vector2] = []
	if first.size() == 3:
		checks["first_line_settles"] = _queue_and_settle(first)
		for i in range(candidates.size()):
			if candidates[i].distance_to(first[1]) <= 0.18: continue
			for j in range(i+1,candidates.size()):
				if candidates[j].distance_to(first[1]) <= 0.18: continue
				var candidate := [first[1],candidates[i],candidates[j]] as Array[Vector2]
				if TransitPlanning.preview(demo.model.world,candidate).get("accepted",false):
					second = candidate
					break
			if second.size() == 3: break
	checks["second_route_found"] = second.size() == 3
	if second.size() == 3:
		checks["second_line_settles"] = _queue_and_settle(second)
		var station := demo._transit_station_at(second[0])
		var click := InputEventMouseButton.new()
		click.position = demo.point(second[0])
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		demo._gui_input(click)
		checks["shared_station_has_two_lines"] = station.get("line_ids",[]).size() >= 2
		checks["context_shows_lines_and_next_action"] = demo.menu_info.text.contains("线路：") and demo.menu_info.text.contains("当前换乘：") and demo.menu_info.text.contains("下一乐句")
		checks["context_keeps_plan_action"] = demo.menu.visible and demo.menu_info.text.contains("规划公交线路")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://验证记录/round167_共享站交互")
	get_root().get_texture().get_image().save_png("res://验证记录/round167_共享站交互/station_context_window.png")
	var failures: Array[String] = []
	for key in checks:
		if not checks[key]: failures.append(key)
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	FileAccess.open("res://验证记录/round167_共享站交互/station_context_window.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND167_STATION_INTERACTION_WINDOW ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
