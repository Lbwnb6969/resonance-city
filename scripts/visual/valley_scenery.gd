class_name ValleyScenery
extends RefCounted
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicGeometry = preload("res://scripts/visual/public_space_visual_geometry.gd")
const GroveLayout = preload("res://scripts/visual/classical_grove_layout.gd")
## Props share the building depth sort and the same audio frame as the river and city.
var props: Dictionary = {}
var sites: Dictionary = {}
var vehicle_kind := ""
var site_key: Array = []
var public_prop_layouts: Dictionary = {}
var public_prop_keys: Dictionary = {}
var prop_projections: Dictionary = {}
var transit_stop_keys: Dictionary = {}
var active_stop_keys: Dictionary = {}
var next_vehicle_ordinal := 4
var grove_clearance_key: Array = []
var grove_clearance: Dictionary = {}

func rebuild(demo: Control) -> void:
	for node in props.values(): node.queue_free()
	props.clear()
	public_prop_layouts.clear()
	public_prop_keys.clear()
	prop_projections.clear()
	transit_stop_keys.clear()
	active_stop_keys.clear()
	site_key.clear()
	grove_clearance_key.clear()
	grove_clearance.clear()
	sites.clear()
	next_vehicle_ordinal = 4
	for site in demo.shown_world.public_sites:
		sites[site["id"]] = site
	var city: ContinuousWorld = demo.shown_world
	if city.terrain.family == "river_valley" and city.era == 1 and demo.art_direction.selected_id == "baseline":
		for record: Dictionary in GroveLayout.build(city):
			_add(demo,record["id"],record["position"],record["kind"],record["tone"])
			props[record["id"]].set_meta("natural_scale",record["scale"])
	else:
		_rebuild_retained_groves(demo,city)
	for road in city.roads:
		if road["bridge"]: continue
		var path: PackedVector2Array = road["path"]
		if road.get("kind","") == "branch": continue
		var p := path[path.size()/2]+Vector2(0.38,0)
		if city.terrain.land_at(p): _add(demo,"lamp-"+road["id"],p,"lamp",0)
	_sync_public_props(demo,city)
	vehicle_kind = city.vehicle_kind()
	for i in range(4): _add(demo,"vehicle-%d" % i,Vector2.ZERO,vehicle_kind,i)
	_sync_transit_props(demo,city)
	# Private cars only enter the street mix in the modern era; they remain
	# authored travelers so the era transition does not create a visual burst.
	for i in range(3): _add(demo,"car-%d" % i,Vector2.ZERO,"car",i+4,"",true)
	for i in range(10): _add(demo,"walker-%d" % i,Vector2.ZERO,"walker",i)

func _rebuild_retained_groves(demo: Control,city: ContinuousWorld) -> void:
	# Retained distribution for candidate art and the other terrain/era entries.
	for i in range(110):
		var p := Vector2(1.2+float((i*47+13)%301)/10.0,-1.4+float((i*73+29)%327)/10.0)
		if not city.terrain.land_at(p): continue
		var clear := true
		for lot in city.lots:
			if p.distance_to(Vector2(lot["center"][0],lot["center"][1])) < 1.25: clear = false
		for site in city.public_sites:
			if SpatialPlanning.point_in_footprint(site,p): clear = false
		var access := city.network.access(p)
		if not access.is_empty() and float(access["gap"]) < 0.6: clear = false
		if clear: _add(demo,"grove-%d" % i,p,"rock" if i%13 == 0 else "tree",i)

func _add(demo: Control,key: String,p: Vector2,kind: String,tone: int,site: String = "",modern_only: bool = false) -> void:
	var prop := ValleyProp.new()
	prop.kind = kind
	prop.tone = tone
	prop.era = demo.shown_world.era
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
		if props.has(key) and props[key].has_meta("traveler"):
			var traveler: CityTraveler = props[key].get_meta("traveler")
			traveler.restore(saved[key])
			if not traveler.service_line_id.is_empty(): next_vehicle_ordinal = maxi(next_vehicle_ordinal,traveler.ordinal+1)

