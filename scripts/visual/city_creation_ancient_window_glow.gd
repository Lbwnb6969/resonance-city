extends RefCounted
## Follow the actual arched facade's shutter panes, including its street rhythm.
static func face(rig,root:Node3D,cell:Dictionary,side:Vector2i,surface:SurfaceTool,windows:Array)->bool:
	for panes:Dictionary in root.get_meta("ancient_window_panes",[]):
		if panes.cell_id!=str(cell.id) or panes.side!=side:continue
		var frame:Transform3D=panes.frame
		for pane:Dictionary in panes.windows:
			if pane.has("outline"):
				var poly:PackedVector2Array=pane.outline;var indices:=Geometry2D.triangulate_polygon(poly)
				for i in range(0,indices.size(),3):
					var points:Array=[]
					for k in range(3):var p:=poly[indices[i+k]];points.append(frame*Vector3(p.x,p.y,pane.at.z))
					rig._tri(surface,points,0)
			else:rig._panel(surface,frame,pane.at,pane.size,0)
			windows.append({"cell_id":str(cell.id),"side":side,"at":frame*Vector3(pane.at),"size":pane.size})
		return true
	return false
