extends RefCounted
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
static func configure(renderer,job)->void:
	if Pitch.guildhall(job.house,renderer.state) or Pitch.basilica(job.house,renderer.state) or Pitch.stoa(job.house,renderer.state) or Pitch.renaissance_special(job.house,renderer.state):return
	if Pitch.modern(job.house,renderer.state) or Pitch.clockwork(job.house,renderer.state):return
	if job.house.get("style","")=="round_tower":return
	if not Pitch.active(renderer.state,job.house):return
	job.joined=true;job.tower_ids.clear();job.domes.clear();job.dome_cells.clear();job.root.set_meta("joined_roof",true);job.root.set_meta("dome_cells",{});job.root.set_meta("roof_pitch",job.house[Pitch.FIELD].duplicate())
static func finish(renderer,job)->void:
	if Pitch.guildhall(job.house,renderer.state) or Pitch.basilica(job.house,renderer.state) or Pitch.stoa(job.house,renderer.state) or Pitch.renaissance_special(job.house,renderer.state):return
	if Pitch.modern(job.house,renderer.state) or Pitch.clockwork(job.house,renderer.state):return
	if job.house.get("style","")=="round_tower":return
	if not Pitch.active(renderer.state,job.house):return
	var faces:=PackedVector3Array();var groups:Dictionary={};var cells:Dictionary={}
	var inverse:Transform3D=job.root.global_transform.affine_inverse()
	for mesh:MeshInstance3D in job.root.find_children("*","MeshInstance3D",true,false):
		if String(mesh.name)!="JoinedRoofSurface" and String(mesh.name)!="GreekContinuousTileRoof" and not String(mesh.name).begins_with("AncientLowTileRoof"):continue
		for p:Vector3 in mesh.mesh.get_faces():faces.append(inverse*mesh.global_transform*p)
	for cell:Dictionary in job.house.cells:
		if cell.kind=="room":cells[str(cell.id)]=cell
	for i in range(0,faces.size(),3):
		var center:Vector3=(faces[i]+faces[i+1]+faces[i+2])/3.;var closest:="";var distance:=INF
		for id:String in cells:
			var at:Vector2=Pitch.Frame.Hinge.point(job.house,Vector2(job.house.origin[0]+cells[id].x*1.8,job.house.origin[1]+cells[id].z*1.8))
			var delta:float=Vector2(center.x,center.z).distance_squared_to(at)+pow(center.y-(float(job.house.get("base_y",0.))+(int(cells[id].level)+1)*1.7),2.)*.01
			if delta<distance:closest=id;distance=delta
		if not groups.has(closest):groups[closest]=PackedVector3Array()
		for j in range(3):groups[closest].append(faces[i+j])
	for id:String in groups:
		var body:=StaticBody3D.new();body.set_meta("roof_surface",true);body.name="RoofPitchPick_"+id;body.set_meta("house_id",job.house.id);body.set_meta("cell_id",id);body.set_meta("cell",cells[id].duplicate(true));job.root.add_child(body)
		var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(groups[id]);var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
		if job.hidden:renderer._hold_house_body(body)
