extends Node2D
const Coupling = preload("res://scripts/world/world_coupling.gd")
const IsoProjection = preload("res://scripts/world/world_projection.gd")
const PublicGeometry = preload("res://scripts/visual/public_space_visual_geometry.gd")
const TerrainGeometry = preload("res://scripts/visual/valley_terrain_visual_geometry.gd")
const ExpressionIdentity = preload("res://scripts/visual/first_expression_identity.gd")
const Miniature = preload("res://scripts/visual/miniature_valley_material.gd")
const CivicCourt = preload("res://scripts/visual/classical_civic_court.gd")
const ClassicalStreetSurface = preload("res://scripts/visual/classical_street_surface.gd")
const ClassicalFrontageGround = preload("res://scripts/visual/classical_frontage_ground.gd")
const ClassicalLandscape = preload("res://scripts/visual/classical_landscape.gd")
var city: ContinuousWorld
var role := "terrain"
var art_style_id := "baseline"
var palette: Dictionary = {}
var key: Array = []
var projected: Dictionary = {}
var point_cache: Dictionary = {}
var drawn_polygons: Dictionary = {}
var drawn_points: Dictionary = {}
var terrain_identity: Array = []
var roads: Array[Dictionary] = []
var patches: Array[PackedVector2Array] = []
var contours: Array[PackedVector2Array] = []
var camera_zoom := 1.0
var rebuild_count := 0
var update_count := 0
var last_draw_ms := 0.0
var max_draw_ms := 0.0
var terrain_geometry: Dictionary = {}
var terrain_geometry_key: Array = []
var terrain_geometry_rebuilds := 0
var terrain_prepare_ms := 0.0
var terrain_surface_skips := 0
var water_material: Array[Dictionary] = []
var land_material: Array[Dictionary] = []
var road_material: Array[Dictionary] = []
var ground_grain: Array[Dictionary] = []
var street_material: Dictionary = {"curbs":[],"joints":[],"paving":[]}
var street_material_key: Array = []
var street_material_rebuilds := 0
var civic_court := CivicCourt.new()
var classical_street_surface := ClassicalStreetSurface.new()
var classical_frontage_ground := ClassicalFrontageGround.new()
var classical_landscape := ClassicalLandscape.new()
var refined_streets_visible := true
var refined_frontages_visible := true
# Independent CanvasItems retain exact draw contents in the original layer order.
var urban_parts: Dictionary = {}
var last_prepare_ms := 0.0
var max_prepare_ms := 0.0
var last_part_draw_frame := -1
const URBAN_PARTS = ["roads","centers","corridors","public","lots","fabric"]

func _init() -> void:
	# The terrain texture carries mipmaps; linear filtering keeps the paper grain
	# quiet when the camera zooms over the large empty fields.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func sync(demo: Control) -> void:
	city = demo.shown_world
	art_style_id = demo.art_direction.selected_id
	palette = demo.art_direction.palette()
	if _miniature_style(): palette = Miniature.COLORS
	for part in urban_parts.values(): part.city = city
	position = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	scale = Vector2.ONE*demo.view_zoom
	visible = not demo.black
	var geometry_key: Array = [city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,hash(city.cfg["terrain"])] if role == "terrain" else demo._shown_city_key()
	var next_key := geometry_key+[snappedf(demo.view_zoom,0.00001),art_style_id]
	if role == "urban":
		var clock: Variant = demo.get("clock")
		var frame: float = clock.renderer.transport.audible_frame if clock != null else float(city.phrase_index*int(city.cfg["timing"]["phrase_frames"]))
		civic_court.sync(city,frame,art_style_id)
		next_key.append(city.era)
		next_key.append(civic_court.key)
		if _classical_streets():
			classical_street_surface.sync(city,frame)
			# Pure terrain fixtures own no catalogue, sprites or playback clock.
			if clock != null: classical_frontage_ground.sync(demo)
			next_key.append(classical_street_surface.key)
			next_key.append(classical_frontage_ground.key)
	var next_terrain := [city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,hash(city.cfg["terrain"])]
	var terrain_changed := terrain_identity != next_terrain
	var landscape_changed := false
	if terrain_changed:
		projected.clear()
		point_cache.clear()
		terrain_identity = next_terrain
	if role == "terrain":
		var clock: Variant = demo.get("clock")
		var heard_frame := int(clock.renderer.transport.audible_frame) if clock != null else city.phrase_index*int(city.cfg["timing"]["phrase_frames"])
		landscape_changed = classical_landscape.sync(city,heard_frame)
	if key == next_key and not terrain_changed and not landscape_changed: return
	key = next_key
	update_count += 1
	camera_zoom = demo.view_zoom
	roads = demo.road_draw_polygons
	patches = demo.ground_patches
	contours = demo.ground_contours
	if role == "urban":
		_sync_urban_parts(terrain_changed)
	else:
		if role == "terrain": _prepare_terrain_geometry()
		queue_redraw()

