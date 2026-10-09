class_name Audio008ProductionSupply
extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Fixtures = preload("res://tests/audio008_fixtures.gd")
const Model = preload("res://tests/stage_profile_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const DIR = "res://验证记录/Demo/AUDIO-008_第60轮/"
const RATE = 22050
var test: RefCounted
var results: Array = []

func _initialize() -> void: call_deferred("_run")

func _configured(city: Array) -> DistrictSynth:
	var synth := Synth.new(city)
	synth.voice_grouping = true
	synth.guard_enabled = true
	synth.sync_rings(Fixtures.source()["ring_states"],0)
	return synth

func _export(city: Array,gain: float,name: String) -> void:
	var synth := _configured(city)
	synth.gain = gain
	synth.capture_drone = true
	var state := synth.initial_state()
	var mix := FileAccess.open(DIR+name+".f32",FileAccess.WRITE)
	var drone := FileAccess.open(DIR+name+"__drone.f32",FileAccess.WRITE)
	for at in range(0,RATE*16,512):
		mix.store_buffer(synth.render_block(state,at,mini(512,RATE*16-at),RATE).to_byte_array())
		drone.store_buffer(synth.captured_drone.to_byte_array())
	mix.close()
	drone.close()

func _supply(count: int) -> void:
	var city := Fixtures.staged_city(count)
	load("res://scripts/city/city_growth.gd").assign_assets(city)
	var initial := _configured(city)
	var calibration: Dictionary = Fixtures.source()["calibration"] if count == 27 else Calibration.for_synth(initial)
	var fixed_gain := float(calibration["gain"])
	_export(city,fixed_gain,"main_%d" % count)
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	test.check(main.model.synth.voice_grouping,"Actual Demo startup opts into production DSP sharing")
	main.model = Model.new(Session.new(city,main.generation["seed"]))
	main.model.session.growth_enabled = count == 27
	main.model.session.rings = Fixtures.source()["ring_states"].duplicate(true)
	main.model.synth.sync_rings(main.model.session.rings,0)
	main.model.synth.guard_enabled = true
	main.model.synth.voice_grouping = true
	main.model.synth.gain = fixed_gain
	main.calibration = calibration
	var view: Control = main.city_view
	for sprite in view.sprites.values(): sprite.queue_free()
	for label in view.labels.values(): label.queue_free()
	for field in [view.sprites,view.labels,view.forms,view.appearance,view.base_scales,view.event_seen]: field.clear()
	view.session = main.model.session
	main.display_phrase = -1
	main._refresh_district_list()
	main._select_district(city[0]["district_id"])
	await process_frame
	await RenderingServer.frame_post_draw
	var clock: Node = main.clock
	clock.renderer.transport.rendered_frames = 0
	clock.renderer.transport.audible_frame = 0
	clock.start_output(main.model._mix_frame,main.model.synth.initial_state())
	var start := Time.get_ticks_msec()
	var target := RATE*16
	var skips := 0
	while clock.active and clock.renderer.transport.audible_frame < target and Time.get_ticks_msec() < start+19000:
		await process_frame
		clock._update_audible()
		skips = maxi(skips,clock.underruns)
	var result := {"entities":count,"display":DisplayServer.get_name(),"driver":AudioServer.get_driver_name(),"renderer":RenderingServer.get_current_rendering_method(),"gain":fixed_gain,"calibration":calibration,"audible_frames":clock.renderer.transport.audible_frame,"rendered_frames":clock.renderer.transport.rendered_frames,"skips":skips,"wall_ms":Time.get_ticks_msec()-start,"group_stats":main.model.synth.voice_group_stats.duplicate(),"sprites":view.sprites.size(),"ring_routes":main.model.synth.ring_snapshot().size(),"fills":main.model.fills}
	test.check(result["driver"] == "WASAPI" and result["display"] != "headless","Actual GPU/WASAPI main scene")
	test.check(result["sprites"] == count and main.model.synth.routing.size() == count,"Full main scene and real audio routing contain %d entities" % count)
	test.check(skips == 0 and result["audible_frames"] >= target,"%d staged/ring/guard main scene supplies full audible phrase without underrun" % count)
	var shown: CityInterventions = main._audible_session()
	var raw_resonance: float = shown.harmony.resonance(shown.city,shown.harmony.adjacency(shown.city))
	test.check(is_equal_approx(main.audible_resonance,raw_resonance),"Cached audible HUD resonance equals fresh city calculation")
	test.check(main._growth_description(shown) == main.Growth.describe(shown.city,shown._district(main._selected_id()),shown.road_marks),"Cached selected growth text equals fresh condition calculation")
	clock.stop_output()
	clock.renderer.source = Callable()
	results.append(result)
	print("AUDIO008_MAIN_SUPPLY "+JSON.stringify(result))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+"main_%d.png" % count)
	main.queue_free()
	await process_frame
	await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	test = Contract.new("AUDIO-008","production_supply_round60")
	await _supply(27)
	await _supply(64)
	test.details = {"results":results,"scope":"27 production budget at original fixed gain; 64 explicit pressure fixture with prepared-synth calibration, actual main scene/GPU/WASAPI; does not raise gameplay growth limit or prove future timbres"}
	test.finish(self,"Production shared DSP full-main-scene supply at 27 and calibrated 64; peak/RMS independently metered; human/era timbre/long run excluded")
