extends RefCounted
const Renderer=preload("res://scripts/visual/city_creation_renderer.gd")
const Junctions=Renderer.Junctions
const Bridges=Renderer.Bridges
static func prepare(renderer,samples:Array[Vector2],vertices:Array[Vector3],width:float,bridge_spans:Array[Vector2],stone_spans:Array[Vector2])->Dictionary:
	var heights:Dictionary={}
	var paving:Dictionary={}
	var paving_uv:Dictionary={}
	var height_started := Time.get_ticks_usec()
	# Every surface vertex is inside the exact round-ended road footprint.
	# Its nearest centre segment lies within half-width plus the dry flare; retain
	# source segment order in metre bins so equal-distance ties stay identical.
	var center_segments: Array = []
	var center_arc := 0.0
	for index in range(samples.size()-1):
		center_segments.append([samples[index],samples[index+1],center_arc])
		center_arc += samples[index].distance_to(samples[index+1])
	var height_bins: Dictionary = renderer.path_edge._bins(center_segments,width*0.5+Junctions.EXTRA+0.002)
	for index in range(vertices.size()):
		var at := Vector2(vertices[index].x,vertices[index].z)
		if heights.has(at):
			vertices[index].y = heights[at]
			continue
		var nearest := samples[0]
		var distance := INF
		var arc := 0.0
		var across := 0.0
		var bin := Vector2i(floori(at.x),floori(at.y))
		for segment: Array in height_bins.get(bin,center_segments):
			var candidate := Geometry2D.get_closest_point_to_segment(at,segment[0],segment[1])
			if at.distance_squared_to(candidate) < distance:
				distance = at.distance_squared_to(candidate)
				nearest = candidate
				arc = float(segment[2])+Vector2(segment[0]).distance_to(candidate)
				var tangent: Vector2=(Vector2(segment[1])-Vector2(segment[0])).normalized()
				across=(at-candidate).dot(Vector2(-tangent.y,tangent.x))
		vertices[index].y = renderer._street_height(nearest)
		heights[at] = vertices[index].y
		paving[at] = Vector2(Bridges.paving_weight(arc,bridge_spans),Bridges.paving_weight(arc,stone_spans))
		paving_uv[at] = Vector2(arc,across)
	renderer.rebuild_stats["road_heights_ms"] = float(renderer.rebuild_stats.get("road_heights_ms",0.0))+float(Time.get_ticks_usec()-height_started)/1000.0
	return {"paving":paving,"paving_uv":paving_uv}
