extends "res://tools/check_creation_road_staging_live.gd"
func mesh_signatures()->Dictionary:
	var result:=super.mesh_signatures()
	for id:String in ["r7","r20"]:
		var node:MeshInstance3D=demo.town.road_roots[id].get_node_or_null("SoftRoadEdge")
		check(node!=null and node.mesh.get_surface_count()==1,"real300 soft road edge publishes "+id)
	return result
