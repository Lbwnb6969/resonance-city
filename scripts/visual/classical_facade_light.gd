extends Sprite2D
## A mask shares its actual parent's geometry and sorting. It never owns a city.
static var emission_material: CanvasItemMaterial

func _init() -> void:
	name = "ClassicalFacadeLight"
	centered = false
	if emission_material == null:
		emission_material = CanvasItemMaterial.new()
		emission_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		emission_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = emission_material

func set_entry(entry: Dictionary,mask: Texture2D) -> void:
	texture = mask
	offset = -Vector2(entry["origin"][0],entry["origin"][1])

func sync(revealed: bool,night_strength: float,inherited_tint: Color) -> void:
	# Light starts after the audible growth primitive has finished revealing.
	visible = texture != null and revealed and night_strength > 0.001
	if not visible: return
	# The stone surfaces stay in moonlight; the warm opening emits its own color.
	# Inherit parent's visibility, alpha, position and scale exactly once.
	modulate = Color(1.0/inherited_tint.r,1.0/inherited_tint.g,1.0/inherited_tint.b,night_strength*0.84)
