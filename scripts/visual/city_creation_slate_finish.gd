extends RefCounted
## Metric slate courses on explicit modern roof skins; geometry and picks stay unchanged.
static var texture:ImageTexture
static func apply(mesh:MeshInstance3D)->void:
	var source:=mesh.material_override as StandardMaterial3D
	if source==null or int(source.get_meta("creation_surface_kind",0))!=3:return
	var arrays:Array=mesh.mesh.surface_get_arrays(0)
	var original:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var source_indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var points:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	# Shared smooth edge normals are lighting data, not a roof chart. Give
	# each triangle its true plane and hard-edge normal; averaging the upper
	# skin with the prism underside creates dark wedges on flat roof panels.
	for triangle in range(0,source_indices.size(),3):
		var a:=original[source_indices[triangle]];var b:=original[source_indices[triangle+1]];var c:=original[source_indices[triangle+2]]
		var n:Vector3=(c-a).cross(b-a).normalized();var along:=Vector3(n.z,0.,-n.x).normalized()
		if along.length_squared()<.01:along=Vector3.RIGHT
		var down:=along.cross(n).normalized()
		for j in range(3):
			var at:int=source_indices[triangle+j];var point:=original[at]
			indices.append(points.size());points.append(point);normals.append(n)
			uv.append(Vector2(point.dot(along)/.64,point.dot(down)/.48) if n.y>.04 else Vector2(.25,.25))
	for slot in [Mesh.ARRAY_TANGENT,Mesh.ARRAY_COLOR,Mesh.ARRAY_TEX_UV2]:
		if arrays[slot]==null:continue
		var original_values=arrays[slot];var expanded=original_values.duplicate();expanded.clear()
		var stride:=4 if slot==Mesh.ARRAY_TANGENT else 1
		for at:int in source_indices:
			for component in range(stride):expanded.append(original_values[at*stride+component])
		arrays[slot]=expanded
	arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices;arrays[Mesh.ARRAY_TEX_UV]=uv
	var result:=ArrayMesh.new();result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.mesh=result
	if texture==null:texture=_texture()
	var material:=source.duplicate() as StandardMaterial3D;material.albedo_texture=texture;mesh.material_override=material

static func _texture()->ImageTexture:
	var image:=Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in range(128):
		var row:=y/64;var v:=float(y%64)/64.
		for x in range(128):
			var shifted:=posmod(x+row*32,128);var column:=shifted/64;var u:=float(shifted%64)/64.
			var seam:=1.-smoothstep(.012,.038,minf(u,1.-u))
			var overlap:=1.-smoothstep(.012,.065,v)
			var grain:=sin(float(x)*1.7+sin(float(y)*.43))*sin(float(y)*1.23)*.012
			var tile:=.97+(.012 if posmod(row+column,2)==0 else -.012)
			var value:=tile+grain-.10*seam-.14*overlap+.018*smoothstep(.80,.98,v)
			image.set_pixel(x,y,Color(value,value,value))
	image.generate_mipmaps();return ImageTexture.create_from_image(image)
