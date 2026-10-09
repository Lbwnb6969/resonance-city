extends SceneTree
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Meter = preload("res://scripts/audio/loudness_calibration.gd")
func _initialize() -> void:
	call_deferred("run")
func render(expression: String) -> PackedVector2Array:
	var world := World.new()
	world.build_starter(expression)
	var model := Model.new(world)
	var pcm := PackedVector2Array()
	var state: Dictionary = {}
	for at in range(0,22050*16,512):
		pcm.append_array(model.render_block(state,at,mini(512,22050*16-at),22050))
	return pcm
func run() -> void:
	var bright := render("bright")
	var deep := render("deep")
	var opening := Meter.integrated(bright,22050)
	var target := -16.0
	var peak := 0.0
	for sample in bright: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	var loudness_gain := pow(10.0,(target-float(opening["lufs"]))/20.0)
	var gain := minf(loudness_gain,pow(10.0,-3.0/20.0)/peak)
	var result := {"gain":gain,"initial_lufs":opening["lufs"],"target_lufs":target,"sample_peak_at_gain":peak*gain,
		"reference":"18 authored starter buildings, current community score, complete first phrase; common gain for both expressions",
		"sample_rate":22050,"duration_seconds":16,"source":"scripts/audio/continuous_synth.gd","score_parameters":WorldValues.load_values()["score"]}
	FileAccess.open("res://数据/valley_score_calibration.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	DirAccess.make_dir_recursive_absolute("res://验证记录/连续河谷/社区合奏响度")
	for entry in [["bright",bright],["deep",deep]]:
		var samples: PackedVector2Array = entry[1]
		var bytes := PackedByteArray()
		bytes.resize(samples.size()*8)
		for i in range(samples.size()):
			bytes.encode_float(i*8,samples[i].x*gain)
			bytes.encode_float(i*8+4,samples[i].y*gain)
		FileAccess.open("res://验证记录/连续河谷/社区合奏响度/"+entry[0]+".f32",FileAccess.WRITE).store_buffer(bytes)
	print("SCORE CALIBRATION ",JSON.stringify(result))
	quit()
