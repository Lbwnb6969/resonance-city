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
var concert_callback: Callable
const CONCERT_DURATION := 24.0
var _concert: Dictionary = {}

var _network_signature: Array = []
var _roles: Dictionary = {}

func setup(city: RefCounted) -> void:
	var fresh := state != city
	if state != city:
		for resident: Dictionary in residents: resident.node.queue_free()
		residents.clear()
		_network_signature.clear()
		last_revision = -1
		_concert.clear()
	state = city
	_read_progress()
	_sync()
	if fresh:
		var saved: Variant = state.get("journey_checkpoint")
		if saved is Dictionary: restore_checkpoint(saved)

func _read_progress() -> void:
	purchases = int(state.life_progress.purchases)
	gatherings = int(state.life_progress.gatherings)

func _process(delta: float) -> void:
	if state == null: return
	if state.revision != last_revision: _sync()
	time += delta
	var already_playing := str(_concert.get("phase", "idle")) == "playing"
	for resident: Dictionary in residents:
		if resident.paused: continue
		if resident.has("daily_snapshot") and str(resident.dwell_id) == str(_concert.get("venue_id", "")):
			continue
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
	if already_playing and str(_concert.get("phase", "idle")) == "playing":
		_concert.elapsed = minf(CONCERT_DURATION, float(_concert.elapsed) + delta)
		if float(_concert.elapsed) >= CONCERT_DURATION: _end_concert(true)
	elif str(_concert.get("phase", "idle")) == "gathering":
		if int(concert_status().arrived) == int(concert_status().invited):
			_concert.phase = "playing"
			if concert_callback.is_valid(): concert_callback.call("started", str(_concert.venue_id))

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
	var concert_invalid := false
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
			if resident.has("daily_snapshot"):
				if not _resume_concert_participant(resident): concert_invalid = true
			elif stops.size() < 2:
				_pause_at_home(resident)
			else:
				_resume(resident)
		next_residents.append(resident)
	for resident: Dictionary in old_by_home.values():
		if resident.has("daily_snapshot"): concert_invalid = true
		resident.node.queue_free()
	residents = next_residents
	if not _concert.is_empty() and (concert_invalid or str(_roles.get(str(_concert.venue_id), "")) != "venue"):
		_end_concert(false)

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
	var best: Array[Vector3] = []
	if not graph.has(finish): return best
	# Find the destination's connected component once, then choose a local
	# attachment. Disconnected segments never trigger repeated path searches.
	var reachable := {finish:true}
	var queue: Array[String] = [finish]
	var cursor := 0
	while cursor < queue.size():
		var current: String = queue[cursor]
		cursor += 1
		for neighbor: String in graph[current]:
			if reachable.has(neighbor): continue
			reachable[neighbor] = true
			queue.append(neighbor)
	var best_distance := INF
	var best_length := INF
	var attachments: Array[Dictionary] = []
	for start: String in graph:
		if not reachable.has(start): continue
		for end: String in graph[start]:
			if start > end: continue
			var a: Vector3 = positions[start]
			var b: Vector3 = positions[end]
			var projected := Geometry2D.get_closest_point_to_segment(planar,Vector2(a.x,a.z),Vector2(b.x,b.z))
			var distance := planar.distance_squared_to(projected)
			if distance > 0.81 or distance > best_distance + 0.000001: continue
			if distance < best_distance - 0.000001: attachments.clear()
			best_distance = distance
			attachments.append({"start":start,"end":end,"point":projected})
	for attachment: Dictionary in attachments:
		var projected: Vector2 = attachment.point
		var projection := Vector3(projected.x,state.street_height(projected)+0.10,projected.y)
		for endpoint: String in [str(attachment.start),str(attachment.end)]:
			var candidate := _route(endpoint,finish)
			var length := projection.distance_to(candidate[0])
			for i in range(1,candidate.size()): length += candidate[i-1].distance_to(candidate[i])
			if length < best_length:
				best_length = length
				best = candidate
				best.push_front(projection)
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
	if resident.has("daily_snapshot"):
		resident.service_pending = "concert"
		resident.wait = 0.0
		_concert_formation(resident)
		return
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

