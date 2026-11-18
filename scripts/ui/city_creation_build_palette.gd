extends RefCounted
static func setup(dock:RefCounted,parent:Control)->void:
	preload("res://scripts/ui/city_creation_shape_palette.gd").new().setup(dock,parent)
