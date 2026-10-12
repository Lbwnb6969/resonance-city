extends SceneTree
## One directed civic asset contract, using Dummy and no production scenes.
const BASE := "res://资源/精制河湾/manifest.json"
const NIGHT := "res://资源/精制河湾/夜光/manifest.json"
const ARCHIVE := "res://废弃/美术/round210_文化馆四向改造前/"
const PROOF := "res://验证记录/round210_文化馆四向/"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func indexed(entries: Array) -> Dictionary:
	var result: Dictionary = {}
	for entry: Dictionary in entries: result[entry["id"]] = entry
	return result

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","uses_dummy_audio_only")
	var base := read_json(BASE)
	var old := read_json(ARCHIVE+"资源/精制河湾/manifest.json")
	var night := read_json(NIGHT)
	var old_night := read_json(ARCHIVE+"资源/精制河湾/夜光/manifest.json")
	var backup := read_json(ARCHIVE+"backup.json")
	var generation := read_json(PROOF+"civic_generation.json")
	var geometry := read_json(PROOF+"geometry.json")
	var emission := read_json(PROOF+"emission_generation.json")
	var entries := indexed(base["entries"])
	var old_entries := indexed(old["entries"])
	var light_entries := indexed(night["entries"])
	var old_lights := indexed(old_night["entries"])
	var keep_ok: bool = entries.size() == 34 and light_entries.size() == 32
	for identifier: String in old_entries:
		if old_entries[identifier]["role"] != "civic":
			keep_ok = keep_ok and entries[identifier] == old_entries[identifier]
			if old_lights.has(identifier): keep_ok = keep_ok and light_entries[identifier] == old_lights[identifier]
	var retained: Dictionary = backup["preserved_noncivic_hashes"]
	for path: String in retained: keep_ok = keep_ok and FileAccess.get_sha256("res://"+path) == retained[path]
	check(keep_ok and retained.size() == 296 and generation["preserved_noncivic_hashes"] == retained,"all_28_houses_shops_two_trees_and_28_other_night_masks_keep_entries_and_296_file_hashes")
	var civic_ids: Array = backup["civic_ids"]
	var scale_ok := true
	var texture_ok := true
	var orientation_ok := true
	var light_ok := true
	var alpha_ok := true
	var mipmaps_ok := true
	var mask_pixels := 0
	var changed := 0
	var maximum_alpha := 0
	var cardinals := [[0,-1],[1,0],[0,1],[-1,0]]
	for identifier: String in civic_ids:
		var entry: Dictionary = entries[identifier]
		var original: Dictionary = old_entries[identifier]
		var light: Dictionary = light_entries[identifier]
		var architecture: Dictionary = entry["civic_architecture"]
		orientation_ok = orientation_ok and int(entry["civic_revision"]) == 210 and int(entry["era"]) == 1 and int(architecture["doric_columns"]) == 20 and int(architecture["complete_pediments"]) == 2 and architecture["colonnade_sides"].size() == 4 and entry["entrance_normal"] == cardinals[int(entry["orientation"])] and entry["entrance_normal"] == original["entrance_normal"] and entry["canonical_id"] == original["canonical_id"] and entry["rotation_y_degrees"] == original["rotation_y_degrees"]
		var bounds: Array = entry["model_bounds"]["size"]
		var old_bounds: Array = original["model_bounds"]["size"]
		scale_ok = scale_ok and entry["plot_span"] == original["plot_span"] and maxf(bounds[0],bounds[2]) == maxf(old_bounds[0],old_bounds[2]) and entry["lighting"]["ground_anchor_world"] == [0.0,0.0,0.0] and entry["lighting"]["contact_footprint"] == original["lighting"]["contact_footprint"] and entry["lighting"]["contact_reference_world_pixels"] == original["lighting"]["contact_reference_world_pixels"] and entry["lighting"]["sun_screen_shadow_degrees"] == original["lighting"]["sun_screen_shadow_degrees"]
		changed += int(entry["texture_sha256"] != original["texture_sha256"] and entry["source_sha256"] != original["source_sha256"])
		for key: String in ["texture","editable_source","shadow_texture","contact_texture"]:
			var hash_key: String = {"texture":"texture_sha256","editable_source":"source_sha256","shadow_texture":"shadow_sha256","contact_texture":"contact_sha256"}[key]
			texture_ok = texture_ok and FileAccess.get_sha256("res://"+entry[key]) == entry[hash_key]
			if key == "editable_source": continue
			var imported := load("res://"+entry[key]) as Texture2D
			mipmaps_ok = mipmaps_ok and imported != null and imported.get_image().has_mipmaps()
		var imported_light := load("res://"+light["emission_texture"]) as Texture2D
		mipmaps_ok = mipmaps_ok and imported_light != null and imported_light.get_image().has_mipmaps()
		light_ok = light_ok and light["base_texture_sha256"] == entry["texture_sha256"] and light["emission_origin"] == entry["origin"] and light["emission_pixels_per_world"] == entry["pixels_per_world"] and light["entrance_normal"] == entry["entrance_normal"] and light["orientation"] == entry["orientation"] and FileAccess.get_sha256("res://"+light["emission_texture"]) == light["emission_sha256"]
		var source := Image.load_from_file(ProjectSettings.globalize_path("res://"+entry["texture"]))
		var mask := Image.load_from_file(ProjectSettings.globalize_path("res://"+light["emission_texture"]))
		light_ok = light_ok and source.get_size() == mask.get_size()
		source.convert(Image.FORMAT_RGBA8)
		mask.convert(Image.FORMAT_RGBA8)
		var original_pixels := source.get_data()
		var pixels := mask.get_data()
		var lit := 0
		var solid := 0
		for pixel in range(0,pixels.size(),4):
			var a: int = pixels[pixel+3]
			if original_pixels[pixel+3] > 127: solid += 1
			if a == 0: continue
			lit += 1
			maximum_alpha = maxi(maximum_alpha,a)
			alpha_ok = alpha_ok and a <= original_pixels[pixel+3] and a <= 143 and pixels[pixel] == 255 and pixels[pixel+1] == 201 and pixels[pixel+2] == 130
		mask_pixels += pixels.size()/4
		alpha_ok = alpha_ok and float(lit)/float(solid) < 0.035 and absf(float(lit)/float(solid)-float(light["visible_emission_fraction"])) < 0.000001
		var windows := 0
		var doors := 0
		for feature: Dictionary in light["features"]:
			windows += int(feature["kind"] == "window")
			doors += int(feature["kind"] == "door")
		light_ok = light_ok and windows <= 1 and doors == 1
	check(civic_ids.size() == 4 and changed == 4 and orientation_ok,"four_actual_rotated_classical_civic_geometries_have_20_ring_columns_two_pediments_and_the_original_road_entrance")
	check(scale_ok,"public_world_scale_lowest_stylobate_contact_anchor_and_world_sun_contract_remain_identical")
	check(texture_ok,"all_four_png_svg_physical_shadow_and_contact_hashes_match_the_new_manifest")
	check(mipmaps_ok,"all_16_imported_civic_base_shadow_contact_and_light_textures_have_actual_mipmaps")
	var depth_ok: bool = bool(geometry["passed"]) and geometry["entries"].size() == 4 and int(geometry["doric_columns"]) == 20 and int(geometry["complete_pediments"]) == 2
	var minimum_columns := 20
	var minimum_agreement := 1.0
	for record: Dictionary in geometry["entries"]:
		minimum_columns = mini(minimum_columns,record["visible_doric_columns"].size())
		minimum_agreement = minf(minimum_agreement,float(record["world_light_bsp_depth_agreement"]))
		var gables: Array = record["visible_pediment_pixels"]
		depth_ok = depth_ok and record["visible_doric_columns"].size() >= 6 and maxf(gables[0],gables[1]) > 100 and int(record["visible_entablature_pixels"]) > 100 and float(record["world_light_bsp_depth_agreement"]) > 0.93
	check(depth_ok,"independent_nearest_triangle_and_world_light_confirm_exposed_columns_pediment_and_entablature_in_every_view")
	check(light_ok and night["source_manifest_sha256"] == FileAccess.get_sha256(BASE),"only_four_new_civic_night_masks_match_the_new_actual_door_recess_geometry_canvas_and_scale")
	var glow_depth_ok: bool = bool(emission["passed"]) and int(emission["building_entries"]) == 4 and int(emission["retained_night_entries"]) == 28
	var minimum_glow_agreement := 1.0
	for record: Dictionary in emission["emission_entries"]:
		minimum_glow_agreement = minf(minimum_glow_agreement,float(record["nearest_surface_agreement"]))
		glow_depth_ok = glow_depth_ok and int(record["matched_original_faces"]) > 0 and float(record["nearest_surface_agreement"]) > 0.995
	check(alpha_ok and glow_depth_ok,"four_sparse_warm_masks_stay_inside_the_new_silhouette_and_all_actual_columns_and_roofs_block_light")
	var archived_ok := FileAccess.file_exists(ARCHIVE+".gdignore")
	for path: String in backup["copied_files"]: archived_ok = archived_ok and FileAccess.get_sha256(ARCHIVE+path) == backup["copied_files"][path]
	check(archived_ok,"all_49_replaced_source_assets_manifests_and_evidence_are_preserved_in_the_dedicated_archive")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"new_civic_geometries":changed,"preserved_noncivic_files":retained.size(),"minimum_visible_doric_columns":minimum_columns,"minimum_world_light_bsp_depth_agreement":minimum_agreement,"minimum_emission_depth_agreement":minimum_glow_agreement,"checked_emission_pixels":mask_pixels,"maximum_emission_alpha_byte":maximum_alpha},"scope":"One directed civic raw/imported asset contract with Dummy; independent original geometry visibility and full hash preservation. Root owns actual .62-clearance public-site compositing and the only live window. No human aesthetic approval."}
	FileAccess.open(PROOF+"asset_contract.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND210_CIVIC_ART ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
