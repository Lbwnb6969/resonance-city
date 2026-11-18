extends RefCounted
## Publish exact CPU timber triangles, with roof and wall picking kept separate.
const Geometry=preload("res://scripts/world/city_creation_acoustic_roof_pitch.gd")
static func build(r,root:Node3D,h:Dictionary,plan:Dictionary,wood:Material,dark:Material)->void:
	var stage:Node3D=root.find_child("TimberAcousticHall",true,false);var data:=Geometry.from_plan(h,plan)
	for row:Dictionary in data.records:
		var node:=Node3D.new();node.name="BentTimberPanel_%d_%d"%[row.lane,row.step];stage.add_child(node)
		var roof_faces:=PackedVector3Array();var wall_faces:=PackedVector3Array()
		for part:Dictionary in row.parts:
			var mesh:MeshInstance3D=r._triangles(node,part.vertices,Color.WHITE);mesh.name=part.name;mesh.material_override=dark if part.material=="dark" else wood
			if part.roof_skin:roof_faces.append_array(PackedVector3Array(part.vertices))
			else:wall_faces.append_array(PackedVector3Array(part.vertices))
		_pick(node,h,row.cell,roof_faces,true);_pick(node,h,row.cell,wall_faces,false)
	root.set_meta("acoustic_roof_pitch",{"apex":data.apex,"degrees":float(h.roof_pitch.degrees)})
	root.set_meta("roof_pitch",h.roof_pitch.duplicate(true))
static func _pick(parent:Node3D,h:Dictionary,cell:Dictionary,faces:PackedVector3Array,roof:bool)->void:
	if faces.is_empty():return
	var body:=StaticBody3D.new();body.name="AcousticRoofPick" if roof else "AcousticReflectorPick";parent.add_child(body)
	body.set_meta("house_id",str(h.id));body.set_meta("cell_id",str(cell.id));body.set_meta("cell",cell.duplicate(true))
	if roof:body.set_meta("roof_surface",true)
	var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(faces)
	var collision:=CollisionShape3D.new();collision.name="AcousticRoofSurface" if roof else "AcousticReflectorSurface";collision.shape=shape;body.add_child(collision)
