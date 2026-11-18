extends RefCounted
## Roofs, clerestories and end walls consume the same clipped CPU triangles.
const Geometry=preload("res://scripts/world/city_creation_basilica_roof_pitch.gd")
const Meshes=preload("res://scripts/visual/city_creation_ancient_civic_mesh.gd")
static func build(r,parent:Node3D,h:Dictionary,palette:Array,plan:Dictionary)->void:
	parent.set_meta("rigid_architecture",true)
	var data:=Geometry.from_plan(h,plan);var mass:Node3D=parent.find_child("RomanBasilicaMassing",true,false);var root:=Node3D.new();root.name="BasilicaPitchedRoof";mass.add_child(root)
	var stone:=Meshes.stone(palette[0]);stone.cull_mode=BaseMaterial3D.CULL_DISABLED
	var glass:Material=r._material(palette[2].darkened(.42)).duplicate();glass.roughness=.35
	for row:Dictionary in data.records:
		var node:=Node3D.new();node.name="BasilicaPitchedCell_"+str(row.cell.id);root.add_child(node);var roof_faces:=PackedVector3Array();var wall_faces:=PackedVector3Array()
		for part:Dictionary in row.parts:
			var mesh:MeshInstance3D
			if part.roof_skin:mesh=Meshes.tiled(r,node,part.vertices,part.uv,palette[1],str(part.name));roof_faces.append_array(PackedVector3Array(part.vertices))
			else:
				var center:=Vector3.ZERO;var vertices:Array[Vector3]=[]
				if part.material=="glass":
					for point:Vector3 in part.vertices:center+=point
					center/=part.vertices.size()
				for point:Vector3 in part.vertices:vertices.append(point-center)
				mesh=r._triangles(node,vertices,palette[0]);mesh.position=center;mesh.name=str(part.name);mesh.material_override=glass if part.material=="glass" else stone;wall_faces.append_array(PackedVector3Array(part.vertices))
				if part.material=="glass":mesh.set_meta("basilica_civic_pane",_pane(part,center))
		_pick(node,h,row.cell,roof_faces,true);_pick(node,h,row.cell,wall_faces,false)
	parent.set_meta("basilica_roof_pitch",{"apex":data.apex,"degrees":float(h.roof_pitch.degrees)})
	parent.set_meta("roof_pitch",h.roof_pitch.duplicate(true));parent.set_meta("ancient_roof_patches",data.patches.size())
	parent.set_meta("roman_basilica",{"floors":plan.floors,"nave_height":data.ridge,"apse_radius":data.apse_radius,"open_door_width":minf(.40,float(plan.width)*.5*.48)*2.})
static func _pick(parent:Node3D,h:Dictionary,cell:Dictionary,faces:PackedVector3Array,roof:bool)->void:
	if faces.is_empty():return
	var body:=StaticBody3D.new();body.name="BasilicaRoofPick" if roof else "BasilicaUpperWallPick";parent.add_child(body);body.set_meta("house_id",str(h.id));body.set_meta("cell_id",str(cell.id));body.set_meta("cell",cell.duplicate(true))
	if roof:body.set_meta("roof_surface",true)
	var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(faces);var collision:=CollisionShape3D.new();collision.name="BasilicaRoofSurface" if roof else "BasilicaUpperWallSurface";collision.shape=shape;body.add_child(collision)

static func _pane(part:Dictionary,center:Vector3)->Dictionary:
	var normal:=Vector3(signf(center.x),0,0);var outside:=-INF if normal.x>0. else INF
	for point:Vector3 in part.vertices:outside=maxf(outside,point.x) if normal.x>0. else minf(outside,point.x)
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF);var found:=false
	for i in range(0,part.vertices.size(),3):
		if absf(part.vertices[i].x-outside)>.000001 or absf(part.vertices[i+1].x-outside)>.000001 or absf(part.vertices[i+2].x-outside)>.000001:continue
		found=true
		for j in range(3):var point:Vector3=part.vertices[i+j];low=low.min(Vector2(point.z,point.y));high=high.max(Vector2(point.z,point.y))
	if not found:return {"visible":false}
	var middle:Vector2=(low+high)*.5
	return {"visible":true,"at":Vector3(outside,middle.y,middle.x)-center,"normal":normal,"size":high-low-Vector2.ONE*.02}
