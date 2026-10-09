class_name ValleyTerrain
extends RefCounted
## Controlled first slice: continuous shores and a seeded four-octave height field.
const Config = preload("res://scripts/world/world_values.gd")
var cfg: Dictionary = Config.load_values()["terrain"]
var noise := FastNoiseLite.new()
var noise_seed := 0
var river_phase := 0.0
var water := PackedVector2Array()
var left_bank := PackedVector2Array()
var right_bank := PackedVector2Array()

func configure(seed_value: int, phase: float) -> void:
	noise_seed = seed_value
	river_phase = phase
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = int(cfg["noise_octaves"])
	noise.fractal_gain = float(cfg["noise_gain"])
	noise.fractal_lacunarity = float(cfg["noise_lacunarity"])
	noise.frequency = float(cfg["noise_frequency"])
	var low := float(cfg["template_land_min"])
	var high := float(cfg["template_land_max"])
	var shore_left := PackedVector2Array()
	var shore_right := PackedVector2Array()
	for i in range(81):
		var y := lerpf(low,high,float(i)/80.0)
		shore_left.append(Vector2(river_x(y)-river_width(y),y))
		shore_right.append(Vector2(river_x(y)+river_width(y),y))
	water = shore_left.duplicate()
	for i in range(shore_right.size()-1,-1,-1): water.append(shore_right[i])
	left_bank = PackedVector2Array([Vector2(low,low)])
	left_bank.append_array(shore_left)
	left_bank.append(Vector2(low,high))
	right_bank = PackedVector2Array([Vector2(high,low),Vector2(high,high)])
	for i in range(shore_right.size()-1,-1,-1): right_bank.append(shore_right[i])

func river_x(y: float) -> float:
	return float(cfg["template_river_center"])+0.8*sin(y*0.19+river_phase)+0.24*sin(y*0.53+river_phase)

func river_width(y: float) -> float:
	return float(cfg["template_river_base_half_width"])+(y-float(cfg["template_land_min"]))*float(cfg["template_river_widening"])

func height_at(p: Vector2) -> float:
	var hill := 1.8*exp(-p.distance_squared_to(Vector2(4,2))/60.0)
	return maxf(0.0,0.28+0.18*noise.get_noise_2dv(p)+hill)

func land_at(p: Vector2) -> bool:
	var low := float(cfg["template_land_min"])
	var high := float(cfg["template_land_max"])
	return p.x >= low and p.x <= high and p.y >= low and p.y <= high and not Geometry2D.is_point_in_polygon(p,water)

func valid_footprint(polygon: PackedVector2Array) -> bool:
	for p in polygon:
		if not land_at(p): return false
	# A thin river can cut a polygon whose corners are all on dry land.
	return Geometry2D.intersect_polygons(polygon,water).is_empty()

func environment(a: Vector2,b: Vector2,bridge: bool) -> Dictionary:
	var crossing := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a,b]),water)
	var open := crossing.is_empty()
	if not open and bridge:
		open = true
		for line in crossing:
			for p in line:
				if absf(p.y-float(cfg["template_bridge_y"])) > 0.55: open = false
	return {"occlusion":1.0 if open else 0.0,"terrain_factor":float(Config.load_values()["space"]["water_factor"]) if not crossing.is_empty() and open else 1.0,
		"sigma_a":1.0+height_at(a)/8.0,"sigma_b":1.0+height_at(b)/8.0}

func buildable_ratio() -> float:
	var count := 0
	for y in range(-8,40):
		for x in range(-8,40):
			if land_at(Vector2(x+0.5,y+0.5)): count += 1
	return float(count)/(48.0*48.0)
