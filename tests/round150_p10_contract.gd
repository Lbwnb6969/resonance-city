extends SceneTree

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _position(site: Dictionary) -> Vector2:
	var raw: Array = site.get("position",[])
	return Vector2(float(raw[0]),float(raw[1]))

func _pick(world: ContinuousWorld) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site := world.planning_candidate(p)
		if site.is_empty() or not bool(site.get("allowed",false)): continue
		if site.has("reservation_id") or site.has("public_id"): continue
		if not Planning.public_access(world,site).is_empty(): return site
	return {}

func _freeze_growth(world: ContinuousWorld) -> void:
	for family in world.families.values(): family["next_growth_phrase"] = 1000

func _cross_boundary(model: ContinuousAudioModel) -> int:
	var boundary: int = model.next_boundary
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	return boundary

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	_freeze_growth(city)
	var site := _pick(city)
	_check(not site.is_empty(),"release_candidate_has_real_road_access")
	if site.is_empty():
		quit(1)
		return
	var p := _position(site)
	var model := Model.new(city,1.3409036)
	var frame := model.next_boundary
	var queued := model.submit({"kind":"reserve","position":[p.x,p.y]})
	_check(bool(queued.get("accepted",false)),"reserve_queues_through_audio_model")
	_check(city.planning_reservations.is_empty(),"reserve_stays_pending_before_boundary")
	var boundary := _cross_boundary(model)
	var before_audible := model.presentation_world(boundary-1)
	_check(before_audible.planning_reservations.is_empty(),"reservation_hidden_before_audible_boundary")
	var reservation_world := model.presentation_world(boundary)
	_check(reservation_world.planning_reservations.size() == 1,"reservation_visible_at_audible_boundary")
	var reservation_id := str(city.planning_reservations[0]["reservation_id"])
	var count_before_release := city.buildings.size()
	var released := model.submit({"kind":"release_reservation","id":reservation_id})
	_check(bool(released.get("accepted",false)),"release_queues_existing_identity")
	var release_boundary := _cross_boundary(model)
	_check(city.planning_reservations.is_empty(),"release_removes_reservation_at_boundary")
	_check(bool(city.placement(p).get("allowed",false)),"release_restores_building_eligibility")
	_check(city.buildings.size() == count_before_release,"release_does_not_spawn_or_delete_buildings")
	_check(city.events.any(func(event: Dictionary) -> bool:
		return str(event.get("kind","")) == "release_reservation" and str(event.get("id","")) == reservation_id),"release_event_keeps_stable_identity")
	_check(model.presentation_world(release_boundary-1).planning_reservations.size() == 1,"released_space_stays_visible_until_audio_boundary")
	_check(model.presentation_world(release_boundary).planning_reservations.is_empty(),"released_space_updates_after_audio_boundary")

	# The same real candidate can be reserved first and explicitly converted to a
	# public facility later. Conversion consumes the reservation and keeps the
	# actual polygon, entrance, service coverage and replay identity.
	var converted_city := World.new()
	converted_city.build_starter("bright")
	_freeze_growth(converted_city)
	var converted_site := _pick(converted_city)
	_check(not converted_site.is_empty(),"conversion_candidate_has_real_road_access")
	if converted_site.is_empty():
		quit(1)
		return
	var converted_position := _position(converted_site)
	var converted_model := Model.new(converted_city,1.3409036)
	_check(bool(converted_model.submit({"kind":"reserve","position":[converted_position.x,converted_position.y]}).get("accepted",false)),"conversion_reservation_queues")
	_cross_boundary(converted_model)
	var reservation_polygon: PackedVector2Array = converted_site["polygon"].duplicate()
	var converted := converted_model.submit({"kind":"civic","position":[converted_position.x,converted_position.y]})
	_check(bool(converted.get("accepted",false)),"conversion_queues_from_existing_reservation")
	var conversion_boundary := _cross_boundary(converted_model)
	var facility := converted_city.public_at(converted_position)
	_check(converted_city.planning_reservations.is_empty(),"conversion_consumes_only_selected_reservation")
	_check(not facility.is_empty() and str(facility.get("kind","")) == "civic","conversion_builds_civic_facility")
	_check(not facility.is_empty() and facility.get("polygon",PackedVector2Array()) == reservation_polygon,"conversion_preserves_real_footprint")
	_check(not facility.is_empty() and not str(facility.get("road_id","")).is_empty() and facility.get("covered",[]).size() > 0 and facility.get("served",[]).size() > 0,"conversion_provides_entrance_and_service")
	_check(converted_city.events.any(func(event: Dictionary) -> bool:
		return str(event.get("kind","")) == "civic" and str(event.get("converted_reservation","")).begins_with("reservation-")),"conversion_event_replays_source_reservation")
	_check(converted_model.presentation_world(conversion_boundary-1).public_at(converted_position).is_empty(),"facility_hidden_before_conversion_boundary")
	_check(not converted_model.presentation_world(conversion_boundary).public_at(converted_position).is_empty(),"facility_visible_after_conversion_boundary")
	var saved := converted_model.capture_state()
	var restored := Model.from_state(saved)
	var restored_facility := restored.world.public_at(converted_position)
	_check(restored.world.planning_reservations.is_empty() and restored_facility.get("id","") == facility.get("id",""),"conversion_state_roundtrip")
	_check(restored_facility.get("polygon",PackedVector2Array()) == reservation_polygon and restored_facility.get("served",[]).size() == facility.get("served",[]).size(),"conversion_service_geometry_roundtrip")
	var passed := checks.values().all(func(ok: bool) -> bool: return ok)
	var result := {"passed":passed,"checks":checks,"scope":"P10 release and reservation-to-civic conversion through the audio model boundary","source_sha256":FileAccess.get_sha256("res://scripts/world/city_spatial_planning.gd")}
	print("ROUND150_P10 ",JSON.stringify(result))
	quit(0 if passed else 1)

