extends RefCounted
## Pruned street trees use the same attached leaves, bark and wind as planted trees.
const Shoots=preload("res://scripts/visual/city_creation_leaf_shoots.gd")
const Safe=preload("res://scripts/visual/city_creation_safe_instances.gd")
static func parts(f:RefCounted)->Dictionary:
	if f._parts.has("avenue:0"):return f._parts["avenue:0"]
	var leaves:Dictionary=f._geometry();var wood:Dictionary=f._geometry()
	var rng:=RandomNumberGenerator.new();rng.seed=68421
	var fork:=Vector3(0,1.62,0)
	f._branch(wood,Vector3(0,.10,0),fork,.10,.045)
	for arm:int in range(7):
		var angle:=arm*2.39996;var radial:=Vector3(cos(angle),0,sin(angle))
		var tip:=fork+radial*(.26+rng.randf()*.06)+Vector3(0,.28+arm*.075,0)
		f._branch(wood,fork,tip,.034,.008)
		Shoots.append(f,leaves,wood,tip,tip+Vector3.UP*.08,Vector3(.30,.30,.30),rng,"olive",2.725,65)
	# Keep the original tree's .65m radial crown envelope and 2.725m top.
	var radius:=0.;var top:=0.
	for data:Dictionary in [leaves,wood]:
		for point:Vector3 in data.vertices:
			radius=maxf(radius,Vector2(point.x,point.z).length());top=maxf(top,point.y)
	var scale_value:=Vector3(.62/radius,2.725/top,.62/radius)
	for data:Dictionary in [leaves,wood]:
		for i:int in range(data.vertices.size()):
			data.vertices[i]*=scale_value;data.normals[i]=(data.normals[i]/scale_value).normalized()
			data.colors[i].a=0. if data.vertices[i].y<.14 else clampf(data.vertices[i].y/2.725,0.,1.)
	var result:={"canopy":f._mesh(leaves),"trunk":f._mesh(wood)}
	f._parts["avenue:0"]=result;return result

static func install(renderer,root:Node3D,positions:Array[Vector3])->void:
	var meshes:=parts(renderer.foliage)
	for part:String in meshes:
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=meshes[part];Safe.initialize(multi,positions.size())
		for at:Vector3 in positions:
			var angle:float=fposmod(at.x*12.9898+at.z*78.233,TAU)
			Safe.append(multi,Transform3D(Basis(Vector3.UP,angle),at))
		var node:=MultiMeshInstance3D.new();node.name="AvenueCrowns" if part=="canopy" else "AvenueTrunks"
		node.multimesh=multi;node.material_override=renderer.foliage.material(part);node.extra_cull_margin=.12;root.add_child(node)
