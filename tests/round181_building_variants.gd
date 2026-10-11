extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Eaves = preload("res://scripts/visual/street_eaves_layer.gd")
const GrowthSprite = preload("res://scripts/visual/audio_growth_mask.gd")
const Projection2D = preload("res://scripts/world/world_projection.gd")
const OUTPUT := "res://验证记录/round181_视觉地基/building_variants.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class VisualHost extends Control:
	var black := false
	var shown_world: RefCounted
	var sprites: Dictionary = {}
	var building_geometry: Dictionary = {}
	var buildings_layer := Node2D.new()
	func _ready() -> void:
		buildings_layer.y_sort_enabled = true
		add_child(buildings_layer)

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _map(city: RefCounted,catalog: RefCounted,fallback: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for building: Dictionary in city.buildings:
		result[building["district_id"]] = catalog.entry_for(building,fallback[building["type"]])["id"]
	return result

func _populate(host: Control,catalog: RefCounted,fallback: Dictionary) -> void:
	for sprite: Node2D in host.sprites.values(): sprite.queue_free()
	host.sprites.clear()
	host.building_geometry.clear()
	for building: Dictionary in host.shown_world.buildings:
		var id := str(building["district_id"])
		var entry: Dictionary = catalog.entry_for(building,fallback[building["type"]])
		var p := Vector2(float(building["position"][0]),float(building["position"][1]))
		var position := Projection2D.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),host.shown_world.terrain.height_at(p))
		var scale := 28.0*sqrt(2.0)*.8/maxf(float(entry["model_bounds"]["size"][0]),float(entry["model_bounds"]["size"][2]))/float(entry["pixels_per_world"])
		host.building_geometry[id] = {"key":[p,entry["id"]],"entry":entry,"position":position,"scale":scale}
		var sprite := GrowthSprite.new()
		sprite.use_master_clock = false
		sprite.texture = catalog.texture_for(entry)
		sprite.centered = false
		sprite.offset = -Vector2(float(entry["origin"][0]),float(entry["origin"][1]))
		sprite.position = position
		sprite.scale = Vector2.ONE*scale
		host.buildings_layer.add_child(sprite)
		sprite.begin_at(int(building["birth_frame"]))
		host.sprites[id] = sprite

