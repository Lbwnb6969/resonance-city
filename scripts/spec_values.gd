class_name ResonantSpec
extends RefCounted

static func load_values() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://数据/spec_values.json"))
	assert(parsed is Dictionary, "Run python tools/build_spec_data.py before opening the project")
	return parsed
