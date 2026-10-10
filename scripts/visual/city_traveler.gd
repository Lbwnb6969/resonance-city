class_name CityTraveler
extends RefCounted
const Coupling = preload("res://scripts/world/world_coupling.gd")
## Persistent journeys: finish a leg before adopting a changed line.
var kind := "walker"
var ordinal := 0
var position := Vector2.ZERO
var direction := Vector2.RIGHT
var path := PackedVector2Array()
var lengths := PackedFloat32Array()
var distance := 0.0
var total := 0.0
var last_seconds := -1.0
var wait := 0.0
var destination := ""
var line_key := ""
var line_index := -1
var leg_index := 0
var initialized := false
var trip := 0
var walk_target := Vector2.ZERO
var stop_id := ""
var passenger_load := 0
var passenger_capacity := 12
var passengers_boarded := 0
var passengers_alighted := 0
var transfer_passengers := 0
# Physical state is kept separate from the route's cruise speed so starts,
# stops and bends read as motion instead of frame-to-frame teleportation.
var motion_speed := 0.0
# A traveler carries a small, deterministic reason for moving. This keeps the
# street layer readable without adding a simulation-heavy economy system.
var purpose := ""
var destination_kind := ""
var transfer_count := 0
var transfer_target := ""
var transfer_stop := ""

func _init(agent_kind: String = "walker", index: int = 0) -> void:
	kind = agent_kind
	ordinal = index

func advance(city: ContinuousWorld, seconds: float, traffic: Array = []) -> Dictionary:
	if kind == "car" and city.era < 5: return {}
	if kind in ["carriage","tram","bus"] and _line(city).is_empty(): return {}
	if kind == "car" and city.network.nodes.is_empty(): return {}
	if kind == "walker" and city.buildings.is_empty(): return {}
	var previous_direction := direction
	if not initialized:
		if kind == "car":
			var starts := _car_nodes(city)
			if starts.is_empty(): return {}
			destination = starts[posmod(ordinal*7,starts.size())]
			var start_point: Array = city.network.nodes[destination]
			position = Vector2(float(start_point[0]),float(start_point[1]))
			_next_car(city)
		elif _is_vehicle():
			var line := _line(city)
			leg_index = (ordinal*3)%line["legs"].size()
			var leg: Dictionary = line["legs"][leg_index]
			destination = leg["from"]
			position = leg["path"][0]
			_next_bus(city)
		else:
			var destinations := _walk_destinations(city)
			walk_target = destinations[(ordinal*3)%destinations.size()]
			position = walk_target
			_next_walk(city)
		initialized = true
	var elapsed := maxf(0.0,seconds-last_seconds) if last_seconds >= 0.0 else 0.0
	var frame_delta := elapsed
	last_seconds = seconds
	var cruise_speed := _speed(city) if _is_vehicle() else 0.48
	var target_speed := 0.0 if wait > 0.0 else cruise_speed
	motion_speed = move_toward(motion_speed,target_speed,_acceleration()*maxf(elapsed,0.016))
	while elapsed > 0.000001:
		if wait > 0.0:
			var pause := minf(elapsed,wait)
			wait -= pause
			elapsed -= pause
			continue
		var speed := maxf(motion_speed,0.05)
		var desired: float = minf(elapsed,maxf(0.0,total-distance)/speed)
		var allowed: float = _traffic_distance(city,desired,traffic)
		if desired > 0.000001 and allowed <= 0.000001:
			# Higher-priority traffic keeps moving; the follower yields for a short visible pause.
			wait = maxf(wait,minf(elapsed,0.08))
			motion_speed = move_toward(motion_speed,0.0,_acceleration()*maxf(elapsed,0.016))
			continue
		var travel := minf(desired,allowed/maxf(speed,0.00001))
		distance += travel*speed
		elapsed -= travel
		_sample(frame_delta)
		if distance >= total-0.00001:
			if kind == "car": _next_car(city)
			elif _is_vehicle(): _next_bus(city)
			else: _next_walk(city)
			if total < 0.00001: break
	if previous_direction.length_squared() > 0.00001 and direction.length_squared() > 0.00001:
		var output_angle := previous_direction.angle_to(direction)
		var output_limit := _turn_rate()*maxf(frame_delta,0.016)
		if absf(output_angle) > output_limit:
			direction = previous_direction.rotated(signf(output_angle)*output_limit).normalized()
	return {"position":position,"direction":direction,"stopped":wait > 0.0,"destination":destination,
		"stop_id":stop_id,"passengers":passenger_load,"capacity":passenger_capacity,"priority":_priority(),"purpose":purpose,"destination_kind":destination_kind,
		"transfer_count":transfer_count,"transfer_target":transfer_target,"transfer_stop":transfer_stop,
		"boarded":passengers_boarded,"alighted":passengers_alighted,"transfer_passengers":transfer_passengers}

