extends SceneTree
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Values = preload("res://scripts/spec_values.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var values := Values.load_values()
	var rate := int(values["timing"]["sample_rate"])
	var directory := "res://验证记录/Demo/时代Demo_第61轮/声学"
	DirAccess.make_dir_recursive_absolute(directory)
	for fixture in [{"name":"minor_second","type":"residential","midi":49},{"name":"tritone","type":"industrial","midi":54},{"name":"perfect_fifth","type":"residential","midi":55}]:
		var a := Schema.create("a","residential",Vector2i(8,8))
		var b := Schema.create("b",fixture["type"],Vector2i(8,9))
		a["era"] = 2
		b["era"] = 2
		b["current_midi"] = fixture["midi"]
		var synth := Synth.new([a,b])
		synth.voice_grouping = true
		synth.active_layers = ["drone"]
		synth.assist_enabled = false
		var state := synth.initial_state()
		var end := roundi(float(values["acoustic_measurement"]["duration_seconds"])*rate)
		var file := FileAccess.open(directory+"/"+fixture["name"]+".f32",FileAccess.WRITE)
		for start in range(0,end,512): file.store_buffer(synth.render_block(state,start,mini(512,end-start),rate).to_byte_array())
	print("ERA_VOICE_PCM_READY")
	quit()
