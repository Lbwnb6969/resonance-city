extends RefCounted
## Resume one road component at a time inside the existing hidden staging tree.
const Bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd")
const LABELS=["surface","curbs","edge","stairs","earthworks","shore_bed","shore_collision","roundabouts","stepping","finish","tram","pebbles"]
static func begin(road:Dictionary,parent:Node3D)->Node3D:
	var root:=Node3D.new();root.name=str(road.id);parent.add_child(root);return root
static func install(r,road:Dictionary,data:Dictionary,parent:Node3D)->Node3D:
	var root:=begin(road,parent)
	while not advance(r,road,data,root,false):pass
	return root
static func advance(r,road:Dictionary,data:Dictionary,root:Node3D,staged:bool=true)->bool:
	var phase:int=root.get_meta("road_install_phase",0);var began:=Time.get_ticks_usec()
	match phase:
		0:
			if not data.arrays.is_empty():
				var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data.arrays)
				var surface:=MeshInstance3D.new();surface.mesh=mesh
				surface.material_override=r.promenade.road_material() if str(road.get("style","path")) in ["promenade","avenue","tram"] else r._shared_road_material()
				surface.name="PromenadeSurface" if str(road.get("style","path")) in ["promenade","avenue","tram"] else "PathSurface";root.add_child(surface)
		1:
			var batches:Dictionary={}
			for record:Array in data.curbs:r._append_road_box(batches,record[0],record[1],r._material(record[2]),record[3])
			for batch:Dictionary in batches.values():
				var instance:=MeshInstance3D.new();instance.mesh=batch.surface.commit();instance.material_override=batch.material;root.add_child(instance)
		2:root.set_meta("soft_edge",r.path_edge.install(r,data.edge,root))
		3:r.RoadStairs.install(r,root,data.stairs,road)
		4:r.RoadEarthworks.install(r,root,data.earthworks,road)
		5:Bed.mesh_for(root,data.earthworks.shore_bed,road,data.earthworks.shore_bed_mesh)
		6:Bed.collide(root,road,data.earthworks.shore_bed_mesh)
		7:r.RoundaboutVisual.install(r,root,data.roundabouts)
		8:r.Stepping.install(r,root,data.get("stepping_runs",[]),road)
		9:preload("res://scripts/visual/city_creation_road_finish.gd").install(r,root,road,data)
		10:r.TramTracks.install(r,root,data.tram)
		11:r._update_road_pebbles(road,root)
	if staged:
		for body:StaticBody3D in root.find_children("*","StaticBody3D",true,false):
			if not body.has_meta("pending_collision_layer"):
				body.set_meta("pending_collision_layer",body.collision_layer);body.collision_layer=0
	var rows:Dictionary=r.rebuild_stats.get("road_install_stages",{});var stages:Dictionary=rows.get(str(road.id),{})
	stages[LABELS[phase]]=(Time.get_ticks_usec()-began)/1000.;stages.total=float(stages.get("total",0.))+float(stages[LABELS[phase]])
	rows[str(road.id)]=stages;r.rebuild_stats.road_install_stages=rows
	root.set_meta("road_install_phase",phase+1);return phase+1==LABELS.size()
