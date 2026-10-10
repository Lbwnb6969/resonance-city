extends RefCounted
## Geometry and player planning share one exclusion contract. No acoustic state.
static func bounds(polygon: PackedVector2Array) -> Rect2:
	var result := Rect2(polygon[0],Vector2.ZERO)
	for p in polygon: result = result.expand(p)
	return result

static func normalize_polygon(value: Variant) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	if value is PackedVector2Array:
		for point in value: polygon.append(point)
	elif value is Array:
		for raw in value:
			if raw is Vector2:
				polygon.append(raw)
			elif raw is Array and raw.size() >= 2:
				polygon.append(Vector2(float(raw[0]),float(raw[1])))
	return polygon

static func polygon_area(polygon: PackedVector2Array) -> float:
	if polygon.size() < 3: return 0.0
	var area := 0.0
	for index in range(polygon.size()):
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index+1)%polygon.size()]
		area += a.x*b.y-b.x*a.y
	return absf(area)*0.5

static func _orientation(a: Vector2,b: Vector2,c: Vector2) -> float:
	return (b-a).cross(c-a)

static func _on_segment(a: Vector2,b: Vector2,p: Vector2) -> bool:
	return absf(_orientation(a,b,p)) <= 0.00001 and p.x >= minf(a.x,b.x)-0.00001 and p.x <= maxf(a.x,b.x)+0.00001 and p.y >= minf(a.y,b.y)-0.00001 and p.y <= maxf(a.y,b.y)+0.00001

