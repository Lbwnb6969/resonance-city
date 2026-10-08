extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Mask = preload("res://scripts/visual/audio_growth_mask.gd")
const Values = preload("res://scripts/spec_values.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test := Contract.new("UI-004","visual_clock")
	var timing: Dictionary = Values.load_values()["timing"]
	var rate := int(timing["sample_rate"])
	var beat_frames := roundi(60.0*rate/float(timing["bpm"]))
	var mask := Mask.new()
	mask.use_master_clock = false
	root.add_child(mask)
	test.check(mask.STEP_FRAMES == beat_frames and beat_frames == 11025,"STEP_FRAMES is one beat, not legacy eighth note")
	mask.begin_at(30000)
	test.check(mask.sample_frame(29999) == 0 and mask.sample_frame(30000) == 0,"Before/start mask is closed")
	test.check(mask.sample_frame(30000+beat_frames*0.5) == 0.5,"Half beat reveals half the UV height")
	test.check(mask.sample_frame(30000+beat_frames) == 1 and mask.sample_frame(90000) == 1,"Exact endpoint and later frames fully revealed")
	var fps_evidence: Array = []
	var clock := root.get_node("AudioClock") as AudibleAudioClock
	var transport := clock.renderer.transport
	var saved_audible := transport.audible_frame
	var saved_rendered := transport.rendered_frames
	mask.use_master_clock = true
	for fps in [15,30,60,144]:
		mask.begin_at(30000)
		var matches := true
		for draw in range(fps+2):
			var at := 30000.0+float(draw)*rate/float(fps)
			transport.audible_frame = at
			transport.rendered_frames = ceili(at+rate*0.12)
			mask._process(0.001 if draw%2 == 0 else 4.0)
			matches = matches and is_equal_approx(mask.progress,clampf((at-30000.0)/beat_frames,0.0,1.0))
		test.check(matches and mask.end_frame() == 30000+beat_frames,"Frame rate/delta do not change audio endpoint: "+str(fps))
		fps_evidence.append({"visual_fps":fps,"scheduled_end_frame":mask.end_frame()})
	mask.begin_at(0)
	transport.rendered_frames = rate*10
	transport.audible_frame = beat_frames*0.25
	mask._process(100.0)
	test.check(mask.progress == 0.25,"Reads audible frame; queued/rendered future and delta are ignored")
	transport.audible_frame = saved_audible
	transport.rendered_frames = saved_rendered
	mask.use_master_clock = false
	var other := Mask.new()
	other.use_master_clock = false
	root.add_child(other)
	other.begin_at(0)
	other.sample_frame(0.75*beat_frames)
	mask.sample_frame(0.25*beat_frames)
	test.check(mask.material != other.material and mask.material.get_shader_parameter("growth_progress") == 0.25 and other.material.get_shader_parameter("growth_progress") == 0.75,"Per-sprite masks have independent shader uniforms")
	test.check(mask.get_child_count() == 0 and other.get_child_count() == 0,"Mask keeps one Sprite2D per building")
	var rendered: Dictionary = {"status":"PENDING: headless only checks clock/structure"}
	if DisplayServer.get_name() != "headless":
		RenderingServer.set_default_clear_color(Color("343943"))
		var nodes: Array[Sprite2D] = []
		for index in range(3):
			var item := Mask.new()
			item.use_master_clock = false
			item.texture = load("res://资源/P0城市/整图/residential_building_type_a_01_base.png")
			item.centered = false
			item.position = Vector2(120+440*index,310)
			item.scale = Vector2.ONE*0.16
			root.add_child(item)
			item.begin_at(0)
			item.sample_frame(beat_frames*index*0.5)
			nodes.append(item)
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		DirAccess.make_dir_recursive_absolute("res://验证记录/P0/视觉时钟")
		shot.save_png("res://验证记录/P0/视觉时钟/0_半拍_一拍.png")
		var counts: Array[int] = [0,0,0]
		var bg := shot.get_pixel(10,10)
		for index in range(3):
			for y in range(300,570):
				for x in range(110+440*index,460+440*index):
					if shot.get_pixel(x,y) != bg:
						counts[index] += 1
		test.check(counts[0] == 0 and counts[1] > 0 and counts[1] < counts[2],"Real GPU alpha mask renders closed/partial/full")
		rendered = {"status":"real Compatibility rendered","visible_pixels":counts,"screenshot":"验证记录/P0/视觉时钟/0_半拍_一拍.png"}
		for node in nodes:
			node.queue_free()
	mask.queue_free()
	other.queue_free()
	await process_frame
	test.details = {"sample_rate":rate,"beat_frames":beat_frames,"frame_rate_cases":fps_evidence,"rendered":rendered,"scope":"Timing primitive only, no CITY-004 mechanics; visible updates still have one display-frame sampling delay"}
	test.finish(self,"Audible-frame driven one-beat shader mask; no Tween or city growth triggers")
