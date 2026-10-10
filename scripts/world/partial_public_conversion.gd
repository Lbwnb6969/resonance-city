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

static func _residuals(source: PackedVector2Array,footprint: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	# Geometry2D.exclude_polygons/clip_polygons expose a hole contour as a
	# second polygon.  A hole cannot be stored in the reservation schema, so
	# split source around each edge of a convex target instead.  At each edge
	# emit the outside pieces and carry only the inside pieces to the next edge.
	# This produces disjoint simple residuals for concave historical sources.
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

static func preview(world: RefCounted,reservation_id: String,kind: String,target_position: Vector2) -> Dictionary:
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"找不到这片留地","source_reservation_id":reservation_id}
	if kind not in ["park","civic"]: return {"accepted":false,"reason":"局部兑现只支持公园或文化设施","source_reservation_id":reservation_id}
	var source_polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
	if not _valid_simple_polygon(source_polygon): return {"accepted":false,"reason":"这片留地不是可继续规划的简单连续范围","source_reservation_id":reservation_id}
	var half := _half_size(world,reservation,kind)
	if half.x < 0.08 or half.y < 0.08: return {"accepted":false,"reason":"留地太窄，暂时无法放入局部公共空间","source_reservation_id":reservation_id}
	return preview_footprint(world,reservation_id,kind,NeighborhoodPlan.box(target_position,half))

## Preview a player-specified public footprint.  The target is deliberately
## limited to a simple convex polygon: Geometry2D's polygon difference returns
## a hole contour, while reservations store only disjoint simple polygons.
## Splitting a source around each convex edge preserves a hole-free residual
## representation and makes the phrase-boundary recheck deterministic.
static func preview_footprint(world: RefCounted,reservation_id: String,kind: String,target_polygon: Variant) -> Dictionary:
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"找不到这片留地","source_reservation_id":reservation_id}
	if kind not in ["park","civic"]: return {"accepted":false,"reason":"局部兑现只支持公园或文化设施","source_reservation_id":reservation_id}
	var source_polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
	var footprint := SpatialPlanning.normalize_polygon(target_polygon)
	var source_revision := _source_revision(reservation)
	var base := {"source_reservation_id":reservation_id,"source_revision":source_revision,"target_polygon":footprint}
	if not _valid_simple_polygon(source_polygon):
		base["reason"] = "这片留地不是可继续规划的简单连续范围"
		return base
	if not _is_convex_polygon(footprint):
		base["reason"] = "公共目标足迹当前需要简单凸多边形"
		return base
	if not _inside(footprint,source_polygon):
		base["reason"] = "公共目标足迹必须完整留在原留地内"
		return base
	var representative := _representative_point(footprint)
	var candidate := {"source_site_id":str(reservation.get("source_site_id","")),"reservation_id":reservation_id,
		"position":[representative.x,representative.y],"polygon":footprint,
		"community_id":FabricRelations.community_for_position(world,representative)}
	var reason := SpatialPlanning.site_reason(world,candidate,reservation_id)
	if not reason.is_empty():
		base["reason"] = reason
		return base
	var access := SpatialPlanning.public_access(world,candidate)
	if access.is_empty():
		base["reason"] = "局部公共空间没有可达的真实道路入口"
		return base
	var residuals := _residuals(source_polygon,footprint)
	if residuals.is_empty():
		base["reason"] = "局部兑现必须保留一片可继续规划的剩余留地"
		return base
	var residual_area := 0.0
	for fragment in residuals: residual_area += _polygon_area(fragment)
	var target_area := _polygon_area(footprint)
	var source_area := _polygon_area(source_polygon)
	var area_tolerance := 0.0001*maxf(1.0,source_area)
	if absf(source_area-target_area-residual_area) > area_tolerance:
		base["reason"] = "局部兑现的几何差集不稳定，请换一处留地"
		return base
	return {"accepted":true,"reason":"可在留地内兑现局部公共空间","source_reservation_id":reservation_id,
		"source_revision":source_revision,"source_site_id":str(reservation.get("source_site_id","")),
		"kind":kind,"target_position":[representative.x,representative.y],"target_polygon":footprint,
		"target_entrance":access["entrance"].duplicate(),"target_access_path":access.get("access_path",PackedVector2Array()).duplicate(),
		"road_id":str(access.get("road_id","")),"target_community_id":str(candidate["community_id"]),
		"root_reservation_id":_root_reservation_id(world,reservation_id,reservation),"source_area":source_area,"target_area":target_area,
		"remaining_polygons":residuals,"remaining_count":residuals.size(),"remaining_area":residual_area}

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> Dictionary:
	var reservation_id := str(operation.get("source_reservation_id",operation.get("reservation_id","")))
	var kind := str(operation.get("facility_kind",operation.get("kind",""))).replace("partial_","")
	var current: Dictionary = {}
	if operation.has("target_polygon"):
		current = preview_footprint(world,reservation_id,kind,operation["target_polygon"])
	else:
		var raw: Array = operation.get("target_position",operation.get("position",[]))
		if raw.size() != 2: return {"accepted":false,"reason":"局部兑现位置缺失"}
		current = preview(world,reservation_id,kind,Vector2(float(raw[0]),float(raw[1])))
	if not bool(current.get("accepted",false)): return current
	if not str(operation.get("source_revision","")).is_empty() and str(operation["source_revision"]) != str(current["source_revision"]):
		return {"accepted":false,"reason":"留地已经变化，请重新查看局部兑现预影"}
	if operation.has("target_polygon") and operation["target_polygon"] != current["target_polygon"]:
		return {"accepted":false,"reason":"局部兑现范围已经变化，请重新查看预影"}
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"留地已经释放"}
	var event_id := int(operation.get("event_id",0))
	var site_id := "partial-%s-%05d" % [kind,event_id]
	var service_before: Dictionary = world.public_service_cache.duplicate(true)
	var root_reservation_id := _root_reservation_id(world,reservation_id,reservation)
	var site := {"id":site_id,"kind":kind,"name":"局部公园" if kind == "park" else "局部文化馆",
		"polygon":current["target_polygon"].duplicate(),"position":current["target_position"].duplicate(),
		"entrance":current["target_entrance"].duplicate(),"road_id":str(current.get("road_id","")),
		"access_path":current.get("target_access_path",PackedVector2Array()).duplicate(),
		"community_id":str(current.get("target_community_id","")),"active":true,"frame":frame,
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
		"source_revision":str(current.get("source_revision","")),"source_polygon":reservation.get("polygon",PackedVector2Array()).duplicate(),"converted_footprint":site["polygon"].duplicate(),
		"target_entrance":site["entrance"].duplicate(true),"road_id":site["road_id"],"target_access_path":site["access_path"].duplicate(),"remaining_reservation_ids":remaining_ids.duplicate(),
		"remaining_polygons":remaining.map(func(item: Dictionary) -> Variant: return item["polygon"].duplicate()),
		"covered_before":[],"covered_after":site.get("covered",[]).duplicate(),"served_before":[],"served_after":site.get("served",[]).duplicate(),
		"service_before":service_before,"service_after":world.public_service_cache.duplicate(true),"service_delta":service_delta,"affected_communities":affected,"frame":frame})
	return {"accepted":true,"id":site_id,"source_reservation_id":reservation_id,"remaining_reservation_ids":remaining_ids,
		"target_position":site["position"].duplicate(),"frame":frame}