func _sync_transit_props(demo: Control,city: ContinuousWorld) -> void:
	# A station is a road access, including authored positions between road nodes.
	# Stable station IDs deduplicate signs and retain transfer identity across lines.
	var wanted: Dictionary = {}
	var wanted_vehicles: Dictionary = {}
	var stop_tone := 0
	for line in city.transit_lines:
		for stop_value in line.get("stops",[]):
			var stop_id := str(stop_value)
			var station := city.transit_stop_record(stop_id)
			if station.is_empty(): continue
			var key := "stop-"+stop_id
			var shared: bool = station.get("line_ids",[]).size() > 1
			if not shared:
				shared = line.get("transfer_stops",[]).any(func(transfer: Dictionary) -> bool: return str(transfer.get("stop_id","")) == stop_id)
			if not wanted.has(key):
				wanted[key] = true
				if not props.has(key): _add(demo,key,city.transit_stop_position(stop_id),"stop",stop_tone)
				stop_tone += 1
			var stop_position := city.transit_stop_position(stop_id)
			if not props.has(key): continue
			if stop_position.is_finite(): props[key].set_meta("world_position",stop_position)
			props[key].set_meta("stop_id",stop_id)
			props[key].set_meta("authored_stop",bool(station.get("authored",false)))
			props[key].set_meta("line_ids",station.get("line_ids",[]).duplicate())
			props[key].set_meta("transfer_stop",shared)
			props[key].queue_redraw()
		if bool(line.get("authored",false)):
			var line_id := str(line["id"])
			var vehicle_key := "vehicle-line-"+line_id
			wanted_vehicles[vehicle_key] = true
			if not props.has(vehicle_key):
				_add(demo,vehicle_key,Vector2.ZERO,city.vehicle_kind(),next_vehicle_ordinal)
				next_vehicle_ordinal += 1
				var traveler: CityTraveler = props[vehicle_key].get_meta("traveler")
				traveler.service_line_id = line_id
				traveler.assigned_line_id = line_id
				props[vehicle_key].set_meta("authored_line",line_id)
	for key in transit_stop_keys:
		if wanted.has(key): continue
		if props.has(key):
			props[key].queue_free()
			props.erase(key)
			prop_projections.erase(key)
		active_stop_keys.erase(key)
	for key in props.keys():
		if not str(key).begins_with("vehicle-line-") or wanted_vehicles.has(key): continue
		props[key].queue_free()
		props.erase(key)
		prop_projections.erase(key)
	transit_stop_keys = wanted

