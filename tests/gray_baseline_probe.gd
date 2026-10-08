extends SceneTree
const Synth = preload("res://scripts/audio/district_synth.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
func _initialize() -> void:
	if FileAccess.file_exists("res://验证记录/P0/声音褪色/normal_before.f32"):
		push_error("Pre-change baseline exists: refuse overwrite")
		quit(1)
		return
	var city: Array = Generator.new().generate("2026100800000001")["city"]
	var synth := Synth.new(city)
	synth.guard_enabled = true
	var pcm := synth.render_block(synth.initial_state(),0,44100,22050)
	var f := FileAccess.open("res://验证记录/P0/声音褪色/normal_before.f32",FileAccess.WRITE)
	f.store_buffer(pcm.to_byte_array())
	f.close()
	print("GRAY_GOLDEN ",pcm.size()," frames")
	quit()
