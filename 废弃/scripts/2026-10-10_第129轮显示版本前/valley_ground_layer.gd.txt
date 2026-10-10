extends Node2D
const Coupling = preload("res://scripts/world/world_coupling.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
var city: ContinuousWorld
var role := "terrain"
var key: Array = []
var projected: Dictionary = {}
var roads: Array[Dictionary] = []
var patches: Array[PackedVector2Array] = []
var contours: Array[PackedVector2Array] = []
var camera_zoom := 1.0
var rebuild_count := 0
var last_draw_ms := 0.0
var max_draw_ms := 0.0

func sync(demo: Control) -> void:
	city = demo.shown_world
	position = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	scale = Vector2.ONE*demo.view_zoom
	visible = not demo.black
	var geometry_key: Array = [city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,hash(city.cfg["terrain"])] if role == "terrain" else [city,city.phrase_index]
	var next_key := geometry_key+[snappedf(demo.view_zoom,0.00001)]
	if key == next_key: return
	if key.is_empty() or key.slice(0,-1) != geometry_key: projected.clear()
	key = next_key
	camera_zoom = demo.view_zoom
	roads = demo.road_draw_polygons
	patches = demo.ground_patches
	contours = demo.ground_contours
	queue_redraw()

func _point(p: Vector2, height: float = -1.0) -> Vector2:
	var h := city.terrain.height_at(p) if height < 0.0 else height
	return IsoProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),h)

func _project_polygon(polygon: PackedVector2Array,height: float = -1.0) -> PackedVector2Array:
	if not projected.has(height): projected[height] = {}
	var cache: Dictionary = projected[height]
	if not cache.has(polygon):
		var points := PackedVector2Array()
		for p in polygon: points.append(_point(p,height))
		cache[polygon] = points
	return cache[polygon]

func _draw() -> void:
	if city == null: return
	var started := Time.get_ticks_usec()
	rebuild_count += 1
	if role == "terrain": _draw_terrain()
	else: _draw_urban()
	last_draw_ms = float(Time.get_ticks_usec()-started)/1000.0
	max_draw_ms = maxf(max_draw_ms,last_draw_ms)

func _draw_terrain() -> void:
	var sea := PackedVector2Array([Vector2(-8,-8),Vector2(40,-8),Vector2(40,40),Vector2(-8,40)])
	var family := city.terrain.family
	var water_color := Color("78a4ad") if family == "river_valley" else (Color("719ca8") if family == "lake_basin" else (Color("82aab0") if family == "coastal_plain" else (Color("5f8192") if family == "highland_pass" else Color("6e9c9a"))))
	var left_color := Color("e9e1cb") if family != "forest_ridge" and family != "highland_pass" else (Color("9eafad") if family == "highland_pass" else Color("b7c8a4"))
	var right_color := Color("e0e5d6") if family != "coastal_plain" and family != "highland_pass" else (Color("c4d0cc") if family == "highland_pass" else Color("e5d9bd"))
	draw_colored_polygon(_project_polygon(sea,0.0),Color("9bbcc0"))
	draw_colored_polygon(_project_polygon(city.terrain.left_bank),left_color)
	draw_colored_polygon(_project_polygon(city.terrain.right_bank),right_color)
	for ring in patches: draw_colored_polygon(_project_polygon(ring),Color(0.72,0.77,0.59,0.12))
	for contour in contours:
		draw_polyline(_project_polygon(contour),Color(0.54,0.64,0.49,0.16),1.0/camera_zoom,true)
	draw_colored_polygon(_project_polygon(city.terrain.water,0.0),water_color)

func _draw_urban() -> void:
	for road in roads: draw_colored_polygon(_project_polygon(road["polygon"]),road["color"])
	_draw_center_markers()
	_draw_green_corridors()
	_draw_public_space()
	for lot in city.lots:
		if lot["occupant"] != "":
			draw_colored_polygon(_project_polygon(lot["polygon"]),Color(0.68,0.73,0.57,0.2))
	_draw_fabric_overlay()

func _draw_center_markers() -> void:
	for center in city.centers:
		if not bool(center.get("active",true)): continue
		var p := Vector2(float(center["position"][0]),float(center["position"][1]))
		var level := str(center.get("level","terrace"))
		var color := Color("b28b53") if level == "primary" else (Color("6e9290") if level == "secondary" else Color("829b69"))
		var radius := 5.8 if level == "primary" else (4.4 if level == "secondary" else 3.0)
		draw_circle(_point(p,city.terrain.height_at(p)+0.08),radius*1.0,Color(color,0.24))
		draw_arc(_point(p,city.terrain.height_at(p)+0.09),radius*1.0,0,TAU,24,color,1.4*1.0,true)
		if level != "terrace":
			draw_circle(_point(p,city.terrain.height_at(p)+0.10),1.6*1.0,color)

