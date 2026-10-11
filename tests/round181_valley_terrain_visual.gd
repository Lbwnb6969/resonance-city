extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
const Geometry = preload("res://scripts/visual/valley_terrain_visual_geometry.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const SEED := "2026100900000062"
const OUTPUT := "res://验证记录/round181_视觉地基/terrain_geometry.json"
var checks: Dictionary = {}
var evidence: Dictionary = {}
var failures: Array[String] = []
class Fixture extends Control:
	var shown_world: ContinuousWorld
	var pan := Vector2.ZERO
	var view_zoom := 0.88
	var black := false
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
func _area(polygon: PackedVector2Array) -> float: return Spatial.polygon_area(polygon)
func _overlap(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var result := 0.0
	for piece in Geometry2D.intersect_polygons(a,b): result += _area(piece)
	return result
func _run() -> void:
	var world := World.new(SEED,true,"river_valley")
	world.build_first_composition_starter()
	var snapshot := world.snapshot()
	var began := Time.get_ticks_usec()
	var data := Geometry.build(world.terrain)
	var milliseconds := float(Time.get_ticks_usec()-began)/1000.0
	check(world.snapshot() == snapshot,"visual_geometry_keeps_world_rules_rng_occupancy_save_and_music_state")
	var land_area := 0.0
	var water_overlap := 0.0
	var bands: Array = []
	var valid := true
	for surface in data["surfaces"]:
		var polygon: PackedVector2Array = surface["polygon"]
		land_area += _area(polygon)
		water_overlap += _overlap(polygon,world.terrain.water)
		valid = valid and Geometry2D.triangulate_polygon(polygon).size() > 0
		if not bands.has(surface["band"]): bands.append(surface["band"])
	check(valid and water_overlap < 0.001 and absf(land_area-_area(world.terrain.left_bank)-_area(world.terrain.right_bank)) < 0.3,"height_surfaces_partition_the_actual_banks_without_water_or_missing_ground")
	bands.sort()
	check(bands == [0,1,2,3],"real_river_bend_contains_four_readable_height_bands")
	var contour_error := 0.0
	for contour in data["contours"]:
		for point in contour["path"]: contour_error = maxf(contour_error,absf(world.terrain.height_at(point)-float(contour["height"])))
	check(not data["contours"].is_empty() and contour_error < 0.002,"contour_lines_follow_actual_noise_height_instead_of_decorative_circles")
	var actual_shore := true
	for face in data["shore_faces"]:
		for index in range(2): actual_shore = actual_shore and world.terrain.water.has(face["edge"][index]) and is_equal_approx(float(face["heights"][index]),world.terrain.height_at(face["edge"][index]))
	check(not data["shore_faces"].is_empty() and actual_shore,"visible_bank_faces_use_actual_shore_vertices_and_actual_height_to_water_level")
	var water_layers_valid := absf(_overlap(data["channel"],world.terrain.water)-_area(data["channel"])) < 0.001
	for polygon in data["shallow_water"]: water_layers_valid = water_layers_valid and absf(_overlap(polygon,world.terrain.water)-_area(polygon)) < 0.001
	check(water_layers_valid and not data["shallow_water"].is_empty() and _area(data["channel"]) < _area(world.terrain.water),"shallow_edges_and_deeper_channel_stay_inside_the_real_water_footprint")
	var rims_valid := true
	for polygon in data["rims"]: rims_valid = rims_valid and _overlap(polygon,world.terrain.water) < 0.0001
	check(rims_valid and not data["rims"].is_empty(),"near_bank_land_uses_the_actual_shore_buffer_without_filling_the_river")
	var fixture := Fixture.new()
	fixture.size = Vector2(1440,900)
	fixture.shown_world = world
	var ground := Ground.new()
	root.add_child(fixture)
	fixture.add_child(ground)
	ground.sync(fixture)
	check(ground.terrain_geometry_rebuilds == 1 and ground.terrain_geometry == data,"retained_layer_prepares_the_actual_geometry_once")
	await process_frame
	await process_frame
	check(ground.rebuild_count == 1 and not ground.drawn_polygons.is_empty(),"retained_canvas_consumes_the_real_surfaces_in_one_valid_draw")
	var count := ground.terrain_geometry_rebuilds
	var updates := ground.update_count
	var canvas_draws := ground.rebuild_count
	fixture.pan = Vector2(73,-42)
	ground.sync(fixture)
	await process_frame
	check(ground.terrain_geometry_rebuilds == count and ground.update_count == updates and ground.rebuild_count == canvas_draws,"camera_pan_retains_surface_geometry_and_existing_draw_commands")
	fixture.view_zoom = 1.21
	ground.sync(fixture)
	ground.modulate = Color(0.42,0.52,0.68)
	ground.sync(fixture)
	check(ground.terrain_geometry_rebuilds == count,"zoom_and_unified_night_tint_reuse_the_same_terrain_geometry")
	var projection_error := 0.0
	for polygon in [world.lots[0]["polygon"],world.public_sites[0]["polygon"],data["surfaces"][0]["polygon"],data["rims"][0]]:
		var drawn := ground._project_polygon(polygon)
		for index in range(polygon.size()):
			var point: Vector2 = polygon[index]
			var expected := IsoProjection.to_screen(point-Vector2(16,16),ground.position,fixture.view_zoom,Vector2(28,14),world.terrain.height_at(point))
			projection_error = maxf(projection_error,ground.to_global(drawn[index]).distance_to(expected))
	check(projection_error < 0.001,"terrain_lots_and_public_footprints_share_the_unchanged_real_projection")
	var old_script := GDScript.new()
	old_script.source_code = FileAccess.get_file_as_string("res://废弃/第181视觉前/valley_ground_layer.gd.txt").replace("\r","")
	check(old_script.reload() == OK,"head_ground_backup_remains_a_loadable_original")
	var reference = old_script.new()
	reference.city = world
	ground.role = "urban"
	check(ground._urban_contents() == reference._urban_contents(),"roads_facilities_reservations_lots_and_fabric_keep_the_original_retention_contract")
	var frame := int(world.cfg["timing"]["phrase_frames"])
	world.request({"kind":"civic","position":First.opportunities(world)["public_candidates"][0]["position"]},frame)
	world.settle(frame)
	ground.role = "terrain"
	ground.sync(fixture)
	check(ground.terrain_geometry_rebuilds == count and ground._urban_contents() == reference._urban_contents(),"real_growth_and_facility_settlement_do_not_rebuild_static_terrain_or_change_urban_draw_data")
	var changed := World.new("2026100900000063",true,"river_valley")
	fixture.shown_world = changed
	ground.sync(fixture)
	check(ground.terrain_geometry_rebuilds == count+1 and ground.terrain_geometry != data,"new_real_terrain_identity_invalidates_the_retained_geometry")
	fixture.shown_world = World.new(SEED,true,"lake_basin")
	ground.sync(fixture)
	check(ground.terrain_geometry.get("surfaces",[]).is_empty(),"other_terrain_families_keep_their_existing_visual_path")
	evidence = {"preparation_ms":milliseconds,"surface_count":data["surfaces"].size(),"contour_count":data["contours"].size(),"bank_face_count":data["shore_faces"].size(),"bands":bands,"land_area":land_area,"water_overlap":water_overlap,"maximum_contour_height_error":contour_error,"maximum_projection_error":projection_error,"scope":"Actual geometry and retained-cache contract; visual enjoyment requires screenshots and human feedback."}
	reference.free()
	fixture.free()
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND181_VALLEY_TERRAIN_VISUAL "+JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
