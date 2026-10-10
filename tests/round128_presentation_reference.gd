extends RefCounted

static func make_script() -> GDScript:
	var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第128轮后台呈现前/continuous_audio_model.gd.txt")
	var script := GDScript.new()
	script.source_code = "extends \"res://scripts/audio/continuous_audio_model.gd\"\n"
	script.source_code += "func _record_presentation"+source.get_slice("func _record_presentation",1).get_slice("func audio_city",0)
	script.source_code += "func presentation_world"+source.get_slice("func presentation_world",1).get_slice("func audible_pitches",0)
	script.source_code += "func capture_state"+source.get_slice("func capture_state",1).get_slice("static func from_state",0)
	assert(script.reload() == OK)
	return script
