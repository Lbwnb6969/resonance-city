extends SceneTree
## Production Scenery, default vehicles and pedestrians: no traffic-free shortcut.
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const OUTPUT := "res://验证记录/round178_公交改站/transit_fleet_progress.json"
const STEP := 0.05
const STALL_SECONDS := 12.0
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var diagnostics: Array = []
var demo: ContinuousValleyDemo
var seconds := 0.0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _positions(city: ContinuousWorld) -> Array:
	var result: Array = []
	for id in ["west-road-1","west-road-2","west-road-3"]:
		for road in city.roads:
			if str(road.get("id","")) != id: continue
			var path: PackedVector2Array = road["path"]
			var p := path[0].lerp(path[-1],0.5)
			result.append([p.x,p.y])
	return result

func _sync() -> void:
	demo.clock.renderer.transport.audible_frame = seconds*demo.clock.renderer.transport.sample_rate
	demo.scenery.sync(demo)

func _traffic_entry(key: String,traveler: CityTraveler) -> Dictionary:
	var access := demo.shown_world.network.access(traveler.position,false)
	return {"key":key,"kind":traveler.kind,"ordinal":traveler.ordinal,"position":traveler.position,"direction":traveler.direction,
		"road":str(access.get("road","")),"road_from":str(access.get("from","")),"road_to":str(access.get("to","")),
		"road_along":float(access.get("along",0.0)),"road_length":float(access.get("length",0.0)),"priority":traveler._priority()}

func _diagnose(key: String,phase: String) -> Dictionary:
	var traveler: CityTraveler = demo.scenery.props[key].get_meta("traveler")
	var city := demo.shown_world
	var nearby: Array = []
	var traffic: Array = []
	for other_key in demo.scenery.props:
		var prop: ValleyProp = demo.scenery.props[other_key]
		if not prop.has_meta("traveler"): continue
		var other: CityTraveler = prop.get_meta("traveler")
		if not other.initialized or (other.kind == "car" and city.era < 5): continue
		var entry := _traffic_entry(str(other_key),other)
		traffic.append(entry)
		if str(other_key) == key or traveler.position.distance_to(other.position) > 1.800001: continue
		entry["gap"] = traveler.position.distance_to(other.position)
		entry["heading_dot"] = traveler.direction.dot(other.direction)
		entry["ahead"] = (other.position-traveler.position).dot(traveler.direction)
		entry["wait"] = other.wait
		entry["remaining"] = other.total-other.distance
		entry["destination"] = other.destination
		entry["single_obstacle_allowed"] = traveler._traffic_distance(city,STEP,[entry])
		nearby.append(entry)
	var result := {"phase":phase,"seconds":seconds,"vehicle":_traffic_entry(key,traveler),"destination":traveler.destination,
		"remaining":traveler.total-traveler.distance,"wait":traveler.wait,"speed":traveler.motion_speed,
		"allowed":traveler._traffic_distance(city,STEP,traffic),"access":city.network.access(traveler.position,false),"nearby":nearby}
	diagnostics.append(result)
	print("ROUND178_FLEET_STALL "+JSON.stringify(result))
	return result

