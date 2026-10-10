extends SceneTree
## Round 159: arbitrary public target footprints use a stable convex contract.

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
			var candidate := {"source_site_id":"round159-source","reservation_id":"round159-reservation",
				"position":[center.x,center.y],"polygon":box,"community_id":FabricRelations.community_for_position(city,center)}
			if not Planning.site_reason(city,candidate,"round159-reservation").is_empty(): continue
			var access := Planning.public_access(city,candidate)
			if access.is_empty(): continue
			return {"center":center,"box":box,"access":access}
	return {}

func _diamond(center: Vector2,extent: Vector2,rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(extent.x,0.0),Vector2(0.0,extent.y),Vector2(-extent.x,0.0),Vector2(0.0,-extent.y)])
	for index in range(points.size()): points[index] = center+points[index].rotated(rotation)
	return points

func _run() -> void:
	var city := World.new("2026101100000159",true,"river_valley")
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
	var reservation_id := "round159-reservation"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round159-source",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var target := _diamond(center,Vector2(bounds.size.x*0.34,bounds.size.y*0.25),0.37)
	var preview := PartialPublic.preview_footprint(city,reservation_id,"civic",target)
	_check(bool(preview.get("accepted",false)),"accepts_convex_target_footprint")
	if not bool(preview.get("accepted",false)):
		_finish()
		return
	_check(preview["target_polygon"] == target,"keeps_requested_target_geometry")
	var target_center := Vector2(float(preview["target_position"][0]),float(preview["target_position"][1]))
	_check(Geometry2D.is_point_in_polygon(target_center,target),"uses_target_representative_point")
	_check(str(preview.get("target_community_id","")) == FabricRelations.community_for_position(city,target_center),"community_matches_representative_point")
	_check(not preview.get("target_entrance",[]).is_empty() and not preview.get("target_access_path",PackedVector2Array()).is_empty(),"keeps_real_road_entry_for_footprint")
	var source_area := PartialPublic._polygon_area(source)
	var target_area := PartialPublic._polygon_area(target)
	var remaining_area := 0.0
	for fragment in preview["remaining_polygons"]:
		remaining_area += PartialPublic._polygon_area(fragment)
		_check(PartialPublic._valid_simple_polygon(fragment),"residual_is_simple_%d" % remaining_area)
		_check(Geometry2D.intersect_polygons(fragment,target).is_empty(),"residual_has_no_target_overlap_%d" % remaining_area)
	_check(is_equal_approx(source_area,target_area+remaining_area),"convex_target_area_conserves_source")
	_check(preview["remaining_polygons"].size() >= 2,"convex_target_keeps_residual_components")
	var reverse_target := target.duplicate()
	reverse_target.reverse()
	var reverse_preview := PartialPublic.preview_footprint(city,reservation_id,"civic",reverse_target)
	_check(bool(reverse_preview.get("accepted",false)) and is_equal_approx(float(reverse_preview.get("target_area",0.0)),target_area),"accepts_clockwise_convex_target")

	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"civic","partial":true,"source_reservation_id":reservation_id,
		"target_polygon":target,"source_revision":preview["source_revision"]})
	_check(bool(queued.get("accepted",false)),"footprint_queues_without_position_argument")
	_check(city.planning_reservations.size() == 1,"footprint_source_stays_until_boundary")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for item in city.public_sites:
		if str(item.get("source_reservation_id","")) == reservation_id: site = item
	_check(not site.is_empty(),"footprint_site_commits_at_boundary")
	_check(site.get("polygon",PackedVector2Array()) == target,"committed_site_keeps_target_polygon")
	_check(city.events.any(func(event: Dictionary)->bool:
		return bool(event.get("partial",false)) and event.get("converted_footprint",PackedVector2Array()) == target),"footprint_event_keeps_target_polygon")
	_check(model.transition_total > 0,"footprint_conversion_enters_structural_audio_seam")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.public_sites.any(func(item: Dictionary)->bool:return item.get("polygon",PackedVector2Array()) == target),"footprint_roundtrips_through_city_dna")

	var invalid_id := "round159-invalid-source"
	city.planning_reservations.append({"id":invalid_id,"reservation_id":invalid_id,"source_site_id":"round159-invalid-source",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var self_crossing := PackedVector2Array([center+Vector2(-0.5,-0.5),center+Vector2(0.8,0.5),center+Vector2(0.8,-0.5),center+Vector2(-0.5,0.5)])
	var rejected_invalid := PartialPublic.preview_footprint(city,invalid_id,"park",self_crossing)
	_check(not bool(rejected_invalid.get("accepted",false)) and str(rejected_invalid.get("reason","")).contains("简单"),"rejects_self_crossing_target_with_explicit_contract")
	var outside := _diamond(center+Vector2(bounds.size.x*3.0,0.0),Vector2(0.2,0.2))
	var rejected_outside := PartialPublic.preview_footprint(city,invalid_id,"park",outside)
	_check(not bool(rejected_outside.get("accepted",false)) and str(rejected_outside.get("reason","")).contains("留地"),"rejects_target_outside_source_reservation")
	_finish()

func _finish() -> void:
	print("ROUND159_TARGET_FOOTPRINT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