func invite_concert(venue_id: String) -> Dictionary:
	if state.revision != last_revision: _sync()
	if not _concert.is_empty(): return {"ok":false,"message":"街坊正在赴约，这场结束后再邀请。"}
	if str(_roles.get(venue_id, "")) != "venue" or not connected_houses.has(venue_id):
		return {"ok":false,"message":"先为音乐屋接上一条能走到的路。"}
	var candidates: Array[Dictionary] = []
	var routes: Array = []
	for resident: Dictionary in residents:
		if resident.paused: continue
		var route := _route_from_position(resident.node.position, str(connected_houses[venue_id]))
		if route.is_empty(): continue
		candidates.append(resident)
		routes.append(route)
	if candidates.is_empty(): return {"ok":false,"message":"这座音乐屋还没有街坊能步行抵达。"}
	var participants: Array[String] = []
	for index in range(candidates.size()):
		var resident: Dictionary = candidates[index]
		resident.daily_snapshot = _resident_checkpoint(resident)
		resident.destination_id = venue_id
		resident.dwell_id = ""
		resident.service_pending = ""
		resident.wait = 0.0
		resident.route = routes[index]
		resident.index = 0
		participants.append(str(resident.home_id))
	_concert = {"phase":"gathering","venue_id":venue_id,"participants":participants,"elapsed":0.0,"duration":CONCERT_DURATION}
	return {"ok":true,"message":"已邀请 %d 位街坊沿路来听演出。" % participants.size()}

func concert_status() -> Dictionary:
	if _concert.is_empty(): return {"phase":"idle","venue_id":"","invited":0,"arrived":0,"elapsed":0.0,"duration":CONCERT_DURATION}
	var arrived := 0
	for resident: Dictionary in residents:
		if _concert.participants.has(str(resident.home_id)) and str(resident.dwell_id) == str(_concert.venue_id): arrived += 1
	return {"phase":str(_concert.phase),"venue_id":str(_concert.venue_id),"invited":_concert.participants.size(),"arrived":arrived,"elapsed":float(_concert.elapsed),"duration":CONCERT_DURATION}

func cancel_concert() -> Dictionary:
	if _concert.is_empty(): return {"ok":false,"message":"当前没有街坊演出。"}
	_end_concert(false)
	return {"ok":true,"message":"演出已结束，街坊继续自己的日常。"}

func _resume_concert_participant(resident: Dictionary) -> bool:
	var venue := str(_concert.get("venue_id", ""))
	if str(_roles.get(venue, "")) != "venue" or not connected_houses.has(venue) or not connected_houses.has(resident.home_id): return false
	# A participant's home and the venue must still belong to one network.
	if _route(str(connected_houses[resident.home_id]), str(connected_houses[venue])).is_empty(): return false
	var target: Vector3 = positions[connected_houses[venue]] + Vector3(0,0.10,0)
	if str(resident.dwell_id) == venue:
		return resident.node.position.distance_to(target) < 0.15
	var route := _route_from_position(resident.node.position, str(connected_houses[venue]))
	if route.is_empty(): return false
	resident.route = route
	resident.index = 0
	return true

func _end_concert(completed: bool) -> void:
	if _concert.is_empty(): return
	var venue := str(_concert.venue_id)
	_concert.clear()
	if completed: state.record_life_event("concerts")
	for resident: Dictionary in residents:
		if not resident.has("daily_snapshot"): continue
		var daily: Dictionary = resident.daily_snapshot
		resident.erase("daily_snapshot")
		var body: Node3D = resident.node.get_child(0)
		body.position = Vector3.ZERO
		var original_stops := _saved_stops(str(resident.home_id), daily.get("stops", null))
		if original_stops.size() > 1: resident.stops = original_stops
		resident.destination_id = str(daily.get("destination_id", resident.home_id))
		resident.dwell_id = ""
		resident.service_pending = ""
		resident.wait = 0.0
		resident.paused = false
		if resident.stops.size() < 2: _pause_at_home(resident)
		else: _resume(resident)
	if concert_callback.is_valid(): concert_callback.call("finished" if completed else "cancelled", venue)

