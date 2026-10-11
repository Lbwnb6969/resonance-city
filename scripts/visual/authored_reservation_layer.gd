extends Node2D
## Read-only emphasis for the land an actual authored family still preserves.
## Ordinary reservations retain the ground layer's existing fill and outline.
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const LABEL := "你留下的空地"
const FONT_SIZE := 13

class GrassGround extends Node2D:
	var parcels: Array[Dictionary] = []
	func _draw() -> void:
		for parcel in parcels:
			draw_colored_polygon(parcel["polygon"],Color(0.62,0.72,0.49,0.34))
			for patch in parcel["patches"]:
				draw_colored_polygon(patch,Color(0.45,0.61,0.36,0.20))
			for stroke in parcel["strokes"]:
				draw_polyline(stroke,Color(0.36,0.50,0.31,0.76),1.1,true)

var ground: GrassGround
var parcels: Array[Dictionary] = []

static func _grass_patch(center: Vector2,radius: Vector2,polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var patch := PackedVector2Array()
	for index in range(12):
		var angle := TAU*float(index)/12.0
		var roughness := 0.86 if index % 3 == 0 else 1.0
		patch.append(center+Vector2(cos(angle),sin(angle))*radius*roughness)
	return Geometry2D.intersect_polygons(patch,polygon)

static func records(world: RefCounted) -> Array[Dictionary]:
	## Everything below is derived drawing data, never new reservation state.
	var authored_ids: Dictionary = {}
	for family: Dictionary in world.families.values():
		if not bool(family.get("player_expression",false)): continue
		var id := str(family.get("expression_reservation_id",""))
		if not id.is_empty(): authored_ids[id] = true
	var result: Array[Dictionary] = []
	for reservation: Dictionary in world.planning_reservations:
		var id := str(reservation.get("reservation_id",reservation.get("id","")))
		if not authored_ids.has(id) or not bool(reservation.get("active",true)): continue
		var polygon: PackedVector2Array = reservation["polygon"]
		var box := SpatialPlanning.bounds(polygon)
		var patches: Array[PackedVector2Array] = []
		# Two low, uneven edge patches leave the middle visibly unbuilt. No paths,
		# furniture, tree canopy or park emblem imply a completed public facility.
		for offset: Vector2 in [Vector2(0.23,0.30),Vector2(0.76,0.73)]:
			patches.append_array(_grass_patch(box.position+box.size*offset,box.size*Vector2(0.22,0.29),polygon))
		var strokes: Array[PackedVector2Array] = []
		for offset: Vector2 in [Vector2(0.20,0.34),Vector2(0.34,0.22),Vector2(0.72,0.80),Vector2(0.83,0.63)]:
			var at := box.position+box.size*offset
			var length := minf(box.size.x,box.size.y)*0.075
			for direction: Vector2 in [Vector2(-0.65,-0.78),Vector2(0.45,-0.90)]:
				var tip := at+direction*length
				if Geometry2D.is_point_in_polygon(at,polygon) and Geometry2D.is_point_in_polygon(tip,polygon):
					strokes.append(PackedVector2Array([at,tip]))
		var raw: Array = reservation["position"]
		result.append({"reservation_id":id,"position":Vector2(float(raw[0]),float(raw[1])),
			"polygon":polygon.duplicate(),"patches":patches,"strokes":strokes,"label":LABEL})
	return result

func _project(demo: Control,polygon: PackedVector2Array) -> PackedVector2Array:
	var projected := PackedVector2Array()
	for point in polygon: projected.append(demo.point(point))
	return projected

func sync(demo: Control) -> void:
	if ground == null:
		ground = GrassGround.new()
		ground.name = "PreservedGrass"
		ground.z_as_relative = false
		ground.z_index = -27
		add_child(ground)
		z_index = 52
	visible = not demo.black
	if not visible: return
	ground.modulate = demo.daylight_state.get("world_tint",Color.WHITE)
	var next: Array[Dictionary] = []
	var viewport := Rect2(Vector2.ZERO,demo.size).grow(24.0)
	var font := ThemeDB.fallback_font
	var label_size := font.get_string_size(LABEL,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE)+Vector2(14,8)
	for record in records(demo.shown_world):
		var polygon := _project(demo,record["polygon"])
		var bounds := SpatialPlanning.bounds(polygon)
		if not viewport.intersects(bounds): continue
		var anchor := polygon[0]
		for point in polygon:
			if point.y > anchor.y: anchor = point
		var label_at := anchor+Vector2(-label_size.x*0.5,12)
		label_at.x = clampf(label_at.x,12,maxf(12,demo.size.x-label_size.x-12))
		label_at.y = clampf(label_at.y,70,maxf(70,demo.size.y-label_size.y-54))
		var patches: Array[PackedVector2Array] = []
		for patch in record["patches"]: patches.append(_project(demo,patch))
		var strokes: Array[PackedVector2Array] = []
		for stroke in record["strokes"]: strokes.append(_project(demo,stroke))
		next.append({"reservation_id":record["reservation_id"],"position":record["position"],
			"polygon":polygon,"patches":patches,"strokes":strokes,"anchor":anchor,
			"label_bounds":Rect2(label_at,label_size)})
	if parcels == next: return
	parcels = next
	ground.parcels = next
	ground.queue_redraw()
	queue_redraw()

func hit_reservation(screen_position: Vector2) -> Dictionary:
	## Optional label hit target for the same existing reservation menu. The
	## ground footprint itself already uses World.planning_at in the Demo.
	if not visible: return {}
	for parcel in parcels:
		if parcel["label_bounds"].has_point(screen_position) or Geometry2D.is_point_in_polygon(screen_position,parcel["polygon"]):
			return {"reservation_id":parcel["reservation_id"],"position":parcel["position"]}
	return {}

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for parcel in parcels:
		var bounds: Rect2 = parcel["label_bounds"]
		var anchor: Vector2 = parcel["anchor"]
		draw_line(anchor,bounds.position+Vector2(bounds.size.x*0.5,0),Color(0.32,0.46,0.31,0.60),1.0,true)
		draw_circle(anchor,1.7,Color("6d895b"))
		draw_rect(bounds,Color(0.94,0.95,0.87,0.94))
		draw_rect(Rect2(bounds.position,Vector2(2,bounds.size.y)),Color("829c69"))
		draw_string(font,bounds.position+Vector2(7,4+font.get_ascent(FONT_SIZE)),LABEL,
			HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,Color("49613d"))
