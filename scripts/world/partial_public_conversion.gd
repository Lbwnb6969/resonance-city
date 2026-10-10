extends RefCounted
## Preview and settle a public facility inside part of a reserved parcel.
##
## The reservation remains the source of truth until the phrase boundary.  A
## preview only translates a small, legal footprint; commit replaces the
## parent reservation with the actual residual polygons and records both IDs.

const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const FabricRelations = preload("res://scripts/world/fabric_relations.gd")

static func _reservation(world: RefCounted,reservation_id: String) -> Dictionary:
	for item in world.planning_reservations:
		if str(item.get("reservation_id",item.get("id",""))) == reservation_id: return item
	return {}

static func _root_reservation_id(world: RefCounted,reservation_id: String,reservation: Dictionary = {}) -> String:
	var root := reservation_id
	var current := reservation if not reservation.is_empty() else _reservation(world,reservation_id)
	var guard := 0
	while guard < 64 and not current.is_empty():
		guard += 1
		var declared_root := str(current.get("root_reservation_id",""))
		if not declared_root.is_empty(): return declared_root
		var parent := str(current.get("parent_reservation_id",""))
		if parent.is_empty(): return root
		root = parent
		current = _reservation(world,parent)
	return root

static func _source_revision(reservation: Dictionary) -> String:
	var basis := [reservation.get("reservation_id",reservation.get("id","")),reservation.get("source_site_id",""),reservation.get("created_phrase",0),reservation.get("polygon",PackedVector2Array())]
	return JSON.stringify(basis).sha256_text()

static func _half_size(world: RefCounted,reservation: Dictionary,kind: String) -> Vector2:
	var box := SpatialPlanning.bounds(reservation["polygon"])
	var cfg: Dictionary = world.cfg["city"]
	var requested := Vector2(float(cfg["civic_half_width"]),float(cfg["civic_half_length"])) if kind == "civic" else Vector2(float(cfg["park_half_width"]),float(cfg["park_half_length"]))
	# A local facility occupies a little over half of the reserved footprint.
	# The cap keeps ordinary lot-sized reservations usable while preserving a
	# visible remainder for another decision.
	return Vector2(minf(requested.x,box.size.x*0.28),minf(requested.y,box.size.y*0.28))

static func _intersection_area(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var area := 0.0
	for fragment in Geometry2D.intersect_polygons(a,b):
		if fragment.size() >= 3: area += _polygon_area(fragment)
	return area

static func _inside(polygon: PackedVector2Array,container: PackedVector2Array) -> bool:
	return is_equal_approx(_intersection_area(polygon,container),_polygon_area(polygon))

static func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index+1)%polygon.size()]
		area += a.x*b.y-b.x*a.y
	return absf(area)*0.5

static func _signed_polygon_area(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3: return 0.0
	var area := 0.0
	for index in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index+1)%polygon.size()]
		area += a.x*b.y-b.x*a.y
	return area*0.5

static func _orientation(a: Vector2,b: Vector2,c: Vector2) -> float:
	return (b-a).cross(c-a)

static func _on_segment(a: Vector2,b: Vector2,p: Vector2) -> bool:
	return is_zero_approx(_orientation(a,b,p)) and p.x >= minf(a.x,b.x)-0.00001 and p.x <= maxf(a.x,b.x)+0.00001 and p.y >= minf(a.y,b.y)-0.00001 and p.y <= maxf(a.y,b.y)+0.00001

