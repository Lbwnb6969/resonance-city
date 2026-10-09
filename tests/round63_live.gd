extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var requests: Array = []
var max_delta := 0.0
func _initialize() -> void:
	call_deferred("run")
func _process(delta: float) -> bool:
	max_delta = maxf(max_delta,delta)
	return false
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	demo._input(event)
func click(p: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)
func screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	demo = DemoScene.instantiate()
	root.add_child(demo)
	await create_timer(1.0).timeout
	checks["starter_18_buildings"] = demo.shown_world.buildings.size() == 18
	await screenshot("res://验证记录/连续河谷/第63轮_晴岸开局.png")
	var first: Dictionary = demo.shown_world.buildings[0]
	var id: String = first["district_id"]
	click(demo.sprites[id].position-Vector2(0,5))
	key(KEY_5)
	var requested_at: float = demo.clock.renderer.transport.audible_frame
	var sound_frame := 0
	for event in demo.model.sound_events:
		if event["kind"] == "retune": sound_frame = int(event["sound_frame"])
	requests.append({"retune":id,"request_frame":requested_at,"sound_frame":sound_frame})
	while demo.clock.renderer.transport.audible_frame < sound_frame+2205:
		await create_timer(0.025).timeout
	checks["retune_next_beat"] = sound_frame > requested_at and float(sound_frame-requested_at)/22050.0 < 0.7 and int(demo.model.audible_pitches().get(id,0)) == 57
	checks["structure_waits_phrase"] = int(demo.shown_world.by_id[id]["current_midi"]) != 57
	key(KEY_ESCAPE)
	var target := demo.model.next_boundary
	var seed_count := 0
	for lot in demo.shown_world.lots:
		if lot["occupant"] != "" or not demo.model.world.placement(Vector2(lot["center"][0],lot["center"][1]))["allowed"]: continue
		click(demo.point(Vector2(lot["center"][0],lot["center"][1])))
		key(KEY_3)
		seed_count += 1
		if seed_count >= 2: break
	key(KEY_ESCAPE)
	key(KEY_G)
	requests.append(demo.model.submit({"kind":"park","id":"east-park"}))
	requests.append(demo.model.submit({"kind":"civic","id":"east-civic"}))
	while demo.clock.renderer.transport.audible_frame < target+22050:
		await create_timer(0.1).timeout
	checks["seed_and_growth_committed"] = demo.shown_world.buildings.size() > 18
	checks["bridge_and_public_sites"] = demo.shown_world.bridge and demo.shown_world.public_sites.all(func(site: Dictionary) -> bool: return site["active"])
	checks["retune_structure_committed"] = int(demo.shown_world.by_id[id]["current_midi"]) == 57
	await screenshot("res://验证记录/连续河谷/第63轮_两岸小城.png")
	var second := demo.model.next_boundary
	while demo.clock.renderer.transport.audible_frame < second+22050:
		await create_timer(0.1).timeout
	checks["two_phrases_no_audio_skips"] = demo.clock.underruns == 0
	checks["voice_budget"] = demo.model.synth.max_voice_count <= 70
	var evidence := {"checks":checks,"runtime":demo.diagnostics(),"requests":requests,"max_render_ms":demo.model.max_render_ms,
		"max_settle_ms":demo.model.max_settle_ms,"max_frame_delta_seconds":max_delta,"scope":"actual GPU and audio output, 18-building starter through two growth boundaries; not final city-scale proof"}
	FileAccess.open("res://验证记录/连续河谷/第63轮_实际运行.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND63 LIVE ",JSON.stringify(evidence))
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if checks.values().all(func(value: bool) -> bool: return value) else 1)
