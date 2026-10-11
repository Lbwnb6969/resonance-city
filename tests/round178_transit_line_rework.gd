extends SceneTree
## A real authored line is updated in place, retaining its creation identity,
## historical charter and old stations through both player save formats.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const CharterAnchor = preload("res://scripts/world/transit_charter_anchor.gd")
const EVIDENCE_PATH := "res://验证记录/round178_作者线路改站/transit_line_rework.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var directory := ""
var paths: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _record(items: Array,id: String) -> Dictionary:
	for item in items:
		if str(item.get("id","")) == id: return item
	return {}

func _event(city: World,event_id: int) -> Dictionary:
	for event in city.events:
		if str(event.get("kind","")) == "transit_line" and int(event.get("event_id",-1)) == event_id: return event
	return {}

func _boundary(model: Model) -> int:
	var frame := model.next_boundary
	model.render_block({},frame-1,2,int(model.world.cfg["timing"]["sample_rate"]))
	return frame

func _nodes(city: World,ids: Array) -> Array:
	var positions: Array = []
	for id in ids: positions.append(city.nodes[str(id)].duplicate())
	return positions

func _operation(city: World,line_id: String,positions: Array) -> Dictionary:
	var candidate := Rework.candidate(city,line_id)
	return {"kind":"transit_line","edit_id":line_id,"source_revision":candidate.get("source_revision",""),
		"source_topology":candidate.get("source_topology",""),"stop_positions":positions.duplicate(true)}

func _origin_kept(before: Dictionary,after: Dictionary) -> bool:
	for key in ["id","name","frame","event_id","charter_id","plan_id","scope_community_ids"]:
		if before.get(key) != after.get(key): return false
	return true

func _saved_models(model: Model,label: String) -> Array:
	var result: Array = []
	var captured := {"model":model.capture_state(),"renderer":{},"view":{}}
	var binary := Archive.save(captured,"Round178 "+label,directory)
	check(bool(binary.get("ok",false)),label+"_binary_writes")
	if bool(binary.get("ok",false)):
		paths.append(str(binary["path"]))
		var loaded := Archive.read(str(binary["path"]))
		check(bool(loaded.get("ok",false)),label+"_binary_reads")
		if bool(loaded.get("ok",false)): result.append({"format":"binary","model":Model.from_state(loaded["city"]["model"])})
	var dna := Archive.export_dna(captured,directory+"/exports")
	check(bool(dna.get("ok",false)),label+"_dna_writes")
	if bool(dna.get("ok",false)):
		paths.append(str(dna["path"]))
		var loaded := Archive.read_dna(str(dna["path"]))
		check(bool(loaded.get("ok",false)),label+"_dna_reads")
		if bool(loaded.get("ok",false)): result.append({"format":"dna","model":Model.from_state(loaded["model"])})
	return result

