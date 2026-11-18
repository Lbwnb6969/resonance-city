extends RefCounted
## CPU plans publish through the established material, batching and picking path.
const Geometry=preload("res://scripts/world/city_creation_clockwork_roof_pitch.gd")
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Pick=preload("res://scripts/visual/city_creation_roof_pick.gd")
const FacadeGlass=preload("res://scripts/visual/city_creation_facade_glass.gd")
static func build(r,root:Node3D,h:Dictionary,data:Dictionary)->void:
	var node:=Node3D.new();node.name="ClockworkPitchedRoof_"+str(data.cell.id);root.add_child(node)
	var colors:Array=r.HouseColors.era_palette(r,h,r.HouseColors.base_palette(r,h),h.has("custom_colors"));var materials:Dictionary={"mansard":Wall.component(r,colors[1] if h.get("architecture","")=="recessed_townhouse" else Color("45585c"),Wall.Kind.SLATE),"slate":Wall.component(r,Color("43585b"),Wall.Kind.SLATE),"stone":Wall.component(r,Color("d9c6a3"),Wall.Kind.STONE),"warm_stone":Wall.component(r,Color("ddcba7"),Wall.Kind.STONE),"copper":preload("res://scripts/visual/city_creation_clockwork_parts.gd").metal(r,Color("a88c58")),"iron":preload("res://scripts/visual/city_creation_clockwork_parts.gd").metal(r,Color("40524f")),"glass":r.conservatory.ensure_roof_material(true),"window_glass":FacadeGlass.material(r,2),"leaf":Wall.component(r,Color("6b8855"),Wall.Kind.PLASTER)}
	if data.prototype=="sawtooth_atrium":materials.merge(preload("res://scripts/visual/city_creation_clockwork_parts.gd").atrium_materials(r))
	var highest:=-INF;var peaks:Array[Vector3]=[];var surface:Array[Vector3]=[]
	for part:Dictionary in data.parts:
		surface.append_array(part.vertices)
		var mesh:MeshInstance3D=r._triangles(node,part.vertices,Color.WHITE);mesh.name=part.name;mesh.material_override=materials[part.material]
		if part.roof_skin:mesh.set_meta("creation_detail_roof",true);mesh.set_meta("creation_detail_cell",str(data.cell.id))
		if part.material in ["glass","window_glass"]:mesh.set_meta("creation_live_visual",true);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if part.material=="window_glass":mesh.set_meta("creation_roof_window_glass",true)
		if part.roof_skin or part.name=="CopperClockSpire":
			for point:Vector3 in part.vertices:
				if point.y>highest+.00001:highest=point.y;peaks.clear()
				if absf(point.y-highest)<.00001 and not peaks.has(point):peaks.append(point)
	var body:=StaticBody3D.new();body.set_meta("roof_surface",true);body.set_meta("house_id",h.id);body.set_meta("cell_id",str(data.cell.id));body.set_meta("cell",data.cell.duplicate(true));node.add_child(body);Pick.from_geometry(body,node,"ClockworkRoofPitchPick")
	var apex:=Vector3.ZERO
	for point:Vector3 in peaks:apex+=point
	if not peaks.is_empty():apex/=peaks.size()
	apex.y=preload("res://scripts/visual/city_creation_dormer_sites.gd").height(surface,Vector2(apex.x,apex.z))
	var prior:Dictionary=root.get_meta("clockwork_roof_pitch",{})
	if prior.is_empty() or apex.y>float(prior.apex.y):root.set_meta("clockwork_roof_pitch",{"apex":apex,"degrees":float(h.roof_pitch.degrees)})
	root.set_meta("roof_pitch",h.roof_pitch.duplicate())
	if data.prototype!="mansard":
		var records:Array=root.get_meta("clockwork_prototypes",[]);records.append(data.metadata);root.set_meta("clockwork_prototypes",records);root.set_meta("prototype_caption",preload("res://scripts/world/city_creation_architecture_choice.gd").label(str(data.prototype)))
	if data.prototype=="guild_arcade" and data.feature:
		var arcade:=Node3D.new();arcade.name="ClockworkGroundArcade";arcade.position=Vector3(data.center.x,data.base,data.center.y);root.add_child(arcade);preload("res://scripts/visual/city_creation_clockwork_prototypes.gd").arcade(r,arcade,h,data,materials.stone)
	preload("res://scripts/visual/city_creation_roof_window_glow.gd").record(root,node,"clockwork_roof")
