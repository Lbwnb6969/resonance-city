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
const Foliage = preload("res://scripts/visual/city_creation_foliage.gd")
const Meadow = preload("res://scripts/visual/city_creation_meadow.gd")
const GroundShader = preload("res://scripts/visual/shaders/creation_ground.gdshader")
const ContactShader = preload("res://scripts/visual/shaders/creation_contact.gdshader")
const RoadShader = preload("res://scripts/visual/shaders/creation_road.gdshader")
const PALETTES := [
	[Color("ead9b4"),Color("bb7054"),Color("647a70")],
	[Color("e9dfc8"),Color("66948b"),Color("557466")],
	[Color("d9c4a7"),Color("a85f4f"),Color("66798a")],
	[Color("f0deb8"),Color("bda179"),Color("537b73")]
]
var state: RefCounted
var foliage := Foliage.new()
var meadow: Node3D
var ground_material: ShaderMaterial
var contact_material: ShaderMaterial
var road_material: ShaderMaterial
var road_join_signatures: Dictionary = {}
var road_layout_signature := -1
var concert_layer: Node3D
var concert_fingerprint := ""
var concert_pulse_material: ShaderMaterial
var house_music_layer: Node3D
var house_music_source := ""
var house_music_fingerprint := ""
var house_music_material: ShaderMaterial
var road_outlines: Dictionary = {}
var buildings: Node3D
var landscape: Node3D
var water_layer: Node3D
var water_fingerprint := -1
var water_edit_stats := {"changed":false,"elapsed_ms":0.0,"contours":0,"triangles":0,"strokes":0}
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
var road_water_signatures: Dictionary = {}
var rebuild_stats := {"houses_changed":0,"roads_changed":0,"houses_removed":0,"roads_removed":0,"vegetation_blocks_changed":0,"vegetation_instances":0,"elapsed_ms":0.0}

func setup(city_state: RefCounted) -> void:
	state = city_state
	landscape = Node3D.new()
	landscape.name = "RiverGarden"
	add_child(landscape)
	water_layer = Node3D.new()
	water_layer.name = "EditableWater"
	add_child(water_layer)
	buildings = Node3D.new()
	buildings.name = "EditableHouses"
	add_child(buildings)
	roads_layer = Node3D.new()
	roads_layer.name = "ContinuousStreets"
	add_child(roads_layer)
	vegetation_layer = Node3D.new()
	vegetation_layer.name = "VegetationBlocks"
	add_child(vegetation_layer)
	meadow = Meadow.new()
	meadow.name = "NaturalMeadow"
	add_child(meadow)
	meadow.setup(state)
	preview = Node3D.new()
	preview.name = "EditPreview"
	add_child(preview)
	concert_layer = Node3D.new()
	concert_layer.name = "StreetConcert"
	add_child(concert_layer)
	house_music_layer = Node3D.new()
	house_music_layer.name = "HouseMusicalResponse"
	add_child(house_music_layer)
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
	_rebuild_water()
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
	var road_layout: Array = []
	for road: Dictionary in state.roads: road_layout.append([road.id,road.points,road.width])
	var layout_signature := hash(road_layout)
	if layout_signature != road_layout_signature:
		road_layout_signature = layout_signature
		road_join_signatures.clear()
		road_outlines.clear()
		for road: Dictionary in state.roads: road_outlines[road.id] = _stroke_contours(_road_samples(road.points),float(road.width)*0.5)
	for road: Dictionary in state.roads:
		var id := str(road["id"])
		live_roads[id] = true
		var fingerprint := hash([road["points"],road.get("width",1.1),_road_water_signature(road),_road_join_signature(road)])
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
		road_water_signatures.erase(id)
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
	var obstacles: Array = [state.roads, _water_records()]
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
	var meadow_candidates: Array[Vector2i] = []
	for block: Vector2i in dirty_blocks: meadow_candidates.append(block)
	# The short lawn covers the entire editable parcel, including clear land
	# without planted trees. Obstacle changes recheck local masks, not every
	# grass batch; each block's signature decides whether it needs replacement.
	for x in range(floori(EDITABLE_WORLD_RECT.position.x/8.0),ceili(EDITABLE_WORLD_RECT.end.x/8.0)):
		for z in range(floori(EDITABLE_WORLD_RECT.position.y/8.0),ceili(EDITABLE_WORLD_RECT.end.y/8.0)):
			var block := Vector2i(x,z)
			if not next_by_block.has(block): next_by_block[block] = []
			if (obstacles_changed or not meadow.fingerprints.has(block)) and not meadow_candidates.has(block): meadow_candidates.append(block)
	if obstacles_changed:
		for block: Vector2i in next_by_block:
			if not meadow_candidates.has(block): meadow_candidates.append(block)
		for block: Vector2i in meadow.blocks:
			if not meadow_candidates.has(block): meadow_candidates.append(block)
	meadow.rebuild(next_by_block,meadow_candidates)
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
		var variant := posmod(seed_value,3)
		for piece: String in foliage.parts(kind,variant):
			var part_key := "%s:%d:%s" % [kind,variant,piece]
			tree_meshes[part_key] = foliage.parts(kind,variant)[piece]
			_add_tree_part(transforms,part_key,Vector3(position.x,0,position.y),Vector3.ONE*scale_value,yaw)

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
	multi.custom_aabb = multi.get_aabb().grow(0.12)
	var instance := MultiMeshInstance3D.new()
	instance.name = "Multi_%s" % part
	instance.multimesh = multi
	instance.material_override = _shared_tree_material(part)
	parent.add_child(instance)


