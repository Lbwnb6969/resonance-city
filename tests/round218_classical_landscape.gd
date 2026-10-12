extends SceneTree
## Minimum contract for the independent classical landscape presentation layer.
## Dummy only: no production Ground node, window, PCM or World mutation.
const World = preload("res://scripts/world/continuous_world.gd")
const TerrainGeometry = preload("res://scripts/visual/valley_terrain_visual_geometry.gd")
const Landscape = preload("res://scripts/visual/classical_landscape.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
const OUTPUT := "res://验证记录/round218_古典自然地表/landscape_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _blocked(city: RefCounted,heard_frame: int) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for building: Dictionary in city.buildings:
		if int(building.get("birth_frame",0)) > heard_frame: continue
		result.append(city.building_polygon(Vector2(float(building["position"][0]),float(building["position"][1]))))
	for road: Dictionary in city.roads:
		if bool(road.get("bridge",false)): continue
		var width := float(city.cfg["city"]["branch_road_half_width"]) if str(road.get("kind","")) == "branch" else float(city.cfg["terrain"]["template_road_half_width"])
		for polygon in Geometry2D.offset_polyline(road["path"],width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT): result.append(polygon)
	for group: Array in [city.public_sites,city.planning_reservations]:
		for record: Dictionary in group:
			if int(record.get("frame",0)) > heard_frame: continue
			var components := Spatial.footprint_components(record)
			var holes := Spatial.footprint_holes(record)
			if holes.is_empty(): result.append_array(components)
			else:
				for component: PackedVector2Array in components: result.append_array(PartialPublic._subtract_components(component,holes))
	return result

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_without_gpu_or_pcm")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var before := city.snapshot()
	var built := TerrainGeometry.build(city.terrain)
	var helper := Landscape.new()
	helper.prepare_terrain(city.terrain,built["continuous_surfaces"])
	var texture_image: Image = helper.land_texture.get_image() if helper.land_texture != null else null
	check(helper.land_texture != null and texture_image.get_width() == 2048 and texture_image.get_height() == 2048 and texture_image.has_mipmaps(),"hd_land_texture_is_2048_and_mipped")
	var uv_ok := true
	var white_ok := true
	for item: Dictionary in helper.land_material:
		var polygon: PackedVector2Array = item["polygon"]
		var uvs: PackedVector2Array = item["uvs"]
		uv_ok = uv_ok and polygon.size() == uvs.size() and item["colors"].size() == polygon.size()
		for uv: Vector2 in uvs: uv_ok = uv_ok and uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0
		for color: Color in item["colors"]: white_ok = white_ok and color == Color.WHITE
	check(not helper.land_material.is_empty() and uv_ok and white_ok,"real_surface_polygons_have_continuous_world_uvs_and_do_not_double_multiply_texture")
	var frame := 9223372036854775807
	check(helper.sync(city,frame),"first_heard_city_builds_derived_natural_geometry")
	var tufts: Array = helper.geometry["tufts"]
	var stones: Array = helper.geometry["stones"]
	check(tufts.size() <= 96 and stones.size() <= 44 and not tufts.is_empty() and not stones.is_empty(),"sparse_tuft_and_stone_caps_are_nonempty")
	var blocked := _blocked(city,frame)
	var clear := true
	for tuft: Dictionary in tufts:
		for path: PackedVector2Array in tuft["paths"]:
			clear = clear and path.size() >= 2
			for p: Vector2 in path:
				clear = clear and city.terrain.land_at(p)
				var disc := Spatial.circle_polygon(p,0.018)
				for obstruction: PackedVector2Array in blocked: clear = clear and not Spatial.overlaps(disc,obstruction)
	for stone: Dictionary in stones:
		var polygon: PackedVector2Array = stone["polygon"]
		clear = clear and polygon.size() >= 5 and city.terrain.land_at(polygon[0])
		for obstruction: PackedVector2Array in blocked: clear = clear and not Spatial.overlaps(polygon,obstruction)
	check(clear,"tufts_and_stones_stay_on_land_outside_heard_houses_roads_public_sites_and_reservations")
	var rebuilds := helper.rebuild_count
	var queries := helper.spatial_query_count
	var fork: RefCounted = city.fork()
	var fork_before: Dictionary = fork.snapshot()
	check(not helper.sync(fork,frame) and helper.rebuild_count == rebuilds and helper.spatial_query_count == queries,"same_value_world_fork_reuses_natural_geometry_without_queries")
	var source_unchanged: bool = city.snapshot() == before
	var fork_unchanged: bool = fork.snapshot() == fork_before
	if not source_unchanged or not fork_unchanged:
		print("LANDSCAPE_SNAPSHOT_DIFF source=",source_unchanged," fork=",fork_unchanged)
	check(source_unchanged and fork_unchanged,"landscape_prepare_and_sync_are_read_only_to_world_snapshot")
	var old_era := city.era
	city.era = 2
	check(helper.sync(city,frame) and helper.geometry["tufts"].is_empty() and helper.geometry["stones"].is_empty(),"later_era_has_no_classical_natural_details")
	city.era = old_era
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"prepare_count":helper.prepare_count,"prepare_ms":helper.prepare_ms,"texture_size":[helper.land_texture.get_width(),helper.land_texture.get_height()] if helper.land_texture != null else [],"mipmaps":texture_image.has_mipmaps() if texture_image != null else false,"land_material_count":helper.land_material.size(),"tuft_count":tufts.size(),"stone_count":stones.size(),"rebuild_count":helper.rebuild_count,"spatial_query_count":helper.spatial_query_count},"scope":"Independent classical_landscape helper only. Real river-valley terrain and continuous surfaces, HD world-UV texture, sparse derived tufts/stones, full obstruction read check, same-value World fork cache and era gate. Root owns Ground draw/compositing, river bank treatment, GPU window and human aesthetic review."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND218_LANDSCAPE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
