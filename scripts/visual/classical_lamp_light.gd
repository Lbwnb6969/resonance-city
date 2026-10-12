extends Node2D
## Emission belongs to the oil wick, while the node keeps the lamp's ground sort.
const WICK_POSITION := Vector2(3.7,-12.3)
const GROUND_RECT := Rect2(-7.0,-3.5,14.0,7.0)
const WICK_RECT := Rect2(-3.1,-3.1,6.2,6.2)
const GROUND_COLOR := Color(1.0,0.67,0.32,0.085)
const WICK_COLOR := Color(1.0,0.70,0.34,0.16)
const FLAME_COLOR := Color(1.0,0.72,0.33,0.66)
const CORE_COLOR := Color(1.0,0.93,0.65,0.83)
static var soft_texture: GradientTexture2D
static var emission_material: CanvasItemMaterial

func _init() -> void:
	# Draw before the opaque bowl/pedestal. Nearby foreground houses still
	# occlude the whole lamp through the existing ground-level depth sort.
	show_behind_parent = true
	position = Vector2.ZERO
	scale = Vector2.ONE
	y_sort_enabled = false
	visible = false
	if emission_material == null:
		emission_material = CanvasItemMaterial.new()
		emission_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		emission_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = emission_material
	if soft_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0,0.22,0.56,0.82,1.0])
		gradient.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0.79),Color(1,1,1,0.27),Color(1,1,1,0.035),Color(1,1,1,0)])
		soft_texture = GradientTexture2D.new()
		soft_texture.width = 64
		soft_texture.height = 64
		soft_texture.gradient = gradient
		soft_texture.fill = GradientTexture2D.FILL_RADIAL
		soft_texture.fill_from = Vector2(0.5,0.5)
		soft_texture.fill_to = Vector2(1.0,0.5)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func sync(night_strength: float,world_tint: Color) -> void:
	# Scenery has already removed building warmth from the parent. Undo RGB
	# tint only; real reveal alpha remains inherited from ValleyProp once.
	modulate = Color(1.0/world_tint.r,1.0/world_tint.g,1.0/world_tint.b,clampf(night_strength,0.0,1.0))
	visible = night_strength > 0.0

static func flame_polygon() -> PackedVector2Array:
	return PackedVector2Array([WICK_POSITION+Vector2(-0.45,0.24),WICK_POSITION+Vector2(-0.29,-0.63),WICK_POSITION+Vector2(0.0,-1.55),WICK_POSITION+Vector2(0.43,-0.54),WICK_POSITION+Vector2(0.34,0.25)])

func _draw() -> void:
	# The small 2:1 pool stays on the foot plane; there is no broad halo or ring.
	draw_texture_rect(soft_texture,GROUND_RECT,false,GROUND_COLOR)
	draw_texture_rect(soft_texture,Rect2(WICK_POSITION+WICK_RECT.position,WICK_RECT.size),false,WICK_COLOR)
	draw_colored_polygon(flame_polygon(),FLAME_COLOR)
	draw_colored_polygon(PackedVector2Array([WICK_POSITION+Vector2(-0.18,0.18),WICK_POSITION+Vector2(0.02,-0.74),WICK_POSITION+Vector2(0.24,0.18)]),CORE_COLOR)
