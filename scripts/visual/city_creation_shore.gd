class_name CityCreationShore
extends Node3D
## Original shore exemplars: deterministic placement, obstacle removal and
## tip-weighted wind informed by Tiny Glade's Grass2 report, without assets.
const State := preload("res://scripts/world/city_creation_state.gd")
const GrassMask := preload("res://scripts/visual/city_creation_grass_mask.gd")
const BLOCK_SIZE := 8.0
const SPACING := 0.6
const LAND_RECT := Rect2(-30.0, -28.0, 60.0, 56.0)
var state: RefCounted
var blocks: Dictionary = {}
var fingerprints: Dictionary = {}
var counts: Dictionary = {}
var meshes: Dictionary = {}
var materials: Dictionary = {}
var detail := 1.0
var last_changed := 0
var elapsed_ms := 0.0
var _geometry: Array = []

func setup(city_state: RefCounted) -> void:
	state = city_state
	name = "ShoreBlocks"

func rebuild() -> void:
	var started := Time.get_ticks_usec()
	last_changed = 0
	var geometry := _geometry_signature()
	if geometry == _geometry:
		elapsed_ms = float(Time.get_ticks_usec()-started)/1000.0
		return
	_geometry = geometry
	for z in range(floori(LAND_RECT.position.y / BLOCK_SIZE), ceili(LAND_RECT.end.y / BLOCK_SIZE)):
		for x in range(floori(LAND_RECT.position.x / BLOCK_SIZE), ceili(LAND_RECT.end.x / BLOCK_SIZE)):
			var block := Vector2i(x, z)
			var signature := hash(_local_obstacles(block))
			if fingerprints.get(block, -1) == signature:
				continue
			fingerprints[block] = signature
			if blocks.has(block):
				var old: Node3D = blocks[block]
				remove_child(old)
				old.queue_free()
				blocks.erase(block)
			counts.erase(block)
			var mask := GrassMask.new()
			mask.setup(state, block)
			var records := _candidates(block, mask)
			var root := Node3D.new()
			root.name = "Shore_%d_%d" % [x, z]
			root.position = Vector3(float(x) * BLOCK_SIZE, 0.0, float(z) * BLOCK_SIZE)
			root.set_meta("candidates", records)
			var amounts := {"grass": 0, "reed": 0, "stone": 0}
			for part: String in amounts:
				var batch: Array = []
				for record: Dictionary in records:
					if record.part == part: batch.append(record)
				amounts[part] = batch.size()
				_make_batch(root, part, batch)
			if not records.is_empty():
				add_child(root)
				blocks[block] = root
				counts[block] = amounts
			else: root.free()
			last_changed += 1
	elapsed_ms = float(Time.get_ticks_usec() - started) / 1000.0

func _geometry_signature() -> Array:
	var water_rows: Array = []
	var road_rows: Array = []
	var houses: Array = []
	for water: Dictionary in state.waters: water_rows.append([water.points.duplicate(true),water.width])
	for road: Dictionary in state.roads: road_rows.append([road.points.duplicate(true),road.width])
	for house: Dictionary in state.houses:
		var cells: Array = []
		for cell: Dictionary in house.cells:
			if int(cell.level)==0: cells.append([cell.x,cell.z,cell.kind])
		houses.append([house.origin.duplicate(),cells])
	return [water_rows,road_rows,houses]

func diagnostics() -> Dictionary:
	var totals := {"blocks": blocks.size(), "instances": 0, "reeds": 0, "stones": 0,
		"last_changed": last_changed, "elapsed_ms": elapsed_ms}
	for amounts: Dictionary in counts.values():
		totals.instances += int(amounts.grass) + int(amounts.reed) + int(amounts.stone)
		totals.reeds += int(amounts.reed)
		totals.stones += int(amounts.stone)
	return totals