func _concert_formation(resident: Dictionary) -> void:
	var index: int = _concert.get("participants", []).find(str(resident.home_id))
	if index < 0: return
	var body: Node3D = resident.node.get_child(0)
	# Visual offsets leave the logical arrival on the real venue entrance.
	body.position.x = float(index % 3 - 1) * 0.24
	body.position.z = floorf(float(index) / 3.0) * 0.24

func _resident_checkpoint(resident: Dictionary) -> Dictionary:
	var node: Node3D = resident.node
	var result := {"home_id":str(resident.home_id),"position":[node.position.x,node.position.z],"yaw":node.rotation.y,"destination_id":str(resident.destination_id),"dwell_id":str(resident.dwell_id),"service_pending":str(resident.service_pending),"wait":float(resident.wait),"paused":bool(resident.paused),"phase":float(resident.phase),"stops":resident.stops.duplicate()}
	if resident.has("daily_snapshot"): result.daily_snapshot = resident.daily_snapshot.duplicate(true)
	return result

func checkpoint() -> Dictionary:
	var people: Array[Dictionary] = []
	for resident: Dictionary in residents: people.append(_resident_checkpoint(resident))
	return {"schema":1,"residents":people,"concert":_concert.duplicate(true)}

func restore_checkpoint(data: Dictionary) -> void:
	if int(data.get("schema", 0)) != 1 or not data.get("residents", null) is Array: return
	var saved_concert: Dictionary = data.get("concert", {}) if data.get("concert", {}) is Dictionary else {}
	var phase := str(saved_concert.get("phase", "idle"))
	var venue := str(saved_concert.get("venue_id", ""))
	var elapsed_value: Variant = saved_concert.get("elapsed", -1.0)
	var saved_elapsed := float(elapsed_value) if elapsed_value is float or elapsed_value is int else -1.0
	var eligible_concert: bool = phase in ["gathering", "playing"] and str(_roles.get(venue, "")) == "venue" and connected_houses.has(venue) and is_finite(saved_elapsed) and saved_elapsed >= 0.0 and saved_elapsed < CONCERT_DURATION and saved_concert.get("participants", null) is Array and not saved_concert.get("participants", []).is_empty()
	var restored: Dictionary = {}
	for entry: Variant in data.residents:
		if not entry is Dictionary: continue
		var home := str(entry.get("home_id", ""))
		if restored.has(home): continue
		if bool(entry.get("paused", false)) and _restore_paused_home(home, entry):
			restored[home] = true
			continue
		for resident: Dictionary in residents:
			if str(resident.home_id) != home: continue
			var visiting_concert: bool = eligible_concert and saved_concert.participants.has(home) and str(entry.get("destination_id", "")) == venue and entry.get("daily_snapshot", null) is Dictionary
			var semantic: Dictionary = entry
			if not visiting_concert and entry.get("daily_snapshot", null) is Dictionary:
				# A stale invitation may not masquerade as an ordinary venue visit.
				semantic = entry.daily_snapshot.duplicate(true)
				semantic.position = entry.get("position", [])
				semantic.yaw = entry.get("yaw", 0.0)
				semantic.dwell_id = ""
				semantic.service_pending = ""
				semantic.wait = 0.0
			if not _restore_resident(resident, semantic, visiting_concert): continue
			if visiting_concert: resident.daily_snapshot = entry.daily_snapshot.duplicate(true)
			restored[home] = true
	if eligible_concert:
		_concert = saved_concert.duplicate(true)
		_concert.duration = CONCERT_DURATION
		var unique: Dictionary = {}
		var valid := true
		for home: Variant in _concert.participants:
			if not home is String or unique.has(home) or not restored.has(home):
				valid = false
				continue
			unique[home] = true
			for resident: Dictionary in residents:
				if str(resident.home_id) == str(home):
					if not resident.has("daily_snapshot") or not _resume_concert_participant(resident): valid = false
					elif str(resident.dwell_id) == venue: _concert_formation(resident)
		if phase == "playing" and int(concert_status().arrived) != int(concert_status().invited): valid = false
		if not valid: _end_concert(false)

