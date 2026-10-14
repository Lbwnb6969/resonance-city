class_name CityCreationRenderer
extends Node3D
## All geometry is authored here. Picking and building use the same local cells.
const UNIT := 1.8
const FLOOR := 1.7
## The creation slice remains a compact, streamable parcel.  Vegetation is
## cached in these same world units so a paint stroke never touches the full
## scene.
const EDITABLE_WORLD_RECT := Rect2(-18.0, -15.0, 35.0, 30.0)
const VEGETATION_BLOCK_SIZE := 8.0
const PALETTES := [
	[Color("ead9b4"),Color("bb7054"),Color("647a70")],
	[Color("e9dfc8"),Color("66948b"),Color("557466")],
	[Color("d9c4a7"),Color("a85f4f"),Color("66798a")],
	[Color("f0deb8"),Color("bda179"),Color("537b73")]
]
var state: RefCounted
var buildings: Node3D
var landscape: Node3D
var roads_layer: Node3D
var vegetation_layer: Node3D
var preview: Node3D
var materials: Dictionary = {}
var vegetation_blocks: Dictionary = {}
var vegetation_block_fingerprints: Dictionary = {}
var vegetation_id_blocks: Dictionary = {}
var vegetation_fingerprints: Dictionary = {}
var vegetation_data_fingerprints: Dictionary = {}
var vegetation_visibility: Dictionary = {}
var vegetation_obstacle_signature := -1
var tree_meshes: Dictionary = {}
var tree_materials: Dictionary = {}
var vegetation_brush_mesh: ArrayMesh
var vegetation_brush_materials: Dictionary = {}
var water_shader: Shader
var water_material: ShaderMaterial
var shallow_water_material: ShaderMaterial
var house_fingerprints: Dictionary = {}
var house_roots: Dictionary = {}
var road_fingerprints: Dictionary = {}
var road_roots: Dictionary = {}
var rebuild_stats := {"houses_changed":0,"roads_changed":0,"houses_removed":0,"roads_removed":0,"vegetation_blocks_changed":0,"vegetation_instances":0,"elapsed_ms":0.0}

func setup(city_state: RefCounted) -> void:
	state = city_state
	landscape = Node3D.new()
	landscape.name = "RiverGarden"
	add_child(landscape)
	buildings = Node3D.new()
	buildings.name = "EditableHouses"
	add_child(buildings)
	roads_layer = Node3D.new()
	roads_layer.name = "ContinuousStreets"
	add_child(roads_layer)
	vegetation_layer = Node3D.new()
	vegetation_layer.name = "VegetationBlocks"
	add_child(vegetation_layer)
	preview = Node3D.new()
	preview.name = "EditPreview"
	add_child(preview)
	_build_landscape()
	rebuild()

func _clear(node: Node3D) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func rebuild() -> void:
	if state == null or buildings == null: return
	var started := Time.get_ticks_usec()
	rebuild_stats = {"houses_changed":0,"roads_changed":0,"houses_removed":0,"roads_removed":0,"vegetation_blocks_changed":0,"vegetation_instances":0,"elapsed_ms":0.0}
	clear_preview()
	var live_houses: Dictionary = {}
	for house: Dictionary in state.houses:
		var id := str(house["id"])
		live_houses[id] = true
		# Names are UI state. Only geometry and frontage clearance invalidate a mesh.
		var fingerprint := hash([house["origin"],house["cells"],house.get("palette",0),house.get("seed",0),house.get("role","residential"),_frontage_signature(house)])
		if house_fingerprints.get(id,-1) == fingerprint: continue
		_remove_cached(id,house_roots,house_fingerprints)
		var root := _house(house)
		_merge_meshes(root)
		house_roots[id] = root
		house_fingerprints[id] = fingerprint
		rebuild_stats["houses_changed"] += 1
	for id: String in house_roots.keys():
		if live_houses.has(id): continue
		_remove_cached(id,house_roots,house_fingerprints)
		rebuild_stats["houses_removed"] += 1
	var live_roads: Dictionary = {}
	for road: Dictionary in state.roads:
		var id := str(road["id"])
		live_roads[id] = true
		var fingerprint := hash([road["points"],road.get("width",1.1)])
		if road_fingerprints.get(id,-1) == fingerprint: continue
		_remove_cached(id,road_roots,road_fingerprints)
		var root := _road(road)
		_merge_meshes(root)
		road_roots[id] = root
		road_fingerprints[id] = fingerprint
		rebuild_stats["roads_changed"] += 1
	for id: String in road_roots.keys():
		if live_roads.has(id): continue
		_remove_cached(id,road_roots,road_fingerprints)
		rebuild_stats["roads_removed"] += 1
	_rebuild_vegetation()
	rebuild_stats["elapsed_ms"] = float(Time.get_ticks_usec()-started)/1000.0

func _remove_cached(id: String, roots: Dictionary, fingerprints: Dictionary) -> void:
	if not roots.has(id): return
	var root: Node3D = roots[id]
	root.get_parent().remove_child(root)
	root.queue_free()
	roots.erase(id)
	fingerprints.erase(id)


