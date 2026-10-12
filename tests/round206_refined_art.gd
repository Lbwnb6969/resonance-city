extends SceneTree
## Actual baked production entries, real author families and live sprite alpha hit.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const OUTPUT := "res://验证记录/round206_精制河湾/asset_contract.json"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _opaque_pixel(image: Image) -> Vector2i:
	for y in range(int(image.get_height()*0.60),image.get_height(),7):
		for x in range(2,image.get_width()-2,7):
			if image.get_pixel(x,y).a > 0.95: return Vector2i(x,y)
	return Vector2i(-1,-1)

func _run() -> void:
	root.size = Vector2i(1440,900)
	demo = DemoScene.instantiate()
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var source := World.new("2026100900000062",true,"river_valley")
	source.build_first_composition_starter()
	demo._start_world({},source)
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	var baseline := source.snapshot()
	var catalog = demo.building_catalog
	check(source.buildings.size() == 24,"actual_starter_contains_24_real_buildings")
	var ordinary_ids: Dictionary = {}
	var production := true
	for building: Dictionary in source.buildings:
		var entry: Dictionary = catalog.entry_for(building,demo.assets[str(building["type"])])
		production = production and bool(entry.get("refined_valley",false))
		ordinary_ids[str(entry.get("canonical_id",entry["id"]))] = true
	check(production and ordinary_ids.size() == 4 and catalog.refined_manifest["residential_ids"].all(func(id: String) -> bool: return ordinary_ids.has(id)),"all_24_starter_buildings_use_three_house_silhouettes_and_actual_commercial_shop")
	var alpha_and_hash := true
	var masks_and_mips := true
	var anchors := true
	var resources: Array = []
	for entry: Dictionary in catalog.refined_entries.values():
		var image: Image = catalog.image_for(entry)
		alpha_and_hash = alpha_and_hash and image.get_pixel(0,0).a == 0.0 and _opaque_pixel(image) != Vector2i(-1,-1)
		anchors = anchors and entry["lighting"]["ground_anchor_world"] == [0.0,0.0,0.0]
		for kind: String in ["texture","shadow","contact"]:
			var path := "res://"+str(entry["texture"] if kind == "texture" else entry[kind+"_texture"])
			alpha_and_hash = alpha_and_hash and FileAccess.get_sha256(path) == str(entry["texture_sha256"] if kind == "texture" else entry[kind+"_sha256"])
			var texture: Texture2D = catalog.texture_for(entry) if kind == "texture" else load(path)
			masks_and_mips = masks_and_mips and texture != null and texture.get_image().has_mipmaps()
			if kind != "texture": masks_and_mips = masks_and_mips and catalog.shadow_images.has(path) and demo.shadow_layer.mask_images.has(path)
		resources.append({"id":entry["id"],"faces":entry["geometry_faces"],"texture":entry["texture"],"city_size":entry["runtime_reference"]["visible_size_px"]})
	check(catalog.refined_entries.size() == 34 and alpha_and_hash,"all_34_bakes_have_transparent_border_opaque_geometry_and_matching_hashes")
	check(masks_and_mips,"all_production_textures_and_physical_masks_are_prewarmed_with_mipmaps")
	check(anchors,"all_texture_and_shadow_geometries_share_actual_zero_ground_foot")
	check(catalog.prop_entry("tree",0.0)["id"] != catalog.prop_entry("tree",1.0)["id"] and catalog.prop_entry("civic")["category"] == "civic","integer_scenery_tone_supplies_two_tree_geometries_and_columned_civic")
	var orientations_ok := true
	for canonical_id: String in catalog.refined_manifest["orientations"]:
		var ids: Array = catalog.refined_manifest["orientations"][canonical_id]
		var unique_hashes: Dictionary = {}
		var base: Dictionary = catalog.refined_entries[canonical_id]
		for index in range(4):
			var angle_entry: Dictionary = catalog.refined_entries[ids[index]]
			var bounds: Array = angle_entry["model_bounds"]["size"]
			var base_bounds: Array = base["model_bounds"]["size"]
			var normal: Array = angle_entry["entrance_normal"]
			orientations_ok = orientations_ok and int(angle_entry["era"]) == 1 and int(angle_entry["orientation"]) == index and Vector2(normal[0],normal[1]) == [Vector2(0,-1),Vector2(1,0),Vector2(0,1),Vector2(-1,0)][index]
			orientations_ok = orientations_ok and is_equal_approx(float(bounds[1]),float(base_bounds[1])) and is_equal_approx(maxf(bounds[0],bounds[2]),maxf(base_bounds[0],base_bounds[2]))
			unique_hashes[angle_entry["texture_sha256"]] = true
		orientations_ok = orientations_ok and ids.size() == 4 and unique_hashes.size() == 4
	check(orientations_ok,"all_eight_building_geometries_have_four_actual_ground_anchored_cardinal_templates")
	var era_isolated := true
	for building_type: String in ["residential","commercial","industrial"]:
		var later := {"district_id":"later-"+building_type,"type":building_type,"era":2,"player_expression":true,"expression":"warm"}
		var old: Dictionary = catalog.retained_era_entries["2:"+building_type]
		era_isolated = era_isolated and catalog.entry_for(later,demo.assets[building_type]) == old and not bool(old.get("refined_valley",false))
		later["era"] = 3
		era_isolated = era_isolated and catalog.entry_for(later,old) == old
	check(era_isolated and catalog.prop_entry("tree",0.2,2).is_empty() and catalog.prop_entry("civic",0.0,2).is_empty(),"refined_era1_scope_preserves_retained_later_era_category_and_original_props")
	var before_count: Array = [catalog.textures.size(),catalog.images.size()]
	var routes: Dictionary = {}
	for choice: String in PlayerExpression.IDS:
		var city = source.fork()
		var position: Array = First.opportunities(city)["seed_candidates"][0]["position"]
		var boundary := int(city.cfg["timing"]["phrase_frames"])
		var queued: Dictionary = city.request(PlayerExpression.operation(choice,position),boundary)
		city.settle(boundary)
		var family: Dictionary = {}
		for item: Dictionary in city.families.values():
			if bool(item.get("player_expression",false)): family = item
		var building: Dictionary = city.by_id[str(family["root"])]
		var before: Dictionary = city.snapshot()
		var entry: Dictionary = catalog.entry_for(building,demo.assets[str(building["type"])],family)
		check(bool(queued.get("accepted",false)) and entry == catalog.preview_entry(choice) and str(entry["category"]) == str(building["type"]) and str(entry["first_expression_style"]) == choice,choice+"_real_author_root_and_sound_card_share_typed_production_entry")
		check(city.snapshot() == before,choice+"_visual_lookup_preserves_saved_city_audio_fields_rng_and_reservations")
		routes[choice] = {"asset":entry["id"],"type":building["type"],"reservation_count":city.planning_reservations.size()}
	check(before_count == [catalog.textures.size(),catalog.images.size()],"all_three_route_assets_and_hit_images_exist_before_first_choice")
	check(int(routes["warm"]["reservation_count"]) == 1 and str(routes["weave"]["type"]) == "commercial","actual_warm_reservation_and_weave_commercial_gameplay_are_retained")
	demo._sync_buildings()
	var front := ""
	for id: String in demo.sprites:
		if front.is_empty() or demo.sprites[id].position.y > demo.sprites[front].position.y: front = id
	var sprite: AudioGrowthMask = demo.sprites[front]
	sprite.progress = 1.0
	var geometry: Dictionary = demo.building_geometry[front]
	var entry: Dictionary = geometry["entry"]
	var ground := sprite.to_global(Vector2.ZERO)
	check(ground.distance_to(demo.point(Coupling.position_of(source.by_id[front]))) < 0.0001 and sprite.offset == -Vector2(entry["origin"][0],entry["origin"][1]),"live_sprite_origin_is_actual_world_foot_with_retained_plot_scale")
	var opaque := _opaque_pixel(geometry["image"])
	check(demo._hit(sprite.to_global(Vector2(opaque)+sprite.offset)) == front and demo._hit(sprite.to_global(sprite.offset)) != front,"live_production_hit_uses_new_png_opaque_geometry_and_ignores_transparent_border")
	var record: Dictionary = demo.shadow_records[front]
	var patch: Dictionary = demo.shadow_layer._patch(record,"contact")
	var ground_texel := Vector2i(record["position"]*float(demo.shadow_layer.cfg["union_resolution"]))
	check(Rect2i(patch["begin"],patch["size"]).has_point(ground_texel) and record["entry"]["id"] == entry["id"],"actual_contact_patch_contains_same_foot_and_uses_same_refined_entry")
	check(source.snapshot() == baseline,"production_catalog_and_visual_sync_are_read_only_for_actual_world")
	evidence = {"resources":resources,"routes":routes,"starter_assets":ordinary_ids.keys(),"live_alpha_hit_building":front,"scope":"Headless Dummy; actual production Demo and imported PNGs, no real audio device or aesthetic approval."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence},"\t")+"\n")
	demo.model.close_background_settlement()
	demo.free()
	print("ROUND206_REFINED_ART "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