func _draw_green_corridors() -> void:
	for corridor in city.green_corridors:
		if not bool(corridor.get("active",true)): continue
		var path: PackedVector2Array = corridor["path"]
		if path.size() < 2: continue
		var width := float(corridor.get("width",0.24))
		for polygon in Geometry2D.offset_polyline(path,width,Geometry2D.JOIN_ROUND,Geometry2D.END_BUTT):
			draw_colored_polygon(_project_polygon(polygon,0.012),Color(0.55,0.69,0.43,0.36))
		draw_polyline(_project_polygon(path,0.025),Color(0.48,0.62,0.39,0.64),2.2*1.0,true)
		for i in range(0,path.size(),2):
			var p := path[i]
			draw_circle(_point(p,0.04),2.4*1.0,Color(0.38,0.56,0.35,0.72))

func _draw_public_space() -> void:
	for site in city.public_sites:
		var polygon: PackedVector2Array = site["polygon"]
		var projected := _project_polygon(polygon)
		if site["active"]:
			var color := Color("bacda7") if site["kind"] == "park" else Color("ded5b9")
			draw_colored_polygon(projected,color)
			if site["kind"] == "park":
				var p := Vector2(site["position"][0],site["position"][1])
				var walk := PackedVector2Array([p+Vector2(-2,0.1),p+Vector2(0.2,-0.25),p+Vector2(2,0.15)])
				for part in Geometry2D.intersect_polyline_with_polygon(walk,polygon):
					draw_polyline(_project_polygon(part),Color("e6e2c9"),3.4*1.0,true)
				var pool := PackedVector2Array()
				for i in range(32): pool.append(p+Vector2(0.4,0.6)+Vector2(cos(TAU*i/32)*0.5,sin(TAU*i/32)*0.35))
				draw_colored_polygon(_project_polygon(pool),Color("9bb9af"))
			else:
				var center := _point(Vector2(site["position"][0],site["position"][1]))
				for level in range(int(site.get("service_level",1))):
					draw_circle(center+Vector2((level-1)*7,15)*1.0,2.2*1.0,Color("927851"))
				if site.get("served",[]).size() >= int(site.get("service_capacity",18)):
					draw_arc(center,14*1.0,0,TAU,32,Color("b58b55"),1.2/camera_zoom,true)
		else:
			projected.append(projected[0])
			draw_polyline(projected,Color(0.45,0.59,0.43,0.34),1.1/camera_zoom,true)
	for line in city.transit_lines:
		for node in line["stops"]:
			var p: Array = city.nodes[node]
			var at := _point(Vector2(p[0],p[1]))
			draw_circle(at,3.5*1.0,Color("e9d4a0"))
			draw_arc(at,4.2*1.0,0,TAU,16,Color("899d87"),1.0/camera_zoom,true)

func _draw_fabric_overlay() -> void:
	var cache: Dictionary = city.fabric_cache
	for courtyard in cache.get("courtyards",[]):
		var center := Vector2(float(courtyard["center"][0]),float(courtyard["center"][1]))
		var polygon: PackedVector2Array = courtyard.get("polygon",PackedVector2Array())
		if polygon.size() < 3:
			polygon = PackedVector2Array([center+Vector2(-0.58,0),center+Vector2(0,-0.42),center+Vector2(0.58,0),center+Vector2(0,0.42)])
		var closed := polygon.duplicate()
		closed.append(closed[0])
		draw_colored_polygon(_project_polygon(polygon,0.01),Color(0.82,0.78,0.60,0.18))
		draw_polyline(_project_polygon(closed,0.015),Color(0.74,0.66,0.48,0.50),1.1*1.0,true)
		draw_circle(_point(center,0.025),2.0*1.0,Color(0.88,0.80,0.52,0.56))
	for relation in cache.get("shared_walls",[]):
		if not city.by_id.has(relation["a"]) or not city.by_id.has(relation["b"]): continue
		var a := _point(Coupling.position_of(city.by_id[relation["a"]]),city.terrain.height_at(Coupling.position_of(city.by_id[relation["a"]]))+0.04)
		var b := _point(Coupling.position_of(city.by_id[relation["b"]]),city.terrain.height_at(Coupling.position_of(city.by_id[relation["b"]]))+0.04)
		draw_line(a,b,Color(0.74,0.52,0.31,0.72),2.1*1.0,true)
	for row in cache.get("rows",[]):
		var members: Array = row["members"]
		for i in range(members.size()-1):
			if not city.by_id.has(members[i]) or not city.by_id.has(members[i+1]): continue
			var a := _point(Coupling.position_of(city.by_id[members[i]]),0.05)
			var b := _point(Coupling.position_of(city.by_id[members[i+1]]),0.05)
			draw_line(a,b,Color(0.62,0.67,0.49,0.42),1.4*1.0,true)
