extends SceneTree
## Keeping is an immediate, source-checked withdrawal of one pending edit.
## It never edits the existing line or consumes a future structural event.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const Reuse = preload("res://scripts/world/public_site_reuse.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const EVIDENCE_PATH := "res://验证记录/round179_公交保留与改站/transit_line_keep.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var paths: Array[String] = []
var directory := ""

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

func _nodes(city: World,ids: Array) -> Array:
	var result: Array = []
	for id in ids: result.append(city.nodes[str(id)].duplicate())
	return result

func _operation(city: World,id: String,positions: Array = [],keeping := false) -> Dictionary:
	var original := Rework.candidate(city,id)
	return {"kind":"transit_line","edit_id":id,"source_revision":original.get("source_revision",""),
		"source_topology":original.get("source_topology",""),"stop_positions":positions.duplicate(true),"keep":keeping}

func _boundary(model: Model) -> void:
	model.render_block({},model.next_boundary-1,2,int(model.world.cfg["timing"]["sample_rate"]))

func _authored_equal(before: Dictionary,after: Dictionary) -> bool:
	for key in ["id","name","frame","event_id","charter_id","plan_id","scope_community_ids","stop_ids","retained_stop_ids","route_mode","revision","edited_frame","edit_event_id"]:
		if before.get(key) != after.get(key): return false
	return true

func _edit_event(city: World,event_id: int) -> bool:
	return city.events.any(func(event: Dictionary) -> bool:
		return str(event.get("kind","")) == "transit_line" and int(event.get("event_id",-1)) == event_id)

func _saved_models(model: Model,label: String) -> Array:
	var result: Array = []
	var captured := {"model":model.capture_state(),"renderer":{},"view":{}}
	var binary := Archive.save(captured,"Round179 "+label,directory)
	var binary_ok := bool(binary.get("ok",false))
	if binary_ok:
		paths.append(str(binary["path"]))
		var loaded := Archive.read(str(binary["path"]))
		binary_ok = bool(loaded.get("ok",false))
		if binary_ok: result.append({"format":"binary","model":Model.from_state(loaded["city"]["model"])})
	check(binary_ok,label+"_binary_save_and_read")
	var dna := Archive.export_dna(captured,directory+"/exports")
	var dna_ok := bool(dna.get("ok",false))
	if dna_ok:
		paths.append(str(dna["path"]))
		var loaded := Archive.read_dna(str(dna["path"]))
		dna_ok = bool(loaded.get("ok",false))
		if dna_ok: result.append({"format":"dna","model":Model.from_state(loaded["model"])})
	check(dna_ok,label+"_dna_save_and_read")
	return result

