extends RefCounted
## Only real usable forecourts can contribute to the authored response.
static func collect(report: Dictionary) -> Array:
	var records: Array = []
	for space: Dictionary in report.spaces:
		if space.evidence.geometry not in ["cultural_forecourt", "landmark_forecourt"]: continue
		var courts: Array = space.evidence.forecourts
		if courts.is_empty(): continue
		var centers: Array[Vector2] = []
		for court: Dictionary in courts:
			var polygon: PackedVector2Array = court.polygon
			var center := Vector2.ZERO
			for point: Vector2 in polygon: center += point
			centers.append(center / polygon.size())
		records.append({"id": space.members[0], "centers": centers})
	return records

static func sample(records: Array, focus: Vector2, zoom: float) -> Dictionary:
	var radius := clampf(zoom * .75, 12., 28.)
	var near := 1. - smoothstep(18., 48., zoom)
	var level := 0.
	var contributions: Array = []
	var sources: Array = []
	for row: Dictionary in records:
		var distance := INF
		for center: Vector2 in row.centers: distance = minf(distance, focus.distance_to(center))
		var weight := (1. - smoothstep(.25, 1., distance / radius)) * near
		if weight <= 0.: continue
		level += weight
		sources.append(row.id)
		contributions.append({"source_ids": [row.id], "value": weight})
	for part: Dictionary in contributions: part.value /= maxf(level, 1.)
	sources.sort()
	return {"civic": minf(level, 1.), "civic_sources": sources, "civic_contributions": contributions}