## Vegetation is a record-driven layer.  The record is the source of truth;
## this method only scans the small state array, compares fingerprints, and
## rebuilds blocks whose membership or derived visibility changed.  A house or
## road can therefore hide/show a plant without recreating unrelated trees.
func _rebuild_vegetation() -> void:
	if vegetation_layer == null or state == null:
		return
	var plants: Array = state.get("plants") if state.get("plants") is Array else []
	var obstacles: Array = [state.roads]
	for house: Dictionary in state.houses:
		var ground: Array = []
		for cell: Dictionary in house.cells:
			if int(cell.level) == 0: ground.append([cell.x,cell.z,cell.kind])
		obstacles.append([house.origin,ground])
	var obstacle_signature := hash(obstacles)
	var obstacles_changed := obstacle_signature != vegetation_obstacle_signature
	vegetation_obstacle_signature = obstacle_signature
	var next_by_block: Dictionary = {}
	var next_fingerprints: Dictionary = {}
	var next_data: Dictionary = {}
	var next_visibility: Dictionary = {}
	var next_id_blocks: Dictionary = {}
	var dirty_blocks: Dictionary = {}
	for plant: Dictionary in plants:
		var id := str(plant.get("id", ""))
		if id.is_empty():
			continue
		var position := _plant_position(plant)
		var inside := _editable_world_rect().has_point(position)
		var block := _vegetation_block(position) if inside else Vector2i.ZERO
		var data_fingerprint := hash([plant.position,plant.kind,plant.scale,plant.seed])
		var visible := bool(vegetation_visibility.get(id,false))
		if obstacles_changed or vegetation_data_fingerprints.get(id,-1) != data_fingerprint:
			visible = inside and _vegetation_visible(plant)
		next_data[id] = data_fingerprint
		next_visibility[id] = visible
		var fingerprint := hash([data_fingerprint,visible,block if inside else "outside"])
		next_fingerprints[id] = fingerprint
		if vegetation_fingerprints.get(id, null) != fingerprint:
			if vegetation_id_blocks.has(id):
				dirty_blocks[vegetation_id_blocks[id]] = true
			if inside:
				dirty_blocks[block] = true
		if inside:
			next_id_blocks[id] = block
			if visible:
				if not next_by_block.has(block):
					next_by_block[block] = []
				next_by_block[block].append(plant)
	for old_id: String in vegetation_fingerprints.keys():
		if next_fingerprints.has(old_id):
			continue
		if vegetation_id_blocks.has(old_id):
			dirty_blocks[vegetation_id_blocks[old_id]] = true
	for block: Vector2i in dirty_blocks.keys():
		var members: Array = next_by_block.get(block, [])
		_rebuild_vegetation_block(block, members)
	vegetation_fingerprints = next_fingerprints
	vegetation_data_fingerprints = next_data
	vegetation_visibility = next_visibility
	vegetation_id_blocks = next_id_blocks
	rebuild_stats["vegetation_blocks_changed"] = dirty_blocks.size()
	var total := 0
	for members: Array in next_by_block.values():
		total += members.size()
	rebuild_stats["vegetation_instances"] = total


func _editable_world_rect() -> Rect2:
	# Keep this renderer compatible with older state snapshots that predate the
	# constant while still following the authoritative creation bounds.
	return EDITABLE_WORLD_RECT


func _vegetation_block(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / VEGETATION_BLOCK_SIZE), floori(position.y / VEGETATION_BLOCK_SIZE))


func _plant_position(plant: Dictionary) -> Vector2:
	var encoded: Variant = plant.get("position", [0.0, 0.0])
	if encoded is Array and encoded.size() >= 2:
		return Vector2(float(encoded[0]), float(encoded[1]))
	if encoded is Vector2:
		return encoded
	return Vector2.ZERO


func _vegetation_visible(plant: Dictionary) -> bool:
	if state != null and state.has_method("vegetation_visible"):
		return bool(state.call("vegetation_visible", plant))
	return true


func _rebuild_vegetation_block(block: Vector2i, members: Array) -> void:
	if vegetation_blocks.has(block):
		var old_root: Node3D = vegetation_blocks[block]
		if is_instance_valid(old_root):
			vegetation_layer.remove_child(old_root)
			old_root.queue_free()
		vegetation_blocks.erase(block)
	vegetation_block_fingerprints.erase(block)
	if members.is_empty():
		return
	var root := Node3D.new()
	root.name = "VegetationBlock_%d_%d" % [block.x, block.y]
	root.set_meta("vegetation_block", block)
	vegetation_layer.add_child(root)
	var transforms: Dictionary = {}
	for plant: Dictionary in members:
		var position := _plant_position(plant)
		var kind := str(plant.get("kind", "olive"))
		var scale_value := clampf(float(plant.get("scale", 1.0)), 0.25, 2.5)
		var seed_value := int(plant.get("seed", 0))
		var yaw := fmod(absf(float(seed_value % 6283)) / 1000.0, TAU)
		if kind != "shrub":
			_add_tree_part(transforms, "trunk", Vector3(position.x, 0.72 * scale_value, position.y),
				Vector3.ONE * scale_value, yaw)
		if kind == "cypress":
			_add_tree_part(transforms, "cypress_lower", Vector3(position.x, 2.0 * scale_value, position.y),
				Vector3.ONE * scale_value, yaw)
			_add_tree_part(transforms, "cypress_upper", Vector3(position.x, 2.77 * scale_value, position.y),
				Vector3.ONE * scale_value, yaw)
		elif kind == "shrub":
			# Tiny Glade-like low clumps use the same shared canopy mesh, with no
			# collision body and a single compact draw instance per clump.
			_add_tree_part(transforms, "shrub_crown", Vector3(position.x, 0.49 * scale_value, position.y),
				Vector3(0.78, 0.52, 0.78) * scale_value, yaw)
		else:
			for part in range(4):
				var angle := float(part) * 2.4 + yaw
				_add_tree_part(transforms, "olive_crown_light" if part % 2 == 0 else "olive_crown", Vector3(position.x + sin(angle) * 0.43 * scale_value,
					1.77 * scale_value + float(part) * 0.19 * scale_value,
					position.y + cos(angle) * 0.43 * scale_value),
					Vector3(0.84, 0.64, 0.79) * scale_value, angle)
	var block_fingerprint := hash([block, members])
	vegetation_block_fingerprints[block] = block_fingerprint
	for part: String in transforms.keys():
		_make_tree_multimesh(root, part, transforms[part])
	vegetation_blocks[block] = root


