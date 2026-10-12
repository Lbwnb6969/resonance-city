extends Node2D
## Only the explicitly selected, heard houses; no enclosing administrative border.
const Projection = preload("res://scripts/world/world_projection.gd")
var demo: Control
var geometry_key: Array = []
var member_polygons: Array[Dictionary] = []
var geometry_updates := 0

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	visible = false

func sync() -> void:
	if not demo.neighborhood_editor.opened or demo.black:
		visible = false
		return
	var city = demo.shown_world
	var frame := int(demo.clock.renderer.transport.audible_frame)
	var key: Array = [city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,hash(city.terrain.cfg)]
	for id: String in demo.neighborhood_editor.selected_ids:
		if not city.by_id.has(id): continue
		var house: Dictionary = city.by_id[id]
		if int(house.get("birth_frame",0)) > frame: continue
		key.append([id,house["position"],house["radius"]])
	if key != geometry_key:
		geometry_key = key.duplicate(true)
		geometry_updates += 1
		member_polygons.clear()
		for index in range(4,key.size()):
			var raw: Array = key[index][1]
			var at := Vector2(float(raw[0]),float(raw[1]))
			var footprint: PackedVector2Array = city.building_polygon(at)
			var polygon := PackedVector2Array()
			for vertex in footprint:
				polygon.append(Projection.to_screen(vertex-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(vertex)))
			polygon.append(polygon[0])
			member_polygons.append({"id":str(key[index][0]),"polygon":polygon})
		queue_redraw()
	position = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	var next_scale := Vector2.ONE*float(demo.view_zoom)
	if scale != next_scale:
		scale = next_scale
		queue_redraw()
	visible = not member_polygons.is_empty()

func _draw() -> void:
	for member: Dictionary in member_polygons:
		draw_colored_polygon(member["polygon"],Color("d6b57b",0.16))
		draw_polyline(member["polygon"],Color("f3e2b8",0.94),3.0/scale.x,true)
		draw_polyline(member["polygon"],Color("647961",0.95),1.0/scale.x,true)
