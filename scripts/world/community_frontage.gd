extends RefCounted
## Measure continuous parcel frontage; overlapping intervals count only once.
static func merged(intervals: Array) -> Array:
	var ordered := intervals.duplicate()
	ordered.sort_custom(func(a: Vector2,b: Vector2)->bool: return a.x < b.x)
	var result: Array = []
	for interval: Vector2 in ordered:
		if interval.y <= interval.x: continue
		if result.is_empty() or interval.x > result[-1].y:
			result.append(interval)
		else: result[-1] = Vector2(result[-1].x,maxf(result[-1].y,interval.y))
	return result

static func length_of(intervals: Array) -> float:
	var length := 0.0
	for interval: Vector2 in merged(intervals): length += interval.y-interval.x
	return length

static func projection(world: RefCounted,polygon: PackedVector2Array,p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var distance := 1.35
	for segment in world.near_road_segments(p,1.35):
		if bool(segment["road"].get("bridge",false)): continue
		var q := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
		var gap := p.distance_to(q)
		if gap > distance or (gap == distance and not best.is_empty()): continue
		best = {"segment":segment,"q":q}
		distance = gap
	if best.is_empty(): return {}
	var segment: Dictionary = best["segment"]
	var q: Vector2 = best["q"]
	var tangent: Vector2 = (segment["b"]-segment["a"]).normalized()
	var path: PackedVector2Array = segment["road"]["path"]
	var arc := 0.0
	var total := 0.0
	var reached := false
	for i in range(path.size()-1):
		var length := path[i].distance_to(path[i+1])
		if not reached:
			if path[i] == segment["a"] and path[i+1] == segment["b"]:
				arc += path[i].distance_to(q)
				reached = true
			else: arc += length
		total += length
	var low := INF
	var high := -INF
	for vertex in polygon:
		var value := arc+(vertex-q).dot(tangent)
		low = minf(low,value)
		high = maxf(high,value)
	var side := -1 if tangent.cross(p-q) < 0.0 else 1
	return {"street":str(segment["road"]["id"])+":"+str(side),"interval":Vector2(clampf(low,0,total),clampf(high,0,total))}

static func measure(world: RefCounted) -> Dictionary:
	var fronts: Dictionary = {}
	for lot in world.lots:
		var polygon: PackedVector2Array = lot["polygon"]
		if not world.SpatialPlanning.exclusion(world,polygon).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var projected := projection(world,polygon,p)
		if projected.is_empty(): continue
		var key := str(lot["community_id"])+"|"+str(projected["street"])
		if not fronts.has(key): fronts[key] = {"cid":str(lot["community_id"]),"available":[],"occupied":[]}
		fronts[key]["available"].append(projected["interval"])
	for building in world.buildings:
		var p := Vector2(float(building["position"][0]),float(building["position"][1]))
		var projected := projection(world,world.building_polygon(p),p)
		if projected.is_empty(): continue
		var key := str(building["community_id"])+"|"+str(projected["street"])
		if fronts.has(key): fronts[key]["occupied"].append(projected["interval"])
	var result: Dictionary = {}
	for cid in world.communities: result[cid] = {"available_length":0.0,"occupied_length":0.0,"score":0.0,"tier":"散落"}
	for front in fronts.values():
		var available := merged(front["available"])
		var occupied := merged(front["occupied"])
		var covered := 0.0
		for a: Vector2 in available:
			for b: Vector2 in occupied: covered += maxf(0.0,minf(a.y,b.y)-maxf(a.x,b.x))
		var status: Dictionary = result[front["cid"]]
		status["available_length"] += length_of(available)
		status["occupied_length"] += covered
	for status in result.values():
		status["score"] = float(status["occupied_length"])/maxf(0.000001,float(status["available_length"]))
		status["tier"] = "散落" if status["score"] < 0.35 else ("成街" if status["score"] < 0.70 else "街区")
	return result
