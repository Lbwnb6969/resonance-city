extends SceneTree
## One Dummy contract: real reserved-land conversion, heard geometry and camera reuse.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const PublicGeometry = preload("res://scripts/visual/public_space_visual_geometry.gd")
const Court = preload("res://scripts/visual/classical_civic_court.gd")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
const Miniature = preload("res://scripts/visual/miniature_valley_material.gd")
const Art = preload("res://scripts/visual/city_art_direction.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
const OUTPUT := "res://验证记录/round210_文化馆院地/court_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class ClockView extends RefCounted:
	var renderer := {"transport":{"audible_frame":0.0}}

class Fixture extends Control:
	var shown_world: ContinuousWorld
	var pan := Vector2.ZERO
	var view_zoom := 1.65
	var black := false
	var art_direction := Art.new()
	var clock := ClockView.new()
	var road_draw_polygons: Array[Dictionary] = []
	var ground_patches: Array[PackedVector2Array] = []
	var ground_contours: Array[PackedVector2Array] = []
	func _shown_city_key() -> Array: return [shown_world,shown_world.phrase_index]

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _intersection_area(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var area := 0.0
	for overlap: PackedVector2Array in Geometry2D.intersect_polygons(a,b): area += Spatial.polygon_area(overlap)
	return area

func _line_enters(line: PackedVector2Array,polygon: PackedVector2Array) -> bool:
	for clipped: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(line,polygon):
		if clipped.size() >= 2 and clipped[0].distance_to(clipped[-1]) > 0.0001: return true
	return false

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_only")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var candidate: Dictionary = First.opportunities(city)["public_candidates"][0]
	var model := Model.new(city,1.3409036)
	var reserved := model.submit({"kind":"reserve","position":candidate["position"]})
	var rate := int(city.cfg["timing"]["sample_rate"])
	var boundary := model.next_boundary
	model.render_block({},boundary-1,2,rate)
	check(bool(reserved.get("accepted",false)) and city.planning_reservations.size() == 1,"actual_public_land_is_reserved_at_the_real_boundary")
	if city.planning_reservations.is_empty(): _finish({}); return
	var reservation: Dictionary = city.planning_reservations[0]
	var targets := Geometry2D.offset_polygon(reservation["polygon"],-0.04,Geometry2D.JOIN_MITER)
	var target: PackedVector2Array = targets[0]
	var p := Spatial.bounds(target).get_center()
	var hole := PackedVector2Array([p+Vector2(-0.07,-0.07),p+Vector2(0.07,-0.07),p+Vector2(0.07,0.07),p+Vector2(-0.07,0.07)])
	var preview := PartialPublic.preview_footprints(city,str(reservation["reservation_id"]),"civic",[target],[hole])
	var requested := model.submit({"kind":"civic","partial":true,"source_reservation_id":reservation["reservation_id"],
		"target_polygons":[target],"target_holes":[hole],"source_revision":preview.get("source_revision","")})
	boundary = model.next_boundary
	model.render_block({},boundary-1,2,rate)
	var site: Dictionary = {}
	for current: Dictionary in city.public_sites:
		if str(current.get("source_reservation_id","")) == str(reservation["reservation_id"]): site = current
	check(bool(preview.get("accepted",false)) and bool(requested.get("accepted",false)) and not site.is_empty(),"actual_transaction_creates_a_civic_with_a_real_inner_hole_and_remaining_land")
	if site.is_empty(): _finish({"preview":preview,"requested":requested}); return
	var before := city.snapshot()
	var court := Court.new()
	court.sync(city,boundary-1)
	var early: bool = court.courts.is_empty()
	var heard_before := model.presentation_world(boundary-1)
	court.sync(heard_before,boundary-1)
	check(early and court.courts.is_empty() and not heard_before.public_sites.any(func(s: Dictionary) -> bool: return str(s["id"]) == str(site["id"])),"render_ahead_and_the_audible_snapshot_cannot_draw_future_civic_land")
	var shown := model.presentation_world(boundary)
	var shown_before := shown.snapshot()
	court.sync(shown,boundary)
	var layouts: Array = court.courts.get(str(site["id"]),[])
	var blocked: Array[PackedVector2Array] = Court._exclusions(shown)
	blocked.append(hole)
	var bounded := not layouts.is_empty()
	var no_overlap := true
	var approach := true
	var area := 0.0
	var joints := 0
	var paths := 0
	for layout: Dictionary in layouts:
		approach = approach and layout["entrance"] == Vector2(float(site["entrance"][0]),float(site["entrance"][1])) and Vector2(layout["front"]).dot(Vector2(layout["position"]).direction_to(layout["entrance"])) > 0.9999
		joints += layout["joints"].size()
		paths += layout["paths"].size()
		for polygon: PackedVector2Array in layout["pieces"]+layout["paths"]:
			bounded = bounded and absf(Spatial.polygon_area(polygon)-Spatial.footprint_intersection_area(polygon,site)) < 0.0001
			for exclusion: PackedVector2Array in blocked: no_overlap = no_overlap and _intersection_area(polygon,exclusion) < 0.00001
		for polygon: PackedVector2Array in layout["pieces"]: area += Spatial.polygon_area(polygon)
		for joint: PackedVector2Array in layout["joints"]:
			for exclusion: PackedVector2Array in blocked: no_overlap = no_overlap and not _line_enters(joint,exclusion)
	check(bounded and no_overlap and joints > 0 and paths > 0,"stone_fill_joints_and_short_approach_stay_inside_real_fill_away_from_holes_water_roads_houses_and_reservations")
	check(approach and layouts.size() == PublicGeometry.components(site).size(),"each_actual_component_uses_its_actual_anchor_and_road_entrance")
	var fixture := Fixture.new()
	fixture.size = Vector2(1440,900)
	fixture.shown_world = shown
	fixture.clock.renderer.transport.audible_frame = boundary
	for road: Dictionary in shown.roads:
		for polygon in Geometry2D.offset_polyline(road["path"],Miniature.road_width(shown,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			fixture.road_draw_polygons.append({"polygon":polygon,"color":Color("d3bb93") if road["bridge"] else Color("f1eee0")})
	root.add_child(fixture)
	var ground := Ground.new()
	ground.role = "urban"
	fixture.add_child(ground)
	ground.sync(fixture)
	await process_frame
	var public_part: Variant = ground.urban_parts["public"]
	var actual_piece: PackedVector2Array = layouts[0]["pieces"][0]
	var projected: PackedVector2Array = public_part._project_polygon(actual_piece)
	var heights_match := true
	for index in range(actual_piece.size()):
		heights_match = heights_match and projected[index].is_equal_approx(IsoProjection.to_screen(actual_piece[index]-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),shown.terrain.height_at(actual_piece[index])))
	check(is_same(public_part.civic_court,ground.civic_court) and ground.civic_court.courts.has(str(site["id"])) and heights_match,"production_public_layer_shares_the_court_and_projects_actual_ground_height")
	var builds: int = ground.civic_court.rebuild_count
	var retained: Array = ground.civic_court.courts[str(site["id"])]
	var retained_key: Array = ground.civic_court.key.duplicate(true)
	fixture.pan = Vector2(160,-74)
	fixture.view_zoom = 0.7
	ground.sync(fixture)
	await process_frame
	check(ground.civic_court.rebuild_count == builds and ground.civic_court.key == retained_key and is_same(retained,ground.civic_court.courts[str(site["id"])]),"pan_and_zoom_reuse_the_same_world_court_geometry")
	var camera_rebuilds: int = ground.civic_court.rebuild_count-builds
	fixture.art_direction.selected_id = "clay"
	ground.sync(fixture)
	var comparison_retained: bool = ground.civic_court.courts.is_empty()
	var later := site.duplicate(true)
	later["created_phrase"] = 12
	var park := site.duplicate(true)
	park["kind"] = "park"
	check(comparison_retained and not Court.applies(shown,later) and not Court.applies(shown,park),"parks_comparison_styles_and_later_birth_eras_keep_the_original_public_entry")
	check(city.snapshot() == before and shown.snapshot() == shown_before,"court_queries_and_draws_preserve_world_rng_pending_and_public_service")
	var evidence := {"site_id":site["id"],"components":layouts.size(),"actual_fill_area":area,"stone_joints":joints,"short_approach_pieces":paths,"actual_hole_area":Spatial.polygon_area(hole),"court_build_ms":court.last_build_ms,"camera_geometry_rebuilds":camera_rebuilds}
	fixture.free()
	model.close_background_settlement()
	_finish(evidence)

func _finish(evidence: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"One Dummy contract using real reserve/civic transactions and public components, audible-boundary gating, retained ground projection and read-only World. No real device or human aesthetic approval."},"\t")+"\n")
	print("ROUND210_CLASSICAL_CIVIC_COURT ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