func _run() -> void:
	directory = "user://round179_transit_keep_%d" % Time.get_ticks_usec()
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_rework_starter("bright")
	var model := Model.new(city)
	var charter := model.submit({"kind":"charter","plan_id":"corridor","community_ids":["west-1","east-1"],"card_refs":["road_echo"]})
	var charter_id := "charter-%05d" % int(charter.get("event_id",-1))
	var created := model.submit({"kind":"transit_line","charter_id":charter_id,"stop_positions":_nodes(city,["west-1","west-2"]),"source_topology":city.network.topology})
	_boundary(model)
	var id := "player-line-%d" % int(created.get("event_id",-1))
	_record(city.authored_transit_lines,id)["name"] = "我的河谷回廊"
	var first_edit := model.submit(_operation(city,id,_nodes(city,["west-outer-3","west-outer-2","west-outer-1"])))
	_boundary(model)
	var other_created := model.submit({"kind":"transit_line","stop_positions":_nodes(city,["west-1","west-3"]),"source_topology":city.network.topology})
	_boundary(model)
	var other_id := "player-line-%d" % int(other_created.get("event_id",-1))
	check(bool(created.get("accepted",false)) and bool(first_edit.get("accepted",false)) and bool(other_created.get("accepted",false)) and int(_record(city.authored_transit_lines,id).get("revision",0)) == 1,"fixture_has_two_real_lines_and_existing_edit_history")
	var origin := _record(city.authored_transit_lines,id).duplicate(true)
	var stable := model.capture_state()
	var keep := _operation(city,id,[],true)
	var draft := _operation(city,id,_nodes(city,["west-1","west-2","west-3","west-1"]))
	var preview_before := city.snapshot()
	var preview := Rework.preview(city,keep)
	check(bool(preview.get("accepted",false)) and bool(preview.get("keep",false)) and not bool(preview.get("edit",true)) and preview.get("charter_id","") == charter_id and preview.get("stop_positions",[]) == Rework.candidate(city,id)["stop_positions"],"keep_preview_uses_real_original_route_and_historical_charter_without_draft")
	check(preview.get("coverage",{}) == preview.get("old_coverage",{}) and preview.get("old_coverage",{}) == preview.get("new_coverage",{}) and preview.get("added_covered_building_ids",[]).is_empty() and preview.get("removed_community_ids",[]).is_empty(),"keep_preview_reports_real_original_coverage_and_no_replacement_delta")
	preview["stop_positions"][0][0] += 0.5
	preview["scope_community_ids"].clear()
	preview["coverage"].clear()
	check(city.snapshot() == preview_before,"keep_preview_is_read_only_and_arrays_are_independent")
	var new_charter := model.submit({"kind":"charter","plan_id":"bluegreen","community_ids":["west-1","east-1"]})
	var house_id := str(city.buildings[0]["district_id"])
	var retune := model.submit({"kind":"retune","id":house_id,"midi":55})
	var public_candidate := Reuse.candidate(city,"west-civic")
	var public_use := model.submit({"kind":"park","reuse":true,"id":"west-civic","position":public_candidate["position"],"source_revision":public_candidate["source_revision"]})
	var seed: Dictionary = {}
	for lot in city.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if bool(city.placement(p).get("allowed",false)):
			seed = model.submit({"kind":"seed","position":[p.x,p.y],"midi":48})
			break
	check(bool(new_charter.get("accepted",false)) and bool(retune.get("accepted",false)) and bool(public_use.get("accepted",false)) and bool(seed.get("accepted",false)),"fixture_queues_independent_charter_seed_retune_and_public_use")
	var independent := city.pending_actions.duplicate(true)
	var edit := model.submit(draft)
	var sounds := model.sound_events.duplicate(true)
	var expected := city.snapshot()
	expected["pending_actions"] = independent.duplicate(true)
	expected["pending"] = independent[-1].duplicate(true)
	var result := model.submit(keep)
	check(bool(edit.get("accepted",false)) and bool(result.get("accepted",false)) and bool(result.get("kept",false)) and bool(result.get("changed",false)) and int(result.get("frame",0)) == -1 and result.get("id","") == id and result.get("edit_id","") == id and not result.has("event_id"),"formal_keep_is_immediate_without_event_identifier")
	check(city.snapshot() == expected,"formal_keep_changes_only_matching_pending_edit_and_legacy_mirror")
	check(model.sound_events == sounds and int(model.decisions[-1]["structure_frame"]) == -1 and int(model.decisions[-1]["sound_frame"]) == -1,"keep_preserves_pending_sound_and_records_no_sound_or_structure_frame")
	var repeated_before := model.capture_state()
	var repeated := model.submit(keep)
	check(bool(repeated.get("kept",false)) and not bool(repeated.get("changed",true)) and model.capture_state() == repeated_before,"repeated_keep_is_idempotent_and_leaves_the_entire_saved_model_unchanged")
	for entry: Dictionary in _saved_models(model,"kept"):
		var restored: Model = entry["model"]
		var label := str(entry["format"])
		check(_authored_equal(origin,_record(restored.world.authored_transit_lines,id)) and not restored.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("edit_id","")) == id) and restored.world.pending_actions.size() == independent.size(),label+"_kept_restore_retains_original_and_independent_queue")
		_boundary(restored)
		check(_authored_equal(origin,_record(restored.world.authored_transit_lines,id)) and not _edit_event(restored.world,int(edit["event_id"])),label+"_kept_restore_next_phrase_has_no_fake_edit")
	var keep_boundary := model.next_boundary
	_boundary(model)
	check(_authored_equal(origin,_record(city.authored_transit_lines,id)) and city.authored_transit_lines.size() == 2 and not _edit_event(city,int(edit["event_id"])),"next_phrase_preserves_line_identity_station_history_revision_and_creation_events")
	var seed_operation: Dictionary = independent.filter(func(op: Dictionary) -> bool: return str(op["kind"]) == "seed")[0]
	check(city.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "charter" and str(event.get("id","")) == "charter-%05d" % int(new_charter["event_id"])) and int(city.by_id[house_id]["current_midi"]) == 55 and str(_record(city.public_sites,"west-civic")["kind"]) == "park" and city.buildings.any(func(house: Dictionary) -> bool: return int(house.get("birth_frame",-1)) == keep_boundary and house.get("position",[]) == seed_operation["position"] and bool(house.get("family_anchor",false))),"independent_charter_retune_public_and_seed_still_land")
	var pending_model := Model.from_state(stable)
	var pending_edit := pending_model.submit(_operation(pending_model.world,id,_nodes(pending_model.world,["west-1","west-2","west-3","west-1"])))
	for entry: Dictionary in _saved_models(pending_model,"pending"):
		var restored: Model = entry["model"]
		var label := str(entry["format"])
		var accepted := restored.submit(_operation(restored.world,id,[],true))
		check(bool(accepted.get("kept",false)) and restored.world.pending_actions.is_empty() and restored.world.pending.is_empty(),label+"_restored_pending_edit_can_be_kept")
		_boundary(restored)
		check(_authored_equal(origin,_record(restored.world.authored_transit_lines,id)) and not _edit_event(restored.world,int(pending_edit["event_id"])),label+"_restored_pending_keep_cannot_resurrect_at_boundary")
	for variant: String in ["other_edit","new_line"]:
		var isolated := Model.from_state(stable)
		var operation := _operation(isolated.world,other_id,_nodes(isolated.world,["west-1","west-2","west-3","west-1"])) if variant == "other_edit" else {"kind":"transit_line","stop_positions":_nodes(isolated.world,["west-2","west-3"]),"source_topology":isolated.world.network.topology}
		var queued := isolated.submit(operation)
		var before := isolated.world.snapshot()
		var kept := isolated.submit(_operation(isolated.world,id,[],true))
		check(bool(queued.get("accepted",false)) and bool(kept.get("kept",false)) and isolated.world.snapshot() == before,variant+"_same_transit_slot_is_preserved_for_another_intent")
		_boundary(isolated)
		check(_authored_equal(origin,_record(isolated.world.authored_transit_lines,id)) and _edit_event(isolated.world,int(queued["event_id"])),variant+"_unrelated_route_still_lands_next_phrase")
	for field: String in ["source_revision","source_topology","edit_id"]:
		var invalid := keep.duplicate(true)
		invalid[field] = "invalid-source"
		var before := pending_model.world.snapshot()
		check(not bool(pending_model.submit(invalid).get("accepted",false)) and pending_model.world.snapshot() == before,field+"_stale_keep_rejects_without_canceling_pending_edit")
	_boundary(pending_model)
	var completed_before := pending_model.world.snapshot()
	check(not bool(pending_model.submit(keep).get("accepted",false)) and pending_model.world.snapshot() == completed_before,"a_landed_edit_expires_old_keep_source")
	var vanished := Model.from_state(stable)
	vanished.world.authored_transit_lines = vanished.world.authored_transit_lines.filter(func(intent: Dictionary) -> bool: return str(intent["id"]) != id)
	var vanished_before := vanished.world.snapshot()
	check(not bool(vanished.submit(keep).get("accepted",false)) and vanished.world.snapshot() == vanished_before,"removed_author_source_is_not_replaced_by_a_derived_line")
	var broken := Model.from_state(stable)
	var broken_edit := broken.submit(_operation(broken.world,id,_nodes(broken.world,["west-1","west-2","west-3","west-1"])))
	broken.world.roads.clear()
	broken.world.network.rebuild(broken.world.nodes,broken.world.roads,broken.world.terrain)
	var broken_keep := _operation(broken.world,id,[],true)
	var broken_origin := _record(broken.world.authored_transit_lines,id).duplicate(true)
	check(bool(broken_edit.get("accepted",false)) and not bool(broken.world.transit_plan_preview(Rework.candidate(broken.world,id)["stop_positions"]).get("accepted",false)) and bool(Rework.preview(broken.world,broken_keep).get("accepted",false)) and bool(broken.submit(broken_keep).get("kept",false)) and _record(broken.world.authored_transit_lines,id) == broken_origin and broken.world.pending_actions.is_empty(),"current_topology_keep_withdraws_edit_even_when_old_route_and_historical_stations_are_disconnected")
	var legacy := Model.from_state(stable)
	legacy.submit(_operation(legacy.world,id,_nodes(legacy.world,["west-1","west-2","west-3","west-1"])))
	legacy.world.pending_actions.clear()
	check(bool(legacy.submit(_operation(legacy.world,id,[],true)).get("kept",false)) and legacy.world.pending.is_empty(),"legacy_pending_only_mirror_cannot_resurrect_a_kept_edit")
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
	print("ROUND179_TRANSIT_LINE_KEEP "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
