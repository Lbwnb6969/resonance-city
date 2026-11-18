extends RefCounted
const Geometry=preload("res://scripts/world/city_creation_modern_roof_pitch.gd")
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Pick=preload("res://scripts/visual/city_creation_roof_pick.gd")
static func build(r,root:Node3D,house:Dictionary,p:Array,cell:Dictionary)->Dictionary:
	var plan:=Geometry.cell_plan(r.state,house,cell);var node:Node3D=root.get_node(str(cell.id));var frame:=Node3D.new();frame.name="ModernPitchedRoof_"+str(cell.id);node.add_child(frame);frame.rotation.y=atan2(float(plan.front.x),float(plan.front.y))
	var materials:Dictionary={"slate":Wall.source(p[1] if house.get("architecture","")=="recessed_townhouse" else Color("52636a"),null,"component",Wall.Kind.SLATE),"wood":Wall.source(p[2].lerp(Color("95653f"),.65),null,"component",Wall.Kind.STONE),"stone":Wall.source(p[0].lerp(Color("b8b3a0"),.55),null,"component",Wall.Kind.STONE),"green":Wall.source(Color("748553"),null,"component",Wall.Kind.STONE),"glass":r.conservatory.ensure_material(true)}
	var highest:=-INF;var apex:=Vector3.ZERO;var peaks:Array[Vector3]=[];var ridge_x:=0.
	for part:Dictionary in plan.parts:
		if part.type=="garden":
			var garden:=Node3D.new();garden.name="PitchedRoofGarden";garden.position=part.at;garden.scale=Vector3.ONE*.62;frame.add_child(garden);preload("res://scripts/visual/city_creation_modern_archetypes.gd").populate_roof(r,garden,house,cell,0.,p);continue
		var mesh:MeshInstance3D
		if part.type=="crown":mesh=r._crown(frame,part.at,part.size,Color("8a9b58"));mesh.rotation=part.rotation
		elif part.type=="box":mesh=r._box(frame,part.size,part.at,materials[part.material]);mesh.rotation=part.rotation
		else:mesh=r._triangles(frame,part.vertices,Color.WHITE);mesh.material_override=materials[part.material]
		if part.material=="slate":preload("res://scripts/visual/city_creation_slate_finish.gd").apply(mesh)
		mesh.name="ModernPitch_"+str(part.name)
		if part.material=="glass":mesh.set_meta("creation_live_visual",true)
		if part.material in ["slate","green"]:
			mesh.set_meta("creation_detail_roof",true);mesh.set_meta("creation_detail_cell",str(cell.id))
			for point:Vector3 in Geometry.vertices(part):
				if point.y>highest+.00001:highest=point.y;peaks.clear();ridge_x=point.x
				var candidate:Vector3=node.position+frame.basis*point
				if absf(point.y-highest)<.00001 and (plan.kind!=4 or point.x*ridge_x>0.) and not peaks.has(candidate):peaks.append(candidate)
		if part.name=="ModernChimneyCap":root.set_meta("chimneys",[node.position+frame.basis*(part.at+Vector3.UP*.045)])
	var body:=StaticBody3D.new();body.set_meta("roof_surface",true);body.set_meta("house_id",str(house.id));body.set_meta("cell_id",str(cell.id));body.set_meta("cell",cell.duplicate(true));frame.add_child(body);Pick.from_geometry(body,frame,"ModernRoofPitchPick")
	for point:Vector3 in peaks:apex+=point
	if not peaks.is_empty():apex/=peaks.size()
	var prior:Dictionary=root.get_meta("modern_roof_pitch",{})
	if prior.is_empty() or apex.y>float(prior.apex.y):root.set_meta("modern_roof_pitch",{"apex":apex,"degrees":plan.angle})
	root.set_meta("roof_pitch",house.roof_pitch.duplicate())
	return {"cell_id":str(cell.id),"roof_y":plan.roof_y,"alpine_kind":plan.kind,"front":plan.front,"joined_ends":plan.joined_ends,"lawn":plan.kind in [2,5],"degrees":plan.angle}
