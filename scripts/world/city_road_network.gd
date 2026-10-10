class_name CityRoadNetwork
extends RefCounted
## Physical graph only. Acoustic edges and administrative IDs never enter this graph.
var nodes: Dictionary = {}
var roads: Array = []
var adjacency: Dictionary = {}
var terrain: RefCounted
var topology := ""
var route_cache: Dictionary = {}
var access_cache: Dictionary = {}
var walking_distance_cache: Dictionary = {}

func rebuild(city_nodes: Dictionary, city_roads: Array, city_terrain: RefCounted) -> void:
	var identity: Array = []
	for road in city_roads: identity.append([road["id"],road["from"],road["to"],str(road["path"])])
	var next_topology := JSON.stringify([city_nodes,identity,str(city_terrain.water)])
	nodes = city_nodes
	roads = city_roads
	terrain = city_terrain
	if next_topology == topology: return
	topology = next_topology
	route_cache.clear()
	access_cache.clear()
	walking_distance_cache.clear()
	adjacency.clear()
	for id in nodes: adjacency[id] = []
	for road in roads:
		var path: PackedVector2Array = road["path"]
		var length := 0.0
		for i in range(path.size()-1): length += path[i].distance_to(path[i+1])
		road["length"] = length
		adjacency[road["from"]].append({"to":road["to"],"road":road["id"],"cost":length})
		adjacency[road["to"]].append({"to":road["from"],"road":road["id"],"cost":length})
	for edges in adjacency.values():
		edges.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["road"] < b["road"])

func route(start: String, finish: String) -> Dictionary:
	var key := start+">"+finish
	if route_cache.has(key): return route_cache[key]
	if not nodes.has(start) or not nodes.has(finish): return {"distance":INF,"edges":[],"path":PackedVector2Array()}
	var distance := {start:0.0}
	var parent: Dictionary = {}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		queue.sort_custom(func(a: String,b: String) -> bool:
			if distance[a] != distance[b]: return distance[a] < distance[b]
			return a < b)
		var current: String = queue.pop_front()
		if current == finish: break
		for edge in adjacency[current]:
			var candidate := float(distance[current])+float(edge["cost"])
			if candidate < float(distance.get(edge["to"],INF))-0.000001:
				distance[edge["to"]] = candidate
				parent[edge["to"]] = {"node":current,"road":edge["road"]}
				if not queue.has(edge["to"]): queue.append(edge["to"])
	if not distance.has(finish): return {"distance":INF,"edges":[],"path":PackedVector2Array()}
	var steps: Array = []
	var cursor := finish
	while cursor != start:
		steps.push_front({"from":parent[cursor]["node"],"to":cursor,"road":parent[cursor]["road"]})
		cursor = parent[cursor]["node"]
	var path := PackedVector2Array()
	var edge_ids: Array = []
	for step in steps:
		var road: Dictionary = road_by_id(step["road"])
		var part: PackedVector2Array = road["path"].duplicate()
		if road["from"] != step["from"]: part.reverse()
		if not path.is_empty(): part.remove_at(0)
		path.append_array(part)
		edge_ids.append(road["id"])
	if path.is_empty():
		var p: Array = nodes[start]
		path.append(Vector2(p[0],p[1]))
	var result := {"distance":distance[finish],"edges":edge_ids,"path":path}
	route_cache[key] = result
	return result

func road_by_id(id: String) -> Dictionary:
	for road in roads:
		if road["id"] == id: return road
	return {}

