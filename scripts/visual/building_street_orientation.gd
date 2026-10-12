extends RefCounted
## Baked facades: 0 faces -y/-z, then +x, +y/+z and -x. No World writes.
const FACING := [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)]

static func street_orientation(world: RefCounted,position: Vector2,entrance: Vector2 = Vector2.INF) -> int:
	var source := _source_access(world,position)
	if entrance == Vector2.INF and source.has("entrance"):
		var raw: Array = source["entrance"]
		entrance = Vector2(float(raw[0]),float(raw[1]))
	var query := position if entrance == Vector2.INF else entrance
	var segments: Array[Dictionary] = world.near_road_segments(query,3.0)
	var street := _nearest_street(world,position,entrance,segments,str(source.get("road_id","")))
	if street.is_empty():
		# Remote L3 land still has a geometric direction. The owner caches this
		# result with its presented city/entry, instead of running it each frame.
		segments.assign(world.road_segments.values())
		street = _nearest_street(world,position,entrance,segments,str(source.get("road_id","")))
	if street.is_empty(): return 0
	var tangent: Vector2 = street["tangent"]
	var normal := Vector2(-tangent.y,tangent.x)
	var target: Vector2 = street["position"]-position
	if entrance != Vector2.INF: target = entrance-position
	if normal.dot(target) < 0.0: normal = -normal
	var orientation := 0
	var alignment := -INF
	for index in range(FACING.size()):
		var value: float = FACING[index].dot(normal)
		if value > alignment:
			alignment = value
			orientation = index
	return orientation

static func _source_access(world: RefCounted,position: Vector2) -> Dictionary:
	# A built facility's committed road entrance is stronger than a nearby
	# unrelated lane. Homes keep their actual lot entrance when they have one.
	for site: Dictionary in world.near_public_sites(position):
		var raw: Array = site.get("position",[])
		if raw.size() == 2 and position.distance_squared_to(Vector2(float(raw[0]),float(raw[1]))) < 0.00000001 and site.has("entrance"):
			return site
	var lot_id := ""
	var has_house := false
	for id: String in world.index.query_circle(position,0.0001):
		var building: Dictionary = world.by_id[id]
		var raw: Array = building["position"]
		if position.distance_squared_to(Vector2(float(raw[0]),float(raw[1]))) < 0.00000001:
			lot_id = str(building.get("lot_id",""))
			has_house = true
			break
	var nearest := INF
	var selected: Dictionary = {}
	for lot: Dictionary in world.near_lots(position):
		if not lot_id.is_empty() and str(lot["id"]) == lot_id: return lot
		if has_house or not Geometry2D.is_point_in_polygon(position,lot["polygon"]): continue
		var raw: Array = lot["center"]
		var distance := position.distance_squared_to(Vector2(float(raw[0]),float(raw[1])))
		if distance < nearest:
			nearest = distance
			selected = lot
	return selected

static func _nearest_street(world: RefCounted,position: Vector2,entrance: Vector2,segments: Array[Dictionary],preferred_road: String) -> Dictionary:
	var query := position if entrance == Vector2.INF else entrance
	var selected: Dictionary = {}
	var best_rank := INF
	var best_gap := INF
	var best_position_gap := INF
	for segment: Dictionary in segments:
		var road: Dictionary = segment["road"]
		if bool(road.get("bridge",false)): continue
		var a: Vector2 = segment["a"]
		var b: Vector2 = segment["b"]
		if a == b: continue
		var at := Geometry2D.get_closest_point_to_segment(query,a,b)
		var projected := Geometry2D.get_closest_point_to_segment(position,a,b)
		if not Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([position,projected]),world.terrain.water).is_empty(): continue
		var rank := 0.0 if preferred_road.is_empty() or str(road["id"]) == preferred_road else 1.0
		var gap := query.distance_squared_to(at)
		var position_gap := position.distance_squared_to(projected)
		if rank > best_rank: continue
		if rank == best_rank and gap > best_gap+0.00000001: continue
		if rank == best_rank and is_equal_approx(gap,best_gap) and position_gap >= best_position_gap-0.00000001: continue
		best_rank = rank
		best_gap = gap
		best_position_gap = position_gap
		selected = {"position":projected,"tangent":(b-a).normalized()}
	return selected