func _shared_tree_mesh(part: String) -> Mesh:
	return tree_meshes[part]

func _shared_tree_material(part: String) -> Material:
	return foliage.material("trunk" if part.ends_with(":trunk") else "canopy")

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

func show_concert(status: Dictionary) -> void:
	var phase := str(status.get("phase","idle"))
	var house := _house_record(str(status.get("venue_id","")))
	var fingerprint := str([phase,house.get("origin",[]),house.get("cells",[]),house.get("role","")])
	if fingerprint == concert_fingerprint: return
	concert_fingerprint = fingerprint
	_clear(concert_layer)
	if phase == "idle" or house.is_empty(): return
	var stage: Vector3 = _cell_position(house,house.cells[0])+Vector3(0,1.9,0)
	for cell: Dictionary in house.cells:
		stage.y = maxf(stage.y,float(cell.level)*FLOOR+2.0)
	if concert_pulse_material == null:
		concert_pulse_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform bool playing = false;
void vertex() { VERTEX.y += sin(TIME*1.5+VERTEX.x*4.0)*0.035; }
void fragment() { ALBEDO = mix(vec3(0.48,0.66,0.57),vec3(0.90,0.72,0.40),playing ? 0.70+0.12*sin(TIME*3.0) : 0.0); }
"""
		concert_pulse_material.shader = shader
	concert_pulse_material.set_shader_parameter("playing",phase == "playing")
	var line_vertices: Array[Vector3] = []
	for index in range(9):
		var x := -1.25+float(index)*0.31
		var sag := (1.0-pow(x/1.25,2))*0.13
		var p := stage+Vector3(x,-sag,1.0)
		line_vertices.append_array([p+Vector3(-0.11,0.07,0),p+Vector3(0.11,0.07,0),p+Vector3(0,-0.20,0)])
	var flags := _triangles(concert_layer,line_vertices,Color.WHITE)
	flags.material_override = concert_pulse_material
	flags.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sign := Label3D.new()
	sign.text = "♫ 街坊合奏" if phase == "playing" else "街坊正在赶来"
	sign.font = preload("res://scripts/ui/valley_ui_theme.gd").make_theme().default_font
	sign.font_size = 40
	sign.pixel_size = 0.007
	sign.modulate = Color("f4edda")
	sign.outline_modulate = Color("3e594b")
	sign.outline_size = 8
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = stage+Vector3(0,0.60,0)
	concert_layer.add_child(sign)

func update_house_music(source: Dictionary) -> void:
	var source_id := str(source.get("source_id","")) if bool(source.get("audible",false)) else ""
	var house := _house_record(source_id)
	var fingerprint := str([source_id,house.get("cells",[]),house.get("origin",[])])
	if fingerprint == house_music_fingerprint: return
	house_music_fingerprint = fingerprint
	house_music_source = source_id
	_clear(house_music_layer)
	if house.is_empty(): return
	if house_music_material == null:
		house_music_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() { ALBEDO = vec3(0.70,0.42,0.13); ALPHA = 0.30+0.09*sin(TIME*2.094395); }
"""
		house_music_material.shader = shader
	var top := 0.0
	for cell: Dictionary in house.cells:
		var at := _cell_position(house,cell)
		var level := int(cell.level)
		top = maxf(top,(level+1)*FLOOR+0.70)
		if cell.kind != "room": continue
		for direction: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if not _at(house.cells,int(cell.x)+direction.x,int(cell.z)+direction.y,level).is_empty(): continue
			if level == 0 and direction == Vector2i.DOWN: continue
			var rotation := atan2(float(direction.x),float(direction.y))
			for x in [-0.46,0.46]:
				var glow := MeshInstance3D.new()
				var panel := QuadMesh.new()
				panel.size = Vector2(0.33,0.53)
				glow.mesh = panel
				glow.material_override = house_music_material
				glow.position = at+Basis(Vector3.UP,rotation)*Vector3(x,level*FLOOR+1.0,UNIT*0.5+0.163)
				glow.rotation.y = rotation
				glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				house_music_layer.add_child(glow)

	var note := Label3D.new()
	note.text = "♫" if str(source.get("role","lead")) == "lead" else "♪"
	note.font_size = 76
	note.pixel_size = 0.006
	note.modulate = Color("f3db9c")
	note.outline_modulate = Color("3d584a")
	note.outline_size = 10
	note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	note.position = _cell_position(house,house.cells[0])+Vector3(0,top+0.18,0)
	house_music_layer.add_child(note)


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