func _is_vehicle() -> bool:
	return kind in ["carriage","tram","bus","car"]

func _priority() -> int:
	var kind_rank: int = int({"carriage":0,"tram":1,"bus":2,"car":3,"walker":4}.get(kind,5))
	return ordinal*8+int(kind_rank)

func _traffic_distance(city: ContinuousWorld,desired: float,traffic: Array) -> float:
	if desired <= 0.000001 or traffic.is_empty(): return desired
	var access: Dictionary = city.network.access(position)
	var road: String = str(access.get("road",""))
	if road.is_empty(): return desired
	for other in traffic:
		if str(other.get("kind","")) == kind and int(other.get("ordinal",-1)) == ordinal: continue
		if str(other.get("road","")) != road: continue
		var other_position: Vector2 = other.get("position",Vector2.ZERO)
		var gap: float = position.distance_to(other_position)
		var other_direction: Vector2 = other.get("direction",Vector2.RIGHT)
		var same_way: bool = direction.dot(other_direction) > 0.55
		var ahead: bool = (other_position-position).dot(direction) > -0.04
		var other_kind := str(other.get("kind",""))
		var other_is_vehicle := other_kind in ["carriage","tram","bus","car"]
		if same_way and ahead:
			var safe: float = 0.52 if (_is_vehicle() or other_is_vehicle) else 0.34
			if gap < safe+desired: return maxf(0.0,gap-safe)
		elif not same_way and gap < 0.48 and int(other.get("priority",0)) < _priority():
			return 0.0
	return desired

func _acceleration() -> float:
	if kind == "car": return 3.8
	if kind == "bus": return 2.4
	if kind == "tram": return 2.8
	if kind == "carriage": return 1.9
	return 2.2

func _turn_rate() -> float:
	if kind == "car": return 4.6
	if kind == "bus": return 3.6
	if kind == "tram": return 3.2
	if kind == "carriage": return 2.8
	return 5.2

func _speed(city: ContinuousWorld) -> float:
	var city_cfg: Dictionary = city.cfg["city"]
	if kind == "carriage": return float(city_cfg.get("carriage_speed",0.95))
	if kind == "tram": return float(city_cfg.get("tram_speed",2.2))
	if kind == "car": return float(city_cfg.get("car_speed",2.8))
	return float(city_cfg.get("bus_speed",1.8))

func _vehicle_lane() -> float:
	if kind == "carriage": return 0.14
	if kind == "tram": return 0.08
	if kind == "car": return 0.07
	# Buses stay close to the road crown on narrow terrace bends; the smaller
	# offset prevents the water-side shoulder from reading as a shortcut.
	return 0.05

func _car_nodes(city: ContinuousWorld) -> Array[String]:
	var result: Array[String] = []
	for node_id in city.network.nodes:
		if city.network.adjacency.get(node_id,[]).size() > 0: result.append(str(node_id))
	result.sort()
	return result

func _car_destinations(city: ContinuousWorld) -> Array[String]:
	var result: Array[String] = []
	for zone in city.functional_zones:
		if str(zone.get("role","")) not in ["commercial","mixed","workshop","transit","cultural","civic_green"]: continue
		for cid in zone.get("community_ids",[]):
			var center := city.center_for(str(cid))
			var node_id := str(center.get("node_id",""))
			if not node_id.is_empty() and city.network.nodes.has(node_id) and not result.has(node_id):
				result.append(node_id)
	if result.size() < 2:
		for center in city.centers:
			var node_id := str(center.get("node_id",""))
			if not node_id.is_empty() and city.network.nodes.has(node_id) and not result.has(node_id):
				result.append(node_id)
	if result.size() < 2: result = _car_nodes(city)
	return result

