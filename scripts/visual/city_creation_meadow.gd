class_name CityCreationMeadow
extends Node3D
## Original low-detail meadow exemplars. Tiny Glade's recovered Grass2
## records inform deterministic clumps, obstacle removal and tip-weighted
## wind; no recovered mesh, texture or packed record is used here.
const BLOCK_SIZE := 8.0
const WORLD_RECT := Rect2(-18.0, -15.0, 35.0, 30.0)
const BASE_SPACING := 0.26
const State := preload("res://scripts/world/city_creation_state.gd")
var state: RefCounted
var blocks: Dictionary = {}
var block_counts: Dictionary = {}
var base_counts: Dictionary = {}
var fingerprints: Dictionary = {}
var meshes: Dictionary = {}
var materials: Dictionary = {}
var last_changed := 0
var elapsed_ms := 0.0

func setup(city_state: RefCounted) -> void:
	state = city_state
	name = "MeadowBlocks"

func rebuild(visible_by_block: Dictionary, dirty: Array[Vector2i]) -> void:
	var started := Time.get_ticks_usec()
	last_changed = 0
	for block: Vector2i in dirty:
		var members: Array = visible_by_block.get(block, [])
		var fingerprint := hash([members, _local_obstacles(block)])
		if fingerprints.get(block, -1) == fingerprint:
			continue
		fingerprints[block] = fingerprint
		if blocks.has(block):
			var old: Node3D = blocks[block]
			remove_child(old)
			old.queue_free()
			blocks.erase(block)
		block_counts.erase(block)
		base_counts.erase(block)
		var root := Node3D.new()
		root.name = "Meadow_%d_%d" % [block.x, block.y]
		root.position = Vector3(float(block.x) * BLOCK_SIZE, 0.0, float(block.y) * BLOCK_SIZE)
		root.set_meta("meadow_block", block)
		var batches := {"grass": [], "flower": [], "stone": []}
		# The production visibility rule scans every road and water stroke. A
		# dirty block gets a small authoritative mask once, so hundreds of grass
		# candidates reuse the exact same rule without a world-wide query.
		var query_state := _make_local_query_state(block)
		base_counts[block] = _add_short_meadow(block, batches.grass, query_state)
		for plant: Dictionary in members:
			_add_plant_clumps(block, plant, batches, query_state)
		var count := 0
		for part: String in batches:
			var records: Array = batches[part]
			count += records.size()
			_make_batch(root, part, records)
		if count > 0:
			add_child(root)
			blocks[block] = root
			block_counts[block] = count
		else:
			root.free()
		last_changed += 1
	elapsed_ms = float(Time.get_ticks_usec() - started) / 1000.0

func diagnostics() -> Dictionary:
	var count := 0
	var short_grass := 0
	for amount: int in block_counts.values():
		count += amount
	for amount: int in base_counts.values():
		short_grass += amount
	return {"blocks": blocks.size(), "instances": count,
		"base_grass": short_grass, "clumps": count - short_grass,
		"last_changed": last_changed, "elapsed_ms": elapsed_ms}

