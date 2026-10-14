class_name CityCreationLife
extends Node3D
## Small, purposeful daily trips on the real continuous street graph.
const UNIT := 1.8
var state: RefCounted
var residents: Array[Dictionary] = []
var connected_houses: Dictionary = {}
var graph: Dictionary = {}
var positions: Dictionary = {}
var last_revision := -1
var purchases := 0
var gatherings := 0
var current_population := 0
var time := 0.0
var arrival_callback: Callable

func setup(city: RefCounted) -> void:
	state = city
	_sync()

func _process(delta: float) -> void:
	if state == null: return
	if state.revision != last_revision: _sync()
	time += delta
	for resident: Dictionary in residents:
		if resident.wait > 0.0:
			resident.wait -= delta
			continue
		if not str(resident.get("service_pending", "")).is_empty():
			var service := str(resident.service_pending)
			if service == "bakery": purchases += 1
			elif service == "venue":
				gatherings += 1
				if arrival_callback.is_valid(): arrival_callback.call("venue")
			resident.service_pending = ""
		var route: Array[Vector3] = resident.route
		var index := int(resident.index)
		if index >= route.size():
			_arrive(resident)
			continue
		var node: Node3D = resident.node
		var target: Vector3 = route[index]
		var remaining := node.position.distance_to(target)
		if remaining < delta * 0.83:
			node.position = target
			resident.index = index + 1
		else:
			var direction := (target - node.position).normalized()
			node.position += direction * delta * 0.83
			node.rotation.y = atan2(direction.x, direction.z)
		node.position.y = _street_height(Vector2(node.position.x,node.position.z))+0.10
		var body: Node3D = node.get_child(0)
		body.position.y = sin(time * 9.0 + float(resident.phase)) * 0.025

func _sync() -> void:
	last_revision = state.revision
	for resident: Dictionary in residents: resident.node.queue_free()
	residents.clear()
	_build_graph()
	var homes: Array[String] = []
	var shops: Array[String] = []
	var venues: Array[String] = []
	current_population = 0
	for house: Dictionary in state.houses:
		var role := str(house.get("role", "residential"))
		if role == "residential":
			current_population += 2
			if connected_houses.has(house.id): homes.append(str(house.id))
		elif connected_houses.has(house.id):
			if role == "bakery": shops.append(str(house.id))
			elif role == "venue": venues.append(str(house.id))
	var serial := 0
	for home: String in homes:
		var stops: Array[String] = [home]
		if not shops.is_empty(): stops.append(shops[serial % shops.size()])
		if not venues.is_empty(): stops.append(venues[serial % venues.size()])
		if stops.size() < 2: continue
		var first_route := _route(connected_houses[home], connected_houses[stops[1]])
		if first_route.is_empty(): continue
		var node := _person(serial)
		node.position = positions[connected_houses[home]] + Vector3(0,0.10,0)
		add_child(node)
		residents.append({"node":node,"stops":stops,"stop":1,"index":0,"route":first_route,"wait":serial*2.4,"phase":serial*1.7})
		serial += 1

func _arrive(resident: Dictionary) -> void:
	var stops: Array[String] = resident.stops
	var reached: String = stops[int(resident.stop)]
	var role := "residential"
	for house: Dictionary in state.houses:
		if house.id == reached: role = str(house.get("role", "residential"))
	resident.service_pending = role
	var next := (int(resident.stop) + 1) % stops.size()
	resident.route = _route(connected_houses[reached], connected_houses[stops[next]])
	resident.index = 0
	resident.stop = next
	resident.wait = 5.0 if role == "venue" else 3.0

func summary() -> String:
	return "%d 位居民 · %d 趟采购 · %d 次小聚" % [current_population, purchases, gatherings]

func house_connected(id: String) -> bool:
	return connected_houses.has(id)

func _key(p: Vector2) -> String:
	return "%d,%d" % [roundi(p.x*1000.0),roundi(p.y*1000.0)]