func _sync_stop_activity(activity: Dictionary) -> void:
	var changed: Dictionary = active_stop_keys.duplicate()
	for key in activity: changed[key] = true
	for key in changed:
		if not props.has(key): continue
		var exchange: Dictionary = activity.get(key,{})
		if props[key].get_meta("station_exchange",{}) == exchange: continue
		props[key].set_meta("station_exchange",exchange)
		props[key].queue_redraw()
	active_stop_keys.clear()
	for key in activity: active_stop_keys[key] = true

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
	for prop: ValleyProp in props.values():
		if prop.kind not in ["carriage","tram","bus"]: continue
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
	var next_clearance: Array = demo._shown_city_key()+[city.road_index_identity]
	if grove_clearance_key != next_clearance:
		grove_clearance_key = next_clearance
		for key in props:
			if str(key).begins_with("grove-"): grove_clearance[key] = GroveLayout.clear(city,props[key].get_meta("world_position"))
	_sync_vehicle_kind(city)
	var next_site_key := [city,city.phrase_index]
	if site_key != next_site_key:
		site_key = next_site_key
		sites.clear()
		for site in city.public_sites: sites[site["id"]] = site
		_sync_public_props(demo,city)
		_sync_transit_props(demo,city)
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
	var stop_activity: Dictionary = {}
	var world_tint: Color = demo.buildings_layer.get_meta("world_tint",Color.WHITE)
	var scenery_red: float = world_tint.r/demo.buildings_layer.modulate.r
	for key in props:
		var prop: ValleyProp = props[key]
		if prop.era != city.era:
			prop.era = city.era
			prop.queue_redraw()
		_sync_prop_art(demo,prop)
		var p: Vector2 = prop.get_meta("world_position")
		var site_id := str(prop.get_meta("site"))
		prop.visible = true
		if str(key).begins_with("grove-"): prop.visible = bool(grove_clearance[key])
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
				prop.set_meta("line_id",movement.get("line_id",""))
				if prop.kind in ["carriage","tram","bus"] and bool(movement["stopped"]) and not prop.stop_id.is_empty():
					var stop_key := "stop-"+prop.stop_id
					var exchange: Dictionary = stop_activity.get(stop_key,{"vehicles":0,"passengers":0,"boarded":0,"alighted":0,"transfers":0})
					exchange["vehicles"] += 1
					exchange["passengers"] += int(movement.get("passengers",0))
					exchange["boarded"] += int(movement.get("boarded",0))
					exchange["alighted"] += int(movement.get("alighted",0))
					exchange["transfers"] += int(movement.get("transfer_passengers",0))
					stop_activity[stop_key] = exchange
		if prop.has_meta("traveler"):
			prop.position = WorldProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(p))
		else:
			var projection_key := [terrain_key,p]
			if not prop_projections.has(key) or prop_projections[key]["key"] != projection_key:
				prop_projections[key] = {"key":projection_key,"position":WorldProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(p))}
			prop.position = prop_projections[key]["position"]
		prop.scale = Vector2.ONE*float(prop.get_meta("public_scale",prop.get_meta("natural_scale",1.0)))
		# Remove building warmth while retaining the world's full daylight tint.
		prop.modulate = Color(scenery_red,1.0,1.0,prop.reveal)
		if prop.kind == "lamp": prop.sync_classical_lamp_light(float(demo.daylight_state.get("night_strength",0.0)),demo.daylight_state.get("world_tint",Color.WHITE))
		if prop.kind == "civic": prop.sync_classical_facade_light(demo.building_catalog.emission_for(prop.art_entry),float(demo.daylight_state.get("night_strength",0.0)),demo.daylight_state.get("world_tint",Color.WHITE))
		prop.motion = seconds*TAU/4.0
		# Station signs, lamps, rocks and civic geometry keep their draw commands.
		# Reveal alpha remains a CanvasItem property; trees/travelers keep animating.
		if prop.kind in ["tree","bus","carriage","tram","car","walker"]: prop.queue_redraw()
	_sync_stop_activity(stop_activity)

func _sync_prop_art(demo: Control,prop: ValleyProp) -> void:
	if prop.kind not in ["tree","civic"]: return
	var era: int = demo.shown_world.era
	var orientation := 0
	if prop.kind == "civic":
		var site: Dictionary = sites[str(prop.get_meta("site"))]
		era = demo.shown_world.era_for_phrase(int(site.get("created_phrase",int(site["frame"])/int(demo.shown_world.cfg["timing"]["phrase_frames"]))))
		var entry_at := Vector2(float(site["entrance"][0]),float(site["entrance"][1]))
		orientation = demo._street_orientation(prop.get_meta("world_position"),entry_at)
	var entry: Dictionary = demo.building_catalog.prop_entry(prop.kind,prop.tone,era,orientation) if demo.art_direction.selected_id == "baseline" else demo.art_direction.prop_entry(prop.kind,prop.tone)
	if str(prop.art_entry.get("id","")) == str(entry.get("id","")): return
	prop.art_entry = entry
	if not entry.is_empty():
		prop.art_texture = demo.building_catalog.texture_for(entry)
		prop.art_shadow = load("res://"+str(entry["shadow_texture"]))
		prop.art_contact = load("res://"+str(entry["contact_texture"]))
	else:
		prop.art_texture = null
		prop.art_shadow = null
		prop.art_contact = null
	prop.queue_redraw()
