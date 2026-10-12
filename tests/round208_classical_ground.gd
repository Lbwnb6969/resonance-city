extends SceneTree
## Read-only continuous ground and inhabited-street focus. No live audio device.
const World = preload("res://scripts/world/continuous_world.gd")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
const Miniature = preload("res://scripts/visual/miniature_valley_material.gd")
const Geometry = preload("res://scripts/visual/valley_terrain_visual_geometry.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const Art = preload("res://scripts/visual/city_art_direction.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const OUTPUT := "res://验证记录/round208_古典街景地面/ground_contract.json"
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
	if not ok:
		failures.append(label)
		push_error(label)

func _color_gap(a: Color,b: Color) -> float:
	return Vector3(a.r,a.g,a.b).distance_to(Vector3(b.r,b.g,b.b))

func _on_road(city: RefCounted,p: Vector2) -> bool:
	for segment: Dictionary in city.near_road_segments(p,1.0):
		var at := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
		if p.distance_to(at) <= Miniature.road_width(city,segment["road"])+0.001: return true
	return false

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","uses_dummy_audio_only")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var before := city.snapshot()
	var data := Geometry.build(city.terrain)
	var area := 0.0
	var no_water := true
	var no_bands := true
	for surface: Dictionary in data["continuous_surfaces"]:
		var polygon: PackedVector2Array = surface["polygon"]
		area += Spatial.polygon_area(polygon)
		no_bands = no_bands and polygon.size() == 3 and not surface.has("band")
		for overlap in Geometry2D.intersect_polygons(polygon,city.terrain.water):
			no_water = no_water and Spatial.polygon_area(overlap) < 0.00001
	var bank_area := Spatial.polygon_area(city.terrain.left_bank)+Spatial.polygon_area(city.terrain.right_bank)
	check(no_bands and no_water and absf(area-bank_area) < 0.001,"unbanded_triangles_cover_the_actual_two_banks_and_preserve_the_real_river")
	var color_steps := 0.0
	var distinct: Dictionary = {}
	var previous := Miniature.earth_color(city.terrain,Vector2(4,2))
	for index in range(1,1001):
		var color := Miniature.earth_color(city.terrain,Vector2(4,2+float(index)*0.01))
		color_steps = maxf(color_steps,_color_gap(previous,color))
		distinct[color] = true
		previous = color
	check(distinct.size() > 500 and color_steps < 0.001 and _color_gap(Miniature.earth_color(city.terrain,Vector2(4,2)),previous) > 0.06,"real_hill_height_and_slope_have_continuous_color_without_flattening_the_relief")
	var street := Miniature.street_geometry(city)
	var road_bound := true
	var inhabited := true
	for kind: String in ["curbs","joints"]:
		for path: PackedVector2Array in street[kind]:
			for p in path: road_bound = road_bound and _on_road(city,p)
	for paving: Dictionary in street["paving"]:
		var p := Vector2.ZERO
		for vertex: Vector2 in paving["polygon"]:
			p += vertex
			road_bound = road_bound and _on_road(city,vertex)
		p /= float(paving["polygon"].size())
		inhabited = inhabited and not city.index.query_circle(p,2.1).is_empty()
	check(road_bound and inhabited and not street["paving"].is_empty() and street["joints"].size() > street["curbs"].size(),"fine_stone_paving_and_staggered_joints_stay_on_real_inhabited_frontages")
	var empty := World.new("2026100900000062",true,"river_valley")
	var empty_before := empty.snapshot()
	var empty_street := Miniature.street_geometry(empty)
	var dirt_gap := 0.0
	for p: Vector2 in [Vector2(4,2),Vector2(5,12),Vector2(26,16)]:
		var polygon := PackedVector2Array([p,p+Vector2(0.1,0),p+Vector2(0,0.1)])
		dirt_gap = maxf(dirt_gap,_color_gap(Miniature.earth_color(city.terrain,p),Miniature.dirt_colors(city.terrain,polygon)[0]))
	check(empty_street["paving"].is_empty() and empty_street["curbs"].is_empty() and empty_street["joints"].is_empty() and dirt_gap < 0.08,"unbuilt_roads_are_readable_low_contrast_earth_without_stone_edges_or_grid_detail")
	check(city.snapshot() == before and empty.snapshot() == empty_before,"terrain_and_street_queries_preserve_world_save_rng_and_occupancy")
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
	var terrain_rebuilds: int = terrain.terrain_geometry_rebuilds
	var street_rebuilds: int = urban.street_material_rebuilds
	var retained_land: Array = terrain.land_material
	var retained_roads: Array = urban.road_material
	var road_redraws: int = urban.urban_parts["roads"].update_count
	fixture.pan = Vector2(80,-37)
	fixture.view_zoom = 0.6
	terrain.sync(fixture)
	urban.sync(fixture)
	await process_frame
	check(terrain.terrain_geometry_rebuilds == terrain_rebuilds and urban.street_material_rebuilds == street_rebuilds and is_same(retained_land,terrain.land_material) and is_same(retained_roads,urban.road_material) and urban.urban_parts["roads"].update_count == road_redraws,"pan_and_zoom_reuse_retained_vertex_materials_stone_geometry_and_road_draw_commands")
	check(terrain.land_material.size() == data["continuous_surfaces"].size() and terrain.water_material.size() == 32 and terrain.terrain_geometry["shore_faces"] == data["shore_faces"],"default_demo_draw_path_uses_interpolated_land_and_retains_32_water_layers_and_actual_stone_bank")
	city.era = 2
	urban.sync(fixture)
	check(not urban._classical_streets() and not urban.street_material["paving"].is_empty(),"later_era_base_roads_keep_their_existing_path_with_surviving_classical_frontage")
	var modern := World.new("2026100900000062",true,"river_valley")
	modern.build_first_composition_starter()
	for building: Dictionary in modern.buildings: building["era"] = 2
	check(Miniature.street_geometry(modern)["paving"].is_empty(),"new_era_buildings_do_not_acquire_classical_stone_frontages")
	city.era = 1
	fixture.art_direction.selected_id = "clay"
	terrain.sync(fixture)
	urban.sync(fixture)
	check(not terrain._miniature_style() and terrain.palette == Art.PALETTES["clay"] and urban.street_material["paving"].is_empty(),"optional_comparison_retains_its_height_bands_and_own_palette")
	fixture.art_direction.selected_id = "baseline"
	terrain.sync(fixture)
	urban.sync(fixture)
	check(urban.road_material.all(func(road: Dictionary) -> bool: return road["colors"].size() == road["polygon"].size()),"returning_to_default_rebuilds_the_real_dirt_vertex_palette")
	var other := World.new("2026100900000062",true,"lake_basin")
	fixture.shown_world = other
	terrain.sync(fixture)
	urban.sync(fixture)
	check(not terrain._miniature_style() and terrain.land_material.is_empty() and urban.street_material["paving"].is_empty(),"other_terrain_families_keep_their_existing_material_path")
	fixture.shown_world = city
	var candidate: Array = First.opportunities(city)["seed_candidates"][0]["position"]
	var frame := int(city.cfg["timing"]["phrase_frames"])
	var accepted := city.request(PlayerExpression.operation("deep",candidate),frame)
	city.settle(frame)
	var authored_before := city.snapshot()
	urban.sync(fixture)
	check(bool(accepted.get("accepted",false)) and urban.street_material_rebuilds > street_rebuilds and city.snapshot() == authored_before,"an_actual_author_birth_refreshes_frontage_read_only_without_changing_its_identity")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"continuous_triangles":data["continuous_surfaces"].size(),"actual_bank_area":bank_area,"drawn_land_area":area,"maximum_nearby_hill_color_step":color_steps,"distinct_hill_colors":distinct.size(),"maximum_dirt_ground_color_gap":dirt_gap,"occupied_paving_segments":street["paving"].size(),"occupied_curbs":street["curbs"].size(),"occupied_stone_joints":street["joints"].size(),"terrain_prepare_ms":terrain.terrain_prepare_ms},"scope":"Dummy real World geometry, read-only land/street material, actual author birth and retained camera caches. Root owns live image review; no human aesthetic conclusion."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND208_CLASSICAL_GROUND ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	fixture.free()
	quit(0 if failures.is_empty() else 1)
