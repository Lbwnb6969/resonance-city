extends SceneTree
const Reference = preload("res://废弃/第119轮_供音优化前/city_shadow_layer.gd")
var failures: Array[String] = []
var comparisons := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var current := CityShadowLayer.new()
	var reference := Reference.new()
	root.add_child(current)
	root.add_child(reference)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
	var entries: Array = manifest["entries"].filter(func(entry: Dictionary) -> bool: return int(entry["era"]) == 1)
	var records: Array[Dictionary] = []
	for i in range(20):
		records.append({"entry":entries[i%entries.size()],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%5)*45,(i/5)*32),"progress":1.0,"visible":true})
	_compare(current,reference,records,"initial union")
	records.append({"entry":entries[0],"base_scale":Vector2.ONE*0.075,"position":Vector2(55,55),"progress":0.0,"visible":true})
	for step in range(1,9):
		records[-1]["progress"] = float(step)/8.0
		_compare(current,reference,records,"growth "+str(step))
	records.append({"entry":entries[1],"base_scale":Vector2.ONE*0.075,"position":Vector2(-100,-90),"progress":1.0,"visible":true})
	_compare(current,reference,records,"bounds expansion")
	records.remove_at(0)
	_compare(current,reference,records,"building retirement")
	records[2]["position"] = Vector2(20,30)
	_compare(current,reference,records,"position replacement")
	records[3]["visible"] = false
	_compare(current,reference,records,"visibility removal")
	records[4]["progress"] = 0.375
	_compare(current,reference,records,"reveal regression")
	var evidence := {"passed":failures.is_empty(),"comparisons":comparisons,"failures":failures}
	FileAccess.open("res://验证记录/连续河谷/第119轮_阴影等价.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("SHADOW_EQUIVALENCE ",JSON.stringify(evidence))
	current.queue_free()
	reference.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _compare(current: CityShadowLayer,reference: Node2D,records: Array[Dictionary],label: String) -> void:
	current.update_records(records)
	reference.update_records(records)
	for kind in ["shadow","contact"]:
		comparisons += 1
		var actual: Sprite2D = current.images[kind]
		var expected: Sprite2D = reference.images[kind]
		if actual.position != expected.position or actual.scale != expected.scale or actual.texture.get_image().get_data() != expected.texture.get_image().get_data():
			failures.append(label+" "+kind)
