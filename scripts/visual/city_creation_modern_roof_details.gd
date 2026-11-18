extends RefCounted
## Publish the same immutable detail plan used by bridge clearance.
const Plan=preload("res://scripts/world/city_creation_modern_roof_details.gd")
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Materials=preload("res://scripts/visual/city_creation_detail_materials.gd")
const Parts = preload("res://scripts/visual/city_creation_roof_detail_mesh.gd")
static func build(r,parent:Node3D,house:Dictionary,p:Array,shared:Dictionary={})->void:
	var plan:Dictionary=Plan.plan(r.state,house) if shared.is_empty() else shared
	for item:Dictionary in plan.details:
		var slot:String=item.slot;var key:String=item.id;var metadata:Dictionary={"version":1,"id":key,"active":item.active}
		if slot=="chimney_detail":parent.set_meta("chimneys",item.outlets.duplicate())
		if not item.active:
			if key!="off":metadata.merge({"dormant_reason":"exposed_trim_missing" if slot=="gable_trim" else "roof_site_unavailable","rejected":item.get("rejected",{})})
			parent.set_meta(slot,metadata);continue
		var node:=Node3D.new();node.name=("GableTrim_" if slot=="gable_trim" else "DormerDetail_" if slot=="roof_detail" else "ChimneyDetail_")+key;parent.add_child(node);node.position=item.origin
		var materials:=palette(r,house,p,key);var bodies:Dictionary={}
		for part:Dictionary in item.parts:
			var mesh := Parts.build(r, node, part, materials[part.material], p[0])
			if slot=="gable_trim":mesh.set_meta("trim_cell_id",str(part.cell_id))
		if slot=="gable_trim":preload("res://scripts/visual/city_creation_gable_trim.gd").merge_parts(r,node)
		for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
			var cell_id:String=mesh.get_meta("trim_cell_id",item.get("site",{}).get("cell_id",""))
			if not bodies.has(cell_id):
				var body:=StaticBody3D.new();body.name="ModernDetailPick_"+cell_id;node.add_child(body);body.set_meta("house_id",house.id);body.set_meta("cell_id",cell_id);body.set_meta("roof_surface",true);body.set_meta(slot,key);bodies[cell_id]=body
				for cell:Dictionary in house.cells:
					if str(cell.id)==cell_id:body.set_meta("cell",cell.duplicate(true));break
			var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(mesh.mesh.get_faces());var collision:=CollisionShape3D.new();collision.shape=shape;collision.transform=mesh.transform;bodies[cell_id].add_child(collision)
		if slot=="roof_detail":preload("res://scripts/visual/city_creation_roof_window_glow.gd").record(parent,node,"modern_roof")
		if slot=="gable_trim":metadata.merge({"parts":item.records,"seed":item.seed})
		else:
			metadata.site=item.site.duplicate(true)
			if slot=="chimney_detail":metadata.outlets=item.outlets.duplicate()
			var local:Dictionary=item.site.duplicate(true);local.id=key
			if slot=="chimney_detail":local.top=item.top;local.outlets=item.outlets.map(func(point):return point-Vector3(item.origin))
			else:local.seed=item.seed
			node.set_meta(slot,local)
		parent.set_meta(slot,metadata)
static func palette(r,h:Dictionary,p:Array,key:String)->Dictionary:
	return {"cream":Wall.component(r,p[0],Wall.Kind.STONE),"wood":Materials.frame(r,h,p),"tile":Materials.roof(r,h,p),"glass":Parts.glass_material(),"brick":Wall.component(r,p[0].darkened(.06),Wall.Kind.STONE),"stone":Wall.component(r,p[0].lightened(.045),Wall.Kind.STONE),"clay":Wall.component(r,p[1],Wall.Kind.TERRACOTTA),"copper":Wall.component(r,Color("6a8877"),Wall.Kind.METAL),"trim":Wall.component(r,p[2],Wall.Kind.TIMBER) if key=="timber_verge" else Wall.component(r,p[0].lightened(.045),Wall.Kind.STONE)}
