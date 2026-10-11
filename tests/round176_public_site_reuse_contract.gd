extends SceneTree
## Existing public spaces can be reused without losing identity, authored
## geometry or capacity investment. Real requests, boundaries and both player
## save formats exercise the same World path used by the playable comparison.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Reuse = preload("res://scripts/world/public_site_reuse.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const SEED := "2026100900000062"
const EVIDENCE_PATH := "res://验证记录/round176_公共空间原位改用/public_site_reuse_contract.json"

var checks: Dictionary = {}
var failures: Array[String] = []
var saved_paths: Array[String] = []
var directory := ""

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _site(city: World,id: String) -> Dictionary:
	for item in city.public_sites:
		if str(item.get("id","")) == id: return item
	return {}

func _operation(city: World,id: String,kind: String) -> Dictionary:
	var candidate := Reuse.candidate(city,id)
	return {"kind":kind,"reuse":true,"id":id,"position":candidate.get("position",[]).duplicate(),
		"source_revision":str(candidate.get("source_revision",""))}

func _boundary(model: Model) -> int:
	var frame := model.next_boundary
	model.render_block({},frame-1,2,int(model.world.cfg["timing"]["sample_rate"]))
	return frame

func _candidate(city: World) -> Dictionary:
	for lot in city.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var current := city.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if not current.is_empty() and bool(current.get("allowed",false)) and not current.has("public_id") and not Planning.public_access(city,current).is_empty(): return current
	return {}

func _same_authored_site(before: Dictionary,after: Dictionary) -> bool:
	for key in ["id","position","polygon","footprint_components","target_polygons","hole_polygons","target_holes",
			"community_id","target_community_ids","entrance","road_id","access_path","name","player_planned",
			"source_site_id","source_lot_ids","source_reservation_id","anchor_id","created_phrase","service_level"]:
		# JSON rounds the doubles inside coordinate arrays. Compare their actual
		# engine positions; packed footprint geometry and all identity stay exact.
		if key in ["position","entrance"] and _same_engine_point(before.get(key),after.get(key)): continue
		if before.get(key) != after.get(key):
			print("ROUND176_AUTHORED_FIELD "+JSON.stringify({"field":key,"before":str(before.get(key)),"after":str(after.get(key)),"before_type":typeof(before.get(key)),"after_type":typeof(after.get(key))}))
			return false
	return true

func _same_engine_point(before: Variant,after: Variant) -> bool:
	if before == after: return true
	if not before is Array or not after is Array or before.size() != 2 or after.size() != 2: return false
	return Vector2(float(before[0]),float(before[1])) == Vector2(float(after[0]),float(after[1]))

func _same_existing_houses(before: Array,city: World) -> bool:
	for building: Dictionary in before:
		var current: Dictionary = city.by_id.get(str(building["district_id"]),{})
		if current.is_empty() or current.get("position") != building.get("position") or current.get("current_midi") != building.get("current_midi"): return false
	return true

func _restore_pending(model: Model,label: String) -> Array:
	var result: Array = []
	var captured := {"model":model.capture_state(),"renderer":{},"view":{}}
	var binary := Archive.save(captured,"Round176 "+label,directory)
	check(bool(binary.get("ok",false)),label+"_binary_save_writes")
	if bool(binary.get("ok",false)):
		saved_paths.append(str(binary["path"]))
		var loaded := Archive.read(str(binary["path"]))
		check(bool(loaded.get("ok",false)),label+"_binary_save_reads")
		if bool(loaded.get("ok",false)): result.append({"format":"binary","model":Model.from_state(loaded["city"]["model"])})
	var dna := Archive.export_dna(captured,directory+"/exports")
	check(bool(dna.get("ok",false)),label+"_json_dna_writes")
	if bool(dna.get("ok",false)):
		saved_paths.append(str(dna["path"]))
		var loaded := Archive.read_dna(str(dna["path"]))
		check(bool(loaded.get("ok",false)),label+"_json_dna_reads")
		if bool(loaded.get("ok",false)): result.append({"format":"json_dna","model":Model.from_state(loaded["model"])})
	return result

