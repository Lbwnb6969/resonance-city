class_name FabricRelations
extends RefCounted
## Visual-only building relationships. Never feeds R/V or audio grouping.

static func gap(a: Dictionary, b: Dictionary) -> float:
	return WorldCoupling.position_of(a).distance_to(WorldCoupling.position_of(b))-float(a["radius"])-float(b["radius"])

static func _bucket(v: Vector2) -> int:
	return posmod(roundi(atan2(v.y,v.x)/(TAU/8.0)),8)

static func _road_width(world: RefCounted, road: Dictionary) -> float:
	if bool(road.get("bridge",false)): return 0.55
	if str(road.get("kind","")) == "branch": return float(world.cfg["city"]["branch_road_half_width"])
	return float(world.cfg["terrain"]["template_road_half_width"])

static func frontage_directions(world: RefCounted, p: Vector2) -> Array[int]:
	var directions: Dictionary = {}
	for segment in world.near_road_segments(p,1.35):
		if bool(segment["road"].get("bridge",false)): continue
		var q := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
		var delta := q-p
		var distance := delta.length()
		if distance > 1.35 or distance < 0.0001: continue
		var connector := PackedVector2Array([p,q])
		if not Geometry2D.intersect_polyline_with_polygon(connector,world.terrain.water).is_empty(): continue
		directions[_bucket(delta)] = true
	var result: Array[int] = []
	for key in directions.keys(): result.append(int(key))
	return result

static func nearest_road(world: RefCounted, p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var nearest := INF
	for road in world.roads:
		var path: PackedVector2Array = road["path"]
		for i in range(path.size()-1):
			var q := Geometry2D.get_closest_point_to_segment(p,path[i],path[i+1])
			var distance := p.distance_to(q)
			if distance < nearest:
				nearest = distance
				best = {"road":road["id"],"gap":distance,"position":q}
	return best

static func on_road(world: RefCounted, p: Vector2, radius: float) -> bool:
	var width := maxf(0.55,maxf(float(world.cfg["city"]["branch_road_half_width"]),float(world.cfg["terrain"]["template_road_half_width"])))
	for segment in world.near_road_segments(p,radius+width):
		var road_width := _road_width(world,segment["road"])
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])) < radius+road_width-0.02:
			return true
	return false

static func reserved(world: RefCounted, p: Vector2) -> bool:
	for site in world.near_public_sites(p):
		if Geometry2D.is_point_in_polygon(p,site["polygon"]): return true
	return false

static func community_for_position(world: RefCounted, p: Vector2) -> String:
	var best := ""
	var nearest := INF
	for lot in world.lots:
		var center := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var distance := p.distance_squared_to(center)
		if distance < nearest:
			nearest = distance
			best = str(lot["community_id"])
	if not best.is_empty(): return best
	for cid in world.communities:
		var members: Array = world.communities[cid].get("members",[])
		for id in members:
			if not world.by_id.has(id): continue
			var distance := p.distance_squared_to(WorldCoupling.position_of(world.by_id[id]))
			if distance < nearest:
				nearest = distance
				best = str(cid)
	return best if not best.is_empty() else str(world.communities.keys()[0]) if not world.communities.is_empty() else "wild"

