class_name ValleyScenery
extends RefCounted
## Props share the building depth sort and the same audio frame as the river and city.
var props: Dictionary = {}
var sites: Dictionary = {}
var vehicle_kind := ""

func rebuild(demo: Control) -> void:
	for node in props.values(): node.queue_free()
	props.clear()
	for site in demo.shown_world.public_sites:
		sites[site["id"]] = site
	var city: ContinuousWorld = demo.shown_world
	# Deterministic natural groves, independent of the city's growth RNG.
	for i in range(110):
		var x := 1.2+float((i*47+13)%301)/10.0
		var y := -1.4+float((i*73+29)%327)/10.0
		var p := Vector2(x,y)
		if not city.terrain.land_at(p): continue
		var clear := true
		for lot in city.lots:
			if p.distance_to(Vector2(lot["center"][0],lot["center"][1])) < 1.25: clear = false
		for site in city.public_sites:
			if Geometry2D.is_point_in_polygon(p,site["polygon"]): clear = false
		var access := city.network.access(p)
		if not access.is_empty() and float(access["gap"]) < 0.6: clear = false
		if clear: _add(demo,"grove-%d" % i,p,"rock" if i%13 == 0 else "tree",i)
	for road in city.roads:
		if road["bridge"]: continue
		var path: PackedVector2Array = road["path"]
		if road.get("kind","") == "branch": continue
		var p := path[path.size()/2]+Vector2(0.38,0)
		if city.terrain.land_at(p): _add(demo,"lamp-"+road["id"],p,"lamp",0)
	# Transit stops are drawn from the same route nodes used by travelers.
	# Shared stops get one marker so a transfer point reads as one place.
	var stop_tone := 0
	for line in city.transit_lines:
		for stop_id in line.get("stops",[]):
			var stop_key := "stop-"+str(stop_id)
			if props.has(stop_key) or not city.network.nodes.has(stop_id): continue
			var stop_node: Array = city.network.nodes[stop_id]
			_add(demo,stop_key,Vector2(float(stop_node[0]),float(stop_node[1])),"stop",stop_tone)
			stop_tone += 1
	for site in city.public_sites:
		var p := Vector2(site["position"][0],site["position"][1])
		if site["kind"] == "civic": _add(demo,site["id"],p,"civic",0,site["id"])
		else:
			for i in range(8):
				var offset := Vector2(-1.1+(i%2)*2.2,-1.4+(i/2)*0.9)
				_add(demo,"%s-tree-%d" % [site["id"],i],p+offset,"tree",i,site["id"])
	vehicle_kind = city.vehicle_kind()
	for i in range(4): _add(demo,"vehicle-%d" % i,Vector2.ZERO,vehicle_kind,i)
	# Private cars only enter the street mix in the modern era; they remain
	# authored travelers so the era transition does not create a visual burst.
	for i in range(3): _add(demo,"car-%d" % i,Vector2.ZERO,"car",i+4,"",true)
	for i in range(10): _add(demo,"walker-%d" % i,Vector2.ZERO,"walker",i)

func _add(demo: Control,key: String,p: Vector2,kind: String,tone: int,site: String = "",modern_only: bool = false) -> void:
	var prop := ValleyProp.new()
	prop.kind = kind
	prop.tone = tone
	prop.set_meta("world_position",p)
	prop.set_meta("site",site)
	prop.set_meta("modern_only",modern_only)
	if kind in ["bus","carriage","tram","car","walker"]: prop.set_meta("traveler",CityTraveler.new(kind,tone))
	demo.buildings_layer.add_child(prop)
	props[key] = prop

func snapshot() -> Dictionary:
	var saved: Dictionary = {}
	for key in props:
		if props[key].has_meta("traveler"): saved[key] = props[key].get_meta("traveler").snapshot()
	return saved

func restore(saved: Dictionary) -> void:
	for key in saved:
		if props.has(key) and props[key].has_meta("traveler"): props[key].get_meta("traveler").restore(saved[key])

func _sync_vehicle_kind(city: ContinuousWorld) -> void:
	var desired := city.vehicle_kind()
	if desired == vehicle_kind: return
	vehicle_kind = desired
	for i in range(4):
		var key := "vehicle-%d" % i
		if not props.has(key): continue
		var prop: ValleyProp = props[key]
		prop.kind = desired
		if prop.has_meta("traveler"):
			var traveler: CityTraveler = prop.get_meta("traveler")
			traveler.kind = desired
			traveler.line_key = ""

func sync(demo: Control) -> void:
	var city: ContinuousWorld = demo.shown_world
	_sync_vehicle_kind(city)
	var frame: float = demo.clock.renderer.transport.audible_frame
	var rate: int = demo.clock.renderer.transport.sample_rate
	var seconds := frame/rate
	# Share the previous frame's physical positions so travelers yield at the same road point.
	# Priority is deterministic, keeping opposing traffic from deadlocking at a bend.
	var traffic: Array = []
	for traffic_key in props:
		var traffic_prop: ValleyProp = props[traffic_key]
		if not traffic_prop.has_meta("traveler"): continue
		if bool(traffic_prop.get_meta("modern_only",false)) and city.vehicle_kind() != "bus": continue
		var traffic_traveler: CityTraveler = traffic_prop.get_meta("traveler")
		if not traffic_traveler.initialized: continue
		var traffic_access: Dictionary = city.network.access(traffic_traveler.position)
		traffic.append({"kind":traffic_traveler.kind,"ordinal":traffic_traveler.ordinal,
			"position":traffic_traveler.position,"direction":traffic_traveler.direction,
			"road":str(traffic_access.get("road","")),"priority":traffic_traveler._priority()})
	for key in props:
		var prop: ValleyProp = props[key]
		var p: Vector2 = prop.get_meta("world_position")
		var site_id := str(prop.get_meta("site"))
		prop.visible = true
		if bool(prop.get_meta("modern_only",false)) and city.vehicle_kind() != "bus":
			prop.visible = false
			continue
		if not site_id.is_empty():
			var site: Dictionary = city.public_sites.filter(func(s: Dictionary) -> bool: return s["id"] == site_id)[0]
			prop.visible = site["active"]
			prop.reveal = clampf((frame-int(site["frame"]))/(0.5*rate),0.0,1.0)
		if prop.kind in ["bus","carriage","tram","car","walker"]:
			var traveler: CityTraveler = prop.get_meta("traveler")
			var movement := traveler.advance(city,seconds,traffic)
			prop.visible = not movement.is_empty()
			if prop.visible:
				p = movement["position"]
				prop.direction = movement["direction"]
				prop.active = not movement["stopped"]
				prop.stop_id = str(movement.get("stop_id",""))
				prop.passengers = int(movement.get("passengers",0))
				prop.set_meta("stop_id",prop.stop_id)
				prop.set_meta("passengers",prop.passengers)
				prop.set_meta("purpose",movement.get("purpose",""))
				prop.set_meta("destination_kind",movement.get("destination_kind",""))
				prop.set_meta("world_position",p)
		prop.position = demo.point(p)
		prop.scale = Vector2.ONE*demo.view_zoom
		prop.motion = seconds*TAU/4.0
		prop.queue_redraw()
