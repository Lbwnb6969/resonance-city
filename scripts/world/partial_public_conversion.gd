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

static func _inside(polygon: PackedVector2Array,container: PackedVector2Array) -> bool:
	for point in polygon:
		if not Geometry2D.is_point_in_polygon(point,container): return false
	return true

static func _is_axis_rect(polygon: PackedVector2Array) -> bool:
	if polygon.size() != 4: return false
	var box := SpatialPlanning.bounds(polygon)
	var corners := [box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)]
	for corner in corners:
		if not polygon.has(corner): return false
	return true

static func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index+1)%polygon.size()]
		area += a.x*b.y-b.x*a.y
	return absf(area)*0.5

static func _box_polygon(box: Rect2) -> PackedVector2Array:
	return PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])

static func _residuals(source: PackedVector2Array,footprint: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	# Both preview polygons are axis-aligned rectangles.  Explicit strips keep
	# the residual parcels deterministic and avoid clip_polygons' hole contour
	# behavior when the subject and clip share the same winding.
	var source_box := SpatialPlanning.bounds(source)
	var cut_box := SpatialPlanning.bounds(footprint)
	var epsilon := 0.00001
	var left_width := cut_box.position.x-source_box.position.x
	var right_width := source_box.end.x-cut_box.end.x
	var bottom_height := cut_box.position.y-source_box.position.y
	var top_height := source_box.end.y-cut_box.end.y
	if left_width > epsilon: result.append(_box_polygon(Rect2(source_box.position,Vector2(left_width,source_box.size.y))))
	if right_width > epsilon: result.append(_box_polygon(Rect2(Vector2(cut_box.end.x,source_box.position.y),Vector2(right_width,source_box.size.y))))
	if bottom_height > epsilon: result.append(_box_polygon(Rect2(Vector2(cut_box.position.x,source_box.position.y),Vector2(cut_box.size.x,bottom_height))))
	if top_height > epsilon: result.append(_box_polygon(Rect2(Vector2(cut_box.position.x,cut_box.end.y),Vector2(cut_box.size.x,top_height))))
	result.sort_custom(func(a: PackedVector2Array,b: PackedVector2Array) -> bool:
		var ac := SpatialPlanning.bounds(a).get_center()
		var bc := SpatialPlanning.bounds(b).get_center()
		return ac.x < bc.x if not is_equal_approx(ac.x,bc.x) else ac.y < bc.y)
	return result

static func preview(world: RefCounted,reservation_id: String,kind: String,target_position: Vector2) -> Dictionary:
	var reservation := _reservation(world,reservation_id)
	if reservation.is_empty(): return {"accepted":false,"reason":"找不到这片留地","source_reservation_id":reservation_id}
	if kind not in ["park","civic"]: return {"accepted":false,"reason":"局部兑现只支持公园或文化设施","source_reservation_id":reservation_id}
	var source_polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
	if source_polygon.size() < 4: return {"accepted":false,"reason":"这片留地没有可切分的连续范围","source_reservation_id":reservation_id}
	if not _is_axis_rect(source_polygon):
		return {"accepted":false,"reason":"这片留地由多个历史片段组成，请先选择其中一片连续矩形留地","source_reservation_id":reservation_id}
	var half := _half_size(world,reservation,kind)
	if half.x < 0.08 or half.y < 0.08: return {"accepted":false,"reason":"留地太窄，暂时无法放入局部公共空间","source_reservation_id":reservation_id}
	var footprint := NeighborhoodPlan.box(target_position,half)
	if not _inside(footprint,source_polygon):
		return {"accepted":false,"reason":"局部公共空间必须完整留在原留地内","source_reservation_id":reservation_id,
			"source_revision":_source_revision(reservation),"target_polygon":footprint}
	var candidate := {"source_site_id":str(reservation.get("source_site_id","")),"reservation_id":reservation_id,
		"position":[target_position.x,target_position.y],"polygon":footprint,
		"community_id":FabricRelations.community_for_position(world,target_position)}
	var reason := SpatialPlanning.site_reason(world,candidate,reservation_id)
	if not reason.is_empty():
		return {"accepted":false,"reason":reason,"source_reservation_id":reservation_id,
			"source_revision":_source_revision(reservation),"target_polygon":footprint}
	var access := SpatialPlanning.public_access(world,candidate)
	if access.is_empty():
		return {"accepted":false,"reason":"局部公共空间没有可达的真实道路入口","source_reservation_id":reservation_id,
			"source_revision":_source_revision(reservation),"target_polygon":footprint}
	var residuals := _residuals(source_polygon,footprint)
	if residuals.is_empty():
		return {"accepted":false,"reason":"局部兑现必须保留一片可继续规划的剩余留地","source_reservation_id":reservation_id,
			"source_revision":_source_revision(reservation),"target_polygon":footprint}
	var residual_area := 0.0
	for fragment in residuals: residual_area += _polygon_area(fragment)
	return {"accepted":true,"reason":"可在留地内兑现局部公共空间","source_reservation_id":reservation_id,
		"source_revision":_source_revision(reservation),"source_site_id":str(reservation.get("source_site_id","")),
		"kind":kind,"target_position":[target_position.x,target_position.y],"target_polygon":footprint,
		"target_entrance":access["entrance"].duplicate(),"target_access_path":access.get("access_path",PackedVector2Array()).duplicate(),
		"road_id":str(access.get("road_id","")),"target_community_id":str(candidate["community_id"]),
		"remaining_polygons":residuals,"remaining_count":residuals.size(),"remaining_area":residual_area}

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> Dictionary:
	var reservation_id := str(operation.get("source_reservation_id",operation.get("reservation_id","")))
	var kind := str(operation.get("facility_kind",operation.get("kind",""))).replace("partial_","")
	var raw: Array = operation.get("target_position",operation.get("position",[]))
	if raw.size() != 2: return {"accepted":false,"reason":"局部兑现位置缺失"}
	var current := preview(world,reservation_id,kind,Vector2(float(raw[0]),float(raw[1])))
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
	var root_reservation_id := str(reservation.get("root_reservation_id",reservation.get("parent_reservation_id",reservation_id)))
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
	world.events.append({"kind":kind,"conversion_scope":"partial","partial":true,"id":site_id,"event_id":event_id,"source_id":str(reservation.get("source_site_id",reservation_id)),"facility_kind":kind,"source_reservation_id":reservation_id,
		"source_site_id":reservation.get("source_site_id",""),"target_community_id":target_community_id,"target_position":site["position"].duplicate(true),
		"source_revision":str(current.get("source_revision","")),"source_polygon":reservation.get("polygon",PackedVector2Array()).duplicate(),"converted_footprint":site["polygon"].duplicate(),
		"target_entrance":site["entrance"].duplicate(true),"road_id":site["road_id"],"target_access_path":site["access_path"].duplicate(),"remaining_reservation_ids":remaining_ids.duplicate(),
		"remaining_polygons":remaining.map(func(item: Dictionary) -> Variant: return item["polygon"].duplicate()),
		"covered_before":[],"covered_after":site.get("covered",[]).duplicate(),"served_before":[],"served_after":site.get("served",[]).duplicate(),
		"service_before":service_before,"service_after":world.public_service_cache.duplicate(true),"service_delta":service_delta,"affected_communities":affected,"frame":frame})
	return {"accepted":true,"id":site_id,"source_reservation_id":reservation_id,"remaining_reservation_ids":remaining_ids,
		"target_position":site["position"].duplicate(),"frame":frame}
