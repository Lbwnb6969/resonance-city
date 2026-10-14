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

var _network_signature: Array = []
var _roles: Dictionary = {}

func setup(city: RefCounted) -> void:
	if state != city:
		for resident: Dictionary in residents: resident.node.queue_free()
		residents.clear()
		_network_signature.clear()
		last_revision = -1
	state = city
	_read_progress()
	_sync()

func _read_progress() -> void:
	purchases = int(state.life_progress.purchases)
	gatherings = int(state.life_progress.gatherings)

func _process(delta: float) -> void:
	if state == null: return
	if state.revision != last_revision: _sync()
	time += delta
	for resident: Dictionary in residents:
		if resident.paused: continue
		if resident.wait > 0.0:
			resident.wait = maxf(0.0, float(resident.wait) - delta)
			continue
		if not str(resident.get("dwell_id", "")).is_empty():
			# Foundation's Visit Building graph separates reaching, waiting and
			# filling the need. An edit never counts as finishing that sequence.
			var reached := str(resident.dwell_id)
			var service := str(resident.service_pending)
			resident.dwell_id = ""
			resident.service_pending = ""
			if service == "bakery": state.record_life_event("purchases")
			elif service == "venue":
				state.record_life_event("gatherings")
				if arrival_callback.is_valid(): arrival_callback.call("venue")
			_read_progress()
			_depart(resident, reached)
			if resident.paused: continue
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
		node.position.y = state.street_height(Vector2(node.position.x,node.position.z))+0.10
		var body: Node3D = node.get_child(0)
		body.position.y = sin(time * 9.0 + float(resident.phase)) * 0.025

func _signature() -> Array:
	var result: Array = []
	for road: Dictionary in state.roads:
		result.append([road.points.duplicate(true), float(road.width)])
	# Water geometry changes bridge elevations even when roads and entrances
	# are untouched. Names, IDs and vegetation never invalidate a journey.
	for water: Dictionary in state.waters:
		result.append([str(water.kind), water.points.duplicate(true), float(water.width)])
	for house: Dictionary in state.houses:
		var entrances: Array = []
		for cell: Dictionary in house.cells:
			if int(cell.level) == 0 and str(cell.kind) == "room":
				entrances.append([int(cell.x), int(cell.z)])
		result.append([str(house.id), house.origin.duplicate(), str(house.get("role", "residential")), entrances])
	return result

func _sync() -> void:
	last_revision = state.revision
	_read_progress()
	var signature := _signature()
	if signature == _network_signature: return
	_network_signature = signature
	_build_graph()
	_roles.clear()
	var old_by_home: Dictionary = {}
	for resident: Dictionary in residents: old_by_home[resident.home_id] = resident
	var next_residents: Array[Dictionary] = []
	var shops: Array[String] = []
	var venues: Array[String] = []
	var homes: Array[String] = []
	current_population = 0
	for house: Dictionary in state.houses:
		var role := str(house.get("role", "residential"))
		_roles[str(house.id)] = role
		if role == "residential":
			current_population += 2
			homes.append(str(house.id))
		elif connected_houses.has(house.id):
			if role == "bakery": shops.append(str(house.id))
			elif role == "venue": venues.append(str(house.id))
	for home: String in homes:
		var serial := next_residents.size()
		var stops: Array[String] = [home]
		if connected_houses.has(home):
			_append_reachable(stops, home, shops, serial)
			_append_reachable(stops, home, venues, serial)
		var resident: Dictionary = old_by_home.get(home, {})
		if resident.is_empty():
			if stops.size() < 2: continue
			var node := _person(serial)
			node.position = positions[connected_houses[home]] + Vector3(0,0.10,0)
			add_child(node)
			resident = {"node":node,"home_id":home,"destination_id":stops[1],"stops":stops,"stop":1,"index":0,"route":_route(connected_houses[home],connected_houses[stops[1]]),"wait":serial*2.4,"phase":serial*1.7,"paused":false,"dwell_id":"","service_pending":""}
		else:
			old_by_home.erase(home)
			var node: Node3D = resident.node
			node.position.y = state.street_height(Vector2(node.position.x,node.position.z))+0.10
			resident.stops = stops
			if stops.size() < 2:
				_pause_at_home(resident)
			else:
				_resume(resident)
		next_residents.append(resident)
	for resident: Dictionary in old_by_home.values(): resident.node.queue_free()
	residents = next_residents

