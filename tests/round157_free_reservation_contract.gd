extends SceneTree
## Round 157: a player-drawn simple polygon enters the existing reservation
## transaction.  This is a technical contract for geometry and persistence;
## it does not claim human control or visual quality.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _freeze_growth(world: World) -> void:
	for family in world.families.values(): family["next_growth_phrase"] = 1000

func _cross_boundary(model: Model) -> int:
	var boundary: int = model.next_boundary
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	return boundary

func _find_polygon(world: World) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","" )).is_empty(): continue
		var box := Planning.bounds(lot["polygon"])
		var center := box.get_center()
		var half := box.size*0.28
		var polygon := PackedVector2Array([center+Vector2(-half.x,-half.y),center+Vector2(half.x,-half.y),center+Vector2(half.x,half.y),center+Vector2(-half.x,half.y)])
		var preview := Planning.polygon_candidate(world,polygon,center)
		if bool(preview.get("allowed",false)):
			return {"polygon":polygon,"preview":preview}
	return {}

func _run() -> void:
	var city := World.new()
	city.build_starter("bright")
	_freeze_growth(city)
	var picked := _find_polygon(city)
	_check(not picked.is_empty(),"free_polygon_finds_legal_empty_source")
	if picked.is_empty():
		quit(1)
		return
	var polygon: PackedVector2Array = picked["polygon"]
	var preview: Dictionary = picked["preview"]
	var center := Vector2(float(preview["position"][0]),float(preview["position"][1]))
	_check(Planning.valid_simple_polygon(polygon),"free_polygon_is_simple")
	_check(Planning.polygon_area(polygon) > 0.01,"free_polygon_has_positive_area")
	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"reserve","position":[center.x,center.y],"polygon":polygon})
	_check(bool(queued.get("accepted",false)),"free_polygon_queues_through_existing_reserve")
	_check(city.planning_reservations.is_empty(),"free_polygon_stays_pending_before_boundary")
	var boundary := _cross_boundary(model)
	_check(city.planning_reservations.size() == 1,"free_polygon_commits_at_phrase_boundary")
	var reservation: Dictionary = city.planning_reservations[0] if not city.planning_reservations.is_empty() else {}
	var reservation_id := str(reservation.get("reservation_id",""))
	_check(reservation.get("polygon",PackedVector2Array()) == polygon,"free_polygon_preserves_drawn_geometry")
	_check(str(reservation.get("source_site_id","")) == str(preview.get("source_site_id","")),"free_polygon_keeps_source_site_identity")
	_check(not city.placement(center).get("allowed",false),"free_polygon_enters_shared_occupancy_exclusion")
	_check(city.events.any(func(event: Dictionary)->bool:return str(event.get("kind","")) == "reserve" and str(event.get("id","")) == reservation_id),"free_polygon_emits_reservation_event")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.planning_reservations.size() == 1 and restored.world.planning_reservations[0].get("polygon",PackedVector2Array()) == polygon,"free_polygon_roundtrips_through_city_dna")
	var released := model.submit({"kind":"release_reservation","id":reservation_id})
	_check(bool(released.get("accepted",false)),"free_polygon_release_reuses_existing_operation")
	_cross_boundary(model)
	_check(city.planning_reservations.is_empty(),"free_polygon_release_commits_at_boundary")
	_check(bool(city.placement(center).get("allowed",false)),"free_polygon_release_restores_occupancy")
	var invalid := PackedVector2Array([center+Vector2(-1,-1),center+Vector2(1,1),center+Vector2(-1,1),center+Vector2(1,-1)])
	var rejected := model.submit({"kind":"reserve","position":[center.x,center.y],"polygon":invalid})
	_check(not bool(rejected.get("accepted",false)) and str(rejected.get("reason","")).contains("连续"),"self_intersecting_free_polygon_is_rejected")

	# The JSON/UI form is accepted as well; the world normalizes it at request time.
	var city_array := World.new()
	city_array.build_starter("bright")
	_freeze_growth(city_array)
	var picked_array := _find_polygon(city_array)
	var array_polygon: PackedVector2Array = picked_array.get("polygon",PackedVector2Array())
	var array_preview: Dictionary = picked_array.get("preview",{})
	var array_center := Vector2(float(array_preview.get("position",[0,0])[0]),float(array_preview.get("position",[0,0])[1]))
	var points: Array = []
	for point in array_polygon: points.append([point.x,point.y])
	var array_model := Model.new(city_array,1.3409036)
	var array_queued := array_model.submit({"kind":"reserve","position":[array_center.x,array_center.y],"polygon":points})
	_check(bool(array_queued.get("accepted",false)),"array_polygon_form_is_normalized")
	_cross_boundary(array_model)
	_check(city_array.planning_reservations.size() == 1 and city_array.planning_reservations[0].get("polygon",PackedVector2Array()) == array_polygon,"array_polygon_commits_same_geometry")
	var failures: Array[String] = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND157_FREE_RESERVATION ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"boundary":boundary}))
	quit(0 if failures.is_empty() else 1)
