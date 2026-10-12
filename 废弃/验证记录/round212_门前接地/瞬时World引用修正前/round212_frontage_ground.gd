extends SceneTree
## Small real-World threshold geometry contract. Dummy; no production window.
const World = preload("res://scripts/world/continuous_world.gd")
const Frontage = preload("res://scripts/visual/classical_frontage_ground.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Orientation = preload("res://scripts/visual/building_street_orientation.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const Spatial = preload("res://scripts/world/city_spatial_planning.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const OUTPUT := "res://验证记录/round212_门前接地/frontage_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class Fixture extends Control:
	var shown_world: ContinuousWorld
	var building_geometry: Dictionary = {}
	var sprites: Dictionary = {}
	var art_direction := {"selected_id":"baseline"}
	var clock := {"renderer":{"transport":{"audible_frame":0}}}
	var pan := Vector2.ZERO
	var view_zoom := 1.0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func fill(fixture: Fixture,catalog: RefCounted) -> void:
	fixture.building_geometry.clear()
	fixture.sprites.clear()
	for building: Dictionary in fixture.shown_world.buildings:
		var id := str(building["district_id"])
		var p := Coupling.position_of(building)
		var entry: Dictionary = catalog.entry_for(building,{},fixture.shown_world.families.get(str(building.get("family_id","")),{}),Orientation.street_orientation(fixture.shown_world,p))
		var factor := 28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])
		fixture.building_geometry[id] = {"entry":entry,"scale":factor,"position":Projection2D.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),fixture.shown_world.terrain.height_at(p))}
		fixture.sprites[id] = {"progress":1.0}

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_without_a_window_or_live_device")
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var fixture := Fixture.new()
	fixture.shown_world = city
	var catalog := Catalog.new()
	catalog.load_catalog()
	fill(fixture,catalog)
	var before := city.snapshot()
	var helper := Frontage.new()
	helper.sync(fixture)
	var initial := helper.pads.duplicate(true)
	var counts := {"threshold":0,"wear":0}
	var touched: Dictionary = {}
	var bounded := true
	var aligned := true
	var no_conflicts := true
	var max_extent := 0.0
	for pad: Dictionary in helper.pads:
		counts[str(pad["kind"])] += 1
		var id := str(pad["building_id"])
		touched[id] = true
		var building: Dictionary = city.by_id[id]
		var root_position := Coupling.position_of(building)
		var polygon: PackedVector2Array = pad["polygon"]
		var lot: Dictionary = {}
		for record: Dictionary in city.lots:
			if str(record["id"]) == str(pad["lot_id"]) and str(record["occupant"]) == id: lot = record
		for p: Vector2 in polygon:
			max_extent = maxf(max_extent,p.distance_to(pad["step_front"]))
			bounded = bounded and (Geometry2D.is_point_in_polygon(p,lot["polygon"]) if not lot.is_empty() else p.distance_to(root_position) <= float(building["radius"])+0.000001)
		no_conflicts = no_conflicts and city.terrain.valid_footprint(polygon) and Spatial.exclusion(city,polygon).is_empty()
		for other: Dictionary in city.buildings:
			if str(other["district_id"]) != id: no_conflicts = no_conflicts and not Spatial.disc_hits(polygon,Coupling.position_of(other),float(other["radius"]))
		for site: Dictionary in city.public_sites:
			for hole: PackedVector2Array in Spatial.footprint_holes(site): no_conflicts = no_conflicts and not Spatial.overlaps(polygon,hole)
		for road: Dictionary in city.roads:
			for mask: PackedVector2Array in Geometry2D.offset_polyline(road["path"],Fabric._road_width(city,road),Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT): no_conflicts = no_conflicts and not Spatial.overlaps(polygon,mask)
		var geometry: Dictionary = fixture.building_geometry[id]
		var entry: Dictionary = geometry["entry"]
		var raw: Vector2 = Frontage.STEPS[str(entry["role"])]["center"]
		var model := Frontage._rotated(raw,int(entry["orientation"]))
		var model_pixels := Vector2((model.x-model.y)/sqrt(2.0),(model.x+model.y)/sqrt(2.0)*0.5)*float(geometry["scale"])*float(entry["pixels_per_world"])
		var world_pixels := Projection2D.to_screen(pad["step_front"]-root_position,Vector2.ZERO,1.0,Vector2(28,14))
		aligned = aligned and model_pixels.distance_to(world_pixels) < 0.0001 and int(pad["orientation"]) == Orientation.street_orientation(city,root_position)
	check(city.buildings.size() == 24 and counts["threshold"] > 0 and counts["wear"] > 0 and aligned,"actual_24_house_opening_uses_real_outer_steps_and_current_baked_street_orientation")
	check(bounded and no_conflicts and max_extent < 0.30,"thin_thresholds_and_short_wear_stay_on_existing_owned_ground_off_roads_water_neighbors_public_and_reservations")
	var rebuilds: int = helper.rebuild_count
	var queries: int = helper.spatial_query_count
	fixture.pan = Vector2(220,-130)
	fixture.view_zoom = 0.4
	fixture.clock.renderer.transport.audible_frame = 20
	check(not helper.sync(fixture) and helper.rebuild_count == rebuilds and helper.spatial_query_count == queries and helper.pads == initial,"pan_zoom_and_transport_ticks_reuse_geometry_without_new_spatial_queries")
	fixture.clock.renderer.transport.audible_frame = -1
	helper.sync(fixture)
	var preheard_empty := helper.pads.is_empty()
	fixture.clock.renderer.transport.audible_frame = 0
	helper.sync(fixture)
	var hidden_id := str(initial[0]["building_id"])
	fixture.sprites[hidden_id].progress = 0.6
	helper.sync(fixture)
	var revealing_hidden := helper.pads.all(func(pad: Dictionary) -> bool: return str(pad["building_id"]) != hidden_id)
	fixture.sprites[hidden_id].progress = 1.0
	helper.sync(fixture)
	check(preheard_empty and revealing_hidden and helper.pads == initial,"birth_audibility_and_complete_actual_sprite_reveal_gate_every_threshold_and_wear_pad")
	check(city.snapshot() == before,"geometry_and_reveal_queries_preserve_world_save_rng_roads_lots_and_acoustic_state")
	# A public hole is intentionally empty despite not being part of its solid.
	# Insert only an obstruction fixture, refresh the actual parcel index, then
	# verify output suppression and World immutability during that query.
	var probe: PackedVector2Array = initial[0]["polygon"]
	var box := Spatial.bounds(probe).grow(0.1)
	var outer := PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
	city.public_sites.append({"id":"round212-hole","kind":"park","position":[box.get_center().x,box.get_center().y],"polygon":outer,"hole_polygons":[probe],"active":false,"frame":0})
	city._refresh_parcel_index()
	var obstruction_before := city.snapshot()
	helper.sync(fixture)
	var hole_safe := helper.pads.all(func(pad: Dictionary) -> bool: return not Spatial.overlaps(pad["polygon"],probe))
	check(hole_safe and city.snapshot() == obstruction_before,"empty_public_holes_are_explicitly_excluded_and_parcel_identity_refreshes_the_read_only_cache")
	city.public_sites.pop_back()
	city.planning_reservations.append({"id":"round212-reservation","reservation_id":"round212-reservation","source_site_id":"fixture","polygon":probe,"position":[box.get_center().x,box.get_center().y],"frame":0})
	city._refresh_parcel_index()
	obstruction_before = city.snapshot()
	helper.sync(fixture)
	check(helper.pads.all(func(pad: Dictionary) -> bool: return not Spatial.overlaps(pad["polygon"],probe)) and city.snapshot() == obstruction_before,"reserved_player_land_is_never_paved_and_its_index_change_invalidates_the_cache")
	city.planning_reservations.pop_back()
	city._refresh_parcel_index()
	fixture.art_direction.selected_id = "clay"
	helper.sync(fixture)
	var other_style_empty := helper.pads.is_empty()
	fixture.art_direction.selected_id = "baseline"
	var original_era: Dictionary = {}
	for building: Dictionary in city.buildings:
		original_era[str(building["district_id"])] = building["era"]
		building["era"] = 2
	helper.sync(fixture)
	var later_empty := helper.pads.is_empty()
	for building: Dictionary in city.buildings: building["era"] = original_era[str(building["district_id"])]
	city.era = 2
	helper.sync(fixture)
	check(other_style_empty and later_empty and helper.pads == initial,"comparison_styles_and_new_era_houses_stay_isolated_while_surviving_classical_houses_keep_their_thresholds")
	city.era = 1
	var candidate: Array = First.opportunities(city)["seed_candidates"][0]["position"]
	var frame := int(city.cfg["timing"]["phrase_frames"])
	var accepted := city.request(PlayerExpression.operation("warm",candidate),frame)
	city.settle(frame)
	fill(fixture,catalog)
	var authored_before := city.snapshot()
	helper.sync(fixture)
	var root_id := ""
	for building: Dictionary in city.buildings:
		if int(building["birth_frame"]) == frame: root_id = str(building["district_id"])
	var pending_hidden := helper.pads.all(func(pad: Dictionary) -> bool: return str(pad["building_id"]) != root_id)
	fixture.clock.renderer.transport.audible_frame = frame
	helper.sync(fixture)
	var actual_pad := helper.pads.any(func(pad: Dictionary) -> bool: return str(pad["building_id"]) == root_id)
	check(bool(accepted.get("accepted",false)) and not root_id.is_empty() and pending_hidden and actual_pad and city.snapshot() == authored_before,"a_real_confirmed_author_house_gets_its_actual_entry_threshold_only_after_the_birth_is_heard")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"opening_thresholds":counts["threshold"],"opening_wear_segments":counts["wear"],"opening_houses_with_pads":touched.size(),"maximum_pad_extent_from_actual_step":max_extent,"opening_pads":initial,"authored_house":root_id,"diagnostics":helper.diagnostics()},"scope":"Dummy real 24-house World/current production entry geometry, actual heard author birth, existing owned lot/radius bounds, real road/water/neighbor/public/hole/reservation exclusions, era/style separation and retained camera cache. Thin thresholds and short wear do not claim a new route; Root owns actual window/compositing/aesthetic review."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND212_FRONTAGE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	fixture.free()
	quit(0 if failures.is_empty() else 1)
