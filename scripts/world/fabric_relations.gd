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
	for road in world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road["path"]
		for i in range(path.size()-1):
			var a: Vector2 = path[i]
			var b: Vector2 = path[i+1]
			var q := Geometry2D.get_closest_point_to_segment(p,a,b)
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
	for road in world.roads:
		var path: PackedVector2Array = road["path"]
		var width := _road_width(world,road)
		for i in range(path.size()-1):
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,path[i],path[i+1])) < radius+width-0.02:
				return true
	return false

static func reserved(world: RefCounted, p: Vector2) -> bool:
	for site in world.public_sites:
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
	var road := nearest_road(world,p)
	return str(road.get("road","")) if float(road.get("gap",INF)) <= 1.35 else ""

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
	var shared: Array = []
	var adjacency: Dictionary = {}
	var street_ids: Dictionary = {}
	for building in world.buildings:
		var id: String = building["district_id"]
		adjacency[id] = []
		street_ids[id] = _street_id(world,WorldCoupling.position_of(building))
	for i in range(world.buildings.size()):
		var a: Dictionary = world.buildings[i]
		var aid: String = a["district_id"]
		for j in range(i+1,world.buildings.size()):
			var b: Dictionary = world.buildings[j]
			var bid: String = b["district_id"]
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
	var courts: Array = []
	var seen_courts: Dictionary = {}
	for i in range(world.buildings.size()):
		var anchor: Dictionary = world.buildings[i]
		var anchor_id: String = anchor["district_id"]
		var nearby_ids: Array = world.index.query_circle(WorldCoupling.position_of(anchor),3.2)
		var nearby: Array[Dictionary] = []
		for id in nearby_ids:
			if str(id) <= anchor_id or not world.by_id.has(id): continue
			nearby.append(world.by_id[id])
		for j in range(nearby.size()):
			for k in range(j+1,nearby.size()):
				var points := PackedVector2Array([WorldCoupling.position_of(anchor),WorldCoupling.position_of(nearby[j]),WorldCoupling.position_of(nearby[k])])
				var hull := Geometry2D.convex_hull(points)
				if hull.size() < 3: continue
				var bounds := Rect2(hull[0],Vector2.ZERO)
				for p in hull:
					bounds = bounds.expand(p)
				if minf(bounds.size.x,bounds.size.y) < 0.8: continue
				var center := (points[0]+points[1]+points[2])/3.0
				if not world.terrain.land_at(center) or reserved(world,center): continue
				var members := [anchor_id,str(nearby[j]["district_id"]),str(nearby[k]["district_id"])]
				members.sort()
				var key := ":".join(members)
				if seen_courts.has(key): continue
				seen_courts[key] = true
				courts.append({"id":"courtyard:"+key,"members":members,"center":[center.x,center.y],"polygon":hull,"clear_diameter":minf(bounds.size.x,bounds.size.y)})
	return {"shared_walls":shared,"rows":rows,"courtyards":_select_courtyards(world,courts),"community_wall":community_wall_stats(world)}

static func _select_courtyards(world: RefCounted, candidates: Array) -> Array:
	# Many adjacent triples describe the same open court. Keep the clearest two
	# per community and reject near-duplicate centers so the visual layer stays legible.
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if float(a.get("clear_diameter",0.0)) != float(b.get("clear_diameter",0.0)):
			return float(a.get("clear_diameter",0.0)) > float(b.get("clear_diameter",0.0))
		return str(a.get("id","")) < str(b.get("id","")))
	var selected: Array = []
	var counts: Dictionary = {}
	for candidate in candidates:
		var members: Array = candidate.get("members",[])
		if members.is_empty() or not world.by_id.has(members[0]): continue
		var community_id := str(world.by_id[members[0]].get("community_id",""))
		if int(counts.get(community_id,0)) >= 2: continue
		var center := Vector2(float(candidate["center"][0]),float(candidate["center"][1]))
		var duplicate := false
		for prior in selected:
			var prior_center := Vector2(float(prior["center"][0]),float(prior["center"][1]))
			if center.distance_to(prior_center) < 0.72:
				duplicate = true
				break
		if duplicate: continue
		candidate["community_id"] = community_id
		selected.append(candidate)
		counts[community_id] = int(counts.get(community_id,0))+1
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