func preview_road(points: Array[Vector2], valid: bool = true) -> void:
	clear_preview()
	if preview == null or points.is_empty(): return
	var color := Color("dfd5a8") if valid else Color("ef7862")
	var samples := _road_samples(points)
	if samples.size() > 1: _road_ribbon(preview,samples,1.25,color,0.04)
	for point: Vector2 in [points[0],points[-1]]:
		_cylinder(preview,0.625,0.625,0.02,Vector3(point.x,_street_height(point)+0.045,point.y),_material(color),24)

func preview_water(points: Array[Vector2], width: float, valid: bool, conflicts: Array = []) -> void:
	clear_preview()
	if preview == null or points.is_empty(): return
	var groups: Array = []
	_merge_water_group(groups, _stroke_contours(points, width * 0.5))
	var color := Color(0.43, 0.81, 0.79, 0.47) if valid else Color(0.96, 0.44, 0.32, 0.50)
	var node := _water_polygon_mesh(preview, groups, 0.095, color)
	if node != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		node.material_override = mat
	for conflict: Variant in conflicts:
		if not conflict is Dictionary: continue
		var encoded: Variant = conflict.get("position", [])
		if not encoded is Array or encoded.size() < 2: continue
		_cylinder(preview, 0.28, 0.28, 0.025, Vector3(float(encoded[0]), 0.14, float(encoded[1])), _material(Color("ef7862")), 16)

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

func _foundation_contact(parent: Node3D) -> void:
	if contact_material == null:
		contact_material = ShaderMaterial.new()
		contact_material.shader = ContactShader
	var contact := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(UNIT+0.7,UNIT+0.7)
	contact.mesh = plane
	contact.material_override = contact_material
	contact.position.y = 0.006
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(contact)

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
		if level == 0: _foundation_contact(node)
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
	return float(state.call("street_height", p))

func _water_clearance(p: Vector2) -> float:
	return float(state.call("water_clearance", p))

func _water_records() -> Array:
	var records: Variant = state.get("waters")
	return records if records is Array else []

func _road_water_signature(road: Dictionary) -> Array:
	# Sample exactly the same vertices and midpoints used by _road. Water edits
	# only invalidate a street when its visible height/material actually changes.
	var id := str(road.get("id", ""))
	var input := hash([road.points, road.get("width", 1.1), water_fingerprint])
	var cached: Dictionary = road_water_signatures.get(id, {})
	if cached.get("input", -1) == input: return cached.signature
	var signature: Array = []
	var samples := _road_samples(road.points)
	for index in range(samples.size()-1):
		var p := samples[index]
		var q := samples[index+1]
		signature.append([_street_height(p),_street_height(q),_water_clearance((p+q)*0.5) < -0.02])
	for endpoint: Vector2 in [samples[0],samples[-1]]: signature.append(_water_clearance(endpoint) > -0.02)

	road_water_signatures[id] = {"input":input, "signature":signature}
	return signature

