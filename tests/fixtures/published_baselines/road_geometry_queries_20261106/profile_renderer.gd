extends "res://scripts/visual/city_creation_renderer.gd"
var query_count:=0
var query_usec:=0
func _street_height(at:Vector2)->float:
	var mark:=Time.get_ticks_usec();var value:=super._street_height(at);query_count+=1;query_usec+=Time.get_ticks_usec()-mark;return value
func _prepare_road_data(road: Dictionary) -> Dictionary:
	var started := Time.get_ticks_usec();var stage_mark:=started;var profile_times:Dictionary={}
	query_count=0;query_usec=0
	var material_code:=preload("res://scripts/world/city_creation_road_paving.gd").code(road)
	var samples: Array[Vector2] = _road_geometry(road).samples
	var width := float(road.width)
	var offsets := _road_offsets(samples,width)
	var curbs: Array = []
	var cuts: Array = []
	for marker: Dictionary in Roundabouts.all(state.roads): cuts.append([Roundabouts.polygon(marker.center,marker.radius-.025)])
	for other: Dictionary in state.roads:
		if int(str(other.id).substr(1)) < int(str(road.id).substr(1)) and _roads_touch(road,other): cuts.append(road_outlines[other.id])
	var profile: Dictionary = state.road_profile(road)
	var stepping_runs: Array=profile.get("stepping_runs",[])
	var stepping_cuts: Array=profile.stepping_cuts
	cuts.append_array(stepping_cuts)
	var stairs := RoadStairs.prepare(self,road,profile,cuts)
	# Adjacent tread masks form one floor cut; keep the individual tread
	# faces/colliders above unchanged. Do not scan every riser as a hole.
	var stair_cuts:Array=[]
	for cut:Array in stairs.cuts:_merge_water_group(stair_cuts,cut)
	cuts.append_array(stair_cuts)
	curbs.append_array(stairs.rails)
	profile_times.before_surface=(Time.get_ticks_usec()-stage_mark)/1000.;stage_mark=Time.get_ticks_usec()
	var vertices: Array[Vector3] = _road_surface_vertices(road_outlines[road.id],cuts)
	profile_times.surface=(Time.get_ticks_usec()-stage_mark)/1000.;profile_times.source_triangles=vertices.size()/3;stage_mark=Time.get_ticks_usec()
	# Height-aware streets require intermediate vertices even on dry land.
	if bool(road.get("bridge",false)) or bool(profile.get("elevated",false)): vertices = _subdivide_road(vertices)
	profile_times.subdivide=(Time.get_ticks_usec()-stage_mark)/1000.;profile_times.subdivided_triangles=vertices.size()/3;stage_mark=Time.get_ticks_usec()
	var bridge_spans: Array[Vector2] = Bridges.paving_spans(profile)
	var stone_spans: Array[Vector2] = Bridges.paving_spans(profile,true)
	var elevation:=preload("res://scripts/visual/city_creation_road_surface_heights.gd").prepare(self,samples,vertices,width,bridge_spans,stone_spans)
	var paving:Dictionary=elevation.paving
	var paving_uv:Dictionary=elevation.paving_uv
	profile_times.heights=(Time.get_ticks_usec()-stage_mark)/1000.;stage_mark=Time.get_ticks_usec()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0,vertices.size(),3):
		for vertex_index: int in [index,index+2,index+1]:
			var vertex := vertices[vertex_index]
			# Red blends the wet deck, green selects architectural stone. Timber
			# follows arc/across UVs; stone keeps world phase through bridgeheads.
			var at:=Vector2(vertex.x,vertex.z)
			var weight:Vector2=paving[at]
			surface.set_color(Color(weight.x,weight.y,material_code,1))
			surface.set_uv(paving_uv[at])
			surface.add_vertex(vertex)
	profile_times.emit=(Time.get_ticks_usec()-stage_mark)/1000.;stage_mark=Time.get_ticks_usec()
	surface.generate_normals()
	profile_times.normals=(Time.get_ticks_usec()-stage_mark)/1000.;stage_mark=Time.get_ticks_usec()
	surface.index()
	profile_times.index=(Time.get_ticks_usec()-stage_mark)/1000.;stage_mark=Time.get_ticks_usec()
	var arrays := surface.commit_to_arrays() if not vertices.is_empty() else []
	profile_times.commit_arrays=(Time.get_ticks_usec()-stage_mark)/1000.;stage_mark=Time.get_ticks_usec()
	var curb_started := Time.get_ticks_usec()
	for index in range(samples.size()-1):
		var p := samples[index]
		var q := samples[index+1]
		var y0 := _street_height(p)
		var y1 := _street_height(q)
		var y := (y0+y1)*0.5
		var over_water := _water_clearance((p+q)*0.5) < -0.02
		var on_stones:=false
		for run: Dictionary in stepping_runs:
			if Rect2(run.bounds).grow(.20).has_point((p+q)*.5): on_stones=true;break
		var on_arch := false
		for run: Dictionary in profile.get("bridge_runs",[]):
			var nearest := INF
			var arc := 0.0
			for sample: Dictionary in run.samples:
				var gap: float=Vector2(sample.xz).distance_squared_to((p+q)*.5)
				if gap<nearest: nearest=gap;arc=float(sample.distance)
			if arc>=float(run.start)-.2 and arc<=float(run.end)+.2: on_arch=true;break
		if on_stones or on_arch: continue
		for side in [-1,1]:
			var a: Vector2 = p+offsets[index]*side
			var b: Vector2 = q+offsets[index+1]*side
			var center := (a+b)*0.5
			if _inside_other_road(center,str(road.id)): continue
			if not over_water: continue
			_append_road_descriptor(curbs,Vector3(0.065,0.065,a.distance_to(b)+0.003),Vector3(center.x,y+0.48,center.y),Color("d5ccb0"),Vector3(-atan2(y1-y0,a.distance_to(b)),atan2(b.x-a.x,b.y-a.y),0))
			if over_water and index%3 == 0: _append_road_descriptor(curbs,Vector3(0.08,0.52,0.08),Vector3(center.x,y+0.25,center.y),Color("c8ba99"))
		if over_water:
			# The old top at mean road height +15mm covered/intersected paving.
			# Support both ramp ends below the authoritative walking surface.
			_append_road_descriptor(curbs,Vector3(width+0.06,0.08,p.distance_to(q)*0.96),Vector3((p.x+q.x)*0.5,minf(y0,y1)-0.052,(p.y+q.y)*0.5),Color("b5a17e"),Vector3(0,atan2(q.x-p.x,q.y-p.y),0))
	rebuild_stats["road_curbs_ms"] = float(rebuild_stats.get("road_curbs_ms",0.0))+float(Time.get_ticks_usec()-curb_started)/1000.0
	var edge_started := Time.get_ticks_usec()
	var is_promenade := str(road.get("style","path")) in ["promenade","avenue","tram"]
	var edge := {"arrays":[],"stats":{"triangles":0,"vertices":0}} if is_promenade else path_edge.prepare(self,road,stepping_cuts)
	rebuild_stats["road_edges_ms"] = float(rebuild_stats.get("road_edges_ms",0.0))+float(Time.get_ticks_usec()-edge_started)/1000.0
	rebuild_stats["road_mesh_ms"] = float(rebuild_stats.get("road_mesh_ms",0.0))+float(Time.get_ticks_usec()-started)/1000.0
	var adjunct_started:=Time.get_ticks_usec()
	var earthworks:Dictionary=RoadEarthworks.prepare(self,road,profile)
	earthworks.shore_bed=preload("res://scripts/visual/city_creation_shore_road_bed.gd").prepare(self,road,arrays)
	earthworks.shore_bed_mesh=preload("res://scripts/visual/city_creation_road_triangle_data.gd").prepare(earthworks.shore_bed.faces)
	rebuild_stats["road_earthworks_ms"]=float(rebuild_stats.get("road_earthworks_ms",0.))+float(Time.get_ticks_usec()-adjunct_started)/1000.;adjunct_started=Time.get_ticks_usec()
	var roundabouts:Array=RoundaboutVisual.prepare(self,road)
	rebuild_stats["road_roundabouts_ms"]=float(rebuild_stats.get("road_roundabouts_ms",0.))+float(Time.get_ticks_usec()-adjunct_started)/1000.;adjunct_started=Time.get_ticks_usec()
	var decoration:Dictionary=preload("res://scripts/visual/city_creation_road_prepared_inputs.gd").take(self,road)
	var promenade_data:Array=decoration.walk
	var era_data:Dictionary=decoration.era
	rebuild_stats["road_decoration_ms"]=float(rebuild_stats.get("road_decoration_ms",0.))+float(Time.get_ticks_usec()-adjunct_started)/1000.;adjunct_started=Time.get_ticks_usec()
	var bridges:Dictionary=Bridges.prepare(profile)
	rebuild_stats["road_bridges_ms"]=float(rebuild_stats.get("road_bridges_ms",0.))+float(Time.get_ticks_usec()-adjunct_started)/1000.;adjunct_started=Time.get_ticks_usec()
	var tram:Dictionary=tram_tracks.prepare(self,road)
	rebuild_stats["road_tram_ms"]=float(rebuild_stats.get("road_tram_ms",0.))+float(Time.get_ticks_usec()-adjunct_started)/1000.
	profile_times.street_queries=query_count;profile_times.street_query_ms=query_usec/1000.;profile_times.total=(Time.get_ticks_usec()-started)/1000.;set_meta("profile_"+str(road.id),profile_times)
	return {"arrays":arrays,"curbs":curbs,"edge":edge,"stairs":stairs,"earthworks":earthworks,"roundabouts":roundabouts,"promenade":promenade_data,"era_streets":era_data,"stepping_runs":stepping_runs,"bridges":bridges,"tram":tram}