static func _segments_intersect(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	var o1 := _orientation(a,b,c)
	var o2 := _orientation(a,b,d)
	var o3 := _orientation(c,d,a)
	var o4 := _orientation(c,d,b)
	if ((o1 > 0.00001 and o2 < -0.00001) or (o1 < -0.00001 and o2 > 0.00001)) and ((o3 > 0.00001 and o4 < -0.00001) or (o3 < -0.00001 and o4 > 0.00001)): return true
	return (absf(o1) <= 0.00001 and _on_segment(a,b,c)) or (absf(o2) <= 0.00001 and _on_segment(a,b,d)) or (absf(o3) <= 0.00001 and _on_segment(c,d,a)) or (absf(o4) <= 0.00001 and _on_segment(c,d,b))

static func valid_simple_polygon(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3 or polygon_area(polygon) <= 0.00001: return false
	for i in range(polygon.size()):
		var a := polygon[i]
		var b := polygon[(i+1)%polygon.size()]
		if a.distance_squared_to(b) <= 0.00000001: return false
		for j in range(i+1,polygon.size()):
			if j == i+1 or (i == 0 and j == polygon.size()-1): continue
			if _segments_intersect(a,b,polygon[j],polygon[(j+1)%polygon.size()]): return false
	return true

static func _intersection_area(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var area := 0.0
	for fragment in Geometry2D.intersect_polygons(a,b):
		if fragment.size() >= 3: area += polygon_area(fragment)
	return area

static func _contains_polygon(container: PackedVector2Array,polygon: PackedVector2Array) -> bool:
	if not valid_simple_polygon(container) or not valid_simple_polygon(polygon): return false
	return is_equal_approx(_intersection_area(container,polygon),polygon_area(polygon))

static func _representative_point(polygon: PackedVector2Array) -> Vector2:
	var average := Vector2.ZERO
	for point in polygon: average += point
	average /= float(maxi(1,polygon.size()))
	if Geometry2D.is_point_in_polygon(average,polygon): return average
	var center := bounds(polygon).get_center()
	if Geometry2D.is_point_in_polygon(center,polygon): return center
	for index in range(1,polygon.size()-1):
		var triangle_center := (polygon[0]+polygon[index]+polygon[index+1])/3.0
		if Geometry2D.is_point_in_polygon(triangle_center,polygon): return triangle_center
	return polygon[0]

static func polygon_candidate(world: RefCounted,value: Variant,anchor: Vector2 = Vector2.INF) -> Dictionary:
	var polygon := normalize_polygon(value)
	if not valid_simple_polygon(polygon): return {}
	var center := anchor if anchor != Vector2.INF and Geometry2D.is_point_in_polygon(anchor,polygon) else _representative_point(polygon)
	var source: Dictionary = {}
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var lot_polygon: PackedVector2Array = lot.get("polygon",PackedVector2Array())
		if _contains_polygon(lot_polygon,polygon):
			source = {"source_site_id":str(lot.get("id","")),"source_polygon":lot_polygon}
			break
	if source.is_empty():
		var point_candidate := candidate(world,center)
		if point_candidate.is_empty() or not _contains_polygon(point_candidate.get("polygon",PackedVector2Array()),polygon): return {}
		source = {"source_site_id":str(point_candidate.get("source_site_id","")),"source_polygon":point_candidate["polygon"]}
	var result := {"source_site_id":source["source_site_id"],"polygon":polygon,"position":[center.x,center.y],
		"community_id":FabricRelations.community_for_position(world,center)}
	var reason := site_reason(world,result)
	result["reason"] = reason
	result["allowed"] = reason.is_empty()
	return result

static func disc_hits(polygon: PackedVector2Array,p: Vector2,radius: float) -> bool:
	if Geometry2D.is_point_in_polygon(p,polygon): return true
	for i in range(polygon.size()):
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,polygon[i],polygon[(i+1)%polygon.size()])) < radius-0.000001:
			return true
	return false

static func overlaps(a: PackedVector2Array,b: PackedVector2Array) -> bool:
	return bounds(a).intersects(bounds(b),true) and not Geometry2D.intersect_polygons(a,b).is_empty()

static func circle_polygon(center: Vector2,radius: float,sides: int = 32) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for i in range(maxi(8,sides)):
		polygon.append(center+Vector2.from_angle(TAU*float(i)/float(maxi(8,sides)))*radius)
	return polygon

static func reservation_contains_disc(reservation: Dictionary,center: Vector2,radius: float) -> bool:
	var polygon: PackedVector2Array = reservation.get("polygon",PackedVector2Array())
	if polygon.size() < 3: return false
	# The footprint uses the same polygonal circle as the landmark renderer. All
	# samples must stay inside the reserved parcel before conversion is accepted.
	for point in circle_polygon(center,radius):
		if not Geometry2D.is_point_in_polygon(point,polygon): return false
	return true

static func subtract_disc(polygon: PackedVector2Array,center: Vector2,radius: float) -> Array[PackedVector2Array]:
	if polygon.size() < 3: return []
	var result: Array[PackedVector2Array] = []
	var box := bounds(polygon)
	var cutter_radius := radius+0.01
	var min_corner := center-Vector2(cutter_radius,cutter_radius)
	var max_corner := center+Vector2(cutter_radius,cutter_radius)
	# Current player parcels are rectangles. Split their four sides and retain
	# the rounded corners as small sector polygons; this avoids Geometry2D's
	# hole contour becoming a second reservation with the landmark inside it.
	var candidates: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(box.position.x,box.position.y),Vector2(min_corner.x,box.position.y),Vector2(min_corner.x,box.end.y),Vector2(box.position.x,box.end.y)]),
		PackedVector2Array([Vector2(max_corner.x,box.position.y),Vector2(box.end.x,box.position.y),Vector2(box.end.x,box.end.y),Vector2(max_corner.x,box.end.y)]),
		PackedVector2Array([Vector2(min_corner.x,box.position.y),Vector2(max_corner.x,box.position.y),Vector2(max_corner.x,min_corner.y),Vector2(min_corner.x,min_corner.y)]),
		PackedVector2Array([Vector2(min_corner.x,max_corner.y),Vector2(max_corner.x,max_corner.y),Vector2(max_corner.x,box.end.y),Vector2(min_corner.x,box.end.y)])]
	var rectangular := polygon.size() == 4
	if rectangular:
		for point in polygon:
			if point != Vector2(box.position.x,box.position.y) and point != Vector2(box.end.x,box.position.y) and point != Vector2(box.end.x,box.end.y) and point != Vector2(box.position.x,box.end.y):
				rectangular = false
				break
	for candidate in candidates:
		for clipped in Geometry2D.intersect_polygons(candidate,polygon):
			if clipped.size() >= 3 and Geometry2D.intersect_polygons(clipped,circle_polygon(center,radius)).is_empty(): result.append(clipped)
	# Four corner sectors cover the portions outside the round footprint that
	# lie inside its bounding square. A small geometric margin keeps the shared
	# boundary out of the next placement exclusion check.
	var corner_angles := [[-PI/2.0,-PI],[-PI,-PI*1.5],[PI*1.5,TAU],[0.0,PI/2.0]]
	var corners := [Vector2(box.position.x,box.position.y),Vector2(box.position.x,box.end.y),Vector2(box.end.x,box.end.y),Vector2(box.end.x,box.position.y)]
	for index in range(4):
		var angle_start: float = corner_angles[index][0]
		var angle_end: float = corner_angles[index][1]
		var sector := PackedVector2Array([corners[index]])
		sector.append(center+Vector2.from_angle(angle_start)*cutter_radius)
		for step in range(1,7): sector.append(center+Vector2.from_angle(lerpf(angle_start,angle_end,float(step)/6.0))*cutter_radius)
		sector.append(center+Vector2.from_angle(angle_end)*cutter_radius)
		if Geometry2D.is_polygon_clockwise(sector) != Geometry2D.is_polygon_clockwise(polygon): sector.reverse()
		var contained := rectangular
		for point in sector:
			if not Geometry2D.is_point_in_polygon(point,polygon): contained = false; break
		if contained:
			if Geometry2D.intersect_polygons(sector,circle_polygon(center,radius)).is_empty(): result.append(sector)
		else:
			for clipped in Geometry2D.intersect_polygons(sector,polygon):
				if clipped.size() >= 3 and Geometry2D.intersect_polygons(clipped,circle_polygon(center,radius)).is_empty(): result.append(clipped)
	return result