func access(p: Vector2) -> Dictionary:
	if access_cache.has(p): return access_cache[p]
	var best: Dictionary = {}
	var nearest := INF
	for road in roads:
		var path: PackedVector2Array = road["path"]
		var along := 0.0
		for i in range(path.size()-1):
			var q := Geometry2D.get_closest_point_to_segment(p,path[i],path[i+1])
			var gap := p.distance_to(q)
			if gap >= nearest-0.000001:
				along += path[i].distance_to(path[i+1])
				continue
			var connector := PackedVector2Array([p,q])
			var valid := Geometry2D.intersect_polyline_with_polygon(connector,terrain.water).is_empty()
			if valid:
				nearest = gap
				best = {"road":road["id"],"from":road["from"],"to":road["to"],"along":along+path[i].distance_to(q),"length":road["length"],"gap":gap,"position":[q.x,q.y]}
			along += path[i].distance_to(path[i+1])
	access_cache[p] = best
	return best

func walking_route(a: Vector2,b: Vector2) -> Dictionary:
	var aa := access(a)
	var bb := access(b)
	if aa.is_empty() or bb.is_empty(): return {"distance":INF,"path":PackedVector2Array()}
	var best := INF
	var middle := PackedVector2Array()
	if aa["road"] == bb["road"]:
		best = absf(float(aa["along"])-float(bb["along"]))
		middle = _road_slice(road_by_id(aa["road"]),float(aa["along"]),float(bb["along"]))
	for left in [[aa["from"],0.0,aa["along"]],[aa["to"],aa["length"],float(aa["length"])-float(aa["along"])]]:
		for right in [[bb["from"],0.0,bb["along"]],[bb["to"],bb["length"],float(bb["length"])-float(bb["along"])]]:
			var journey := route(left[0],right[0])
			var candidate := float(left[2])+float(journey["distance"])+float(right[2])
			if candidate >= best: continue
			best = candidate
			middle = _road_slice(road_by_id(aa["road"]),float(aa["along"]),float(left[1]))
			middle.append_array(journey["path"])
			middle.append_array(_road_slice(road_by_id(bb["road"]),float(right[1]),float(bb["along"])))
	var path := PackedVector2Array([a])
	for p in middle:
		if path[-1].distance_to(p) > 0.00001: path.append(p)
	if path[-1].distance_to(b) > 0.00001: path.append(b)
	return {"distance":best+float(aa["gap"])+float(bb["gap"]),"path":path}

func _road_slice(road: Dictionary, begin: float, end: float) -> PackedVector2Array:
	var reverse := begin > end
	var low := minf(begin,end)
	var high := maxf(begin,end)
	var result := PackedVector2Array()
	var path: PackedVector2Array = road["path"]
	var along := 0.0
	for i in range(path.size()-1):
		var length := path[i].distance_to(path[i+1])
		var first := maxf(low,along)
		var last := minf(high,along+length)
		if first <= last:
			var p := path[i].lerp(path[i+1],(first-along)/maxf(length,0.00001))
			var q := path[i].lerp(path[i+1],(last-along)/maxf(length,0.00001))
			if result.is_empty() or result[-1].distance_to(p) > 0.00001: result.append(p)
			if result[-1].distance_to(q) > 0.00001: result.append(q)
		along += length
	if reverse: result.reverse()
	return result

func walking_distance(a: Vector2,b: Vector2) -> float:
	var key := Vector4(a.x,a.y,b.x,b.y)
	if walking_distance_cache.has(key): return float(walking_distance_cache[key])
	var aa := access(a)
	var bb := access(b)
	if aa.is_empty() or bb.is_empty(): return INF
	var best := absf(float(aa["along"])-float(bb["along"])) if aa["road"] == bb["road"] else INF
	for left in [[aa["from"],aa["along"]],[aa["to"],float(aa["length"])-float(aa["along"])]]:
		for right in [[bb["from"],bb["along"]],[bb["to"],float(bb["length"])-float(bb["along"])]]:
			best = minf(best,float(left[1])+float(route(left[0],right[0])["distance"])+float(right[1]))
	var distance := best+float(aa["gap"])+float(bb["gap"])
	walking_distance_cache[key] = distance
	walking_distance_cache[Vector4(b.x,b.y,a.x,a.y)] = distance
	return distance