func _node_destination_kind(city: ContinuousWorld,node_id: String) -> String:
	var best := "road"
	var best_rank := 99
	var ranks := {"commercial":0,"mixed":1,"workshop":2,"transit":3,"cultural":4,"civic_green":5,"residential":6}
	for zone in city.functional_zones:
		var role := str(zone.get("role","center"))
		for cid in zone.get("community_ids",[]):
			var center := city.center_for(str(cid))
			if str(center.get("node_id","")) != node_id: continue
			var rank := int(ranks.get(role,8))
			if rank < best_rank:
				best = role
				best_rank = rank
	return best

func _next_car(city: ContinuousWorld) -> void:
	var nodes := _car_nodes(city)
	var anchors := _car_destinations(city)
	if nodes.size() < 2: return
	var origin := destination if nodes.has(destination) else nodes[posmod(ordinal*3,nodes.size())]
	var targets: Array[String] = anchors.duplicate()
	for node_id in nodes:
		if not targets.has(node_id): targets.append(node_id)
	# A disconnected river bank must never turn into a fake cross-city jump.
	# Probe deterministic center targets first, then the rest of the reachable road graph.
	for offset in range(targets.size()):
		var target: String = targets[posmod(ordinal+trip+offset,targets.size())]
		if target == origin: continue
		var journey := city.network.route(origin,target)
		if journey["path"].is_empty(): continue
		destination = target
		destination_kind = _node_destination_kind(city,target)
		var labels := {"commercial":"商街","mixed":"混合中心","workshop":"工坊带","transit":"换乘","cultural":"文化声场","civic_green":"公共绿地","road":"道路","residential":"居住区"}
		purpose = "前往"+str(labels.get(destination_kind,"道路"))
		stop_id = ""
		passenger_load = 0
		passenger_capacity = 4
		_set_path(journey["path"],_vehicle_lane())
		wait = 0.15+float(posmod(ordinal+trip,3))*0.05
		trip += 1
		return
	wait = 0.2

func _line(city: ContinuousWorld) -> Dictionary:
	if city.transit_lines.is_empty(): return {}
	# Assign vehicles round-robin across every active line, including expanded terrace routes.
	# Keep the chosen index stable while a line is rebuilt so a traveler reconnects at a stop.
	if line_index < 0 or line_index >= city.transit_lines.size():
		line_index = posmod(ordinal,city.transit_lines.size())
	return city.transit_lines[line_index]

func _next_bus(city: ContinuousWorld) -> void:
	var line := _line(city)
	if line.is_empty(): return
	var arrival_stop := destination
	var was_initialized := initialized
	var legs: Array = line["legs"]
	if legs.is_empty(): return
	if transfer_count > 0 and not transfer_stop.is_empty(): transfer_stop = ""
	var transfer_options: Array = []
	var did_transfer := false
	for transfer in line.get("transfer_stops",[]):
		if str(transfer.get("stop_id","")) == arrival_stop:
			transfer_options.append(transfer)
	if was_initialized and not transfer_options.is_empty() and posmod(ordinal+trip+leg_index,3) == 0:
		var choice: Dictionary = transfer_options[posmod(transfer_count+ordinal,transfer_options.size())]
		line_index = int(choice.get("line_index",line_index))
		line = _line(city)
		legs = line["legs"]
		transfer_count += 1
		transfer_target = str(line.get("name",""))
		transfer_stop = arrival_stop
		purpose = "换乘至"+transfer_target
		destination_kind = "transit_transfer"
		line_key = ""
		did_transfer = true
	else:
		purpose = "沿线接驳"
		destination_kind = "transit"
	var next_key := str(line["id"])+":"+str(line.get("edges",[]))
	if line_key != next_key:
		# Reroute only at the next completed stop; reconnect physically if it left the new line.
		# The edge signature changes when a bridge, branch, or era network rebuilds,
		# while the stable line id alone would silently keep an obsolete route.
		line_key = next_key
		var match_index := -1
		for i in range(legs.size()):
			if legs[i]["from"] == destination:
				match_index = i
				break
		if match_index < 0:
			var reconnect := city.network.route(destination,legs[0]["from"])
			destination = legs[0]["from"]
			leg_index = 0
			_set_path(reconnect["path"],_vehicle_lane())
			wait = 1.0
			return
		leg_index = match_index
	var leg: Dictionary = legs[leg_index]
	stop_id = str(leg["from"])
	destination = leg["to"]
	leg_index = (leg_index+1)%legs.size()
	_set_path(leg["path"],_vehicle_lane())
	if kind == "car":
		passenger_load = 0
		passenger_capacity = 4
		passengers_boarded = 0
		passengers_alighted = 0
		transfer_passengers = 0
		wait = 0.0
		return
	var previous_load := passenger_load
	var demand := _stop_demand(city,line,stop_id)
	var target_load := clampi(demand,1,passenger_capacity-1)
	if did_transfer:
		# A line change is a real journey boundary: some riders leave before
		# connecting passengers board the next service.
		target_load = maxi(1,mini(target_load,previous_load-1)) if previous_load > 1 else 1
	passengers_alighted = maxi(0,previous_load-target_load)
	var after_alight := previous_load-passengers_alighted
	passengers_boarded = maxi(0,target_load-after_alight)
	passenger_load = target_load
	transfer_passengers = mini(passenger_load,1+posmod(ordinal+leg_index+stop_id.length(),3)) if did_transfer else 0
	city.record_transit_flow(arrival_stop,passengers_boarded,passengers_alighted,transfer_passengers)
	var base_dwell := float(city.cfg["city"]["bus_dwell_beats"])*60.0/float(city.cfg["timing"]["bpm"])
	wait = base_dwell+float(passenger_load)*0.035+float(passengers_boarded+passengers_alighted)*0.018+(0.35 if did_transfer else 0.0)

