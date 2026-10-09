class_name ValleyTerrain
extends RefCounted
## Controlled terrain slice with several playable terrain families sharing the same continuous-world contract.
const Config = preload("res://scripts/world/world_values.gd")
var cfg: Dictionary = Config.load_values()["terrain"]
var noise := FastNoiseLite.new()
var noise_seed := 0
var river_phase := 0.0
var family := "river_valley"
var water := PackedVector2Array()
var left_bank := PackedVector2Array()
var right_bank := PackedVector2Array()

static func family_ids() -> Array[String]:
	return ["river_valley","lake_basin","forest_ridge","coastal_plain","highland_pass"]

static func family_title(value: String) -> String:
	return {"river_valley":"河谷","lake_basin":"湖盆","forest_ridge":"林岭","coastal_plain":"海湾平原","highland_pass":"高地峡谷"}.get(value,"河谷")

func configure(seed_value: int, phase: float, terrain_family: String = "river_valley") -> void:
	noise_seed = seed_value
	river_phase = phase
	family = terrain_family if family_ids().has(terrain_family) else "river_valley"
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
	var base := float(cfg["template_river_center"])
	if family == "coastal_plain":
		base -= 1.1
	elif family == "highland_pass":
		base += 0.7
		return base+1.55*sin(y*0.14+river_phase)+0.42*cos(y*0.37+river_phase)
	return base+0.8*sin(y*0.19+river_phase)+0.24*sin(y*0.53+river_phase)

func river_width(y: float) -> float:
	var base := float(cfg["template_river_base_half_width"])
	match family:
		"lake_basin":
			return 2.45+0.55*sin((y-5.0)*0.24+river_phase)+0.22*sin(y*0.61)
		"forest_ridge":
			return base*0.78+0.12*sin(y*0.31+river_phase)
		"coastal_plain":
			return base*1.35+0.22*sin(y*0.27+river_phase)
		"highland_pass":
			return base*0.62+0.16*sin(y*0.44+river_phase)
		_:
			return base+(y-float(cfg["template_land_min"]))*float(cfg["template_river_widening"])

func height_at(p: Vector2) -> float:
	var hill_gain := 1.8
	var ridge := 0.0
	match family:
		"lake_basin":
			hill_gain = 1.35
			ridge = 0.22*cos(p.y*0.26+river_phase)
		"forest_ridge":
			hill_gain = 3.0
			ridge = 0.55*sin(p.y*0.21+river_phase)+0.28*cos(p.x*0.17)
		"coastal_plain":
			hill_gain = 0.75
			ridge = 0.08*sin(p.y*0.33)
		"highland_pass":
			hill_gain = 4.2
			ridge = 0.72*cos(p.y*0.18+river_phase)+0.34*sin(p.x*0.23)
	var hill := hill_gain*exp(-p.distance_squared_to(Vector2(4,2))/60.0)
	return maxf(0.0,0.28+0.18*noise.get_noise_2dv(p)+hill+ridge)

func land_at(p: Vector2) -> bool:
	var low := float(cfg["template_land_min"])
	var high := float(cfg["template_land_max"])
	return p.x >= low and p.x <= high and p.y >= low and p.y <= high and not Geometry2D.is_point_in_polygon(p,water)

func valid_footprint(polygon: PackedVector2Array) -> bool:
	for p in polygon:
		if not land_at(p): return false
	return Geometry2D.intersect_polygons(polygon,water).is_empty()

func environment(a: Vector2,b: Vector2,bridge: bool) -> Dictionary:
	var crossing := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a,b]),water)
	var open := crossing.is_empty()
	if not open and bridge:
		open = true
		for line in crossing:
			for p in line:
				if absf(p.y-float(cfg["template_bridge_y"])) > 0.55: open = false
	var terrain_factor := 1.0
	if family in ["forest_ridge","highland_pass"] and crossing.is_empty():
		terrain_factor = float(Config.load_values()["space"]["forest_factor"])*(1.08 if family == "highland_pass" else 1.0)
	elif not crossing.is_empty() and open:
		terrain_factor = float(Config.load_values()["space"]["water_factor"])
	return {"occlusion":1.0 if open else 0.0,"terrain_factor":terrain_factor,
		"sigma_a":1.0+height_at(a)/8.0,"sigma_b":1.0+height_at(b)/8.0}

func buildable_ratio() -> float:
	var count := 0
	for y in range(-8,40):
		for x in range(-8,40):
			if land_at(Vector2(x+0.5,y+0.5)): count += 1
	return float(count)/(48.0*48.0)
