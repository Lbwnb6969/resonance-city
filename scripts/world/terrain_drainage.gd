class_name TerrainDrainage
extends RefCounted
## Priority flood with a deterministic parent forest on a D8 sampling grid.
## The drainage surface is separate from the visible, original terrain.

const DIRECTIONS := [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i(-1,-1),Vector2i(1,-1),Vector2i(1,1),Vector2i(-1,1)]

static func build(heights: PackedFloat64Array, width: int, height: int, outlets: PackedInt32Array = PackedInt32Array()) -> Dictionary:
	assert(width > 0 and height > 0 and heights.size() == width*height)
	var filled := heights.duplicate()
	var downstream := PackedInt32Array()
	downstream.resize(heights.size())
	downstream.fill(-1)
	var visited := PackedByteArray()
	visited.resize(heights.size())
	var heap: Array[Dictionary] = []
	var seeds := outlets.duplicate()
	if seeds.is_empty():
		for y in range(height):
			for x in range(width):
				if x == 0 or y == 0 or x == width-1 or y == height-1: seeds.append(y*width+x)
	seeds.sort()
	for id in seeds:
		assert(id >= 0 and id < heights.size())
		if visited[id] != 0: continue
		visited[id] = 1
		_push(heap, {"id":id,"level":filled[id]})
	var order := PackedInt32Array()
	while not heap.is_empty():
		var node := _pop(heap)
		var id := int(node["id"])
		order.append(id)
		var x := id%width
		var y := id/width
		for direction in DIRECTIONS:
			var nx: int = x+direction.x
			var ny: int = y+direction.y
			if nx < 0 or nx >= width or ny < 0 or ny >= height: continue
			var next := ny*width+nx
			if visited[next] != 0: continue
			visited[next] = 1
			filled[next] = maxf(heights[next],filled[id])
			downstream[next] = id
			_push(heap, {"id":next,"level":filled[next]})
	var accumulation := PackedFloat64Array()
	accumulation.resize(heights.size())
	accumulation.fill(1.0)
	for i in range(order.size()-1,-1,-1):
		var id := order[i]
		if downstream[id] >= 0: accumulation[downstream[id]] += accumulation[id]
	var depth := PackedFloat64Array()
	depth.resize(heights.size())
	for id in range(heights.size()): depth[id] = filled[id]-heights[id]
	return {"drainage_height":filled,"fill_depth":depth,"downstream":downstream,"accumulation":accumulation,"order":order}

static func path_to_outlet(start: int, downstream: PackedInt32Array) -> PackedInt32Array:
	assert(start >= 0 and start < downstream.size())
	var path := PackedInt32Array()
	var id := start
	while id >= 0:
		path.append(id)
		assert(path.size() <= downstream.size(), "Drainage graph contains a cycle")
		id = downstream[id]
	return path

static func _before(a: Dictionary, b: Dictionary) -> bool:
	return int(a["id"]) < int(b["id"]) if float(a["level"]) == float(b["level"]) else float(a["level"]) < float(b["level"])

static func _push(heap: Array[Dictionary], node: Dictionary) -> void:
	heap.append(node)
	var child := heap.size()-1
	while child > 0:
		var parent := (child-1)/2
		if not _before(heap[child],heap[parent]): break
		var swap := heap[parent]
		heap[parent] = heap[child]
		heap[child] = swap
		child = parent

static func _pop(heap: Array[Dictionary]) -> Dictionary:
	var result := heap[0]
	var tail: Dictionary = heap.pop_back()
	if heap.is_empty(): return result
	heap[0] = tail
	var parent := 0
	while parent*2+1 < heap.size():
		var child := parent*2+1
		if child+1 < heap.size() and _before(heap[child+1],heap[child]): child += 1
		if not _before(heap[child],heap[parent]): break
		var swap := heap[parent]
		heap[parent] = heap[child]
		heap[child] = swap
		parent = child
	return result
