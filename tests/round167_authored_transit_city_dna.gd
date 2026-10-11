extends SceneTree
## Round 167: authored multi-line transit identity and passenger memory survive
## City DNA export/import. Runtime view caches remain derived and disposable.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var checks: Dictionary = {}
var failures: Array[String] = []
var directory := ""
var paths: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _midpoints(world: RefCounted) -> Array:
	var result: Array = []
	for road in world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var point := path[0].lerp(path[-1],0.5)
		result.append({"id":str(road.get("id","")),"position":[point.x,point.y]})
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["id"]) < str(b["id"])
	)
	return result

func _fixture(world: RefCounted, ids: Array) -> Array:
	var by_id: Dictionary = {}
	for entry in _midpoints(world): by_id[str(entry["id"])] = entry["position"]
	var result: Array = []
	for id in ids:
		if not by_id.has(id): return []
		result.append(by_id[id].duplicate(true))
	return result

func _line(world: RefCounted, id: String) -> Dictionary:
	for line in world.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _event(world: RefCounted, id: String) -> Dictionary:
	for event in world.events:
		if str(event.get("kind","")) == "transit_line" and str(event.get("id","")) == id: return event
	return {}

func _second_route(world: RefCounted, first_preview: Dictionary, first_line: Dictionary) -> Dictionary:
	var stop_positions: Array = first_preview.get("stop_positions",[])
	if stop_positions.is_empty(): return {}
	var shared: Variant = stop_positions[0].duplicate(true)
	var candidates := _midpoints(world)
	for a in candidates:
		for b in candidates:
			if str(a["id"]) == str(b["id"]): continue
			var positions: Array = [shared.duplicate(true),a["position"].duplicate(true),b["position"].duplicate(true)]
			var preview: Dictionary = world.transit_plan_preview(positions)
			if not bool(preview.get("accepted",false)): continue
			if preview.get("stop_ids",[]) == first_line.get("stops",[]): continue
			return {"positions":positions,"preview":preview}
	return {}

func _export_model(model: RefCounted, suffix: String) -> Dictionary:
	var result := Archive.export_dna({"model":model.capture_state(),"view":{}},directory+"/exports")
	_check(bool(result.get("ok",false)),suffix+"_dna_export_writes")
	if not bool(result.get("ok",false)): return {}
	paths.append(str(result["path"]))
	var imported := Archive.read_dna(str(result["path"]))
	_check(bool(imported.get("ok",false)),suffix+"_dna_read_is_recoverable")
	return imported

