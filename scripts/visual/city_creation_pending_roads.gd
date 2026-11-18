extends RefCounted
## Committed road surfaces stay visible until the atomic renderer catches up.
## These nodes have no collision and never enter State or authored history.
var renderer:Node3D
var root:Node3D
var rows:Array[Dictionary]=[]
func clear()->void:
	if is_instance_valid(renderer):renderer.set_meta("pending_road_masks",[])
	if is_instance_valid(root):root.get_parent().remove_child(root);root.queue_free()
	rows.clear();renderer=null;root=null
func keep(demo:Node,road:Dictionary)->void:
	if renderer!=demo.town:clear();renderer=demo.town
	if not is_instance_valid(root):
		root=Node3D.new();root.name="PendingRoadSurfaces";renderer.add_child(root)
	var node:=Node3D.new();node.name=str(road.id);root.add_child(node)
	# Freeze the mask/material before another pen stroke updates its texture.
	var frozen:ShaderMaterial=renderer.road_draft_field.material.duplicate()
	frozen.set_shader_parameter("draft_field",ImageTexture.create_from_image(renderer.road_draft_field.image))
	for child:Node in renderer.preview.get_children():
		if str(child.name)=="ChemistryGhost":continue
		renderer.preview.remove_child(child);node.add_child(child);_freeze(child,frozen)
	rows.append({"road":road.duplicate(true),"node":node})
	_masks()
func _freeze(node:Node,material:ShaderMaterial)->void:
	if node is MeshInstance3D and node.material_override==renderer.road_draft_field.material:node.material_override=material
	for child:Node in node.get_children():_freeze(child,material)
func _masks()->void:
	var masks:Array=[]
	for row:Dictionary in rows:
		var points:Array[Vector2]=[]
		for p:Array in row.road.points:points.append(Vector2(p[0],p[1]))
		masks.append({"points":points,"width":row.road.width})
	renderer.set_meta("pending_road_masks",masks)
func tick(demo:Node)->void:
	if rows.is_empty():return
	if renderer!=demo.town:clear();return
	var published:Array=renderer.budget_rebuild._published_snapshot.get("roads",[])
	var changed:=false
	for i:int in range(rows.size()-1,-1,-1):
		var road:Dictionary=rows[i].road
		if demo.state.roads.has(road) and not published.has(road):continue
		var node:Node=rows[i].node;node.get_parent().remove_child(node);node.queue_free();rows.remove_at(i);changed=true
	if changed:
		_masks()
		if not demo.road_drawing:renderer.road_draft_field.clear(renderer)
