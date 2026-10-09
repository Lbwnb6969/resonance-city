class_name CityTraveler
extends RefCounted
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
var leg_index := 0
var initialized := false
var trip := 0
var walk_target := Vector2.ZERO

func _init(agent_kind: String = "walker", index: int = 0) -> void:
	kind = agent_kind
	ordinal = index

func advance(city: ContinuousWorld, seconds: float) -> Dictionary:
	if _is_vehicle() and _line(city).is_empty(): return {}
	if kind == "walker" and city.buildings.is_empty(): return {}
	if not initialized:
		if _is_vehicle():
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
		last_seconds = seconds
	var elapsed := maxf(0.0,seconds-last_seconds)
	last_seconds = seconds
	var speed := _speed(city) if _is_vehicle() else 0.48
	while elapsed > 0.000001:
		if wait > 0.0:
			var pause := minf(elapsed,wait)
			wait -= pause
			elapsed -= pause
			continue
		var travel := minf(elapsed,maxf(0.0,total-distance)/speed)
		distance += travel*speed
		elapsed -= travel
		_sample()
		if distance >= total-0.00001:
			if _is_vehicle(): _next_bus(city)
			else: _next_walk(city)
			if total < 0.00001: break
	return {"position":position,"direction":direction,"stopped":wait > 0.0,"destination":destination}

func _is_vehicle() -> bool:
	return kind in ["carriage","tram","bus"]

func _speed(city: ContinuousWorld) -> float:
	var city_cfg: Dictionary = city.cfg["city"]
	if kind == "carriage": return float(city_cfg.get("carriage_speed",0.95))
	if kind == "tram": return float(city_cfg.get("tram_speed",2.2))
	return float(city_cfg.get("bus_speed",1.8))

func _vehicle_lane() -> float:
	if kind == "carriage": return 0.14
	if kind == "tram": return 0.08
	return 0.10

func _line(city: ContinuousWorld) -> Dictionary:
	var id := "valley-line" if ordinal < 2 else "garden-line"
	for line in city.transit_lines:
		if line["id"] == id: return line
	return {}

func _next_bus(city: ContinuousWorld) -> void:
	var line := _line(city)
	var legs: Array = line["legs"]
	var next_key := str(line["name"])
	if line_key != next_key:
		# Reroute only at the next completed stop; reconnect physically if it left the new line.
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
	destination = leg["to"]
	leg_index = (leg_index+1)%legs.size()
	_set_path(leg["path"],_vehicle_lane())
	wait = float(city.cfg["city"]["bus_dwell_beats"])*60.0/float(city.cfg["timing"]["bpm"])

func _walk_destinations(city: ContinuousWorld) -> Array[Vector2]:
	var destinations: Array[Vector2] = []
	for lot in city.lots:
		if lot["occupant"] != "":
			destinations.append(Vector2(lot["entrance"][0],lot["entrance"][1]))
	for site in city.public_sites:
		if site["active"]:
			destinations.append(Vector2(site["entrance"][0],site["entrance"][1]))
	return destinations

func _next_walk(city: ContinuousWorld) -> void:
	var destinations := _walk_destinations(city)
	trip += 1
	for offset in range(destinations.size()):
		var candidate: Vector2 = destinations[(ordinal*3+trip*7+offset)%destinations.size()]
		if candidate.distance_to(walk_target) < 0.4: continue
		var journey: Dictionary = city.network.walking_route(walk_target,candidate)
		if is_inf(float(journey["distance"])): continue
		walk_target = candidate
		destination = "entrance"
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
		var normal := Vector2(-(previous.y+following.y),previous.x+following.x).normalized()
		var correction := lane/maxf(0.7,normal.dot(Vector2(-following.y,following.x)))
		var amount := correction
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
		"destination","line_key","leg_index","initialized","trip","walk_target"]: saved[field] = get(field)
	return saved.duplicate(true)

func restore(saved: Dictionary) -> void:
	for field in saved: set(field,saved[field])

func _sample() -> void:
	var remaining := distance
	for i in range(lengths.size()):
		if remaining <= lengths[i] or i == lengths.size()-1:
			position = path[i].lerp(path[i+1],clampf(remaining/maxf(lengths[i],0.00001),0.0,1.0))
			if lengths[i] > 0.00001: direction = (path[i+1]-path[i]).normalized()
			return
		remaining -= lengths[i]
