extends RefCounted
## Capture the actual facade glass before batching removes temporary wall nodes.
const Glass=preload("res://scripts/visual/shaders/creation_conservatory_glass.gdshader")
static func record(root:Node3D,wall:Node3D,cell:Dictionary,side:Vector2i)->void:
	if not wall.has_meta("modern_glass"):return
	var panes:Array=[];var inverse:=root.global_transform.affine_inverse()
	for mesh:MeshInstance3D in wall.find_children("*","MeshInstance3D",true,false):
		if not mesh.material_override is ShaderMaterial or mesh.material_override.shader!=Glass:continue
		var bounds:=mesh.mesh.get_aabb();var frame:Transform3D=inverse*mesh.global_transform
		panes.append({"frame":frame,"at":Vector3(bounds.get_center().x,bounds.get_center().y,bounds.end.z+.002),"size":Vector2(bounds.size.x,bounds.size.y)})
	var faces:Array=root.get_meta("modern_window_panes",[])
	faces.append({"cell_id":str(cell.id),"side":side,"panes":panes})
	root.set_meta("modern_window_panes",faces)
static func face(rig,root:Node3D,cell:Dictionary,side:Vector2i,surface:SurfaceTool,windows:Array)->bool:
	for record:Dictionary in root.get_meta("modern_window_panes",[]):
		if record.cell_id!=str(cell.id) or record.side!=side:continue
		for pane:Dictionary in record.panes:
			rig._panel(surface,pane.frame,pane.at,pane.size,0,1.)
			windows.append({"cell_id":str(cell.id),"side":side,"at":pane.frame*Vector3(pane.at),"size":pane.size})
		# A cedar door face can have no pane; it must not acquire a floating lamp.
		return true
	return false