func _prepare_terrain_geometry() -> void:
	if terrain_geometry_key == terrain_identity and not terrain_geometry.is_empty(): return
	var began := Time.get_ticks_usec()
	terrain_geometry = TerrainGeometry.build(city.terrain) if city.terrain.family == "river_valley" else {"surfaces":[]}
	water_material.assign(Miniature.water_bands(city.terrain) if city.terrain.family == "river_valley" else [])
	ground_grain.assign(Miniature.land_grain(city.terrain) if city.terrain.family == "river_valley" else [])
	land_material = []
	for surface: Dictionary in terrain_geometry.get("continuous_surfaces",[]):
		land_material.append({"polygon":surface["polygon"],"side":surface["side"],"colors":Miniature.earth_colors(city.terrain,surface["polygon"])})
	classical_landscape.prepare_terrain(city.terrain,terrain_geometry.get("continuous_surfaces",[]))
	terrain_geometry_key = terrain_identity.duplicate(true)
	terrain_geometry_rebuilds += 1
	terrain_prepare_ms = float(Time.get_ticks_usec()-began)/1000.0

func _miniature_style() -> bool:
	return city != null and city.terrain.family == "river_valley" and art_style_id == "baseline"

func _classical_streets() -> bool:
	return _miniature_style() and city.era == 1

func _point(p: Vector2, height: float = -1.0) -> Vector2:
	var point_key := [p,height]
	if not point_cache.has(point_key):
		var h := city.terrain.height_at(p) if height < 0.0 else height
		point_cache[point_key] = IsoProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),h)
	drawn_points[point_key] = point_cache[point_key]
	return point_cache[point_key]

func _project_polygon(polygon: PackedVector2Array,height: float = -1.0) -> PackedVector2Array:
	if not projected.has(height): projected[height] = {}
	var cache: Dictionary = projected[height]
	if not cache.has(polygon):
		var points := PackedVector2Array()
		for p in polygon: points.append(_point(p,height))
		cache[polygon] = points
	if not drawn_polygons.has(height): drawn_polygons[height] = {}
	drawn_polygons[height][polygon] = cache[polygon]
	return cache[polygon]

func _draw() -> void:
	if city == null or (role == "urban" and not urban_parts.is_empty()): return
	var started := Time.get_ticks_usec()
	drawn_polygons = {}
	drawn_points = {}
	rebuild_count += 1
	match role:
		"terrain": _draw_terrain()
		"roads": _draw_roads()
		"centers": _draw_center_markers()
		"corridors": _draw_green_corridors()
		"public": _draw_public_space()
		"lots": _draw_occupied_lots()
		"fabric": _draw_fabric_overlay()
		_: _draw_urban()
	# Retain only geometry read by this draw, not previous city history.
	projected = drawn_polygons
	point_cache = drawn_points
	last_draw_ms = float(Time.get_ticks_usec()-started)/1000.0
	max_draw_ms = maxf(max_draw_ms,last_draw_ms)
	if role in URBAN_PARTS: get_parent().call("_record_part_draw",last_draw_ms)

