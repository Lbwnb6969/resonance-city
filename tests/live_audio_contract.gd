class_name LiveAudioContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Values = preload("res://scripts/spec_values.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var mode := Contract.selected_case("live_supply")
	var assisted := mode == "assist_supply" or mode == "assist_stress"
	var test := Contract.new("AUDIO-004" if assisted else "AUDIO-002",mode)
	var city: Array = Generator.new().generate("2026100800000001")["city"]
	if assisted:
		for index in range(city.size()):
			city[index]["footprint"] = [[(index%8)*2,(index/8)*2]]
		city[0]["footprint"] = [[8,6]]
		city[1]["footprint"] = [[8,7]]
		city[0]["current_midi"] = 48
		city[1]["current_midi"] = 49
	if mode == "assist_stress":
		for index in range(city.size()):
			var row := floori(index/3.0)
			city[index]["footprint"] = [[6+index%3,6+row]]
			city[index]["current_midi"] = 48+(index%3+row)%2
	var synth := Synth.new(city)
	synth.guard_enabled = true
	if assisted:
		synth.device_mode = "narrowband"
		test.check(synth.assist_routes(synth.initial_state()).size() == 9 if mode == "assist_stress" else synth.assist_routes(synth.initial_state()).size() >= 2,"Physical fixture contains requested active slow-beat helpers")
	var offline := Renderer.new()
	offline.source = synth._mix_frame
	offline.state = synth.initial_state()
	var rate := offline.transport.sample_rate
	var start := Time.get_ticks_usec()
	offline.render(rate)
	var render_ms := float(Time.get_ticks_usec() - start) / 1000.0
	test.check(city.size() == int(Values.load_values()["city"]["initial_count"]), "Production nine-district fixture")
	test.check(render_ms < 1000.0, "One second PCM renders faster than real time")
	var clock := root.get_node("AudioClock")
	clock.start_output(synth._mix_frame, synth.initial_state())
	var phrase_seconds := float(clock.renderer.transport.phrase_frame(1)) / rate
	var wall_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - wall_start < phrase_seconds * 1000.0:
		await process_frame
	clock._update_audible()
	var measured_skips: int = clock.underruns
	var audible: float = clock.renderer.transport.audible_frame
	var rendered: int = clock.renderer.transport.rendered_frames
	test.check(AudioServer.get_driver_name() != "Dummy", "Physical audio driver, not dummy headless output")
	test.check(clock.active, "Real AudioStreamGenerator remains active")
	test.check(measured_skips == 0, "No runtime generator underruns")
	test.check(audible > 0.0 and audible <= rendered, "Audible clock progresses within generated PCM")
	test.details = {"district_count":city.size(),"one_second_render_ms":render_ms,
		"wall_ms":Time.get_ticks_msec()-wall_start,"audible_frame":audible,
		"rendered_frames":rendered,"capacity":clock.capacity,"skips":measured_skips,
		"assist_routes":synth.assist_routes(synth.initial_state()).size(),"guard_factor":clock.renderer.state.get("_guard_factor",1.0),"device_mode":synth.device_mode,"driver":AudioServer.get_driver_name(),"hardware_latency":clock.output_latency}
	clock.stop_output()
	test.finish(self, "Actual output device; nine voices with rhythm, one phrase; excludes human audibility")
