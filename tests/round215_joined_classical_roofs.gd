extends SceneTree
## True starter + controlled geometric counterexamples. Dummy only.
const World = preload("res://scripts/world/continuous_world.gd")
const Joined = preload("res://scripts/visual/joined_classical_roofs.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Orientation = preload("res://scripts/visual/building_street_orientation.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const OUTPUT := "res://验证记录/round215_古典联合屋顶/roof_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var entries: Dictionary = {}

class DummyTransport extends RefCounted:
	var audible_frame := 0.0
class DummyRenderer extends RefCounted:
	var transport := DummyTransport.new()
class DummyClock extends RefCounted:
	var renderer := DummyRenderer.new()
class DummySprite extends RefCounted:
	var progress := 1.0
class DummyDemo extends Control:
	var shown_world: RefCounted
	var clock := DummyClock.new()
	var black := false
	var building_geometry: Dictionary = {}
	var sprites: Dictionary = {}

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)

func _prepare(view: Control,city: RefCounted) -> void:
	view.shown_world = city
	view.building_geometry.clear(); view.sprites.clear()
	var base_ids := ["refined_house_terrace","refined_house_gabled","refined_house_courtyard"]
	for building: Dictionary in city.buildings:
		var id := str(building["district_id"])
		var p := Coupling.position_of(building)
		var facing := Orientation.street_orientation(city,p)
		var canonical: String = base_ids[Catalog.variant_index(id)] if str(building["type"]) == "residential" else "refined_shop_arcade"
		var style := str(building.get("expression","")) if bool(building.get("player_expression",false)) else ""
		if style == "warm": canonical = "refined_warm_courtyard"
		elif style == "deep": canonical = "refined_deep_terrace"
		elif style == "weave" and str(building["type"]) == "commercial": canonical = "refined_weave_shop"
		var entry: Dictionary = entries[canonical+("_o%d" % facing if facing != 0 else "")]
		var geometry := {"entry":entry,"position":IsoProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(p)),
			"scale":28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])}
		view.building_geometry[id] = geometry
		view.sprites[id] = DummySprite.new()

func _pairs(layer: Node2D) -> Array:
	var result: Array = []
	for patch in layer.patches:
		var pair: Array = patch.row_ids.duplicate(); pair.sort(); result.append(pair)
	return result

func _set_roof(view: Control,id: String,canonical: String) -> void:
	var facing := int(view.building_geometry[id]["entry"]["orientation"])
	var entry: Dictionary = entries[canonical+("_o%d" % facing if facing != 0 else "")]
	view.building_geometry[id]["entry"] = entry
	view.building_geometry[id]["scale"] = 28.0*sqrt(2.0)*0.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])

func _actual_roof_planes(layer: Node2D,view: Control,city: RefCounted) -> bool:
	# Independent values from the actual asset builders, including tiled eave
	# lip. This rejects the old guessed-height central ridge on both fixtures
	# and the real first work. A half roof can only continue its own plane.
	var profiles := {"terrace":[0.603,0.0,0.575,0.0],"gabled":[0.585,0.26,0.60,0.0],
		"courtyard":[0.563,0.115,0.22,0.39],"commercial":[0.618,0.17,0.60,0.0]}
	for patch in layer.patches:
		for surface: Dictionary in patch.surfaces:
			if surface["kind"] != "roof": continue
			var id := str(surface["owner"])
			var geometry: Dictionary = view.building_geometry[id]
			var entry: Dictionary = geometry["entry"]
			var values: Array = profiles[entry["role"]]
			var p := Coupling.position_of(city.by_id[id])
			var front: Vector2 = Orientation.FACING[int(entry["orientation"])]
			var right := Vector2(front.y,-front.x)
			var pixels := float(geometry["scale"])*float(entry["pixels_per_world"])
			var ground_scale := pixels/(28.0*sqrt(2.0))
			var height_scale := pixels*sqrt(3.0)/(2.0*14.0)
			var other := str(patch.row_ids[1] if patch.row_ids[0] == id else patch.row_ids[0])
			var side := 1.0 if (Coupling.position_of(city.by_id[other])-p).dot(right) > 0.0 else -1.0
			for vertex: Vector3 in surface["vertices"]:
				var x := (Vector2(vertex.x,vertex.z)-p).dot(right)/ground_scale
				var expected: float = city.terrain.height_at(p)+(float(values[0])+float(values[1])*(1.0-absf(x-float(values[3])*side)/float(values[2])))*height_scale
				if absf(vertex.y-expected) > 0.00001: return false
				if entry["role"] == "courtyard" and absf(x) < 0.60: return false
	return not layer.patches.is_empty()