func set_view_scale(zoom: float) -> void:
	detail = 1.0 - smoothstep(15.0, 42.0, zoom)
	for material: Material in materials.values():
		if material is ShaderMaterial: material.set_shader_parameter("detail", detail)

func _candidates(block: Vector2i, mask: RefCounted) -> Array:
	var result: Array = []
	var origin := Vector2(block) * BLOCK_SIZE
	var bounds := Rect2(origin, Vector2.ONE * BLOCK_SIZE)
	var masks := {block: mask}
	# The analytic river meanders only 0.52 m. Blocks beyond its complete
	# shore band and every authored water footprint have no candidate work.
	if bounds.end.x < -0.721 or bounds.position.x > 6.721:
		var local_water: Array = []
		for water: Dictionary in state.get("waters"):
			_collect(local_water, bounds, "water", water.points, float(water.width) * 0.5 + 0.901)
		if local_water.is_empty(): return result
	for z in range(floori(origin.y / SPACING) - 1, ceili((origin.y + BLOCK_SIZE) / SPACING) + 1):
		for x in range(floori(origin.x / SPACING) - 1, ceili((origin.x + BLOCK_SIZE) / SPACING) + 1):
			var seed_value := _hash(x, z)
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var at := Vector2((float(x) + 0.5) * SPACING, (float(z) + 0.5) * SPACING)
			at += Vector2(rng.randf_range(-0.22, 0.22), rng.randf_range(-0.22, 0.22))
			# Draw every choice before masking: surviving tuples retain identity.
			var chance := rng.randf()
			var kind_choice := rng.randf()
			var yaw := rng.randf() * TAU
			var width := rng.randf_range(0.8, 1.25)
			var height := rng.randf_range(0.75, 1.3)
			var tint_choice := rng.randf()
			if not LAND_RECT.has_point(at) or Vector2i(floori(at.x / BLOCK_SIZE), floori(at.y / BLOCK_SIZE)) != block: continue
			var clearance: float = state.call("water_clearance", at)
			if clearance < 0.106 or clearance > 0.9: continue
			# Broad drifts leave long empty passages. They never trace a uniform
			# row of equal reeds or a continuous decorative border around ponds.
			var cluster := 0.45 + sin(at.y * 0.43 + at.x * 0.22) * 0.30 + sin(at.y * 0.9 - at.x * 0.35) * 0.22
			var edge := minf(minf(at.x - LAND_RECT.position.x, LAND_RECT.end.x - at.x), minf(at.y - LAND_RECT.position.y, LAND_RECT.end.y - at.y))
			if cluster < 0.40 or chance > smoothstep(0.35, 0.8, cluster) * 0.78 * smoothstep(0.0, 3.0, edge): continue
			if not _visible(mask, at): continue
			var part := "stone" if kind_choice < 0.13 and clearance < 0.55 else ("reed" if kind_choice < 0.53 else "grass")
			var scale_value := Vector3(width, height, width)
			var tint := Color("759267").srgb_to_linear().lerp(Color("91a776").srgb_to_linear(), tint_choice)
			var y := 0.005
			if part == "stone":
				scale_value = Vector3(0.17 + width * 0.11, 0.055 + height * 0.025, 0.11 + width * 0.08)
				tint = Color("aaa897").srgb_to_linear().lerp(Color("cac3ab").srgb_to_linear(), tint_choice)
				y = 0.025
				# The stone's full ellipse remains dry, rather than checking only
				# its center. Candidate identity and yaw remain independent of water.
				var clear_stone := true
				for edge_step in range(12):
					var angle := float(edge_step) * TAU / 12.0
					var offset := Vector2(cos(angle) * scale_value.x, sin(angle) * scale_value.z).rotated(-yaw)
					var edge_at := at + offset
					var edge_block := Vector2i(floori(edge_at.x / BLOCK_SIZE), floori(edge_at.y / BLOCK_SIZE))
					if not masks.has(edge_block):
						var edge_mask := GrassMask.new()
						edge_mask.setup(state, edge_block)
						masks[edge_block] = edge_mask
					if float(state.call("water_clearance", edge_at)) <= 0.01 or not _visible(masks[edge_block], edge_at):
						clear_stone = false
						break
				if not clear_stone: continue
			var transform := Transform3D(Basis(Vector3.UP, yaw).scaled(scale_value), Vector3(at.x - origin.x, y, at.y - origin.y))
			result.append({"position": at, "seed": seed_value, "part": part, "transform": transform, "tint": tint})
	return result

