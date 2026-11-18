extends RefCounted
## Publish the same CPU surfaces with established tile, stone and glass materials.
const Geometry=preload("res://scripts/world/city_creation_renaissance_roof_pitch.gd")
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Sites=preload("res://scripts/visual/city_creation_dormer_sites.gd")
const Pick=preload("res://scripts/visual/city_creation_roof_pick.gd")
static func build(r,parent:Node3D,h:Dictionary)->void:
	var plan:=Geometry.for_house(r.state,h);var custom:bool=h.architecture in ["stepped_guildhouse","corner_loggia_tower"];var palette:Array=r.HouseColors.era_palette(r,h,r.HouseColors.base_palette(r,h),h.has("custom_colors"));var tile:Material
	if custom:
		var tiles:=ShaderMaterial.new();tiles.shader=r.JoinedRoofShader;tiles.set_shader_parameter("roof_color",palette[1]);tile=tiles
	else:tile=Wall.component(r,palette[1],Wall.Kind.TERRACOTTA)
	var materials:Dictionary={"stone":Wall.component(r,palette[0].lerp(Color("ecdfc5"),.7) if custom else Color("e8d7b7"),Wall.Kind.STONE),"plaster":Wall.component(r,palette[0],Wall.Kind.PLASTER),"tile":tile,"wood":Wall.component(r,palette[2],Wall.Kind.TIMBER),"iron":Wall.component(r,Color("4a504a"),Wall.Kind.METAL),"glass":preload("res://scripts/visual/city_creation_facade_glass.gd").material(r,0)}
	if not custom:materials.stone=materials.stone.duplicate();materials.stone.set_meta("creation_fixed_color",true)
	var records:Array=[];var highest:=-INF;var apex:=Vector3.ZERO;var all:Array[Vector3]=[]
	for row:Dictionary in plan.records:
		var node:=Node3D.new();node.name="RenaissancePitchedRoof_"+str(row.cell.id);parent.add_child(node);var peaks:Array[Vector3]=[];var high:=-INF
		for part:Dictionary in row.parts:
			var mesh:MeshInstance3D=r._roof_surface(node,part.vertices,palette[1]) if part.material=="tile" and custom else r._triangles(node,part.vertices,Color.WHITE);mesh.name=part.name;mesh.material_override=materials[part.material];all.append_array(part.vertices)
			if part.material=="glass":mesh.set_meta("creation_live_visual",true)
			if part.roof_skin:
				for point:Vector3 in part.vertices:
					if point.y>high+.00001:high=point.y;peaks.clear()
					if absf(point.y-high)<.00001 and not peaks.has(point):peaks.append(point)
		preload("res://scripts/visual/city_creation_roof_window_glow.gd").record(parent,node,"renaissance_roof")
		var body:=StaticBody3D.new();body.set_meta("roof_surface",true);body.set_meta("house_id",h.id);body.set_meta("cell_id",str(row.cell.id));body.set_meta("cell",row.cell.duplicate(true));node.add_child(body);Pick.from_geometry(body,node,"RenaissanceRoofPitchPick");records.append(row.metadata.duplicate(true))
		if high>highest and not peaks.is_empty():
			highest=high;apex=Vector3.ZERO
			for point:Vector3 in peaks:apex+=point
			apex/=peaks.size()
	if highest>-INF:apex.y=Sites.height(all,Vector2(apex.x,apex.z));parent.set_meta("renaissance_roof_pitch",{"apex":apex,"degrees":float(h.roof_pitch.degrees)})
	parent.set_meta("roof_pitch",h.roof_pitch.duplicate());parent.set_meta("chimneys",plan.outlets.duplicate())
	var label:=preload("res://scripts/world/city_creation_architecture_choice.gd").label(str(h.architecture))
	if h.architecture=="stepped_guildhouse":parent.set_meta("stepped_guildhouse",records);label="阶梯山墙行会"
	elif h.architecture=="corner_loggia_tower":parent.set_meta("corner_loggia",records);parent.set_meta("corner_loggia_clear",not plan.crown.is_empty());parent.set_meta("rigid_architecture",true);label="街角双向连拱望楼" if not plan.crown.is_empty() else "连拱望楼 · 顶部外角净空不足"
	else:parent.set_meta("renaissance_prototypes",records)
	parent.set_meta("prototype_caption",label)