func _add_tree_part(transforms: Dictionary, part: String, at: Vector3, scale_value: Vector3, yaw: float) -> void:
	if not transforms.has(part):
		transforms[part] = []
	var basis := Basis.IDENTITY.scaled(scale_value)
	basis = basis.rotated(Vector3.UP, yaw)
	transforms[part].append(Transform3D(basis, at))


func _make_tree_multimesh(parent: Node3D, part: String, transforms: Array) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = false
	multi.mesh = _shared_tree_mesh(part)
	multi.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Multi_%s" % part
	instance.multimesh = multi
	instance.material_override = _shared_tree_material(part)
	parent.add_child(instance)


func _shared_tree_mesh(part: String) -> Mesh:
	var mesh_key := "crown" if part in ["olive_crown", "olive_crown_light", "shrub_crown"] else part
	if tree_meshes.has(mesh_key):
		return tree_meshes[mesh_key]
	var mesh: Mesh
	match part:
		"trunk":
			var trunk := CylinderMesh.new()
			trunk.bottom_radius = 0.12
			trunk.top_radius = 0.06
			trunk.height = 1.45
			trunk.radial_segments = 8
			mesh = trunk
		"cypress_lower":
			var lower := CylinderMesh.new()
			lower.bottom_radius = 0.62
			lower.top_radius = 0.10
			lower.height = 2.75
			lower.radial_segments = 9
			mesh = lower
		"cypress_upper":
			var upper := CylinderMesh.new()
			upper.bottom_radius = 0.49
			upper.top_radius = 0.02
			upper.height = 1.8
			upper.radial_segments = 9
			mesh = upper
		_:
			var crown := SphereMesh.new()
			crown.radius = 1.0
			crown.height = 2.0
			crown.radial_segments = 10
			crown.rings = 5
			mesh = crown
	tree_meshes[mesh_key] = mesh
	return mesh


func _shared_tree_material(part: String) -> StandardMaterial3D:
	if tree_materials.has(part):
		return tree_materials[part]
	var color := Color("887351")
	match part:
		"olive_crown": color = Color("78936e")
		"olive_crown_light": color = Color("839c77")
		"cypress_lower": color = Color("526f57")
		"cypress_upper": color = Color("638366")
		"shrub_crown": color = Color("78936e")
	var material := _material(color)
	tree_materials[part] = material
	return material

func _frontage_signature(house: Dictionary) -> Array:
	var role := str(house.get("role","residential"))
	if role == "residential": return []
	var cells: Array = house["cells"]
	for cell: Dictionary in cells:
		if int(cell["level"]) != 0 or str(cell["kind"]) != "room": continue
		var next := _at(cells,int(cell["x"]),int(cell["z"])+1,0)
		if not next.is_empty() and str(next["kind"]) == "room": continue
		var at := _cell_position(house,cell)
		var front := Vector2(at.x,at.z+UNIT*0.5)
		var id := str(cell["id"])
		if role == "bakery": return [_clearance_at(front+Vector2(0.82,0.20),id,0.29)]
		return [_clearance_at(front+Vector2(0.90,0.20),id,0.35),_clearance_at(front+Vector2(0.85,0.18),id,0.32),_clearance_at(front+Vector2(-0.76,0.23),id,0.22),_clearance_at(front+Vector2(0.76,0.23),id,0.22)]
	return []

func _merge_meshes(parent: Node3D) -> void:
	# Detailed facade pieces stay cheap: one surface per material, stable bodies.
	var batches: Dictionary = {}
	var inverse := parent.global_transform.affine_inverse()
	for instance: MeshInstance3D in parent.find_children("*","MeshInstance3D",true,false):
		var material: Material = instance.material_override
		var key := material.get_instance_id()
		if not batches.has(key):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[key] = {"surface":surface,"material":material}
		for index in range(instance.mesh.get_surface_count()):
			batches[key]["surface"].append_from(instance.mesh,index,inverse*instance.global_transform)
		instance.get_parent().remove_child(instance)
		instance.queue_free()
	for batch: Dictionary in batches.values():
		var instance := MeshInstance3D.new()
		instance.mesh = batch["surface"].commit()
		instance.material_override = batch["material"]
		parent.add_child(instance)

func clear_preview() -> void:
	if preview != null: _clear(preview)


## A lightweight brush guide only.  It deliberately creates MeshInstance3D
## nodes without StaticBody3D/CollisionShape3D, so painting never alters
## picking or physics while the pointer is moving.
func show_vegetation_brush(at: Vector2, radius: float, erase: bool = false, points: Array[Vector2] = []) -> void:
	clear_preview()
	if preview == null or not is_finite(radius) or radius <= 0.0:
		return
	if vegetation_brush_mesh == null:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in range(48):
			var a := float(segment) * TAU / 48.0
			var b := float(segment + 1) * TAU / 48.0
			var outer_a := Vector3(cos(a), 0.0, sin(a))
			var outer_b := Vector3(cos(b), 0.0, sin(b))
			for vertex: Vector3 in [outer_a, outer_b * 0.965, outer_b, outer_a, outer_a * 0.965, outer_b * 0.965]:
				surface.add_vertex(vertex)
		surface.generate_normals()
		vegetation_brush_mesh = surface.commit()
	if not vegetation_brush_materials.has(erase):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.96, 0.57, 0.42, 0.70) if erase else Color(0.89, 0.93, 0.66, 0.72)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		vegetation_brush_materials[erase] = mat
	var centers: Array[Vector2] = []
	# A spaced trail is readable and bounded during a long drag. All rings are
	# one MultiMesh; pointer motion only uploads transforms of a shared mesh.
	var stride := maxi(1, ceili(float(points.size()) / 64.0))
	for index in range(0, points.size(), stride):
		var point := points[index]
		if point.distance_to(at) < radius * 0.35:
			continue
		if centers.is_empty() or centers[-1].distance_to(point) >= maxf(0.4, radius * 0.55):
			centers.append(point)
	centers.append(at)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = vegetation_brush_mesh
	multi.instance_count = centers.size()
	for index in range(centers.size()):
		var center := centers[index]
		var size_value := radius if index == centers.size() - 1 else minf(radius * 0.22, 0.25)
		multi.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3(size_value, 1.0, size_value)), Vector3(center.x, 0.08, center.y)))
	var instance := MultiMeshInstance3D.new()
	instance.name = "VegetationBrushGuide"
	instance.multimesh = multi
	instance.material_override = vegetation_brush_materials[erase]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	preview.add_child(instance)

