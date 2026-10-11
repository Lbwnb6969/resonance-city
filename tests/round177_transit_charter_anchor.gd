extends SceneTree
## One real charter owns its new transit anchor through request, settlement and
## both save formats. Association is metadata, not a new growth or demand rule.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Anchor = preload("res://scripts/world/transit_charter_anchor.gd")
const EVIDENCE_PATH := "res://验证记录/round177_公交章程锚点/transit_charter_anchor.json"
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

func _city() -> World:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	return city

func _route(city: World) -> Dictionary:
	return city.transit_plan_preview([city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate()])

func _submit(model: Model,route: Dictionary,charter_id := "") -> Dictionary:
	var operation := {"kind":"transit_line","stop_positions":route["stop_positions"].duplicate(true),"source_topology":route["source_topology"]}
	if not charter_id.is_empty(): operation["charter_id"] = charter_id
	return model.submit(operation)

func _boundary(model: Model) -> int:
	var frame := model.next_boundary
	model.render_block({},frame-1,2,int(model.world.cfg["timing"]["sample_rate"]))
	return frame

func _record(items: Array,id: String) -> Dictionary:
	for item in items:
		if str(item.get("id","")) == id: return item
	return {}

func _identity(record: Dictionary,source: String) -> bool:
	return record.get("charter_id","") == source and record.get("plan_id","") == "corridor" and record.get("scope_community_ids",[]) == ["east-1","west-1"]

func _same_music_growth(a: World,b: World) -> bool:
	if a.buildings != b.buildings or a.rng.snapshot() != b.rng.snapshot() or a.resonance != b.resonance: return false
	return a.transit_demand == b.transit_demand and a.transit_flow_pending == b.transit_flow_pending