func _append_reachable(stops: Array[String], home: String, candidates: Array[String], serial: int) -> void:
	for offset in range(candidates.size()):
		var candidate := candidates[(serial + offset) % candidates.size()]
		if not _route(connected_houses[home], connected_houses[candidate]).is_empty():
			stops.append(candidate)
			return

func _pause_at_home(resident: Dictionary) -> void:
	resident.paused = true
	resident.wait = 0.0
	resident.dwell_id = ""
	resident.service_pending = ""
	var empty_route: Array[Vector3] = []
	resident.route = empty_route
	resident.index = 0
	resident.destination_id = resident.home_id
	for house: Dictionary in state.houses:
		if str(house.id) != str(resident.home_id): continue
		var entrance := Vector2(float(house.origin[0]),float(house.origin[1])+1.52)
		if connected_houses.has(house.id):
			resident.node.position = positions[connected_houses[house.id]]+Vector3(0,0.10,0)
		else:
			resident.node.position = Vector3(entrance.x,state.street_height(entrance)+0.10,entrance.y)

func _resume(resident: Dictionary) -> void:
	var stops: Array[String] = resident.stops
	var destination := str(resident.destination_id)
	if resident.paused or not stops.has(destination):
		destination = stops[1]
		resident.dwell_id = ""
		resident.service_pending = ""
		resident.wait = 0.0
	resident.destination_id = destination
	resident.stop = stops.find(destination)
	# A resident already dwelling may keep that exact visit only while the
	# same entrance and use survive. Otherwise the pending event is cancelled.
	if not str(resident.dwell_id).is_empty():
		var target: Vector3 = positions[connected_houses[destination]]+Vector3(0,0.10,0)
		if str(_roles[destination]) == str(resident.service_pending) and resident.node.position.distance_to(target) < 0.15:
			resident.paused = false
			return
		resident.dwell_id = ""
		resident.service_pending = ""
		resident.wait = 0.0
	var route := _route_from_position(resident.node.position, connected_houses[destination])
	if route.is_empty():
		_pause_at_home(resident)
		return
	resident.route = route
	resident.index = 0
	resident.paused = false

func _route_from_position(point: Vector3, finish: String) -> Array[Vector3]:
	var planar := Vector2(point.x,point.z)
	var nearest := Vector2.ZERO
	var best_distance := INF
	var edge: Array[String] = []
	for start: String in graph:
		for end: String in graph[start]:
			var a: Vector3 = positions[start]
			var b: Vector3 = positions[end]
			var projected := Geometry2D.get_closest_point_to_segment(planar,Vector2(a.x,a.z),Vector2(b.x,b.z))
			var distance := planar.distance_squared_to(projected)
			if distance < best_distance:
				best_distance = distance
				nearest = projected
				edge.assign([start,end])
	var best: Array[Vector3] = []
	var best_length := INF
	if best_distance > 0.81: return best
	var projected := Vector3(nearest.x,state.street_height(nearest)+0.10,nearest.y)
	for endpoint: String in edge:
		var candidate := _route(endpoint,finish)
		if candidate.is_empty(): continue
		var length := projected.distance_to(candidate[0])
		for i in range(1,candidate.size()): length += candidate[i-1].distance_to(candidate[i])
		if length < best_length:
			best_length = length
			best = candidate
	if not best.is_empty(): best.push_front(projected)
	return best

func _arrive(resident: Dictionary) -> void:
	var reached := str(resident.destination_id)
	if not connected_houses.has(reached):
		_pause_at_home(resident)
		return
	var target: Vector3 = positions[connected_houses[reached]]+Vector3(0,0.10,0)
	if resident.node.position.distance_to(target) > 0.15:
		_pause_at_home(resident)
		return
	var role := str(_roles[reached])
	resident.dwell_id = reached
	resident.service_pending = role
	resident.wait = 5.0 if role == "venue" else 3.0

func _depart(resident: Dictionary, reached: String) -> void:
	var stops: Array[String] = resident.stops
	var next := (stops.find(reached)+1) % stops.size()
	resident.destination_id = stops[next]
	resident.stop = next
	resident.route = _route(connected_houses[reached],connected_houses[stops[next]])
	resident.index = 0
	if resident.route.is_empty(): _pause_at_home(resident)

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
			positions[ka] = Vector3(a.x,state.street_height(a),a.y)
			positions[kb] = Vector3(b.x,state.street_height(b),b.y)
			if not graph.has(ka): graph[ka] = {}
			if not graph.has(kb): graph[kb] = {}
			graph[ka][kb] = a.distance_to(b)
			graph[kb][ka] = a.distance_to(b)

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
