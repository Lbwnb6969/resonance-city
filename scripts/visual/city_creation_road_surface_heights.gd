extends RefCounted
## Per-road immutable preparation. Cache exact queries, preserving segment ties.
const Junctions=preload("res://scripts/world/city_creation_junctions.gd")
const Bridges=preload("res://scripts/visual/city_creation_bridge.gd")
static func prepare(renderer,samples:Array[Vector2],vertices:Array[Vector3],width:float,bridge_spans:Array[Vector2],stone_spans:Array[Vector2])->Dictionary:
	var began:=Time.get_ticks_usec();var heights:Dictionary={};var queried:Dictionary={};var paving:Dictionary={};var paving_uv:Dictionary={}
	var segments:Array=[];var center_arc:=0.
	for i in range(samples.size()-1):
		var tangent:Vector2=(samples[i+1]-samples[i]).normalized()
		segments.append([samples[i],samples[i+1],center_arc,Vector2(-tangent.y,tangent.x)])
		center_arc+=samples[i].distance_to(samples[i+1])
	var bins:Dictionary=renderer.path_edge._bins(segments,width*.5+Junctions.EXTRA+.002)
	var context=preload("res://scripts/visual/city_creation_road_height_context.gd").new(renderer.state)
	for i in range(vertices.size()):
		var at:=Vector2(vertices[i].x,vertices[i].z)
		if heights.has(at):vertices[i].y=heights[at];continue
		var nearest:=samples[0];var distance:=INF;var arc:=0.;var across:=0.
		for segment:Array in bins.get(Vector2i(floori(at.x),floori(at.y)),segments):
			var candidate:=Geometry2D.get_closest_point_to_segment(at,segment[0],segment[1])
			if at.distance_squared_to(candidate)<distance:
				distance=at.distance_squared_to(candidate);nearest=candidate
				arc=float(segment[2])+Vector2(segment[0]).distance_to(candidate);across=(at-candidate).dot(segment[3])
		if not queried.has(nearest):queried[nearest]=context.height_at(nearest)
		vertices[i].y=queried[nearest];heights[at]=vertices[i].y
		paving[at]=Vector2(Bridges.paving_weight(arc,bridge_spans),Bridges.paving_weight(arc,stone_spans));paving_uv[at]=Vector2(arc,across)
	renderer.rebuild_stats.road_heights_ms=float(renderer.rebuild_stats.get("road_heights_ms",0.))+(Time.get_ticks_usec()-began)/1000.
	renderer.rebuild_stats.road_height_vertices=int(renderer.rebuild_stats.get("road_height_vertices",0))+heights.size()
	renderer.rebuild_stats.road_height_queries=int(renderer.rebuild_stats.get("road_height_queries",0))+queried.size()
	return {"paving":paving,"paving_uv":paving_uv}
