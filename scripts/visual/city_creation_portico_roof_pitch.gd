extends RefCounted
const Geometry=preload("res://scripts/world/city_creation_portico_roof_pitch.gd")
const Meshes=preload("res://scripts/visual/city_creation_ancient_civic_mesh.gd")
static func build(r,parent:Node3D,h:Dictionary,palette:Array)->void:
	var data:=Geometry.for_house(r.state,h);var root:=Node3D.new();root.name="PorticoPitchedRoofs";parent.add_child(root)
	parent.set_meta("rigid_architecture",true)
	var stone:=Meshes.stone(palette[0].lerp(Color("e6d8b8"),.48))
	for patch:Dictionary in data.patches:
		var faces:Array[Vector3]=[];faces.assign(patch.vertices)
		var node:=Node3D.new();node.name="Portico_"+str(patch.category)+"_"+str(patch.cell_id);root.add_child(node)
		if patch.material=="tile":
			var uv:PackedVector2Array=patch.uv
			Meshes.tiled(r,node,faces,uv,palette[1],str(patch.part))
		else:
			var mesh:MeshInstance3D=r._triangles(node,faces,palette[0]);mesh.material_override=stone;mesh.name=str(patch.part)
		var cell:Dictionary=h.cells.filter(func(c):return str(c.id)==str(patch.cell_id))[0]
		var body:=StaticBody3D.new();body.name="PorticoRoofPick" if patch.roof_skin else "PorticoGablePick";node.add_child(body)
		body.set_meta("house_id",str(h.id));body.set_meta("cell_id",str(cell.id));body.set_meta("cell",cell.duplicate(true))
		if patch.roof_skin:body.set_meta("roof_surface",true)
		var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(PackedVector3Array(faces));var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	parent.set_meta("portico_roof_pitch",{"apex":data.apex,"degrees":float(h.roof_pitch.degrees),"kind":data.kind})
	parent.set_meta("roof_pitch",h.roof_pitch.duplicate(true));parent.set_meta("ancient_roof_patches",data.patches.size())

static func original_anchor(parent:Node3D)->Vector3:
	var result:=Vector3.ZERO;var high:=-INF;var inverse:=parent.global_transform.affine_inverse()
	for mesh:MeshInstance3D in parent.find_children("*","MeshInstance3D",true,false):
		if not ["GreekContinuousTileRoof","AncientLowTileRoof","VillaProjectingTerracottaRoof"].any(func(prefix):return str(mesh.name).begins_with(prefix)):continue
		var pose:=inverse*mesh.global_transform;var faces:=mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var center:Vector3=pose*((faces[i]+faces[i+1]+faces[i+2])/3.)
			if center.y>high:high=center.y;result=center
	return result
