class_name ValleyScenery
extends RefCounted
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicGeometry = preload("res://scripts/visual/public_space_visual_geometry.gd")
## Props share the building depth sort and the same audio frame as the river and city.
var props: Dictionary = {}
var sites: Dictionary = {}
var vehicle_kind := ""
var site_key: Array = []
var public_prop_layouts: Dictionary = {}
var public_prop_keys: Dictionary = {}
var prop_projections: Dictionary = {}

func rebuild(demo: Control) -> void:
	for node in props.values(): node.queue_free()
	props.clear()
	public_prop_layouts.clear()
	public_prop_keys.clear()
	prop_projections.clear()
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
			if SpatialPlanning.point_in_footprint(site,p): clear = false
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
			var shared := false
			for transfer in line.get("transfer_stops",[]):
				if str(transfer.get("stop_id","")) == str(stop_id):
					shared = true
					break
			if shared: props[stop_key].set_meta("transfer_stop",true)
			stop_tone += 1
	_sync_public_props(demo,city)
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

func _sync_public_props(demo: Control,city: ContinuousWorld) -> void:
	for site in city.public_sites:
		var id := str(site["id"])
		var layout := [site["position"],PublicGeometry.identity(site),site["kind"],bool(site.get("player_planned",false))]
		if public_prop_layouts.get(id,[]) == layout: continue
		for key in public_prop_keys.get(id,[]):
			if props.has(key):
				props[key].queue_free()
				props.erase(key)
				prop_projections.erase(key)
		public_prop_layouts[id] = layout.duplicate()
		var keys: Array[String] = []
		var holes := SpatialPlanning.footprint_holes(site)
		var component_index := 0
		for component in PublicGeometry.components(site):
			var p: Vector2 = component["position"]
			var polygon: PackedVector2Array = component["outer"]
			var component_id := id if component_index == 0 else "%s-part-%d" % [id,component_index]
			if site["kind"] == "civic":
				_add(demo,component_id,p,"civic",component_index,id)
				# The civic base fits inside a radius of 0.7 world units.
				props[component_id].set_meta("public_scale",minf(1.0,float(component["clearance"])/0.7))
				keys.append(component_id)
			else:
				var box := _polygon_bounds(polygon)
				var before := keys.size()
				for i in range(8):
					var candidate := p+Vector2(-1.1+(i%2)*2.2,-1.4+(i/2)*0.9)
					if bool(site.get("player_planned",false)) or box.size.x < 2.4 or box.size.y < 3.2:
						candidate = box.get_center()+Vector2((-0.35 if i%2 == 0 else 0.35)*box.size.x,(-0.33+(i/2)*0.22)*box.size.y)
					var available := PublicGeometry.clearance(polygon,holes,candidate)
					if available <= 0.00001: continue
					var key := "%s-tree-%d" % [component_id,i]
					_add(demo,key,candidate,"tree",i+component_index*8,id)
					props[key].set_meta("public_scale",minf(1.0,available/0.5))
					keys.append(key)
				if keys.size() == before:
					var key := component_id+"-tree-0"
					_add(demo,key,p,"tree",component_index*8,id)
					props[key].set_meta("public_scale",minf(1.0,float(component["clearance"])/0.5))
					keys.append(key)
			component_index += 1
		public_prop_keys[id] = keys

func _polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var box := Rect2(polygon[0],Vector2.ZERO)
	for p in polygon: box = box.expand(p)
	return box

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

func _index_traffic(traffic: Array,accesses: Dictionary) -> void:
	# One frame, no persistent position cache. Same-road following has no radius
	# limit; different roads can only conflict within two 0.9-unit node reaches.
	var by_road: Dictionary = {}
	var cells: Dictionary = {}
	for i in range(traffic.size()):
		var agent: Dictionary = traffic[i]
		var road: String = agent["road"]
		var p: Vector2 = agent["position"]
		var cell := Vector2i(floori(p.x/2.0),floori(p.y/2.0))
		if not by_road.has(road): by_road[road] = []
		if not cells.has(cell): cells[cell] = []
		by_road[road].append(i)
		cells[cell].append(i)
	for physical in accesses.values():
		var road := str(physical["access"].get("road",""))
		var p: Vector2 = physical["position"]
		var cell := Vector2i(floori(p.x/2.0),floori(p.y/2.0))
		var selected: Dictionary = {}
		for i in by_road.get(road,[]): selected[i] = true
		for dy in range(-1,2):
			for dx in range(-1,2):
				for i in cells.get(cell+Vector2i(dx,dy),[]):
					if p.distance_squared_to(traffic[i]["position"]) <= 1.800001*1.800001: selected[i] = true
		var indices: Array = selected.keys()
		indices.sort()
		var nearby: Array = []
		for i in indices: nearby.append(traffic[i])
		physical["traffic"] = nearby