func preview_road(points: Array[Vector2]) -> void:
	clear_preview()
	if preview == null: return
	var mat := _material(Color("edd9a4"))
	for point: Vector2 in points:
		_cylinder(preview,0.17,0.17,0.035,Vector3(point.x,0.12,point.y),mat,12)
	for i in range(points.size()-1):
		var a := points[i]
		var b := points[i+1]
		if a.distance_to(b) < 0.01: continue
		var normal := (b-a).normalized().orthogonal()*0.5
		_quad(preview,Vector3(a.x-normal.x,0.10,a.y-normal.y),Vector3(b.x-normal.x,0.10,b.y-normal.y),Vector3(b.x+normal.x,0.10,b.y+normal.y),Vector3(a.x+normal.x,0.10,a.y+normal.y),Color("e6d6ad"))

func set_preview(house_id: String, cell: Dictionary, valid: bool) -> void:
	clear_preview()
	if state == null or preview == null: return
	var house := _house_record(house_id)
	if house_id.is_empty() and cell.has("origin"): house = {"origin":cell["origin"]}
	if house.is_empty(): return
	var color := Color(0.63,0.89,0.72,0.40) if valid else Color(0.95,0.39,0.31,0.45)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = false
	var level := int(cell.get("level",0))
	var height := 0.16 if str(cell.get("kind","room")) == "terrace" else FLOOR
	var pos := _cell_position(house,cell)+Vector3(0,level*FLOOR+height*0.5+0.04,0)
	_box(preview,Vector3(UNIT+0.04,height+0.03,UNIT+0.04),pos,material)
	# A clear outline remains readable against both stone and foliage.
	var edge := _material(Color("f3e7ae") if valid else Color("ef7862"))
	for x in [-1,1]:
		_box(preview,Vector3(0.025,0.035,UNIT+0.1),pos+Vector3(x*(UNIT*0.5+0.03),height*0.5,0),edge)
	for z in [-1,1]:
		_box(preview,Vector3(UNIT+0.1,0.035,0.025),pos+Vector3(0,height*0.5,z*(UNIT*0.5+0.03)),edge)

func _house_record(id: String) -> Dictionary:
	for house: Dictionary in state.houses:
		if str(house["id"]) == id: return house
	return {}

func _material(color: Color, roughness: float = 0.88) -> StandardMaterial3D:
	var key := color.to_html()+str(roughness)
	if materials.has(key): return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	materials[key] = mat
	return mat


func _water_surface_material(shallow: bool) -> ShaderMaterial:
	if shallow and shallow_water_material != null:
		return shallow_water_material
	if not shallow and water_material != null:
		return water_material
	# One shared, low-frequency shader gives the river a quiet living surface.
	# Meshes stay static; TIME is the only animation input and is independent of
	# the audio system.  world_pos avoids requiring generated UVs on hand-built
	# SurfaceTool quads.
	if water_shader == null:
		water_shader = Shader.new()
		water_shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
varying vec3 world_pos;
uniform bool shoreline = false;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float ripple = sin(world_pos.z * 1.25 + TIME * 0.20) * 0.5
		+ sin(world_pos.x * 2.10 - TIME * 0.13) * 0.5;
	float band = smoothstep(-0.8, 0.8, ripple);
	vec3 deep = vec3(0.22, 0.48, 0.47);
	vec3 light = vec3(0.42, 0.65, 0.61);
	vec3 shore = vec3(0.59, 0.72, 0.66);
	ALBEDO = shoreline ? mix(shore, light, band) : mix(deep, light, band * 0.55);
	ROUGHNESS = 0.62;
	METALLIC = 0.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = water_shader
	material.set_shader_parameter("shoreline", shallow)
	if shallow:
		shallow_water_material = material
	else:
		water_material = material
	return material

func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node

func _cylinder(parent: Node3D, bottom: float, top: float, height: float, at: Vector3, material: Material, sides: int = 8) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node

