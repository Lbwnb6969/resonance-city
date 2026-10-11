extends SceneTree
## Real old-leg arrival, rider exchange, reconnect and in-flight restoration.
const World = preload("res://scripts/world/continuous_world.gd")
const Plan = preload("res://scripts/world/transit_planning.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const Traveler = preload("res://scripts/visual/city_traveler.gd")
const OUTPUT := "res://验证记录/round178_公交改站/transit_rework_travelers.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _line(world: World,id: String) -> Dictionary:
	for line in world.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _run() -> void:
	var world := World.new("2026100900000062",true,"river_valley")
	world.build_rework_starter("bright")
	var positions: Array = []
	for road in world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road["path"]
		if path[0].distance_to(path[-1]) < 1.2: continue
		for fraction in [0.15,0.4,0.7,0.9]: positions.append(path[0].lerp(path[-1],fraction))
		break
	check(positions.size() == 4,"fixture_uses_four_real_non_node_road_positions")
	if positions.size() != 4:
		_finish()
		return
	var old := Plan.commit(world,{"event_id":17801,"source_topology":world.network.topology,"stop_positions":positions.slice(0,3)},world.phrase_index*int(world.cfg["timing"]["phrase_frames"]))
	check(bool(old.get("accepted",false)),"real_authored_line_commits")
	if not bool(old.get("accepted",false)):
		_finish()
		return
	world._refresh_public_network()
	var id := str(old["id"])
	var old_stops: Array = _line(world,id)["stops"].duplicate()
	var bus := Traveler.new("bus",0)
	bus.service_line_id = id
	bus.assigned_line_id = id
	var seconds := 0.0
	bus.advance(world,seconds)
	for tick in range(1,1001):
		seconds = float(tick)*0.02
		bus.advance(world,seconds)
		if bus.wait <= 0.0 and bus.distance > 0.08 and bus.distance < bus.total-0.08: break
	check(bus.destination == str(old_stops[1]) and bus.distance > 0.08 and bus.distance < bus.total-0.08,"edit_begins_during_first_real_old_leg")
	var path_before := bus.path.duplicate()
	var position_before := bus.position
	var destination_before := bus.destination
	var candidate := Rework.candidate(world,id)
	var edit := {"kind":"transit_line","edit_id":id,"source_revision":candidate["source_revision"],"source_topology":candidate["source_topology"],"stop_positions":positions.slice(2,4)}
	var boundary := (world.phrase_index+1)*int(world.cfg["timing"]["phrase_frames"])
	var queued := world.request(edit,boundary)
	check(bool(queued.get("accepted",false)) and _line(world,id)["stops"] == old_stops,"pending_edit_keeps_visible_original_route")
	world.settle(boundary)
	var edited := _line(world,id)
	check(int(edited.get("edit_revision",0)) == 1 and world.authored_transit_lines.size() == 1,"edit_reuses_one_stable_authored_service")
	check(bus.path == path_before and bus.position == position_before and bus.destination == destination_before,"settlement_keeps_existing_vehicle_position_destination_and_old_path")
	# Explicit rider fixture: removed origin first, actual old arrival second,
	# retained new first last. This exposes the old pop_back starvation bug.
	bus.passenger_destinations.assign([str(old_stops[0]),str(old_stops[1]),str(old_stops[2])])
	bus.passenger_load = 3
	world.transit_flow_pending.clear()
	var reached := false
	var maximum_step := 0.0
	for tick in range(3000):
		var previous := bus.position
		seconds += 0.02
		bus.advance(world,seconds)
		maximum_step = maxf(maximum_step,previous.distance_to(bus.position))
		if bus.destination_kind == "transit_reconnect":
			reached = true
			break
	check(reached and bus.stop_id == destination_before,"old_leg_finishes_at_its_real_removed_stop")
	check(bus.passengers_boarded == 0 and bus.passengers_alighted == 2 and bus.passenger_destinations == [str(old_stops[2])],"actual_old_arrival_alights_removed_targets_and_keeps_valid_rider")
	check(world.transit_flow_pending.size() == 1 and str(world.transit_flow_pending[0]["stop_id"]) == destination_before and int(world.transit_flow_pending[0]["alighted"]) == 2,"old_arrival_records_one_real_alighting_packet")
	check(bus.destination == str(edited["stops"][0]) and bus.path[0].distance_to(world.transit_stop_position(destination_before)) < 0.1 and bus.path[-1].distance_to(world.transit_stop_position(bus.destination)) < 0.1 and maximum_step < 0.1,"same_vehicle_reconnects_by_real_road_without_a_position_jump")
	var saved := bus.snapshot()
	var captured_path: PackedVector2Array = saved["path"].duplicate()
	var captured_lengths: PackedFloat32Array = saved["lengths"].duplicate()
	var restored_world := World.new()
	restored_world.restore(world.snapshot())
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	check(restored.snapshot() == saved and restored.reconnect_arrival_stop == destination_before,"in_flight_reconnect_snapshot_keeps_once_only_arrival")
	var exact := true
	for tick in range(1000):
		seconds += 0.02
		bus.advance(world,seconds)
		restored.advance(restored_world,seconds)
		exact = exact and bus.snapshot() == restored.snapshot() and world.transit_flow_pending == restored_world.transit_flow_pending
	check(exact,"restored_reconnect_continues_exact_vehicle_and_flow_state")
	check(saved["path"] == captured_path and saved["lengths"] == captured_lengths,"captured_in_flight_packed_path_is_immutable_after_later_legs")
	check(bus.service_line_id == id and bus.assigned_line_id == id and bus.reconnect_arrival_stop.is_empty(),"rejoined_vehicle_keeps_service_identity_and_resumes_station_exchange")
	check(not bus.passenger_destinations.has(str(old_stops[0])) and not bus.passenger_destinations.has(str(old_stops[1])),"removed_rider_destinations_do_not_remain_on_the_new_line")
	var removed_packets := 0
	for packet in world.transit_flow_pending:
		if str(packet["stop_id"]) == destination_before: removed_packets += 1
	check(removed_packets == 1,"subsequent_travel_does_not_repeat_old_stop_flow")
	evidence = {"line_id":id,"old_stops":old_stops,"new_stops":edited["stops"],"old_arrival":destination_before,"max_position_step":maximum_step,"retained_reconnect":saved,"rider_fixture":"Three explicit riders: removed origin, completed old stop, retained new first. Route and arrivals use production Traveler."}
	_disconnected(world,id)
	_finish()

func _disconnected(world: World,id: String) -> void:
	id = str(world.transit_lines[0]["id"])
	var at := Vector2(-20,-20)
	world.network.nodes["isolated-test-stop"] = [at.x,at.y]
	world.network.adjacency["isolated-test-stop"] = []
	var stop := world.transit_stop_record(str(_line(world,id)["stops"][0]))
	stop["id"] = "isolated-test-stop"
	stop["position"] = [at.x,at.y]
	world.authored_transit_stops["isolated-test-stop"] = stop
	var bus := Traveler.new("bus",0)
	bus.initialized = true
	bus.service_line_id = id
	bus.assigned_line_id = id
	bus.line_key = "old line"
	bus.destination = "isolated-test-stop"
	bus.position = at
	bus.path = PackedVector2Array([at-Vector2.RIGHT,at])
	bus.lengths = PackedFloat32Array([1.0])
	bus.total = 1.0
	bus.distance = 1.0
	bus.passenger_destinations.assign(["isolated-test-stop",str(_line(world,id)["stops"][0])])
	bus.passenger_load = 2
	world.transit_flow_pending.clear()
	bus._next_bus(world)
	var saved := bus.snapshot()
	bus._next_bus(world)
	check(bus.position == at and bus.destination == "isolated-test-stop" and bus.path == saved["path"] and bus.wait == 1.0,"disconnected_reconnect_waits_at_actual_old_stop_without_jump")
	check(world.transit_flow_pending.size() == 1 and bus.passenger_load == 1 and bus.passengers_alighted == 1,"disconnected_retry_does_not_repeat_rider_exchange")
	var restored := Traveler.new("bus",0)
	restored.restore(saved)
	restored._next_bus(world)
	check(world.transit_flow_pending.size() == 1,"restored_disconnected_retry_keeps_once_only_flow")

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Real non-node authored line and road reconnect; explicit rider edge fixture and isolated retry fixture; no physical device or human experience claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND178_TRANSIT_REWORK_TRAVELERS "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
