extends SceneTree
## Round168: a transit hub aggregates line-level next actions truthfully.
## A shared pair must keep the hub actionable even when a later unrelated line
## is still waiting for passengers; the aggregate survives save/restore.
const World = preload("res://scripts/world/continuous_world.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

var checks: Dictionary = {}
var failures: Array[String] = []
var export_directory := ""
var exported_paths: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _positions(world: World, roads: Array[String]) -> Array:
	var result: Array = []
	for road_id in roads:
		for road in world.roads:
			if str(road.get("id","")) != road_id: continue
			var path: PackedVector2Array = road.get("path",PackedVector2Array())
			if path.size() < 2: continue
			var point := path[path.size()/2]
			result.append([point.x,point.y])
	return result

func _line(world: World, id: String) -> Dictionary:
	for line in world.transit_lines:
		if str(line.get("id","")) == id: return line
	return {}

func _zone(world: World) -> Dictionary:
	for candidate in world.functional_zones:
		if str(candidate.get("role","")) == "transit": return candidate
	return {}

func _queue(world: World, positions: Array, frame: int) -> Dictionary:
	var preview := world.transit_plan_preview(positions)
	_check(bool(preview.get("accepted",false)),"route_preview_accepts_real_stops")
	if not bool(preview.get("accepted",false)): return {}
	return world.request({"kind":"transit_line","stop_positions":positions,"source_topology":preview["source_topology"]},frame)

func _union(values: Array) -> Array:
	var result: Array = []
	for value in values:
		for raw in value:
			var item := str(raw)
			if not item.is_empty() and not result.has(item): result.append(item)
	result.sort()
	return result

func _same_action(a: Dictionary, b: Dictionary) -> bool:
	for field in ["kind","qualified_role","transfer_state","state"]:
		if str(a.get(field,"")) != str(b.get(field,"")): return false
	if _union([a.get("line_ids",[])]) != _union([b.get("line_ids",[]) ]): return false
	if _union([a.get("transfer_stop_ids",[])]) != _union([b.get("transfer_stop_ids",[]) ]): return false
	return true

func _remove_exports() -> void:
	for path in exported_paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if not export_directory.is_empty() and DirAccess.dir_exists_absolute(export_directory): DirAccess.remove_absolute(export_directory)

func _run() -> void:
	export_directory = "user://round168_transit_next_action_aggregation_%d" % Time.get_ticks_usec()
	var world := World.new("2026101100000168",true,"river_valley")
	world.build_expanded_town()
	var phrase := int(world.cfg["timing"]["phrase_frames"])
	var first_positions := _positions(world,["west-road-1","west-road-2","west-road-3"])
	var second_positions := _positions(world,["west-road-2","west-road-3","west-road-1"])
	var third_positions := _positions(world,["east-road-1","east-road-2","east-road-3"])
	_check(first_positions.size() == 3 and second_positions.size() == 3 and third_positions.size() == 3,"three_routes_use_real_road_stops")
	var first := _queue(world,first_positions,phrase)
	_check(bool(first.get("accepted",false)),"first_authored_line_queues")
	world.settle(phrase)
	var first_id := "player-line-%d" % int(first.get("event_id",-1))
	var second := _queue(world,second_positions,phrase*2)
	_check(bool(second.get("accepted",false)),"shared_authored_line_queues")
	world.settle(phrase*2)
	var second_id := "player-line-%d" % int(second.get("event_id",-1))
	var third := _queue(world,third_positions,phrase*3)
	_check(bool(third.get("accepted",false)),"unrelated_authored_line_queues")
	world.settle(phrase*3)
	var third_id := "player-line-%d" % int(third.get("event_id",-1))
	var first_feedback := world.transit_music_feedback(first_id)
	var second_feedback := world.transit_music_feedback(second_id)
	var third_feedback := world.transit_music_feedback(third_id)
	var shared_stops: Array = _union([first_feedback.get("transfer_stop_ids",[]),second_feedback.get("transfer_stop_ids",[])])
	_check(not shared_stops.is_empty(),"first_pair_has_transfer_stops")
	_check(str(first_feedback.get("next_action",{}).get("kind","")) == "observe_transfer" and str(second_feedback.get("next_action",{}).get("kind","")) == "observe_transfer","shared_lines_wait_for_real_exchange")
	_check(str(third_feedback.get("next_action",{}).get("kind","")) == "observe_passengers","unrelated_line_waits_for_own_passengers")
	var before_zone := _zone(world)
	var before_action: Dictionary = before_zone.get("next_action",{})
	var all_ids := [first_id,second_id,third_id]
	var before_zone_line_ids: Array = _union([before_zone.get("line_ids",[])])
	var before_zone_transfer_ids: Array = []
	for raw_line_id in before_zone_line_ids:
		before_zone_transfer_ids = _union([before_zone_transfer_ids,world.transit_music_feedback(str(raw_line_id)).get("transfer_stop_ids",[])])
	evidence["before_zone_action"] = before_action.duplicate(true)
	_check(all_ids.all(func(id: String) -> bool: return before_zone.get("line_ids",[]).has(id)),"hub_contains_all_three_authored_lines")
	_check(str(before_zone.get("next_action_kind","")) == "observe_transfer","hub_prioritizes_shared_exchange_over_later_wait")
	_check(_union([before_action.get("transfer_stop_ids",[])]) == before_zone_transfer_ids,"hub_before_action_keeps_all_transfer_stops")
	_check(_union([before_action.get("line_ids",[])]) == before_zone_line_ids,"hub_before_action_names_all_zone_lines")

	var shared_id := str(shared_stops[0])
	world.record_transit_flow(shared_id,2,1,2)
	world._commit_transit_flow()
	world.refresh_functional_zones()
	var first_after := world.transit_music_feedback(first_id)
	var after_zone := _zone(world)
	var after_action: Dictionary = after_zone.get("next_action",{})
	var after_zone_line_ids: Array = _union([after_zone.get("line_ids",[])])
	var after_zone_transfer_ids: Array = []
	for raw_line_id in after_zone_line_ids:
		after_zone_transfer_ids = _union([after_zone_transfer_ids,world.transit_music_feedback(str(raw_line_id)).get("transfer_stop_ids",[])])
	evidence["after_zone_action"] = after_action.duplicate(true)
	_check(str(first_after.get("next_action",{}).get("kind","")) == "continue_composition","shared_line_unlocks_composition")
	_check(str(after_zone.get("next_action_kind","")) == "continue_composition","hub_prioritizes_real_exchange_over_waiting_lines")
	_check(_union([after_action.get("transfer_stop_ids",[])]) == after_zone_transfer_ids,"hub_after_action_keeps_all_transfer_stops")
	_check(_union([after_action.get("line_ids",[])]) == after_zone_line_ids,"hub_after_action_names_all_zone_lines")
	_check(str(after_action.get("growth_action",{}).get("kind","")) == "prioritize_near_station","hub_after_action_keeps_strongest_growth_followup")
	_check(not after_action.get("growth_action",{}).get("demand_stop_ids",[]).is_empty(),"hub_after_action_keeps_demand_stops")

	# Pending observations and the aggregate action must survive both model state
	# capture and the JSON DNA runtime without replaying the vehicle flow.
	world.record_transit_flow(shared_id,1,0,1)
	var model := Model.new(world,1.0)
	var dna := Archive.export_dna({"model":model.capture_state(),"view":{}},export_directory+"/exports")
	_check(bool(dna.get("ok",false)),"aggregate_dna_export_writes")
	if bool(dna.get("ok",false)):
		exported_paths.append(str(dna.get("path","")))
		var imported := Archive.read_dna(str(dna.get("path","")))
		_check(bool(imported.get("ok",false)),"aggregate_dna_read_is_recoverable")
		if bool(imported.get("ok",false)):
			var restored_model: RefCounted = Model.from_state(imported["model"])
			var restored_zone := _zone(restored_model.world)
			_check(restored_model.world.transit_flow_pending == world.transit_flow_pending,"dna_restores_pending_flow_once")
			_check(_same_action(restored_zone.get("next_action",{}),after_action),"dna_restores_aggregate_next_action")
			evidence["restored_zone_action"] = restored_zone.get("next_action",{})
	_remove_exports()
	_finish()

func _finish() -> void:
	print("ROUND168_TRANSIT_NEXT_ACTION_AGGREGATION ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}))
	quit(0 if failures.is_empty() else 1)