func _hash(x: int, z: int) -> int:
	var value := ((x + 8192) * 73856093) ^ ((z + 8192) * 19349663) ^ 842915
	value = ((value ^ (value >> 13)) & 0x7fffffff) * 1274126177
	return (value ^ (value >> 16)) & 0x7fffffff

func _visible(mask: RefCounted, at: Vector2) -> bool:
	if State.WORLD_RECT.has_point(at): return bool(mask.call("visible", at, 0.25))
	# Background extends beyond editable bounds. Use the same geometric
	# predicates, including obstacles whose footprints cross those bounds.
	var origin: Vector2 = mask.get("_origin")
	var local := at - origin
	var bin: RefCounted = mask.get("_bins")[floori(local.y) * 8 + floori(local.x)]
	const CLEARANCE := 0.105
	for footprint: Rect2 in bin.get("footprints"):
		if footprint.grow(CLEARANCE).has_point(at): return false
	for door: Vector2 in bin.get("doors"):
		if at.distance_to(door) <= 0.95 + CLEARANCE: return false
	for capsule: RefCounted in bin.get("capsules"):
		var a: Vector2 = capsule.get("a")
		var b: Vector2 = capsule.get("b")
		var length_squared: float = capsule.get("length_squared")
		var t := 0.0 if length_squared <= 0.000001 else clampf((at - a).dot(b - a) / length_squared, 0.0, 1.0)
		var distance := at.distance_to(a.lerp(b, t))
		var radius: float = capsule.get("radius")
		if capsule.get("water"):
			if distance - radius <= CLEARANCE: return false
		elif distance <= radius + CLEARANCE: return false
	return true

func _local_obstacles(block: Vector2i) -> Array:
	var rect := Rect2(Vector2(block) * BLOCK_SIZE, Vector2.ONE * BLOCK_SIZE)
	var rows: Array = []
	for house: Dictionary in state.get("houses"):
		var origin := Vector2(float(house.origin[0]), float(house.origin[1]))
		for cell: Dictionary in house.cells:
			if int(cell.level) != 0: continue
			var at := origin + Vector2(float(cell.x), float(cell.z)) * State.CELL_UNIT
			# Stones add at most .308 m beyond their center. Dirty dependencies
			# include their full ellipse as well as the .105 m removal margin.
			var footprint := Rect2(at - Vector2.ONE * 0.9, Vector2.ONE * 1.8).grow(0.416)
			var doorway := Rect2(at + Vector2(0, 1.55) - Vector2.ONE * 1.366, Vector2.ONE * 2.732)
			if not rect.intersects(footprint, true) and not rect.intersects(doorway, true): continue
			rows.append(["house", at, cell.kind])
			for neighbor: Dictionary in house.cells:
				if int(neighbor.level) == 0 and neighbor.x == cell.x and int(neighbor.z) == int(cell.z) + 1: rows.append(["front", at, neighbor.kind])
	for road: Dictionary in state.get("roads"):
		_collect(rows, rect, "road", road.points, float(road.width) * 0.5 + 0.866)
	for water: Dictionary in state.get("waters"):
		_collect(rows, rect, "water", water.points, float(water.width) * 0.5 + 0.901)
	return rows

