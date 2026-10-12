extends SceneTree
## Two real imported trees through production catalog/prop and geometric masks.
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Prop = preload("res://scripts/visual/valley_prop.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const OUTPUT := "res://验证记录/round208_古典植被/tree_contract.json"
const BASELINE := "res://验证记录/round208_古典植被/building_baseline.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _alpha_near(image: Image,at: Vector2i) -> float:
	var found := 0.0
	for y in range(maxi(0,at.y-2),mini(image.get_height(),at.y+3)):
		for x in range(maxi(0,at.x-2),mini(image.get_width(),at.x+3)):
			found = maxf(found,image.get_pixel(x,y).a)
	return found

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var before := city.snapshot()
	var catalog := Catalog.new()
	catalog.load_catalog()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	var building_bytes := true
	for path: String in baseline["files"]:
		building_bytes = building_bytes and FileAccess.get_sha256("res://"+path) == str(baseline["files"][path])
	var building_entries: Array = catalog.refined_manifest["entries"].filter(func(entry: Dictionary) -> bool: return str(entry["role"]) != "tree")
	check(building_bytes and building_entries == baseline["entries"] and building_entries.size() == 32,"only_two_trees_changed_all_32_building_entries_and_256_building_files_are_identical")
	var ground_and_alpha := true
	var physical_masks := true
	var props: Array = []
	var tree_records: Array = []
	for tone in [0,1]:
		var entry: Dictionary = catalog.prop_entry("tree",tone,1)
		var texture := catalog.texture_for(entry)
		var image := catalog.image_for(entry)
		var origin := Vector2(entry["origin"][0],entry["origin"][1])
		ground_and_alpha = ground_and_alpha and image.get_pixel(0,0).a == 0.0 and _alpha_near(image,Vector2i(origin)) > 0.1 and entry["lighting"]["ground_anchor_world"] == [0.0,0.0,0.0]
		var prop := Prop.new()
		prop.kind = "tree"
		prop.tone = tone
		prop.position = Vector2(200+tone*100,240)
		prop.art_entry = entry
		prop.art_texture = texture
		for mask: String in ["shadow","contact"]:
			var path := "res://"+str(entry[mask+"_texture"])
			var mask_texture: Texture2D = load(path)
			var mask_image := mask_texture.get_image()
			physical_masks = physical_masks and catalog.shadow_images.has(path) and mask_image.has_mipmaps() and FileAccess.get_sha256(path) == str(entry[mask+"_sha256"])
			if mask == "contact":
				prop.art_contact = mask_texture
				var mask_origin := Vector2i(entry[mask+"_origin"][0],entry[mask+"_origin"][1])
				physical_masks = physical_masks and _alpha_near(mask_image,mask_origin) > 0.1
			else: prop.art_shadow = mask_texture
		root.add_child(prop)
		props.append(prop)
		check(texture != null and image.has_mipmaps() and FileAccess.get_sha256("res://"+str(entry["texture"])) == str(entry["texture_sha256"]) and int(entry["tree_revision"]) == 208,tone_to_label(tone)+"_real_production_png_is_prewarmed_mipped_and_hash_verified")
		tree_records.append({"id":entry["id"],"species":entry["tree_species"],"faces":entry["geometry_faces"],"size":entry["runtime_reference"]["visible_size_px"],"origin":entry["origin"],"plot_span":entry["plot_span"]})
	check(ground_and_alpha,"both_actual_tree_pngs_have_transparent_border_and_woody_foot_at_shared_zero_origin")
	check(physical_masks,"both_physical_cast_and_contact_masks_are_prewarmed_and_contact_the_same_tree_foot")
	var stable_tones := true
	for tone in range(-3,5):
		stable_tones = stable_tones and catalog.prop_entry("tree",tone,1) == catalog.prop_entry("tree",posmod(tone,2),1)
	check(stable_tones and catalog.prop_entry("tree",0,1)["tree_species"] == "olive" and catalog.prop_entry("tree",1,1)["tree_species"] == "mediterranean_cypress" and catalog.prop_entry("tree",0,2).is_empty(),"integer_tones_keep_two_stable_species_and_later_eras_keep_existing_prop_entry")
	var olive: Dictionary = catalog.prop_entry("tree",0,1)
	var cypress: Dictionary = catalog.prop_entry("tree",1,1)
	var olive_image: Image = catalog.image_for(olive).duplicate()
	olive_image.clear_mipmaps()
	olive_image.resize(128,128,Image.INTERPOLATE_LANCZOS)
	var open_crown_rows := 0
	for y in range(16,85):
		var first := -1
		var last := -1
		for x in range(128):
			if olive_image.get_pixel(x,y).a > 0.7:
				if first < 0: first = x
				last = x
		if last-first < 20: continue
		var gap := 0
		for x in range(first,last+1):
			gap = gap+1 if olive_image.get_pixel(x,y).a < 0.1 else 0
			if gap >= 4:
				open_crown_rows += 1
				break
	var cypress_size: Array = cypress["runtime_reference"]["visible_size_px"]
	check(open_crown_rows >= 5 and float(cypress_size[1])/float(cypress_size[0]) > 2.4,"olive_crown_has_visible_inner_spaces_and_cypress_is_a_slender_vertical_silhouette")
	var geometry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://验证记录/round208_古典植被/geometry.json"))
	check(bool(geometry["passed"]) and geometry["trees"].all(func(tree: Dictionary) -> bool: return float(tree["bsp_depth_agreement"]) > 0.93 and int(tree["nearest_surface_samples"]) > 5000 and float(tree["silhouette_change_fraction"]) > 0.15),"new_bsp_occlusion_matches_independent_nearest_surface_reference_and_old_silhouettes_changed")
	await process_frame
	check(city.snapshot() == before and props.all(func(prop: Node2D) -> bool: return prop.position == Vector2(200+prop.tone*100,240)),"actual_production_props_draw_without_moving_their_ground_anchors_or_writing_world_rng")
	for prop: Node in props: prop.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"trees":tree_records,"olive_crown_open_rows":open_crown_rows,"scope":"Headless Dummy imported production trees and real prop drawing; independent offline geometric occlusion reference; aesthetic review remains Root live window."},"\t")+"\n")
	print("ROUND208_TREES "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func tone_to_label(tone: int) -> String: return "olive" if tone == 0 else "cypress"
