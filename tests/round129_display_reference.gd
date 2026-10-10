extends RefCounted

static func make_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = "extends \"res://scripts/ui/continuous_valley_demo.gd\"\nfunc _shown_city_key() -> Array:\n\treturn [shown_world,shown_world.phrase_index]\n"
	assert(script.reload() == OK)
	return script