func _draw_terrain() -> void:
	var high_y := float(city.terrain.cfg.get("template_land_max_y",city.terrain.cfg["template_land_max"]))+4.0
	var sea := PackedVector2Array([Vector2(-8,-8),Vector2(40,-8),Vector2(40,high_y),Vector2(-8,high_y)])
	var family := city.terrain.family
	var water_color := Color("78a4ad") if family == "river_valley" else (Color("719ca8") if family == "lake_basin" else (Color("82aab0") if family == "coastal_plain" else (Color("5f8192") if family == "highland_pass" else Color("6e9c9a"))))
	var left_color := Color("e9e1cb") if family != "forest_ridge" and family != "highland_pass" else (Color("9eafad") if family == "highland_pass" else Color("b7c8a4"))
	var right_color := Color("e0e5d6") if family != "coastal_plain" and family != "highland_pass" else (Color("c4d0cc") if family == "highland_pass" else Color("e5d9bd"))
	draw_colored_polygon(_project_polygon(sea,0.0),Color("9bbcc0"))
	if family == "river_valley":
		_draw_river_terrain()
		return
	draw_colored_polygon(_project_polygon(city.terrain.left_bank),left_color)
	draw_colored_polygon(_project_polygon(city.terrain.right_bank),right_color)
	for ring in patches: draw_colored_polygon(_project_polygon(ring),Color(0.72,0.77,0.59,0.12))
	for contour in contours:
		draw_polyline(_project_polygon(contour),Color(0.54,0.64,0.49,0.16),1.0/camera_zoom,true)
	draw_colored_polygon(_project_polygon(city.terrain.water,0.0),water_color)

func _draw_river_terrain() -> void:
	_prepare_terrain_geometry()
	var left_colors := [Color("e9e1cb"),Color("d4dcc0"),Color("becfb0"),Color("acbfae")]
	var right_colors := [Color("e0e5d6"),Color("ced9c5"),Color("b9ccb8"),Color("acbfae")]
	if not palette.is_empty():
		for band in range(4):
			left_colors[band] = Color(palette["left"][band])
			right_colors[band] = Color(palette["right"][band])
	terrain_surface_skips = 0
	var use_classical_landscape := _miniature_style() and city.era == 1 and classical_landscape.land_texture != null
	var surfaces: Array = classical_landscape.land_material if use_classical_landscape else (land_material if _miniature_style() else terrain_geometry["surfaces"])
	for surface in surfaces:
		var colors: Array = left_colors if int(surface["side"]) == 0 else right_colors
		var projected := _project_polygon(surface["polygon"])
		# Height clipping can leave a tiny world-space triangle whose projected
		# vertices collapse onto one line. Godot's CanvasItem triangulator logs an
		# error for that command even though the source triangulation succeeded.
		# Filter only the degenerate projected face; all readable terrain remains.
		if not _is_drawable_polygon(projected):
			terrain_surface_skips += 1
			continue
		if use_classical_landscape:
			draw_polygon(projected,surface["colors"],surface.get("uvs",PackedVector2Array()),classical_landscape.land_texture)
		elif _miniature_style(): draw_polygon(projected,surface["colors"])
		else: draw_colored_polygon(projected,colors[int(surface["band"])])
	if _miniature_style():
		if use_classical_landscape:
			for tuft: Dictionary in classical_landscape.geometry.get("tufts",[]):
				for path: PackedVector2Array in tuft["paths"]:
					draw_polyline(_project_polygon(path),tuft["color"],0.72,true)
			for stone: Dictionary in classical_landscape.geometry.get("stones",[]):
				draw_colored_polygon(_project_polygon(stone["polygon"]),stone["color"])
		else:
			for mark: Dictionary in ground_grain:
				var color := Color("f0e6c8",0.15) if bool(mark["light"]) else Color("687d5a",0.12)
				draw_polyline(_project_polygon(mark["path"]),color,0.65,true)
	else:
		for ring in patches: draw_colored_polygon(_project_polygon(ring),Color(0.72,0.77,0.59,0.08))
	if not _miniature_style():
		for contour in terrain_geometry["contours"]:
			draw_polyline(_project_polygon(contour["path"]),Color(0.45,0.58,0.46,0.18),0.8/camera_zoom,true)
	for rim in terrain_geometry["rims"]: draw_colored_polygon(_project_polygon(rim),Color(palette.get("rim","c2ceb3")))
	if _miniature_style():
		for band: Dictionary in water_material: draw_colored_polygon(_project_polygon(band["polygon"],0.0),band["color"])
	else:
		draw_colored_polygon(_project_polygon(city.terrain.water,0.0),Color(palette.get("water","91b1b3")))
		draw_colored_polygon(_project_polygon(terrain_geometry["channel"],0.0),Color(palette.get("channel","78a4ad")))
		for shallow in terrain_geometry["shallow_water"]: draw_colored_polygon(_project_polygon(shallow,0.0),Color(palette.get("shallow","acc6be")))
	for face in terrain_geometry["shore_faces"]:
		var edge: PackedVector2Array = face["edge"]
		var top := PackedVector2Array([_point(edge[0],float(face["heights"][0])),_point(edge[1],float(face["heights"][1]))])
		var wall := PackedVector2Array([top[0],top[1],_point(edge[1],0.0),_point(edge[0],0.0)])
		if _miniature_style():
			_draw_stone_bank(top,wall)
		else:
			draw_colored_polygon(wall,Color(palette.get("shore","9fac9c")))
			draw_polyline(top,Color(palette.get("edge","d8dfc7")),0.8/camera_zoom,true)