func _run() -> void:
	directory = "user://round167_authored_transit_city_dna_%d" % Time.get_ticks_usec()
	var world := World.new("2026101100000167",true,"river_valley")
	world.build_expanded_town()
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	var first_preview := world.transit_plan_preview(_fixture(world,["west-road-1","west-road-2","west-road-3"]))
	_check(bool(first_preview.get("accepted",false)),"first_route_preview_is_real")
	if not bool(first_preview.get("accepted",false)):
		_finish()
		return
	var first_request := world.request({"kind":"transit_line","stop_positions":first_preview["stop_positions"],"source_topology":first_preview["source_topology"]},phrase)
	_check(bool(first_request.get("accepted",false)),"first_route_queues")
	world.settle(phrase)
	var first_id := "player-line-%d" % int(first_request.get("event_id",0))
	var first_line := _line(world,first_id)
	_check(not first_line.is_empty(),"first_route_settles")
	if first_line.is_empty():
		_finish()
		return
	var second := _second_route(world,first_preview,first_line)
	_check(not second.is_empty(),"second_distinct_route_uses_shared_station")
	if second.is_empty():
		_finish()
		return
	var second_preview: Dictionary = second["preview"]
	var shared_id := str(first_line.get("stops",[])[0])
	_check(second_preview.get("transfer_stop_ids",[]).has(shared_id),"preview_keeps_shared_station_identity")
	_check(second_preview.get("line_ids",[]).has(first_id),"preview_exposes_first_line_identity")
	var second_request := world.request({"kind":"transit_line","stop_positions":second["positions"],"source_topology":second_preview["source_topology"]},phrase*2)
	_check(bool(second_request.get("accepted",false)),"second_route_queues")
	world.settle(phrase*2)
	var second_id := "player-line-%d" % int(second_request.get("event_id",0))
	var second_line := _line(world,second_id)
	var second_event := _event(world,second_id)
	_check(not second_line.is_empty() and not second_event.is_empty(),"second_route_and_event_settle")
	_check(second_line.get("line_ids",[]).has(first_id) and second_line.get("line_ids",[]).has(second_id),"settled_line_contract_has_both_authored_ids")
	_check(second_line.get("transfer_stop_ids",[]).has(shared_id) and str(second_line.get("route_role","")) == "换乘走廊","settled_line_contract_keeps_shared_transfer_role")
	_check(second_event.get("coverage",{}).get("transfer_stop_ids",[]).has(shared_id) and second_event.get("line_ids",[]).has(first_id),"settled_event_contract_keeps_transfer_metadata")

	# One observation is committed into durable demand memory; another remains a
	# pending real vehicle observation and must be restored without being replayed.
	world.record_transit_flow(shared_id,2,1,2)
	world._commit_transit_flow()
	var committed_demand: Dictionary = world.transit_demand.get(shared_id,{})
	world.record_transit_flow(shared_id,1,0,1)
	world.refresh_functional_zones()
	world._refresh_transit_music_feedback()
	var feedback := world.transit_music_feedback(second_id)
	_check(int(committed_demand.get("transfers",0)) >= 2 and bool(feedback.get("transfer_qualified",false)),"committed_transfer_memory_enters_feedback")
	var model := Model.new(world,1.0)
	var pending_imported := _export_model(model,"pending")
	if pending_imported.is_empty():
		_finish()
		return
	var payload: Dictionary = pending_imported["dna"]
	var plan: Dictionary = payload.get("plan",{})
	evidence["shared_id"] = shared_id
	evidence["plan_authored_stop_ids"] = plan.get("authored_transit_stops",{}).keys()
	evidence["world_node_has_shared"] = world.nodes.has(shared_id)
	_check(plan.get("authored_transit_stops",{}).has(shared_id) or plan.get("transit_lines",[]).any(func(line: Dictionary) -> bool: return line.get("stops",[]).has(shared_id)),"dna_plan_exports_authored_station_identity")
	_check(plan.get("authored_transit_lines",[]).size() >= 2,"dna_plan_exports_both_authored_lines")
	_check(plan.get("transit_lines",[]).any(func(line: Dictionary) -> bool: return str(line.get("id","")) == second_id and line.get("transfer_stop_ids",[]).has(shared_id)),"dna_plan_exports_settled_transfer_contract")
	_check(plan.get("transit_demand",{}).get(shared_id,{}).get("transfers",0) == committed_demand.get("transfers",0),"dna_plan_exports_committed_passenger_memory")
	_check(plan.get("transit_flow_pending",[]).size() == 1,"dna_plan_exports_pending_vehicle_observation")
	_check(not plan.has("transit_stop_cache") and not payload.get("runtime",{}).get("model",{}).get("world",{}).has("transit_stop_cache"),"dna_excludes_derived_station_cache")
	var restored_model: RefCounted = Model.from_state(pending_imported["model"])
	var restored_world: RefCounted = restored_model.world
	var restored_line := _line(restored_world,second_id)
	var restored_event := _event(restored_world,second_id)
	_check((restored_world.authored_transit_stops.has(shared_id) or restored_world.nodes.has(shared_id)) and restored_world.authored_transit_lines.size() >= 2,"dna_runtime_restores_authored_station_and_lines")
	_check(restored_line.get("line_ids",[]).has(first_id) and restored_line.get("transfer_stop_ids",[]).has(shared_id),"dna_runtime_restores_transfer_contract")
	_check(restored_event.get("coverage",{}).get("route_role","") == "换乘走廊" and restored_event.get("music_feedback",{}).get("transfer_count",0) >= 2,"dna_runtime_restores_event_feedback")
	evidence["restored_demand"] = restored_world.transit_demand.get(shared_id,{})
	evidence["source_demand"] = committed_demand
	evidence["restored_pending"] = restored_world.transit_flow_pending
	evidence["source_pending"] = world.transit_flow_pending
	var restored_record: Dictionary = restored_world.transit_demand.get(shared_id,{})
	var demand_fields_match := true
	for field in ["score","boarded","alighted","transfers","visits"]:
		if not is_equal_approx(float(restored_record.get(field,0)),float(committed_demand.get(field,0))): demand_fields_match = false
	_check(demand_fields_match,"dna_runtime_restores_committed_passenger_memory")
	_check(restored_world.transit_flow_pending == world.transit_flow_pending,"dna_runtime_restores_pending_vehicle_observation_once")

	# Simulate an export that retained authored intent but lost the derived event;
	# restore must rebuild the complete current contract from the runtime line.
	var eventless_state := model.capture_state()
	eventless_state["world"]["events"] = eventless_state["world"]["events"].filter(func(event: Dictionary) -> bool: return not (str(event.get("kind","")) == "transit_line" and str(event.get("id","")) == second_id))
	var eventless: RefCounted = Model.from_state(eventless_state)
	var rebuilt_event := _event(eventless.world,second_id)
	_check(rebuilt_event.get("line_ids",[]).has(first_id) and rebuilt_event.get("transfer_stop_ids",[]).has(shared_id),"missing_event_restore_rebuilds_transfer_contract")
	_check(rebuilt_event.get("coverage",{}).get("route_role","") == "换乘走廊" and rebuilt_event.get("music_feedback",{}).get("transfer_count",0) >= 2,"missing_event_restore_rebuilds_feedback_metadata")
	_finish()

func _finish() -> void:
	for path in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if not directory.is_empty():
		if DirAccess.dir_exists_absolute(directory+"/exports"): DirAccess.remove_absolute(directory+"/exports")
		if DirAccess.dir_exists_absolute(directory): DirAccess.remove_absolute(directory)
	print("ROUND167_AUTHORED_TRANSIT_CITY_DNA ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}))
	quit(0 if failures.is_empty() else 1)
