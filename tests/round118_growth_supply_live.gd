extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await create_timer(0.6).timeout
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	demo._input(key)
	await create_timer(0.8).timeout
	var site: Dictionary = {}
	for candidate in demo.shown_world.public_sites:
		if candidate["kind"] == "civic" and candidate["active"]:
			site = candidate
			break
	var event := InputEventMouseButton.new()
	event.position = demo.point(Vector2(site["position"][0],site["position"][1]))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)
	checks["click_opens_civic_context"] = demo.context.get("id","") == site["id"]
	demo._verb("civic")
	checks["ui_queues_expansion"] = demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return op["kind"] == "civic" and op["id"] == site["id"])
	checks["shown_level_waits_for_audio"] = int(site.get("service_level",1)) == 1
	var target: int = demo.model.next_boundary
	while demo.clock.renderer.transport.audible_frame < target+2*demo.model.phrase_frames+4410:
		await create_timer(0.1).timeout
	var revealed: Dictionary = {}
	for candidate in demo.shown_world.public_sites:
		if candidate["id"] == site["id"]: revealed = candidate
	checks["live_expansion_revealed"] = int(revealed.get("service_level",1)) == 2 and int(revealed.get("service_capacity",0)) == 36
	checks["real_output_no_underruns"] = demo.clock.underruns == 0
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/第118轮_成长供音.png")
	var passed := checks.values().all(func(value: bool) -> bool: return value)
	var evidence := {"passed":passed,"checks":checks,"summary":demo.shown_world.public_service_summary(),"skips":demo.clock.underruns,"capacity":demo.clock.capacity,"sample_rate":demo.clock.renderer.transport.sample_rate,"phrases":demo.shown_world.phrase_index,"max_settle_ms":demo.model.max_settle_ms,"max_render_ms":demo.model.max_render_ms,"settle_profile":demo.model.world.settle_profile}
	FileAccess.open("res://验证记录/连续河谷/第118轮_成长供音.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("GROWTH_SUPPLY_LIVE ",JSON.stringify(evidence))
	demo.queue_free()
	await process_frame
	quit(0 if passed else 1)
