extends SceneTree
## Round 161: one public facility can preserve multiple disjoint components.

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

func _find_accessible_anchor(city: World) -> Dictionary:
	var half := Vector2(float(city.cfg["city"]["civic_half_width"])*0.28,float(city.cfg["city"]["civic_half_length"])*0.28)
	for y in range(-36,37):
		for x in range(-36,37):
			var center := Vector2(float(x)*0.25,float(y)*0.25)
			var polygon := NeighborhoodPlan.box(center,half)
			if not city.terrain.valid_footprint(polygon): continue
			var candidate := {"source_site_id":"round161-source","reservation_id":"round161-reservation","position":[center.x,center.y],"polygon":polygon,"community_id":FabricRelations.community_for_position(city,center)}
			if not Planning.site_reason(city,candidate,"round161-reservation").is_empty(): continue
			if Planning.public_access(city,candidate).is_empty(): continue
			return {"center":center,"box":polygon}
	return {}

func _find_components(city: World,source: PackedVector2Array,center: Vector2) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var half := Vector2(0.22,0.22)
	var offsets: Array[Vector2] = []
	for y in range(-7,8):
		for x in range(-7,8): offsets.append(Vector2(float(x)*0.28,float(y)*0.28))
	for first_offset in offsets:
		var first := NeighborhoodPlan.box(center+first_offset,half)
		if not Geometry2D.is_point_in_polygon(center+first_offset,source): continue
		var first_candidate := {"source_site_id":"round161-source","reservation_id":"round161-reservation","position":[center.x+first_offset.x,center.y+first_offset.y],"polygon":first,"community_id":FabricRelations.community_for_position(city,center+first_offset)}
		if not Planning.site_reason(city,first_candidate,"round161-reservation").is_empty() or Planning.public_access(city,first_candidate).is_empty(): continue
		for second_offset in offsets:
			if first_offset.distance_to(second_offset) < 0.8: continue
			var second := NeighborhoodPlan.box(center+second_offset,half)
			if not Geometry2D.is_point_in_polygon(center+second_offset,source): continue
			var second_candidate := {"source_site_id":"round161-source","reservation_id":"round161-reservation","position":[center.x+second_offset.x,center.y+second_offset.y],"polygon":second,"community_id":FabricRelations.community_for_position(city,center+second_offset)}
			if not Planning.site_reason(city,second_candidate,"round161-reservation").is_empty() or Planning.public_access(city,second_candidate).is_empty(): continue
			result.append(first)
			result.append(second)
			return result
	return result

func _area_sum(polygons: Array) -> float:
	var total := 0.0
	for polygon in polygons: total += PartialPublic._polygon_area(polygon)
	return total

func _run() -> void:
	var city := World.new("2026101100000161",true,"river_valley")
	city.build_starter("bright")
	var found := _find_accessible_anchor(city)
	_check(not found.is_empty(),"finds_accessible_anchor")
	if found.is_empty():
		_finish()
		return
	var center: Vector2 = found["center"]
	var source := NeighborhoodPlan.box(center,Vector2(3.8,3.8))
	var reservation_id := "round161-reservation"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round161-source","polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var components := _find_components(city,source,center)
	_check(components.size() == 2,"finds_two_separate_accessible_components")
	if components.size() != 2:
		_finish()
		return
	var preview := PartialPublic.preview_footprints(city,reservation_id,"civic",components)
	_check(bool(preview.get("accepted",false)),"accepts_disjoint_target_components")
	_check(preview.get("target_polygons",[]).size() == 2 and preview.get("footprint_components",[]).size() == 2,"preview_keeps_component_schema")
	_check(preview.get("target_polygon",PackedVector2Array()) == components[0],"preview_keeps_legacy_first_polygon")
	_check(preview.get("target_community_ids",[]).size() >= 1,"preview_keeps_component_communities")
	var source_area := PartialPublic._polygon_area(source)
	var target_area := _area_sum(components)
	var residual_area := _area_sum(preview.get("remaining_polygons",[]))
	_check(is_equal_approx(source_area,target_area+residual_area),"multi_component_area_conserves_source")
	for residual in preview.get("remaining_polygons",[]):
		_check(PartialPublic._valid_simple_polygon(residual),"multi_component_residual_is_simple")
		for component in components: _check(Geometry2D.intersect_polygons(residual,component).is_empty(),"multi_component_residual_disjoint")

	var overlap_components: Array = [components[0],NeighborhoodPlan.box(Vector2(float(components[0][0].x)+0.25,float(components[0][0].y)),Vector2(0.22,0.22))]
	var overlap_preview := PartialPublic.preview_footprints(city,reservation_id,"civic",overlap_components)
	_check(not bool(overlap_preview.get("accepted",false)) and str(overlap_preview.get("reason","")).contains("分离"),"rejects_overlapping_components")
	var touching_components: Array = [components[0],NeighborhoodPlan.box(Vector2(float(components[0][1].x),float(components[0][1].y)),Vector2(0.22,0.22))]
	var touching_preview := PartialPublic.preview_footprints(city,reservation_id,"civic",touching_components)
	_check(not bool(touching_preview.get("accepted",false)) and str(touching_preview.get("reason","")).contains("分离"),"rejects_touching_components")

	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"civic","partial":true,"source_reservation_id":reservation_id,"target_polygons":components,"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"multi_component_request_queues")
	_check(city.planning_reservations.size() == 1,"multi_component_source_stays_until_boundary")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for candidate in city.public_sites:
		if str(candidate.get("source_reservation_id","")) == reservation_id: site = candidate
	_check(not site.is_empty(),"multi_component_site_commits")
	_check(site.get("footprint_components",[]).size() == 2 and site.get("target_polygons",[]).size() == 2,"site_persists_components")
	_check(site.get("polygon",PackedVector2Array()) == components[0],"site_keeps_legacy_polygon")
	_check(city.public_at(components[1][0]+Vector2(0.01,0.01)).get("id","") == site.get("id",""),"public_at_hits_second_component")
	var second_center := (components[1][0]+components[1][2])*0.5
	var blocked := Planning.exclusion(city,NeighborhoodPlan.box(second_center,Vector2(0.05,0.05)))
	_check(blocked == "占地不能压进公园或文化设施","exclusion_hits_second_component")
	var event: Dictionary = {}
	for candidate in city.events:
		if bool(candidate.get("partial",false)) and str(candidate.get("source_reservation_id","")) == reservation_id: event = candidate
	_check(event.get("converted_footprints",[]).size() == 2 and event.get("footprint_components",[]).size() == 2,"event_persists_components")
	_check(event.get("target_community_ids",[]).size() == site.get("target_community_ids",[]).size(),"event_persists_component_communities")
	var restored := Model.from_state(model.capture_state())
	var restored_site: Dictionary = {}
	for candidate in restored.world.public_sites:
		if str(candidate.get("source_reservation_id","")) == reservation_id: restored_site = candidate
	_check(restored_site.get("footprint_components",[]).size() == 2,"dna_roundtrips_components")
	_check(restored.world.public_at(second_center).get("id","") == site.get("id",""),"dna_keeps_second_component_hit_test")
	var restored_event: Dictionary = {}
	for candidate in restored.world.events:
		if bool(candidate.get("partial",false)) and str(candidate.get("source_reservation_id","")) == reservation_id: restored_event = candidate
	_check(restored_event.get("converted_footprints",[]).size() == 2 and restored_event.get("footprint_components",[]).size() == 2,"dna_roundtrips_component_event")
	_finish()

func _finish() -> void:
	print("ROUND161_MULTICOMPONENT_PUBLIC_FOOTPRINT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
