class_name ValleyBuildingVariantCatalog
extends RefCounted
## Deterministic presentation only: no city RNG, acoustic state, or saved author choices.
const MANIFEST := "res://资源/街坊建筑变体/manifest.json"
const REFINED_MANIFEST := "res://资源/精制河湾/manifest.json"
const EMISSION_MANIFEST := "res://资源/精制河湾/夜光/manifest.json"
const ERA_MANIFEST := "res://资源/时代城市/manifest.json"
const FirstExpressionIdentity = preload("res://scripts/visual/first_expression_identity.gd")
var entries: Array[Dictionary] = []
var refined_manifest: Dictionary = {}
var refined_entries: Dictionary = {}
var retained_era_entries: Dictionary = {}
var textures: Dictionary = {}
var images: Dictionary = {}
var shadow_images: Dictionary = {}
var emission_entries: Dictionary = {}
var emission_textures: Dictionary = {}
var art_direction: RefCounted

func load_catalog() -> void:
	if not entries.is_empty(): return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for entry: Dictionary in manifest["entries"]:
		entries.append(entry)
		_prewarm_entry(entry)
	refined_manifest = JSON.parse_string(FileAccess.get_file_as_string(REFINED_MANIFEST))
	for entry: Dictionary in refined_manifest["entries"]:
		refined_entries[str(entry["id"])] = entry
		_prewarm_entry(entry)
	var lamps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EMISSION_MANIFEST))
	for entry: Dictionary in lamps["entries"]:
		emission_entries[str(entry["id"])] = entry
		emission_textures[str(entry["id"])] = load("res://"+str(entry["emission_texture"]))
	var eras: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ERA_MANIFEST))
	for entry: Dictionary in eras["entries"]:
		if int(entry["era"]) <= 1: continue
		retained_era_entries[str(int(entry["era"]))+":"+str(entry["category"])] = entry
		_prewarm_entry(entry)

func _prewarm_entry(entry: Dictionary) -> void:
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

func entry_for(building: Dictionary,fallback_entry: Dictionary = {},family: Dictionary = {},orientation: int = 0) -> Dictionary:
	# A building retains its actual birth era after the city advances.
	var building_era := int(building.get("era",1))
	if building_era != 1:
		return retained_era_entries.get(str(building_era)+":"+str(building.get("type","")),fallback_entry)
	if art_direction != null:
		var candidate: Dictionary = art_direction.building_entry(building,family,variant_index(str(building["district_id"])))
		if not candidate.is_empty(): return candidate
	var building_type := str(building.get("type",""))
	var expression := FirstExpressionIdentity.expression_for(building,family)
	if not expression.is_empty():
		var authored := preview_entry(expression,orientation)
		# Keep the real gameplay use: a residential companion of the weave
		# remains a house, while its actual commercial source remains a shop.
		if str(authored.get("category","")) == building_type: return authored
	if building_type == "residential":
		return _oriented_entry(str(refined_manifest["residential_ids"][variant_index(str(building["district_id"]))]),orientation)
	if building_type == "commercial": return _oriented_entry(str(refined_manifest["commercial_id"]),orientation)
	var base := fallback_entry
	return FirstExpressionIdentity.entry_for(building,base,entries,family)

func _oriented_entry(canonical_id: String,orientation: int) -> Dictionary:
	var ids: Array = refined_manifest["orientations"][canonical_id]
	return refined_entries[ids[posmod(orientation,4)]]

func preview_entry(expression: String,orientation: int = 0) -> Dictionary:
	# Cards and real route buildings share these baked production entries.
	var id := str(refined_manifest.get("authored_ids",{}).get(expression,""))
	return _oriented_entry(id,orientation) if not id.is_empty() else {}

func prop_entry(kind: String,tone: float = 0.0,era: int = 1,orientation: int = 0) -> Dictionary:
	if era != 1: return {}
	if kind == "civic": return _oriented_entry(str(refined_manifest["civic_id"]),orientation)
	if kind == "tree":
		var index := posmod(floori(tone),2)
		return refined_entries[refined_manifest["tree_ids"][index]]
	return {}

func prewarm_first_expressions(fallback_entries: Dictionary) -> void:
	# Call before starting audio, alongside existing texture/mask prewarming.
	if not refined_entries.is_empty(): return
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

func emission_for(entry: Dictionary) -> Texture2D:
	# Independent sparse masks leave the original geometry and hit image intact.
	return emission_textures.get(str(entry.get("id","")))
