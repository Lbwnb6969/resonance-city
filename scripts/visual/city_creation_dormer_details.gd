extends RefCounted
const Choice=preload("res://scripts/world/city_creation_architecture_variants.gd")
const Sites=preload("res://scripts/visual/city_creation_dormer_sites.gd")
const Wall=preload("res://scripts/visual/city_creation_wall_material.gd")
const Shapes = preload("res://scripts/world/city_creation_roof_detail_shapes.gd")
const Parts = preload("res://scripts/visual/city_creation_roof_detail_mesh.gd")
const Materials = preload("res://scripts/visual/city_creation_detail_materials.gd")
static func build(r,parent:Node3D,house:Dictionary,palette:Array)->void:
	var key:=Choice.dormer(house)
	if not Choice.dormer_supported(r.state,house):return
	parent.set_meta("roof_detail",{"version":1,"id":key,"active":false})
	if key=="off":return
	var diagnostics:Dictionary={};var site:=Sites.plan(r.state,parent,house,diagnostics)
	if site.is_empty():parent.set_meta("roof_detail",{"id":key,"active":false,"dormant_reason":"roof_site_unavailable","rejected":diagnostics});return
	var node:=Node3D.new();node.name="DormerDetail_"+key;parent.add_child(node);node.position=Vector3(site.at.x,site.low-.015,site.at.y)
	var materials := {
		"cream": Wall.component(r, palette[0], Wall.Kind.STONE),
		"wood": Materials.frame(r, house, palette),
		"tile": Materials.roof(r, house, palette),
		"glass": Parts.glass_material(),
	}
	for part: Dictionary in Shapes.dormer(site, key):
		Parts.build(r, node, part, materials[part.material], palette[1] if part.material == "tile" else palette[0])
	var body:=StaticBody3D.new();body.name="DormerPick";node.add_child(body);body.set_meta("house_id",house.id);body.set_meta("cell_id",site.cell_id);body.set_meta("roof_detail",key)
	for cell:Dictionary in house.cells:
		if str(cell.id)==site.cell_id:body.set_meta("cell",cell.duplicate(true));break
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true;shape.set_faces(mesh.mesh.get_faces());var collider:=CollisionShape3D.new();collider.shape=shape;collider.transform=node.global_transform.affine_inverse()*mesh.global_transform;body.add_child(collider)
	preload("res://scripts/visual/city_creation_roof_window_glow.gd").record(parent,node,"dormer")
	node.set_meta("roof_detail",site.merged({"id":key,"seed":Choice.record(house,"dormer").seed}));parent.set_meta("roof_detail",{"version":1,"id":key,"active":true,"site":site})
