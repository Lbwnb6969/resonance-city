extends SceneTree
## P10 historical non-rectangular reservation conversion contract.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const NeighborhoodPlan = preload("res://scripts/world/neighborhood_plan.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const FabricRelations = preload("res://scripts/world/fabric_relations.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _target_candidate(city: World) -> Dictionary:
	var half := Vector2(float(city.cfg["city"]["civic_half_width"])*0.28,float(city.cfg["city"]["civic_half_length"])*0.28)
	for y in range(-36,37):
		for x in range(-36,37):
			var position := Vector2(float(x)*0.25,float(y)*0.25)
			var polygon := NeighborhoodPlan.box(position,half)
			if not city.terrain.valid_footprint(polygon): continue
			var candidate := {"source_site_id":"nonrect-source","reservation_id":"reservation-round156","position":[position.x,position.y],"polygon":polygon,
				"community_id":FabricRelations.community_for_position(city,position)}
			if not Planning.site_reason(city,candidate,"reservation-round156").is_empty(): continue
			var access := Planning.public_access(city,candidate)
			if access.is_empty(): continue
			return {"position":position,"polygon":polygon,"access":access}
	return {}

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	var target := _target_candidate(city)
	_check(not target.is_empty(),"finds_accessible_target_for_nonrect_fragment")
	if target.is_empty():
		_finish()
		return
	var center: Vector2 = target["position"]
	# An L-shaped historical fragment with the target rectangle in its solid arm.
	var source_polygon := PackedVector2Array([
		center+Vector2(-2.0,-2.0),center+Vector2(2.0,-2.0),center+Vector2(2.0,0.8),
		center+Vector2(0.8,0.8),center+Vector2(0.8,2.0),center+Vector2(-2.0,2.0)])
	var source_id := "reservation-round156"
	city.planning_reservations.append({"id":source_id,"reservation_id":source_id,"source_site_id":"nonrect-source",
		"polygon":source_polygon,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var preview := PartialPublic.preview(city,source_id,"civic",center)
	_check(bool(preview.get("accepted",false)),"accepts_nonrectangular_source_fragment")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	var source_area := PartialPublic._polygon_area(source_polygon)
	var target_area := PartialPublic._polygon_area(preview["target_polygon"])
	var residual_area := 0.0
	for fragment in preview["remaining_polygons"]: residual_area += PartialPublic._polygon_area(fragment)
	_check(is_equal_approx(source_area,target_area+residual_area),"nonrect_residual_area_conserves_source")
	_check(preview["remaining_polygons"].size() >= 2,"nonrect_source_keeps_multiple_residual_components")
	_check(preview["remaining_polygons"].all(func(fragment: PackedVector2Array)->bool:
		return PartialPublic._polygon_area(fragment) > 0.00001 and Geometry2D.intersect_polygons(fragment,preview["target_polygon"]).is_empty()),"nonrect_residuals_are_positive_and_disjoint")
	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"civic","partial":true,"source_reservation_id":source_id,"position":[center.x,center.y],"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"nonrect_conversion_queues_through_audio_model")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	var before := model.presentation_world(boundary-1)
	_check(not before.public_sites.any(func(site: Dictionary)->bool:return str(site.get("source_reservation_id","")) == source_id),"nonrect_site_hidden_before_boundary")
	model.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for candidate in city.public_sites:
		if str(candidate.get("source_reservation_id","")) == source_id: site = candidate
	_check(not site.is_empty(),"nonrect_site_settles_at_boundary")
	_check(city.planning_reservations.size() == preview["remaining_polygons"].size(),"nonrect_fragments_replace_source")
	_check(city.planning_reservations.all(func(item: Dictionary)->bool:
		return str(item.get("parent_reservation_id","")) == source_id and str(item.get("root_reservation_id","")) == source_id and str(item.get("converted_by","")) == str(site.get("id",""))),"nonrect_lineage_is_stable")
	var event: Dictionary = {}
	for item in city.events:
		if bool(item.get("partial",false)) and str(item.get("source_reservation_id","")) == source_id: event = item
	_check(str(event.get("conversion_scope","")) == "partial" and event.get("remaining_reservation_ids",[]).size() == city.planning_reservations.size(),"nonrect_event_records_conversion_and_fragments")
	_check(model.presentation_world(boundary).public_sites.any(func(item: Dictionary)->bool:return str(item.get("source_reservation_id","")) == source_id),"nonrect_site_visible_at_boundary")
	_check(model.transition_total > 0,"nonrect_conversion_enters_structural_audio_seam")
	var stale := model.submit({"kind":"park","partial":true,"source_reservation_id":source_id,"position":[center.x,center.y],"source_revision":"stale"})
	_check(not bool(stale.get("accepted",false)),"nonrect_stale_revision_rejected")
	_check(str(event.get("root_reservation_id","")) == source_id,"nonrect_event_keeps_root_lineage")
	var invalid_id := "reservation-round156-invalid"
	city.planning_reservations.append({"id":invalid_id,"reservation_id":invalid_id,"source_site_id":"invalid","polygon":PackedVector2Array([center+Vector2(-1,-1),center+Vector2(1,1),center+Vector2(-1,1),center+Vector2(1,-1)]),"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var invalid := PartialPublic.preview(city,invalid_id,"park",center)
	_check(not bool(invalid.get("accepted",false)),"nonrect_self_intersection_rejected")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.planning_reservations.size() == city.planning_reservations.size() and restored.world.events.any(func(item: Dictionary)->bool:return bool(item.get("partial",false))),"nonrect_lineage_roundtrips_through_city_dna")
	_finish()

func _finish() -> void:
	print("ROUND156_NONRECT_PARTIAL ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
