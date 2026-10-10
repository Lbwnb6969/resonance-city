extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Reference = preload("res://废弃/第118轮_全扫描参考/continuous_world.gd")
var failures: Array[String] = []
var comparisons := 0

func _initialize() -> void:
	for family in ValleyTerrain.family_ids():
		var current := World.new("2026101000000118",true,family)
		var reference := Reference.new("2026101000000118",true,family)
		current.build_expanded_town()
		reference.build_expanded_town()
		_same(current.snapshot(),reference.snapshot(),family+" opening")
		_same(current.fabric_cache,reference.fabric_cache,family+" opening fabric")
		# Signed coordinates, shoreline and parcel/frontage boundaries.
		for y in range(-8,40,2):
			for x in range(-8,40,2):
				var p := Vector2(x+0.37,y+0.41)
				_same(current.placement(p),reference.placement(p),family+" placement "+str(p))
		for phrase in range(1,4):
			var at := int(current.cfg["timing"]["phrase_frames"])*phrase
			if phrase == 1:
				current.request({"kind":"civic","id":"west-civic"},at)
				reference.request({"kind":"civic","id":"west-civic"},at)
			current.settle(at)
			reference.settle(at)
			_same(current.snapshot(),reference.snapshot(),family+" phrase "+str(phrase))
			_same(current.fabric_cache,reference.fabric_cache,family+" fabric "+str(phrase))
		var saved := current.snapshot()
		current.restore(saved)
		reference.restore(saved)
		_same(current.snapshot(),reference.snapshot(),family+" restore")
		_same(current.fabric_cache,reference.fabric_cache,family+" restored fabric")
		print("GEOMETRY_EQUIVALENCE family=",family," buildings=",current.buildings.size())
	var evidence := {"passed":failures.is_empty(),"comparisons":comparisons,"families":5,"failures":failures}
	FileAccess.open("res://验证记录/连续河谷/第118轮_几何等价.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("GEOMETRY_EQUIVALENCE ",JSON.stringify(evidence))
	quit(0 if failures.is_empty() else 1)

func _same(actual: Variant,expected: Variant,label: String) -> void:
	comparisons += 1
	if actual != expected:
		failures.append(label)
		if failures.size() <= 5: print("DIFFERENCE ",label)