func _crown(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = at
	node.scale = size
	parent.add_child(node)
	return node

func _triangles(parent: Node3D, vertices: Array[Vector3], color: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Geometry below is authored with outward cross products. Godot uses
	# clockwise front faces; reverse the winding before deriving normals.
	for index in range(0,vertices.size(),3):
		surface.add_vertex(vertices[index])
		surface.add_vertex(vertices[index+2])
		surface.add_vertex(vertices[index+1])
	surface.generate_normals()
	# append_from cannot mix indexed primitives with unindexed triangle lists:
	# later indices would omit the earlier road/roof faces. Index every source.
	surface.index()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	var mat := _material(color)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	parent.add_child(node)
	return node

func _quad(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> MeshInstance3D:
	return _triangles(parent,[a,b,c,a,c,d],color)

func _cell_position(house: Dictionary, cell: Dictionary) -> Vector3:
	var origin: Array = house["origin"]
	return Vector3(float(origin[0])+int(cell["x"])*UNIT,0,float(origin[1])+int(cell["z"])*UNIT)

func _at(cells: Array, x: int, z: int, level: int) -> Dictionary:
	for cell: Dictionary in cells:
		if int(cell["x"]) == x and int(cell["z"]) == z and int(cell["level"]) == level: return cell
	return {}

func _house(house: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(house["id"])
	buildings.add_child(root)
	var palette: Array = PALETTES[posmod(int(house.get("palette",0)),PALETTES.size())]
	var walls := _material(palette[0])
	var trim := _material(Color("f1e5cc"))
	var cells: Array = house["cells"]
	var role_prop_added := false
	for cell: Dictionary in cells:
		var p := _cell_position(house,cell)
		var level := int(cell["level"])
		var y := level*FLOOR
		var x := int(cell["x"])
		var z := int(cell["z"])
		var terrace := str(cell["kind"]) == "terrace"
		var node := Node3D.new()
		node.name = str(cell["id"])
		node.position = p
		root.add_child(node)
		var body := StaticBody3D.new()
		body.set_meta("house_id",str(house["id"]))
		body.set_meta("cell_id",str(cell["id"]))
		body.set_meta("cell",cell.duplicate(true))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(UNIT,0.18 if terrace else FLOOR,UNIT)
		shape.shape = box
		shape.position.y = y+box.size.y*0.5
		body.add_child(shape)
		node.add_child(body)
		_box(node,Vector3(UNIT,0.15,UNIT),Vector3(0,y+0.075,0),_material(Color("c7b995")))
		if terrace:
			_terrace(node,cell,cells,y,palette)
			continue
		for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor := _at(cells,x+direction.x,z+direction.y,level)
			if not neighbor.is_empty() and str(neighbor["kind"]) == "room": continue
			var wall := Node3D.new()
			wall.position = Vector3(direction.x*UNIT*0.5,y,direction.y*UNIT*0.5)
			wall.rotation.y = atan2(float(direction.x),float(direction.y))
			node.add_child(wall)
			_box(wall,Vector3(UNIT,FLOOR,0.13),Vector3(0,FLOOR*0.5,0),walls)
			_box(wall,Vector3(UNIT+0.04,0.12,0.20),Vector3(0,0.12,0.02),_material(Color("c7b797")))
			_box(wall,Vector3(UNIT+0.07,0.11,0.20),Vector3(0,FLOOR-0.06,0.02),trim)
			var door := level == 0 and direction == Vector2i.DOWN
			_facade(wall,palette,door,int(house.get("seed",0))+x*17+z*31+level*7)
			if door and not role_prop_added:
				_role_frontage(wall,str(house.get("role","residential")))
				role_prop_added = true
		if not _at(cells,x,z,level+1).is_empty():
			_box(node,Vector3(UNIT+0.06,0.1,UNIT+0.06),Vector3(0,y+FLOOR,0),trim)
			continue
		# One gable across each exposed room run: no interior eaves or roof valley.
		var left := _at(cells,x-1,z,level)
		if not left.is_empty() and str(left["kind"]) == "room" and _at(cells,x-1,z,level+1).is_empty(): continue
		var span := 1
		while true:
			var next := _at(cells,x+span,z,level)
			if next.is_empty() or str(next["kind"]) != "room" or not _at(cells,x+span,z,level+1).is_empty(): break
			span += 1
		var roof := Node3D.new()
		roof.position.x = float(span-1)*UNIT*0.5
		node.add_child(roof)
		var front_open := false
		var back_open := false
		for column in range(span):
			var front := _at(cells,x+column,z-1,level)
			var back := _at(cells,x+column,z+1,level)
			front_open = front_open or front.is_empty() or str(front.get("kind","")) != "room" or not _at(cells,x+column,z-1,level+1).is_empty()
			back_open = back_open or back.is_empty() or str(back.get("kind","")) != "room" or not _at(cells,x+column,z+1,level+1).is_empty()
		_roof(roof,y+FLOOR,palette[1],int(house.get("seed",0))+x*13+z*19,span,front_open,back_open)
	return root

func _prop_clear(parent: Node3D, local: Vector3, radius: float) -> bool:
	var at := parent.to_global(local)
	var p := Vector2(at.x,at.z)
	var own_cell := str(parent.get_parent().name)
	return _clearance_at(p,own_cell,radius)

func _clearance_at(p: Vector2, own_cell: String, radius: float) -> bool:
	for house: Dictionary in state.houses:
		for cell: Dictionary in house["cells"]:
			if str(cell["id"]) == own_cell or int(cell["level"]) != 0: continue
			var center := _cell_position(house,cell)
			var delta := Vector2(maxf(0,absf(p.x-center.x)-UNIT*0.5),maxf(0,absf(p.y-center.z)-UNIT*0.5))
			if delta.length() < radius: return false
	for road: Dictionary in state.roads:
		var points: Array = road["points"]
		for i in range(points.size()-1):
			var a := Vector2(float(points[i][0]),float(points[i][1]))
			var b := Vector2(float(points[i+1][0]),float(points[i+1][1]))
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)) < float(road.get("width",1.1))*0.5+radius: return false
	return true

func _role_frontage(wall: Node3D, role: String) -> void:
	if role == "residential": return
	var wood := _material(Color("8e7052"))
	var cream := Color("efe2be")
	if role == "bakery":
		# Suspended canvas stays above the pedestrian path; no poles in the street.
		for stripe in range(8):
			var x0 := -0.78+stripe*0.195
			var color := Color("bc7758") if stripe%2 == 0 else cream
			_quad(wall,Vector3(x0,1.43,0.12),Vector3(x0+0.195,1.43,0.12),Vector3(x0+0.195,1.25,0.69),Vector3(x0,1.25,0.69),color)
			_box(wall,Vector3(0.195,0.12,0.045),Vector3(x0+0.0975,1.2,0.68),_material(color))
		var counter := Vector3(0.82,0.0,0.20)
		if _prop_clear(wall,counter,0.29):
			_box(wall,Vector3(0.52,0.08,0.38),counter+Vector3(0,0.57,0),wood)
			for x in [-0.20,0.20]: _box(wall,Vector3(0.045,0.55,0.27),counter+Vector3(x,0.28,0),wood)
			for bread in range(3):
				_crown(wall,counter+Vector3(-0.16+bread*0.16,0.65,0),Vector3(0.07,0.045,0.15),Color("d6a35d"))
		# Bread emblem makes the service readable even when its counter is omitted.
		_box(wall,Vector3(0.45,0.38,0.055),Vector3(0.59,0.93,0.10),wood)
		_crown(wall,Vector3(0.59,0.94,0.15),Vector3(0.17,0.065,0.07),Color("d9af72"))
	else:
		var stage := Vector3(0.90,0,0.20)
		if _prop_clear(wall,stage,0.35):
			_box(wall,Vector3(0.62,0.16,0.40),stage+Vector3(0,0.08,0),wood)
			for plank in range(4): _box(wall,Vector3(0.012,0.008,0.40),stage+Vector3(-0.24+plank*0.16,0.165,0),_material(Color("b3966e")))
		var piano := Vector3(0.85,0,0.18)
		if _prop_clear(wall,piano,0.32):
			_box(wall,Vector3(0.50,0.48,0.23),piano+Vector3(0,0.39,0),_material(Color("586e65")))
			_box(wall,Vector3(0.53,0.04,0.34),piano+Vector3(0,0.45,0.03),_material(cream))
			for key in range(6): _box(wall,Vector3(0.025,0.018,0.10),piano+Vector3(-0.20+key*0.07,0.48,-0.06),_material(Color("3e534d")))
			for x in [-0.18,0.18]: _box(wall,Vector3(0.04,0.26,0.04),piano+Vector3(x,0.13,0.03),wood)
		# A painted musical flag is attached to the facade and cannot block a road.
		_box(wall,Vector3(0.46,0.48,0.055),Vector3(0.60,1.10,0.10),_material(Color("73968a")))
		_box(wall,Vector3(0.026,0.24,0.026),Vector3(0.63,1.12,0.15),_material(cream))
		_crown(wall,Vector3(0.58,1.0,0.15),Vector3(0.075,0.045,0.026),cream)
		_box(wall,Vector3(0.10,0.027,0.026),Vector3(0.66,1.24,0.15),_material(cream))
		for x in [-0.76,0.76]:
			var pot := Vector3(x,0.0,0.23)
			if not _prop_clear(wall,pot,0.22): continue
			_cylinder(wall,0.16,0.21,0.26,pot+Vector3(0,0.13,0),_material(Color("b98464")))
			_cylinder(wall,0.035,0.025,0.43,pot+Vector3(0,0.43,0),wood)
			_crown(wall,pot+Vector3(0,0.69,0),Vector3(0.25,0.29,0.24),Color("779375"))

func _facade(wall: Node3D, palette: Array, door: bool, seed_value: int) -> void:
	var dark := _material(Color("425b59"))
	var wood := _material(palette[2])
	var trim := _material(Color("f6ead0"))
	if door:
		_box(wall,Vector3(0.61,1.13,0.10),Vector3(0,0.675,0.105),trim)
		_box(wall,Vector3(0.46,1.02,0.075),Vector3(0,0.63,0.167),wood)
		_box(wall,Vector3(0.34,0.13,0.04),Vector3(0,1.24,0.20),dark)
		for x in [-0.11,0.0,0.11]: _box(wall,Vector3(0.018,0.8,0.018),Vector3(x,0.62,0.21),_material(Color("7d8870")))
		_cylinder(wall,0.025,0.025,0.035,Vector3(0.16,0.61,0.22),_material(Color("d6bb74")))
		_box(wall,Vector3(0.96,0.10,0.54),Vector3(0,0.055,0.3),_material(Color("d7c8a5")))
		_box(wall,Vector3(1.04,0.045,0.68),Vector3(0,0.022,0.55),_material(Color("bdb797")))
	else:
		for x in [-0.46,0.46]:
			_box(wall,Vector3(0.47,0.70,0.075),Vector3(x,1.00,0.092),trim)
			_box(wall,Vector3(0.35,0.56,0.04),Vector3(x,1.00,0.14),dark)
			_box(wall,Vector3(0.028,0.57,0.026),Vector3(x,1.00,0.17),trim)
			_box(wall,Vector3(0.36,0.024,0.026),Vector3(x,1.00,0.17),trim)
			for side in [-1,1]:
				_box(wall,Vector3(0.14,0.58,0.04),Vector3(x+side*0.25,1.0,0.145),wood)
				for slat in range(5): _box(wall,Vector3(0.13,0.018,0.013),Vector3(x+side*0.25,0.79+slat*0.105,0.174),_material(palette[2].lightened(0.13)))
			_box(wall,Vector3(0.53,0.08,0.21),Vector3(x,0.64,0.18),_material(Color("d5c5a4")))
			if posmod(seed_value,3) == 0:
				_box(wall,Vector3(0.43,0.13,0.13),Vector3(x,0.65,0.25),_material(Color("ae7256")))
				_cylinder(wall,0.20,0.16,0.12,Vector3(x,0.75,0.25),_material(Color("78936a")))

func _roof(node: Node3D, y: float, roof_color: Color, seed_value: int, span: int = 1, front_open: bool = true, back_open: bool = true) -> void:
	var half := UNIT*span*0.5+0.12
	var half_z := UNIT*0.5+0.12
	var eave := y+0.03
	var ridge := y+0.49+float(span-1)*0.13
	var a := Vector3(-half,eave,-half_z)
	var b := Vector3(half,eave,-half_z)
	var c := Vector3(half,eave,half_z)
	var d := Vector3(-half,eave,half_z)
	var r0 := Vector3(0,ridge,-half_z)
	var r1 := Vector3(0,ridge,half_z)
	_quad(node,a,d,r1,r0,roof_color.darkened(0.04))
	_quad(node,r0,r1,c,b,roof_color.lightened(0.09))
	if front_open: _triangles(node,[a,r0,b],Color("e9d9b7"))
	if back_open: _triangles(node,[d,c,r1],Color("e9d9b7"))
	var edge := _material(roof_color.darkened(0.20))
	for x in [-half,half]: _box(node,Vector3(0.09,0.08,half_z*2.03),Vector3(x,eave-0.035,0),edge)
	_box(node,Vector3(0.13,0.08,half_z*2.06),Vector3(0,ridge+0.015,0),_material(roof_color.lightened(0.17)))
	# Light raised tile courses give the roof a readable miniature scale.
	for side in [-1,1]:
		for course in range(1,5):
			var t := float(course)/5.0
			var strip := _box(node,Vector3(0.024,0.024,half_z*2.01),Vector3(side*half*t,ridge+(eave-ridge)*t+0.012,0),_material(roof_color.lightened(0.10)))
			strip.rotation.z = side*atan2(ridge-eave,half)
	if posmod(seed_value,4) == 0:
		_box(node,Vector3(0.24,0.57,0.26),Vector3(0.4,y+0.57,-0.45),_material(Color("e0cbaa")))
		_box(node,Vector3(0.31,0.09,0.33),Vector3(0.4,y+0.89,-0.45),_material(Color("b67d61")))
		_box(node,Vector3(0.18,0.025,0.18),Vector3(0.4,y+0.942,-0.45),_material(Color("4f5951")))

func _terrace(node: Node3D, cell: Dictionary, cells: Array, y: float, palette: Array) -> void:
	var top := y+0.19
	_box(node,Vector3(UNIT,0.11,UNIT),Vector3(0,top-0.05,0),_material(Color("ded1b0")))
	for line in range(-2,3): _box(node,Vector3(UNIT,0.006,0.018),Vector3(0,top+0.01,line*0.33),_material(Color("c4b99b")))
	for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if not _at(cells,int(cell["x"])+direction.x,int(cell["z"])+direction.y,int(cell["level"])).is_empty(): continue
		var rail := Node3D.new()
		rail.position = Vector3(direction.x*(UNIT*0.5-0.06),top,direction.y*(UNIT*0.5-0.06))
		rail.rotation.y = atan2(float(direction.x),float(direction.y))
		node.add_child(rail)
		_box(rail,Vector3(UNIT,0.09,0.10),Vector3(0,0.53,0),_material(palette[0]))
		for post in range(7): _box(rail,Vector3(0.065,0.49,0.065),Vector3(-0.81+post*0.27,0.25,0),_material(palette[0].darkened(0.06)))
	if int(cell["level"]) > 0:
		for x in [-0.72,0.72]:
			for z in [-0.72,0.72]: _box(node,Vector3(0.17,y,0.17),Vector3(x,y*0.5,z),_material(palette[0].darkened(0.08)))
	_cylinder(node,0.19,0.23,0.27,Vector3(0.49,top+0.135,0.49),_material(Color("bd8160")))
	_cylinder(node,0.28,0.12,0.47,Vector3(0.49,top+0.48,0.49),_material(Color("779374")))

func _river_x(z: float) -> float: return 3.0+sin(z*0.17)*0.52

func _street_height(p: Vector2) -> float:
	var bank_distance := absf(p.x-_river_x(p.y))
	return 0.055+0.185*(1.0-smoothstep(2.25,2.95,bank_distance))

func _build_landscape() -> void:
	_box(landscape,Vector3(60,0.7,56),Vector3(0,-0.37,0),_material(Color("86a381")))
	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundPick"
	ground_body.set_meta("ground",true)
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(60,0.1,56)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.08
	ground_body.add_child(ground_shape)
	landscape.add_child(ground_body)
	var rng := RandomNumberGenerator.new()
	rng.seed = 261014
	for i in range(75):
		var x := rng.randf_range(-27,27)
		var z := rng.randf_range(-25,25)
		if absf(x-_river_x(z)) < 2.6: continue
		var radius := rng.randf_range(1.0,3.4)
		var vertices: Array[Vector3] = []
		var contour: Array[Vector3] = []
		for corner in range(10):
			var angle := float(corner)*TAU/10.0
			var uneven := rng.randf_range(0.78,1.20)*radius
			contour.append(Vector3(x+cos(angle)*uneven,-0.004,z+sin(angle)*uneven*0.78))
		for corner in range(10): vertices.append_array([Vector3(x,-0.004,z),contour[(corner+1)%10],contour[corner]])
		_triangles(landscape,vertices,Color("88a482") if i%2 == 0 else Color("84a180"))
	for i in range(56):
		var z0 := -28.0+i
		var z1 := z0+1.0
		var x0 := _river_x(z0)
		var x1 := _river_x(z1)
		_quad(landscape,Vector3(x0-2.3,0.002,z0),Vector3(x1-2.3,0.002,z1),Vector3(x1+2.3,0.002,z1),Vector3(x0+2.3,0.002,z0),Color("bdbd9c"))
		var water := _quad(landscape,Vector3(x0-1.94,0.017,z0),Vector3(x1-1.94,0.017,z1),Vector3(x1+1.94,0.017,z1),Vector3(x0+1.94,0.017,z0),Color("659f9a"))
		water.material_override = _water_surface_material(false)
		for side in [-1,1]:
			var shallow := _quad(landscape,Vector3(x0+side*1.90,0.022,z0),Vector3(x1+side*1.90,0.022,z1),Vector3(x1+side*1.75,0.022,z1),Vector3(x0+side*1.75,0.022,z0),Color("a0bab0"))
			shallow.material_override = _water_surface_material(true)
	for i in range(34):
		var z := rng.randf_range(-26,26)
		var x := _river_x(z)+rng.randf_range(-1.55,1.55)
		_box(landscape,Vector3(rng.randf_range(0.15,0.65),0.006,0.025),Vector3(x,0.029,z),_material(Color("a3c9ba")))
	var groves := [Vector2(-14,-9),Vector2(-16,7),Vector2(13,-9),Vector2(14,8),Vector2(-7,14),Vector2(8,17),Vector2(-19,-18),Vector2(18,-19)]
	for grove: Vector2 in groves:
		for i in range(7):
			var p := grove+Vector2(rng.randf_range(-3.0,3.0),rng.randf_range(-2.7,2.7))
			var scale_value := rng.randf_range(0.75,1.3)
			# Editable groves are represented by state plants and rendered through
			# the block cache.  Trees outside the creation parcel remain authored
			# background scenery and intentionally have no state record.
			if _editable_world_rect().has_point(p):
				continue
			_tree(p,scale_value,i%3 == 0)
	for i in range(28):
		var z := rng.randf_range(-25,25)
		var side := -1.0 if i%2 == 0 else 1.0
		var p := Vector2(_river_x(z)+side*rng.randf_range(2.15,2.9),z)
		var stone := _cylinder(landscape,0.25,0.10,0.25,Vector3(p.x,0.08,p.y),_material(Color("c2bca6")),5)
		stone.rotation.y = rng.randf()*TAU
		stone.scale = Vector3(rng.randf_range(0.8,1.5),rng.randf_range(0.6,1.0),rng.randf_range(0.7,1.5))
	_merge_meshes(landscape)

func _near_house(p: Vector2, radius: float) -> bool:
	for house: Dictionary in state.houses:
		for cell: Dictionary in house["cells"]:
			var at := _cell_position(house,cell)
			if p.distance_to(Vector2(at.x,at.z)) < radius: return true
	return false

func _tree(p: Vector2, scale_value: float, cypress: bool) -> void:
	var root := Node3D.new()
	root.position = Vector3(p.x,0,p.y)
	root.scale = Vector3.ONE*scale_value
	landscape.add_child(root)
	_cylinder(root,0.12,0.06,1.45,Vector3(0,0.72,0),_material(Color("887351")))
	if cypress:
		_cylinder(root,0.62,0.10,2.75,Vector3(0,2.0,0),_material(Color("526f57")),9)
		_cylinder(root,0.49,0.02,1.8,Vector3(0,2.77,0),_material(Color("638366")),9)
	else:
		for part in range(4):
			var angle := part*2.4
			var canopy := _crown(root,Vector3(sin(angle)*0.43,1.77+part*0.19,cos(angle)*0.43),Vector3(0.84,0.64,0.79),Color("78936e") if part%2 else Color("839c77"))
			canopy.rotation.y = angle

func _road(road: Dictionary) -> Node3D:
	var points: Array = road["points"]
	var width := float(road.get("width",1.1))
	var root := Node3D.new()
	root.name = str(road.get("id","street"))
	roads_layer.add_child(root)
	for i in range(points.size()-1):
		var a := Vector2(float(points[i][0]),float(points[i][1]))
		var b := Vector2(float(points[i+1][0]),float(points[i+1][1]))
		var length := a.distance_to(b)
		if length < 0.01: continue
		var steps := maxi(1,ceili(length/0.42))
		for step in range(steps):
			var p := a.lerp(b,float(step)/steps)
			var q := a.lerp(b,float(step+1)/steps)
			var normal := (q-p).normalized().orthogonal()*width*0.5
			var over_water := absf((p.x+q.x)*0.5-_river_x((p.y+q.y)*0.5)) < 2.28
			var y0 := _street_height(p)
			var y1 := _street_height(q)
			var y := (y0+y1)*0.5
			var color := Color("bca98a") if over_water else (Color("d3c5a5") if step%4 else Color("cbbd9e"))
			_quad(root,Vector3(p.x-normal.x,y0,p.y-normal.y),Vector3(q.x-normal.x,y1,q.y-normal.y),Vector3(q.x+normal.x,y1,q.y+normal.y),Vector3(p.x+normal.x,y0,p.y+normal.y),color)
			if over_water:
				for side in [-1,1]:
					var center: Vector2 = (p+q)*0.5+normal*side
					var rail := _box(root,Vector3(0.055,0.065,p.distance_to(q)+0.025),Vector3(center.x,y+0.48,center.y),_material(Color("d5ccb0")))
					rail.rotation.y = atan2(q.x-p.x,q.y-p.y)
					if step%2 == 0: _box(root,Vector3(0.08,0.52,0.08),Vector3(center.x,y+0.25,center.y),_material(Color("c8ba99")))
				var plank := _box(root,Vector3(width+0.06,0.08,p.distance_to(q)*0.92),Vector3((p.x+q.x)*0.5,y-0.025,(p.y+q.y)*0.5),_material(Color("b5a17e")))
				plank.rotation.y = atan2(q.x-p.x,q.y-p.y)
			else:
				for side in [-1,1]:
					var center: Vector2 = (p+q)*0.5+normal*side
					var curb := _box(root,Vector3(0.085,0.055,p.distance_to(q)+0.018),Vector3(center.x,y+0.01,center.y),_material(Color("c1b598")))
					curb.rotation.y = atan2(q.x-p.x,q.y-p.y)
					curb.rotation.x = -atan2(y1-y0,p.distance_to(q))
		for point: Variant in [points[i],points[i+1]]:
			var p := Vector2(float(point[0]),float(point[1]))
			if absf(p.x-_river_x(p.y)) > 2.28: _cylinder(root,width*0.5,width*0.5,0.02,Vector3(p.x,_street_height(p),p.y),_material(Color("d3c5a5")),16)
	return root