func _run() -> void:
	var catalog := Catalog.new()
	catalog.load_catalog()
	var fallback: Dictionary = {}
	var retained: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
	for entry: Dictionary in retained["entries"]:
		if int(entry["era"]) == 1: fallback[entry["category"]] = entry
	var heights: Array = []
	var silhouettes: Array = []
	for entry: Dictionary in catalog.entries:
		heights.append(float(entry["model_bounds"]["size"][1]))
		var image: Image = catalog.image_for(entry)
		silhouettes.append([image.get_size(),image.get_used_rect()])
	check(catalog.entries.size() == 3 and heights[0] != heights[1] and heights[1] != heights[2] and silhouettes[0] != silhouettes[1] and silhouettes[1] != silhouettes[2],"three_actual_geometry_silhouettes_have_distinct_roof_height_and_alpha_bounds")
	check(catalog.shadow_images.size() == 6 and catalog.entries.all(func(entry: Dictionary) -> bool: return catalog.texture_for(entry) != null and catalog.image_for(entry) != null),"textures_hit_alpha_and_all_six_ground_masks_are_prewarmed")
	var city := World.new("2026101100000180",true,"river_valley")
	city.build_first_composition_starter()
	var source_map := _map(city,catalog,fallback)
	var variants: Dictionary = {}
	for building: Dictionary in city.buildings:
		if str(building["type"]) == "residential": variants[source_map[building["district_id"]]] = true
	check(variants.size() == 3,"actual_young_starter_contains_all_three_stable_house_variants")
	var natural_shared_before: int = city.fabric_cache["shared_walls"].size()
	# Plant through the real continuous placement/settlement path beside an existing house.
	var seed_result: Dictionary = {}
	for building: Dictionary in city.buildings.duplicate():
		var center := Vector2(float(building["position"][0]),float(building["position"][1]))
		for index in range(24):
			var p := center+Vector2.from_angle(TAU*float(index)/24.0)*.95
			var placement: Dictionary = city.placement(p)
			if not bool(placement.get("allowed",false)) or str(placement.get("community_id","")) != str(building["community_id"]): continue
			seed_result = city.request({"kind":"seed","position":[p.x,p.y],"midi":int(building["current_midi"])},int(city.cfg["timing"]["phrase_frames"]))
			if bool(seed_result.get("accepted",false)): break
		if bool(seed_result.get("accepted",false)): break
	city.settle(int(city.cfg["timing"]["phrase_frames"]))
	check(bool(seed_result.get("accepted",false)) and not city.fabric_cache["shared_walls"].is_empty(),"real_legal_continuous_house_placement_derives_actual_shared_wall_relationship")
	var before := city.snapshot()
	var rng_before := city.rng.snapshot()
	var host := VisualHost.new()
	host.shown_world = city
	root.add_child(host)
	await process_frame
	_populate(host,catalog,fallback)
	var eaves := Eaves.new()
	host.buildings_layer.add_child(eaves)
	eaves.sync(host)
	check(eaves.diagnostics()["pairs"].size() > 0,"real_shared_residential_pair_has_a_geometry_anchored_cornice")
	var actual_pairs: Dictionary = {}
	for relation: Dictionary in city.fabric_cache["shared_walls"]: actual_pairs[str(relation["a"])+":"+str(relation["b"])] = true
	check(eaves.diagnostics()["pairs"].all(func(pair: Array) -> bool: return actual_pairs.has(str(pair[0])+":"+str(pair[1]))),"cornices_join_only_actual_shared_wall_pairs")
	check(eaves.diagnostics()["visible_pairs"] == 0,"cornices_do_not_appear_before_audio_frame_house_reveal")
	for sprite: AudioGrowthMask in host.sprites.values(): sprite.sample_frame(sprite.end_frame())
	eaves.sync(host)
	check(eaves.diagnostics()["visible_pairs"] == eaves.diagnostics()["pairs"].size(),"cornices_appear_when_both_actual_house_reveals_complete")
	var one_pair: Array = eaves.diagnostics()["pairs"][0]
	host.sprites[one_pair[0]].sample_frame(host.sprites[one_pair[0]].start_frame)
	eaves.sync(host)
	check(not eaves.patches[str(one_pair[0])+":"+str(one_pair[1])].visible,"one_unrevealed_house_does_not_receive_a_future_neighbor_roof")
	check(city.snapshot() == before and city.rng.snapshot() == rng_before and host.sprites.size() == city.buildings.size(),"visuals_keep_independent_building_ids_pitch_phase_state_and_all_city_rng_streams")
	var restored := World.new(city.rng.seed_hex,false)
	restored.restore(before)
	check(_map(restored,catalog,fallback) == _map(city,catalog,fallback),"save_restore_uses_same_per_id_variants_without_adding_save_data")
	host.shown_world = restored
	_populate(host,catalog,fallback)
	eaves.sync(host)
	check(eaves.diagnostics()["pairs"].all(func(pair: Array) -> bool: return actual_pairs.has(str(pair[0])+":"+str(pair[1]))) and eaves.diagnostics()["visible_pairs"] == 0,"restored_actual_fabric_rebuilds_same_pairs_and_waits_for_current_reveal")
	var directory := ProjectSettings.globalize_path(OUTPUT).get_base_dir()
	DirAccess.make_dir_recursive_absolute(directory)
	var output := {"checks":checks,"failures":failures,"variant_ids":variants.keys(),"roof_heights":heights,"natural_shared_before":natural_shared_before,"actual_shared_after":city.fabric_cache["shared_walls"].size(),"eaves":eaves.diagnostics()}
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("ROUND181_BUILDINGS ",JSON.stringify(output))
	host.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