func _rotate_fixture(city: RefCounted,angle: float) -> void:
	var center := Vector2(8,8)
	city.index = city.Index.new()
	for building: Dictionary in city.buildings:
		var p := center+(Coupling.position_of(building)-center).rotated(angle)
		building["position"] = [p.x,p.y]; city.index.put(str(building["district_id"]),p,0.45)
	var path: PackedVector2Array = city.roads[0]["path"]
	for index in range(path.size()): path[index] = center+(path[index]-center).rotated(angle)
	city.roads[0]["path"] = path
	city.road_index_identity = ""; city.parcel_index_identity = ""
	city.rebuild_graph(); city.refresh_fabric()

func _fixture(source: RefCounted,count: int = 2) -> RefCounted:
	var city: RefCounted = source.fork()
	city.buildings.clear(); city.by_id.clear(); city.index = city.Index.new()
	city.lots.clear(); city.public_sites.clear(); city.planning_reservations.clear()
	city.roads.assign([{"id":"fixture-road","path":PackedVector2Array([Vector2(8,4),Vector2(8,16)]),"from":"f-a","to":"f-b","kind":"street","bridge":false}])
	city.nodes = {"f-a":[8.0,4.0],"f-b":[8.0,16.0]}
	city.communities = {"left":{"id":"left","members":[],"bank":-1,"name":"旧分区甲"},"right":{"id":"right","members":[],"bank":-1,"name":"旧分区乙"}}
	var exemplar: Dictionary = source.buildings[0]
	for i in range(count):
		var building := exemplar.duplicate(true)
		var id := "fixture-%02d" % (count-i)
		building["district_id"] = id; building["position"] = [9.0,6.0+float(i)*0.96]
		building["community_id"] = "left" if i%2 == 0 else "right"
		building["type"] = "residential"; building["radius"] = 0.45
		building["lot_id"] = ""; building["birth_frame"] = 0
		city.buildings.append(building); city.by_id[id] = building
		city.index.put(id,Coupling.position_of(building),0.45)
		city.communities[building["community_id"]]["members"].append(id)
	city.road_index_identity = ""; city.parcel_index_identity = ""
	city.rebuild_graph(); city.refresh_fabric()
	return city

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy" and DisplayServer.get_name() == "headless","headless_dummy_no_gpu_or_device")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/精制河湾/manifest.json"))
	for entry: Dictionary in manifest["entries"]: entries[str(entry["id"])] = entry
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var view := DummyDemo.new(); root.add_child(view); _prepare(view,city)
	var joined := Joined.new(); view.add_child(joined)
	var before: Dictionary = city.snapshot()
	joined.setup(view)
	var actual: Dictionary = joined.diagnostics()
	check(city.buildings.size() == 24 and actual["patches"] > 0,"real_24_house_starter_has_true_joined_roof_bodies")
	var true_edges: Array = []
	for edge: Dictionary in city.fabric_cache["shared_walls"]:
		var pair: Array = [edge["a"],edge["b"]]; pair.sort(); true_edges.append(pair)
	check(_pairs(joined).all(func(pair: Array) -> bool: return true_edges.has(pair)),"every_visual_union_comes_from_actual_shared_wall_relationship")
	var solid := not joined.patches.is_empty()
	for patch in joined.patches:
		solid = solid and patch.top_a.size() == 4 and patch.top_b.size() == 4 and patch.fascia_a.size() == 4 and patch.world_footprint.size() == 4 and patch.surfaces.size() >= 6
		var area := absf(patch.world_footprint[0].cross(patch.world_footprint[1])+patch.world_footprint[1].cross(patch.world_footprint[2])+patch.world_footprint[2].cross(patch.world_footprint[3])+patch.world_footprint[3].cross(patch.world_footprint[0]))*0.5
		solid = solid and area > 0.015 and patch.actual_depth > 0.18
	check(solid,"union_is_solid_actual_eave_overlap_with_roof_and_fascia_surfaces_not_a_line")
	check(_actual_roof_planes(joined,view,city),"real_starter_continues_each_exact_asset_plane_and_keeps_courtyards_open")
	check(city.snapshot() == before,"presentation_does_not_modify_world_rng_pending_identity_or_pitch")
	var rebuilt: int = joined.rebuild_count
	view.position = Vector2(64,-22); view.scale = Vector2.ONE*0.7
	view.clock.renderer.transport.audible_frame = 1234
	joined.sync(view)
	check(joined.rebuild_count == rebuilt,"camera_and_heard_clock_reuse_retained_roof_geometry")
	var fixture := _fixture(city,7); _prepare(view,fixture); joined.sync(view)
	var seven: Dictionary = joined.diagnostics()
	check(seven["rows"].size() == 1 and seven["rows"][0]["ids"].size() == 6 and seven["patches"] == 5,"seven_house_chain_stops_at_six_and_leaves_next_seam_open")
	check(seven["rows"][0]["ids"][0] == "fixture-07" and seven["rows"][0]["ids"][-1] == "fixture-02","row_order_follows_real_road_arc_instead_of_building_id_order")
	var cross_ids: Array = seven["rows"][0]["ids"]
	check(cross_ids.any(func(id: String) -> bool: return str(fixture.by_id[id]["community_id"]) == "left") and cross_ids.any(func(id: String) -> bool: return str(fixture.by_id[id]["community_id"]) == "right"),"tightly_related_houses_join_across_old_community_ids")
	fixture = _fixture(city); _prepare(view,fixture)
	var ids: Array = fixture.by_id.keys()
	view.building_geometry[ids[1]]["entry"] = view.building_geometry[ids[1]]["entry"].duplicate(true)
	view.building_geometry[ids[1]]["entry"]["orientation"] = posmod(int(view.building_geometry[ids[0]]["entry"]["orientation"])+2,4)
	joined.sync(view)
	check(joined.patches.is_empty(),"different_actual_baked_facades_never_join")
	_prepare(view,fixture); fixture.by_id[ids[1]]["birth_frame"] = 2000
	joined.sync(view)
	check(joined.patches.is_empty(),"render_ahead_future_house_does_not_gain_a_union")
	fixture.by_id[ids[1]]["birth_frame"] = 0
	view.sprites[ids[1]].progress = 0.5; joined.sync(view)
	check(joined.patches.is_empty(),"unfinished_reveal_waits_until_actual_second_roof_is_visible")
	_prepare(view,fixture); fixture.by_id[ids[1]]["type"] = "civic"; joined.sync(view)
	check(joined.patches.is_empty(),"public_culture_building_stays_independent")
	fixture = _fixture(city); _prepare(view,fixture)
	ids = fixture.by_id.keys()
	fixture.by_id[ids[1]]["position"][0] = 7.0
	fixture.index.put(ids[1],Coupling.position_of(fixture.by_id[ids[1]]),0.45)
	fixture.fabric_cache["shared_walls"] = [{"a":ids[0],"b":ids[1],"gap":0.06}]
	_prepare(view,fixture); joined.sync(view)
	check(joined.patches.is_empty(),"opposite_sides_of_same_road_do_not_join_even_with_a_stale_candidate")
	fixture = _fixture(city); ids = fixture.by_id.keys()
	var middle := (Coupling.position_of(fixture.by_id[ids[0]])+Coupling.position_of(fixture.by_id[ids[1]]))*0.5
	fixture.terrain.water = PackedVector2Array([middle+Vector2(-0.5,-0.1),middle+Vector2(0.5,-0.1),middle+Vector2(0.5,0.1),middle+Vector2(-0.5,0.1)])
	_prepare(view,fixture); joined.sync(view)
	check(joined.patches.is_empty(),"water_between_real_houses_blocks_joined_roof")
	fixture = _fixture(city); _prepare(view,fixture); ids = fixture.by_id.keys()
	fixture.by_id[ids[0]]["player_expression"] = true; fixture.by_id[ids[0]]["expression"] = "deep"
	fixture.by_id[ids[1]]["player_expression"] = true; fixture.by_id[ids[1]]["expression"] = "deep"
	_prepare(view,fixture); joined.sync(view)
	check(joined.patches.size() == 1 and joined.patches[0].roof_color == Color("597a83"),"actual_deep_author_roofs_keep_their_stone_blue_identity")
	var mixed_ok := true
	var continuous_ok := true
	var four_angles: Array = []
	for quarter in range(4):
		fixture = _fixture(city); _rotate_fixture(fixture,float(quarter)*PI/2.0)
		_prepare(view,fixture); ids = fixture.by_id.keys()
		_set_roof(view,ids[0],"refined_house_terrace"); _set_roof(view,ids[1],"refined_house_courtyard")
		joined.sync(view)
		mixed_ok = mixed_ok and joined.patches.size() == 1 and _actual_roof_planes(joined,view,fixture)
		if joined.patches.size() != 1: continue
		var patch = joined.patches[0]
		var step_count := 0
		for surface: Dictionary in patch.surfaces:
			if surface["kind"] != "height_step": continue
			step_count += 1
			var points: PackedVector3Array = surface["vertices"]
			mixed_ok = mixed_ok and Vector2(points[0].x,points[0].z).distance_to(Vector2(points[3].x,points[3].z)) < 0.000001
			mixed_ok = mixed_ok and Vector2(points[1].x,points[1].z).distance_to(Vector2(points[2].x,points[2].z)) < 0.000001
		mixed_ok = mixed_ok and step_count == 1 and absf(patch.seam_heights.x-patch.seam_heights.y) > 0.035
		four_angles.append(joined.diagnostics())
		_set_roof(view,ids[0],"refined_house_gabled"); _set_roof(view,ids[1],"refined_house_gabled")
		joined.sync(view)
		continuous_ok = continuous_ok and joined.patches.size() == 1 and _actual_roof_planes(joined,view,fixture)
		if joined.patches.size() == 1:
			patch = joined.patches[0]
			for surface: Dictionary in patch.surfaces:
				if surface["kind"] != "roof": continue
				var points: PackedVector3Array = surface["vertices"]
				# The valley lies at the lower original side slope, never at an
				# invented ridge higher than both facing outer eaves.
				continuous_ok = continuous_ok and (points[0].y > points[1].y if surface["owner"] == ids[0] else points[0].y < points[1].y)
	check(mixed_ok and four_angles.size() == 4,"all_four_actual_facades_keep_flat_terrace_low_tile_and_vertical_height_step")
	check(continuous_ok,"all_four_same_tile_pairs_form_connected_original_slope_valleys_without_extra_ridge")
	view.black = true; joined.sync(view)
	check(not joined.visible and joined.patches.is_empty(),"black_screen_clears_roof_presentation")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT).get_base_dir())
	var report := {"checks":checks,"failures":failures,"passed":checks.size()-failures.size(),"total":checks.size(),
		"actual_starter":actual,"controlled_seven_house_chain":seven,"mixed_roofs_four_orientations":four_angles,
		"scope":"Dummy structural/geometry/read-only contract. No GPU pixels, PCM or human quality verdict."}
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND215 JOINED CLASSICAL ROOFS %d/%d" % [checks.size()-failures.size(),checks.size()])
	view.free()
	quit(0 if failures.is_empty() else 1)
