extends SceneTree
const Synth = preload("res://scripts/audio/district_synth.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
func _initialize() -> void:
	var city: Array = Generator.new().generate("2026100800000001")["city"]
	var calibration := Calibration.for_city(city)
	for mode in ["normal_city","gray_city"]:
		var synth := Synth.new(city)
		synth.gain = calibration["gain"]
		synth.guard_enabled = true
		if mode == "gray_city":
			synth.set_gray(true,0)
		var pcm := synth.render_block(synth.initial_state(),0,176400,22050)
		var f := FileAccess.open("res://验证记录/P0/声音褪色/"+mode+".f32",FileAccess.WRITE)
		f.store_buffer(pcm.to_byte_array())
		f.close()
	var meta := FileAccess.open("res://验证记录/P0/声音褪色/listening_fixture.json",FileAccess.WRITE)
	meta.store_string(JSON.stringify({"city":city,"calibration":calibration,"sample_rate":22050,"frames":176400,"fade_frames":44100,"assist":false,"scope":"Nine-voice sound review; human beauty and diagnostic masking PENDING"},"\t")+"\n")
	meta.close()
	print("GRAY_CITY_PROOF: same initial public calibration, 8 seconds normal/gray")
	quit()
