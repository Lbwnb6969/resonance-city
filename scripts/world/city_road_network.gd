class_name CityRoadNetwork
extends RefCounted
## Physical graph only. Acoustic edges and administrative IDs never enter this graph.
var nodes: Dictionary = {}
var roads: Array = []
var adjacency: Dictionary = {}
var terrain: RefCounted

func rebuild(city_nodes: Dictionary, city_roads: Array, city_terrain: RefCounted) -> void:
	nodes = city_nodes
	roads = city_roads
	terrain = city_terrain
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
	return {"distance":distance[finish],"edges":edge_ids,"path":path}

func road_by_id(id: String) -> Dictionary:
	for road in roads:
		if road["id"] == id: return road
	return {}

func access(p: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var nearest := INF
	for road in roads:
		var path: PackedVector2Array = road["path"]
		var along := 0.0
		for i in range(path.size()-1):
			var q := Geometry2D.get_closest_point_to_segment(p,path[i],path[i+1])
			var connector := PackedVector2Array([p,q])
			var valid := Geometry2D.intersect_polyline_with_polygon(connector,terrain.water).is_empty()
			var gap := p.distance_to(q)
			if valid and gap < nearest-0.000001:
				nearest = gap
				best = {"road":road["id"],"from":road["from"],"to":road["to"],"along":along+path[i].distance_to(q),"length":road["length"],"gap":gap,"position":[q.x,q.y]}
			along += path[i].distance_to(path[i+1])
	return best

func walking_distance(a: Vector2,b: Vector2) -> float:
	var aa := access(a)
	var bb := access(b)
	if aa.is_empty() or bb.is_empty(): return INF
	var best := absf(float(aa["along"])-float(bb["along"])) if aa["road"] == bb["road"] else INF
	for left in [[aa["from"],aa["along"]],[aa["to"],float(aa["length"])-float(aa["along"])]]:
		for right in [[bb["from"],bb["along"]],[bb["to"],float(bb["length"])-float(bb["along"])]]:
			best = minf(best,float(left[1])+float(route(left[0],right[0])["distance"])+float(right[1]))
	return best+float(aa["gap"])+float(bb["gap"])
