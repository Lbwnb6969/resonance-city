extends SceneTree
## Actual World parcels and production entries, with a numeric audible-frame owner.
const Details = preload("res://scripts/visual/classical_frontage_details.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Orientation = preload("res://scripts/visual/building_street_orientation.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Growth = preload("res://scripts/visual/audio_growth_mask.gd")
const OUTPUT := "res://验证记录/round208_古典街面细节/frontage_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class NumericTransport extends RefCounted:
	var audible_frame := 0
class NumericRenderer extends RefCounted:
	var transport := NumericTransport.new()
class NumericClock extends RefCounted:
	var renderer := NumericRenderer.new()
class FrontageOwner extends Control:
	var shown_world: RefCounted
	var black := false
	var clock := NumericClock.new()
	var building_geometry: Dictionary = {}
	var sprites: Dictionary = {}
	var token := 0
	func _shown_city_key() -> Array: return [token,shown_world.phrase_index]
	func bind(city: RefCounted,catalog: RefCounted) -> void:
		for sprite: Node2D in sprites.values(): sprite.free()
		sprites.clear()
		building_geometry.clear()
		shown_world = city
		token += 1
		for building: Dictionary in city.buildings:
			var id := str(building["district_id"])
			var p := Coupling.position_of(building)
			var direction := Orientation.street_orientation(city,p)
			var entry: Dictionary = catalog.entry_for(building,{},city.families.get(str(building.get("family_id","")),{}),direction)
			building_geometry[id] = {"key":[p,entry.get("id","")],"entry":entry}
			var sprite := Growth.new()
			sprite.use_master_clock = false
			sprite.progress = 1.0
			sprites[id] = sprite
	func release() -> void:
		for sprite: Node2D in sprites.values(): sprite.free()
		sprites.clear()

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _all_legal(city: RefCounted,module: Node2D) -> bool:
	for id: String in module.layouts:
		var building: Dictionary = city.by_id[id]
		var p := Coupling.position_of(building)
		for piece in module.layouts[id]["pieces"]:
			if not city.terrain.valid_footprint(piece.footprint): return false
			if not Spatial.exclusion(city,piece.footprint).is_empty(): return false
			for corner in piece.footprint:
				if corner.distance_to(p) > float(building["radius"]): return false
			var source: Dictionary = Orientation._source_access(city,p)
			if str(source.get("id","")) == str(building.get("lot_id","")) and source.has("polygon"):
				for corner in piece.footprint:
					if not Geometry2D.is_point_in_polygon(corner,source["polygon"]): return false
			var box := Spatial.bounds(piece.footprint)
			for segment: Dictionary in city.near_road_segments(box.get_center(),box.size.length()*0.5+0.55):
				for strip in Geometry2D.offset_polyline(PackedVector2Array([segment["a"],segment["b"]]),Fabric._road_width(city,segment["road"]),Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
					if not Geometry2D.intersect_polygons(strip,piece.footprint).is_empty(): return false
	return true

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_only")
	var catalog := Catalog.new()
	catalog.load_catalog()
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var owner := FrontageOwner.new()
	root.add_child(owner)
	owner.bind(city,catalog)
	owner.clock.renderer.transport.audible_frame = int(city.cfg["timing"]["phrase_frames"])
	var module := Details.new()
	var parent := Node2D.new()
	parent.y_sort_enabled = true
	parent.position = Vector2(621,403)
	parent.scale = Vector2(1.75,1.75)
	parent.modulate = Color(0.59,0.64,0.72)
	root.add_child(parent)
	parent.add_child(module)
	var baseline := city.snapshot()
	module.setup(owner)
	var initial: Dictionary = module.diagnostics()
	check(initial["houses"].size() == 24 and int(initial["visible_pieces"]) >= 40,"real_24_starter_houses_receive_restrained_lived_in_frontages")
	var kinds: Dictionary = {}
	var precise_projection := module.position == Vector2.ZERO and module.scale == Vector2.ONE and module.y_sort_enabled
	var two_per_house := true
	var toward_actual_street := true
	for id: String in module.layouts:
		var layout: Dictionary = module.layouts[id]
		two_per_house = two_per_house and layout["pieces"].size() <= 3 and layout["pieces"].size() >= 1
		var p: Vector2 = layout["root"]
		var front: Vector2 = Orientation.FACING[layout["orientation"]]
		var road: Dictionary = Fabric.nearest_road(city,p)
		toward_actual_street = toward_actual_street and front.dot(road["position"]-p) > 0.0
		for piece in layout["pieces"]:
			kinds[piece.kind] = true
			var expected := Projection2D.to_screen(piece.world_position-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(piece.world_position))
			precise_projection = precise_projection and piece.position.distance_to(expected) < 0.000001 and piece.scale == Vector2.ONE
			toward_actual_street = toward_actual_street and (piece.world_position-p).dot(front) > 0.0
	check(two_per_house and kinds.has("leaf_pot") and kinds.has("wood_crate") and kinds.has("terracotta_jar") and kinds.has("low_bench"),"residential_plants_and_distinct_wood_clay_commercial_objects_stay_below_three_per_house")
	check(precise_projection and toward_actual_street,"every_piece_uses_actual_street_orientation_terrain_foot_and_single_parent_pan_zoom")
	check(_all_legal(city,module),"all_starter_objects_stay_on_owned_land_clear_of_water_roads_public_and_reserved_footprints")
	var rebuilds: int = module.rebuild_count
	var queries: int = module.placement_query_count
	for ignored in range(100): module.sync(owner)
	check(rebuilds == module.rebuild_count and queries == module.placement_query_count and module.diagnostics()["houses"] == initial["houses"],"100_unchanged_visual_syncs_keep_stable_id_layout_without_repeating_geometry_queries")
	var first_id := str(module.layouts.keys()[0])
	var hidden_count: int = module.layouts[first_id]["pieces"].size()
	owner.sprites[first_id].progress = 0.45
	module.sync(owner)
	check(module.diagnostics()["visible_pieces"] == initial["visible_pieces"]-hidden_count and module.rebuild_count == rebuilds,"actual_growth_reveal_hides_its_frontage_without_rebuilding")
	owner.sprites[first_id].progress = 1.0
	module.sync(owner)
	check(city.snapshot() == baseline,"all_frontage_queries_leave_actual_world_save_audio_fields_and_rng_unchanged")
	# A real committed warm root also owns a real open-space reservation.
	var warm: RefCounted = city.fork()
	var at: Array = First.opportunities(warm)["seed_candidates"][0]["position"]
	var boundary := int(warm.cfg["timing"]["phrase_frames"])
	var accepted: Dictionary = warm.request(PlayerExpression.operation("warm",at),boundary)
	warm.settle(boundary)
	owner.bind(warm,catalog)
	owner.clock.renderer.transport.audible_frame = boundary
	baseline = warm.snapshot()
	module.sync(owner)
	var warm_record: Dictionary = module.diagnostics()
	check(bool(accepted.get("accepted",false)) and warm.planning_reservations.size() == 1 and _all_legal(warm,module) and warm_record["houses"].size() <= 28,"real_warm_root_and_reserved_garden_keep_objects_inside_owned_frontage_and_below_28_house_scope")
	check(warm.snapshot() == baseline,"warm_reserved_land_and_rng_are_not_written_by_details")
	# Render-ahead sprites are insufficient authority; the actual birth must be audible.
	var authored_id := ""
	for building: Dictionary in warm.buildings:
		if bool(building.get("player_expression",false)) and bool(building.get("family_anchor",false)): authored_id = str(building["district_id"])
	owner.clock.renderer.transport.audible_frame = boundary-1
	module.sync(owner)
	var silent_root := module.layouts.has(authored_id)
	if silent_root:
		for piece in module.layouts[authored_id]["pieces"]: silent_root = silent_root and not piece.visible
	check(silent_root,"future_birth_stays_hidden_even_when_cached_sprite_is_fully_revealed")
	owner.clock.renderer.transport.audible_frame = boundary
	module.sync(owner)
	var heard_root := module.layouts.has(authored_id)
	if heard_root:
		for piece in module.layouts[authored_id]["pieces"]: heard_root = heard_root and piece.visible
	check(heard_root,"accepted_real_house_shows_details_at_its_audible_birth_after_reveal")
	var ghost := Growth.new()
	ghost.progress = 1.0
	owner.sprites["future-cache-only"] = ghost
	owner.building_geometry["future-cache-only"] = owner.building_geometry[authored_id]
	module.sync(owner)
	check(not module.layouts.has("future-cache-only"),"future_art_cache_never_creates_a_house_or_frontage")
	# Later buildings use their own historical assets; old classical homes persist.
	var later: RefCounted = warm.fork()
	later.era = 2
	later.by_id[authored_id]["era"] = 2
	owner.bind(later,catalog)
	baseline = later.snapshot()
	module.sync(owner)
	check(not module.layouts.has(authored_id) and module.layouts.size() >= 20 and later.snapshot() == baseline,"birth_era_gate_excludes_later_buildings_and_retains_existing_classical_homes_read_only")
	parent.modulate = Color(0.27,0.36,0.48)
	var before_light := module.rebuild_count
	module.sync(owner)
	check(module.modulate == Color.WHITE and module.rebuild_count == before_light and not module.get_children().any(func(node: Node) -> bool: return node is PointLight2D),"night_light_is_inherited_once_from_parent_without_glow_or_geometry_rebuild")
	owner.black = true
	module.sync(owner)
	check(not module.visible,"black_listening_mode_hides_frontage_geometry")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"starter":initial,"warm":warm_record,
		"scope":"Standalone headless Dummy with actual 24-house World, imported production entries, committed warm root/reservation, real road/parcel queries and real reveal primitive. No window or physical audio. Root owns real-window aesthetic review and integration."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND208_FRONTAGE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	owner.release()
	owner.free()
	parent.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