static func green_hits(world: RefCounted,polygon: PackedVector2Array) -> bool:
	var box := bounds(polygon)
	for corridor in world.green_corridors:
		if not bool(corridor.get("active",true)): continue
		var path: PackedVector2Array = corridor["path"]
		var width := float(corridor.get("width",0.24))
		if not box.intersects(bounds(path).grow(width),true): continue
		for strip in Geometry2D.offset_polyline(path,width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			if overlaps(polygon,strip): return true
	return false

static func exclusion(world: RefCounted,polygon: PackedVector2Array,ignore_reservation: String = "",ignore_public: String = "") -> String:
	var terrain_reason: String = world.terrain.building_footprint_reason(polygon)
	if not terrain_reason.is_empty(): return terrain_reason
	if green_hits(world,polygon): return "这里是绿廊，保持公共空间连通"
	var box := bounds(polygon)
	var p := box.get_center()
	var reach := box.size.length()*0.5
	for reservation in world.near_planning_reservations(p,reach):
		if str(reservation["reservation_id"]) != ignore_reservation and overlaps(polygon,reservation["polygon"]):
			return "这里是你留下的空地，先释放或改作公共用途"
	for landmark in world.landmarks:
		var center := Vector2(float(landmark["position"][0]),float(landmark["position"][1]))
		if disc_hits(polygon,center,float(landmark.get("radius",1.0))):
			return "这里是地标占地，给地标留出完整空间"
	for site in world.near_public_sites(p,reach):
		if str(site["id"]) != ignore_public and overlaps(polygon,site["polygon"]):
			return "占地不能压进公园或文化设施"
	return ""

static func site_reason(world: RefCounted,candidate: Dictionary,ignore_public_id: String = "") -> String:
	var polygon: PackedVector2Array = candidate["polygon"]
	var reason := exclusion(world,polygon,str(candidate.get("reservation_id","")),ignore_public_id if not ignore_public_id.is_empty() else str(candidate.get("public_id","")))
	if not reason.is_empty(): return reason
	var box := bounds(polygon)
	var center := box.get_center()
	var reach := box.size.length()*0.5
	for id in world.index.query_circle(center,reach):
		var building: Dictionary = world.by_id[id]
		if disc_hits(polygon,WorldCoupling.position_of(building),float(building["radius"])):
			return "这片地已经有房屋，不能覆盖既有作品"
	for segment in world.near_road_segments(center,reach+0.55):
		var width := FabricRelations._road_width(world,segment["road"])
		for strip in Geometry2D.offset_polyline(PackedVector2Array([segment["a"],segment["b"]]),width,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			if overlaps(polygon,strip): return "这片范围压住道路，请选择街道旁的空地"
	return ""

static func relocation_candidate(world: RefCounted,source_site: Dictionary,target_position: Vector2) -> Dictionary:
	var source_id := str(source_site.get("id", ""))
	var source_position := Vector2(float(source_site["position"][0]),float(source_site["position"][1]))
	var polygon := PackedVector2Array()
	for point in source_site.get("polygon",PackedVector2Array()):
		polygon.append(Vector2(point)+target_position-source_position)
	var candidate := {"source_site_id":source_id,"public_id":source_id,"position":[target_position.x,target_position.y],
		"polygon":polygon,"community_id":FabricRelations.community_for_position(world,target_position)}
	var reason := site_reason(world,candidate,source_id)
	if not reason.is_empty():
		candidate["allowed"] = false
		candidate["reason"] = reason
		return candidate
	var access := public_access(world,candidate)
	if access.is_empty():
		candidate["allowed"] = false
		candidate["reason"] = "新位置没有可达的真实道路入口"
		return candidate
	candidate.merge(access)
	candidate["allowed"] = true
	candidate["reason"] = "可搬迁到这片合法空地"
	return candidate

static func reservation_at(world: RefCounted,p: Vector2) -> Dictionary:
	for item in world.near_planning_reservations(p):
		if Geometry2D.is_point_in_polygon(p,item["polygon"]): return item
	return {}

static func candidate(world: RefCounted,p: Vector2) -> Dictionary:
	var selected: Dictionary = {}
	var reservation := reservation_at(world,p)
	if not reservation.is_empty():
		selected = {"source_site_id":reservation["source_site_id"],"reservation_id":reservation["reservation_id"],"polygon":reservation["polygon"]}
	else:
		var site: Dictionary = world.public_at(p)
		if not site.is_empty():
			if bool(site["active"]): return {}
			selected = {"source_site_id":site["id"],"public_id":site["id"],"polygon":site["polygon"]}
		else:
			for lot in world.near_lots(p):
				if not str(lot["occupant"]).is_empty() or not Geometry2D.is_point_in_polygon(p,lot["polygon"]): continue
				selected = {"source_site_id":lot["id"],"polygon":lot["polygon"]}
				break
			if selected.is_empty():
				var court := FabricRelations.courtyard_at(world,p)
				if not court.is_empty():
					var center := Vector2(float(court["center"][0]),float(court["center"][1]))
					var half := minf(0.35,float(court["clear_diameter"])*0.25)
					selected = {"source_site_id":court["id"],"polygon":NeighborhoodPlan.box(center,Vector2.ONE*half)}
	if selected.is_empty(): return {}
	var polygon: PackedVector2Array = selected["polygon"]
	var center := bounds(polygon).get_center()
	selected["position"] = [center.x,center.y]
	selected["community_id"] = FabricRelations.community_for_position(world,center)
	selected["reason"] = site_reason(world,selected)
	selected["allowed"] = str(selected["reason"]).is_empty()
	return selected

static func public_access(world: RefCounted,site: Dictionary) -> Dictionary:
	var polygon: PackedVector2Array = site["polygon"]
	var center := bounds(polygon).get_center()
	var best: Dictionary = {}
	var distance := INF
	for segment in world.near_road_segments(center,3.0):
		if bool(segment["road"].get("bridge",false)): continue
		var q := Geometry2D.get_closest_point_to_segment(center,segment["a"],segment["b"])
		var gap := center.distance_to(q)
		if gap >= distance or gap > 3.0: continue
		var path := PackedVector2Array([center,q])
		if not Geometry2D.intersect_polyline_with_polygon(path,world.terrain.water).is_empty(): continue
		var blocked := false
		for id in world.index.query_circle((center+q)*0.5,gap*0.5):
			var building: Dictionary = world.by_id[id]
			if WorldCoupling.position_of(building).distance_to(Geometry2D.get_closest_point_to_segment(WorldCoupling.position_of(building),center,q)) < float(building["radius"]):
				blocked = true
				break
		if blocked: continue
		distance = gap
		best = {"entrance":[q.x,q.y],"road_id":str(segment["road"]["id"]),"access_path":path}
	return best

## Explain a stale planning intent at the commit boundary. The request was
## accepted against an earlier preview, so the player needs the actual reason
## when another growth or operation changed that parcel before the phrase.
## This is diagnostic state only; it never changes the commit decision.
static func rejection_reason(world: RefCounted,operation: Dictionary) -> String:
	var kind := str(operation.get("kind","规划"))
	if kind == "release_reservation":
		return "这片留地已经释放，请重新选择空地"
	if kind == "reserve" and operation.has("polygon"):
		var raw_anchor: Array = operation.get("position",[])
		var anchor := Vector2.INF
		if raw_anchor.size() == 2: anchor = Vector2(float(raw_anchor[0]),float(raw_anchor[1]))
		var polygon_site := polygon_candidate(world,operation["polygon"],anchor)
		if polygon_site.is_empty(): return "自由留地范围已失效，请重新绘制一片连续简单范围"
		if not bool(polygon_site.get("allowed",false)): return str(polygon_site.get("reason","这片范围已不可用"))
		if str(polygon_site.get("source_site_id","")) != str(operation.get("source_site_id","")):
			return "自由留地的来源地块已变化，请重新绘制"
		if polygon_site.get("polygon",PackedVector2Array()) != normalize_polygon(operation["polygon"]):
			return "自由留地的范围已变化，请重新绘制"
		return "自由留地条件在乐句边界失效，请重新绘制"
	if not operation.has("position"):
		return "规划位置已失效，请重新选择"
	var raw: Array = operation["position"]
	var site := candidate(world,Vector2(float(raw[0]),float(raw[1])))
	if site.is_empty():
		return "这片空间已经被城市占用，请重新选择"
	if not bool(site.get("allowed",false)):
		return str(site.get("reason","这片空间已不可用"))
	if str(site.get("source_site_id","")) != str(operation.get("source_site_id","")):
		return "这片空地的来源已变化，请重新选择"
	if operation.has("polygon") and site.get("polygon",PackedVector2Array()) != operation["polygon"]:
		return "这片空地的范围已变化，请重新选择"
	if kind == "reserve" and (site.has("reservation_id") or site.has("public_id")):
		return "这里已经是留地或公共空间，请选择其他空地"
	if kind in ["park","civic"] and public_access(world,site).is_empty():
		return "公共空间的真实入口已被阻断，请先换一片能接入道路的空地"
	return "规划条件在乐句边界失效，请重新选择"

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> bool:
	var kind := str(operation["kind"])
	if kind == "release_reservation":
		var id := str(operation["id"])
		var old_size: int = world.planning_reservations.size()
		world.planning_reservations = world.planning_reservations.filter(func(item: Dictionary) -> bool: return str(item["reservation_id"]) != id)
		if world.planning_reservations.size() == old_size: return false
		world._refresh_parcel_index()
		world.events.append({"kind":kind,"id":id,"frame":frame})
		return true
	var site: Dictionary
	if kind == "reserve" and operation.has("polygon"):
		var raw_polygon_anchor: Array = operation.get("position",[])
		var polygon_anchor := Vector2.INF
		if raw_polygon_anchor.size() == 2: polygon_anchor = Vector2(float(raw_polygon_anchor[0]),float(raw_polygon_anchor[1]))
		site = polygon_candidate(world,operation["polygon"],polygon_anchor)
	else:
		var raw: Array = operation["position"]
		site = candidate(world,Vector2(float(raw[0]),float(raw[1])))
	if site.is_empty() or not bool(site["allowed"]) or str(site["source_site_id"]) != str(operation["source_site_id"]): return false
	if site["polygon"] != operation["polygon"]: return false
	if kind == "reserve":
		if site.has("reservation_id") or site.has("public_id"): return false
		var id := "reservation-%05d" % int(operation["event_id"])
		world.planning_reservations.append({"id":id,"reservation_id":id,"polygon":site["polygon"].duplicate(),"position":site["position"].duplicate(),
			"source_site_id":site["source_site_id"],"created_phrase":world.phrase_index})
		world._refresh_parcel_index()
		world.events.append({"kind":kind,"id":id,"source_site_id":site["source_site_id"],"frame":frame})
		return true
	var access := public_access(world,site)
	if access.is_empty(): return false
	var new_site := {"id":"player-"+kind+"-%05d" % int(operation["event_id"]),"kind":kind,
		"name":"自选公园" if kind == "park" else "自选文化馆","polygon":site["polygon"].duplicate(),"position":site["position"].duplicate(),
		"community_id":site["community_id"],"active":true,"frame":frame,"service_level":1,"player_planned":true,"source_site_id":site["source_site_id"]}
	new_site.merge(access)
	var public_id := str(site.get("public_id",""))
	if not public_id.is_empty(): new_site["id"] = public_id
	preload("res://scripts/world/development_charter.gd").mark_anchor(world,new_site,str(site.get("reservation_id","")))
	if not public_id.is_empty():
		for old in world.public_sites:
			if str(old["id"]) == public_id:
				new_site["id"] = public_id
				old.merge(new_site,true)
	else:
		world.public_sites.append(new_site)
	var reservation_id := str(site.get("reservation_id",""))
	if not reservation_id.is_empty():
		world.planning_reservations = world.planning_reservations.filter(func(item: Dictionary) -> bool: return str(item["reservation_id"]) != reservation_id)
	world._refresh_parcel_index()
	world.events.append({"kind":kind,"id":new_site["id"],"source_site_id":site["source_site_id"],"converted_reservation":reservation_id,"frame":frame})
	return true
