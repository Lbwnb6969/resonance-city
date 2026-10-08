class_name LoudnessProbe
extends SceneTree

const Generator = preload("res://scripts/city/city_generator.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Values = preload("res://scripts/spec_values.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory := "res://验证记录/P0/响度探针"
	DirAccess.make_dir_recursive_absolute(directory)
	var fixtures: Dictionary = {}
	var city: Array = Generator.new().safe_fixture()
	fixtures["initial"] = city.duplicate(true)
	for district in city:
		if district["type"] == "industrial":
			district["current_midi"] = 48
	fixtures["retuned_all_industrial_to_C"] = city.duplicate(true)
	var values := Values.load_values()
	var rate := int(values["timing"]["sample_rate"])
	for key in fixtures:
		var synth := Synth.new(fixtures[key])
		var renderer := Renderer.new()
		renderer.source = synth._mix_frame
		renderer.state = synth.initial_state()
		var pcm := renderer.render(roundi(float(values["acoustic_measurement"]["duration_seconds"])*rate))
		var file := FileAccess.open(directory.path_join(key+".f32"),FileAccess.WRITE)
		file.store_buffer(pcm.to_byte_array())
		file.close()
	var output: Array = []
	var code := OS.execute("python",[ProjectSettings.globalize_path("res://tools/analyze_loudness.py")],output,true)
	for line in output:
		print(line)
	quit(code)
