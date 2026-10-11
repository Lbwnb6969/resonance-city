extends SceneTree
## Round 169 planning contract: a station's real catchment seeds the ordinary
## charter -> variation card -> community scope flow, while the seed remains a
## transient UI suggestion and never becomes saved world/DNA state.

const TransitPlanning = preload("res://scripts/world/transit_planning.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Archive = preload("res://scripts/world/city_archive.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _road_candidates(demo: Control) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var seen: Array[String] = []
	for road in demo.shown_world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var stop: Dictionary = TransitPlanning.stop_preview(demo.model.world,path[path.size()/2])
		if not bool(stop.get("accepted",false)): continue
		var id := str(stop.get("id",""))
		if id.is_empty() or seen.has(id): continue
		seen.append(id)
		result.append(Vector2(float(stop["position"][0]),float(stop["position"][1])))
	return result

func _find_route(demo: Control,candidates: Array[Vector2]) -> Array[Vector2]:
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			for k in range(j+1,candidates.size()):
				var preview: Dictionary = TransitPlanning.preview(demo.model.world,[candidates[i],candidates[j],candidates[k]])
				if bool(preview.get("accepted",false)): return [candidates[i],candidates[j],candidates[k]]
	return []

func _settle_pending(demo: Control) -> bool:
	if demo.model.world.pending_actions.is_empty(): return false
	var frame := int(demo.model.world.pending_actions[0].get("frame",-1))
	if frame < 0: return false
	demo.model.world.settle(frame)
	demo.shown_world = demo.model.world
	return true

func _find_public_candidate(world: RefCounted,scope: Array) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","" )).is_empty(): continue
		if not scope.has(str(lot.get("community_id",""))): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate: Dictionary = world.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)): continue
		if not candidate.has("public_id") and not candidate.has("reservation_id") and not Planning.public_access(world,candidate).is_empty():
			return candidate
	return {}

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)

	var candidates := _road_candidates(demo)
	var route: Array[Vector2] = _find_route(demo,candidates)
	check(route.size() == 3,"station_scope_fixture_finds_real_route")
	if route.size() != 3:
		demo.queue_free()
		await process_frame
		quit(1)
		return
	demo._verb("plan_transit")
	for position in route: demo._append_transit_stop(position)
	demo._submit_transit_route()
	check(_settle_pending(demo),"station_scope_fixture_settles_authored_line")
	var station: Dictionary = demo._transit_station_at(route[1])
	var record: Dictionary = station.get("record",{})
	var covered_communities: Array = []
	for raw_id in record.get("community_ids",[]):
		var id := str(raw_id)
		if demo.model.world.communities.has(id) and not covered_communities.has(id): covered_communities.append(id)
	covered_communities.sort()
	check(not str(station.get("id","" )).is_empty(),"station_scope_fixture_keeps_stable_station_id")
	check(not covered_communities.is_empty(),"station_scope_fixture_has_real_community_catchment")
	if covered_communities.is_empty():
		demo.queue_free()
		await process_frame
		quit(1)
		return

	var guide = demo.planning_guide
	var before_open: Dictionary = demo.model.world.snapshot()
	guide.open_tool_from_transit_station(station)
	check(guide.stage == "charter" and guide.opened,"station_scope_opens_normal_charter_flow")
	check(guide.scope_seed == covered_communities,"station_catchment_seeds_only_real_communities")
	check(str(guide.scope_source.get("kind","")) == "transit_station" and str(guide.scope_source.get("station_id","")) == str(station.get("id","")),"station_scope_source_keeps_station_identity")
	check(demo.model.world.snapshot() == before_open,"opening_station_scope_does_not_mutate_world")
	guide.choose_plan("corridor")
	var card_id := str(guide.drawn_card_ids[0]) if not guide.drawn_card_ids.is_empty() else ""
	guide.choose_card(card_id)
	check(guide.stage == "scope" and guide.scope == covered_communities,"plan_and_card_preserve_station_scope_seed")
	check(not card_id.is_empty(),"station_scope_flow_keeps_drawn_card")

	guide.commit_scope()
	var charter_pending: Dictionary = demo.model.world.pending_actions.back() if not demo.model.world.pending_actions.is_empty() else {}
	check(demo.model.world.development_charters.is_empty(),"station_scope_charter_waits_for_phrase_boundary")
	check(charter_pending.get("kind","") == "charter" and charter_pending.get("community_ids",[]) == covered_communities,"station_scope_queues_canonical_charter_scope")
	check(charter_pending.get("card_refs",[]) == [card_id],"station_scope_queues_selected_variation_card")
	check(not charter_pending.has("scope_source") and not charter_pending.has("station_scope_source") and not charter_pending.has("scope_seed"),"transient_station_scope_does_not_enter_pending_operation")

	var candidate: Dictionary = _find_public_candidate(demo.model.world,covered_communities)
	check(not candidate.is_empty(),"station_scope_catchment_has_public_anchor_candidate")
	var anchor_result := {}
	if not candidate.is_empty():
		anchor_result = demo.model.submit({"kind":"park","position":candidate["position"].duplicate()})
	check(bool(anchor_result.get("accepted",false)),"station_scope_public_anchor_queues_through_existing_contract")
	check(demo.model.world.public_sites.all(func(site: Dictionary) -> bool: return not bool(site.get("active",false)) or str(site.get("id","")) != "planning"),"station_scope_anchor_waits_for_phrase_boundary")
	check(demo.model.world.development_charters.is_empty(),"station_scope_charter_still_waits_before_boundary")
	if not demo.model.world.pending_actions.is_empty():
		var boundary := int(demo.model.world.pending_actions[0].get("frame",demo.model.next_boundary))
		demo.model.world.settle(boundary)
	check(demo.model.world.development_charters.size() == 1,"station_scope_charter_commits_at_boundary")
	check(demo.model.world.development_charters[0].get("community_ids",[]) == covered_communities and demo.model.world.development_charters[0].get("card_refs",[]) == [card_id],"station_scope_committed_charter_keeps_scope_and_card")

	var model_state: Dictionary = demo.model.capture_state()
	var directory := "user://round169_station_scope_%d" % Time.get_ticks_usec()
	var exported := Archive.export_dna({"model":model_state,"renderer":{},"view":{}},directory)
	check(bool(exported.get("ok",false)),"station_scope_dna_exports")
	if bool(exported.get("ok",false)):
		var path := str(exported["path"])
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var plan: Dictionary = payload.get("plan",{}) if payload is Dictionary else {}
		var serialized := FileAccess.get_file_as_string(path)
		check(plan.get("development_charters",[]).size() == 1,"station_scope_dna_keeps_committed_charter")
		check(not plan.has("scope_source") and not plan.has("station_scope_source") and not plan.has("scope_seed"),"station_scope_dna_omits_transient_ui_seed")
		check(not serialized.contains("scope_source") and not serialized.contains("station_scope_source") and not serialized.contains("scope_seed"),"station_scope_serialization_has_no_transient_seed")
		var imported := Archive.read_dna(path)
		check(bool(imported.get("ok",false)),"station_scope_dna_reads_back")
		if bool(imported.get("ok",false)):
			var restored = demo.model.from_state(imported["model"])
			var restored_charter: Dictionary = restored.world.development_charters[0] if not restored.world.development_charters.is_empty() else {}
			var current_charter: Dictionary = demo.model.world.development_charters[0] if not demo.model.world.development_charters.is_empty() else {}
			check(restored.world.development_charters.size() == 1 and restored_charter.get("community_ids",[]) == current_charter.get("community_ids",[]) and restored_charter.get("plan_id","") == current_charter.get("plan_id","") and restored_charter.get("card_refs",[]) == current_charter.get("card_refs",[]),"station_scope_dna_restore_keeps_committed_charter")
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)

	var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"station_id":station.get("id",""),"community_ids":covered_communities}
	print("ROUND169_STATION_SCOPE_PLANNING_CONTRACT ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