func _stage(key: String,label: String,duration: float) -> Dictionary:
	var traveler: CityTraveler = demo.scenery.props[key].get_meta("traveler")
	var previous := traveler.position
	var travelled := 0.0
	var still := 0.0
	var maximum_still := 0.0
	var recorded_stall := false
	var old_destination := traveler.destination
	var arrivals := 0
	var first_flow := demo.shown_world.transit_flow_pending.size()
	var fleet: Dictionary = {}
	for prop_key in demo.scenery.props:
		var prop: ValleyProp = demo.scenery.props[prop_key]
		if not prop.has_meta("traveler"): continue
		var actor: CityTraveler = prop.get_meta("traveler")
		if not actor.initialized or (actor.kind == "car" and demo.shown_world.era < 5): continue
		fleet[prop_key] = {"position":actor.position,"travelled":0.0,"still":0.0,"max_still":0.0}
	for tick in range(roundi(duration/STEP)):
		seconds += STEP
		_sync()
		var movement := previous.distance_to(traveler.position)
		travelled += movement
		if movement < 0.00001 and traveler.total-traveler.distance > 0.1:
			still += STEP
		else: still = 0.0
		maximum_still = maxf(maximum_still,still)
		if still >= STALL_SECONDS and not recorded_stall:
			recorded_stall = true
			_diagnose(key,label)
		if old_destination != traveler.destination:
			arrivals += 1
			old_destination = traveler.destination
		previous = traveler.position
		for prop_key in fleet:
			var actor: CityTraveler = demo.scenery.props[prop_key].get_meta("traveler")
			var progress: Dictionary = fleet[prop_key]
			var delta := Vector2(progress["position"]).distance_to(actor.position)
			progress["travelled"] += delta
			progress["still"] = float(progress["still"])+STEP if delta < 0.00001 and actor.total-actor.distance > 0.1 else 0.0
			progress["max_still"] = maxf(float(progress["max_still"]),float(progress["still"]))
			progress["position"] = actor.position
	var fleet_progress := true
	for prop_key in fleet:
		var progress: Dictionary = fleet[prop_key]
		if float(progress["max_still"]) >= STALL_SECONDS: fleet_progress = false
		if float(progress["still"]) >= STALL_SECONDS and str(prop_key) != key: _diagnose(str(prop_key),label+"_end")
	var result := {"travelled":travelled,"max_still_seconds":maximum_still,"arrivals":arrivals,
		"new_flow_observations":demo.shown_world.transit_flow_pending.size()-first_flow,"position":traveler.position,"destination":traveler.destination,"fleet_progress":fleet}
	check(travelled > 2.0 and arrivals > 0,label+"_author_vehicle_reaches_real_stops_with_default_fleet")
	check(maximum_still < STALL_SECONDS,label+"_author_vehicle_does_not_remain_blocked")
	check(fleet_progress,label+"_all_active_default_fleet_agents_keep_progressing")
	return result

func _queue_contract(city: ContinuousWorld) -> void:
	var junction := Vector2(float(city.nodes["west-outer-2"][0]),float(city.nodes["west-outer-2"][1]))
	var leader := CityTraveler.new("carriage",0)
	leader.position = junction+Vector2.RIGHT*2.0
	leader.direction = Vector2.RIGHT
	var access: Dictionary = city.network.access(leader.position,false)
	var peer := {"kind":"carriage","ordinal":2,"priority":16,"position":leader.position,"direction":Vector2.RIGHT,"road":access["road"]}
	check(leader._traffic_distance(city,0.05,[peer]) == 0.05,"parallel_spawn_has_one_stable_queue_winner")
	var follower := CityTraveler.new("carriage",2)
	follower.position = leader.position
	follower.direction = leader.direction
	peer.merge({"ordinal":0,"priority":0},true)
	check(follower._traffic_distance(city,0.05,[peer]) == 0.0,"parallel_spawn_follower_yields_to_same_winner")
	peer["position"] = leader.position+Vector2.RIGHT*0.3
	peer["ordinal"] = 2
	peer["priority"] = 16
	check(leader._traffic_distance(city,0.05,[peer]) == 0.0,"genuine_same_lane_front_vehicle_keeps_headway")
	peer.merge({"kind":"walker","ordinal":1,"priority":12,"position":leader.position+Vector2(0.1,0.17)},true)
	check(leader._traffic_distance(city,0.05,[peer]) == 0.05,"parallel_sidewalk_does_not_queue_road_vehicle")
	peer.merge({"kind":"carriage","ordinal":2,"priority":16,"position":leader.position+Vector2(0.1,0.1),"direction":Vector2.LEFT},true)
	check(leader._traffic_distance(city,0.05,[peer]) == 0.05,"separate_opposite_lane_can_pass")
	var exiting := CityTraveler.new("walker",7)
	exiting.position = junction+Vector2.RIGHT*0.02
	exiting.direction = Vector2.LEFT
	access = city.network.access(exiting.position,false)
	var incoming := {"kind":"carriage","ordinal":0,"priority":0,"position":junction+Vector2.DOWN*0.8,"direction":Vector2.UP,"road":"west-outer-road-3","road_from":"west-outer-2","road_to":"west-outer-3"}
	check(not exiting._junction_conflict(city,access,incoming),"nearest_junction_occupant_clears_before_incoming_priority")
	var arriving := CityTraveler.new("carriage",0)
	arriving.position = incoming["position"]
	arriving.direction = Vector2.UP
	var occupant := {"kind":"walker","ordinal":7,"priority":60,"position":exiting.position,"direction":Vector2.LEFT,"road":access["road"],"road_from":access["from"],"road_to":access["to"]}
	check(arriving._junction_conflict(city,city.network.access(arriving.position,false),occupant),"incoming_vehicle_yields_to_occupied_crossing")