func _add_short_meadow(block: Vector2i, records: Array, query_state: RefCounted) -> int:
	var first := records.size()
	var origin := Vector2(block) * BLOCK_SIZE
	# The lattice belongs to world coordinates. Jittered samples crossing an
	# eight-metre boundary are owned by their final block, avoiding seams or
	# duplicate tufts when a neighbouring block alone is rebuilt.
	var start_x := floori(origin.x / BASE_SPACING) - 1
	var start_z := floori(origin.y / BASE_SPACING) - 1
	var end_x := ceili((origin.x + BLOCK_SIZE) / BASE_SPACING) + 1
	var end_z := ceili((origin.y + BLOCK_SIZE) / BASE_SPACING) + 1
	var dark := Color("63855a")
	var light := Color("6d8c60")
	for z in range(start_z, end_z):
		for x in range(start_x, end_x):
			var bits := _lattice_hash(x, z)
			var jitter_x := (float(bits & 1023) / 1023.0 - 0.5) * 0.13
			var jitter_z := (float((bits >> 10) & 1023) / 1023.0 - 0.5) * 0.13
			var at := Vector2((float(x) + 0.5) * BASE_SPACING + jitter_x,
				(float(z) + 0.5) * BASE_SPACING + jitter_z)
			if not _candidate_visible(block, at, query_state, 0.18):
				continue
			# Broad, barely perceptible drifts connect the lawn rather than
			# painting each cell a different noisy colour. Individual height
			# jitter stays below a centimetre and introduces no bare holes.
			var drift := 0.5 + 0.25 * sin(at.x * 0.31 + at.y * 0.17) + 0.25 * sin(at.y * 0.23 - at.x * 0.11)
			var height := 0.40 + drift * 0.075 + float((bits >> 20) & 63) / 63.0 * 0.025
			var width := 0.55 + float((bits >> 26) & 31) / 31.0 * 0.08
			var yaw := float(bits & 65535) / 65535.0 * TAU
			_append(records, block, at, Vector3(width, height, width), yaw,
				dark.lerp(light, drift), -0.003)
	return records.size() - first

func _lattice_hash(x: int, z: int) -> int:
	var value := ((x + 8192) * 73856093) ^ ((z + 8192) * 19349663) ^ 261014
	value = ((value ^ (value >> 13)) & 0x7fffffff) * 1274126177
	return (value ^ (value >> 16)) & 0x7fffffff

func _local_obstacles(block: Vector2i) -> Array:
	var rect := Rect2(Vector2(block) * BLOCK_SIZE, Vector2.ONE * BLOCK_SIZE).grow(1.0)
	var relevant: Array = []
	for house: Dictionary in state.get("houses"):
		var origin := Vector2(float(house.origin[0]), float(house.origin[1]))
		for cell: Dictionary in house.cells:
			if int(cell.level) != 0:
				continue
			var at := origin + Vector2(float(cell.x), float(cell.z)) * 1.8
			# Full foundation and exposed south doorway define the grass removal
			# domain; upper floors, names and palettes never invalidate grass.
			var footprint := Rect2(at - Vector2.ONE * 0.9, Vector2.ONE * 1.8)
			var doorway := Rect2(at + Vector2(0.0, 1.55) - Vector2.ONE * 1.06, Vector2.ONE * 2.12)
			if rect.intersects(footprint.grow(0.12)) or rect.intersects(doorway):
				relevant.append(["house", at, cell.kind])
				# Include the adjacent ground row that determines whether this
				# cell's doorway is exposed, even if it lies beyond this block.
				for neighbor: Dictionary in house.cells:
					if int(neighbor.level) == 0 and neighbor.x == cell.x and int(neighbor.z) == int(cell.z) + 1:
						relevant.append(["front", at, neighbor.kind])
	for road: Dictionary in state.get("roads"):
		_collect_segments(relevant, rect, "road", road.points, float(road.width) * 0.5 + 0.56)
	for water: Dictionary in state.get("waters"):
		_collect_segments(relevant, rect, "water", water.points, float(water.width) * 0.5 + 0.12)
	return relevant