func _stop_demand(city: ContinuousWorld,line: Dictionary,stop: String) -> int:
	var demand := 2+posmod(stop.length()*7+ordinal*3+leg_index,4)
	if not line.get("transfer_stops",[]).is_empty():
		for transfer in line.get("transfer_stops",[]):
			if str(transfer.get("stop_id","")) == stop:
				demand += 3
				break
	for center in city.centers:
		if str(center.get("node_id","")) != stop: continue
		var cid := str(center.get("community_id",center.get("node_id","")))
		for zone in city.functional_zones:
			if not zone.get("community_ids",[]).has(cid): continue
			match str(zone.get("role","")):
				"commercial","workshop","cultural","transit": demand += 2
				"civic_green": demand += 1
	# Passenger flow creates a bounded memory: busy stops keep attracting journeys
	# for later phrases, then decay with the world's musical clock.
	demand += mini(3,roundi(city.transit_demand_score(stop)/2.0))
	return clampi(demand,1,maxi(1,passenger_capacity-1))

func _walk_destinations(city: ContinuousWorld) -> Array[Vector2]:
	var destinations: Array[Vector2] = []
	for lot in city.lots:
		if lot["occupant"] != "":
			destinations.append(Vector2(lot["entrance"][0],lot["entrance"][1]))
	for building in city.buildings:
		if str(building.get("lot_id","")).is_empty():
			destinations.append(Coupling.position_of(building))
	for site in city.public_sites:
		if site["active"]:
			destinations.append(Vector2(site["entrance"][0],site["entrance"][1]))
	return destinations

func _walk_destinations_for(city: ContinuousWorld,category: String) -> Array[Vector2]:
	var destinations: Array[Vector2] = []
	if category in ["home","market"]:
		for lot in city.lots:
			if lot["occupant"] == "": continue
			var use := str(lot.get("use","residential"))
			if (category == "home" and use != "residential") or (category == "market" and use != "commercial"): continue
			destinations.append(Vector2(lot["entrance"][0],lot["entrance"][1]))
		for building in city.buildings:
			if not str(building.get("lot_id","")).is_empty(): continue
			var building_type := str(building.get("type","residential"))
			if (category == "home" and building_type == "residential") or (category == "market" and building_type == "commercial"):
				destinations.append(Coupling.position_of(building))
		return destinations
	for site in city.public_sites:
		if not bool(site.get("active",false)): continue
		var site_kind := str(site.get("kind",""))
		if (category == "garden" and site_kind != "park") or (category == "civic" and site_kind != "civic"): continue
		destinations.append(Vector2(site["entrance"][0],site["entrance"][1]))
	return destinations

func _next_walk(city: ContinuousWorld) -> void:
	var profiles := ["market","garden","civic","home"]
	var profile: String = profiles[posmod(ordinal+trip,profiles.size())]
	var destinations := _walk_destinations_for(city,profile)
	if destinations.is_empty():
		profile = "local"
		destinations = _walk_destinations(city)
	trip += 1
	for offset in range(destinations.size()):
		var candidate: Vector2 = destinations[(ordinal*3+trip*7+offset)%destinations.size()]
		if candidate.distance_to(walk_target) < 0.4: continue
		var journey: Dictionary = city.network.walking_route(walk_target,candidate)
		if is_inf(float(journey["distance"])): continue
		walk_target = candidate
		destination = "entrance"
		destination_kind = profile
		purpose = {"market":"去商街","garden":"去公园","civic":"去公共设施","home":"回家","local":"附近漫步"}.get(profile,"附近漫步")
		_set_path(journey["path"],0.22)
		wait = 0.6+float(ordinal%4)*0.2
		return

