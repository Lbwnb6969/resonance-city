extends SceneTree
## Real-window smoke path for two player-authored lines sharing a station.
const DemoScene = preload("res://scenes/continuous_valley.tscn")

var demo: ContinuousValleyDemo
var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _click_world(position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(position)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _key(code: Key, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _wait_for_authored(count: int, timeout_seconds := 28.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(timeout_seconds*1000.0)
	while Time.get_ticks_msec() < deadline:
		var authored := demo.shown_world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored",false)))
		if authored.size() >= count: return true
		await create_timer(0.1).timeout
	return false

func _queue_route(points: Array[Vector2]) -> Dictionary:
	demo._verb("plan_transit")
	for position in points: _click_world(position)
	var preview := demo._transit_route_preview()
	checks["route_%d_stops" % points.size()] = preview.get("stops",[]).size() == points.size()
	checks["route_%d_accepted" % points.size()] = bool(preview.get("accepted",false))
	_key(KEY_SPACE)
	for index in range(50):
		if demo.preview_started: break
		await create_timer(0.1).timeout
	checks["route_%d_preview_started" % points.size()] = demo.preview_started
	_key(KEY_SPACE,false)
	var frozen_preview := preview.duplicate(true)
	_key(KEY_ENTER)
	return frozen_preview

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await create_timer(0.8).timeout
	var road_points: Array[Vector2] = []
	for road_id in ["west-road-1","west-road-2","west-road-3","west-road-4"]:
		for road in demo.shown_world.roads:
			if str(road.get("id","")) != road_id: continue
			var path: PackedVector2Array = road["path"]
			road_points.append(path[path.size()/2])
	checks["four_real_road_positions"] = road_points.size() == 4
	if road_points.size() < 4:
		_print_and_quit()
		return
	var first := await _queue_route([road_points[0],road_points[1],road_points[2]])
	var first_boundary := demo.model.next_boundary
	while demo.clock.renderer.transport.audible_frame < first_boundary+4410:
		await create_timer(0.1).timeout
	checks["first_line_settles"] = await _wait_for_authored(1)
	var first_lines := demo.shown_world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored",false)))
	var first_line_id := str(first_lines[0].get("id","")) if not first_lines.is_empty() else ""
	var second := await _queue_route([road_points[1],road_points[2],road_points[3]])
	var transfer := demo._transit_transfer_feedback(second,demo.planning_guide.transit_preview_feedback(second))
	checks["second_preview_marks_transfer"] = not transfer.get("transfer_stop_ids",[]).is_empty() and transfer.get("line_ids",[]).has(first_line_id)
	checks["second_preview_names_first_line"] = not transfer.get("line_names",[]).is_empty()
	var second_boundary := demo.model.next_boundary
	while demo.clock.renderer.transport.audible_frame < second_boundary+4410:
		await create_timer(0.1).timeout
	checks["second_line_settles"] = await _wait_for_authored(2)
	var settled := demo.shown_world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored",false)))
	checks["settled_transfer_contract"] = settled.size() >= 2 and settled[1].get("transfer_stop_ids",[]).size() >= 1
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://验证记录/round166_公交换乘")
	get_root().get_texture().get_image().save_png("res://验证记录/round166_公交换乘/transit_transfer_live.png")
	_print_and_quit()

func _print_and_quit() -> void:
	var failures: Array[String] = []
	for name in checks:
		if not checks[name]: failures.append(name)
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	FileAccess.open("res://验证记录/round166_公交换乘/transit_transfer_live.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND166_TRANSIT_TRANSFER_DEMO_LIVE ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
