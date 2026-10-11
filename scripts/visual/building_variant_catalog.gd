class_name ValleyBuildingVariantCatalog
extends RefCounted
## Deterministic presentation only: no city RNG, acoustic state, or saved author choices.
const MANIFEST := "res://资源/街坊建筑变体/manifest.json"
const FirstExpressionIdentity = preload("res://scripts/visual/first_expression_identity.gd")
var entries: Array[Dictionary] = []
var textures: Dictionary = {}
var images: Dictionary = {}
var shadow_images: Dictionary = {}

func load_catalog() -> void:
	if not entries.is_empty(): return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for entry: Dictionary in manifest["entries"]:
		entries.append(entry)
		texture_for(entry)
		image_for(entry)
		for kind: String in ["shadow","contact"]:
			var path := "res://"+str(entry[kind+"_texture"])
			var texture: Texture2D = load(path)
			shadow_images[path] = texture.get_image()

static func variant_index(id: String) -> int:
	var value := 0
	for index in range(id.length()): value = (value*31+id.unicode_at(index))%2147483647
	return posmod(value,3)

func prewarm_masks(shadow_layer: Node2D) -> void:
	shadow_layer.mask_images.merge(shadow_images,true)

func entry_for(building: Dictionary,fallback_entry: Dictionary = {},family: Dictionary = {}) -> Dictionary:
	var base := fallback_entry
	if str(building.get("type","")) == "residential": base = entries[variant_index(str(building["district_id"]))]
	return FirstExpressionIdentity.entry_for(building,base,entries,family)

func prewarm_first_expressions(fallback_entries: Dictionary) -> void:
	# Call before starting audio, alongside existing texture/mask prewarming.
	for expression: String in ["deep","weave","warm"]:
		var base: Dictionary = fallback_entries["commercial"] if expression == "weave" else {}
		if base.is_empty():
			for entry: Dictionary in entries:
				if str(entry["id"]) == str(FirstExpressionIdentity.STYLES[expression]["residential_id"]):
					base = entry
					break
		var styled := FirstExpressionIdentity.styled_entry(base,expression)
		texture_for(styled)
		image_for(styled)

func texture_for(entry: Dictionary) -> Texture2D:
	var path := "res://"+str(entry["texture"])
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

func image_for(entry: Dictionary) -> Image:
	var path := "res://"+str(entry["texture"])
	if not images.has(path): images[path] = texture_for(entry).get_image()
	return images[path]