func _make_local_query_state(block: Vector2i) -> RefCounted:
	var mask := State.new()
	var rect := Rect2(Vector2(block) * BLOCK_SIZE, Vector2.ONE * BLOCK_SIZE).grow(1.0)
	# Keep complete house dictionaries so doorway exposure still sees a
	# neighbour that happens to sit just outside this block.
	mask.houses = []
	for house: Dictionary in state.get("houses"):
		var origin := Vector2(float(house.origin[0]), float(house.origin[1]))
		var relevant := false
		for cell: Dictionary in house.cells:
			if int(cell.level) != 0:
				continue
			var at := origin + Vector2(float(cell.x), float(cell.z)) * 1.8
			var footprint := Rect2(at - Vector2.ONE * 0.9, Vector2.ONE * 1.8).grow(0.12)
			var doorway := Rect2(at + Vector2(0.0, 1.55) - Vector2.ONE * 1.06, Vector2.ONE * 2.12)
			if rect.intersects(footprint) or rect.intersects(doorway):
				relevant = true
				break
		if relevant:
			mask.houses.append(house.duplicate(true))
	mask.roads = []
	for road: Dictionary in state.get("roads"):
		var width := float(road.width)
		for index in range(1, road.points.size()):
			var a := Vector2(float(road.points[index - 1][0]), float(road.points[index - 1][1]))
			var b := Vector2(float(road.points[index][0]), float(road.points[index][1]))
			if _segment_hits(rect, a, b, width * 0.5 + 0.56):
				mask.roads.append({"id": road.get("id", "local"), "points": [[a.x, a.y], [b.x, b.y]],
					"width": width, "bridge": road.get("bridge", false), "source": road.get("source", "seed")})
	mask.waters = []
	for water: Dictionary in state.get("waters"):
		var width := float(water.width)
		var points: Array = water.points
		if points.size() == 1:
			var at := Vector2(float(points[0][0]), float(points[0][1]))
			if rect.intersects(Rect2(at - Vector2.ONE * (width * 0.5 + 0.12), Vector2.ONE * (width + 0.24))):
				mask.waters.append({"id": water.get("id", "local"), "points": [[at.x, at.y]], "width": width,
					"kind": water.get("kind", "pond"), "seed": water.get("seed", 0), "source": water.get("source", "seed")})
		else:
			for index in range(1, points.size()):
				var a := Vector2(float(points[index - 1][0]), float(points[index - 1][1]))
				var b := Vector2(float(points[index][0]), float(points[index][1]))
				if _segment_hits(rect, a, b, width * 0.5 + 0.12):
					mask.waters.append({"id": water.get("id", "local"), "points": [[a.x, a.y], [b.x, b.y]], "width": width,
						"kind": water.get("kind", "channel"), "seed": water.get("seed", 0), "source": water.get("source", "seed")})
	return mask

func _segment_hits(rect: Rect2, a: Vector2, b: Vector2, radius: float) -> bool:
	var bounds := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(a.x - b.x), absf(a.y - b.y))).grow(radius)
	return rect.intersects(bounds)

func _collect_segments(relevant: Array, rect: Rect2, kind: String, points: Array, radius: float) -> void:
	if points.size() == 1:
		var at := Vector2(float(points[0][0]), float(points[0][1]))
		if rect.intersects(Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)):
			relevant.append([kind, at, radius])
	for index in range(1, points.size()):
		var a := Vector2(float(points[index - 1][0]), float(points[index - 1][1]))
		var b := Vector2(float(points[index][0]), float(points[index][1]))
		var swept_bounds := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)),
			Vector2(absf(a.x - b.x), absf(a.y - b.y))).grow(radius)
		if rect.intersects(swept_bounds):
			relevant.append([kind, a, b, radius])

