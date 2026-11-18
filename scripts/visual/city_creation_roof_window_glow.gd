extends RefCounted
## Reuses exact published glass triangles for the night response rig.
static func record(root:Node3D,owner:Node3D,source:String,name_filter:String="")->void:
	var panes:Array=root.get_meta("roof_window_panes",[])
	for mesh:MeshInstance3D in owner.find_children("*","MeshInstance3D",true,false):
		if not name_filter.is_empty() and not str(mesh.name).begins_with(name_filter):continue
		var material:Material=mesh.material_override
		if material==null and not mesh.has_meta("creation_roof_window_glass"):continue
		if material!=null and not material.has_meta("creation_facade_glass") and not mesh.has_meta("creation_roof_window_glass"):continue
		var transform:=_relative_transform(root,mesh);var faces:=_broad_faces(mesh.mesh.get_faces(),transform)
		if not faces.is_empty():
			var row:Dictionary={"source":source,"faces":faces}
			if owner.has_meta("layered_window"):
				var spec:Dictionary=owner.get_meta("layered_window");row["cell_id"]=str(spec.get("cell_id",""));row["side"]=Vector2i(roundi(owner.basis.z.x),roundi(owner.basis.z.z))
			if owner.has_meta("organic_facade"):
				var facade:Dictionary=owner.get_meta("organic_facade");row["cell_id"]=str(facade.get("cell_id",""));row["side"]=facade.get("side",Vector2i.ZERO)
			if owner.has_meta("guild_shop_window"):
				row["cell_id"]=str(owner.get_parent().name);row["side"]=Vector2i(roundi(owner.basis.z.x),roundi(owner.basis.z.z))
			if owner.has_meta("timber_service_entry"):
				var entry: Dictionary = owner.get_meta("timber_service_entry")
				row["cell_id"] = entry.cell_id
				row["side"] = entry.side
			panes.append(row)
	root.set_meta("roof_window_panes",panes)

static func record_mesh(root:Node3D,mesh:MeshInstance3D,source:String)->void:
	var transform:=_relative_transform(root,mesh);var faces:=_broad_faces(mesh.mesh.get_faces(),transform)
	if faces.is_empty():return
	var panes:Array=root.get_meta("roof_window_panes",[]);panes.append({"source":source,"faces":faces});root.set_meta("roof_window_panes",panes)

static func _relative_transform(root:Node3D,mesh:Node3D)->Transform3D:
	var result:=mesh.transform;var cursor:Node=mesh.get_parent()
	while cursor!=null and cursor!=root:
		result=cursor.transform*result;cursor=cursor.get_parent()
	return result

static func _broad_faces(raw:PackedVector3Array,transform:Transform3D)->PackedVector3Array:
	var max_area:=0.
	for i in range(0,raw.size(),3):max_area=maxf(max_area,(transform*raw[i+1]-transform*raw[i]).cross(transform*raw[i+2]-transform*raw[i]).length())
	var result:=PackedVector3Array()
	for i in range(0,raw.size(),3):
		var a:=transform*raw[i];var b:=transform*raw[i+1];var c:=transform*raw[i+2]
		if (b-a).cross(c-a).length()>=max_area*.70:result.append_array([a,b,c])
	return result
