extends RefCounted
## Optional art review. Entries and palettes never enter a World or work save.
const BUILDINGS := "res://资源/美术候选/建筑/manifest.json"
const FOLIAGE := "res://资源/美术候选/植被/manifest.json"
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const STYLE_IDS := ["baseline","clay","garden","paper"]
const LABELS := {"baseline":"原河湾","clay":"陶土街巷","garden":"清透园林","paper":"纸上城镇"}
const PALETTES := {
	"clay":{"left":["e9dccc","d9cdb8","c1c4a3","acb698"],"right":["e2ddc9","d0d1b6","bcc5a3","acb698"],
		"rim":"c8c8ab","water":"9ab8b3","channel":"7fa9ab","shallow":"b4cbc0","shore":"a6b2a0","edge":"e1ddc6",
		"road":"f1e6d5","bridge":"d2b697","backdrop":"f0e9df","world_tint":Color(1.0,0.985,0.96)},
	"garden":{"left":["e6e6d6","d6decf","c2d2be","abc4b6"],"right":["e4e9df","d2dfd3","bed3c5","abc4b6"],
		"rim":"c4d6c5","water":"a1bec3","channel":"82a8b7","shallow":"bdd5ce","shore":"a5b9ae","edge":"e0e9d7",
		"road":"f2f2e8","bridge":"c9c5b1","backdrop":"eaf0eb","world_tint":Color(0.965,0.99,1.0)},
	"paper":{"left":["e8e2d6","d6d5c4","c1c6b0","b0bca7"],"right":["e2e3d8","d0d6c7","bdcbb8","b0bca7"],
		"rim":"c8cfb9","water":"a7bbbd","channel":"8ba8b0","shallow":"c2d1c8","shore":"aeb8a8","edge":"e6e6d7",
		"road":"f7f3e9","bridge":"c9bda7","backdrop":"f0eee6","world_tint":Color(1.0,0.995,0.975)},
}
var selected_id := "baseline"
var styles: Dictionary = {}
var foliage_styles: Dictionary = {}
var entries: Dictionary = {}
var authored_entries: Dictionary = {}
var textures: Dictionary = {}

func load_catalog(catalog: RefCounted) -> void:
	var buildings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BUILDINGS))
	var foliage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLIAGE))
	styles = buildings["styles"]
	foliage_styles = foliage["styles"]
	for manifest: Dictionary in [buildings,foliage]:
		for entry: Dictionary in manifest["entries"]:
			entries[str(entry["id"])] = entry
			textures[str(entry["id"])] = catalog.texture_for(entry)
			catalog.image_for(entry)
			for kind: String in ["shadow","contact"]:
				var path := "res://"+str(entry[kind+"_texture"])
				var texture: Texture2D = load(path)
				catalog.shadow_images[path] = texture.get_image()
	for style: String in styles:
		for expression: String in ["deep","weave","warm"]:
			var role := "commercial" if expression == "weave" else ("terrace" if expression == "deep" else "gabled")
			var entry: Dictionary = entries[str(styles[style]["role_map"][role])]
			authored_entries[style+":"+expression+":"+role] = _authored_entry(entry,expression,catalog)
			if expression == "weave":
				entry = entries[str(styles[style]["role_map"]["hipped"])]
				authored_entries[style+":"+expression+":hipped"] = _authored_entry(entry,expression,catalog)

func _authored_entry(base: Dictionary,expression: String,catalog: RefCounted) -> Dictionary:
	var entry := base.duplicate(true)
	var svg := FileAccess.get_file_as_string("res://"+str(base["texture"]))
	var target: Color = Identity.STYLES[expression]["ink"]
	for value: String in base["author_palette_colors"]:
		var source := Color(value)
		var shade := target.lightened(clampf((source.v-0.65)*0.45,0.0,0.22)).darkened(clampf((0.65-source.v)*0.4,0.0,0.18))
		svg = svg.replace('fill="'+value+'"','fill="#'+shade.to_html(false).to_upper()+'"')
	var image := Image.new()
	assert(image.load_svg_from_string(svg,0.5) == OK)
	image.generate_mipmaps()
	entry["id"] = str(base["id"])+":"+expression
	entry["texture"] = str(base["texture"])+":"+expression
	entry["first_expression_style"] = expression
	entry["origin"] = [float(base["origin"][0])*0.5,float(base["origin"][1])*0.5]
	entry["pixels_per_world"] = float(base["pixels_per_world"])*0.5
	entry["image_bounds"] = {"width":image.get_width(),"height":image.get_height(),"crop":[0,0,image.get_width(),image.get_height()]}
	var path := "res://"+str(entry["texture"])
	catalog.textures[path] = ImageTexture.create_from_image(image)
	catalog.images[path] = image
	return entry

func building_entry(building: Dictionary,family: Dictionary,variant: int) -> Dictionary:
	if selected_id == "baseline": return {}
	var expression := Identity.expression_for(building,family)
	var role: String = ["terrace","gabled","hipped"][variant]
	if str(building["type"]) == "commercial": role = "commercial"
	elif str(building["type"]) != "residential": return {}
	elif not expression.is_empty(): role = "terrace" if expression == "deep" else ("gabled" if expression == "warm" else "hipped")
	if not expression.is_empty(): return authored_entries[selected_id+":"+expression+":"+role]
	return entries[str(styles[selected_id]["role_map"][role])]

func prop_entry(kind: String,tone: int) -> Dictionary:
	if selected_id == "baseline": return {}
	if kind == "tree":
		var ids: Array = foliage_styles[selected_id]["tree_ids"]
		return entries[str(ids[posmod(tone,ids.size())])]
	if kind == "civic": return entries[str(styles[selected_id]["role_map"]["civic"])]
	return {}

func palette() -> Dictionary: return PALETTES.get(selected_id,{})

func daylight(state: Dictionary) -> Dictionary:
	if selected_id == "baseline": return state
	var result := state.duplicate()
	var colors := palette()
	result["world_tint"] = state["world_tint"]*colors["world_tint"]
	result["backdrop"] = Color(colors["backdrop"]).lerp(state["backdrop"],float(state["night_strength"])*0.85)
	return result
