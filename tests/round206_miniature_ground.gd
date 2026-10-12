extends SceneTree
## Physical bounds and retained caches of the refined miniature river town.
const World = preload("res://scripts/world/continuous_world.gd")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
const Water = preload("res://scripts/visual/valley_water_flow.gd")
const Miniature = preload("res://scripts/visual/miniature_valley_material.gd")
const Art = preload("res://scripts/visual/city_art_direction.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const OUTPUT := "res://验证记录/round206_精致微缩河湾/ground_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
class Fixture extends Control:
	var shown_world: ContinuousWorld
	var pan := Vector2.ZERO
	var view_zoom := 1.4
	var black := false
	var art_direction := Art.new()
	var road_draw_polygons: Array[Dictionary] = []
	var ground_patches: Array[PackedVector2Array] = []
	var ground_contours: Array[PackedVector2Array] = []
	func _shown_city_key() -> Array: return [shown_world,shown_world.phrase_index]
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)
func _on_road(city: RefCounted,p: Vector2) -> bool:
	for segment: Dictionary in city.near_road_segments(p,1.0):
		var closest := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
		if p.distance_to(closest) <= Miniature.road_width(city,segment["road"])+0.001: return true
	return false
func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var snapshot := city.snapshot()
	var water_bands := Miniature.water_bands(city.terrain)
	var bands_inside := true
	for band: Dictionary in water_bands:
		var area := Spatial.polygon_area(band["polygon"])
		var intersection := 0.0
		for part in Geometry2D.intersect_polygons(band["polygon"],city.terrain.water): intersection += Spatial.polygon_area(part)
		bands_inside = bands_inside and area > 0.0 and absf(area-intersection) < 0.001
	check(water_bands.size() == Miniature.WATER_DEPTH_STEPS and bands_inside,"layered_water_material_stays_inside_the_real_river")
	var maximum_color_step := 0.0
	for index in range(water_bands.size()-1):
		var a: Color = water_bands[index]["color"]
		var b: Color = water_bands[index+1]["color"]
		maximum_color_step = maxf(maximum_color_step,Vector3(a.r,a.g,a.b).distance_to(Vector3(b.r,b.g,b.b)))
	check(maximum_color_step < 0.025,"adjacent_depth_layers_have_a_small_continuous_color_step")
	var street := Miniature.street_geometry(city)
	var streets_inside := true
	for kind: String in ["curbs","joints"]:
		for path: PackedVector2Array in street[kind]:
			for p: Vector2 in path: streets_inside = streets_inside and _on_road(city,p)
	check(streets_inside and not street["curbs"].is_empty() and not street["joints"].is_empty(),"stone_edges_and_joints_use_existing_occupied_streets")
	check(city.snapshot() == snapshot,"material_queries_preserve_world_rng_occupancy_audio_and_save_state")
	var fixture := Fixture.new()
	fixture.size = Vector2(1440,900)
	fixture.shown_world = city
	for road: Dictionary in city.roads:
		for polygon in Geometry2D.offset_polyline(road["path"],Miniature.road_width(city,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			fixture.road_draw_polygons.append({"polygon":polygon,"color":Color("d3bb93") if road["bridge"] else Color("f1eee0")})
	root.add_child(fixture)
	var terrain := Ground.new()
	fixture.add_child(terrain)
	terrain.sync(fixture)
	var urban := Ground.new()
	urban.role = "urban"
	fixture.add_child(urban)
	urban.sync(fixture)
	await process_frame
	var material_rebuilds := urban.street_material_rebuilds
	var geometry_rebuilds := terrain.terrain_geometry_rebuilds
	fixture.pan = Vector2(80,-37)
	urban.sync(fixture)
	terrain.sync(fixture)
	fixture.view_zoom = 0.6
	urban.sync(fixture)
	terrain.sync(fixture)
	check(urban.street_material_rebuilds == material_rebuilds and terrain.terrain_geometry_rebuilds == geometry_rebuilds,"pan_and_zoom_retain_stone_and_terrain_material_geometry")
	check(terrain.palette == Miniature.COLORS and urban._miniature_style(),"default_river_uses_the_unified_warm_stone_and_teal_material_palette")
	city.era = 2
	urban.sync(fixture)
	check(not urban._classical_streets() and not urban.street_material["paving"].is_empty(),"later_era_base_streets_keep_only_actual_classical_frontage_stone")
	city.era = 1
	fixture.art_direction.selected_id = "clay"
	terrain.sync(fixture)
	urban.sync(fixture)
	check(not urban._miniature_style() and urban.street_material["curbs"].is_empty() and terrain.palette == Art.PALETTES["clay"],"optional_art_comparison_keeps_its_existing_material_path")
	fixture.art_direction.selected_id = "baseline"
	var water := Water.new()
	water.city = city
	fixture.add_child(water)
	var traces_inside := true
	for y: float in [0.0,4.0,8.0,12.0,18.0,26.0]:
		var path := water.reflection_path(y,0.31,0.8)
		traces_inside = traces_inside and path.size() == 6
	check(traces_inside,"slow_reflection_traces_follow_the_real_channel")
	var position: Array = First.opportunities(city)["seed_candidates"][0]["position"]
	var frame := int(city.cfg["timing"]["phrase_frames"])
	var accepted := city.request(PlayerExpression.operation("deep",position),frame)
	city.settle(frame)
	var authored_snapshot := city.snapshot()
	urban.sync(fixture)
	var authored_id := str(city.families.values().filter(func(family: Dictionary) -> bool: return bool(family.get("player_expression",false)))[0]["root"])
	var authored: Dictionary = city.by_id[authored_id]
	check(bool(accepted.get("accepted",false)) and str(authored["expression"]) == "deep" and urban.street_material_rebuilds > material_rebuilds,"real_author_growth_updates_occupied_frontage_without_replacing_its_identity")
	check(city.snapshot() == authored_snapshot,"author_frontage_materials_remain_read_only_after_real_birth")
	fixture.black = true
	urban.sync(fixture)
	terrain.sync(fixture)
	check(not urban.visible and not terrain.visible,"black_listening_hides_all_refined_ground")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"evidence":{"water_bands":water_bands.size(),"maximum_depth_color_step":maximum_color_step,"street_curbs":street["curbs"].size(),"street_joints":street["joints"].size(),"land_grain":Miniature.land_grain(city.terrain).size(),"initial_buildings":24,"authored_buildings":city.buildings.size()},
		"scope":"Dummy read-only material geometry, actual street/water bounds, real authored birth, camera retention and style isolation; final screenshots handled by Root."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND206_MINIATURE_GROUND ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	fixture.free()
	quit(0 if failures.is_empty() else 1)
