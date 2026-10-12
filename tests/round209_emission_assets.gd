extends SceneTree
## Standalone raw-asset contract. No scene, sound device or catalog dependency.
const BASE := "res://资源/精制河湾/manifest.json"
const NIGHT := "res://资源/精制河湾/夜光/manifest.json"
const PROOF := "res://验证记录/round209_古典夜光资产/generation.json"
const PRESERVED := "res://验证记录/round208_古典植被/building_unchanged.json"
const OUTPUT := "res://验证记录/round209_古典夜光资产/asset_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy", "uses_dummy_audio_only")
	var base := read_json(BASE)
	var night := read_json(NIGHT)
	var proof := read_json(PROOF)
	var preserved := read_json(PRESERVED)
	var buildings: Dictionary = {}
	for entry: Dictionary in base["entries"]:
		if entry["role"] != "tree": buildings[entry["id"]] = entry
	var indexed: Dictionary = {}
	var hashes_ok := true
	var geometry_ok := true
	var alpha_ok := true
	var sparse_ok := true
	var features_ok := true
	var mipmaps_ok := true
	var pixel_total := 0
	var lit_total := 0
	var maximum_fraction := 0.0
	var hidden_doors := 0
	var pixel_records: Array[Dictionary] = []
	for entry: Dictionary in night["entries"]:
		var identifier: String = entry["id"]
		indexed[identifier] = entry
		var original: Dictionary = buildings[identifier]
		var texture_path: String = "res://"+entry["emission_texture"]
		var original_path: String = "res://"+original["texture"]
		hashes_ok = hashes_ok and FileAccess.get_sha256(texture_path) == entry["emission_sha256"] and FileAccess.get_sha256(original_path) == entry["base_texture_sha256"] and entry["base_texture_sha256"] == original["texture_sha256"]
		geometry_ok = geometry_ok and entry["emission_origin"] == original["origin"] and entry["emission_pixels_per_world"] == original["pixels_per_world"] and entry["orientation"] == original["orientation"] and entry["entrance_normal"] == original["entrance_normal"] and int(entry["era"]) == 1
		var mask := Image.load_from_file(texture_path)
		var source := Image.load_from_file(original_path)
		geometry_ok = geometry_ok and mask.get_size() == source.get_size()
		mask.convert(Image.FORMAT_RGBA8)
		source.convert(Image.FORMAT_RGBA8)
		var light := mask.get_data()
		var original_pixels := source.get_data()
		var solid := 0
		var lit := 0
		var peak := 0
		for pixel in range(0,light.size(),4):
			var a: int = light[pixel+3]
			if original_pixels[pixel+3] > 127: solid += 1
			if a == 0: continue
			lit += 1
			peak = maxi(peak,a)
			alpha_ok = alpha_ok and a <= original_pixels[pixel+3] and a <= 143 and light[pixel] == 255 and light[pixel+1] == 201 and light[pixel+2] == 130
		var fraction := float(lit)/float(solid)
		maximum_fraction = maxf(maximum_fraction,fraction)
		sparse_ok = sparse_ok and fraction < 0.035 and absf(fraction-float(entry["visible_emission_fraction"])) < 0.000001 and absf(float(peak)/255.0-float(entry["maximum_alpha"])) < 0.000001
		pixel_total += light.size()/4
		lit_total += lit
		var door_count := 0
		var window_count := 0
		var visible_count := 0
		var door_visible := false
		for feature: Dictionary in entry["features"]:
			var visible: bool = int(feature["visible_pixels"]) > 0
			visible_count += int(visible)
			if feature["kind"] == "door":
				door_count += 1
				door_visible = visible
				features_ok = features_ok and float(feature["peak_alpha"]) <= 0.56
			elif feature["kind"] == "window":
				window_count += 1
				features_ok = features_ok and float(feature["peak_alpha"]) <= 0.30
		features_ok = features_ok and door_count == 1 and window_count <= 1 and visible_count == int(entry["visible_feature_count"])
		if not door_visible: hidden_doors += 1
		if original["role"] == "courtyard" or int(original["orientation"]) in [0,3]: features_ok = features_ok and not door_visible
		var config := ConfigFile.new()
		mipmaps_ok = mipmaps_ok and config.load(texture_path+".import") == OK and config.get_value("params","mipmaps/generate") == true
		pixel_records.append({"id":identifier,"lit_pixels":lit,"solid_pixels":solid,"fraction":fraction,"maximum_alpha_byte":peak,"door_visible":door_visible})
	check(buildings.size() == 32 and indexed.size() == 32 and buildings.keys().all(func(identifier: String) -> bool: return indexed.has(identifier)), "all_32_original_classical_buildings_have_exactly_one_four_view_mask")
	check(hashes_ok and night["source_manifest_sha256"] == FileAccess.get_sha256(BASE), "mask_hashes_and_original_base_identity_match_the_independent_manifest")
	check(geometry_ok, "all_masks_preserve_canvas_origin_pixels_per_world_actual_entrance_and_era")
	check(alpha_ok, "every_lit_pixel_is_warm_sparse_alpha_inside_the_original_silhouette")
	check(sparse_ok, "each_mask_occupies_less_than_3_5_percent_of_its_actual_building")
	check(features_ok and hidden_doors > 0, "at_most_one_actual_recess_and_hidden_back_or_courtyard_doors_remain_dark")
	check(mipmaps_ok, "all_32_new_masks_enable_mipmaps_for_distant_view")
	var original_hashes: Dictionary = proof["original_hashes"]
	var after_hashes: Dictionary = proof["after_hashes"]
	var preservation_ok: bool = original_hashes == after_hashes and original_hashes.size() == 257 and int(preserved["building_files"]) == 256
	for path: String in original_hashes:
		preservation_ok = preservation_ok and FileAccess.get_sha256("res://"+path) == original_hashes[path]
	for path: String in preserved["hashes"]:
		preservation_ok = preservation_ok and original_hashes[path] == preserved["hashes"][path]
	check(preservation_ok, "main_manifest_and_all_256_round208_building_files_and_imports_are_unchanged")
	var depth_ok: bool = bool(proof["passed"]) and proof["emission_entries"].size() == 32
	var minimum_agreement := 1.0
	var bright_samples := 0
	var edge_disagreements := 0
	for entry: Dictionary in proof["emission_entries"]:
		minimum_agreement = minf(minimum_agreement,float(entry["nearest_surface_agreement"]))
		bright_samples += int(entry["bright_samples"])
		edge_disagreements += int(entry["occluded_bright_samples"])
		depth_ok = depth_ok and int(entry["matched_original_faces"]) > 0 and float(entry["nearest_surface_agreement"]) > 0.995
	check(depth_ok, "independent_nearest_triangle_rays_confirm_full_bsp_geometry_occlusion")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"building_entries":buildings.size(),"preserved_original_files":original_hashes.size(),"decoded_pixels":pixel_total,"lit_pixels":lit_total,"maximum_emission_fraction":maximum_fraction,"hidden_original_door_angles":hidden_doors,"independent_bright_samples":bright_samples,"minimum_nearest_surface_agreement":minimum_agreement,"raster_edge_disagreements":edge_disagreements,"images":pixel_records},"scope":"Raw assets with Dummy audio only. Full-pixel alpha, source hashes, original geometry depth and mipmap configuration. Root owns production Sprite reveal, compositor and live review."}
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND209_EMISSION_ASSETS ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
