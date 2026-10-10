extends SceneTree

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _find_clear_site(city: ContinuousWorld,radius: float) -> Vector2:
	for y in range(3,29):
		for x in range(-14,15):
			var p := Vector2(float(x)*0.65,float(y)*0.65)
			if city.terrain.land_at(p) and city.terrain.valid_footprint(Planning.circle_polygon(p,radius)) and city.landmark_site_clear(p,radius):
				return p
	return Vector2.INF

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	var name := "元老院"
	city.landmark_progress[name] = {"streak":2,"awakened":true,"last_phrase":city.phrase_index}
	var radius := 1.35
	var center := _find_clear_site(city,radius)
	_check(center != Vector2.INF,"finds_clear_landmark_site")
	if center == Vector2.INF:
		_finish()
		return
	var reservation_polygon := PackedVector2Array([center+Vector2(-2.0,-2.0),center+Vector2(2.0,-2.0),center+Vector2(2.0,2.0),center+Vector2(-2.0,2.0)])
	var source_id := "reservation-round152"
	city.planning_reservations.append({"id":source_id,"reservation_id":source_id,"source_site_id":"synthetic-clear-parcel",
		"polygon":reservation_polygon,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	_check(Planning.reservation_contains_disc(city.planning_reservations[0],center,radius),"landmark_footprint_fits_reserved_parcel")
	var model := Model.new(city,1.3409036)
	var request := model.submit({"kind":"landmark","name":name,"position":[center.x,center.y],"radius":radius,"source_reservation_id":source_id})
	_check(bool(request.get("accepted",false)),"landmark_conversion_queues_through_audio_model")
	var boundary := model.next_boundary
	var rate := int(city.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	_check(city.landmarks.size() == 1,"landmark_conversion_settles_at_phrase_boundary")
	_check(city.planning_reservations.size() > 0,"remaining_reserved_fragments_survive_conversion")
	_check(not city.planning_reservations.any(func(item: Dictionary) -> bool: return str(item.get("reservation_id","")) == source_id),"source_reservation_is_replaced_by_fragments")
	_check(city.planning_reservations.all(func(item: Dictionary) -> bool:
		return str(item.get("parent_reservation_id","")) == source_id and str(item.get("converted_by","")) == str(city.landmarks[0].get("id",""))),"fragments_keep_parent_and_landmark_identity")
	_check(city.planning_reservations.all(func(item: Dictionary) -> bool:
		return Geometry2D.intersect_polygons(item["polygon"],Planning.circle_polygon(center,radius)).is_empty()),"remaining_fragments_do_not_overlap_landmark_footprint")
	var conversion_event: Dictionary = {}
	for event in city.events:
		if str(event.get("kind","")) == "landmark": conversion_event = event
	_check(str(conversion_event.get("converted_reservation","")) == source_id,"landmark_event_records_source_reservation")
	_check(conversion_event.get("reservation_fragments",[]).size() == city.planning_reservations.size(),"landmark_event_lists_remaining_fragments")
	_check(model.presentation_world(boundary-1).landmarks.is_empty(),"landmark_hidden_before_audible_boundary")
	_check(model.presentation_world(boundary).landmarks.size() == 1,"landmark_visible_at_audible_boundary")
	_check(model.audio_city().any(func(item: Dictionary) -> bool: return bool(item.get("landmark",false))),"landmark_conversion_enters_existing_audio_route")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.planning_reservations.size() == city.planning_reservations.size() and restored.world.planning_reservations.all(func(item: Dictionary) -> bool: return item.has("parent_reservation_id")),"fragmented_reservation_roundtrips_through_city_dna")
	_finish()

func _finish() -> void:
	print("ROUND152_P10_LANDMARK ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
