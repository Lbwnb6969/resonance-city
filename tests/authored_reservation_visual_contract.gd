extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Layer = preload("res://scripts/visual/authored_reservation_layer.gd")
const OUTPUT := "res://验证记录/round190_作者留地构图/"
var checks: Dictionary = {}
var failures: Array[String] = []

class MapView extends Control:
	var shown_world: RefCounted
	var black := false
	var daylight_state := {"world_tint":Color.WHITE}
	func point(p: Vector2) -> Vector2:
		return Vector2((p.x-p.y)*28,(p.x+p.y-32)*14)+Vector2(640,400)

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var opportunities := First.opportunities(city)
	var frame := int(city.cfg["timing"]["phrase_frames"])
	var ordinary: Dictionary = opportunities["public_candidates"][1]
	var seed_position: Array = opportunities["seed_candidates"][0]["position"]
	var reserved := city.request({"kind":"reserve","position":ordinary["position"]},frame)
	var seeded := city.request(PlayerExpression.operation("warm",seed_position),frame)
	check(bool(reserved.get("accepted",false)) and bool(seeded.get("accepted",false)) and Layer.records(city).is_empty(),"pending_operations_never_draw_future_land")
	city.settle(frame)
	var snapshot := city.snapshot()
	var records := Layer.records(city)
	var actual_id := ""
	for family: Dictionary in city.families.values():
		if bool(family.get("player_expression",false)): actual_id = str(family.get("expression_reservation_id",""))
	check(city.planning_reservations.size() == 2 and records.size() == 1 and str(records[0]["reservation_id"]) == actual_id,"only_actual_authored_family_reservation_is_emphasized")
	var record: Dictionary = records[0]
	var actual: Dictionary = city.planning_at(record["position"])
	check(str(actual.get("reservation_id","")) == actual_id and record["polygon"] == actual["polygon"],"drawing_uses_exact_current_clickable_footprint")
	var inside := true
	for patch in record["patches"]:
		for point in patch: inside = inside and Geometry2D.is_point_in_polygon(point,record["polygon"])
	for stroke in record["strokes"]:
		for point in stroke: inside = inside and Geometry2D.is_point_in_polygon(point,record["polygon"])
	check(inside and not record["patches"].is_empty() and not record["strokes"].is_empty(),"all_grass_detail_stays_within_true_reserved_land")
	var center_clear := true
	for patch in record["patches"]: center_clear = center_clear and not Geometry2D.is_point_in_polygon(record["position"],patch)
	check(center_clear and record["label"] == "你留下的空地","unbuilt_center_and_short_ownership_marker")
	var view := MapView.new()
	view.shown_world = city
	view.size = Vector2(1280,800)
	root.add_child(view)
	var layer := Layer.new()
	view.add_child(layer)
	layer.sync(view)
	var marker: Dictionary = layer.parcels[0]
	check(layer.ground.z_index == -27 and not layer.ground.z_as_relative and layer.z_index == 52 and str(layer.hit_reservation(marker["label_bounds"].get_center()).get("reservation_id","")) == actual_id,"ground_sits_below_buildings_and_label_hit_returns_same_real_reservation")
	check(city.snapshot() == snapshot,"visual_sync_does_not_change_world_rng_audio_events_or_archive")
	var released := city.request({"kind":"release_reservation","id":actual_id},frame*2)
	city.settle(frame*2)
	layer.sync(view)
	check(bool(released.get("accepted",false)) and city.planning_reservations.size() == 1 and Layer.records(city).is_empty() and layer.parcels.is_empty(),"released_authored_land_disappears_while_ordinary_reservation_remains")
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	FileAccess.open(OUTPUT+"authored_reservation_visual.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"reservation_id":actual_id,"patches":record["patches"].size(),"grass_strokes":record["strokes"].size(),"scope":"Drawing-data and read-only sync contract. Real GPU composition is reviewed by the root agent."},"\t"))
	print("AUTHORED_RESERVATION_VISUAL ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
