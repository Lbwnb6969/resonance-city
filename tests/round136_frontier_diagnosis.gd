extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var saved: Dictionary = FileAccess.open("res://.git/任务备份/round136/original_scale_final.bin",FileAccess.READ).get_var()
	var source := FileAccess.get_file_as_string("res://scripts/world/continuous_world.gd")
	var method := source.substr(source.find("func _grow("),source.find("func _community_adjacency(")-source.find("func _grow("))
	method = method.replace("maxi(0,owned_positions.size()-4)","0")
	var reference := GDScript.new()
	reference.source_code = "extends ContinuousWorld\n"+method
	assert(reference.reload() == OK)
	var city: ContinuousWorld = reference.new(saved["seed_hex"],false)
	city.restore(saved)
	var before := city.buildings.size()
	var started := Time.get_ticks_usec()
	city.settle((city.phrase_index+1)*int(city.cfg["timing"]["phrase_frames"]))
	var result := {"before":before,"after":city.buildings.size(),"settle_ms":float(Time.get_ticks_usec()-started)/1000.0,"profile":city.settle_profile,"reason":city.last_reason}
	FileAccess.open("res://验证记录/连续河谷/第136轮_完整历史前沿诊断.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("FULL_FRONTIER ",JSON.stringify(result))
	quit()