func _draw_stone_bank(top: PackedVector2Array,wall: PackedVector2Array) -> void:
	# The bank's bottom is water level and its cap is the real terrain height.
	# Stone courses add relief without extruding or moving the shoreline.
	var colors := [Color("b6b79a"),Color("96a48c"),Color("728c80")]
	for index in range(3):
		var above := float(index)/3.0
		var below := float(index+1)/3.0
		var a := wall[0].lerp(wall[3],above)
		var b := wall[1].lerp(wall[2],above)
		var c := wall[1].lerp(wall[2],below)
		var d := wall[0].lerp(wall[3],below)
		var course := PackedVector2Array([a,b,c,d])
		if _is_drawable_polygon(course): draw_colored_polygon(course,colors[index])
		if index > 0: draw_line(a,b,Color("566f65",0.26),0.65,true)
		var joint := 0.38 if index%2 == 0 else 0.70
		draw_line(a.lerp(b,joint),d.lerp(c,joint),Color("596e60",0.24),0.65,true)
	draw_polyline(top,Color("dfd8bc"),1.0,true)
	draw_line(wall[2],wall[3],Color("2f6370",0.30),1.8,true)

func _is_drawable_polygon(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3: return false
	var twice_area := 0.0
	for index in range(polygon.size()):
		twice_area += polygon[index].cross(polygon[(index+1)%polygon.size()])
	if absf(twice_area) <= 0.000002: return false
	return not Geometry2D.triangulate_polygon(polygon).is_empty()

func _draw_urban() -> void:
	_draw_roads()
	_draw_center_markers()
	_draw_green_corridors()
	_draw_public_space()
	_draw_occupied_lots()
	_draw_fabric_overlay()

func _draw_roads() -> void:
	if not _miniature_style():
		for road in roads: draw_colored_polygon(_project_polygon(road["polygon"]),road["color"])
		return
	for road in road_material:
		if _classical_streets() and not bool(road["bridge"]):
			draw_polygon(_project_polygon(road["polygon"]),road["colors"])
		else:
			draw_colored_polygon(_project_polygon(road["polygon"]),Color("bda37d") if _classical_streets() else road["color"])
	if _classical_streets() and refined_streets_visible:
		_draw_classical_street_surface()
		return
	# Empty roads remain dirt at their real width. Light stone and contact
	# edges belong only to actually inhabited classical street frontages.
	# Later eras keep their base road material and surviving era-one paving.
	for paving: Dictionary in street_material["paving"]:
		draw_colored_polygon(_project_polygon(paving["polygon"]),Color(Miniature.PAVING_COLOR,float(paving["strength"])))
	for curb: PackedVector2Array in street_material["curbs"]:
		var path := _project_polygon(curb)
		draw_polyline(path,Color("8b826b",0.38),2.0,true)
		draw_polyline(path,Color("ece0c1",0.85),1.0,true)
	for joint: PackedVector2Array in street_material["joints"]:
		draw_polyline(_project_polygon(joint),Color("968b70",0.24),0.6,true)

func _draw_classical_street_surface() -> void:
	var material: Dictionary = classical_street_surface.material
	for paving: Dictionary in material["paving"]:
		draw_colored_polygon(_project_polygon(paving["polygon"]),Color(Color("a49c86"),float(paving["strength"])))
	for stone: Dictionary in material["stones"]:
		var tone := float(stone["tone"])
		var color := Color("bdb59b")
		color = color.lightened(tone) if tone >= 0.0 else color.darkened(-tone)
		draw_colored_polygon(_project_polygon(stone["polygon"]),Color(color,float(stone["strength"])))
	for curb: Dictionary in material["curbs"]:
		var polygon: PackedVector2Array = curb["polygon"]
		var edge: PackedVector2Array = curb["edge"]
		var rise := float(curb["raise"])
		var strength := float(curb["strength"])
		var center := Vector2.ZERO
		for p in polygon: center += p
		center /= polygon.size()
		# Only the two camera-facing sides of a low curb have visible height.
		if ((edge[0]+edge[1])*0.5-center).dot(Vector2.ONE) > 0.0:
			var wall := PackedVector2Array([_point(edge[0]),_point(edge[1]),_raised_point(edge[1],rise),_raised_point(edge[0],rise)])
			draw_colored_polygon(wall,Color(Color("898473"),strength))
		var top := PackedVector2Array()
		for p in polygon: top.append(_raised_point(p,rise))
		draw_colored_polygon(top,Color(Color("d1c6a9"),strength))
	for joint: PackedVector2Array in material["joints"]:
		draw_polyline(_project_polygon(joint),Color("817e6b",0.28),0.4,true)

func _raised_point(p: Vector2,rise: float) -> Vector2:
	return _point(p,city.terrain.height_at(p)+rise)

func _draw_occupied_lots() -> void:
	for lot in city.lots:
		if lot["occupant"] != "":
			var expression := _lot_expression(lot)
			var polygon := _project_polygon(lot["polygon"])
			if expression.is_empty():
				draw_colored_polygon(polygon,Color("cabd9c",0.75) if _miniature_style() else Color(0.68,0.73,0.57,0.24))
			else:
				# The same authored palette reaches the street, not just the roof.
				# Subtle paved plots make the growing family read as one place.
				var ink: Color = ExpressionIdentity.STYLES[expression]["ink"]
				draw_colored_polygon(polygon,Color(ink,0.29))
				var edge := polygon.duplicate()
				edge.append(edge[0])
				draw_polyline(edge,Color(ink,0.32),0.75,true)
	if _classical_streets() and refined_frontages_visible:
		for pad: Dictionary in classical_frontage_ground.pads:
			draw_colored_polygon(_project_polygon(pad["polygon"]),pad["color"])

func _lot_expression(lot: Dictionary) -> String:
	var building: Dictionary = city.by_id[str(lot["occupant"])]
	return ExpressionIdentity.expression_for(building,city.families.get(str(building.get("family_id","")),{}))

func _draw_center_markers() -> void:
	# Centers are graph anchors, not circular objects built into the landscape.
	if _miniature_style(): return
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
	for reservation in city.planning_reservations:
		var polygon := _project_polygon(reservation["polygon"]).duplicate()
		draw_colored_polygon(polygon,Color(0.78,0.83,0.69,0.36))
		polygon.append(polygon[0])
		draw_polyline(polygon,Color(0.40,0.56,0.40,0.72),1.5/camera_zoom,true)
	for site in city.public_sites:
		if CivicCourt.applies(city,site,art_style_id):
			_draw_classical_civic_court(str(site["id"]))
			continue
		for component in PublicGeometry.components(site):
			if site["active"]:
				var color := Color("97ae87") if site["kind"] == "park" else Color("d1c3a1")
				if not _miniature_style(): color = Color("bacda7") if site["kind"] == "park" else Color("ded5b9")
				for piece in component["pieces"]: draw_colored_polygon(_project_polygon(piece),color)
				if site["kind"] == "park":
					var details := PublicGeometry.park_details(component)
					for path in details["paths"]: draw_colored_polygon(_project_polygon(path),Color("d1c7a6") if _miniature_style() else Color("e6e2c9"))
					for pool in details["pools"]: draw_colored_polygon(_project_polygon(pool),Color("6e9c94") if _miniature_style() else Color("9bb9af"))
				else:
					var center := _point(component["position"])
					var mark_scale := minf(1.0,float(component["clearance"])/0.9)
					for level in range(int(site.get("service_level",1))):
						draw_circle(center+Vector2((level-1)*7,15)*mark_scale,2.2*mark_scale,Color("927851"))
					if site.get("served",[]).size() >= int(site.get("service_capacity",18)):
						draw_arc(center,14*mark_scale,0,TAU,32,Color("b58b55"),1.2/camera_zoom,true)
			elif not _miniature_style():
				var outline := _project_polygon(component["outer"]).duplicate()
				outline.append(outline[0])
				draw_polyline(outline,Color(0.45,0.59,0.43,0.34),1.1/camera_zoom,true)
	for line in city.transit_lines:
		for node in line["stops"]:
			var stop_position := city.transit_stop_position(str(node))
			if stop_position == Vector2.INF: continue
			var at := _point(stop_position)
			draw_circle(at,3.5*1.0,Color("e9d4a0"))
			draw_arc(at,4.2*1.0,0,TAU,16,Color("899d87"),1.0/camera_zoom,true)

func _draw_classical_civic_court(site_id: String) -> void:
	for court: Dictionary in civic_court.courts.get(site_id,[]):
		for piece: PackedVector2Array in court["pieces"]:
			draw_colored_polygon(_project_polygon(piece),Color("d5c8aa"))
		for path: PackedVector2Array in court["paths"]:
			draw_colored_polygon(_project_polygon(path),Color("eadfc4",0.44))
		for joint: PackedVector2Array in court["joints"]:
			draw_polyline(_project_polygon(joint),Color("998d73",0.28),0.6,true)

func _draw_fabric_overlay() -> void:
	var cache: Dictionary = city.fabric_cache
	for courtyard in cache.get("courtyards",[]):
		var center := Vector2(float(courtyard["center"][0]),float(courtyard["center"][1]))
		var polygon: PackedVector2Array = courtyard.get("polygon",PackedVector2Array())
		if polygon.size() < 3:
			polygon = PackedVector2Array([center+Vector2(-0.58,0),center+Vector2(0,-0.42),center+Vector2(0.58,0),center+Vector2(0,0.42)])
		var closed := polygon.duplicate()
		closed.append(closed[0])
		draw_colored_polygon(_project_polygon(polygon,0.01),Color("c6b68e",0.36) if _miniature_style() else Color(0.82,0.78,0.60,0.18))
		draw_polyline(_project_polygon(closed,0.015),Color("a69d80",0.38) if _miniature_style() else Color(0.74,0.66,0.48,0.50),0.9 if _miniature_style() else 1.1,true)
		if not _miniature_style(): draw_circle(_point(center,0.025),2.0,Color(0.88,0.80,0.52,0.56))
	for relation in cache.get("shared_walls",[]):
		if not city.by_id.has(relation["a"]) or not city.by_id.has(relation["b"]): continue
		var a := _point(Coupling.position_of(city.by_id[relation["a"]]),city.terrain.height_at(Coupling.position_of(city.by_id[relation["a"]]))+0.04)
		var b := _point(Coupling.position_of(city.by_id[relation["b"]]),city.terrain.height_at(Coupling.position_of(city.by_id[relation["b"]]))+0.04)
		# Shared walls carry the block rhythm. Keep the accent under the houses
		# so closely packed starter homes read as one street frontage.
		draw_line(a,b,Color("8d8972",0.42) if _miniature_style() else Color(0.74,0.52,0.31,0.78),2.0 if _miniature_style() else 2.5,true)
	for row in cache.get("rows",[]):
		var members: Array = row["members"]
		for i in range(members.size()-1):
			if not city.by_id.has(members[i]) or not city.by_id.has(members[i+1]): continue
			var a := _point(Coupling.position_of(city.by_id[members[i]]),0.05)
			var b := _point(Coupling.position_of(city.by_id[members[i+1]]),0.05)
			# A translucent sidewalk ribbon turns the row relation into a visible
			# street block. It is presentation-only and remains beneath buildings.
			draw_line(a,b,Color("c6b898",0.34) if _miniature_style() else Color(0.52,0.63,0.48,0.16),6.0,true)
			draw_line(a,b,Color("a49d80",0.40) if _miniature_style() else Color(0.62,0.67,0.49,0.52),1.4 if _miniature_style() else 1.8,true)

func _sync_urban_parts(terrain_changed: bool) -> void:
	var began := Time.get_ticks_usec()
	if _miniature_style():
		var footprint_key: Array = []
		for building: Dictionary in city.buildings: footprint_key.append([building["district_id"],Coupling.position_of(building),int(building.get("era",1))])
		var next_material_key: Array = [terrain_identity,city.network.topology,footprint_key]
		if street_material_key != next_material_key:
			street_material_key = next_material_key
			street_material = Miniature.street_geometry(city)
			street_material_rebuilds += 1
	else:
		street_material_key = []
		street_material = {"curbs":[],"joints":[],"paving":[]}
	# Retain vertex material beside the road draw signature; camera motion
	# never resamples height or rebuilds stone geometry.
	var road_part_key: Array = [art_style_id]
	for road: Dictionary in roads: road_part_key.append([road["polygon"],road["color"]])
	if terrain_changed or not urban_parts.has("roads") or urban_parts["roads"].get_meta("material_key",[]) != road_part_key:
		road_material = []
		for road: Dictionary in roads:
			road_material.append({"polygon":road["polygon"],"color":road["color"],"bridge":road["color"] == Color("d3bb93"),"colors":Miniature.dirt_colors(city.terrain,road["polygon"]) if _miniature_style() else PackedColorArray()})
	var contents := _urban_contents()
	last_draw_ms = 0.0
	var changed := false
	for name in URBAN_PARTS:
		if not urban_parts.has(name):
			var part: Node2D = get_script().new()
			part.name = "Ground_"+name
			part.role = name
			add_child(part)
			urban_parts[name] = part
		var part: Node2D = urban_parts[name]
		part.city = city
		part.art_style_id = art_style_id
		part.palette = palette
		part.roads = roads
		part.road_material = road_material
		if name == "roads": part.set_meta("material_key",road_part_key)
		part.street_material = street_material
		if name == "roads": part.classical_street_surface = classical_street_surface
		if name == "lots": part.classical_frontage_ground = classical_frontage_ground
		if name == "public": part.civic_court = civic_court
		part.camera_zoom = camera_zoom
		var content_key: Array = [terrain_identity,contents[name],art_style_id]
		# Public outline widths are screen-constant. Other urban marks scale with
		# their parent, so camera motion/zoom reuses their exact draw commands.
		if name == "public": content_key.append(camera_zoom)
		if not terrain_changed and part.key == content_key: continue
		if terrain_changed:
			part.projected.clear()
			part.point_cache.clear()
		part.key = content_key
		part.update_count += 1
		part.queue_redraw()
		changed = true
	if changed: rebuild_count += 1
	last_prepare_ms = float(Time.get_ticks_usec()-began)/1000.0
	max_prepare_ms = maxf(max_prepare_ms,last_prepare_ms)

func _record_part_draw(milliseconds: float) -> void:
	var frame := Engine.get_process_frames()
	if last_part_draw_frame != frame:
		last_part_draw_frame = frame
		last_draw_ms = 0.0
	last_draw_ms += milliseconds
	max_draw_ms = maxf(max_draw_ms,last_draw_ms)

func _urban_contents() -> Dictionary:
	# Snapshot only values that affect commands, in their exact draw order.
	# Fresh arrays own the signature; packed geometry uses value semantics.
	var content := {"roads":[],"centers":[],"corridors":[],"public":[],"lots":[],"fabric":[]}
	for road in roads: content["roads"].append([road["polygon"],road["color"]])
	if _miniature_style(): content["roads"].append([street_material_key,city.era])
	if _classical_streets():
		content["roads"].append(classical_street_surface.key)
		content["lots"].append(classical_frontage_ground.key)
	for center in city.centers:
		if bool(center.get("active",true)):
			content["centers"].append([Vector2(float(center["position"][0]),float(center["position"][1])),str(center.get("level","terrace"))])
	for corridor in city.green_corridors:
		if bool(corridor.get("active",true)) and corridor["path"].size() >= 2:
			content["corridors"].append([corridor["path"],float(corridor.get("width",0.24))])
	for reservation in city.planning_reservations: content["public"].append(["reserve",reservation["polygon"]])
	for site in city.public_sites:
		var footprint := PublicGeometry.identity(site)
		if not site["active"]:
			content["public"].append(["inactive",footprint])
		elif site["kind"] == "park":
			content["public"].append(["park",footprint,Vector2(site["position"][0],site["position"][1])])
		else:
			content["public"].append(["civic",footprint,Vector2(site["position"][0],site["position"][1]),
				int(site.get("service_level",1)),site.get("served",[]).size() >= int(site.get("service_capacity",18))])
	content["public"].append(["classical_civic_courts",civic_court.key])
	for line in city.transit_lines:
		for node in line["stops"]:
			var p := city.transit_stop_position(str(node))
			if p == Vector2.INF: continue
			content["public"].append(["stop",p])
	for lot in city.lots:
		if lot["occupant"] != "": content["lots"].append([lot["polygon"],_lot_expression(lot)])
	var cache: Dictionary = city.fabric_cache
	for courtyard in cache.get("courtyards",[]):
		content["fabric"].append(["court",Vector2(float(courtyard["center"][0]),float(courtyard["center"][1])),
			courtyard.get("polygon",PackedVector2Array())])
	for relation in cache.get("shared_walls",[]):
		if not city.by_id.has(relation["a"]) or not city.by_id.has(relation["b"]): continue
		content["fabric"].append(["wall",Coupling.position_of(city.by_id[relation["a"]]),Coupling.position_of(city.by_id[relation["b"]])])
	for row in cache.get("rows",[]):
		var members: Array = row["members"]
		for index in range(members.size()-1):
			if not city.by_id.has(members[index]) or not city.by_id.has(members[index+1]): continue
			content["fabric"].append(["row",Coupling.position_of(city.by_id[members[index]]),Coupling.position_of(city.by_id[members[index+1]])])
	return content
