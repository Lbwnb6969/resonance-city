extends RefCounted
## Geometry and player planning share one exclusion contract. No acoustic state.
static func bounds(polygon: PackedVector2Array) -> Rect2:
	var result := Rect2(polygon[0],Vector2.ZERO)
	for p in polygon: result = result.expand(p)
	return result

static func disc_hits(polygon: PackedVector2Array,p: Vector2,radius: float) -> bool:
	if Geometry2D.is_point_in_polygon(p,polygon): return true
	for i in range(polygon.size()):
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,polygon[i],polygon[(i+1)%polygon.size()])) < radius-0.000001:
			return true
	return false

static func overlaps(a: PackedVector2Array,b: PackedVector2Array) -> bool:
	return bounds(a).intersects(bounds(b),true) and not Geometry2D.intersect_polygons(a,b).is_empty()

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

static func site_reason(world: RefCounted,candidate: Dictionary) -> String:
	var polygon: PackedVector2Array = candidate["polygon"]
	var reason := exclusion(world,polygon,str(candidate.get("reservation_id","")),str(candidate.get("public_id","")))
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
	var raw: Array = operation["position"]
	var site := candidate(world,Vector2(float(raw[0]),float(raw[1])))
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
