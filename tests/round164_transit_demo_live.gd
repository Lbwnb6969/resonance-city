extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var demo: ContinuousValleyDemo
var checks: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

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

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await create_timer(0.8).timeout
	var road_points: Array[Vector2] = []
	for road_id in ["west-road-1","west-road-2","west-road-3"]:
		for road in demo.shown_world.roads:
			if str(road.get("id","")) != road_id: continue
			var path: PackedVector2Array = road["path"]
			road_points.append(path[path.size()/2])
	demo._verb("plan_transit")
	checks["transit_mode_opens"] = demo.transit_route_mode
	for position in road_points: _click_world(position)
	checks["three_real_stops_placed"] = demo.transit_route_stops.size() == 3 and demo._transit_route_preview().get("accepted",false)
	_key(KEY_SPACE)
	for index in range(40):
		if demo.preview_started: break
		await create_timer(0.1).timeout
	checks["route_preview_started"] = demo.preview_started
	_key(KEY_SPACE,false)
	_key(KEY_ENTER)
	checks["route_pending"] = demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line")
	var boundary := demo.model.next_boundary
	while demo.clock.renderer.transport.audible_frame < boundary+4410:
		await create_timer(0.1).timeout
	var authored := demo.shown_world.transit_lines.filter(func(line: Dictionary) -> bool: return bool(line.get("authored",false)))
	checks["route_settled"] = not authored.is_empty() and authored.back().get("stops",[]).size() >= 3
	checks["route_has_real_coverage"] = not authored.is_empty() and not authored.back().get("covered_building_ids",[]).is_empty()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://验证记录/round164_公交线路")
	get_root().get_texture().get_image().save_png("res://验证记录/round164_公交线路/transit_route_live.png")
	var failures: Array[String] = []
	for name in checks:
		if not checks[name]: failures.append(name)
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"stops":demo.transit_route_stops.size(),"underruns":demo.clock.underruns,"route_preview":demo.transit_preview.duplicate(true)}
	FileAccess.open("res://验证记录/round164_公交线路/transit_route_live.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND164_TRANSIT_DEMO_LIVE ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)