func sync(demo: Control) -> void:
	var city: ContinuousWorld = demo.shown_world
	_sync_vehicle_kind(city)
	var next_site_key := [city,city.phrase_index]
	if site_key != next_site_key:
		site_key = next_site_key
		sites.clear()
		for site in city.public_sites: sites[site["id"]] = site
		_sync_public_props(demo,city)
	var frame: float = demo.clock.renderer.transport.audible_frame
	var rate: int = demo.clock.renderer.transport.sample_rate
	var seconds := frame/rate
	var terrain_key := [city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family]
	# Share the previous frame's physical positions so travelers yield at the same road point.
	# Priority is deterministic, keeping opposing traffic from deadlocking at a bend.
	var traffic: Array = []
	var accesses: Dictionary = {}
	for traffic_key in props:
		var traffic_prop: ValleyProp = props[traffic_key]
		if not traffic_prop.has_meta("traveler"): continue
		if bool(traffic_prop.get_meta("modern_only",false)) and city.vehicle_kind() != "bus": continue
		var traffic_traveler: CityTraveler = traffic_prop.get_meta("traveler")
		if not traffic_traveler.initialized: continue
		var traffic_access: Dictionary = city.network.access(traffic_traveler.position,false)
		accesses[traffic_key] = {"position":traffic_traveler.position,"topology_token":city.network.access_token,"access":traffic_access}
		traffic.append({"kind":traffic_traveler.kind,"ordinal":traffic_traveler.ordinal,
			"position":traffic_traveler.position,"direction":traffic_traveler.direction,
			"road":str(traffic_access.get("road","")),"road_from":str(traffic_access.get("from","")),
			"road_to":str(traffic_access.get("to","")),"road_along":float(traffic_access.get("along",0.0)),
			"road_length":float(traffic_access.get("length",0.0)),"priority":traffic_traveler._priority()})
	_index_traffic(traffic,accesses)
	for key in props:
		var prop: ValleyProp = props[key]
		var p: Vector2 = prop.get_meta("world_position")
		var site_id := str(prop.get_meta("site"))
		prop.visible = true
		if bool(prop.get_meta("modern_only",false)) and city.vehicle_kind() != "bus":
			prop.visible = false
			continue
		if not site_id.is_empty():
			var site: Dictionary = sites[site_id]
			prop.visible = site["active"]
			prop.reveal = clampf((frame-int(site["frame"]))/(0.5*rate),0.0,1.0)
		if prop.kind in ["bus","carriage","tram","car","walker"]:
			var traveler: CityTraveler = prop.get_meta("traveler")
			var flow_start := city.transit_flow_pending.size()
			var movement := traveler.advance(city,seconds,traffic,accesses.get(key,{}))
			if city != demo.model.world:
				# Routes follow the still-audible city; new observations belong to the live world.
				for observation in city.transit_flow_pending.slice(flow_start):
					demo.model.world.transit_flow_pending.append(observation.duplicate())
				city.transit_flow_pending.resize(flow_start)
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
				prop.set_meta("boarded",movement.get("boarded",0))
				prop.set_meta("alighted",movement.get("alighted",0))
				prop.set_meta("transfer_passengers",movement.get("transfer_passengers",0))
				prop.set_meta("passenger_destinations",movement.get("passenger_destinations",[]))
				prop.set_meta("world_position",p)
		if prop.has_meta("traveler"):
			prop.position = WorldProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(p))
		else:
			var projection_key := [terrain_key,p]
			if not prop_projections.has(key) or prop_projections[key]["key"] != projection_key:
				prop_projections[key] = {"key":projection_key,"position":WorldProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(p))}
			prop.position = prop_projections[key]["position"]
		prop.scale = Vector2.ONE*float(prop.get_meta("public_scale",1.0))
		# Building warmth is shared at the layer; scenery retains its original tint.
		prop.modulate = Color(1.0/demo.buildings_layer.modulate.r,1.0,1.0,prop.reveal)
		prop.motion = seconds*TAU/4.0
		# Station signs, lamps, rocks and civic geometry keep their draw commands.
		# Reveal alpha remains a CanvasItem property; trees/travelers keep animating.
		if prop.kind in ["tree","bus","carriage","tram","car","walker"]: prop.queue_redraw()