func _set_path(center: PackedVector2Array, lane: float) -> void:
	var shifted := PackedVector2Array()
	for i in range(center.size()):
		var previous := (center[i]-center[maxi(0,i-1)]).normalized()
		var following := (center[mini(center.size()-1,i+1)]-center[i]).normalized()
		if previous == Vector2.ZERO: previous = following
		if following == Vector2.ZERO: following = previous
		var tangent := (previous+following).normalized()
		if tangent == Vector2.ZERO: tangent = following
		var normal := Vector2(-tangent.y,tangent.x)
		# Keep the lane offset bounded at corners; the old projection correction
		# could amplify a sharp terrace bend and visibly leave the carriageway.
		var amount := lane
		if kind == "walker" and (i == 0 or i == center.size()-1): amount = 0.0
		shifted.append(center[i]+normal*amount)
	if initialized:
		if position.distance_to(shifted[0]) > 0.0001: shifted.insert(0,position)
	else:
		position = shifted[0]
	path.clear()
	path.append(shifted[0])
	# Small rounded corners stay inside the carriageway/sidewalk envelope.
	for i in range(1,shifted.size()-1):
		var reach := minf(lane*0.8,minf(shifted[i].distance_to(shifted[i-1]),shifted[i].distance_to(shifted[i+1]))*0.3)
		var enter := shifted[i].move_toward(shifted[i-1],reach)
		var leave := shifted[i].move_toward(shifted[i+1],reach)
		path.append(enter)
		for step in range(1,5):
			var t := float(step)/4.0
			path.append(enter.lerp(shifted[i],t).lerp(shifted[i].lerp(leave,t),t))
	path.append(shifted[-1])
	if not initialized and path.size() > 1:
		var initial_tangent := (path[1]-path[0]).normalized()
		if initial_tangent.length_squared() > 0.00001: direction = initial_tangent
	lengths.clear()
	total = 0.0
	for i in range(path.size()-1):
		var length := path[i].distance_to(path[i+1])
		lengths.append(length)
		total += length
	distance = 0.0

func snapshot() -> Dictionary:
	var saved: Dictionary = {}
	for field in ["kind","ordinal","position","direction","path","lengths","distance","total","last_seconds","wait",
		"destination","destination_kind","purpose","line_key","line_index","leg_index","initialized","trip","walk_target","stop_id","passenger_load","passenger_capacity","passengers_boarded","passengers_alighted","transfer_passengers","motion_speed","transfer_count","transfer_target","transfer_stop"]: saved[field] = get(field)
	return saved.duplicate(true)

func _saved_vector(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(float(value[0]),float(value[1]))

func _saved_path(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array: return value
	var result := PackedVector2Array()
	for point in value: result.append(_saved_vector(point))
	return result

func _saved_lengths(value: Variant) -> PackedFloat32Array:
	if value is PackedFloat32Array: return value
	var result := PackedFloat32Array()
	for number in value: result.append(float(number))
	return result

func restore(saved: Dictionary) -> void:
	for field in saved:
		match field:
			"position","direction","walk_target": set(field,_saved_vector(saved[field]))
			"path": path = _saved_path(saved[field])
			"lengths": lengths = _saved_lengths(saved[field])
			_: set(field,saved[field])

func _sample(delta_seconds: float = 0.0) -> void:
	var remaining := distance
	for i in range(lengths.size()):
		if remaining <= lengths[i] or i == lengths.size()-1:
			position = path[i].lerp(path[i+1],clampf(remaining/maxf(lengths[i],0.00001),0.0,1.0))
			if lengths[i] > 0.00001:
				var tangent := (path[i+1]-path[i]).normalized()
				var max_turn := _turn_rate()*maxf(delta_seconds,0.016)
				var angle := direction.angle_to(tangent)
				if absf(angle) > max_turn:
					direction = direction.rotated(signf(angle)*max_turn).normalized()
				else:
					direction = tangent
			return
		remaining -= lengths[i]