func _add_plant_clumps(block: Vector2i, plant: Dictionary, batches: Dictionary, query_state: RefCounted) -> void:
	var encoded: Array = plant.position
	var center := Vector2(float(encoded[0]), float(encoded[1]))
	var tree_scale := clampf(float(plant.scale), 0.25, 2.5)
	var shrub := str(plant.kind) == "shrub"
	var rng := RandomNumberGenerator.new()
	rng.seed = int(plant.seed) ^ 0x3752a1
	# Three overlapping drifts leave uneven patches of short meadow leaves,
	# rather than isolated tall stalks, a radial lawn or a dark painted disk.
	var angle := rng.randf() * TAU
	var spread := (0.70 if shrub else 1.15) * tree_scale
	var islands: Array[Vector2] = [center + Vector2.from_angle(angle) * spread * 0.20,
		center + Vector2.from_angle(angle + 1.9) * spread * rng.randf_range(0.65, 1.0),
		center + Vector2.from_angle(angle + 4.0) * spread * rng.randf_range(0.72, 1.15)]
	var attempts := rng.randi_range(14, 20) if shrub else rng.randi_range(24, 32)
	for index in range(attempts):
		var island := islands[index % 3]
		var at := island + Vector2(rng.randf_range(-0.46, 0.46), rng.randf_range(-0.38, 0.38)) * tree_scale
		var yaw := rng.randf() * TAU
		var height := rng.randf_range(0.78, 1.18)
		var tint := Color("63855a").lerp(Color("7d9564"), rng.randf())
		# Draw all random choices before the removal test: a new path removes
		# affected clumps but never shifts the survivors' exemplar or transform.
		var flower := rng.randf() < (0.042 if shrub else 0.033)
		var yellow := rng.randf() < 0.40
		var stone := index == 2 and rng.randf() < 0.18
		var flower_scale := rng.randf_range(0.84, 1.12)
		var stone_tint := Color("aea995").lerp(Color("c5bea7"), rng.randf())
		if not _candidate_visible(block, at, query_state):
			continue
		_append(batches.grass, block, at, Vector3(1.0, height, 1.0), yaw, tint, -0.004)
		if flower:
			_append(batches.flower, block, at, Vector3.ONE * flower_scale,
				yaw, Color("efd080") if yellow else Color("f4eddb"), -0.006)
		if stone:
			_append(batches.stone, block, at, Vector3(0.12, 0.058, 0.085), yaw,
				stone_tint, 0.018)

func _candidate_visible(block: Vector2i, at: Vector2, query_state: RefCounted, clearance_scale: float = 0.25) -> bool:
	if not WORLD_RECT.has_point(at):
		return false
	if Vector2i(floori(at.x / BLOCK_SIZE), floori(at.y / BLOCK_SIZE)) != block:
		return false
	return bool(query_state.call("vegetation_visible", {"id": "p_meadow", "position": [at.x, at.y],
		"kind": "shrub", "scale": clearance_scale, "seed": 0, "source": "seed"}))

func _append(records: Array, block: Vector2i, at: Vector2, scale_value: Vector3,
		yaw: float, tint: Color, y: float) -> void:
	var basis := Basis(Vector3.UP, yaw).scaled(scale_value)
	var local := Vector3(at.x - float(block.x) * BLOCK_SIZE, y, at.y - float(block.y) * BLOCK_SIZE)
	records.append([Transform3D(basis, local), tint])

func _make_batch(root: Node3D, part: String, records: Array) -> void:
	if records.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = _mesh(part)
	multi.instance_count = records.size()
	# GPU wind moves vertices after the engine's static mesh bounds are
	# computed. Include leaf reach, breeze and the tallest flower in the
	# block-local bound so edge tufts never vanish during camera orbit.
	multi.custom_aabb = AABB(Vector3(-0.35, -0.10, -0.35), Vector3(BLOCK_SIZE + 0.70, 0.60, BLOCK_SIZE + 0.70))
	for index in range(records.size()):
		multi.set_instance_transform(index, records[index][0])
		multi.set_instance_color(index, records[index][1])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Meadow_%s" % part
	instance.multimesh = multi
	instance.material_override = _material(part)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)

