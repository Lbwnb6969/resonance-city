extends SceneTree
# One physical phrase with the production main scene at its real growth budget.
const Contract = preload("res://tests/contract_support.gd")
const Model = preload("res://tests/stage_profile_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
func _initialize() -> void: call_deferred("run_check")
func run_check() -> void:
	var test := Contract.new("AUDIO-006","stage_supply_round56")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	var initial_city: Array = main.model.session.city.duplicate(true)
	var calibration: Dictionary = Calibration.for_city(initial_city)
	var budget: int = main.model.session.growth_values["growth"]["max_entities"]
	main.release_armed = true
	var empty: Array = main.model.session._empty_cells()
	empty.sort_custom(func(a: Array,b: Array) -> bool: return Vector2(a[0]-8,a[1]-8).length_squared() < Vector2(b[0]-8,b[1]-8).length_squared())
	for cell in empty:
		var safe := true
		for d in main.model.session.city:
			if d["type"] == "industrial":
				var location: Array = d["footprint"][0]
				safe = safe and absi(cell[0]-location[0])+absi(cell[1]-location[1]) > 5
		if safe:
			main._select_empty(Vector2i(cell[0],cell[1]))
			break
	test.check(main.model.session.pending.get("verb") == "release","Production release queued on a legal cell")
	main.release_button.set_pressed_no_signal(false)
	main.release_armed = false
	main.city_view.release_mode = false
	var grown_phrases := 0
	for phrase in range(36):
		var at: int = main.model.next_boundary
		main.clock.renderer.transport.rendered_frames = at
		main.clock.renderer.render(17)
		main.clock.renderer.transport.audible_frame = at+11042
		grown_phrases += 1
		await process_frame
		if main.model.session.city.size() == budget: break
	var grown_city: Array = main.model.session.city.duplicate(true)
	test.check(initial_city.size() == 9 and grown_city.size() == budget,"Real release/growth rules reach the approved 27-entity budget")
	if test.failures > 0:
		test.finish(self,"Growth fixture preparation failed; no physical supply claim")
		return
	# Reset only this fixture's transport; do not recalibrate the grown mix.
	main.model = Model.new(Session.new(grown_city,main.generation["seed"]))
	main.model.session.growth_enabled = true
	main.model.synth.guard_enabled = true
	main.model.synth.gain = float(calibration["gain"])
	main.calibration = calibration
	var view: Control = main.city_view
	for sprite in view.sprites.values(): sprite.queue_free()
	for label in view.labels.values(): label.queue_free()
	for field in [view.sprites,view.labels,view.forms,view.appearance,view.base_scales,view.event_seen]: field.clear()
	view.session = main.model.session
	main.display_phrase = -1
	main.clock.renderer.transport.rendered_frames = 0
	main.clock.renderer.transport.audible_frame = 0
	main._refresh_district_list()
	main._select_district(grown_city[0]["district_id"])
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	test.check(DisplayServer.get_name() != "headless","Actual city viewport, not headless supply")
	test.check(main.model.synth.routing.size() == budget and view.sprites.size() == budget,"Production view and audio routes both contain 27 entities")
	main.clock.start_output(main.model._mix_frame,main.model.synth.initial_state())
	var clock: Node = main.clock
	var boundary: int = clock.renderer.transport.phrase_frame(1)
	var rate: int = clock.renderer.transport.sample_rate
	var wall_start := Time.get_ticks_msec()
	var deadline := wall_start+ceili(1000.0*boundary/rate)+2000
	var max_skips := 0
	var skip_changes: Array[Dictionary] = []
	var previous_wall := Time.get_ticks_usec()
	var slow_frames: Array[Dictionary] = []
	while clock.active and clock.renderer.transport.audible_frame < boundary and Time.get_ticks_msec() < deadline:
		await process_frame
		clock._update_audible()
		if clock.underruns > max_skips: skip_changes.append({"audible":clock.renderer.transport.audible_frame,"skips":clock.underruns})
		max_skips = maxi(max_skips,clock.underruns)
		var now := Time.get_ticks_usec()
		if now-previous_wall > 30000: slow_frames.append({"audible":clock.renderer.transport.audible_frame,"usec":now-previous_wall})
		previous_wall = now
	test.check(AudioServer.get_driver_name() == "WASAPI","Physical WASAPI output")
	test.check(clock.active and max_skips == 0,"No generator underruns during the physical full-city phrase")
	test.check(clock.renderer.transport.audible_frame >= boundary and clock.renderer.transport.audible_frame <= clock.renderer.transport.rendered_frames,"One complete audible phrase, bounded by generated PCM")
	test.check(main._audible_session().phrase_index == 1 and main.model.session.city.size() == budget,"Actual boundary settles and presents the full city")
	test.details = {"fills":main.model.fills,"skip_changes":skip_changes,"slow_frames":slow_frames,"stage_routes":main.model.synth.stage_snapshot(),"initial_entities":initial_city.size(),"district_count":grown_city.size(),"preparation_simulated_phrases":grown_phrases,"driver":AudioServer.get_driver_name(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"seed":main.generation["seed"],"gain":main.model.synth.gain,"initial_calibration":calibration,"skips":max_skips,"wall_ms":Time.get_ticks_msec()-wall_start,"audible_frame":clock.renderer.transport.audible_frame,"rendered_frames":clock.renderer.transport.rendered_frames,"capacity":clock.capacity,"hardware_latency":clock.output_latency}
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	test.check(main.city_summary.text.contains("第2乐句"),"Final HUD shows the new audible session, not preparation frames")
	test.details["hud_summary"] = main.city_summary.text
	root.get_texture().get_image().save_png("res://验证记录/Demo/A13_U15_第56轮/阶段声层_满城供音.png")
	clock.stop_output()
	test.finish(self,"Actual main scene, 27 naturally generated entities, one WASAPI audible phrase with fixed initial gain; preparation uses simulated boundaries, not a full real-time growth run; excludes human listening, long-run performance and narrowband assistance",false)
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if test.failures == 0 else 1)
