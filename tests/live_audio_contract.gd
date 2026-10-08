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
	var test := Contract.new("AUDIO-002", "live_supply")
	var city: Array = Generator.new().generate("2026100800000001")["city"]
	var synth := Synth.new(city)
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
		"driver":AudioServer.get_driver_name(),"hardware_latency":clock.output_latency}
	clock.stop_output()
	test.finish(self, "Actual output device; nine voices with rhythm, one phrase; excludes human audibility")
