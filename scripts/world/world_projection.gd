class_name WorldProjection
extends RefCounted
## Continuous world positions. Height inversion requires a known ground plane.

static func to_screen(world: Vector2, origin: Vector2, zoom: float, half_axes: Vector2 = Vector2(28,14), height: float = 0.0) -> Vector2:
	assert(zoom > 0.0 and half_axes.x > 0.0 and half_axes.y > 0.0)
	return origin + Vector2((world.x-world.y)*half_axes.x, (world.x+world.y-height)*half_axes.y)*zoom

static func from_screen(screen: Vector2, origin: Vector2, zoom: float, half_axes: Vector2 = Vector2(28,14), plane_height: float = 0.0) -> Vector2:
	assert(zoom > 0.0 and half_axes.x > 0.0 and half_axes.y > 0.0)
	var local := (screen-origin)/zoom
	var difference := local.x/half_axes.x
	var total := local.y/half_axes.y + plane_height
	return Vector2((total+difference)*0.5, (total-difference)*0.5)
