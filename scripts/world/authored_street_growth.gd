extends RefCounted
## Actual player families extend a street frontage through ordinary placement,
## connectivity and acoustic filters. These are ephemeral growth candidates.

static func candidates(world: RefCounted,frontier: Array[Vector2],expression: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var radius := float(world.cfg["space"]["residential_radius"])
	# Commercial roofs join; the slower stone houses also join; warm homes keep
	# a little more air beside their real reserved public space.
	var gap: float = {"weave":0.04,"deep":0.08,"warm":0.16}.get(expression,0.08)
	for origin: Vector2 in frontier:
		var frontages: Dictionary = {}
		for segment: Dictionary in world.near_road_segments(origin,1.35):
			if bool(segment["road"].get("bridge",false)): continue
			var nearest := Geometry2D.get_closest_point_to_segment(origin,segment["a"],segment["b"])
			var distance := origin.distance_to(nearest)
			if distance > 1.35 or distance < radius: continue
			var road_id := str(segment["road"]["id"])
			if frontages.has(road_id) and float(frontages[road_id]["distance"]) <= distance: continue
			frontages[road_id] = {"distance":distance,"direction":(Vector2(segment["b"])-Vector2(segment["a"])).normalized()}
		for frontage: Dictionary in frontages.values():
			for sign: float in [-1.0,1.0]:
				var p: Vector2 = origin+Vector2(frontage["direction"])*(radius*2.0+gap)*sign
				if result.any(func(item: Dictionary) -> bool: return p.distance_squared_to(item["position"]) < 0.01): continue
				result.append({"position":p,"use":"residential","authored_frontage":true})
	return result
