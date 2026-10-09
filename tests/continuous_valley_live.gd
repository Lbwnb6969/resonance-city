extends SceneTree
const WorldScene = preload("res://scenes/continuous_valley.tscn")
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var trace: Array = []

func _initialize() -> void:
	call_deferred("run")

func key(code: int, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func click(p: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = p
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func boundary() -> void:
	var target := demo.model.next_boundary
	while demo.clock.renderer.transport.audible_frame < target+11025:
		await create_timer(0.25).timeout

func run() -> void:
	demo = WorldScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	var lot: Dictionary = demo.shown_world.lots[18]
	click(demo.point(Vector2(lot["center"][0],lot["center"][1])))
	key(KEY_1)
	key(KEY_1,false)
	checks["floating_seed_queued"] = demo.model.world.pending.get("kind") == "seed"
	await boundary()
	checks["audible_birth"] = demo.shown_world.buildings.size() == 1
	if demo.shown_world.buildings.is_empty():
		finish()
		return
	var id: String = demo.shown_world.buildings[0]["district_id"]
	var community: String = demo.shown_world.by_id[id]["community_id"]
	click(demo.sprites[id].position-Vector2(0,5))
	checks["roof_picks_building"] = demo.context.get("id") == id
	key(KEY_4)
	key(KEY_4,false)
	trace.append({"retune_request":demo.model.world.pending.duplicate(true),"context":demo.context.duplicate(true)})
	key(KEY_SPACE)
	for i in range(40):
		if demo.preview_started: break
		await create_timer(0.1).timeout
	checks["space_preview_with_menu_context"] = demo.preview_started
	key(KEY_SPACE,false)
	await boundary()
	trace.append({"after_retune":demo.shown_world.by_id[id].duplicate(true),"events":demo.model.world.events.duplicate(true)})
	checks["quantized_retune"] = int(demo.shown_world.by_id[id]["current_midi"]) == 55
	checks["stable_community"] = demo.shown_world.by_id[id]["community_id"] == community
	key(KEY_TAB)
	key(KEY_TAB,false)
	checks["community_solo"] = demo.model.synth.listener_community == community
	key(KEY_ESCAPE)
	key(KEY_ESCAPE,false)
	key(KEY_M)
	key(KEY_M,false)
	checks["community_mute"] = bool(demo.model.synth.muted_communities.get(community,false))
	key(KEY_M)
	key(KEY_M,false)
	key(KEY_G)
	key(KEY_G,false)
	trace.append({"bridge_request":demo.model.world.pending.duplicate(true),"notice":demo.notice})
	await boundary()
	checks["bridge_committed_with_real_road"] = demo.shown_world.bridge and demo.shown_world.roads[-1]["from"] == "west-2"
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/最终河谷.png")
	finish()

func finish() -> void:
	checks["no_audio_underruns"] = demo.clock.underruns == 0
	var failed: Array = []
	for name in checks:
		if not checks[name]: failed.append(name)
	var evidence := {"checks":checks,"failures":failed,"runtime":demo.diagnostics(),"trace":trace,"engine":Engine.get_version_info(),
		"scope":"real GPU and audio clock, final continuous scene; UI path injection; three live phrase boundaries, not city-scale performance"}
	var file := FileAccess.open("res://验证记录/连续河谷/实际运行.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t")+"\n")
	file.close()
	print("VALLEY LIVE ",JSON.stringify(evidence))
	quit(0 if failed.is_empty() else 1)