func _collect(rows: Array, rect: Rect2, kind: String, points: Array, radius: float) -> void:
	for index in range(maxi(1, points.size() - 1)):
		var a := Vector2(float(points[index][0]), float(points[index][1]))
		var next := mini(index + 1, points.size() - 1)
		var b := Vector2(float(points[next][0]), float(points[next][1]))
		var swept := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(a.x - b.x), absf(a.y - b.y))).grow(radius)
		if rect.intersects(swept, true): rows.append([kind, a, b, radius])

func _make_batch(root: Node3D, part: String, records: Array) -> void:
	if records.is_empty(): return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = _mesh(part)
	multi.instance_count = records.size()
	multi.custom_aabb = AABB(Vector3(-0.5, -0.1, -0.5), Vector3(9.0, 1.5, 9.0))
	for index in range(records.size()):
		multi.set_instance_transform(index, records[index].transform)
		multi.set_instance_color(index, records[index].tint)
	var instance := MultiMeshInstance3D.new()
	instance.name = "Shore_%s" % part
	instance.multimesh = multi
	instance.material_override = _material(part)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)

func _mesh(part: String) -> Mesh:
	if meshes.has(part): return meshes[part]
	var mesh: Mesh
	if part == "stone":
		var stone := SphereMesh.new()
		stone.radius = 1.0
		stone.height = 2.0
		stone.radial_segments = 10
		stone.rings = 4
		mesh = stone
	else:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for blade in range(4 if part == "grass" else 3):
			var angle := float(blade) * 2.39996
			var axis := Vector3(cos(angle), 0, sin(angle))
			var side := Vector3(-sin(angle), 0, cos(angle))
			var base := axis * 0.035
			var height := (0.22 + float(blade % 3) * 0.035) if part == "grass" else (0.36 + float(blade) * 0.065)
			var bend := base + axis * 0.11 + Vector3.UP * height * 0.6
			var tip := base + axis * (0.23 if part == "grass" else 0.13) + Vector3.UP * height
			var width := 0.045 if part == "grass" else 0.018
			_triangle(surface, base - side * width, base + side * width, bend + side * width)
			_triangle(surface, base - side * width, bend + side * width, bend - side * width)
			_triangle(surface, bend - side * width, bend + side * width, tip)
			if part == "reed":
				var leaf := base + Vector3.UP * height * 0.46
				_triangle(surface, leaf, leaf + axis * 0.21 + side * 0.045 + Vector3.UP * 0.11, leaf + axis * 0.32 + Vector3.UP * 0.07)
				_triangle(surface, leaf, leaf + axis * 0.32 + Vector3.UP * 0.07, leaf + axis * 0.21 - side * 0.045 + Vector3.UP * 0.11)
				_triangle(surface, tip - side * 0.023 - Vector3.UP * 0.07, tip + side * 0.023 - Vector3.UP * 0.07, tip + Vector3.UP * 0.065)
		surface.index()
		mesh = surface.commit()
	meshes[part] = mesh
	return mesh

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for at: Vector3 in [a, b, c]:
		surface.set_normal(Vector3.UP)
		surface.set_uv(Vector2(0, clampf(at.y / 0.7, 0, 1)))
		surface.add_vertex(at)

func _material(part: String) -> Material:
	if materials.has(part): return materials[part]
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
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform float detail = 1.0;
varying vec4 tint;
varying float tip;
void vertex() {
	tint = COLOR;
	tip = UV.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y *= mix(0.55, 1.0, detail);
	float wind = sin(TIME * 0.8 + world.x * 0.3 + world.z * 0.25);
	VERTEX.x += wind * 0.026 * tip * tip;
	VERTEX.z += wind * 0.013 * tip * tip;
}
void fragment() {
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = tint.rgb * mix(vec3(0.93, 0.98, 0.90), vec3(1.05), tip);
	ROUGHNESS = 1.0;
}
"""
		var foliage := ShaderMaterial.new()
		foliage.shader = shader
		foliage.set_shader_parameter("detail", detail)
		material = foliage
	materials[part] = material
	return material
