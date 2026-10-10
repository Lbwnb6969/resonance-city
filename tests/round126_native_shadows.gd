extends SceneTree
var failures: Array[String] = []
var comparisons := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第126轮原生阴影前/city_shadow_layer.gd.txt")
	var script := GDScript.new()
	script.source_code = source.replace("class_name CityShadowLayer\n","")
	assert(script.reload() == OK)
	var current := CityShadowLayer.new()
	var reference: Node2D = script.new()
	root.add_child(current)
	root.add_child(reference)
	_check(current.mask_merger != null,"native mask class available")
	_check_quantization(current)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
	var entries: Array = manifest["entries"].filter(func(entry: Dictionary) -> bool: return int(entry["era"]) == 1)
	var records: Array[Dictionary] = []
	for i in range(20):
		records.append({"entry":entries[i%entries.size()],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%5)*45,(i/5)*32),"progress":1.0,"visible":true})
	_compare(current,reference,records,"initial union")
	_check(current.native_batches > 0,"initial union uses native batches")
	var cached: PackedByteArray = current.static_cache["shadow"]["data"]
	var frozen := cached.duplicate()
	for direction in [Vector2(-120,40),Vector2(340,40),Vector2(40,-120),Vector2(40,280)]:
		var previous_merges := current.static_merge_count
		var previous_resizes := current.retained_resize_count
		records.append({"entry":entries[0],"base_scale":Vector2.ONE*0.075,"position":direction,"progress":1.0,"visible":true})
		_compare(current,reference,records,"mature expansion "+str(direction))
		_check(current.static_merge_count-previous_merges == 2,"only the added mature masks merge "+str(direction))
		_check(current.retained_resize_count-previous_resizes == 2,"native bounds copy "+str(direction))
	_check(cached == frozen,"published mature byte array stays immutable")
	records.append({"entry":entries[1],"base_scale":Vector2.ONE*0.075,"position":Vector2(-240,-240),"progress":0.0,"visible":true})
	var previous_merges := current.static_merge_count
	_compare(current,reference,records,"unrevealed expansion")
	_check(current.static_merge_count == previous_merges,"zero progress expansion keeps mature coverage")
	for progress in [0.01,0.125,0.5,0.999,1.0]:
		records[-1]["progress"] = progress
		_compare(current,reference,records,"edge reveal "+str(progress))
	records.append({"entry":entries[2],"base_scale":Vector2.ONE*0.075,"position":Vector2(800,700),"progress":0.375,"visible":true})
	_compare(current,reference,records,"partial margin")
	previous_merges = current.static_merge_count
	records.remove_at(records.size()-1)
	_compare(current,reference,records,"partial margin contraction")
	_check(current.static_merge_count == previous_merges,"clipped copy avoids mature merges")
	records.remove_at(0)
	_compare(current,reference,records,"mature retirement")
	records[2]["position"] = Vector2(20,30)
	_compare(current,reference,records,"mature replacement")
	records[3]["visible"] = false
	_compare(current,reference,records,"visibility removal")
	records[4]["progress"] = 0.375
	_compare(current,reference,records,"reveal regression")
	records.reverse()
	_compare(current,reference,records,"record reordering")
	var rebuilds := current.rebuild_count
	current.update_records(records)
	_check(current.rebuild_count == rebuilds,"unchanged records keep texture")
	_compare(current,reference,[],"empty visibility")
	_compare(current,reference,records,"return from empty")
	records.clear()
	for i in range(607):
		records.append({"entry":entries[i%entries.size()],"base_scale":Vector2.ONE*0.075,"position":Vector2((i%30)*35,(i/30)*25),"progress":1.0,"visible":true})
	_compare(current,reference,records,"607 mask component warmup")
	previous_merges = current.static_merge_count
	records.append({"entry":entries[0],"base_scale":Vector2.ONE*0.075,"position":Vector2(-200,-150),"progress":1.0,"visible":true})
	records.append({"entry":entries[1],"base_scale":Vector2.ONE*0.075,"position":Vector2(1300,800),"progress":1.0,"visible":true})
	_compare(current,reference,records,"609 mask component expansion")
	_check(current.static_merge_count-previous_merges == 4,"607 old masks reused in each layer")
	records[100]["position"] += Vector2(5,7)
	_compare(current,reference,records,"609 component mature replacement")
	var evidence := {"passed":failures.is_empty(),"comparisons":comparisons,"failures":failures,"component_mature_replacement_script_ms":float(reference.rebuild_usec)/1000.0,"component_mature_replacement_native_ms":float(current.rebuild_usec)/1000.0,"retained_resizes":current.retained_resize_count,"static_merges":current.static_merge_count,"native_batches":current.native_batches,"rounding_levels":256,"scope":"Synthetic mask component plus exact R8 equivalence; real city performance measured separately"}
	FileAccess.open("res://验证记录/连续河谷/第126轮_原生阴影等价.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("SHADOW_BOUNDS ",JSON.stringify(evidence))
	current.queue_free()
	reference.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool,label: String) -> void:
	comparisons += 1
	if not ok: failures.append(label)

func _compare(current: CityShadowLayer,reference: Node2D,records: Array[Dictionary],label: String) -> void:
	current.update_records(records)
	reference.update_records(records)
	for kind in ["shadow","contact"]:
		var actual: Sprite2D = current.images[kind]
		var expected: Sprite2D = reference.images[kind]
		_check(actual.visible == expected.visible,label+" visibility "+kind)
		if actual.visible:
			_check(actual.position == expected.position and actual.scale == expected.scale and actual.texture.get_image().get_data() == expected.texture.get_image().get_data(),label+" exact R8 "+kind)

func _check_quantization(current: CityShadowLayer) -> void:
	var mask := PackedByteArray()
	var initial := PackedByteArray()
	mask.resize(256)
	initial.resize(256)
	for i in range(256):
		mask[i] = i
		initial[i] = (i*17)%256
	var frozen := initial.duplicate()
	var exact := true
	var immutable := true
	for progress in range(256):
		var items: Array[Dictionary] = [{"patch":{"begin":Vector2i(3,4),"size":Vector2i(256,1),"alpha":mask},"progress":progress}]
		current.native_enabled = true
		var actual := current._merge_batch(initial,256,Vector2i(3,4),items)
		current.native_enabled = false
		var expected := current._merge_batch(initial.duplicate(),256,Vector2i(3,4),items)
		exact = exact and actual == expected
		immutable = immutable and initial == frozen
	current.native_enabled = true
	_check(exact,"every byte value at every quantized reveal step matches script")
	_check(immutable,"native batch leaves published source bytes unchanged")
