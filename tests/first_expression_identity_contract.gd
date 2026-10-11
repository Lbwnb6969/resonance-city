extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Catalog = preload("res://scripts/visual/building_variant_catalog.gd")
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const OUTPUT := "res://验证记录/首作路线外观/expression_identity.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	var assets: Dictionary = {}
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/时代城市/manifest.json"))
	for entry: Dictionary in manifest["entries"]:
		if int(entry["era"]) == 1: assets[str(entry["category"])] = entry
	var catalog := Catalog.new()
	catalog.load_catalog()
	for entry: Dictionary in assets.values():
		catalog.texture_for(entry)
		catalog.image_for(entry)
	catalog.prewarm_first_expressions(assets)
	var texture_count := catalog.textures.size()
	var image_count := catalog.images.size()
	var source := World.new("2026100900000062",true,"river_valley")
	source.build_first_composition_starter()
	var opening := source.snapshot()
	var regular: Dictionary = source.buildings[0]
	check(not catalog.entry_for(regular,assets["residential"]).has("first_expression_style"),"ordinary_opening_houses_keep_existing_variants")
	var routes: Dictionary = {}
	for choice: String in ["deep","weave","warm"]:
		var city := World.new(source.rng.seed_hex,false,"river_valley")
		city.restore(opening)
		var position: Array = First.opportunities(city)["seed_candidates"][0]["position"]
		var frame := int(city.cfg["timing"]["phrase_frames"])
		var queued := city.request({"kind":"seed","position":position,"midi":{"deep":36,"weave":60,"warm":48}[choice],"expression":choice,"player_expression":true},frame)
		city.settle(frame)
		var family: Dictionary = {}
		for item: Dictionary in city.families.values():
			if bool(item.get("player_expression",false)): family = item
		var house: Dictionary = city.by_id[str(family["root"])]
		var before := city.snapshot()
		var entry := catalog.entry_for(house,assets[str(house["type"])],family)
		var image := catalog.image_for(entry)
		var original := FileAccess.get_file_as_string("res://"+str(entry["source_texture"]))
		var styled := FileAccess.get_file_as_string("res://"+str(entry["texture"]))
		check(bool(queued.get("accepted",false)) and str(entry.get("first_expression_style","")) == choice and image.get_width() > 0,choice+"_real_authored_route_loads_its_prewarmed_texture")
		check(styled == Identity.svg_for(original,choice) and styled != original,choice+"_asset_changes_only_declared_fill_colors")
		var source_entry: Dictionary = assets[str(house["type"])]
		if str(house["type"]) == "residential":
			for candidate: Dictionary in catalog.entries:
				if str(candidate["texture"]) == str(entry["source_texture"]): source_entry = candidate
		check(entry["model_bounds"] == source_entry["model_bounds"] and entry["origin"] == source_entry["origin"] and entry["shadow_texture"] == source_entry["shadow_texture"] and entry["contact_texture"] == source_entry["contact_texture"] and image.get_size() == catalog.image_for(source_entry).get_size(),choice+"_keeps_source_footprint_origin_dimensions_and_shadow_geometry")
		check(city.snapshot() == before,choice+"_identity_queries_leave_world_pitch_events_reservations_and_rng_unchanged")
		routes[choice] = {"district_id":house["district_id"],"type":house["type"],"asset":entry["id"],"texture":entry["texture"],"reservation_count":city.planning_reservations.size()}
	check(catalog.textures.size() == texture_count and catalog.images.size() == image_count,"all_production_route_textures_and_hit_images_are_ready_before_first_growth")
	check(str(routes["weave"]["type"]) == "commercial" and str(routes["weave"]["texture"]).contains("commercial") and int(routes["warm"]["reservation_count"]) == 1,"weave_keeps_actual_shop_and_warm_keeps_actual_reservation")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"routes":routes,"scope":"Pure route visual identity over real first-expression families; imported SVG colors only, no new geometry, save fields, RNG, audio or human-art claim."},"\t")+"\n")
	print("FIRST_EXPRESSION_IDENTITY "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
