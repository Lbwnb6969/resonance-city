extends Node2D
## Screen-size map names retain their draw commands while the camera and city stay still.
const IsoProjection = preload("res://scripts/world/world_projection.gd")
var geometry_key: Array = []
var layout_key: Array = []
var anchors: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var geometry_updates := 0
var layout_updates := 0
var draw_count := 0
var last_sync_ms := 0.0
var last_draw_ms := 0.0

func sync(demo: Control) -> void:
	var started := Time.get_ticks_usec()
	visible = not demo.black and demo.view_zoom < 1.0
	if not visible:
		last_sync_ms = float(Time.get_ticks_usec()-started)/1000.0
		return
	var city: ContinuousWorld = demo.shown_world
	var font := ThemeDB.fallback_font
	var next_geometry: Array = demo.overlay_key+[city.terrain.noise_seed,city.terrain.river_phase,city.terrain.family,font]
	if geometry_key != next_geometry:
		geometry_key = next_geometry
		geometry_updates += 1
		anchors.clear()
		for community in demo.overlay_communities:
			var p: Vector2 = community["position"]
			anchors.append({"id":community["id"],"name":community["name"],"members":community["members"],
				"position":IsoProjection.to_screen(p-Vector2(16,16),Vector2.ZERO,1.0,Vector2(28,14),city.terrain.height_at(p)),
				"size":Vector2(font.get_string_size(community["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,12).x,font.get_height(12))})
	var selected := str(city.by_id.get(demo.selected_id,{}).get("community_id",""))
	var lead := str(demo.model.synth.theme.get("cid",""))
	var next_layout: Array = geometry_key+[demo.size,demo.pan,demo.view_zoom,selected,lead]
	if layout_key == next_layout:
		last_sync_ms = float(Time.get_ticks_usec()-started)/1000.0
		return
	layout_key = next_layout
	layout_updates += 1
	labels.clear()
	var candidates := anchors.duplicate()
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var ap := 2 if a["id"] == selected else (1 if a["id"] == lead else 0)
		var bp := 2 if b["id"] == selected else (1 if b["id"] == lead else 0)
		if ap != bp: return ap > bp
		if a["members"] != b["members"]: return a["members"] > b["members"]
		return str(a["id"]) < str(b["id"]))
	var origin: Vector2 = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
	var viewport := Rect2(Vector2(24,100),demo.size-Vector2(48,200))
	var occupied: Array[Rect2] = []
	for anchor in candidates:
		var at: Vector2 = origin+anchor["position"]*demo.view_zoom+Vector2(-16,29)
		var bounds := Rect2(at-Vector2(0,font.get_ascent(12)),anchor["size"]).grow(4.0)
		if not viewport.encloses(bounds): continue
		if occupied.any(func(other: Rect2) -> bool: return other.intersects(bounds)): continue
		occupied.append(bounds)
		labels.append({"id":anchor["id"],"name":anchor["name"],"position":at,"bounds":bounds})
	queue_redraw()
	last_sync_ms = float(Time.get_ticks_usec()-started)/1000.0

func _draw() -> void:
	var started := Time.get_ticks_usec()
	draw_count += 1
	for label in labels:
		draw_string(ThemeDB.fallback_font,label["position"],label["name"],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.40,0.48,0.42,0.72))
	last_draw_ms = float(Time.get_ticks_usec()-started)/1000.0