static func _segments_intersect(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	var o1 := _orientation(a,b,c)
	var o2 := _orientation(a,b,d)
	var o3 := _orientation(c,d,a)
	var o4 := _orientation(c,d,b)
	if ((o1 > 0.00001 and o2 < -0.00001) or (o1 < -0.00001 and o2 > 0.00001)) and ((o3 > 0.00001 and o4 < -0.00001) or (o3 < -0.00001 and o4 > 0.00001)): return true
	return (absf(o1) <= 0.00001 and _on_segment(a,b,c)) or (absf(o2) <= 0.00001 and _on_segment(a,b,d)) or (absf(o3) <= 0.00001 and _on_segment(c,d,a)) or (absf(o4) <= 0.00001 and _on_segment(c,d,b))

static func _valid_simple_polygon(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3 or _polygon_area(polygon) <= 0.00001: return false
	for i in range(polygon.size()):
		var a := polygon[i]
		var b := polygon[(i+1)%polygon.size()]
		if a.distance_squared_to(b) <= 0.00000001: return false
		for j in range(i+1,polygon.size()):
			if j == i+1 or (i == 0 and j == polygon.size()-1): continue
			if _segments_intersect(a,b,polygon[j],polygon[(j+1)%polygon.size()]): return false
	return true

## Normalize either the legacy single polygon value or the new nested
## component representation.  JSON restores nested arrays, while the live
## UI usually passes PackedVector2Array values.
static func _normalize_target_components(value: Variant) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if value is PackedVector2Array:
		var single := SpatialPlanning.normalize_polygon(value)
		if not single.is_empty(): result.append(single)
		return result
	if not value is Array or value.is_empty(): return result
	var first: Variant = value[0]
	var nested := first is PackedVector2Array
	if first is Array and not first.is_empty():
		nested = first[0] is Array or first[0] is PackedVector2Array or first[0] is Vector2
	if not nested:
		var single := SpatialPlanning.normalize_polygon(value)
		if not single.is_empty(): result.append(single)
		return result
	for raw in value:
		var component := SpatialPlanning.normalize_polygon(raw)
		if not component.is_empty(): result.append(component)
	return result

static func _normalize_holes(value: Variant) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	if value is PackedVector2Array:
		var single := SpatialPlanning.normalize_polygon(value)
		if not single.is_empty(): result.append(single)
		return result
	if not value is Array or value.is_empty(): return result
	var first: Variant = value[0]
	var nested := first is PackedVector2Array
	if first is Array and not first.is_empty(): nested = first[0] is Array or first[0] is PackedVector2Array or first[0] is Vector2
	if not nested:
		var single := SpatialPlanning.normalize_polygon(value)
		if not single.is_empty(): result.append(single)
		return result
	for raw in value:
		var hole := SpatialPlanning.normalize_polygon(raw)
		if not hole.is_empty(): result.append(hole)
	return result

static func _point_in_holes(p: Vector2,holes: Array[PackedVector2Array]) -> bool:
	for hole in holes:
		if Geometry2D.is_point_in_polygon(p,hole): return true
	return false

static func _representative_for_components(components: Array[PackedVector2Array],holes: Array[PackedVector2Array]) -> Vector2:
	for component in components:
		var candidate := _representative_point(component)
		if not _point_in_holes(candidate,holes): return candidate
		for point in component:
			if not _point_in_holes(point,holes): return point
	return _representative_point(components[0]) if not components.is_empty() else Vector2.ZERO

static func _components_share_boundary(a: PackedVector2Array,b: PackedVector2Array) -> bool:
	for i in range(a.size()):
		var a0 := a[i]
		var a1 := a[(i+1)%a.size()]
		for j in range(b.size()):
			if _segments_intersect(a0,a1,b[j],b[(j+1)%b.size()]): return true
	return false

static func _components_are_disjoint(components: Array[PackedVector2Array]) -> bool:
	for i in range(components.size()):
		for j in range(i+1,components.size()):
			var a: PackedVector2Array = components[i]
			var b: PackedVector2Array = components[j]
			if _intersection_area(a,b) > 0.00001: return false
			# Touching components form one connected outline but are represented as
			# two identities; reject that ambiguous seam instead of creating a
			# zero-width residual fragment.
			if _components_share_boundary(a,b): return false
	return true

static func _subtract_components(source: PackedVector2Array,components: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var remaining: Array[PackedVector2Array] = [source]
	for component in components:
		var next: Array[PackedVector2Array] = []
		for part in remaining:
			var overlap := _intersection_area(part,component)
			if overlap <= 0.00001:
				next.append(part)
				continue
			var residuals := _residuals(part,component)
			var expected := _polygon_area(part)-overlap
			var actual := 0.0
			for residual in residuals: actual += _polygon_area(residual)
			if absf(expected-actual) > 0.0001*maxf(1.0,_polygon_area(part)):
				return []
			next.append_array(residuals)
		remaining = next
	return remaining

static func _representative_point(polygon: PackedVector2Array) -> Vector2:
	var average := Vector2.ZERO
	for point in polygon: average += point
	average /= float(maxi(1,polygon.size()))
	if Geometry2D.is_point_in_polygon(average,polygon): return average
	var center := SpatialPlanning.bounds(polygon).get_center()
	if Geometry2D.is_point_in_polygon(center,polygon): return center
	for index in range(1,polygon.size()-1):
		var triangle_center := (polygon[0]+polygon[index]+polygon[index+1])/3.0
		if Geometry2D.is_point_in_polygon(triangle_center,polygon): return triangle_center
	return polygon[0]

static func _is_convex_polygon(polygon: PackedVector2Array) -> bool:
	if not _valid_simple_polygon(polygon): return false
	var sign := 0
	for index in range(polygon.size()):
		var cross := _orientation(polygon[index],polygon[(index+1)%polygon.size()],polygon[(index+2)%polygon.size()])
		if absf(cross) <= 0.00001: continue
		var current := 1 if cross > 0.0 else -1
		if sign == 0: sign = current
		elif sign != current: return false
	return sign != 0

static func _box_polygon(box: Rect2) -> PackedVector2Array:
	return PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])

static func _half_plane_polygon(a: Vector2,b: Vector2,keep_left: bool,extent: float) -> PackedVector2Array:
	var direction := b-a
	var length := direction.length()
	if length <= 0.00001: return PackedVector2Array()
	direction /= length
	var normal := Vector2(-direction.y,direction.x)
	if not keep_left: normal = -normal
	var start := a-direction*extent
	var end := b+direction*extent
	return PackedVector2Array([start,end,end+normal*extent,start+normal*extent])

static func _residuals_convex(source: PackedVector2Array,footprint: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	# Split source around each edge of a convex target.  At each edge emit the
	# outside pieces and carry only the inside pieces to the next edge.  This
	# produces disjoint simple residuals without writing a hole contour.
	var combined_box := SpatialPlanning.bounds(source)
	for point in footprint: combined_box = combined_box.expand(point)
	var extent := maxf(combined_box.size.length()*8.0,64.0)
	var keep_left := _signed_polygon_area(footprint) > 0.0
	var remaining: Array[PackedVector2Array] = [source]
	for index in range(footprint.size()):
		var a := footprint[index]
		var b := footprint[(index+1)%footprint.size()]
		var outside_plane := _half_plane_polygon(a,b,not keep_left,extent)
		var inside_plane := _half_plane_polygon(a,b,keep_left,extent)
		if outside_plane.size() < 3 or inside_plane.size() < 3: return []
		var next_remaining: Array[PackedVector2Array] = []
		for part in remaining:
			for fragment in Geometry2D.intersect_polygons(part,outside_plane):
				if fragment.size() < 3 or _polygon_area(fragment) <= 0.00001: continue
				if _intersection_area(fragment,footprint) <= 0.00001 and _valid_simple_polygon(fragment): result.append(fragment)
			for fragment in Geometry2D.intersect_polygons(part,inside_plane):
				if fragment.size() >= 3 and _polygon_area(fragment) > 0.00001 and _valid_simple_polygon(fragment): next_remaining.append(fragment)
		remaining = next_remaining
	result = result.filter(func(fragment: PackedVector2Array) -> bool: return _valid_simple_polygon(fragment))
	result.sort_custom(func(a: PackedVector2Array,b: PackedVector2Array) -> bool:
		var ac := SpatialPlanning.bounds(a).get_center()
		var bc := SpatialPlanning.bounds(b).get_center()
		if not is_equal_approx(ac.x,bc.x): return ac.x < bc.x
		if not is_equal_approx(ac.y,bc.y): return ac.y < bc.y
		var aa := _polygon_area(a)
		var ba := _polygon_area(b)
		if not is_equal_approx(aa,ba): return aa < ba
		return JSON.stringify(a) < JSON.stringify(b))
	return result

static func _triangulate_target(footprint: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	# Godot's triangulator is most stable with counter-clockwise input.  Keep
	# the requested winding in the public contract, but triangulate a temporary
	# canonical copy so clockwise player drawings behave identically.
	var triangulation_polygon := footprint.duplicate()
	if _signed_polygon_area(triangulation_polygon) < 0.0: triangulation_polygon.reverse()
	var indices := Geometry2D.triangulate_polygon(triangulation_polygon)
	if indices.size() < 3 or indices.size() % 3 != 0: return result
	for index in range(0,indices.size(),3):
		var a_index := int(indices[index])
		var b_index := int(indices[index+1])
		var c_index := int(indices[index+2])
		if a_index < 0 or b_index < 0 or c_index < 0 or a_index >= triangulation_polygon.size() or b_index >= triangulation_polygon.size() or c_index >= triangulation_polygon.size():
			return []
		var triangle := PackedVector2Array([triangulation_polygon[a_index],triangulation_polygon[b_index],triangulation_polygon[c_index]])
		if not _is_convex_polygon(triangle): return []
		result.append(triangle)
	return result

static func _snap_to_target_vertices(polygon: PackedVector2Array,target: PackedVector2Array) -> PackedVector2Array:
	# Boolean clipping can move a shared target vertex by a few microns.  Snap
	# only those near-exact vertices back to the requested polygon so residual
	# contours never retain a numerical sliver inside the target.
	var snapped := PackedVector2Array()
	for point in polygon:
		var replacement := point
		for target_point in target:
			if point.distance_squared_to(target_point) <= 0.00000001:
				replacement = target_point
				break
		snapped.append(replacement)
	return snapped

static func _residuals_concave(source: PackedVector2Array,footprint: PackedVector2Array) -> Array[PackedVector2Array]:
	# A concave target is a union of ear triangles.  Subtract the triangles in
	# sequence, partitioning the current source into outside and inside pieces
	# at every step.  The next step receives only the outside pieces, while the
	# inside pieces are discarded as target area.  Final residuals are therefore
	# disjoint, simple and hole-free even when the target bends inward.
	var triangles := _triangulate_target(footprint)
	if triangles.is_empty(): return []
	var remaining: Array[PackedVector2Array] = [source]
	for cutter in triangles:
		var combined_box := SpatialPlanning.bounds(source)
		for point in cutter: combined_box = combined_box.expand(point)
		var extent := maxf(combined_box.size.length()*8.0,64.0)
		var keep_left := _signed_polygon_area(cutter) > 0.0
		var next_remaining: Array[PackedVector2Array] = []
		# Keep the half-plane walk identical to the convex path, but process
		# every current piece independently so no hole contour is introduced.
		for part in remaining:
			var inside_parts: Array[PackedVector2Array] = [part]
			var outside_parts: Array[PackedVector2Array] = []
			for edge_index in range(cutter.size()):
				var a := cutter[edge_index]
				var b := cutter[(edge_index+1)%cutter.size()]
				var outside_plane := _half_plane_polygon(a,b,not keep_left,extent)
				var inside_plane := _half_plane_polygon(a,b,keep_left,extent)
				if outside_plane.size() < 3 or inside_plane.size() < 3: return []
				var next_inside: Array[PackedVector2Array] = []
				for current in inside_parts:
					for fragment in Geometry2D.intersect_polygons(current,outside_plane):
						if fragment.size() < 3 or _polygon_area(fragment) <= 0.00001: continue
						if _intersection_area(fragment,cutter) <= 0.00001 and _valid_simple_polygon(fragment): outside_parts.append(fragment)
					for fragment in Geometry2D.intersect_polygons(current,inside_plane):
						if fragment.size() >= 3 and _polygon_area(fragment) > 0.00001 and _valid_simple_polygon(fragment): next_inside.append(fragment)
				inside_parts = next_inside
			# The outside pieces are the source minus this triangle and become
			# the input for the next triangle.  The inside pieces are already
			# covered by the target and are deliberately discarded.
			next_remaining.append_array(outside_parts)
		remaining = next_remaining
	var result: Array[PackedVector2Array] = []
	for fragment in remaining:
		var snapped := _snap_to_target_vertices(fragment,footprint)
		if _valid_simple_polygon(snapped): result.append(snapped)
	result.sort_custom(func(a: PackedVector2Array,b: PackedVector2Array) -> bool:
		var ac := SpatialPlanning.bounds(a).get_center()
		var bc := SpatialPlanning.bounds(b).get_center()
		if not is_equal_approx(ac.x,bc.x): return ac.x < bc.x
		if not is_equal_approx(ac.y,bc.y): return ac.y < bc.y
		var aa := _polygon_area(a)
		var ba := _polygon_area(b)
		if not is_equal_approx(aa,ba): return aa < ba
		return JSON.stringify(a) < JSON.stringify(b))
	return result

static func _residuals(source: PackedVector2Array,footprint: PackedVector2Array) -> Array[PackedVector2Array]:
	if _is_convex_polygon(footprint): return _residuals_convex(source,footprint)
	return _residuals_concave(source,footprint)

static func preview(world: RefCounted,reservation_id: String,kind: String,target_position: Vector2) -> Dictionary:
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"找不到这片留地","source_reservation_id":reservation_id}
	if kind not in ["park","civic"]: return {"accepted":false,"reason":"局部兑现只支持公园或文化设施","source_reservation_id":reservation_id}
	var source_polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
	if not _valid_simple_polygon(source_polygon): return {"accepted":false,"reason":"这片留地不是可继续规划的简单连续范围","source_reservation_id":reservation_id}
	var half := _half_size(world,reservation,kind)
	if half.x < 0.08 or half.y < 0.08: return {"accepted":false,"reason":"留地太窄，暂时无法放入局部公共空间","source_reservation_id":reservation_id}
	return preview_footprint(world,reservation_id,kind,NeighborhoodPlan.box(target_position,half))

## Legacy single-component entry point.  Keep this stable for old saves,
## operations and callers while routing all geometry through the component
## contract below.
static func preview_footprint(world: RefCounted,reservation_id: String,kind: String,target_polygon: Variant) -> Dictionary:
	return preview_footprints(world,reservation_id,kind,[target_polygon])

## Preview one public facility made from one or more disjoint simple target
## components.  The source reservation still remains the only mutable truth
## until the phrase boundary.  Every component is checked independently for
## terrain, buildings, roads and access; the shortest legal component entrance
## becomes the stable facility entrance.  Residuals are partitioned into
## simple polygons after subtracting each component in order.
static func preview_footprints(world: RefCounted,reservation_id: String,kind: String,target_polygons: Variant,target_holes: Variant = []) -> Dictionary:
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"找不到这片留地","source_reservation_id":reservation_id}
	if kind not in ["park","civic"]: return {"accepted":false,"reason":"局部兑现只支持公园或文化设施","source_reservation_id":reservation_id}
	var source_polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
	var components := _normalize_target_components(target_polygons)
	var holes := _normalize_holes(target_holes)
	var source_revision := _source_revision(reservation)
	var base := {"source_reservation_id":reservation_id,"source_revision":source_revision,
		"target_polygon":components[0] if not components.is_empty() else PackedVector2Array(),
		"target_polygons":components.duplicate(true),"footprint_components":components.duplicate(true),
		"hole_polygons":holes.duplicate(true),"target_holes":holes.duplicate(true)}
	if not _valid_simple_polygon(source_polygon):
		base["reason"] = "这片留地不是可继续规划的简单连续范围"
		return base
	if components.is_empty() or components.any(func(component: PackedVector2Array) -> bool: return not _valid_simple_polygon(component)):
		base["reason"] = "公共目标足迹必须是简单多边形"
		return base
	if components.size() > 1 and not _components_are_disjoint(components):
		base["reason"] = "公共目标的多个组件必须彼此分离"
		return base
	for hole in holes:
		if not _valid_simple_polygon(hole):
			base["reason"] = "公共目标孔洞必须是简单多边形"
			return base
		var containing := 0
		for component in components:
			if _inside(hole,component) and not _components_share_boundary(hole,component): containing += 1
		if containing != 1:
			base["reason"] = "公共目标孔洞必须完整落在且只落在一个外环内"
			return base
	for i in range(holes.size()):
		for j in range(i+1,holes.size()):
			if _intersection_area(holes[i],holes[j]) > 0.00001 or _components_share_boundary(holes[i],holes[j]):
				base["reason"] = "公共目标孔洞必须彼此分离"
				return base
	for component in components:
		if not _inside(component,source_polygon):
			base["reason"] = "公共目标足迹必须完整留在原留地内"
			return base
	var access: Dictionary = {}
	var representative := _representative_for_components(components,holes)
	var target_community_ids: Array[String] = []
	var candidate_reason := ""
	var best_path_length := INF
	for component in components:
		var component_holes: Array[PackedVector2Array] = []
		for hole in holes:
			if _inside(hole,component): component_holes.append(hole)
		var component_representative := _representative_point(component)
		if _point_in_holes(component_representative,holes):
			for point in component:
				if not _point_in_holes(point,holes):
					component_representative = point
					break
		var candidate := {"source_site_id":str(reservation.get("source_site_id","")),"reservation_id":reservation_id,
			"position":[component_representative.x,component_representative.y],"polygon":component,
			"community_id":FabricRelations.community_for_position(world,component_representative),"hole_polygons":component_holes.duplicate(true),"target_holes":component_holes.duplicate(true)}
		var reason := SpatialPlanning.site_reason(world,candidate,reservation_id)
		if not reason.is_empty():
			candidate_reason = reason
			break
		var component_access := SpatialPlanning.public_access(world,candidate)
		if component_access.is_empty():
			candidate_reason = "局部公共空间没有可达的真实道路入口"
			break
		var component_community := str(candidate["community_id"])
		if not component_community.is_empty() and not target_community_ids.has(component_community): target_community_ids.append(component_community)
		var path: PackedVector2Array = component_access.get("access_path",PackedVector2Array())
		var path_length := 0.0
		for path_index in range(maxi(0,path.size()-1)): path_length += path[path_index].distance_to(path[path_index+1])
		if path_length < best_path_length:
			best_path_length = path_length
			access = component_access
			representative = path[0] if not path.is_empty() else component_representative
	if not candidate_reason.is_empty():
		base["reason"] = candidate_reason
		return base
	if access.is_empty():
		base["reason"] = "局部公共空间没有可达的真实道路入口"
		return base
	var residuals := _subtract_components(source_polygon,components)
	for hole in holes: residuals.append(hole.duplicate())
	if residuals.is_empty():
		base["reason"] = "局部兑现必须保留一片可继续规划的剩余留地"
		return base
	var residual_area := 0.0
	for fragment in residuals: residual_area += _polygon_area(fragment)
	var target_area := 0.0
	for component in components: target_area += _polygon_area(component)
	for hole in holes:
		target_area -= _polygon_area(hole)
		# The intentionally empty interior remains an independently plannable
		# residual parcel. This keeps source area conservation without introducing
		# a hole contour into the existing simple-polygon residual contract.
	var source_area := _polygon_area(source_polygon)
	var area_tolerance := 0.0001*maxf(1.0,source_area)
	if absf(source_area-target_area-residual_area) > area_tolerance:
		base["reason"] = "局部兑现的几何差集不稳定，请换一处留地"
		return base
	target_community_ids.sort()
	return {"accepted":true,"reason":"可在留地内兑现局部公共空间","source_reservation_id":reservation_id,
		"source_revision":source_revision,"source_site_id":str(reservation.get("source_site_id","")),
		"kind":kind,"target_position":[representative.x,representative.y],"target_polygon":components[0].duplicate(),
		"target_polygons":components.duplicate(true),"footprint_components":components.duplicate(true),
		"hole_polygons":holes.duplicate(true),"target_holes":holes.duplicate(true),
		"target_entrance":access["entrance"].duplicate(),"target_access_path":access.get("access_path",PackedVector2Array()).duplicate(),
		"road_id":str(access.get("road_id","")),"target_community_id":str(FabricRelations.community_for_position(world,representative)),
		"target_community_ids":target_community_ids,"root_reservation_id":_root_reservation_id(world,reservation_id,reservation),
		"source_area":source_area,"target_area":target_area,"remaining_polygons":residuals,
		"remaining_count":residuals.size(),"remaining_area":residual_area}

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> Dictionary:
	var reservation_id := str(operation.get("source_reservation_id",operation.get("reservation_id","")))
	var kind := str(operation.get("facility_kind",operation.get("kind",""))).replace("partial_","")
	var operation_holes: Variant = operation.get("hole_polygons",operation.get("target_holes",[]))
	var current: Dictionary = {}
	if operation.has("target_polygons"):
		current = preview_footprints(world,reservation_id,kind,operation["target_polygons"],operation_holes)
	elif operation.has("footprint_components"):
		current = preview_footprints(world,reservation_id,kind,operation["footprint_components"],operation_holes)
	elif operation.has("target_polygon"):
		current = preview_footprints(world,reservation_id,kind,[operation["target_polygon"]],operation_holes)
	else:
		var raw: Array = operation.get("target_position",operation.get("position",[]))
		if raw.size() != 2: return {"accepted":false,"reason":"局部兑现位置缺失"}
		current = preview(world,reservation_id,kind,Vector2(float(raw[0]),float(raw[1])))
	if not bool(current.get("accepted",false)): return current
	if not str(operation.get("source_revision","")).is_empty() and str(operation["source_revision"]) != str(current["source_revision"]):
		return {"accepted":false,"reason":"留地已经变化，请重新查看局部兑现预影"}
	if operation.has("target_polygons") and _normalize_target_components(operation["target_polygons"]) != current["target_polygons"]:
		return {"accepted":false,"reason":"局部兑现范围已经变化，请重新查看预影"}
	if operation.has("footprint_components") and _normalize_target_components(operation["footprint_components"]) != current["target_polygons"]:
		return {"accepted":false,"reason":"局部兑现范围已经变化，请重新查看预影"}
	if operation.has("target_polygon") and not operation.has("target_polygons") and operation["target_polygon"] != current["target_polygon"]:
		return {"accepted":false,"reason":"局部兑现范围已经变化，请重新查看预影"}
	if operation.has("hole_polygons") and _normalize_holes(operation["hole_polygons"]) != current.get("hole_polygons",[]):
		return {"accepted":false,"reason":"局部兑现孔洞已经变化，请重新查看预影"}
	if operation.has("target_holes") and _normalize_holes(operation["target_holes"]) != current.get("target_holes",[]):
		return {"accepted":false,"reason":"局部兑现孔洞已经变化，请重新查看预影"}
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"留地已经释放"}
	var event_id := int(operation.get("event_id",0))
	var site_id := "partial-%s-%05d" % [kind,event_id]
	var service_before: Dictionary = world.public_service_cache.duplicate(true)
	var root_reservation_id := _root_reservation_id(world,reservation_id,reservation)
	var site := {"id":site_id,"kind":kind,"name":"局部公园" if kind == "park" else "局部文化馆",
		"polygon":current["target_polygon"].duplicate(),"position":current["target_position"].duplicate(),
		"target_polygons":current["target_polygons"].duplicate(true),"footprint_components":current["footprint_components"].duplicate(true),
		"hole_polygons":current.get("hole_polygons",[]).duplicate(true),"target_holes":current.get("target_holes",[]).duplicate(true),
		"entrance":current["target_entrance"].duplicate(),"road_id":str(current.get("road_id","")),
		"access_path":current.get("target_access_path",PackedVector2Array()).duplicate(),
		"community_id":str(current.get("target_community_id","")),"target_community_ids":current.get("target_community_ids",[]).duplicate(),"active":true,"frame":frame,
		"service_level":1,"player_planned":true,"source_site_id":reservation.get("source_site_id","") ,
		"source_reservation_id":reservation_id}
	var remaining_ids: Array[String] = []
	var remaining: Array[Dictionary] = []
	for index in range(current["remaining_polygons"].size()):
		var polygon: PackedVector2Array = current["remaining_polygons"][index]
		var fragment_id := "%s-frag-%02d" % [reservation_id,index+1]
		var center := SpatialPlanning.bounds(polygon).get_center()
		remaining.append({"id":fragment_id,"reservation_id":fragment_id,"parent_reservation_id":reservation_id,"root_reservation_id":root_reservation_id,
			"source_site_id":reservation.get("source_site_id",""),"polygon":polygon,"position":[center.x,center.y],
			"created_phrase":reservation.get("created_phrase",world.phrase_index),"converted_by":site_id})
		remaining_ids.append(fragment_id)
	world.planning_reservations = world.planning_reservations.filter(func(item: Dictionary) -> bool:
		return str(item.get("reservation_id",item.get("id",""))) != reservation_id)
	world.planning_reservations.append_array(remaining)
	world.public_sites.append(site)
	preload("res://scripts/world/development_charter.gd").mark_anchor(world,site,reservation_id)
	world._refresh_parcel_index()
	world._refresh_public_network(frame)
	var target_community_id := str(current.get("target_community_id",""))
	var affected: Array[String] = []
	if not target_community_id.is_empty(): affected.append(target_community_id)
	for key in service_before.keys():
		var before_service: Dictionary = service_before[key]
		var after_service: Dictionary = world.public_service_cache.get(key,{})
		if before_service != after_service and not affected.has(str(key)): affected.append(str(key))
	var service_delta: Dictionary = {}
	for key in affected:
		service_delta[key] = {"before":service_before.get(key,{}).duplicate(true),"after":world.public_service_cache.get(key,{}).duplicate(true)}
	affected.sort()
	world.events.append({"kind":kind,"conversion_scope":"partial","partial":true,"id":site_id,"event_id":event_id,"source_id":str(reservation.get("source_site_id",reservation_id)),"root_reservation_id":root_reservation_id,"facility_kind":kind,"source_reservation_id":reservation_id,
		"source_site_id":reservation.get("source_site_id",""),"target_community_id":target_community_id,"target_position":site["position"].duplicate(true),
		"target_community_ids":site.get("target_community_ids",[]).duplicate(),
		"source_revision":str(current.get("source_revision","")),"source_polygon":reservation.get("polygon",PackedVector2Array()).duplicate(),"converted_footprint":site["polygon"].duplicate(),
		"converted_footprints":site["target_polygons"].duplicate(true),"footprint_components":site["footprint_components"].duplicate(true),
		"hole_polygons":site.get("hole_polygons",[]).duplicate(true),"target_holes":site.get("target_holes",[]).duplicate(true),
		"target_entrance":site["entrance"].duplicate(true),"road_id":site["road_id"],"target_access_path":site["access_path"].duplicate(),"remaining_reservation_ids":remaining_ids.duplicate(),
		"remaining_polygons":remaining.map(func(item: Dictionary) -> Variant: return item["polygon"].duplicate()),
		"covered_before":[],"covered_after":site.get("covered",[]).duplicate(),"served_before":[],"served_after":site.get("served",[]).duplicate(),
		"service_before":service_before,"service_after":world.public_service_cache.duplicate(true),"service_delta":service_delta,"affected_communities":affected,"frame":frame})
	return {"accepted":true,"id":site_id,"source_reservation_id":reservation_id,"remaining_reservation_ids":remaining_ids,
		"target_position":site["position"].duplicate(),"target_polygon":site["polygon"].duplicate(),"target_community_ids":site.get("target_community_ids",[]).duplicate(),
		"target_polygons":site["target_polygons"].duplicate(true),"hole_polygons":site.get("hole_polygons",[]).duplicate(true),"target_holes":site.get("target_holes",[]).duplicate(true),"frame":frame}
