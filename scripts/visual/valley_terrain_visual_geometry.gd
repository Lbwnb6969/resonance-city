extends RefCounted
## Retained visual surfaces sampled from the existing terrain. This data has
## no occupancy, randomness, simulation state or independent height field.
const HEIGHT_LEVELS := [0.48,0.82,1.28]
const CELL_SIZE := 2.0

static func build(terrain: RefCounted) -> Dictionary:
	var result := {"surfaces":[],"contours":[],"rims":[],"shore_faces":[],"shallow_water":[],"channel":PackedVector2Array()}
	for bank: PackedVector2Array in [terrain.left_bank,terrain.right_bank]:
		var side := 0 if bank == terrain.left_bank else 1
		var box := _bounds(bank)
		# Long retained maps keep bounded preparation; local relief still uses
		# actual heights and is never regenerated for camera or light changes.
		var step := maxf(CELL_SIZE,box.size.y/80.0)
		for y_index in range(ceili(box.size.y/step)):
			for x_index in range(ceili(box.size.x/step)):
				var a := box.position+Vector2(x_index*step,y_index*step)
				var b := a+Vector2(minf(step,box.end.x-a.x),minf(step,box.end.y-a.y))
				var cell := PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
				for piece in Geometry2D.intersect_polygons(cell,bank):
					var triangles := Geometry2D.triangulate_polygon(piece)
					for at in range(0,triangles.size(),3):
						var triangle := PackedVector2Array([piece[triangles[at]],piece[triangles[at+1]],piece[triangles[at+2]]])
						for band in range(HEIGHT_LEVELS.size()+1):
							var polygon := triangle
							if band > 0: polygon = _height_clip(terrain,polygon,HEIGHT_LEVELS[band-1],true)
							if band < HEIGHT_LEVELS.size(): polygon = _height_clip(terrain,polygon,HEIGHT_LEVELS[band],false)
							# Shore clipping may leave a zero-area corner. Do not
							# retain it as a CanvasItem polygon draw command.
							if polygon.size() >= 3 and not Geometry2D.triangulate_polygon(polygon).is_empty(): result["surfaces"].append({"polygon":polygon,"band":band,"side":side})
						for level: float in HEIGHT_LEVELS:
							var contour := _contour(terrain,triangle,level)
							if contour.size() == 2: result["contours"].append({"path":contour,"height":level})
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var count: int = terrain.water.size()/2
	for index in range(count):
		left.append(terrain.water[index])
		right.append(terrain.water[terrain.water.size()-1-index])
	var channel_left := PackedVector2Array()
	var channel_right := PackedVector2Array()
	for index in range(count):
		channel_left.append(left[index].lerp(right[index],0.19))
		channel_right.append(right[index].lerp(left[index],0.19))
	for side in range(2):
		var shore := left if side == 0 else right
		var across := right if side == 0 else left
		var inland := -1.0 if side == 0 else 1.0
		for index in range(count-1):
			var a := shore[index]
			var b := shore[index+1]
			var width_a: float = float(terrain.cfg.get("template_shore_buffer_ratio",0.12))*terrain.river_width(a.y)
			var width_b: float = float(terrain.cfg.get("template_shore_buffer_ratio",0.12))*terrain.river_width(b.y)
			result["rims"].append(PackedVector2Array([a,b,b+Vector2(inland*width_b,0),a+Vector2(inland*width_a,0)]))
			result["shallow_water"].append(PackedVector2Array([a,b,b.lerp(across[index+1],0.055),a.lerp(across[index],0.055)]))
			# The viewer sees positive X/Y facing slopes. A back-facing river
			# wall stays behind its own bank instead of painting over the land.
			var outward := Vector2((b-a).y,-(b-a).x)*(1.0 if side == 0 else -1.0)
			if outward.dot(Vector2.ONE) > 0.0:
				result["shore_faces"].append({"edge":PackedVector2Array([a,b]),"heights":[terrain.height_at(a),terrain.height_at(b)]})
	result["channel"] = channel_left
	for index in range(channel_right.size()-1,-1,-1): result["channel"].append(channel_right[index])
	return result

static func _height_clip(terrain: RefCounted,polygon: PackedVector2Array,level: float,above: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty(): return result
	var previous := polygon[-1]
	var previous_height: float = terrain.height_at(previous)
	var previous_inside := previous_height >= level if above else previous_height <= level
	for current in polygon:
		var current_height: float = terrain.height_at(current)
		var inside := current_height >= level if above else current_height <= level
		if inside != previous_inside: result.append(_level_point(terrain,previous,current,level))
		if inside: result.append(current)
		previous = current
		previous_height = current_height
		previous_inside = inside
	return result

static func _level_point(terrain: RefCounted,a: Vector2,b: Vector2,level: float) -> Vector2:
	# A short bisection lands on the real noise height, keeping drawn contour
	# and height-band boundaries consistent instead of using circular rings.
	var low := a
	var high := b
	var a_above: bool = terrain.height_at(a) >= level
	for iteration in range(9):
		var middle := (low+high)*0.5
		if (terrain.height_at(middle) >= level) == a_above: low = middle
		else: high = middle
	return (low+high)*0.5

static func _contour(terrain: RefCounted,triangle: PackedVector2Array,level: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(triangle.size()):
		var a := triangle[index]
		var b := triangle[(index+1)%triangle.size()]
		if (terrain.height_at(a) >= level) != (terrain.height_at(b) >= level): result.append(_level_point(terrain,a,b,level))
	return result

static func _bounds(polygon: PackedVector2Array) -> Rect2:
	var result := Rect2(polygon[0],Vector2.ZERO)
	for point in polygon: result = result.expand(point)
	return result