func _build_graph() -> void:
	graph.clear()
	positions.clear()
	connected_houses.clear()
	var segments: Array[Dictionary] = []
	for road: Dictionary in state.roads:
		for i in range(1, road.points.size()):
			var a := Vector2(road.points[i-1][0],road.points[i-1][1])
			var b := Vector2(road.points[i][0],road.points[i][1])
			if a.distance_to(b) < 0.001: continue
			segments.append({"a":a,"b":b,"splits":[a,b],"width":float(road.width)})
	var connectors: Array[Dictionary] = []
	for i in range(segments.size()):
		for j in range(i):
			var intersection: Variant = Geometry2D.segment_intersects_segment(segments[i].a,segments[i].b,segments[j].a,segments[j].b)
			if intersection != null:
				segments[i].splits.append(intersection)
				segments[j].splits.append(intersection)
			# A free stroke can start anywhere on the physical street strip.
			# Split collinear overlaps and connect nearby centres within the width.
			for pair: Array in [[i,j],[j,i]]:
				var first: Dictionary = segments[int(pair[0])]
				var second: Dictionary = segments[int(pair[1])]
				for endpoint: Vector2 in [first.a,first.b]:
					var nearest := Geometry2D.get_closest_point_to_segment(endpoint,second.a,second.b)
					if endpoint.distance_to(nearest) > minf(float(first.width),float(second.width))*0.5: continue
					second.splits.append(nearest)
					connectors.append({"a":endpoint,"b":nearest,"splits":[endpoint,nearest]})
	segments.append_array(connectors)
	for house: Dictionary in state.houses:
		var best_distance := 0.82
		var best_segment := -1
		var best := Vector2.ZERO
		for cell: Dictionary in house.cells:
			if int(cell.level) != 0 or str(cell.kind) != "room": continue
			var entrance := Vector2(house.origin[0]+int(cell.x)*UNIT,house.origin[1]+int(cell.z)*UNIT+1.52)
			for index in range(segments.size()):
				var nearest := Geometry2D.get_closest_point_to_segment(entrance,segments[index].a,segments[index].b)
				var distance := nearest.distance_to(entrance)
				if distance < best_distance:
					best_distance = distance
					best_segment = index
					best = nearest
		if best_segment >= 0:
			segments[best_segment].splits.append(best)
			connected_houses[house.id] = _key(best)
	for segment: Dictionary in segments:
		var splits: Array = segment.splits
		splits.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.distance_squared_to(segment.a) < b.distance_squared_to(segment.a))
		for i in range(1,splits.size()):
			var a: Vector2 = splits[i-1]
			var b: Vector2 = splits[i]
			if a.distance_to(b) < 0.0005: continue
			var ka := _key(a)
			var kb := _key(b)
			positions[ka] = Vector3(a.x,_street_height(a),a.y)
			positions[kb] = Vector3(b.x,_street_height(b),b.y)
			if not graph.has(ka): graph[ka] = {}
			if not graph.has(kb): graph[kb] = {}
			graph[ka][kb] = a.distance_to(b)
			graph[kb][ka] = a.distance_to(b)

func _street_height(p: Vector2) -> float:
	return 0.055+0.185*(1.0-smoothstep(2.25,2.95,absf(p.x-(3.0+sin(p.y*0.17)*0.52))))

func _route(start: String, finish: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if not graph.has(start) or not graph.has(finish): return result
	var distances := {start:0.0}
	var previous: Dictionary = {}
	var queue: Array[String] = [start]
	var visited: Dictionary = {}
	while not queue.is_empty():
		queue.sort_custom(func(a:String,b:String)->bool: return float(distances[a])<float(distances[b]))
		var current: String = queue.pop_front()
		if visited.has(current): continue
		visited[current] = true
		if current == finish: break
		for neighbor: String in graph[current]:
			var distance := float(distances[current])+float(graph[current][neighbor])
			if distance < float(distances.get(neighbor,INF)):
				distances[neighbor] = distance
				previous[neighbor] = current
				queue.append(neighbor)
	if not visited.has(finish): return result
	var current := finish
	result.push_front(positions[current]+Vector3(0,0.10,0))
	while current != start:
		current = str(previous[current])
		result.push_front(positions[current]+Vector3(0,0.10,0))
	return result

func _person(index: int) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = [Color("b67755"),Color("709694"),Color("c9b273"),Color("889574")][index%4]
	var tunic := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.10
	capsule.height = 0.34
	tunic.mesh = capsule
	tunic.material_override = cloth
	tunic.position.y = 0.22
	body.add_child(tunic)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	head.mesh = sphere
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("e2bb8e")
	head.material_override = skin
	head.position.y = 0.45
	body.add_child(head)
	return root
