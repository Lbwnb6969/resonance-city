extends SceneTree
## P10 partial public conversion contract: a reserved rectangle can become one
## real public footprint while its residual parcels remain available.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _find_source(city: World) -> Dictionary:
	for lot in city.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var center := Planning.bounds(lot["polygon"]).get_center()
		var candidate := {"source_site_id":str(lot["id"]),"polygon":lot["polygon"],"position":[center.x,center.y]}
		if not Planning.site_reason(city,candidate).is_empty(): continue
		if Planning.public_access(city,candidate).is_empty(): continue
		return {"lot":lot,"center":center}
	return {}

func _find_preview(city: World,reservation_id: String,kind: String,source: PackedVector2Array) -> Dictionary:
	var center := Planning.bounds(source).get_center()
	for y in range(-8,9):
		for x in range(-8,9):
			var target := center+Vector2(float(x),float(y))*0.12
			var preview := PartialPublic.preview(city,reservation_id,kind,target)
			if bool(preview.get("accepted",false)): return preview
	return {}

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	var source := _find_source(city)
	_check(not source.is_empty(),"finds_empty_road_accessible_lot")
	if source.is_empty():
		_finish()
		return
	var lot: Dictionary = source["lot"]
	var center: Vector2 = source["center"]
	var source_id := "reservation-round155"
	var source_polygon: PackedVector2Array = lot["polygon"].duplicate()
	city.planning_reservations.append({"id":source_id,"reservation_id":source_id,"source_site_id":lot["id"],"polygon":source_polygon,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var preview := _find_preview(city,source_id,"civic",source_polygon)
	_check(not preview.is_empty(),"finds_legal_partial_civic_footprint")
	if preview.is_empty():
		_finish()
		return
	_check(preview.get("target_polygon",PackedVector2Array()).size() == 4,"preview_has_rectangular_target")
	_check(int(preview.get("remaining_count",0)) > 0 and preview.get("remaining_polygons",[]).size() > 0,"preview_keeps_residual_polygons")
	var residual_area := 0.0
	for residual in preview.get("remaining_polygons",[]): residual_area += PartialPublic._polygon_area(residual)
	var source_area := PartialPublic._polygon_area(source_polygon)
	var target_area := PartialPublic._polygon_area(preview["target_polygon"])
	_check(is_equal_approx(source_area,target_area+residual_area),"residual_area_conserves_reserved_space")
	_check(preview.get("target_access_path",PackedVector2Array()).size() >= 2 and not str(preview.get("road_id","")).is_empty(),"preview_keeps_real_road_access")
	var before_reservation := city.planning_reservations[0].duplicate(true)
	var model := Model.new(city,1.3409036)
	var rejected := model.submit({"kind":"civic","partial":true,"source_reservation_id":source_id,"position":preview["target_position"],"source_revision":"stale"})
	_check(not bool(rejected.get("accepted",false)),"partial_request_rejects_stale_preview")
	_check(city.planning_reservations.size() == 1 and city.planning_reservations[0]["polygon"] == before_reservation["polygon"],"stale_request_does_not_mutate_reservation")
	var queued := model.submit({"kind":"civic","partial":true,"source_reservation_id":source_id,"position":preview["target_position"],"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"partial_request_queues_through_audio_model")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	var before_boundary := model.presentation_world(boundary-1)
	_check(not before_boundary.public_sites.any(func(item: Dictionary)->bool:return str(item.get("source_reservation_id","")) == source_id),"partial_site_hidden_before_boundary")
	_check(before_boundary.planning_reservations.size() == 1 and str(before_boundary.planning_reservations[0].get("reservation_id","")) == source_id,"reservation_stays_until_boundary")
	model.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for candidate in city.public_sites:
		if str(candidate.get("source_reservation_id","")) == source_id: site = candidate
	_check(not site.is_empty(),"partial_site_settles_at_phrase_boundary")
	_check(str(site.get("kind","")) == "civic" and bool(site.get("active",false)),"partial_site_is_active_civic")
	_check(str(site.get("source_reservation_id","")) == source_id,"partial_site_keeps_source_reservation_id")
	_check(city.planning_reservations.size() == int(preview["remaining_count"]),"residual_reservations_replace_source")
	_check(not city.planning_reservations.any(func(item: Dictionary)->bool:return str(item.get("reservation_id","")) == source_id),"source_reservation_removed_after_boundary")
	_check(city.planning_reservations.all(func(item: Dictionary)->bool:return str(item.get("parent_reservation_id","")) == source_id and str(item.get("converted_by","")) == str(site.get("id",""))),"residuals_keep_parent_and_converter")
	var conversion_event: Dictionary = {}
	for event in city.events:
		if bool(event.get("partial",false)) and str(event.get("source_reservation_id","")) == source_id: conversion_event = event
	_check(str(conversion_event.get("conversion_scope","")) == "partial" and str(conversion_event.get("kind","")) == "civic","event_records_partial_facility_scope")
	_check(int(conversion_event.get("event_id",0)) == int(queued.get("event_id",0)) and not str(conversion_event.get("source_id","")).is_empty(),"event_records_stable_order_identity")
	_check(str(conversion_event.get("target_community_id","")) == str(site.get("community_id","")) and conversion_event.get("remaining_reservation_ids",[]).size() == city.planning_reservations.size(),"event_records_target_and_residual_identity")
	_check(conversion_event.has("service_before") and conversion_event.has("service_after") and conversion_event.has("service_delta"),"event_records_service_before_after_delta")
	_check(model.transition_total > 0,"partial_conversion_enters_structural_audio_seam")
	# The pre-boundary presentation was checked before rendering above; at this
	# point the live world has intentionally advanced across the boundary.
	_check(model.presentation_world(boundary).public_sites.any(func(item: Dictionary)->bool:return str(item.get("source_reservation_id","")) == source_id),"partial_site_visible_from_presentation_at_boundary")
	var second: Dictionary = {}
	for fragment in city.planning_reservations:
		var second_preview := PartialPublic.preview(city,str(fragment["reservation_id"]),"park",Vector2(float(fragment["position"][0]),float(fragment["position"][1])))
		if bool(second_preview.get("accepted",false)):
			second = second_preview
			break
	_check(not second.is_empty(),"a_residual_fragment_can_be_planned_again")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.public_sites.any(func(item: Dictionary)->bool:return str(item.get("source_reservation_id","")) == source_id),"partial_site_roundtrips_through_city_dna")
	_check(restored.world.planning_reservations.size() == city.planning_reservations.size() and restored.world.events.any(func(event: Dictionary)->bool:return bool(event.get("partial",false))),"residuals_and_event_roundtrip_through_city_dna")
	_finish()

func _finish() -> void:
	print("ROUND155_PARTIAL_PUBLIC ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
