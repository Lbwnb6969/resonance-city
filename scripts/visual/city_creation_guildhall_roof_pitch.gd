extends RefCounted
const Geo=preload("res://scripts/world/city_creation_guildhall_roof_pitch.gd")
const Meshes=preload("res://scripts/visual/city_creation_ancient_civic_mesh.gd")
static func build(r,parent:Node3D,h:Dictionary,palette:Array)->void:
 var data:=Geo.for_house(r.state,h);var node:=Node3D.new();node.name="GuildPitchRoofs";parent.add_child(node);parent.set_meta("rigid_architecture",true)
 var stone:=Meshes.stone(palette[0].lerp(Color("dfcfb1"),.65))
 for patch:Dictionary in data.patches:
  var faces:Array[Vector3]=[];faces.assign(patch.vertices)
  if patch.material=="tile":Meshes.tiled(r,node,faces,patch.uv,palette[1],str(patch.part))
  else:
   var mesh:MeshInstance3D=r._triangles(node,faces,palette[0]);mesh.material_override=stone;mesh.name=str(patch.part)
  var cell:Dictionary=h.cells.filter(func(c):return str(c.id)==str(patch.cell_id))[0]
  var body:=StaticBody3D.new();body.name="GuildPitchRoofPick" if patch.roof_skin else "GuildPitchEndPick";node.add_child(body)
  body.set_meta("house_id",h.id);body.set_meta("cell_id",cell.id);body.set_meta("cell",cell.duplicate(true))
  if patch.roof_skin:body.set_meta("roof_surface",true)
  var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(PackedVector3Array(faces));var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
 parent.set_meta("guildhall_roof_pitch",{"apex":data.apex,"degrees":h.roof_pitch.degrees});parent.set_meta("roof_pitch",h.roof_pitch.duplicate(true))

static func original_anchor(root:Node3D,hall:Node3D)->Vector3:
 var inverse:=root.global_transform.affine_inverse();var high:=-INF;var result:=Vector3.ZERO
 for mesh:MeshInstance3D in hall.get_children().filter(func(n):return n is MeshInstance3D):
  if str(mesh.name)=="GuildhallRaisedNave" or not mesh.mesh is ArrayMesh:continue
  var pose:=inverse*mesh.global_transform;var faces:=mesh.mesh.get_faces()
  for i in range(0,faces.size(),3):
   var center:Vector3=pose*((faces[i]+faces[i+1]+faces[i+2])/3.);var normal:Vector3=(faces[i+1]-faces[i]).cross(faces[i+2]-faces[i])
   if absf(normal.y)>.000001 and center.y>high:high=center.y;result=center
 return result
