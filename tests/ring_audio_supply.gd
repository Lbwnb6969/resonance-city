extends SceneTree
# One physical phrase with the production main scene at its real growth budget.
const Contract = preload("res://tests/contract_support.gd")
const Model = preload("res://tests/stage_profile_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
func _initialize() -> void: call_deferred("run_check")
func run_check() -> void:
	var test := Contract.new("CITY-005","ring_supply_round57")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	var evidence: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/P0/CITY-005_ring_round57.json"))["details"]
	var initial_city: Array = evidence["initial_city"]
	var grown_city: Array = evidence["controlled_full_city"]
	load("res://scripts/city/city_growth.gd").assign_assets(grown_city)
	var calibration: Dictionary = evidence["calibration"]
	var budget := 27
	var grown_phrases := 0 # explicit controlled two-ring fixture, not naturally generated.
	main.model = Model.new(Session.new(grown_city,main.generation["seed"]))
	main.model.session.growth_enabled = true
	main.model.session.rings = evidence["ring_states"].duplicate(true)
	main.model.synth.sync_rings(main.model.session.rings,0)
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
	test.check(main.model.synth.routing.size() == budget and view.sprites.size() == budget and main.model.synth.ring_snapshot().size() == 16,"Production view and audio routes both contain 27 entities")
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
	test.check(main._audible_session().phrase_index == 1 and main.model.session.city.size() == budget and main.model.session.rings["west_source"]["status"] == "formed" and main.model.session.rings["east_source"]["status"] == "formed","Actual boundary retains both rings and presents the full city")
	test.details = {"fills":main.model.fills,"skip_changes":skip_changes,"slow_frames":slow_frames,"stage_routes":main.model.synth.stage_snapshot(),"initial_entities":initial_city.size(),"district_count":grown_city.size(),"preparation_simulated_phrases":grown_phrases,"driver":AudioServer.get_driver_name(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"seed":main.generation["seed"],"gain":main.model.synth.gain,"initial_calibration":calibration,"skips":max_skips,"wall_ms":Time.get_ticks_msec()-wall_start,"audible_frame":clock.renderer.transport.audible_frame,"rendered_frames":clock.renderer.transport.rendered_frames,"capacity":clock.capacity,"hardware_latency":clock.output_latency}
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	test.check(main.city_summary.text.contains("第2乐句"),"Final HUD shows the new audible session, not preparation frames")
	test.details["hud_summary"] = main.city_summary.text
	root.get_texture().get_image().save_png("res://验证记录/Demo/CITY-005_第57轮/双环满城供音.png")
	clock.stop_output()
	test.finish(self,"Actual main scene, controlled 27 with two independent rings and their one-bar entry, one complete WASAPI audible phrase with unchanged initial-nine gain; not a natural growth run, human listening, long-run performance or narrowband assistance",false)
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if test.failures == 0 else 1)