static func courtyard_at(world: RefCounted, p: Vector2) -> Dictionary:
	for courtyard in world.fabric_cache.get("courtyards",[]):
		var polygon: PackedVector2Array = courtyard.get("polygon",PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(p,polygon):
			return courtyard
	return {}

static func tier_for(world: RefCounted, p: Vector2, lot_id: String = "", community_id: String = "") -> Dictionary:
	var frontage := frontage_directions(world,p)
	var tier := "L3"
	if not lot_id.is_empty() and frontage.size() > 0: tier = "L1"
	elif frontage.size() >= 2: tier = "L1"
	elif frontage.size() == 1: tier = "L2"
	var cid := community_id if not community_id.is_empty() else community_for_position(world,p)
	var labels := {"L1":"沿街地块 · 可成长","L2":"侧街地块 · 稍慢","L3":"孤屋空地 · 停在群"}
	return {"tier":tier,"frontage":frontage.size(),"lot_id":lot_id,"community_id":cid,
		"preview":labels[tier],"growth_delay":2 if tier == "L3" else (2 if tier == "L2" else 1),
		"max_form":"群" if tier == "L3" else "腔"}

static func _street_id(world: RefCounted, p: Vector2) -> String:
	var nearest := INF
	var result := ""
	for segment in world.near_road_segments(p,1.35):
		var distance := p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"]))
		if distance <= 1.35 and distance < nearest:
			nearest = distance
			result = str(segment["road"]["id"])
	return result

static func _connected_components(ids: Array, adjacency: Dictionary) -> Array:
	var remaining: Dictionary = {}
	for id in ids: remaining[id] = true
	var groups: Array = []
	while not remaining.is_empty():
		var start: String = remaining.keys()[0]
		var queue: Array[String] = [start]
		remaining.erase(start)
		var group: Array[String] = []
		while not queue.is_empty():
			var current: String = queue.pop_front()
			group.append(current)
			for next in adjacency.get(current,[]):
				if remaining.has(next):
					remaining.erase(next)
					queue.append(next)
		group.sort()
		groups.append(group)
	return groups

static func rebuild(world: RefCounted) -> Dictionary:
	world._refresh_parcel_index()
	var started := Time.get_ticks_usec()
	var shared: Array = []
	var adjacency: Dictionary = {}
	var street_ids: Dictionary = {}
	for building in world.buildings:
		var id: String = building["district_id"]
		adjacency[id] = []
		street_ids[id] = _street_id(world,WorldCoupling.position_of(building))
	var order: Dictionary = {}
	for i in range(world.buildings.size()): order[world.buildings[i]["district_id"]] = i
	for i in range(world.buildings.size()):
		var a: Dictionary = world.buildings[i]
		var aid: String = a["district_id"]
		var nearby: Array = []
		for id in world.index.query_circle(WorldCoupling.position_of(a),float(a["radius"])+0.25+1e-6):
			if int(order[id]) > i: nearby.append(id)
		nearby.sort_custom(func(left: String,right: String) -> bool: return int(order[left]) < int(order[right]))
		for bid in nearby:
			var b: Dictionary = world.by_id[bid]
			var distance := gap(a,b)
			if distance <= 0.10+1e-6:
				shared.append({"a":aid,"b":bid,"gap":distance})
			if distance <= 0.25+1e-6 and not str(street_ids[aid]).is_empty() and street_ids[aid] == street_ids[bid]:
				adjacency[aid].append(bid)
				adjacency[bid].append(aid)
	var rows: Array = []
	for component in _connected_components(adjacency.keys(),adjacency):
		var cursor := 0
		while cursor < component.size():
			var segment: Array = component.slice(cursor,min(component.size(),cursor+6))
			rows.append({"members":segment,"split_gap":0.3 if cursor > 0 else 0.0})
			cursor += 6
	world.fabric_profile["walls_rows_ms"] = float(Time.get_ticks_usec()-started)/1000.0
	started = Time.get_ticks_usec()
	var geometry: Array = [str(world.terrain.water),world.terrain.cfg["template_land_min"],world.terrain.cfg["template_land_max"]]
	for site in world.public_sites: geometry.append([site["id"],site["polygon"]])
	var identity := JSON.stringify(geometry)
	if identity != world.fabric_geometry_identity:
		world.fabric_geometry_identity = identity
		world.fabric_anchor_cache.clear()
	var next_cache: Dictionary = {}
	for anchor in world.buildings:
		var anchor_id: String = anchor["district_id"]
		var nearby: Array[Dictionary] = []
		var signature: Array = [WorldCoupling.position_of(anchor)]
		for id in world.index.query_circle(WorldCoupling.position_of(anchor),3.2):
			if str(id) <= anchor_id or not world.by_id.has(id): continue
			nearby.append(world.by_id[id])
			signature.append([id,WorldCoupling.position_of(world.by_id[id])])
		var cached: Dictionary = world.fabric_anchor_cache.get(anchor_id,{})
		if cached.get("signature",[]) != signature:
			cached = {"signature":signature,"courts":_anchor_courts(world,anchor,nearby,cached)}
		next_cache[anchor_id] = cached
	world.fabric_anchor_cache = next_cache
	world.fabric_profile["anchor_ms"] = float(Time.get_ticks_usec()-started)/1000.0
	started = Time.get_ticks_usec()
	var courts := _select_courtyards(world,next_cache)
	world.fabric_profile["select_ms"] = float(Time.get_ticks_usec()-started)/1000.0
	return {"shared_walls":shared,"rows":rows,"courtyards":courts,"community_wall":community_wall_stats(world)}

static func _anchor_courts(world: RefCounted, anchor: Dictionary, nearby: Array[Dictionary], cached: Dictionary) -> Array:
	var courts: Array = []
	var anchor_id: String = anchor["district_id"]
	var previous: Array = cached.get("signature",[])
	var old_neighbors: Dictionary = {}
	var can_extend: bool = not previous.is_empty() and previous[0] == WorldCoupling.position_of(anchor)
	if can_extend:
		var positions: Dictionary = {}
		for building in nearby: positions[building["district_id"]] = WorldCoupling.position_of(building)
		for item in previous.slice(1):
			if not positions.has(item[0]) or positions[item[0]] != item[1]:
				can_extend = false
				break
			old_neighbors[item[0]] = true
	if can_extend: courts = cached["courts"].duplicate()
	else: old_neighbors.clear()
	for j in range(nearby.size()):
		for k in range(j+1,nearby.size()):
			if old_neighbors.has(nearby[j]["district_id"]) and old_neighbors.has(nearby[k]["district_id"]): continue
			var points := PackedVector2Array([WorldCoupling.position_of(anchor),WorldCoupling.position_of(nearby[j]),WorldCoupling.position_of(nearby[k])])
			var hull := Geometry2D.convex_hull(points)
			if hull.size() < 3: continue
			var bounds := Rect2(hull[0],Vector2.ZERO)
			for p in hull: bounds = bounds.expand(p)
			if minf(bounds.size.x,bounds.size.y) < 0.8: continue
			var center := (points[0]+points[1]+points[2])/3.0
			if not world.terrain.land_at(center) or reserved(world,center): continue
			var members := [anchor_id,str(nearby[j]["district_id"]),str(nearby[k]["district_id"])]
			members.sort()
			courts.append({"id":"courtyard:"+":".join(members),"members":members,"center":[center.x,center.y],"polygon":hull,"clear_diameter":minf(bounds.size.x,bounds.size.y)})
	courts.sort_custom(_court_before)
	return courts

static func _court_before(a: Dictionary,b: Dictionary) -> bool:
	if float(a["clear_diameter"]) != float(b["clear_diameter"]):
		return float(a["clear_diameter"]) > float(b["clear_diameter"])
	return str(a["id"]) < str(b["id"])

static func _entry_before(a: Dictionary,b: Dictionary) -> bool:
	return _court_before(a["courts"][a["cursor"]],b["courts"][b["cursor"]])

static func _heap_push(heap: Array, entry: Dictionary) -> void:
	heap.append(entry)
	var child := heap.size()-1
	while child > 0:
		var parent: int = (child-1)/2
		if not _entry_before(heap[child],heap[parent]): break
		var previous: Dictionary = heap[parent]
		heap[parent] = heap[child]
		heap[child] = previous
		child = parent

static func _heap_pop(heap: Array) -> Dictionary:
	var first: Dictionary = heap[0]
	var tail: Dictionary = heap.pop_back()
	if not heap.is_empty():
		heap[0] = tail
		var parent := 0
		while parent*2+1 < heap.size():
			var child := parent*2+1
			if child+1 < heap.size() and _entry_before(heap[child+1],heap[child]): child += 1
			if not _entry_before(heap[child],heap[parent]): break
			var previous: Dictionary = heap[parent]
			heap[parent] = heap[child]
			heap[child] = previous
			parent = child
	return first

static func _select_courtyards(world: RefCounted, anchors: Dictionary) -> Array:
	# Each anchor list is already sorted by the original diameter/ID rule.
	# Merge only the prefix needed for two courts per community, skipping a
	# saturated community without sorting or visiting its remaining triangles.
	var heap: Array = []
	for anchor_id in anchors:
		var courts: Array = anchors[anchor_id]["courts"]
		if not courts.is_empty():
			_heap_push(heap,{"courts":courts,"cursor":0,"community":str(world.by_id[anchor_id]["community_id"])})
	var selected: Array = []
	var counts: Dictionary = {}
	while not heap.is_empty():
		var entry := _heap_pop(heap)
		var community_id := str(entry["community"])
		if int(counts.get(community_id,0)) >= 2: continue
		var candidate: Dictionary = entry["courts"][entry["cursor"]]
		var center := Vector2(float(candidate["center"][0]),float(candidate["center"][1]))
		var duplicate := false
		for prior in selected:
			var prior_center := Vector2(float(prior["center"][0]),float(prior["center"][1]))
			if center.distance_to(prior_center) < 0.72:
				duplicate = true
				break
		if not duplicate:
			# Cached court geometry is immutable after publication; annotate a selection copy.
			candidate = candidate.duplicate()
			candidate["community_id"] = community_id
			selected.append(candidate)
			counts[community_id] = int(counts.get(community_id,0))+1
		entry["cursor"] = int(entry["cursor"])+1
		if int(counts.get(community_id,0)) < 2 and int(entry["cursor"]) < entry["courts"].size():
			_heap_push(heap,entry)
	return selected

static func community_wall_stats(world: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	for cid in world.communities:
		var total := 0
		var occupied := 0
		for lot in world.lots:
			if str(lot["community_id"]) != str(cid): continue
			total += 1
			if not str(lot["occupant"]).is_empty(): occupied += 1
		var score := float(occupied)/float(total) if total > 0 else 0.0
		result[cid] = {"score":score,"tier":"萌芽" if score < 0.35 else ("成街" if score < 0.70 else "街区")}
	return result