func _run() -> void:
	directory = "user://round178_transit_line_%d" % Time.get_ticks_usec()
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var model := Model.new(city)
	var charter := model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1","east-1"],"card_refs":["road_echo"]})
	var charter_id := "charter-%05d" % int(charter.get("event_id",-1))
	var first_positions: Array = []
	for road in city.roads:
		if str(road.get("id","")) not in ["west-road-1","west-road-2"]: continue
		var path: PackedVector2Array = road["path"]
		var position := path[0].lerp(path[-1],0.5)
		first_positions.append([position.x,position.y])
	var first_plan := city.transit_plan_preview(first_positions)
	check(bool(first_plan.get("accepted",false)),"fixture_uses_real_authored_midroad_stations")
	var created := model.submit({"kind":"transit_line","charter_id":charter_id,"stop_positions":first_positions,"source_topology":first_plan["source_topology"]})
	check(bool(created.get("accepted",false)),"fixture_queues_real_charter_line")
	_boundary(model)
	var id := "player-line-%d" % int(created["event_id"])
	var intent := _record(city.authored_transit_lines,id)
	intent["name"] = "我的河谷回廊"
	var original := intent.duplicate(true)
	var old_stops := city.authored_transit_stops.duplicate(true)
	var original_revision := str(Rework.candidate(city,id)["source_revision"])
	check(not original.has("revision") and int(Rework.candidate(city,id).get("edit_revision",-1)) == 0,"legacy_intent_without_edit_fields_is_editable")
	var snapshot := city.snapshot()
	var candidate := Rework.candidate(city,id)
	check(bool(candidate.get("accepted",false)) and candidate.get("line_name","") == original["name"] and candidate.get("charter_id","") == charter_id,"candidate_uses_real_identity_name_and_original_charter")
	candidate["stop_positions"][0][0] += 0.5
	candidate["scope_community_ids"].clear()
	check(city.snapshot() == snapshot,"candidate_arrays_are_independent")
	check(not bool(Rework.candidate(city,"valley-line").get("accepted",false)),"derived_default_line_cannot_be_edited_as_author_intent")
	var unchanged := Rework.preview(city,_operation(city,id,first_positions))
	check(bool(unchanged.get("accepted",false)) and unchanged.get("transfer_stop_ids",[]).is_empty(),"existing_line_does_not_count_itself_as_new_transfer")
	_boundary(model)
	check(Rework.candidate(city,id).get("source_revision","") == original_revision,"natural_growth_and_derived_coverage_do_not_expire_edit_source")
	model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1","east-1"]})
	model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":55})
	var seed: Dictionary = {}
	for lot in city.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if bool(city.placement(p).get("allowed",false)):
			seed = model.submit({"kind":"seed","position":[p.x,p.y],"midi":48})
			break
	check(bool(seed.get("accepted",false)),"fixture_has_real_independent_seed")
	check(not bool(CharterAnchor.source(city,charter_id).get("accepted",false)) and Rework.candidate(city,id)["source_revision"] == original_revision,"later_charter_and_retune_do_not_expire_existing_line_source")
	var positions := _nodes(city,["west-outer-3","west-outer-2","west-outer-1"])
	var operation := _operation(city,id,positions)
	var preview := Rework.preview(city,operation)
	check(bool(preview.get("accepted",false)) and preview.get("charter_id","") == charter_id and preview.get("scope_community_ids",[]) == original["scope_community_ids"],"preview_keeps_historical_charter_after_scope_replacement")
	check(preview.get("new_coverage",{}).get("covered_building_ids",[]) == preview.get("covered_building_ids",[]) and not (preview.get("added_covered_building_ids",[]).is_empty() and preview.get("removed_covered_building_ids",[]).is_empty()),"preview_exposes_actual_old_new_coverage_difference")
	var before_request := city.snapshot()
	var disconnected := _operation(city,id,_nodes(city,["east-1","east-2"]))
	check(not bool(model.submit(disconnected).get("accepted",false)) and city.snapshot() == before_request,"disconnected_old_stops_reject_without_world_or_rng_mutation")
	var stale := operation.duplicate(true)
	stale["source_revision"] = "old-editor"
	check(not bool(model.submit(stale).get("accepted",false)) and city.snapshot() == before_request,"stale_request_rejects_without_mutation")
	var stale_topology := operation.duplicate(true)
	stale_topology["source_topology"] = "old-road"
	check(not bool(model.submit(stale_topology).get("accepted",false)),"stale_topology_rejects")
	var temporary_new := city.transit_plan_preview(_nodes(city,["west-1","west-2"]))
	model.submit({"kind":"transit_line","stop_positions":temporary_new["stop_positions"],"source_topology":temporary_new["source_topology"]})
	var submitted := model.submit(operation)
	check(bool(submitted.get("accepted",false)),"edit_queues_existing_line_for_next_phrase")
	check(city.pending_actions.filter(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line").size() == 1 and city.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "charter") and city.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "seed") and city.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "retune"),"new_and_edit_share_one_route_slot_preserving_independent_actions")
	check(_record(city.authored_transit_lines,id)["stop_ids"] == original["stop_ids"] and city.authored_transit_lines.size() == 1,"pending_edit_does_not_change_current_line")
	var changed_source := Model.from_state(model.capture_state())
	_record(changed_source.world.authored_transit_lines,id)["revision"] = 1
	_boundary(changed_source)
	check(changed_source.world.authored_transit_lines.size() == 1 and _record(changed_source.world.authored_transit_lines,id)["stop_ids"] == original["stop_ids"] and changed_source.world.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "planning_rejected" and str(event.get("edit_id","")) == id and int(event.get("event_id",-1)) == int(submitted["event_id"])),"boundary_rechecks_authored_revision_and_preserves_line")
	for entry: Dictionary in _saved_models(model,"pending"):
		var restored: Model = entry["model"]
		var label := str(entry["format"])
		var pending: Dictionary = restored.world.pending_actions.filter(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line")[0]
		check(pending.get("edit_id","") == id and pending.get("source_revision","") == Rework.candidate(restored.world,id)["source_revision"],label+"_pending_restores_edit_identity_revision")
		_boundary(restored)
		check(restored.world.authored_transit_lines.size() == 1 and _origin_kept(original,_record(restored.world.authored_transit_lines,id)) and int(_record(restored.world.transit_lines,id).get("edit_revision",0)) == 1,label+"_pending_lands_one_line_with_original_identity")
	var boundary := _boundary(model)
	var edited := _record(city.authored_transit_lines,id)
	var line := _record(city.transit_lines,id)
	var event := _event(city,int(submitted["event_id"]))
	check(city.authored_transit_lines.size() == 1 and _origin_kept(original,edited),"commit_updates_one_intent_preserving_creation_name_and_charter")
	check(edited.get("stop_ids",[]) != original["stop_ids"] and int(edited.get("revision",0)) == 1 and int(edited.get("edited_frame",-1)) == boundary and int(edited.get("edit_event_id",-1)) == int(submitted["event_id"]),"commit_records_real_station_order_and_edit_version")
	check(line.get("id","") == id and line.get("name","") == original["name"] and int(line.get("frame",-1)) == int(original["frame"]) and int(line.get("edit_revision",0)) == 1 and line.get("source_revision","") == Rework.candidate(city,id)["source_revision"],"runtime_propagates_stable_creation_and_new_route_version")
	check(bool(event.get("edit",false)) and event.get("id","") == id and int(event.get("frame",-1)) == boundary and int(event.get("original_event_id",-1)) == int(original["event_id"]) and not _event(city,int(original["event_id"])).is_empty(),"edit_event_keeps_new_operation_and_original_event")
	var retained := true
	for old_id in original["stop_ids"]:
		if not edited.get("retained_stop_ids",[]).has(old_id) or not city.authored_transit_stops.has(old_id) or city.authored_transit_stops[old_id] != old_stops[old_id]: retained = false
	check(retained,"old_authored_station_records_and_all_old_destination_ids_survive")
	check(Rework.candidate(city,id)["source_revision"] != original_revision and not bool(model.submit(operation).get("accepted",false)),"completed_edit_expires_only_old_route_editor")
	check(not bool(Rework.preview(city,_operation(city,id,_nodes(city,["east-1","east-2"]))).get("accepted",false)),"later_edit_checks_retained_historical_stations_too")
	var loop_positions := _nodes(city,["west-1","west-2","west-3","west-1"])
	for entry: Dictionary in _saved_models(model,"settled"):
		var restored: Model = entry["model"]
		var label := str(entry["format"])
		check(_origin_kept(original,_record(restored.world.authored_transit_lines,id)) and int(_record(restored.world.transit_lines,id).get("edit_revision",0)) == 1 and bool(_event(restored.world,int(submitted["event_id"])).get("edit",false)),label+"_settled_restore_keeps_edit_and_creation_records")
		var again := restored.submit(_operation(restored.world,id,loop_positions))
		check(bool(again.get("accepted",false)),label+"_restored_line_accepts_another_edit")
		_boundary(restored)
		var current := _record(restored.world.authored_transit_lines,id)
		check(restored.world.authored_transit_lines.size() == 1 and _origin_kept(original,current) and int(current.get("revision",0)) == 2 and str(current.get("route_mode","")) == "loop",label+"_second_edit_preserves_one_line_and_loop_intent")
	var eventless := model.capture_state()
	eventless["world"]["events"] = eventless["world"]["events"].filter(func(item: Dictionary) -> bool: return str(item.get("id","")) != id)
	var rebuilt := Model.from_state(eventless)
	var rebuilt_event := _event(rebuilt.world,int(submitted["event_id"]))
	check(bool(rebuilt_event.get("edit",false)) and int(rebuilt_event.get("original_event_id",-1)) == int(original["event_id"]) and rebuilt_event.get("charter_id","") == charter_id,"eventless_restore_rebuilds_latest_edit_with_original_source")
	_finish()

func _finish() -> void:
	for path in paths: DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory+"/exports")
	DirAccess.remove_absolute(directory)
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE_PATH.get_base_dir()))
	var file := FileAccess.open(EVIDENCE_PATH,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  ")+"\n")
		file.close()
	print("ROUND178_TRANSIT_LINE_REWORK "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
