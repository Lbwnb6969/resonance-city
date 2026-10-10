extends SceneTree
## Round 158: a free reservation may span adjacent empty lots while retaining
## one deterministic source identity.  The fixture uses authored adjacent lots
## so it does not depend on the current starter plan's intentionally spaced lots.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")

var checks: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)

func _box(origin: Vector2,size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([origin,origin+Vector2(size.x,0.0),origin+size,origin+Vector2(0.0,size.y)])

func _new_world() -> World:
	var world := World.new("2026101100000158",false,"river_valley")
	world.communities["synthetic"] = {"id":"synthetic","bank":0,"name":"合成连续地块","members":[],"parent_id":""}
	var origin := Vector2.ZERO
	var found := false
	for y in range(-24,25):
		for x in range(-24,25):
			var candidate := Vector2(float(x),float(y))
			var joined := _box(candidate,Vector2(2.0,2.0))
			if world.terrain.valid_footprint(joined):
				origin = candidate
				found = true
				break
		if found: break
	if not found: return world
	var offsets := [0.0,1.0,3.0]
	for index in range(3):
		var lot_origin := origin+Vector2(float(offsets[index]),0.0)
		var polygon := _box(lot_origin,Vector2(1.0,2.0))
		world.lots.append({"id":"synthetic-lot-%d" % (index+1),"center":[polygon[0].x+(polygon[2].x-polygon[0].x)*0.5,polygon[0].y+1.0],"polygon":polygon,"entrance":[polygon[0].x,polygon[0].y+1.0],"use":"residential","community_id":"synthetic","bank":0,"occupant":""})
	world._refresh_parcel_index()
	return world

func _cross_boundary(model: Model) -> int:
	var boundary: int = model.next_boundary
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	model.render_block({},boundary-1,2,rate)
	return boundary

func _run() -> void:
	var city := _new_world()
	var source: PackedVector2Array = city.lots[0]["polygon"]
	var second: PackedVector2Array = city.lots[1]["polygon"]
	var left := Vector2(source[0].x+0.1,source[0].y+0.2)
	var right := Vector2(second[2].x-0.1,second[2].y-0.2)
	var polygon := _box(left,Vector2(right.x-left.x,right.y-left.y))
	var preview := Planning.polygon_candidate(city,polygon,polygon[0]+Vector2(0.2,0.2))
	_check(bool(preview.get("allowed",false)),"cross_lot_polygon_is_allowed")
	_check(preview.get("source_lot_ids",[]) == ["synthetic-lot-1","synthetic-lot-2"],"cross_lot_source_lot_ids_are_sorted")
	_check(str(preview.get("source_site_id","")) == "lot-group:synthetic-lot-1|synthetic-lot-2","cross_lot_source_site_id_is_deterministic")
	_check(is_equal_approx(Planning.polygon_area(polygon),Planning._intersection_area(city.lots[0]["polygon"],polygon)+Planning._intersection_area(city.lots[1]["polygon"],polygon)),"cross_lot_area_is_conserved")
	var reverse := PackedVector2Array([polygon[3],polygon[2],polygon[1],polygon[0]])
	var reverse_preview := Planning.polygon_candidate(city,reverse,Vector2.INF)
	_check(reverse_preview.get("source_lot_ids",[]) == preview.get("source_lot_ids",[]) and str(reverse_preview.get("source_site_id","")) == str(preview.get("source_site_id","")),"cross_lot_source_identity_ignores_point_order_and_anchor")

	var model := Model.new(city,1.3409036)
	var queued := model.submit({"kind":"reserve","position":preview["position"],"polygon":polygon})
	_check(bool(queued.get("accepted",false)),"cross_lot_reserve_queues")
	_check(city.planning_reservations.is_empty(),"cross_lot_reserve_stays_pending_before_boundary")
	_cross_boundary(model)
	_check(city.planning_reservations.size() == 1,"cross_lot_reserve_commits_at_boundary")
	var reservation: Dictionary = city.planning_reservations[0] if not city.planning_reservations.is_empty() else {}
	_check(reservation.get("source_lot_ids",[]) == preview.get("source_lot_ids",[]),"cross_lot_reservation_keeps_source_lot_ids")
	_check(str(reservation.get("source_site_id","")) == str(preview.get("source_site_id","")),"cross_lot_reservation_keeps_source_site_id")
	_check(city.events.any(func(event: Dictionary)->bool:return str(event.get("kind","")) == "reserve" and event.get("source_lot_ids",[]) == preview.get("source_lot_ids",[])),"cross_lot_event_keeps_source_lot_ids")
	var restored := Model.from_state(model.capture_state())
	_check(restored.world.planning_reservations.size() == 1 and restored.world.planning_reservations[0].get("source_lot_ids",[]) == preview.get("source_lot_ids",[]),"cross_lot_dna_roundtrip_keeps_source_lot_ids")
	var reservation_id := str(reservation.get("reservation_id",""))
	var released := model.submit({"kind":"release_reservation","id":reservation_id})
	_check(bool(released.get("accepted",false)),"cross_lot_release_queues")
	_cross_boundary(model)
	_check(city.planning_reservations.is_empty(),"cross_lot_release_commits")
	_check(city.events.any(func(event: Dictionary)->bool:return str(event.get("kind","")) == "release_reservation" and event.get("source_lot_ids",[]) == preview.get("source_lot_ids",[])),"cross_lot_release_event_keeps_source_lot_ids")

	city.lots[0]["occupant"] = "occupied-building"
	city._refresh_parcel_index()
	var occupied_preview := Planning.polygon_candidate(city,polygon,Vector2.INF)
	_check(not bool(occupied_preview.get("allowed",false)) and str(occupied_preview.get("reason","")).contains("已有房屋"),"cross_lot_occupied_source_is_rejected")
	city.lots[0]["occupant"] = ""
	var gap_polygon := _box(Vector2(source[0].x+0.1,source[0].y+0.2),Vector2(city.lots[2]["polygon"][2].x-source[0].x-0.2,1.6))
	var gap_preview := Planning.polygon_candidate(city,gap_polygon,Vector2.INF)
	_check(not bool(gap_preview.get("allowed",false)) and str(gap_preview.get("reason","")).contains("连续"),"cross_lot_gap_is_rejected")

	var failures: Array[String] = []
	for label in checks:
		if not checks[label]: failures.append(label)
	print("ROUND158_CROSS_LOT_RESERVATION ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
