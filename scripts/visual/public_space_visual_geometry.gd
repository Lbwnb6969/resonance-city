extends RefCounted
## Ground and props consume the same filled footprint, including every component.
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")

static func identity(site: Dictionary) -> Array:
	return [SpatialPlanning.footprint_components(site),SpatialPlanning.footprint_holes(site)]

static func components(site: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var holes := SpatialPlanning.footprint_holes(site)
	var preferred := Vector2(float(site["position"][0]),float(site["position"][1]))
	for outer in SpatialPlanning.footprint_components(site):
		var pieces := PartialPublic._subtract_components(outer,holes)
		if pieces.is_empty(): continue
		var placement := _placement(outer,holes,preferred,pieces)
		result.append({"outer":outer,"pieces":pieces,"position":placement["position"],"clearance":placement["clearance"]})
	return result

static func park_details(component: Dictionary) -> Dictionary:
	var p: Vector2 = component["position"]
	var walk := PackedVector2Array([p+Vector2(-2,0.1),p+Vector2(0.2,-0.25),p+Vector2(2,0.15)])
	var walk_strips := Geometry2D.offset_polyline(walk,0.06,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)
	var pool := PackedVector2Array()
	for i in range(32): pool.append(p+Vector2(0.4,0.6)+Vector2(cos(TAU*i/32)*0.5,sin(TAU*i/32)*0.35))
	var paths: Array[PackedVector2Array] = []
	var pools: Array[PackedVector2Array] = []
	for piece in component["pieces"]:
		for strip in walk_strips: paths.append_array(Geometry2D.intersect_polygons(strip,piece))
		pools.append_array(Geometry2D.intersect_polygons(pool,piece))
	return {"paths":paths,"pools":pools}

static func _contains(outer: PackedVector2Array,holes: Array[PackedVector2Array],p: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(p,outer): return false
	for hole in holes:
		if Geometry2D.is_point_in_polygon(p,hole): return false
	return true

static func clearance(outer: PackedVector2Array,holes: Array[PackedVector2Array],p: Vector2) -> float:
	if not _contains(outer,holes,p): return 0.0
	var distance := INF
	var rings: Array[PackedVector2Array] = [outer]
	rings.append_array(holes)
	for ring in rings:
		for index in range(ring.size()):
			var nearest := Geometry2D.get_closest_point_to_segment(p,ring[index],ring[(index+1)%ring.size()])
			distance = minf(distance,p.distance_to(nearest))
	return distance

static func _placement(outer: PackedVector2Array,holes: Array[PackedVector2Array],preferred: Vector2,pieces: Array[PackedVector2Array]) -> Dictionary:
	var available := clearance(outer,holes,preferred)
	# Preserve authored single-piece layouts when their anchor is in solid space.
	if available > 0.05: return {"position":preferred,"clearance":available}
	var box := SpatialPlanning.bounds(outer)
	var candidates := PackedVector2Array([box.get_center()])
	for y in range(1,8):
		for x in range(1,8): candidates.append(box.position+box.size*Vector2(float(x)/8.0,float(y)/8.0))
	# Triangles of the actual fill retain an interior candidate for narrow rings.
	for piece in pieces:
		var triangles := Geometry2D.triangulate_polygon(piece)
		for index in range(0,triangles.size(),3):
			candidates.append((piece[triangles[index]]+piece[triangles[index+1]]+piece[triangles[index+2]])/3.0)
	var best := preferred
	for candidate in candidates:
		var candidate_clearance := clearance(outer,holes,candidate)
		if candidate_clearance > available:
			best = candidate
			available = candidate_clearance
	return {"position":best,"clearance":available}