func _stroke_contours(points: Array[Vector2], radius: float) -> Array:
	if points.is_empty() or radius <= 0.0: return []
	if points.size() == 1:
		var circle := PackedVector2Array()
		for side in range(36):
			var angle := TAU * float(side) / 36.0
			circle.append(points[0] + Vector2(cos(angle), sin(angle)) * radius)
		return [circle]
	# Continuous world-space round-ended strokes, independent of house cells.
	# A loop can produce an outer boundary plus an island boundary. Keep both.
	# Clipper's arc tolerance is in input units. Scale this operation so its
	# default tolerance becomes < 2 cm here instead of visibly faceted 25 cm caps.
	var scaled := PackedVector2Array()
	for point: Vector2 in points: scaled.append(point * 16.0)
	var contours: Array = Geometry2D.offset_polyline(scaled, radius * 16.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	for contour_index in range(contours.size()):
		var contour: PackedVector2Array = contours[contour_index]
		for index in range(contour.size()): contour[index] /= 16.0
		contours[contour_index] = contour
	return contours

func _merge_water_group(groups: Array, contours: Array) -> void:
	if contours.is_empty(): return
	var candidate: Array = contours
	# Simple connected parts use Godot's exact polygon union. A part containing
	# holes remains a contour group; the scanline union below combines that group
	# with later strokes without filling islands or stacking coplanar surfaces.
	var index := 0
	while index < groups.size() and candidate.size() == 1:
		var existing: Array = groups[index]
		if existing.size() != 1:
			index += 1
			continue
		var merged: Array = Geometry2D.merge_polygons(existing[0], candidate[0])
		if merged.size() == 2 and Geometry2D.is_polygon_clockwise(merged[0]) == Geometry2D.is_polygon_clockwise(merged[1]):
			index += 1
			continue
		candidate = merged
		groups.remove_at(index)
		index = 0
	groups.append(candidate)

func _water_groups(inset: float) -> Array:
	var groups: Array = []
	var river := PackedVector2Array()
	var half_width := 2.3 - inset
	for index in range(57):
		var z := -28.0 + index
		river.append(Vector2(_river_x(z) - half_width, z))
	for index in range(56, -1, -1):
		var z := -28.0 + index
		river.append(Vector2(_river_x(z) + half_width, z))
	_merge_water_group(groups, [river])
	for water: Dictionary in _water_records():
		var points: Array[Vector2] = []
		for encoded: Array in water.points:
			points.append(Vector2(float(encoded[0]), float(encoded[1])))
		_merge_water_group(groups, _stroke_contours(points, maxf(0.05, float(water.width) * 0.5 - inset)))
	return groups

func _water_polygon_mesh(parent: Node3D, groups: Array, height: float, color: Color) -> MeshInstance3D:
	var vertices: Array[Vector3] = []
	var simple := true
	for group: Array in groups:
		if group.size() != 1:
			simple = false
			break
	if simple:
		# Disjoint merged contours have no overlaps or holes: normal triangulation
		# is the inexpensive common path for a branch or a round pond.
		for group: Array in groups:
			var polygon: PackedVector2Array = group[0]
			var indices := Geometry2D.triangulate_polygon(polygon)
			for index in range(0, indices.size(), 3):
				_append_water_triangle(vertices, polygon[indices[index]], polygon[indices[index + 1]], polygon[indices[index + 2]], height)
	else:
		vertices = _water_scanline_union(groups, height)
	if vertices.is_empty(): return null
	var node := _triangles(parent, vertices, color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _append_water_triangle(vertices: Array[Vector3], a: Vector2, b: Vector2, c: Vector2, height: float) -> void:
	if absf((b - a).cross(c - a)) < 0.0000001: return
	if (b - a).cross(c - a) > 0.0:
		vertices.append_array([Vector3(a.x, height, a.y), Vector3(c.x, height, c.y), Vector3(b.x, height, b.y)])
	else:
		vertices.append_array([Vector3(a.x, height, a.y), Vector3(b.x, height, b.y), Vector3(c.x, height, c.y)])

func _water_scanline_union(groups: Array, height: float, subtract: Array = []) -> Array[Vector3]:
	# Exact trapezoids between contour vertices, not a terrain grid. Each contour
	# group uses even/odd fill; union its intervals with all other stroke groups.
	# Holes, self-returning channels and water inside an island remain truthful.
	var edges_by_group: Array = []
	var levels: Array[float] = []
	for group: Array in groups+subtract:
		var edges: Array = []
		for contour: PackedVector2Array in group:
			for index in range(contour.size()):
				var a := contour[index]
				var b := contour[(index + 1) % contour.size()]
				levels.append(a.y)
				if absf(a.y - b.y) > 0.000001: edges.append([a, b])
		edges_by_group.append(edges)
	# Crossing edges from different groups are additional events. Splitting at
	# those heights makes the interval ordering exact across overlapping groups.
	for left in range(edges_by_group.size()):
		for right in range(left + 1, edges_by_group.size()):
			for a: Array in edges_by_group[left]:
				for b: Array in edges_by_group[right]:
					if maxf(a[0].x, a[1].x) < minf(b[0].x, b[1].x) or maxf(b[0].x, b[1].x) < minf(a[0].x, a[1].x): continue
					if maxf(a[0].y, a[1].y) < minf(b[0].y, b[1].y) or maxf(b[0].y, b[1].y) < minf(a[0].y, a[1].y): continue
					var crossing: Variant = Geometry2D.segment_intersects_segment(a[0], a[1], b[0], b[1])
					if crossing is Vector2: levels.append(crossing.y)
	levels.sort()
	var unique: Array[float] = []
	for level: float in levels:
		if unique.is_empty() or level - unique[-1] > 0.000001: unique.append(level)
	var vertices: Array[Vector3] = []
	for index in range(unique.size() - 1):
		var y0 := unique[index]
		var y1 := unique[index + 1]
		var middle := (y0 + y1) * 0.5
		var intervals: Array = []
		var excluded: Array = []
		for group_index in range(edges_by_group.size()):
			var edges: Array = edges_by_group[group_index]
			var crossings: Array = []
			for edge: Array in edges:
				if middle <= minf(edge[0].y, edge[1].y) or middle >= maxf(edge[0].y, edge[1].y): continue
				crossings.append([_water_edge_x(edge, middle), _water_edge_x(edge, y0), _water_edge_x(edge, y1)])
			crossings.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
			for pair in range(0, crossings.size() - 1, 2):
				if group_index < groups.size(): intervals.append([crossings[pair], crossings[pair + 1]])
				else: excluded.append([crossings[pair], crossings[pair + 1]])
		intervals.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0][0]) < float(b[0][0]))
		var joined: Array = []
		for interval: Array in intervals:
			if joined.is_empty() or float(interval[0][0]) > float(joined[-1][1][0]) + 0.000001:
				joined.append(interval)
			elif float(interval[1][0]) > float(joined[-1][1][0]):
				joined[-1][1] = interval[1]
		for cut: Array in excluded:
			var remaining: Array = []
			for interval: Array in joined:
				if float(cut[1][0]) <= float(interval[0][0]) or float(cut[0][0]) >= float(interval[1][0]):
					remaining.append(interval)
					continue
				if float(cut[0][0]) > float(interval[0][0]): remaining.append([interval[0],cut[0]])
				if float(cut[1][0]) < float(interval[1][0]): remaining.append([cut[1],interval[1]])
			joined = remaining
		for interval: Array in joined:
			var a := Vector2(float(interval[0][1]), y0)
			var b := Vector2(float(interval[1][1]), y0)
			var c := Vector2(float(interval[1][2]), y1)
			var d := Vector2(float(interval[0][2]), y1)
			_append_water_triangle(vertices, a, b, c, height)
			_append_water_triangle(vertices, a, c, d, height)
	return vertices