func _complex_fixture() -> Dictionary:
	var city := World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var model := Model.new(city)
	var source: Dictionary = {}
	var components: Array[PackedVector2Array] = []
	var holes: Array[PackedVector2Array] = []
	for lot in city.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate := city.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		var first := NeighborhoodPlan.box(p+Vector2(-0.20,0),Vector2(0.08,0.08))
		var second := NeighborhoodPlan.box(p+Vector2(0.20,0),Vector2(0.08,0.08))
		if not Planning._contains_polygon(candidate["polygon"],first) or not Planning._contains_polygon(candidate["polygon"],second): continue
		if Planning.public_access(city,{"polygon":first,"position":[p.x-0.20,p.y]}).is_empty() or Planning.public_access(city,{"polygon":second,"position":[p.x+0.20,p.y]}).is_empty(): continue
		source = candidate
		components = [first,second]
		holes = [NeighborhoodPlan.box(p+Vector2(-0.20,0),Vector2(0.025,0.025))]
		break
	check(not source.is_empty(),"complex_fixture_has_real_empty_lot")
	if source.is_empty(): return {}
	var reservation := model.submit({"kind":"reserve","position":source["position"].duplicate()})
	check(bool(reservation.get("accepted",false)),"complex_fixture_reserves_through_real_request")
	_boundary(model)
	var reservation_id := "reservation-%05d" % int(reservation.get("event_id",-1))
	var preview := PartialPublic.preview_footprints(city,reservation_id,"civic",components,holes)
	check(bool(preview.get("accepted",false)),"complex_fixture_accepts_two_components_and_hole")
	if not bool(preview.get("accepted",false)): return {}
	var submitted := model.submit({"kind":"civic","partial":true,"source_reservation_id":reservation_id,
		"target_polygons":components,"target_holes":holes,"source_revision":preview["source_revision"]})
	check(bool(submitted.get("accepted",false)),"complex_fixture_queues_authored_shape")
	_boundary(model)
	var id := ""
	for item in city.public_sites:
		if str(item.get("source_reservation_id","")) == reservation_id: id = str(item["id"]); break
	check(not id.is_empty(),"complex_fixture_lands_authored_shape")
	if id.is_empty(): return {}
	check(bool(model.submit({"kind":"civic","id":id}).get("accepted",false)),"complex_fixture_invests_in_service_level")
	_boundary(model)
	return {"model":model,"id":id}