func _run() -> void:
	demo = preload("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var city := demo.model.world
	_queue_contract(city)
	var rate := int(city.cfg["timing"]["sample_rate"])
	seconds = float(city.phrase_index*int(city.cfg["timing"]["phrase_frames"]))/rate
	_sync()
	var vehicles := 0
	var walkers := 0
	for key in demo.scenery.props:
		if str(key).begins_with("vehicle-"): vehicles += 1
		if str(key).begins_with("walker-"): walkers += 1
	check(vehicles == 4 and walkers == 10,"fixture_keeps_all_default_four_vehicles_and_ten_pedestrians")
	var queued := demo.model.submit({"kind":"transit_line","stop_positions":_positions(city),"source_topology":city.network.topology})
	check(bool(queued.get("accepted",false)),"three_actual_midroad_stations_queue_one_author_line")
	if not bool(queued.get("accepted",false)):
		await _finish()
		return
	var boundary := demo.model.next_boundary
	while seconds+STEP < float(boundary)/rate:
		seconds += STEP
		_sync()
	demo.model.render_block({},boundary-1,2,rate)
	demo.shown_world = demo.model.world
	seconds = float(boundary)/rate
	_sync()
	var line_id := "player-line-%d" % int(queued["event_id"])
	var key := "vehicle-line-"+line_id
	check(demo.scenery.props.has(key),"production_scenery_adds_real_authored_service_vehicle")
	if not demo.scenery.props.has(key):
		await _finish()
		return
	var traveler: CityTraveler = demo.scenery.props[key].get_meta("traveler")
	var identity := traveler.get_instance_id()
	evidence["before_edit"] = _stage(key,"before_edit",90.0)
	var candidate := Rework.candidate(city,line_id)
	var stops: Array = []
	for id in ["west-outer-3","west-outer-2","west-outer-1"]: stops.append(city.nodes[id].duplicate())
	var edit := demo.model.submit({"kind":"transit_line","edit_id":line_id,"source_revision":candidate["source_revision"],"source_topology":candidate["source_topology"],"stop_positions":stops})
	check(bool(edit.get("accepted",false)),"same_author_line_accepts_real_connected_rework")
	if bool(edit.get("accepted",false)):
		# This test's explicit simulated device cursor is independent of render
		# supply. Commit the real operation, then continue the same fleet clock.
		boundary = demo.model.next_boundary
		demo.model.render_block({},boundary-1,2,rate)
		demo.shown_world = demo.model.world
		_sync()
		check(demo.scenery.props[key].get_meta("traveler").get_instance_id() == identity,"rework_retains_the_existing_author_vehicle_in_full_fleet")
		evidence["after_edit"] = _stage(key,"after_edit",90.0)
	evidence["line_id"] = line_id
	evidence["default_vehicles"] = vehicles
	evidence["default_pedestrians"] = walkers
	evidence["diagnostics"] = diagnostics
	await _finish()

func _finish() -> void:
	demo.queue_free()
	await process_frame
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"Dummy production Scenery.sync, real default fleet and authored station edits. Simulated audible-frame time; no physical device or audio timing claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND178_TRANSIT_FLEET_PROGRESS "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
