extends RefCounted
static var traveler_type: GDScript
static func traveler_script() -> GDScript:
 if traveler_type != null: return traveler_type
 var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第135轮交通逐帧优化前/city_traveler.gd.txt").replace("\r","")
 traveler_type = GDScript.new()
 # Both sides use the disconnected-line fix; only the old avoidance loop differs.
 traveler_type.source_code = "extends \"res://scripts/visual/city_traveler.gd\"\nfunc _traffic_distance"+source.get_slice("func _traffic_distance",1).get_slice("func _junction_conflict",0)
 assert(traveler_type.reload() == OK)
 return traveler_type
static func demo_script() -> GDScript:
 var script := GDScript.new()
 var source := FileAccess.get_file_as_string("res://scripts/ui/continuous_valley_demo.gd").replace("\r","").replace("class_name ContinuousValleyDemo\n","")
 source = source.replace("var scenery := ValleyScenery.new()", "var scenery: ValleyScenery = preload(\"res://tests/round135_traffic_reference.gd\").scenery_script().new()")
 script.source_code = source
 assert(script.reload() == OK)
 return script
static func scenery_script() -> GDScript:
 var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第135轮交通逐帧优化前/valley_scenery.gd.txt").replace("\r","")
 var add := "func _add"+source.get_slice("func _add",1).get_slice("func snapshot",0)
 add = add.replace("CityTraveler.new(kind,tone)","preload(\"res://tests/round135_traffic_reference.gd\").traveler_script().new(kind,tone)")
 var script := GDScript.new()
 script.source_code = "extends \"res://scripts/visual/valley_scenery.gd\"\n"+add+"func sync"+source.get_slice("func sync",1)
 assert(script.reload() == OK)
 return script
