extends RefCounted
static func job_script() -> GDScript:
 var script := GDScript.new()
 script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第132轮捕获优化前/world_settlement_job.gd.txt").replace("\r","")
 assert(script.reload() == OK)
 return script
static func model_script() -> GDScript:
 var source := FileAccess.get_file_as_string("res://scripts/audio/continuous_audio_model.gd").replace("\r","")
 var script := GDScript.new()
 script.source_code = "extends \"res://scripts/audio/continuous_audio_model.gd\"\n"
 script.source_code += "func prepare_settlement"+source.get_slice("func prepare_settlement",1).get_slice("func _settlement_ready",0)
 script.source_code = script.source_code.replace("settlement_job = SettlementJob.new()","settlement_job = preload(\"res://tests/round132_capture_reference.gd\").job_script().new()")
 assert(script.reload() == OK)
 return script
