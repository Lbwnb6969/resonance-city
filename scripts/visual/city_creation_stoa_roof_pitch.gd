extends RefCounted
## Only the Ionic roof changes; colonnades and walkways remain the old builder's.
const Geometry=preload("res://scripts/world/city_creation_stoa_roof_pitch.gd")
const Meshes=preload("res://scripts/visual/city_creation_ancient_civic_mesh.gd")
static func build(r,parent:Node3D,h:Dictionary,palette:Array,plan:Dictionary)->void:
	parent.set_meta("rigid_architecture",true)
	var data:=Geometry.from_plan(h,plan);var root:=Node3D.new();root.name="IonicStoaRoof";parent.add_child(root);root.position=data.pose.origin
	var stone:=Meshes.stone(palette[0]);stone.cull_mode=BaseMaterial3D.CULL_DISABLED
	for row:Dictionary in data.records:
		var node:=Node3D.new();node.name="StoaPitchedRoof_"+str(row.cell.id);root.add_child(node);var roof_faces:=PackedVector3Array();var end_faces:=PackedVector3Array()
		for part:Dictionary in row.parts:
			if part.roof_skin:Meshes.roof(r,node,part.vertices,palette[1],str(part.name),0,float(data.ridge));roof_faces.append_array(PackedVector3Array(part.vertices))
			else:var mesh:MeshInstance3D=r._triangles(node,part.vertices,palette[0]);mesh.name=str(part.name);mesh.material_override=stone;end_faces.append_array(PackedVector3Array(part.vertices))
		_pick(node,h,row.cell,roof_faces,true);_pick(node,h,row.cell,end_faces,false)
	parent.set_meta("stoa_roof_pitch",{"apex":data.apex,"degrees":float(h.roof_pitch.degrees)})
	parent.set_meta("roof_pitch",h.roof_pitch.duplicate(true));parent.set_meta("ancient_roof_patches",data.patches.size())
static func _pick(parent:Node3D,h:Dictionary,cell:Dictionary,faces:PackedVector3Array,roof:bool)->void:
	if faces.is_empty():return
	var body:=StaticBody3D.new();body.name="StoaRoofPick" if roof else "StoaGablePick";parent.add_child(body)
	body.set_meta("house_id",str(h.id));body.set_meta("cell_id",str(cell.id));body.set_meta("cell",cell.duplicate(true))
	if roof:body.set_meta("roof_surface",true)
	var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(faces);var collision:=CollisionShape3D.new();collision.name="StoaRoofSurface" if roof else "StoaGableSurface";collision.shape=shape;body.add_child(collision)
