class_name AcousticContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Values = preload("res://scripts/spec_values.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test := Contract.new("AUDIO-001", Contract.selected_case("all"))
	test.check(test.case_name == "all", "Supported case: all")
	var values := Values.load_values()
	var directory := "res://验证记录/P0/声学"
	DirAccess.make_dir_recursive_absolute(directory)
	var fixtures: Array = [
		{"name":"minor_second","type":"residential","midi":49},
		{"name":"tritone","type":"industrial","midi":54},
		{"name":"perfect_fifth","type":"residential","midi":55}]
	var render_ms: Dictionary = {}
	for fixture in fixtures:
		var first := Schema.create("a", "residential", Vector2i(8,8))
		var second := Schema.create("b", fixture["type"], Vector2i(8,9))
		second["current_midi"] = fixture["midi"]
		var synth := Synth.new([first,second])
		synth.active_layers = ["drone"]
		var renderer := Renderer.new()
		renderer.source = synth._mix_frame
		renderer.state = synth.initial_state()
		var started := Time.get_ticks_msec()
		var pcm := renderer.render(roundi(float(values["acoustic_measurement"]["duration_seconds"]) * renderer.transport.sample_rate))
		render_ms[fixture["name"]] = Time.get_ticks_msec() - started
		var raw := FileAccess.open(directory.path_join(fixture["name"] + ".f32"), FileAccess.WRITE)
		test.check(raw != null, "Actual float32 PCM can be saved")
		if raw != null:
			raw.store_buffer(pcm.to_byte_array())
			raw.close()
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.stereo = true
		wav.mix_rate = renderer.transport.sample_rate
		wav.data = Renderer.pcm16(pcm)
		test.check(wav.save_to_wav(directory.path_join(fixture["name"] + ".wav")) == OK, "Rendered actual drone WAV: " + fixture["name"])
	var output: Array = []
	var code := OS.execute("python", [ProjectSettings.globalize_path("res://tools/analyze_acoustics.py")], output, true)
	for line in output:
		print(line)
	test.check(code == 0, "Declared acoustic protocol passed without assists")
	var report: Variant = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("measurement.json")))
	test.check(report is Dictionary, "Measurement report exists")
	if report is Dictionary:
		for id in ["ACOUSTIC-001","ACOUSTIC-002","ACOUSTIC-003"]:
			test.check(bool(report["checks"][id]), "Original threshold: " + id)
	test.details = {"render_ms":render_ms, "measurement":"验证记录/P0/声学/measurement.json",
		"assist":"OFF","layers":["drone"],"human":"PENDING"}
	test.finish(self, "Actual production drone mixer, published A6 antialiasing protocol, original acoustic thresholds; no human audibility claim")
