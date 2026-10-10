extends SceneTree
## A public outer ring preserves its empty interior as a plannable parcel.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const FabricRelations = preload("res://scripts/world/fabric_relations.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const Relocation = preload("res://scripts/world/public_site_relocation.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _find_anchor(city: World) -> Dictionary:
	for y in range(-36,37):
		for x in range(-36,37):
			var p := Vector2(float(x)*0.25,float(y)*0.25)
			var polygon := NeighborhoodPlan.box(p,Vector2(0.42,0.42))
			if not city.terrain.valid_footprint(polygon): continue
			var candidate := {"polygon":polygon,"position":[p.x,p.y]}
			if not Planning.site_reason(city,candidate).is_empty() or Planning.public_access(city,candidate).is_empty(): continue
			return {"position":p,"polygon":polygon}
	return {}

func _site(city: World,reservation_id: String) -> Dictionary:
	for site in city.public_sites:
		if str(site.get("source_reservation_id","")) == reservation_id: return site
	return {}

func _run() -> void:
	var city := World.new("2026101100000162",true,"river_valley")
	city.build_starter("bright")
	var anchor := _find_anchor(city)
	_check(not anchor.is_empty(),"finds_accessible_hole_target")
	if anchor.is_empty():
		_finish()
		return
	var p: Vector2 = anchor["position"]
	var outer: PackedVector2Array = anchor["polygon"]
	var hole := NeighborhoodPlan.box(p,Vector2(0.14,0.14))
	var source := NeighborhoodPlan.box(p,Vector2(1.2,1.2))
	var reservation_id := "round162-reservation"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round162-source","polygon":source,"position":[p.x,p.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var preview := PartialPublic.preview_footprints(city,reservation_id,"park",[outer],[hole])
	if not bool(preview.get("accepted",false)): print("ROUND162_PREVIEW_REJECT ",preview.get("reason",""))
	_check(bool(preview.get("accepted",false)),"accepts_outer_ring_with_one_hole")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	_check(preview.get("hole_polygons",[]) == [hole] and preview.get("target_holes",[]) == [hole],"preview_preserves_hole_schema")
	_check(is_equal_approx(float(preview["source_area"]),float(preview["target_area"])+float(preview["remaining_area"])),"hole_area_conserves_source")
	_check(is_equal_approx(float(preview["target_area"]),Planning.polygon_area(outer)-Planning.polygon_area(hole)),"target_area_excludes_hole")
	_check(preview["remaining_polygons"].has(hole),"hole_becomes_simple_residual_parcel")
	var raw_position: Array = preview["target_position"]
	var access_start := Vector2(float(raw_position[0]),float(raw_position[1]))
	_check(not Geometry2D.is_point_in_polygon(access_start,hole),"public_access_starts_outside_hole")
	var outside := NeighborhoodPlan.box(p+Vector2(0.5,0),Vector2(0.1,0.1))
	_check(not bool(PartialPublic.preview_footprints(city,reservation_id,"park",[outer],[outside]).get("accepted",false)),"rejects_hole_outside_outer_ring")
	var touching := NeighborhoodPlan.box(p+Vector2(0.28,0),Vector2(0.14,0.14))
	_check(not bool(PartialPublic.preview_footprints(city,reservation_id,"park",[outer],[touching]).get("accepted",false)),"rejects_hole_touching_outer_ring")
	var overlapping := NeighborhoodPlan.box(p+Vector2(0.1,0),Vector2(0.14,0.14))
	_check(not bool(PartialPublic.preview_footprints(city,reservation_id,"park",[outer],[hole,overlapping]).get("accepted",false)),"rejects_overlapping_holes")
	# A second component's empty interior must never cancel an occupied first
	# component when each component is validated independently.
	var separate: PackedVector2Array = PackedVector2Array()
	for offset in [Vector2(0.75,0),Vector2(-0.75,0),Vector2(0,0.75),Vector2(0,-0.75)]:
		var candidate_polygon := NeighborhoodPlan.box(p+offset,Vector2(0.05,0.05))
		var candidate := {"polygon":candidate_polygon,"reservation_id":reservation_id,"position":[p.x+offset.x,p.y+offset.y]}
		if Planning.site_reason(city,candidate).is_empty() and not Planning.public_access(city,candidate).is_empty():
			separate = candidate_polygon
			break
	_check(not separate.is_empty(),"finds_separate_component_for_hole_occupancy_audit")
	if not separate.is_empty():
		city.public_sites.append({"id":"round162-occupancy","polygon":separate,"footprint_components":[separate,hole],"position":[p.x,p.y],"active":true})
		city._refresh_parcel_index()
		var cross_component := PartialPublic.preview_footprints(city,reservation_id,"park",[separate,outer],[hole])
		_check(not bool(cross_component.get("accepted",false)) and str(cross_component.get("reason","")).contains("占地"),"other_component_hole_cannot_mask_occupied_component")
		city.public_sites = city.public_sites.filter(func(candidate: Dictionary)->bool: return str(candidate.get("id","")) != "round162-occupancy")
		city._refresh_parcel_index()
	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"park","partial":true,"source_reservation_id":reservation_id,"target_polygons":[outer],"target_holes":[hole]})
	_check(bool(queued.get("accepted",false)),"hole_request_queues")
	_check(city.pending_actions[0].get("hole_polygons",[]) == [hole],"pending_preserves_holes")
	var restored_pending := Model.from_state(model.capture_state())
	_check(restored_pending.world.pending_actions[0].get("target_holes",[]) == [hole],"pending_save_restores_holes")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	var site := _site(city,reservation_id)
	_check(not site.is_empty(),"hole_site_commits_at_boundary")
	_check(site.get("hole_polygons",[]) == [hole],"site_preserves_hole_polygons")
	_check(city.public_at(p).is_empty(),"public_at_excludes_hole")
	var ring_point := p+Vector2(0.28,0)
	_check(str(city.public_at(ring_point).get("id","")) == str(site.get("id","")),"public_at_hits_ring")
	var residual := Planning.reservation_at(city,p)
	_check(not residual.is_empty() and str(residual.get("parent_reservation_id","")) == reservation_id,"hole_residual_is_selectable_with_lineage")
	var tiny := NeighborhoodPlan.box(p,Vector2(0.05,0.05))
	_check(Planning.exclusion(city,tiny,str(residual.get("reservation_id",""))).is_empty(),"hole_is_not_public_occupancy")
	_check(not FabricRelations.reserved(city,p) and FabricRelations.reserved(city,ring_point),"fabric_reservation_excludes_hole")
	var next := PartialPublic.preview_footprints(city,str(residual.get("reservation_id","")),"civic",[tiny])
	_check(bool(next.get("accepted",false)),"hole_residual_can_continue_public_planning")
	var event: Dictionary = {}
	for candidate in city.events:
		if bool(candidate.get("partial",false)) and str(candidate.get("source_reservation_id","")) == reservation_id: event = candidate
	_check(event.get("hole_polygons",[]) == [hole],"event_preserves_hole_geometry")
	var restored := Model.from_state(model.capture_state())
	_check(_site(restored.world,reservation_id).get("hole_polygons",[]) == [hole] and restored.world.public_at(p).is_empty(),"save_restores_hole_hit_testing")
	var directory := "user://round162_hole_%d" % Time.get_ticks_usec()
	var exported := Archive.export_dna({"model":model.capture_state(),"renderer":{},"view":{}},directory)
	_check(bool(exported.get("ok",false)),"dna_exports_holes")
	var dna := Archive.read_dna(str(exported.get("path",""))) if bool(exported.get("ok",false)) else {}
	_check(bool(dna.get("ok",false)),"dna_reads_holes")
	if bool(dna.get("ok",false)):
		var json_restored := Model.from_state(dna["model"])
		_check(_site(json_restored.world,reservation_id).get("hole_polygons",[]) == [hole] and json_restored.world.public_at(p).is_empty(),"json_dna_restores_hole_geometry")
		_check(json_restored.world.events.any(func(candidate: Dictionary)->bool: return bool(candidate.get("partial",false)) and candidate.get("hole_polygons",[]) == [hole]),"json_dna_restores_hole_event")
	# Move the completed ring on a clone without the surrounding source parcels.
	# This exercises the normal relocation preview/commit contract rather than
	# calling its translation helper in isolation.
	var moved_city := Model.from_state(model.capture_state()).world
	moved_city.planning_reservations.clear()
	moved_city._refresh_parcel_index()
	var relocation: Dictionary = {}
	for y in range(-8,9):
		for x in range(-8,9):
			if x == 0 and y == 0: continue
			var candidate := Relocation.preview(moved_city,str(site["id"]),p+Vector2(float(x)*0.15,float(y)*0.15))
			if bool(candidate.get("accepted",false)):
				relocation = candidate
				break
		if not relocation.is_empty(): break
	_check(not relocation.is_empty(),"hole_relocation_finds_legal_position")
	if not relocation.is_empty():
		_check(relocation.get("target_holes",[]).size() == 1,"hole_relocation_preserves_hole_preview")
		var move_operation := relocation.duplicate(true)
		move_operation["id"] = site["id"]
		var moved := Relocation.commit(moved_city,move_operation,boundary+1)
		_check(bool(moved.get("accepted",false)),"hole_relocation_commits")
		var moved_site := _site(moved_city,reservation_id)
		var moved_hole: PackedVector2Array = moved_site.get("hole_polygons",[])[0]
		var moved_hole_center := Planning.bounds(moved_hole).get_center()
		_check(moved_city.public_at(moved_hole_center).is_empty(),"hole_relocation_keeps_empty_interior")
		_check(moved_city.events.back().get("hole_polygons",[]) == moved_site.get("hole_polygons",[]),"hole_relocation_event_preserves_holes")
	_finish()

func _finish() -> void:
	print("ROUND162_HOLE_PUBLIC_FOOTPRINT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
