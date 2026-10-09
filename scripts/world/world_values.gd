class_name WorldValues
extends RefCounted

static var _values: Dictionary = {}

static func load_values() -> Dictionary:
	if _values.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://数据/world_v2.json"))
		assert(parsed is Dictionary and int(parsed.get("schema_version",0)) == 2, "Generate continuous schema 2 with tools/build_spec_data.py")
		_values = parsed
	return _values