func _run() -> void:
	directory = "user://round176_public_reuse_%d" % Time.get_ticks_usec()
	var city := World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var model := Model.new(city)
	check(bool(model.submit({"kind":"civic","id":"west-civic"}).get("accepted",false)),"existing_civic_investment_queues")
	var authored := model.submit({"kind":"transit_line","stop_positions":[city.nodes["west-1"].duplicate(),city.nodes["west-2"].duplicate()],"source_topology":city.network.topology})
	check(bool(authored.get("accepted",false)),"real_authored_line_queues")
	_boundary(model)
	var before := _site(city,"west-civic").duplicate(true)
	check(int(before.get("service_level",0)) == 2,"real_civic_expansion_investment_lands")
	var before_houses := city.buildings.duplicate(true)
	var before_count := city.public_sites.size()
	var before_world := city.snapshot()
	var candidate := Reuse.candidate(city,"west-civic")
	check(bool(candidate.get("allowed",false)) and candidate.get("reuse",false) and candidate.get("public_id","") == "west-civic" and candidate.get("source_site_id","") == "west-civic","active_site_has_separate_reuse_candidate")
	check(candidate.get("current_kind","") == "civic" and not str(candidate.get("source_revision","")).is_empty(),"candidate_records_real_use_and_revision")
	candidate["position"][0] = float(candidate["position"][0])+1.0
	candidate["polygon"][0] += Vector2.ONE
	check(city.snapshot() == before_world,"candidate_arrays_are_independent_of_world")
	var p := Vector2(float(before["position"][0]),float(before["position"][1]))
	check(city.planning_candidate(p).is_empty(),"active_site_stays_excluded_from_ordinary_empty_land")
	var stale := _operation(city,"west-civic","park")
	stale["source_revision"] = "old-preview"
	check(not bool(model.submit(stale).get("accepted",false)) and city.snapshot() == before_world,"stale_revision_request_rejects_without_mutation")
	var shifted := _operation(city,"west-civic","park")
	shifted["position"][0] += 0.5
	check(not bool(model.submit(shifted).get("accepted",false)) and city.snapshot() == before_world,"reuse_cannot_move_the_facility")
	var open_site := _candidate(city)
	check(not open_site.is_empty(),"fixture_has_an_unrelated_real_public_slot")
	if not open_site.is_empty(): model.submit({"kind":"reserve","position":open_site["position"].duplicate()})
	model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"]})
	var queued := model.submit(_operation(city,"west-civic","park"))
	check(bool(queued.get("accepted",false)),"reuse_queues_at_existing_phrase_boundary")
	check(city.pending_actions.filter(func(op: Dictionary) -> bool: return op.has("position") and str(op.get("kind","")) in ["park","civic","reserve","relocate_public"]).size() == 1 and city.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "charter"),"reuse_replaces_public_slot_and_preserves_unrelated_charter")
	check(_site(city,"west-civic")["kind"] == "civic" and city.public_sites.size() == before_count,"queued_reuse_does_not_change_live_site")
	var pending_state := model.capture_state()
	var stale_boundary := Model.from_state(pending_state)
	_site(stale_boundary.world,"west-civic")["service_level"] = 3
	var stale_frame := _boundary(stale_boundary)
	check(_site(stale_boundary.world,"west-civic")["kind"] == "civic" and stale_boundary.world.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "planning_rejected" and bool(event.get("reuse",false)) and int(event.get("event_id",-1)) == int(queued["event_id"]) and int(event.get("frame",-1)) == stale_frame),"boundary_rechecks_revision_and_reports_rejection")
	var boundary := _boundary(model)
	var after := _site(city,"west-civic")
	check(after["kind"] == "park" and city.public_sites.size() == before_count,"boundary_reuses_one_stable_facility_record")
	check(_same_authored_site(before,after),"reuse_preserves_identity_land_provenance_and_investment")
	check(_same_existing_houses(before_houses,city),"reuse_preserves_existing_house_notes_and_positions")
	check(int(after.get("service_capacity",-1)) == 0 and after.get("served",[]).is_empty(),"park_use_recomputes_real_cultural_service")
	check(not city.transit_lines.any(func(line: Dictionary) -> bool: return str(line.get("id","")) == "valley-line") and city.authored_transit_lines.size() == 1 and city.transit_lines.any(func(line: Dictionary) -> bool: return str(line.get("id","")) == str(city.authored_transit_lines[0]["id"])),"new_use_removes_civic_derived_line_and_keeps_authored_line")
	check(city.events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "park" and bool(event.get("reuse",false)) and str(event.get("id","")) == "west-civic" and str(event.get("source_site_id","")) == "west-civic" and str(event.get("previous_kind","")) == "civic" and int(event.get("event_id",-1)) == int(queued["event_id"]) and int(event.get("frame",-1)) == boundary),"reuse_event_has_stable_identity_operation_and_boundary")
	check(model.transition_total > 0 and model.synth.last_voice_count <= 70,"reuse_enters_existing_structural_audio_seam_and_voice_budget")
	var restored_default := Model.from_state(model.capture_state())
	check(bool(restored_default.submit(_operation(restored_default.world,"west-civic","civic")).get("accepted",false)),"saved_default_site_can_return_to_civic")
	_boundary(restored_default)
	check(int(_site(restored_default.world,"west-civic").get("service_level",0)) == 2 and int(_site(restored_default.world,"west-civic").get("service_capacity",0)) == 36,"returning_to_civic_restores_capacity_investment")
	check(bool(restored_default.submit(_operation(restored_default.world,"west-civic","civic")).get("accepted",false)),"same_use_reaffirmation_queues")
	_boundary(restored_default)
	check(int(_site(restored_default.world,"west-civic").get("service_level",0)) == 2,"same_use_reuse_does_not_expand_civic")

	var complex := _complex_fixture()
	if not complex.is_empty():
		var shape_model: Model = complex["model"]
		var shape_id := str(complex["id"])
		var shape_before := _site(shape_model.world,shape_id).duplicate(true)
		var shape_count := shape_model.world.public_sites.size()
		check(shape_before.get("footprint_components",[]).size() == 2 and shape_before.get("hole_polygons",[]).size() == 1 and int(shape_before.get("service_level",0)) == 2,"authored_fixture_has_components_hole_and_investment")
		check(bool(shape_model.submit(_operation(shape_model.world,shape_id,"park")).get("accepted",false)),"authored_complex_reuse_queues")
		for entry: Dictionary in _restore_pending(shape_model,"complex_pending"):
			var restored: Model = entry["model"]
			var format := str(entry["format"])
			var pending: Dictionary = restored.world.pending_actions.filter(func(op: Dictionary) -> bool: return bool(op.get("reuse",false)))[0]
			check(pending.get("source_revision","") == Reuse.candidate(restored.world,shape_id).get("source_revision","") and pending.get("footprint_components",[]) == shape_before.get("footprint_components",[]) and pending.get("hole_polygons",[]) == shape_before.get("hole_polygons",[]),format+"_pending_restores_revision_components_and_hole")
			_boundary(restored)
			var reused := _site(restored.world,shape_id)
			check(reused.get("kind","") == "park" and _same_authored_site(shape_before,reused) and restored.world.public_sites.size() == shape_count,format+"_pending_lands_without_losing_authored_space")
			if format == "json_dna":
				check(bool(restored.submit(_operation(restored.world,shape_id,"civic")).get("accepted",false)),"json_dna_restored_site_can_choose_a_new_use")
				_boundary(restored)
				var civic := _site(restored.world,shape_id)
				check(civic.get("kind","") == "civic" and int(civic.get("service_capacity",0)) == 36 and _same_authored_site(shape_before,civic),"json_dna_reuse_roundtrip_keeps_full_footprint_and_capacity")
	_finish()

func _finish() -> void:
	for path in saved_paths: DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory+"/exports")
	DirAccess.remove_absolute(directory)
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE_PATH.get_base_dir()))
	var file := FileAccess.open(EVIDENCE_PATH,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  ")+"\n")
		file.close()
	print("ROUND176_PUBLIC_SITE_REUSE_CONTRACT "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
