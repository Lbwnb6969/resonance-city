class_name WorldFoundationProbe
extends SceneTree

const IsoProjection = preload("res://scripts/world/world_projection.gd")
const Spatial = preload("res://scripts/world/world_spatial_index.gd")
const Drainage = preload("res://scripts/world/terrain_drainage.gd")

var failures: Array[String] = []
var checks := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _init() -> void:
	probe_projection()
	probe_spatial()
	probe_drainage()
	var evidence := {"checks":checks,"failures":failures,"scope":"continuous projection, footprint queries and deterministic drainage; no playable integration or scale claim"}
	print(JSON.stringify(evidence))
	var target := "res://验证记录/技术准备/2026-10-09_世界基础.json"
	var folder := DirAccess.open("res://")
	folder.make_dir_recursive("验证记录/技术准备")
	var file := FileAccess.open(target,FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"  ")+"\n")
	file.close()
	quit(0 if failures.is_empty() else 1)

func probe_projection() -> void:
	for p in [Vector2(-3.125,7.75),Vector2(0.015,-0.015),Vector2(39.9,4.2)]:
		for zoom in [0.25,1.0,2.4]:
			var screen := IsoProjection.to_screen(p,Vector2(720,240),zoom,Vector2(28,14),1.7)
			var recovered := IsoProjection.from_screen(screen,Vector2(720,240),zoom,Vector2(28,14),1.7)
			expect(p.distance_to(recovered) < 1e-4,"projection fractional round trip")
	expect(IsoProjection.to_screen(Vector2(2,1),Vector2.ZERO,1.0) == Vector2(28,42),"projection known value")

func probe_spatial() -> void:
	var index := Spatial.new(4.0)
	var reference: Dictionary = {}
	for i in range(96):
		var id := "b_%03d"%i
		var center := Vector2(float((i*37)%120)/4.0-10.0,float((i*19)%100)/4.0-8.0)
		var radius := 4.5 if i == 7 else 0.45
		index.put(id,center,radius)
		reference[id] = {"center":center,"radius":radius}
	index.put("b_020",Vector2(-24.25,13.75),0.8)
	reference["b_020"] = {"center":Vector2(-24.25,13.75),"radius":0.8}
	expect(index.remove("b_008"),"remove known entity")
	reference.erase("b_008")
	for center in [Vector2(-24,14),Vector2(-4,-4),Vector2.ZERO,Vector2(8,4),Vector2(15,14)]:
		for radius in [0.0,1.0,4.0]:
			var wanted: Array[String] = []
			for id in reference:
				var reach: float = radius+float(reference[id]["radius"])
				if center.distance_squared_to(reference[id]["center"]) <= reach*reach: wanted.append(id)
			wanted.sort()
			expect(index.query_circle(center,radius) == wanted,"indexed query equals independent exhaustive query")
	var wanted_pairs: Array[String] = []
	var ids := reference.keys()
	ids.sort()
	for a in range(ids.size()):
		for b in range(a+1,ids.size()):
			var first: Dictionary = reference[ids[a]]
			var second: Dictionary = reference[ids[b]]
			if first["center"].distance_to(second["center"])-float(first["radius"])-float(second["radius"]) <= 4.0: wanted_pairs.append(ids[a]+"|"+ids[b])
	var actual_pairs: Array[String] = []
	for pair in index.pairs_within_gap(4.0): actual_pairs.append(pair["a"]+"|"+pair["b"])
	expect(actual_pairs == wanted_pairs,"gap pairs include large footprints and have no duplicates")
	index.put("touch",Vector2(-30,0),1.0)
	expect(index.query_circle(Vector2(-28,0),1.0).has("touch"),"tangent footprints across negative buckets")

func probe_drainage() -> void:
	var diagonal := Drainage.build(PackedFloat64Array([0,5,5,5,1,5,5,5,5]),3,3)
	expect(diagonal["drainage_height"][4] == 1.0 and diagonal["downstream"][4] == 0,"D8 diagonal outlet avoids artificial fill")
	var examples := [PackedFloat64Array([5,5,5,5,5,5,1,1,1,5,5,1,0,1,3,5,1,1,1,5,5,5,5,5,5]),PackedFloat64Array([2,2,2,2,2,2,2,2,2]),PackedFloat64Array([4,3,2,3,2,1,2,1,0])]
	for heights in examples:
		var width := 5 if heights.size() == 25 else 3
		var original: PackedFloat64Array = heights.duplicate()
		var built := Drainage.build(heights,width,width)
		var again := Drainage.build(heights,width,width)
		expect(built == again,"drainage deterministic on basin/flat/slope")
		expect(heights == original,"original visible terrain retained")
		var outlet_sum := 0.0
		var legal := true
		for id in range(heights.size()):
			var next := int(built["downstream"][id])
			legal = legal and float(built["fill_depth"][id]) >= 0.0
			if next < 0:
				outlet_sum += float(built["accumulation"][id])
			else:
				var path := Drainage.path_to_outlet(id,built["downstream"])
				legal = legal and path.size() <= heights.size() and int(built["downstream"][path[-1]]) == -1 and float(built["drainage_height"][next]) <= float(built["drainage_height"][id])
		expect(legal,"every route reaches outlet without cycle or uphill drainage surface")
		expect(outlet_sum == float(heights.size()),"unit rainfall conserved at outlets")
		if heights.size() == 25: expect(built["drainage_height"][12] == 3.0,"basin reaches lowest spill elevation")
	var custom := Drainage.build(PackedFloat64Array([2,2,2,2,2,2,2,2,2]),3,3,PackedInt32Array([0]))
	expect(custom["accumulation"][0] == 9.0,"explicit outlet receives all flat drainage")