func _restore_paused_home(home: String, saved: Dictionary) -> bool:
	if str(_roles.get(home, "")) != "residential" or str(saved.get("destination_id", "")) != home or not str(saved.get("dwell_id", "")).is_empty() or not str(saved.get("service_pending", "")).is_empty() or saved.has("daily_snapshot"): return false
	if connected_houses.has(home):
		for destination: String in _roles:
			if _roles[destination] in ["bakery", "venue"] and connected_houses.has(destination) and not _route(str(connected_houses[home]), str(connected_houses[destination])).is_empty(): return false
	var resident: Dictionary = {}
	for candidate: Dictionary in residents:
		if str(candidate.home_id) == home: resident = candidate
	if resident.is_empty():
		var node := _person(residents.size())
		add_child(node)
		var route: Array[Vector3] = []
		var stops: Array[String] = [home]
		resident = {"node":node,"home_id":home,"destination_id":home,"stops":stops,"stop":0,"index":0,"route":route,"wait":0.0,"phase":residents.size()*1.7,"paused":true,"dwell_id":"","service_pending":""}
		residents.append(resident)
	_pause_at_home(resident)
	return true

func _restore_resident(resident: Dictionary, saved: Dictionary, concert: bool) -> bool:
	var values: Variant = saved.get("position", null)
	if not values is Array or values.size() != 2 or not (values[0] is float or values[0] is int) or not (values[1] is float or values[1] is int): return false
	for key: String in ["yaw", "wait", "phase"]:
		if not saved.get(key, 0.0) is float and not saved.get(key, 0.0) is int: return false
	var planar := Vector2(float(values[0]), float(values[1]))
	var yaw := float(saved.get("yaw", 0.0))
	var wait := float(saved.get("wait", 0.0))
	var phase := float(saved.get("phase", 0.0))
	if not is_finite(planar.x) or not is_finite(planar.y) or not is_finite(yaw) or not is_finite(wait) or not is_finite(phase) or wait < 0.0: return false
	var destination := str(saved.get("destination_id", ""))
	var stops := _saved_stops(str(resident.home_id), saved.get("stops", null))
	if stops.is_empty(): stops.assign(resident.stops)
	if not concert and not stops.has(destination): return false
	if not connected_houses.has(destination): return false
	var point := Vector3(planar.x,state.street_height(planar)+0.10,planar.y)
	var route := _route_from_position(point, str(connected_houses[destination]))
	if route.is_empty(): return false
	var dwell := str(saved.get("dwell_id", ""))
	var service := str(saved.get("service_pending", ""))
	if not dwell.is_empty():
		var target: Vector3 = positions[connected_houses[destination]]+Vector3(0,0.10,0)
		if dwell != destination or point.distance_to(target) > 0.15 or service != ("concert" if concert else str(_roles.get(destination, ""))): return false
		if wait > (0.0 if concert else 5.0 if service == "venue" else 3.0): return false
	elif not service.is_empty(): return false
	resident.node.position = point
	resident.node.rotation.y = yaw
	resident.destination_id = destination
	resident.dwell_id = dwell
	resident.service_pending = service
	resident.wait = wait
	resident.phase = phase
	resident.paused = false
	resident.route = route
	resident.index = 0
	resident.stops = stops
	resident.stop = resident.stops.find(destination)
	return true

func _saved_stops(home: String, data: Variant) -> Array[String]:
	var result: Array[String] = []
	if not data is Array or data.size() < 2 or data.size() > 3 or data[0] != home or not connected_houses.has(home): return result
	for index in range(data.size()):
		var id: Variant = data[index]
		if not id is String or result.has(id) or not connected_houses.has(id):
			result.clear()
			return result
		if index > 0 and (str(_roles.get(id, "")) not in ["bakery", "venue"] or _route(str(connected_houses[home]), str(connected_houses[id])).is_empty()):
			result.clear()
			return result
		result.append(id)
	return result

func summary() -> String:
	return "%d 位居民 · %d 趟采购 · %d 次小聚\n♫ 已完成 %d 场街坊演出" % [current_population, purchases, gatherings,int(state.life_progress.concerts)]

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
