extends Node2D
## Heard member footprints, without inventing a larger community boundary.
const IsoProjection = preload("res://scripts/world/world_projection.gd")
var demo: Control
var geometry_key: Array = []
var member_polygons: Array[Dictionary] = []
var geometry_updates := 0
var draw_count := 0

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	visible = false
	geometry_key.clear()
	member_polygons.clear()

func sync() -> void:
	if not demo.community_workbench.opened or demo.black:
		_clear()
		return
	var state: Dictionary = demo.community_workbench.state
	var cid := str(state.get("id",""))
	if cid.is_empty():
		_clear()
		return
	var city = demo.shown_world
	var frame: float = demo.clock.renderer.transport.audible_frame
	var ids: Array[String] = []
	for raw_id in state.get("member_ids",[]):
		var id := str(raw_id)
		if not city.by_id.has(id) or ids.has(id): continue
		var member: Dictionary = city.by_id[id]
		if str(member.get("community_id","")) != cid or int(member.get("birth_frame",0)) > frame: continue
		ids.append(id)
	ids.sort()
	var next_key: Array = [cid,float(city.cfg["space"]["residential_radius"]),
		city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,hash(city.terrain.cfg)]
	for id in ids:
		var member: Dictionary = city.by_id[id]
		var raw: Array = member["position"]
		next_key.append([id,Vector2(float(raw[0]),float(raw[1])),float(member["radius"]),int(member.get("birth_frame",0))])
	if geometry_key != next_key:
		geometry_key = next_key
		geometry_updates += 1
		member_polygons.clear()
		for id in ids:
			var raw: Array = city.by_id[id]["position"]
			var at := Vector2(float(raw[0]),float(raw[1]))
			var footprint: PackedVector2Array = city.building_polygon(at)
			var projected := PackedVector2Array()
			for vertex in footprint:
				projected.append(IsoProjection.to_screen(vertex-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(vertex)))
			projected.append(projected[0])
			member_polygons.append({"id":id,"world_position":at,"footprint":footprint,"polygon":projected})
		queue_redraw()
	# Camera changes transform retained geometry; they do not query footprints
	# or the terrain again. Width stays fixed in screen pixels at every zoom.
	position = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	var next_scale := Vector2.ONE*float(demo.view_zoom)
	if scale != next_scale:
		scale = next_scale
		queue_redraw()
	visible = not member_polygons.is_empty()

func _clear() -> void:
	visible = false
	if geometry_key.is_empty() and member_polygons.is_empty(): return
	geometry_key.clear()
	member_polygons.clear()
	queue_redraw()

func _draw() -> void:
	draw_count += 1
	for member in member_polygons:
		var polygon: PackedVector2Array = member["polygon"]
		draw_polyline(polygon,Color("e5d6b5",0.62),2.4/scale.x,true)
		draw_polyline(polygon,Color("6e8067",0.78),1.0/scale.x,true)