func _mesh(part: String) -> Mesh:
	if meshes.has(part):
		return meshes[part]
	var mesh: Mesh
	if part == "stone":
		var stone := SphereMesh.new()
		stone.radius = 1.0
		stone.height = 2.0
		stone.radial_segments = 6
		stone.rings = 2
		mesh = stone
	else:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		if part == "grass":
			# Six broad curved leaves. Three triangles per leaf keep the shared
			# clump at 18 triangles while its silhouette reads as a low soft fan.
			for blade in range(6):
				var angle := float(blade) * 2.39996
				var outward := Vector3(cos(angle), 0.0, sin(angle))
				var side := Vector3(-sin(angle), 0.0, cos(angle))
				var base := outward * (0.021 + float(blade % 2) * 0.019)
				var height := 0.155 + float(blade % 3) * 0.027
				var bend := base + outward * 0.078 + Vector3.UP * height * 0.68
				var tip := base + outward * (0.18 + float(blade % 2) * 0.023) + Vector3.UP * height
				var base_side := side * 0.020
				var mid_side := side * (0.043 + float(blade % 2) * 0.009)
				_triangle(surface, base - base_side, base + base_side, bend + mid_side, Color.WHITE)
				_triangle(surface, base - base_side, bend + mid_side, bend - mid_side, Color.WHITE)
				_triangle(surface, bend - mid_side, bend + mid_side, tip, Color.WHITE)
		else:
			# One short green stem and five broad petals remain readable from the
			# orthographic creation camera, using vertex color in the shared mesh.
			_triangle(surface, Vector3(-0.008, 0.0, 0.0), Vector3(0.008, 0.0, 0.0), Vector3(0.005, 0.235, 0.0), Color("92a777"))
			_triangle(surface, Vector3(-0.008, 0.0, 0.0), Vector3(0.005, 0.235, 0.0), Vector3(-0.005, 0.235, 0.0), Color("92a777"))
			for petal in range(5):
				var angle := float(petal) * TAU / 5.0
				var axis := Vector3(cos(angle), 0.0, sin(angle))
				var across := Vector3(-sin(angle), 0.0, cos(angle))
				var heart := Vector3(0.0, 0.23, 0.0)
				var a := heart + axis * 0.047 + across * 0.032
				var b := heart + axis * 0.085 + Vector3.UP * 0.006
				var c := heart + axis * 0.047 - across * 0.032
				_triangle(surface, heart, a, b, Color.WHITE)
				_triangle(surface, heart, b, c, Color.WHITE)
		surface.index()
		mesh = surface.commit()
	meshes[part] = mesh
	return mesh

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color) -> void:
	var normal := (c - a).cross(b - a).normalized()
	for point: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.set_color(tint)
		surface.set_uv(Vector2(0.0, clampf(point.y / 0.27, 0.0, 1.0)))
		surface.add_vertex(point)

func _material(part: String) -> Material:
	if materials.has(part):
		return materials[part]
	var material: Material
	if part == "stone":
		var stone := StandardMaterial3D.new()
		stone.vertex_color_use_as_albedo = true
		stone.roughness = 1.0
		material = stone
	else:
		var shader := Shader.new()
		shader.code = """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform bool is_grass = true;
varying float tip_weight;
varying vec4 clump_tint;
void vertex() {
	tip_weight = UV.y;
	clump_tint = COLOR;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float breeze = sin(TIME * 0.85 + world.x * 0.37 + world.z * 0.29);
	float small_wave = sin(TIME * 1.23 + world.x * 0.83 - world.z * 0.47);
	VERTEX.x += (breeze * 0.014 + small_wave * 0.006) * tip_weight * tip_weight;
	VERTEX.z += breeze * 0.009 * tip_weight * tip_weight;
}
void fragment() {
	// Both faces of the short leaf fan share the lawn's upward light normal.
	// This avoids black back-facing card silhouettes under grazing sunlight.
	if (is_grass) {
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	}
	vec3 root = vec3(0.93, 0.97, 0.91);
	ALBEDO = clump_tint.rgb * (is_grass ? mix(root, vec3(1.015), smoothstep(0.0, 0.8, tip_weight)) : vec3(1.0));
	ROUGHNESS = 1.0;
}
"""
		var foliage := ShaderMaterial.new()
		foliage.shader = shader
		foliage.set_shader_parameter("is_grass", part == "grass")
		material = foliage
	materials[part] = material
	return material
