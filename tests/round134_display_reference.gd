extends RefCounted
static var _growth_script: GDScript
static func growth_script() -> GDScript:
 if _growth_script != null: return _growth_script
 var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第134轮显示准备优化前/audio_growth_mask.gd.txt").replace("\r","")
 var ready := "func _ready()"+source.get_slice("func _ready()",1).get_slice("func begin_at",0)
 var sample := "func sample_frame"+source.get_slice("func sample_frame",1).get_slice("func _process",0)
 var script := GDScript.new()
 script.source_code = "extends \"res://scripts/visual/audio_growth_mask.gd\"\n"+ready+sample
 assert(script.reload() == OK)
 _growth_script = script
 return script
static func demo_script() -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/ui/continuous_valley_demo.gd").replace("\r","").replace("class_name ContinuousValleyDemo\n","")
 source = source.replace("var shadow_layer: CityShadowLayer","var shadow_layer: Node2D")
 source = source.replace("shadow_layer = Shadows.new()","shadow_layer = preload(\"res://tests/round134_shared_masks.gd\").reference_script().new()")
 source = source.replace("GrowthSprite.new()", "preload(\"res://tests/round134_display_reference.gd\").growth_script().new()")
 source = source.replace("GroundLayer.new()","preload(\"res://tests/round134_ground_projection.gd\").reference_script().new()")
 var script := GDScript.new()
 script.source_code = source
 assert(script.reload() == OK)
 return script
