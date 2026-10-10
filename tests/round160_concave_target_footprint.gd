extends SceneTree
## Round 160: a simple concave public target remains a hole-free reservation.

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

func _find_target(city: World) -> Dictionary:
	var half := Vector2(float(city.cfg["city"]["civic_half_width"])*0.28,float(city.cfg["city"]["civic_half_length"])*0.28)
	for y in range(-36,37):
		for x in range(-36,37):
			var center := Vector2(float(x)*0.25,float(y)*0.25)
			var box := NeighborhoodPlan.box(center,half)
			if not city.terrain.valid_footprint(box): continue
			var candidate := {"source_site_id":"round160-source","reservation_id":"round160-reservation",
				"position":[center.x,center.y],"polygon":box,"community_id":FabricRelations.community_for_position(city,center)}
			if not Planning.site_reason(city,candidate,"round160-reservation").is_empty(): continue
			var access := Planning.public_access(city,candidate)
			if access.is_empty(): continue
			return {"center":center,"box":box,"access":access}
	return {}

func _concave_target(center: Vector2,bounds: Rect2) -> PackedVector2Array:
	var width := bounds.size.x*0.27
	var height := bounds.size.y*0.27
	# A six-sided rectangle with a single inward notch.  It is simple,
	# connected and concave, while leaving a visible remainder on every side.
	return PackedVector2Array([
		center+Vector2(-width,-height),
		center+Vector2(width,-height),
		center+Vector2(width,height),
		center+Vector2(width*0.18,height*0.18),
		center+Vector2(-width,height)])

func _run() -> void:
	var city := World.new("2026101100000160",true,"river_valley")
	city.build_starter("bright")
	var found := _find_target(city)
	_check(not found.is_empty(),"finds_legal_accessible_anchor")
	if found.is_empty():
		_finish()
		return
	var center: Vector2 = found["center"]
	var base: PackedVector2Array = found["box"]
	var bounds := Planning.bounds(base)
	var source := NeighborhoodPlan.box(bounds.get_center(),bounds.size*0.5+Vector2.ONE*1.2)
	var reservation_id := "round160-reservation"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round160-source",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var target := _concave_target(center,bounds)
	_check(PartialPublic._valid_simple_polygon(target),"target_is_simple")
	_check(not PartialPublic._is_convex_polygon(target),"target_is_concave")
	var preview := PartialPublic.preview_footprint(city,reservation_id,"civic",target)
	_check(bool(preview.get("accepted",false)),"accepts_concave_target_footprint")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	_check(preview["target_polygon"] == target,"keeps_concave_target_geometry")
	var target_center := Vector2(float(preview["target_position"][0]),float(preview["target_position"][1]))
	_check(Geometry2D.is_point_in_polygon(target_center,target),"uses_target_representative_point")
	_check(str(preview.get("target_community_id","")) == FabricRelations.community_for_position(city,target_center),"community_matches_target_representative")
	_check(not preview.get("target_entrance",[]).is_empty() and not preview.get("target_access_path",PackedVector2Array()).is_empty(),"keeps_real_road_entry_for_concave_target")
	var source_area := PartialPublic._polygon_area(source)
	var target_area := PartialPublic._polygon_area(target)
	var remaining_area := 0.0
	for index in range(preview["remaining_polygons"].size()):
		var fragment: PackedVector2Array = preview["remaining_polygons"][index]
		remaining_area += PartialPublic._polygon_area(fragment)
		_check(PartialPublic._valid_simple_polygon(fragment),"residual_is_simple_%d" % index)
		_check(Geometry2D.intersect_polygons(fragment,target).is_empty(),"residual_has_no_target_overlap_%d" % index)
	_check(is_equal_approx(source_area,target_area+remaining_area),"concave_target_area_conserves_source")
	_check(preview["remaining_polygons"].size() >= 2,"concave_target_keeps_residual_components")

	# The same target must work inside historical L and U shaped reservations;
	# these calls exercise the source partition independently of site access.
	var concave_sources := [
		PackedVector2Array([center+Vector2(-2.0,-2.0),center+Vector2(2.0,-2.0),center+Vector2(2.0,0.8),center+Vector2(0.8,0.8),center+Vector2(0.8,2.0),center+Vector2(-2.0,2.0)]),
		PackedVector2Array([center+Vector2(-2.0,-2.0),center+Vector2(2.0,-2.0),center+Vector2(2.0,2.0),center+Vector2(0.8,2.0),center+Vector2(0.8,0.5),center+Vector2(-0.8,0.5),center+Vector2(-0.8,2.0),center+Vector2(-2.0,2.0)])]
	for source_index in range(concave_sources.size()):
		var source_shape: PackedVector2Array = concave_sources[source_index]
		var shape_residuals := PartialPublic._residuals(source_shape,target)
		var shape_area := 0.0
		for fragment in shape_residuals: shape_area += PartialPublic._polygon_area(fragment)
		_check(not shape_residuals.is_empty(),"concave_target_accepts_source_shape_%d" % source_index)
		_check(is_equal_approx(PartialPublic._polygon_area(source_shape),PartialPublic._polygon_area(target)+shape_area),"concave_source_area_conserves_%d" % source_index)
		_check(shape_residuals.all(func(fragment: PackedVector2Array)->bool:
			return PartialPublic._valid_simple_polygon(fragment) and Geometry2D.intersect_polygons(fragment,target).is_empty()),"concave_source_residuals_are_simple_%d" % source_index)

	var reverse_target := target.duplicate()
	reverse_target.reverse()
	var reverse_residuals := PartialPublic._residuals(source,reverse_target)
	var reverse_area := 0.0
	for fragment in reverse_residuals: reverse_area += PartialPublic._polygon_area(fragment)
	_check(not reverse_residuals.is_empty(),"accepts_clockwise_concave_target")
	_check(is_equal_approx(reverse_area,source_area-target_area),"clockwise_concave_target_area_matches")

	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"civic","partial":true,"source_reservation_id":reservation_id,
		"target_polygon":target,"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"concave_target_queues_without_position")
	_check(city.planning_reservations.size() == 1,"concave_source_stays_until_boundary")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for item in city.public_sites:
		if str(item.get("source_reservation_id","")) == reservation_id: site = item
	_check(not site.is_empty(),"concave_target_site_commits_at_boundary")
	_check(site.get("polygon",PackedVector2Array()) == target,"committed_site_keeps_concave_geometry")
	_check(city.events.any(func(event: Dictionary)->bool:
		return bool(event.get("partial",false)) and event.get("converted_footprint",PackedVector2Array()) == target),"concave_event_keeps_target_geometry")
	_check(model.transition_total > 0,"concave_conversion_enters_structural_audio_seam")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.public_sites.any(func(item: Dictionary)->bool:return item.get("polygon",PackedVector2Array()) == target),"concave_target_roundtrips_through_city_dna")

	var invalid_id := "round160-invalid-source"
	city.planning_reservations.append({"id":invalid_id,"reservation_id":invalid_id,"source_site_id":"round160-invalid-source",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var self_crossing := PackedVector2Array([center+Vector2(-0.6,-0.4),center+Vector2(0.6,0.4),center+Vector2(0.6,-0.4),center+Vector2(-0.6,0.4)])
	var rejected := PartialPublic.preview_footprint(city,invalid_id,"park",self_crossing)
	_check(not bool(rejected.get("accepted",false)) and str(rejected.get("reason","")).contains("简单"),"rejects_self_crossing_target")
	_finish()

func _finish() -> void:
	print("ROUND160_CONCAVE_TARGET_FOOTPRINT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
