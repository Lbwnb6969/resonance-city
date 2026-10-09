class_name WorldSpatialIndex
extends RefCounted
## Buckets accelerate queries; entity coordinates and circle footprints remain continuous.

var cell_size: float
var _entries: Dictionary = {}
var _buckets: Dictionary = {}

func _init(bucket_size: float = 4.0) -> void:
	assert(bucket_size > 0.0)
	cell_size = bucket_size

func put(id: String, center: Vector2, radius: float) -> void:
	assert(not id.is_empty() and radius >= 0.0)
	remove(id)
	var bounds := Rect2(center-Vector2.ONE*radius, Vector2.ONE*radius*2.0)
	var cells := _cells_for(bounds)
	_entries[id] = {"center":center,"radius":radius,"bounds":bounds,"cells":cells}
	for cell in cells:
		if not _buckets.has(cell): _buckets[cell] = {}
		_buckets[cell][id] = true

func remove(id: String) -> bool:
	if not _entries.has(id): return false
	for cell in _entries[id]["cells"]:
		_buckets[cell].erase(id)
		if _buckets[cell].is_empty(): _buckets.erase(cell)
	_entries.erase(id)
	return true

func entry(id: String) -> Dictionary:
	return _entries[id].duplicate(true) if _entries.has(id) else {}

func query_bounds(bounds: Rect2) -> Array[String]:
	assert(bounds.size.x >= 0.0 and bounds.size.y >= 0.0)
	var found: Dictionary = {}
	for cell in _cells_for(bounds):
		for id in _buckets.get(cell, {}):
			var other: Rect2 = _entries[id]["bounds"]
			if bounds.position.x <= other.end.x and bounds.end.x >= other.position.x and bounds.position.y <= other.end.y and bounds.end.y >= other.position.y:
				found[id] = true
	var result: Array[String] = []
	result.assign(found.keys())
	result.sort()
	return result

func query_circle(center: Vector2, radius: float) -> Array[String]:
	assert(radius >= 0.0)
	var result: Array[String] = []
	for id in query_bounds(Rect2(center-Vector2.ONE*radius, Vector2.ONE*radius*2.0)):
		var item: Dictionary = _entries[id]
		var reach := radius + float(item["radius"])
		if center.distance_squared_to(item["center"]) <= reach*reach:
			result.append(id)
	return result

func pairs_within_gap(max_gap: float) -> Array[Dictionary]:
	assert(max_gap >= 0.0)
	var ids: Array[String] = []
	ids.assign(_entries.keys())
	ids.sort()
	var result: Array[Dictionary] = []
	for id in ids:
		var item: Dictionary = _entries[id]
		for other_id in query_circle(item["center"], float(item["radius"])+max_gap):
			if other_id <= id: continue
			var other: Dictionary = _entries[other_id]
			var gap: float = item["center"].distance_to(other["center"])-float(item["radius"])-float(other["radius"])
			result.append({"a":id,"b":other_id,"gap":gap})
	return result

func _cells_for(bounds: Rect2) -> Array[Vector2i]:
	var low := Vector2i(floori(bounds.position.x/cell_size),floori(bounds.position.y/cell_size))
	var high := Vector2i(floori(bounds.end.x/cell_size),floori(bounds.end.y/cell_size))
	var result: Array[Vector2i] = []
	for y in range(low.y, high.y+1):
		for x in range(low.x, high.x+1): result.append(Vector2i(x,y))
	return result
