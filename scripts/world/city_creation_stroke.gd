class_name CityCreationStroke
extends RefCounted
## One pure path pipeline for both the preview and the committed road.
## Shared, limited Hermite tangents round freehand strokes; there is no grid.
const SPACING := 0.2
const FLATNESS := 0.035
const DUPLICATE_EPSILON_SQUARED := 0.000000000001

static func road_points(raw: Array[Vector2], straight: bool = false) -> Array[Vector2]:
	var clean: Array[Vector2] = []
	for index in range(raw.size()):
		var point := raw[index]
		if not point.is_finite(): continue
		if clean.is_empty() or clean[-1].distance_squared_to(point) > DUPLICATE_EPSILON_SQUARED or (index == raw.size() - 1 and clean[-1] != point):
			clean.append(point)
	if clean.size() < 2: return clean
	if straight:
		if clean[0] == clean[-1]: return [clean[0]]
		return [clean[0],clean[-1]]
	# Removing inserted collinear samples first makes pointer event rate irrelevant
	# for the same authored polyline. The second step removes sub-pixel jitter.
	clean = _collinear(clean)
	clean = _simplify(clean,FLATNESS)
	if clean.size() == 2: return clean
	var tangents := _tangents(clean)
	var fine: Array[Vector2] = [clean[0]]
	for segment in range(clean.size() - 1):
		var length := clean[segment].distance_to(clean[segment + 1])
		var steps := maxi(4,int(ceil(length / 0.04)))
		for step in range(1,steps + 1):
			var t := float(step) / steps
			var t2 := t * t
			var t3 := t2 * t
			var point := (2.0 * t3 - 3.0 * t2 + 1.0) * clean[segment] + (t3 - 2.0 * t2 + t) * tangents[segment] + (-2.0 * t3 + 3.0 * t2) * clean[segment + 1] + (t3 - t2) * tangents[segment + 1]
			if fine[-1].distance_squared_to(point) > DUPLICATE_EPSILON_SQUARED: fine.append(point)
	var result := _arc_sample(fine)
	result[0] = clean[0]
	result[-1] = clean[-1]
	return result

static func _collinear(points: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point in points:
		while result.size() > 1:
			var before := result[-2]
			var middle := result[-1]
			var incoming := middle - before
			var outgoing := point - middle
			if incoming.dot(outgoing) < 0.0: break
			if _segment_distance(middle,before,point) > 0.00005: break
			result.pop_back()
		result.append(point)
	return result

static func _simplify(points: Array[Vector2], tolerance: float) -> Array[Vector2]:
	var keep := PackedByteArray()
	keep.resize(points.size())
	keep[0] = 1
	keep[-1] = 1
	var ranges: Array[Vector2i] = [Vector2i(0,points.size() - 1)]
	while not ranges.is_empty():
		var span: Vector2i = ranges.pop_back()
		var furthest := -1
		var distance := tolerance
		for index in range(span.x + 1,span.y):
			var candidate := _segment_distance(points[index],points[span.x],points[span.y])
			if candidate > distance:
				distance = candidate
				furthest = index
		if furthest >= 0:
			keep[furthest] = 1
			ranges.append(Vector2i(span.x,furthest))
			ranges.append(Vector2i(furthest,span.y))
	var result: Array[Vector2] = []
	for index in range(points.size()):
		if keep[index] != 0: result.append(points[index])
	return result

static func _segment_distance(point: Vector2, first: Vector2, last: Vector2) -> float:
	var segment := last - first
	var length_squared := segment.length_squared()
	if length_squared <= DUPLICATE_EPSILON_SQUARED: return point.distance_to(first)
	return point.distance_to(first + segment * clampf((point - first).dot(segment) / length_squared,0.0,1.0))

static func _tangents(points: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	result.resize(points.size())
	var closed := points[0] == points[-1]
	for index in range(points.size()):
		if not closed and index == 0:
			result[index] = (points[1] - points[0]) * 0.75
			continue
		if not closed and index == points.size() - 1:
			result[index] = (points[-1] - points[-2]) * 0.75
			continue
		var previous := points[-2] if index == 0 else points[index - 1]
		var following := points[1] if index == points.size() - 1 else points[index + 1]
		var incoming := points[index] - previous
		var outgoing := following - points[index]
		var incoming_unit := incoming.normalized()
		var outgoing_unit := outgoing.normalized()
		var bisector := incoming_unit + outgoing_unit
		# A turn back onto itself stops at its tip. At a normal bend, both spans
		# share exactly one tangent. Short edges cannot create a long overshoot.
		var turn_weight := sqrt(maxf(0.0,(1.0 + incoming_unit.dot(outgoing_unit)) * 0.5))
		result[index] = bisector.normalized() * minf(incoming.length(),outgoing.length()) * 0.75 * turn_weight
	return result

static func _arc_sample(points: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = [points[0]]
	var remaining := SPACING
	for index in range(1,points.size()):
		var start := points[index - 1]
		var end := points[index]
		var distance := start.distance_to(end)
		while distance >= remaining:
			start = start.lerp(end,remaining / distance)
			if result[-1].distance_squared_to(start) > DUPLICATE_EPSILON_SQUARED: result.append(start)
			distance = start.distance_to(end)
			remaining = SPACING
		remaining -= distance
	if result[-1].distance_squared_to(points[-1]) > DUPLICATE_EPSILON_SQUARED:
		result.append(points[-1])
	else:
		result[-1] = points[-1]
	return result
