extends SceneTree
## Real-window evidence for clicking a settled shared station and returning to
## authored transit planning with the station already loaded as stop one.

const DemoScene = preload("res://scenes/continuous_valley.tscn")

var demo: ContinuousValleyDemo
var checks: Dictionary = {}

func _click_world(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(position)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _wait_for_authored(count: int, timeout_seconds := 32.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(timeout_seconds*1000.0)
	while Time.get_ticks_msec() < deadline:
		var authored := demo.shown_world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored",false)))
		if authored.size() >= count: return true
		await create_timer(0.1).timeout
	return false

func _queue_route(points: Array[Vector2]) -> int:
	demo._verb("plan_transit")
	for position in points: _click_world(position)
	var boundary := demo.model.next_boundary
	demo._submit_transit_route()
	return boundary

func _road_position(demo_world: RefCounted, road_id: String) -> Vector2:
	for road in demo_world.roads:
		if str(road.get("id","")) != road_id: continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() >= 2: return path[path.size()/2]
	return Vector2.INF

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await create_timer(1.0).timeout
	var points: Array[Vector2] = []
	for road_id in ["west-road-1","west-road-2","west-road-3","west-road-4"]:
		var position := _road_position(demo.shown_world,road_id)
		if position != Vector2.INF: points.append(position)
	checks["four_real_road_positions"] = points.size() == 4
	if points.size() < 4:
		_finish()
		return
	var first_boundary := _queue_route([points[0],points[1],points[2]])
	while demo.clock.renderer.transport.audible_frame < first_boundary+4410: await create_timer(0.1).timeout
	checks["first_line_settles"] = await _wait_for_authored(1)
	var second_boundary := _queue_route([points[1],points[2],points[3]])
	while demo.clock.renderer.transport.audible_frame < second_boundary+4410: await create_timer(0.1).timeout
	checks["second_line_settles"] = await _wait_for_authored(2)
	_click_world(points[1])
	await process_frame
	await process_frame
	checks["station_context_visible"] = demo.menu.visible and demo.menu_info.text.contains("线路：") and demo.menu_info.text.contains("当前换乘：")
	checks["station_action_visible"] = demo.menu_info.text.contains("规划公交线路")
	checks["station_focus_selected"] = not demo.transit_station_focus_id.is_empty()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://验证记录/round167_共享站交互")
	get_root().get_texture().get_image().save_png("res://验证记录/round167_共享站交互/station_context_live.png")
	_finish()

func _finish() -> void:
	var failures: Array[String] = []
	for name in checks:
		if not checks[name]: failures.append(name)
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	DirAccess.make_dir_recursive_absolute("res://验证记录/round167_共享站交互")
	FileAccess.open("res://验证记录/round167_共享站交互/station_context_live.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND167_STATION_INTERACTION_DEMO_LIVE ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
