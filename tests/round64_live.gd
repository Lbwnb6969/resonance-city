extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var blocks: Array[PackedVector2Array] = []
var record_pcm := false
func _initialize() -> void:
	call_deferred("run")
func _mix_frame(_state: Dictionary,_at: int,_rate: int) -> Vector2: return Vector2.ZERO
func render_block(state: Dictionary,at: int,count: int,rate: int) -> PackedVector2Array:
	var block := demo.model.render_block(state,at,count,rate)
	if record_pcm: blocks.append(block)
	return block
func key(code: int,control: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.ctrl_pressed = control
	demo._input(event)
func screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.archive_directory = "res://验证记录/连续河谷/第64轮_实跑作品/"+str(Time.get_ticks_usec())
	root.add_child(demo)
	await create_timer(0.5).timeout
	key(KEY_T)
	await create_timer(1.2).timeout
	checks["town_80_in_10_communities"] = demo.shown_world.buildings.size() == 80 and demo.shown_world.communities.size() == 10
	checks["six_blocks_two_transit_lines"] = demo.shown_world.blocks.size() == 6 and demo.shown_world.transit_lines.size() == 2 and demo.shown_world.vehicle_kind() == "carriage"
	await screenshot("res://验证记录/连续河谷/第64轮_林荫交响.png")
	# UI save, temporary empty world, and actual audio-clock resume of the saved cursor.
	var saved_frame := demo.clock.renderer.transport.rendered_frames
	var saved_rng := demo.model.world.rng.snapshot()
	var saved_camera := {"zoom":demo.view_zoom,"pan":demo.pan}
	key(KEY_S,true)
	key(KEY_N)
	await create_timer(0.3).timeout
	key(KEY_F9)
	checks["resume_city_rng_and_camera"] = demo.model.world.buildings.size() == 80 and demo.model.world.rng.snapshot() == saved_rng and absf(demo.view_zoom-saved_camera["zoom"]) < 0.00001 and demo.pan.distance_to(saved_camera["pan"]) < 0.00001
	checks["resume_audio_cursor"] = demo.clock.renderer.transport.rendered_frames >= saved_frame and demo.clock.renderer.transport.rendered_frames < saved_frame+16000
	var old_cid: String = demo.model.synth.theme["cid"]
	var bridge_result := demo.model.submit({"kind":"bridge"})
	checks["bridge_queued"] = bool(bridge_result.get("accepted",false))
	# Reach the fourth phrase using the same renderer, then observe the actual live rotation boundary.
	demo.clock.stop_output()
	var renderer := demo.clock.renderer.snapshot()
	var phases: Dictionary = renderer["state"]
	var target := demo.model.phrase_frames*4
	for at in range(int(renderer["transport"]["rendered_frames"]),target-44100,512):
		demo.model.render_block(phases,at,mini(512,target-44100-at),22050)
	renderer["state"] = phases
	renderer["transport"]["rendered_frames"] = target-44100
	renderer["transport"]["audible_frame"] = target-44100
	# Prepare the visual world at the resumed cursor while the audio clock is stopped.
	demo.shown_world = demo.model.presentation_world(target-44100)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	await RenderingServer.frame_post_draw
	demo.clock.start_output(_mix_frame,{},renderer)
	record_pcm = true
	var id: String = demo.model.world.buildings[4]["district_id"]
	demo.model.submit({"kind":"retune","id":id,"midi":57})
	while demo.clock.renderer.transport.audible_frame < target+330750:
		await create_timer(0.1).timeout
	record_pcm = false
	checks["theme_rotates_and_cross_river_answers"] = demo.model.synth.theme["cid"] != old_cid and not demo.model.synth.response.is_empty()
	checks["actual_output_no_underruns"] = demo.clock.underruns == 0
	checks["render_budget"] = demo.model.synth.max_voice_count <= 70
	var peak := 0.0
	var bytes := PackedByteArray()
	var frame_count := 0
	for block in blocks: frame_count += block.size()
	bytes.resize(frame_count*8)
	var index := 0
	for block in blocks:
		for sample in block:
			peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
			bytes.encode_float(index*8,sample.x)
			bytes.encode_float(index*8+4,sample.y)
			index += 1
	checks["sample_peak_headroom"] = peak < pow(10.0,-3.0/20.0)
	DirAccess.make_dir_recursive_absolute("res://验证记录/连续河谷/第64轮_80栋供音")
	FileAccess.open("res://验证记录/连续河谷/第64轮_80栋供音/town.f32",FileAccess.WRITE).store_buffer(bytes)
	var evidence := {"checks":checks,"runtime":demo.diagnostics(),"peak":peak,"recorded_frames":frame_count,
		"max_render_ms":demo.model.max_render_ms,"max_settle_ms":demo.model.max_settle_ms,
		"scope":"80 authored playable buildings in 10 real planned communities, actual audio resume/rotation/retune; approach to fourth phrase advanced by same renderer, not a natural-growth claim"}
	FileAccess.open("res://验证记录/连续河谷/第64轮_实际运行.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND64 LIVE ",JSON.stringify(evidence))
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if checks.values().all(func(value: bool) -> bool: return value) else 1)