func _saved_models(model: Model,label: String) -> Array:
	var result: Array = []
	var captured := {"model":model.capture_state(),"renderer":{},"view":{}}
	var binary := Archive.save(captured,"Round177 "+label,directory)
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
	directory = "user://round177_transit_charter_%d" % Time.get_ticks_usec()
	var city := _city()
	var model := Model.new(city)
	var scope_request := model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1","east-1"],"card_refs":["road_echo"]})
	var source := "charter-%05d" % int(scope_request.get("event_id",-1))
	check(bool(scope_request.get("accepted",false)),"real_scope_and_card_queue")
	check(bool(Anchor.source(city,source).get("accepted",false)),"pending_charter_has_stable_source")
	var route := _route(city)
	check(bool(route.get("accepted",false)),"route_uses_real_connected_roads")
	var before := city.snapshot()
	var preview := Anchor.preview(city,route,source)
	check(bool(preview.get("accepted",false)) and _identity(preview,source),"preview_binds_exact_pending_charter")
	check(preview.get("covered_scope_community_ids",[]) == ["west-1"] and preview.get("uncovered_scope_community_ids",[]) == ["east-1"] and not preview.get("scope_covered_building_ids",[]).is_empty(),"preview_reports_real_scope_coverage_and_gap")
	preview["scope_community_ids"].clear()
	preview["scope_covered_building_ids"].clear()
	check(city.snapshot() == before and Anchor.preview(city,route,source)["scope_community_ids"].size() == 2,"preview_is_read_only_and_independent")
	var forged := route.duplicate(true)
	forged["community_ids"] = ["east-1"]
	forged["covered_building_ids"] = []
	check(Anchor.preview(city,forged,source).get("covered_scope_community_ids",[]) == ["west-1"],"caller_cannot_forge_route_coverage")
	check(not bool(Anchor.preview(city,route,"charter-99999").get("accepted",false)),"unknown_source_rejects")
	var east_city := _city()
	var east_model := Model.new(east_city)
	var east_scope := east_model.submit({"kind":"charter","plan_id":"corridor","community_ids":["east-1"]})
	var east_source := "charter-%05d" % int(east_scope["event_id"])
	var east_before := east_city.snapshot()
	check(not bool(_submit(east_model,_route(east_city),east_source).get("accepted",false)) and east_city.snapshot() == east_before,"uncovered_source_rejects_without_world_or_rng_mutation")
	check(not bool(Anchor.preview(city,{"stop_positions":[city.nodes["west-1"],city.nodes["east-1"]]},source).get("accepted",false)),"anchor_does_not_bypass_missing_bridge")
	var plain := Model.from_state(model.capture_state())
	var anchored_request := _submit(model,route,source)
	var plain_request := _submit(plain,_route(plain.world))
	check(bool(anchored_request.get("accepted",false)) and bool(plain_request.get("accepted",false)),"anchor_and_ordinary_route_queue")
	var pending: Dictionary = city.pending_actions.filter(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line")[0]
	check(_identity(pending,source) and pending.get("covered_scope_community_ids",[]) == ["west-1"],"pending_preserves_source_and_actual_coverage")
	var local_choice := Model.from_state(model.capture_state())
	local_choice.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"]})
	check(bool(Anchor.source(local_choice.world,source).get("accepted",false)),"local_override_keeps_remaining_original_scope_source")
	check(not bool(Anchor.preview(local_choice.world,_route(local_choice.world),source).get("accepted",false)),"local_override_cannot_be_counted_as_old_charter_coverage")
	var remaining_route := local_choice.world.transit_plan_preview([local_choice.world.nodes["east-1"],local_choice.world.nodes["east-2"]])
	check(Anchor.preview(local_choice.world,remaining_route,source).get("covered_scope_community_ids",[]) == ["east-1"],"original_charter_can_anchor_only_its_remaining_scope")
	var source_copy := Model.from_state(model.capture_state())
	var replacement := source_copy.submit({"kind":"charter","plan_id":"compact","community_ids":["east-1","west-1"]})
	check(bool(replacement.get("accepted",false)) and not bool(Anchor.source(source_copy.world,source).get("accepted",false)),"replaced_pending_source_is_invalid")
	_boundary(source_copy)
	check(source_copy.world.authored_transit_lines.is_empty() and source_copy.world.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "planning_rejected" and str(event.get("charter_id","")) == source and int(event.get("event_id",-1)) == int(anchored_request["event_id"])),"boundary_rechecks_source_without_rebinding_route")
	var line_id := "player-line-%d" % int(anchored_request["event_id"])
	for entry: Dictionary in _saved_models(model,"pending"):
		var restored: Model = entry["model"]
		var label := str(entry["format"])
		var operation: Dictionary = restored.world.pending_actions.filter(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "transit_line")[0]
		check(_identity(operation,source) and bool(Anchor.source(restored.world,source).get("accepted",false)),label+"_pending_restores_exact_source")
		_boundary(restored)
		check(_identity(_record(restored.world.authored_transit_lines,line_id),source) and _identity(_record(restored.world.transit_lines,line_id),source) and _identity(_record(restored.world.events,line_id),source),label+"_pending_lands_one_associated_line_and_event")
	var frame := _boundary(model)
	_boundary(plain)
	check(_same_music_growth(city,plain.world),"association_does_not_change_rng_growth_resonance_or_vitality")
	check(city.transit_demand.is_empty() and city.transit_flow_pending.is_empty(),"anchor_creates_no_passenger_observations")
	var line := _record(city.transit_lines,line_id)
	var event := _record(city.events,line_id)
	check(_identity(line,source) and _identity(_record(city.authored_transit_lines,line_id),source) and _identity(event,source),"settled_intent_runtime_and_event_share_source")
	check(int(event.get("event_id",-1)) == int(anchored_request["event_id"]) and int(event.get("frame",-1)) == frame and event.get("coverage",{}).get("charter_id","") == source,"event_retains_operation_boundary_and_nested_contract")
	check(city.development_charters.back().get("card_refs",[]) == ["road_echo"] and bool(Anchor.source(city,source).get("accepted",false)),"settled_source_retains_real_plan_scope_and_card")
	var settled_model := Model.from_state(model.capture_state())
	for entry: Dictionary in _saved_models(settled_model,"settled"):
		var restored: Model = entry["model"]
		var label := str(entry["format"])
		check(_identity(_record(restored.world.authored_transit_lines,line_id),source) and _identity(_record(restored.world.transit_lines,line_id),source) and _identity(_record(restored.world.events,line_id),source),label+"_settled_restore_preserves_all_association_records")
		check(bool(_submit(restored,_route(restored.world),source).get("accepted",false)),label+"_restored_charter_can_anchor_another_route")
		_boundary(restored)
		check(restored.world.authored_transit_lines.size() == 2,label+"_restored_route_uses_normal_authored_lifecycle")
	var eventless := model.capture_state()
	eventless["world"]["events"] = eventless["world"]["events"].filter(func(item: Dictionary) -> bool: return str(item.get("id","")) != line_id)
	var rebuilt := Model.from_state(eventless)
	check(_identity(_record(rebuilt.world.events,line_id),source),"missing_derived_event_rebuilds_exact_charter_identity")
	model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1","east-1"]})
	check(not bool(Anchor.source(city,source).get("accepted",false)) and not bool(_submit(model,_route(city),source).get("accepted",false)),"new_scope_choice_rejects_old_source_before_settlement")
	_boundary(model)
	check(_identity(_record(city.transit_lines,line_id),source) and city.authored_transit_lines.size() == 1,"later_charter_keeps_existing_route_original_identity_and_service")
	check(not bool(Anchor.source(city,source).get("accepted",false)),"replaced_settled_source_rejects")
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
	print("ROUND177_TRANSIT_CHARTER_ANCHOR "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