func _water_edge_x(edge: Array, height: float) -> float:
	var a: Vector2 = edge[0]
	var b: Vector2 = edge[1]
	return lerpf(a.x, b.x, (height - a.y) / (b.y - a.y))

func _rebuild_water() -> void:
	var records := _water_records()
	var fingerprint := hash(records)
	water_edit_stats = {"changed":false,"elapsed_ms":0.0,"contours":0,"triangles":0,"strokes":records.size()}
	if water_layer == null or fingerprint == water_fingerprint: return
	var started := Time.get_ticks_usec()
	_clear(water_layer)
	var banks := _water_groups(0.0)
	var shallow := _water_groups(0.34)
	var deep := _water_groups(0.53)
	_water_polygon_mesh(water_layer, banks, 0.003, Color("bdbd9c"))
	var shallow_mesh := _water_polygon_mesh(water_layer, shallow, 0.019, Color("a0bab0"))
	if shallow_mesh != null: shallow_mesh.material_override = _water_surface_material(true)
	var deep_mesh := _water_polygon_mesh(water_layer, deep, 0.022, Color("659f9a"))
	if deep_mesh != null: deep_mesh.material_override = _water_surface_material(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 261014
	# Stones belong to water, not landscape. Edges swallowed by a joining pond
	# never leave an old stone bank running through the new water surface.
	for group: Array in banks:
		for contour: PackedVector2Array in group:
			water_edit_stats["contours"] += 1
			var accumulated := 0.0
			for index in range(contour.size()):
				var a := contour[index]
				var b := contour[(index + 1) % contour.size()]
				accumulated += a.distance_to(b)
				if accumulated < 2.7: continue
				accumulated = 0.0
				var p := a.lerp(b, 0.5)
				if absf(_water_clearance(p)) > 0.08: continue
				if _near_house(p, 1.2): continue
				var stone := _cylinder(water_layer, 0.20, 0.10, 0.19, Vector3(p.x, 0.065, p.y), _material(Color("c2bca6")), 7)
				stone.rotation.y = rng.randf() * TAU
				stone.scale = Vector3(rng.randf_range(0.8, 1.4), rng.randf_range(0.6, 1.0), rng.randf_range(0.7, 1.4))
	_merge_meshes(water_layer)
	for child: Node in water_layer.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for surface in range(child.mesh.get_surface_count()):
				water_edit_stats["triangles"] += child.mesh.surface_get_array_index_len(surface) / 3
	water_fingerprint = fingerprint
	water_edit_stats["changed"] = true
	water_edit_stats["elapsed_ms"] = float(Time.get_ticks_usec() - started) / 1000.0

func _build_landscape() -> void:
	ground_material = ShaderMaterial.new()
	ground_material.shader = GroundShader
	_box(landscape,Vector3(60,0.7,56),Vector3(0,-0.37,0),ground_material)
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
		var patch := _triangles(landscape,vertices,Color.WHITE)
		patch.material_override = ground_material
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
	_merge_meshes(landscape)

func _near_house(p: Vector2, radius: float) -> bool:
	for house: Dictionary in state.houses:
		for cell: Dictionary in house["cells"]:
			var at := _cell_position(house,cell)
			if p.distance_to(Vector2(at.x,at.z)) < radius: return true
	return false

func _tree(p: Vector2, scale_value: float, cypress: bool) -> void:
	var kind := "cypress" if cypress else "olive"
	var seed_value := hash(p)
	var variant := posmod(seed_value,3)
	for part: String in foliage.parts(kind,variant):
		var instance := MeshInstance3D.new()
		instance.mesh = foliage.parts(kind,variant)[part]
		instance.material_override = foliage.material(part)
		instance.position = Vector3(p.x,0,p.y)
		instance.scale = Vector3.ONE*scale_value
		instance.rotation.y = float(posmod(seed_value,6283))/1000.0
		landscape.add_child(instance)

func _road_samples(points: Array) -> Array[Vector2]:
	var samples: Array[Vector2] = []
	for point in points:
		var at: Vector2 = point if point is Vector2 else Vector2(float(point[0]),float(point[1]))
		if samples.is_empty(): samples.append(at)
		else:
			var from := samples[-1]
			var steps := maxi(1,ceili(from.distance_to(at)/0.35))
			for step in range(1,steps+1):
				var position := from.lerp(at,float(step)/steps)
				if samples[-1].distance_to(position) > 0.001: samples.append(position)
	return samples

func _road_offsets(samples: Array[Vector2], width: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(samples.size()):
		var incoming := (samples[index]-samples[maxi(0,index-1)]).normalized()
		var outgoing := (samples[mini(samples.size()-1,index+1)]-samples[index]).normalized()
		if incoming == Vector2.ZERO: incoming = outgoing
		if outgoing == Vector2.ZERO: outgoing = incoming
		var normal := (incoming+outgoing).normalized().orthogonal()
		if normal == Vector2.ZERO: normal = outgoing.orthogonal()
		var factor := minf(1.5,1.0/maxf(0.1,absf(normal.dot(outgoing.orthogonal()))))
		result.append(normal*width*0.5*factor)
	return result

func _road_ribbon(parent: Node3D, samples: Array[Vector2], width: float, color: Color, lift: float = 0.0) -> void:
	var offsets := _road_offsets(samples,width)
	var vertices: Array[Vector3] = []
	for index in range(samples.size()-1):
		var p := samples[index]
		var q := samples[index+1]
		var y0 := _street_height(p)+lift
		var y1 := _street_height(q)+lift
		var n0 := offsets[index]
		var n1 := offsets[index+1]
		var a := Vector3(p.x-n0.x,y0,p.y-n0.y)
		var b := Vector3(q.x-n1.x,y1,q.y-n1.y)
		var c := Vector3(q.x+n1.x,y1,q.y+n1.y)
		var d := Vector3(p.x+n0.x,y0,p.y+n0.y)
		vertices.append_array([a,b,c,a,c,d])
	var ribbon := _triangles(parent,vertices,color)
	if lift == 0.0: ribbon.material_override = _shared_road_material()

func _shared_road_material() -> ShaderMaterial:
	if road_material == null:
		road_material = ShaderMaterial.new()
		road_material.shader = RoadShader
	return road_material

func _road_join_signature(road: Dictionary) -> Array:
	if road_join_signatures.has(road.id): return road_join_signatures[road.id]
	var signature: Array = []
	for other: Dictionary in state.roads:
		if other.id == road.id: continue
		var radius := (float(road.width)+float(other.width))*0.5+0.08
		for index in range(other.points.size()-1):
			var a := Vector2(other.points[index][0],other.points[index][1])
			var b := Vector2(other.points[index+1][0],other.points[index+1][1])
			for segment in range(road.points.size()-1):
				var c := Vector2(road.points[segment][0],road.points[segment][1])
				var d := Vector2(road.points[segment+1][0],road.points[segment+1][1])
				if float(state.call("_segment_distance",a,b,c,d)) <= radius:
					signature.append([a,b,other.width])
					break
	road_join_signatures[road.id] = signature
	return signature

func _inside_other_road(position: Vector2, own_id: String) -> bool:
	for road: Dictionary in state.roads:
		if road.id == own_id: continue
		for index in range(road.points.size()-1):
			var a := Vector2(road.points[index][0],road.points[index][1])
			var b := Vector2(road.points[index+1][0],road.points[index+1][1])
			if position.distance_to(Geometry2D.get_closest_point_to_segment(position,a,b)) <= float(road.width)*0.5+0.07: return true
	return false

func _road_surface_vertices(contours: Array, cuts: Array) -> Array[Vector3]:
	if contours.size() != 1: return _water_scanline_union([contours],0,cuts)
	var polygons: Array = contours.duplicate()
	for cut: Array in cuts:
		if cut.size() != 1: return _water_scanline_union([contours],0,cuts)
		var next: Array = []
		for polygon: PackedVector2Array in polygons:
			var clipped := Geometry2D.clip_polygons(polygon,cut[0])
			for part: PackedVector2Array in clipped:
				if Geometry2D.is_polygon_clockwise(part): return _water_scanline_union([contours],0,cuts)
				next.append(part)
		polygons = next
	var vertices: Array[Vector3] = []
	for polygon: PackedVector2Array in polygons:
		var indices := Geometry2D.triangulate_polygon(polygon)
		for index in range(0,indices.size(),3): _append_water_triangle(vertices,polygon[indices[index]],polygon[indices[index+1]],polygon[indices[index+2]],0)
	return vertices

func _subdivide_road(vertices: Array[Vector3]) -> Array[Vector3]:
	var output: Array[Vector3] = []
	var triangles: Array = []
	for index in range(0,vertices.size(),3): triangles.append([vertices[index],vertices[index+1],vertices[index+2]])
	while not triangles.is_empty():
		var triangle: Array = triangles.pop_back()
		var longest := 0
		for edge in range(1,3):
			if triangle[edge].distance_squared_to(triangle[(edge+1)%3]) > triangle[longest].distance_squared_to(triangle[(longest+1)%3]): longest = edge
		if triangle[longest].distance_squared_to(triangle[(longest+1)%3]) <= 0.36:
			var a := Vector2(triangle[0].x,triangle[0].z)
			var b := Vector2(triangle[1].x,triangle[1].z)
			var c := Vector2(triangle[2].x,triangle[2].z)
			if absf((b-a).cross(c-a)) > 0.000001: output.append_array(triangle)
			continue
		var a: Vector3 = triangle[longest]
		var b: Vector3 = triangle[(longest+1)%3]
		var c: Vector3 = triangle[(longest+2)%3]
		var middle := (a+b)*0.5
		triangles.append([a,middle,c])
		triangles.append([middle,b,c])
	return output

func _road(road: Dictionary) -> Node3D:
	var samples := _road_samples(road.points)
	var width := float(road.width)
	var offsets := _road_offsets(samples,width)
	var root := Node3D.new()
	root.name = str(road.id)
	roads_layer.add_child(root)
	var cuts: Array = []
	for other: Dictionary in state.roads:
		if int(str(other.id).substr(1)) < int(str(road.id).substr(1)) and _roads_touch(road,other): cuts.append(road_outlines[other.id])
	var vertices: Array[Vector3] = _road_surface_vertices(road_outlines[road.id],cuts)
	if bool(road.get("bridge",false)): vertices = _subdivide_road(vertices)
	var heights: Dictionary = {}
	for index in range(vertices.size()):
		var at := Vector2(vertices[index].x,vertices[index].z)
		if heights.has(at):
			vertices[index].y = heights[at]
			continue
		var nearest := samples[0]
		var distance := INF
		for segment in range(samples.size()-1):
			var candidate := Geometry2D.get_closest_point_to_segment(at,samples[segment],samples[segment+1])
			if at.distance_squared_to(candidate) < distance:
				distance = at.distance_squared_to(candidate)
				nearest = candidate
		vertices[index].y = _street_height(nearest)
		heights[at] = vertices[index].y
	if not vertices.is_empty():
		var surface := _triangles(root,vertices,Color.WHITE)
		surface.material_override = _shared_road_material()
	for index in range(samples.size()-1):
		var p := samples[index]
		var q := samples[index+1]
		var y0 := _street_height(p)
		var y1 := _street_height(q)
		var y := (y0+y1)*0.5
		var over_water := _water_clearance((p+q)*0.5) < -0.02
		for side in [-1,1]:
			var a: Vector2 = p+offsets[index]*side
			var b: Vector2 = q+offsets[index+1]*side
			var center := (a+b)*0.5
			if _inside_other_road(center,str(road.id)): continue
			var curb := _box(root,Vector3(0.065,0.065 if over_water else 0.045,a.distance_to(b)+0.003),Vector3(center.x,y+(0.48 if over_water else 0.005),center.y),_material(Color("d5ccb0") if over_water else Color("bcb295")))
			curb.rotation.y = atan2(b.x-a.x,b.y-a.y)
			curb.rotation.x = -atan2(y1-y0,a.distance_to(b))
			if over_water and index%3 == 0: _box(root,Vector3(0.08,0.52,0.08),Vector3(center.x,y+0.25,center.y),_material(Color("c8ba99")))
		if over_water:
			var plank := _box(root,Vector3(width+0.06,0.08,p.distance_to(q)*0.96),Vector3((p.x+q.x)*0.5,y-0.025,(p.y+q.y)*0.5),_material(Color("b5a17e")))
			plank.rotation.y = atan2(q.x-p.x,q.y-p.y)
	return root

func _roads_touch(road: Dictionary, other: Dictionary) -> bool:
	var radius := (float(road.width)+float(other.width))*0.5+0.08
	for a in range(road.points.size()-1):
		for b in range(other.points.size()-1):
			if float(state.call("_segment_distance",Vector2(road.points[a][0],road.points[a][1]),Vector2(road.points[a+1][0],road.points[a+1][1]),Vector2(other.points[b][0],other.points[b][1]),Vector2(other.points[b+1][0],other.points[b+1][1]))) <= radius: return true
	return false
