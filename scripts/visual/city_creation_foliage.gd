class_name CityCreationFoliage
extends RefCounted
## Folded leaf sprays and species branching. Mesh/material caches are shared by every
## vegetation block; no tree allocates its own material or runs a CPU wind loop.
## Tiny Glade's recovered Grass2 semantics informed height tint, instance-scale
## variation and height-weighted wind, not these authored vertices or colours.

const SIDES := 14
const RINGS := 6
var _parts: Dictionary = {}
var _materials: Dictionary = {}

func parts(kind: String, variant: int) -> Dictionary:
	variant = posmod(variant, 3)
	var key := "%s:%d" % [kind, variant]
	if _parts.has(key): return _parts[key]
	var leaves := _geometry()
	var wood := _geometry()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7391 + variant * 223 + {"olive":31,"cypress":71,"shrub":113,"weeping_willow":211}.get(kind,113)
	if kind in ["pink_flower","white_flower","yellow_flower"]:
		_flowers(leaves,wood,rng,variant,kind)
		for i in range(wood.colors.size()):wood.colors[i].a=0.
	else:preload("res://scripts/visual/city_creation_tree_crown.gd").append(self,leaves,wood,rng,variant,kind)
	var result := {"canopy":_mesh(leaves)}
	if not wood.vertices.is_empty(): result["trunk"] = _mesh(wood)
	_parts[key] = result
	return result

func material(part: String) -> Material:
	if _materials.has(part): return _materials[part]
	var result: Material
	if part == "trunk":
		var wood := ShaderMaterial.new()
		wood.shader=preload("res://scripts/visual/shaders/creation_branches.gdshader")
		result = wood
	else:
		var shader := preload("res://scripts/visual/shaders/creation_foliage.gdshader")
		var foliage := ShaderMaterial.new()
		foliage.shader = shader
		foliage.set_shader_parameter("micro_normal_strength",.018)
		foliage.set_shader_parameter("transmission_strength",.42)
		result = foliage
	_materials[part] = result
	return result

func _geometry() -> Dictionary:
	return {"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"colors":PackedColorArray(),"indices":PackedInt32Array()}

func _mesh(data: Dictionary) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data.vertices
	arrays[Mesh.ARRAY_NORMAL] = data.normals
	arrays[Mesh.ARRAY_COLOR] = data.colors
	arrays[Mesh.ARRAY_INDEX] = data.indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

func _flowers(leaves:Dictionary,wood:Dictionary,rng:RandomNumberGenerator,variant:int,kind:String)->void:
	var petal:Color={"pink_flower":Color("ef9db3"),"white_flower":Color("fff5dc"),"yellow_flower":Color("efc44f")}[kind]
	for stem:int in range(7):
		var angle:float=stem*2.39996+variant*.6
		var at:=Vector3(cos(angle),0,sin(angle))*(.09+float(stem)*.038)
		var top:=at+Vector3(0,.24+rng.randf()*.24,0)
		_branch(wood,at,top,.014,.008,"flower")
		_lobe(leaves,at+Vector3(.025,.12,0),Vector3(.12,.055,.06),rng,"shrub",.55)
		for petal_index:int in range(5):
			var phase:float=petal_index*TAU/5.
			var before:int=leaves.colors.size()
			_lobe(leaves,top+Vector3(cos(phase)*.065,0,sin(phase)*.065),Vector3(.070,.035,.055),rng,"shrub",.55)
			for i:int in range(before,leaves.colors.size()):leaves.colors[i]=Color(petal.lightened(rng.randf()*.08),1.)
		var before:int=leaves.colors.size()
		_lobe(leaves,top+Vector3(0,.02,0),Vector3(.032,.025,.032),rng,"shrub",.55)
		for i:int in range(before,leaves.colors.size()):leaves.colors[i]=Color("c58a31")

func _lobe(data: Dictionary, center: Vector3, radius: Vector3, rng: RandomNumberGenerator, kind: String, height: float) -> void:
	var first: int = data.vertices.size()
	var phase := rng.randf_range(0,TAU)
	var twist := rng.randf_range(-0.26,0.26)
	var hue := rng.randf_range(-0.035,0.035)
	_leaf_vertex(data,center+preload("res://scripts/visual/city_creation_canopy_shape.gd").point(0.,0.,phase,radius,kind),Vector3.UP,kind,height,hue)
	for ring in range(1,RINGS + 1):
		var theta := PI * ring / float(RINGS + 1)
		for side in range(SIDES):
			var angle := TAU * side / float(SIDES) + twist * sin(theta)
			var shape=preload("res://scripts/visual/city_creation_canopy_shape.gd")
			var position:Vector3=center+shape.point(theta,angle,phase,radius,kind)
			var normal:Vector3=shape.normal(theta,angle,phase,radius,kind)
			_leaf_vertex(data,position,normal,kind,height,hue)
	var bottom: int = data.vertices.size()
	_leaf_vertex(data,center+preload("res://scripts/visual/city_creation_canopy_shape.gd").point(PI,0.,phase,radius,kind),Vector3.DOWN,kind,height,hue)
	for side in range(SIDES):
		var next := (side + 1) % SIDES
		# Clockwise from outside, the convention used by Godot mesh surfaces.
		_triangle(data,first,first + 1 + side,first + 1 + next)
		for ring in range(RINGS - 1):
			var a := first + 1 + ring * SIDES + side
			var b := first + 1 + ring * SIDES + next
			_triangle(data,a,a + SIDES,b)
			_triangle(data,b,a + SIDES,b + SIDES)
		var a := first + 1 + (RINGS - 1) * SIDES + side
		var b := first + 1 + (RINGS - 1) * SIDES + next
		_triangle(data,a,bottom,b)

func _leaf_vertex(data: Dictionary, position: Vector3, normal: Vector3, kind: String, height: float, hue: float) -> void:
	var t := clampf(position.y / height,0.0,1.0)
	var low := Color("566c43")
	var high := Color("a7b778")
	if kind == "cypress":
		low = Color("3f6450")
		high = Color("81a17b")
	elif kind == "golden":
		low=Color("b77b31");high=Color("e4bf52")
	elif kind == "willow":
		low=Color("617c4b");high=Color("b0c582")
	elif kind == "shrub":
		low = Color("57703f")
		high = Color("a1b86c")
	var color := low.lerp(high,smoothstep(0.14,1.0,t))
	color.r = clampf(color.r + hue,0.0,1.0)
	color.g = clampf(color.g + hue * 0.65,0.0,1.0)
	color.b = clampf(color.b + hue * 0.4,0.0,1.0)
	color.a = t
	data.vertices.append(position)
	data.normals.append(normal)
	data.colors.append(color)

func _branch(data: Dictionary, start: Vector3, end: Vector3, radius_start: float, radius_end: float, kind:String="olive") -> void:
	var first:int=data.vertices.size()
	preload("res://scripts/visual/city_creation_bough_curve.gd").append(data,start,end,radius_start,radius_end,kind)
	if kind!="flower":preload("res://scripts/visual/city_creation_bough_curve.gd").caps(data,first)

func _triangle(data: Dictionary, a: int, b: int, c: int) -> void:
	data.indices.append(a)
	data.indices.append(b)
	data.indices.append(c)
