extends RefCounted
## Worker-owned SurfaceTool only: no scene nodes, GPU mesh or physics server.
static func prepare(faces:Array)->Dictionary:
	if faces.is_empty():return {"arrays":[],"collision":PackedVector3Array()}
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,faces.size(),3):
		surface.add_vertex(faces[i]);surface.add_vertex(faces[i+2]);surface.add_vertex(faces[i+1])
	surface.generate_normals();surface.index()
	var arrays:=surface.commit_to_arrays();var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var collision:=PackedVector3Array();collision.resize(indices.size())
	# Godot4.7 Mesh.get_faces -> TriangleMesh::create snaps each collision
	# vertex to .0001m (core/math/triangle_mesh.cpp); retain that exact policy.
	for i in range(indices.size()):collision[i]=vertices[indices[i]].snappedf(.0001)
	return {"arrays":arrays,"collision":collision}
