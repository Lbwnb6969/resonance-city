class_name CityDemoView
extends Control
const Schema = preload("res://scripts/city/district_schema.gd")
const Values = preload("res://scripts/spec_values.gd")
const GrowthMask = preload("res://scripts/visual/audio_growth_mask.gd")
signal district_clicked(id: String)
signal empty_clicked(cell: Vector2i)
signal draft_requested(start: Vector2i, end: Vector2i)
var session: CityInterventions
var selected_id := ""
var hover_cell := Vector2i(-1,-1)
var preview_cell := Vector2i(-1,-1)
var release_mode := false
var draft_mode := false
var draft_start := Vector2i(-1,-1)
var sprites: Dictionary = {}
var textures: Dictionary = {}
var entries: Dictionary = {}
var by_type: Dictionary = {}
var labels: Dictionary = {}
var event_seen: Dictionary = {}
var forms: Dictionary = {}
var appearance: Dictionary = {}
var view_zoom := 1.0
var zoom_from := 1.0
var zoom_target := 1.0
var zoom_pivot := Vector2.ZERO
var zoom_world := Vector2.ZERO
var pan_from := Vector2.ZERO
var camera_age := 1.0
var camera_resetting := false
var base_scales: Dictionary = {}
var view_pan := Vector2.ZERO
var pan_active := false
var camera_cfg: Dictionary
var cfg: Dictionary
var buildings: Node2D
var label_layer: Control
var point_texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cfg = Values.load_values()["growth"]
	camera_cfg = Values.load_values()["camera"]
	view_zoom = float(camera_cfg["default_zoom"])
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/Demo城市/manifest.json"))
	for entry in manifest["entries"]:
		entries[entry["id"]] = entry
		if entry["category"] in ["residential","commercial","industrial"]:
			if not by_type.has(entry["category"]): by_type[entry["category"]] = []
			by_type[entry["category"]].append(entry["id"])
	for list in by_type.values(): list.sort()
	buildings = Node2D.new()
	buildings.y_sort_enabled = true
	buildings.name = "CityBuildings"
	add_child(buildings)
	label_layer = Control.new()
	label_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label_layer)
	var image := Image.create(48,48,false,Image.FORMAT_RGBA8)
	for y in range(48):
		for x in range(48):
			var distance := Vector2(x-23.5,y-23.5).length()/23.5
			image.set_pixel(x,y,Color(0.85,0.7,0.46,pow(maxf(0.0,1.0-distance),2)*0.7))
	point_texture = ImageTexture.create_from_image(image)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _view_origin() -> Vector2:
	return Vector2(size.x*0.5,float(camera_cfg["origin_y"]))+view_pan

func point(cell: Vector2i) -> Vector2:
	return _view_origin()+Vector2((cell.x-cell.y)*float(cfg["tile_half_width"]),(cell.x+cell.y)*float(cfg["tile_half_height"]))*view_zoom

func cell_at(position: Vector2) -> Vector2i:
	var p := (position-_view_origin())/view_zoom
	return Vector2i(roundi((p.x/float(cfg["tile_half_width"])+p.y/float(cfg["tile_half_height"]))*0.5),roundi((p.y/float(cfg["tile_half_height"])-p.x/float(cfg["tile_half_width"]))*0.5))

func zoom_at(position: Vector2, requested: float) -> void:
	zoom_from = view_zoom
	zoom_target = clampf(requested,float(camera_cfg["minimum_zoom"]),float(camera_cfg["maximum_zoom"]))
	zoom_pivot = position
	zoom_world = (position-_view_origin())/view_zoom
	camera_age = 0.0
	camera_resetting = false

func reset_view() -> void:
	zoom_from = view_zoom
	zoom_target = float(camera_cfg["default_zoom"])
	pan_from = view_pan
	pan_active = false
	camera_age = 0.0
	camera_resetting = true

func _sample_camera(delta: float) -> void:
	var duration := float(camera_cfg["smooth_seconds"])
	if camera_age >= duration: return
	camera_age = minf(camera_age+delta,duration)
	var t := 1.0-pow(1.0-camera_age/duration,3.0)
	view_zoom = lerpf(zoom_from,zoom_target,t)
	if camera_resetting:
		view_pan = pan_from.lerp(Vector2.ZERO,t)
	else:
		view_pan = zoom_pivot-Vector2(size.x*0.5,float(camera_cfg["origin_y"]))-zoom_world*view_zoom

func _display_point(d: Dictionary) -> Vector2:
	var center := point(Schema.cell(d))
	if d.has("visual_partner"):
		var partner := session._district(d["visual_partner"])
		return (center+point(Schema.cell(partner)))*0.5
	if not d.get("is_anchor",false):
		var cell := Schema.cell(d)
		var x := float(posmod(cell.x*17+cell.y*7,5)-2)*0.025
		var y := float(posmod(cell.x*11+cell.y*13,5)-2)*0.025
		center += Vector2((x-y)*float(cfg["tile_half_width"]),(x+y)*float(cfg["tile_half_height"]))*view_zoom
	return center

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if pan_active:
			view_pan += event.relative
			hover_cell = Vector2i(-1,-1)
		else:
			hover_cell = cell_at(event.position) if event.position.y >= float(camera_cfg["header_height"]) else Vector2i(-1,-1)
		queue_redraw()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			pan_active = event.pressed and event.position.y >= float(camera_cfg["header_height"])
			if pan_active:
				camera_age = float(camera_cfg["smooth_seconds"])
				zoom_target = view_zoom
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and draft_start.x >= 0:
			var end := cell_at(event.position)
			if event.position.y >= float(camera_cfg["header_height"]) and end.x >= 0 and end.y >= 0 and end.x < 16 and end.y < 16 and end != draft_start:
				draft_requested.emit(draft_start,end)
			draft_start = Vector2i(-1,-1)
			accept_event()
			return
		if event.position.y < float(camera_cfg["header_height"]): return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var factor := float(camera_cfg["wheel_multiplier"])
			zoom_at(event.position,zoom_target*(factor if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/factor))
			accept_event()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := cell_at(event.position)
		if draft_mode:
			if cell.x >= 0 and cell.y >= 0 and cell.x < 16 and cell.y < 16: draft_start = cell
			accept_event()
			return
		if not release_mode:
			var ordered: Array = session.city.duplicate()
			ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return _display_point(a).y > _display_point(b).y)
			for d in ordered:
				var id: String = d["district_id"]
				if not sprites.has(id): continue
				var sprite: Sprite2D = sprites[id]
				if not sprite.visible: continue
				if d.get("is_anchor",false):
					if event.position.distance_to(sprite.position) <= 14*view_zoom:
						district_clicked.emit(id)
						accept_event()
						return
				else:
					var entry: Dictionary = entries[sprite.get_meta("asset_id")]
					var rect := Rect2(sprite.position+sprite.offset*sprite.scale,sprite.texture.get_size()*sprite.scale)
					if rect.has_point(event.position):
						var picked: String = id
						if d.has("visual_partner") and cell == Schema.cell(session._district(d["visual_partner"])): picked = d["visual_partner"]
						district_clicked.emit(picked)
						accept_event()
						return
		if cell.x < 0 or cell.x >= 16 or cell.y < 0 or cell.y >= 16: return
		for d in session.city:
			if Schema.cell(d) == cell:
				district_clicked.emit(d["district_id"])
				return
		empty_clicked.emit(cell)
		accept_event()

func _draw_band(start: Vector2i, end: Vector2i, color: Color) -> void:
	var a := point(start)
	var b := point(end)
	if a.is_equal_approx(b): return
	var direction := (b-a).normalized()
	var side := Vector2(-direction.y,direction.x)
	draw_line(a,b,Color(color,0.13),12.0*view_zoom,true)
	draw_line(a,b,color,2.0,true)
	draw_colored_polygon(PackedVector2Array([b,b-direction*12.0+side*6.0,b-direction*12.0-side*6.0]),color)
	draw_arc(a,4.0*view_zoom,0,TAU,20,color,1.2,true)

func _draw() -> void:
	if cfg == null: return
	var half := Vector2(float(cfg["tile_half_width"]),float(cfg["tile_half_height"]))*view_zoom
	var occupied: Dictionary = {}
	if session != null:
		for d in session.city: occupied[Schema.cell(d)] = d
	for y in range(16):
		for x in range(16):
			var cell := Vector2i(x,y)
			var center := point(cell)
			var vertices := PackedVector2Array([center+Vector2(-half.x,0),center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y)])
			var color := Color("e1e8ec") if (x+y)%2 == 0 else Color("e4eaee")
			if occupied.has(cell) and not str(occupied[cell].get("anchor_id","")).is_empty():
				color = Color("dde2d6") if occupied[cell]["type"] == "residential" else Color("d8e3e7")
				if occupied[cell].get("is_anchor",false): color = Color("e8ddc3")
			if cell == hover_cell: color = Color("d3e0df")
			if cell == preview_cell: color = Color("e8d4bb")
			draw_colored_polygon(vertices,color)
			draw_polyline(PackedVector2Array([vertices[0],vertices[1],vertices[2],vertices[3],vertices[0]]),Color(1.0,1.0,1.0,0.38),0.6,true)
	if session == null: return
	if not session.gravity_band.is_empty():
		var band: Dictionary = session.gravity_band
		_draw_band(Vector2i(band["start"][0],band["start"][1]),Vector2i(band["end"][0],band["end"][1]),Color("93ba9e") if band["bias"] == "residential" else Color("83b0c6"))
	if session.pending.get("verb","") == "draft":
		var band: Dictionary = session.pending
		_draw_band(Vector2i(band["start"][0],band["start"][1]),Vector2i(band["end"][0],band["end"][1]),Color("ba9673"))
	if draft_start.x >= 0 and hover_cell.x >= 0 and hover_cell.y >= 0 and hover_cell.x < 16 and hover_cell.y < 16:
		_draw_band(draft_start,hover_cell,Color("ba9673"))
	var estate_forms: Dictionary = {}
	var rank := {"胚":0,"群":1,"腔":2,"央":3}
	for d in session.city:
		var family: String = d.get("anchor_id","")
		if not family.is_empty() and rank.get(d.get("form","胚"),0) > rank.get(estate_forms.get(family,"胚"),0):
			estate_forms[family] = d["form"]
	# The shared paths are visual estate spacing, not logical road cells that cut adjacency.
	for d in session.city:
		var family: String = d.get("anchor_id","")
		if family.is_empty(): continue
		var cell := Schema.cell(d)
		for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
			var neighbor: Vector2i = cell+direction
			if occupied.has(neighbor) and occupied[neighbor].get("anchor_id","") == family:
				draw_line(point(cell),point(neighbor),Color("f5f0e6"),3.0*view_zoom,true)
	# Highlight the estate perimeter once instead of drawing a ring around every house.
	var edge_directions := [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]
	var edge_vertices := [Vector2(-half.x,0),Vector2(0,-half.y),Vector2(half.x,0),Vector2(0,half.y)]
	for d in session.city:
		var family: String = d.get("anchor_id","")
		var estate_form: String = estate_forms.get(family,"胚")
		if family.is_empty() or estate_form == "胚": continue
		var cell := Schema.cell(d)
		var color := Color("88aab1") if estate_form == "腔" else (Color("ba9673") if estate_form == "央" else Color("f5f0e6"))
		for i in range(4):
			var neighbor: Vector2i = cell+edge_directions[i]
			if not occupied.has(neighbor) or occupied[neighbor].get("anchor_id","") != family:
				draw_line(point(cell)+edge_vertices[i],point(cell)+edge_vertices[(i+1)%4],color,1.6,true)
	for d in session.city:
		var center := point(Schema.cell(d))
		if d["district_id"] == selected_id:
			draw_polyline(PackedVector2Array([center+Vector2(-half.x,0),center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y),center+Vector2(-half.x,0)]),Color("ba9673"),2.5,true)
		if d.get("is_anchor",false):
			draw_arc(center,11*view_zoom,0,TAU,32,Color("ba9673"),1.5,true)

func _process(delta: float) -> void:
	if session == null or buildings == null: return
	_sample_camera(delta)
	if pan_active and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE): pan_active = false
	var clock := get_node("/root/AudioClock")
	var audible := float(clock.renderer.transport.audible_frame)
	var gray: float = clock.renderer.source.get_object().synth.gray_level(int(audible),clock.renderer.transport.sample_rate) if clock.renderer.source.is_valid() else 0.0
	var events: Dictionary = {}
	for event in session.last_result.get("growth_events",[]): events[event["district_id"]] = event
	for d in session.city:
		var id: String = d["district_id"]
		var form: String = d.get("form","胚")
		var created := not sprites.has(id)
		if created:
			var sprite := GrowthMask.new()
			sprite.name = id
			sprite.centered = false
			buildings.add_child(sprite)
			sprites[id] = sprite
			var label := Label.new()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size",12)
			label.add_theme_color_override("font_outline_color",Color("f5f1e9"))
			label.add_theme_color_override("font_color",Color("536d78"))
			label.add_theme_constant_override("outline_size",3)
			label_layer.add_child(label)
			labels[id] = label
			if not events.has(id):
				sprite.progress = 1.0
				sprite.material.set_shader_parameter("growth_progress",1.0)
		var asset_id: String = d.get("manifest_id","")
		if forms.get(id,"") != form or appearance.get(id,"") != asset_id:
			var old_asset: String = appearance.get(id,"")
			appearance[id] = asset_id
			forms[id] = form
			var sprite: Sprite2D = sprites[id]
			if d.get("is_anchor",false):
				sprite.texture = point_texture
				sprite.offset = Vector2(-24,-24)
				base_scales[id] = Vector2.ONE
			else:
				var candidates: Array = by_type[d["type"]]
				var index := 0 if form == "胚" else (1 if form == "群" else 2)
				var entry: Dictionary = entries[d.get("manifest_id",candidates[mini(index,candidates.size()-1)])]
				var path: String = "res://"+str(entry["texture"])
				if not textures.has(path): textures[path] = load(path)
				sprite.texture = textures[path]
				sprite.offset = -Vector2(float(entry["origin"][0]),float(entry["origin"][1]))
				# Reconstruct the baker's per-world-pixel factor, then fit the actual ground plot.
				var bounds: Array = entry["model_bounds"]["size"]
				var horizontal := (float(bounds[0])+float(bounds[2]))/sqrt(2.0)
				var camera_span := maxf(horizontal,float(bounds[1])*cos(PI/6.0)+horizontal*0.5)*1.1
				var crop: Array = entry["image_bounds"]["crop"]
				var pixels_per_world := float(entry.get("pixels_per_world",2048.0*2048.0/(camera_span*maxf(float(crop[2]),float(crop[3])))))
				var fit := float(entry.get("plot_span",cfg["plot_coverage"]))/maxf(float(bounds[0]),float(bounds[2]))
				if entry["category"] != "compound":
					var cell := Schema.cell(d)
					fit *= 1.0-float(posmod(cell.x*7+cell.y*3,4))*0.02
				var world_to_screen := float(cfg["tile_half_width"])*sqrt(2.0)
				base_scales[id] = Vector2.ONE*world_to_screen*fit/pixels_per_world
				sprite.set_meta("asset_id",entry["id"])
				if entry["category"] == "compound" and not old_asset.is_empty() and old_asset != asset_id:
					var event: Dictionary = events.get(id,events.get(d.get("visual_partner",""),{}))
					sprite.begin_at(int(event.get("frame",int(session.last_result.get("frame",0))+clock.renderer.transport.beat_frame(1))))
		if events.has(id) and event_seen.get(id,-1) != events[id]["frame"]:
			event_seen[id] = events[id]["frame"]
			sprites[id].begin_at(int(events[id]["frame"]))
		sprites[id].scale = base_scales[id]*view_zoom
		sprites[id].visible = not d.has("visual_owner")
		sprites[id].position = _display_point(d)
		sprites[id].modulate = Color(1.0-gray*0.35,1.0-gray*0.35,1.0-gray*0.25,0.45 if clock.renderer.transport.audible_frame < int(session.silent_until.get(id,0)) else 1.0)
		var label: Label = labels[id]
		label.position = point(Schema.cell(d))+Vector2(-24,15*view_zoom)
		label.text = ("● %s" % form if d.get("is_anchor",false) else "%s %.0f" % [form,d["vitality"]]) if d["type"] != "industrial" else "工业 %.0f" % d["vitality"]
		label.visible = sprites[id].progress >= 1.0 and (id == selected_id or Schema.cell(d) == hover_cell)
	queue_redraw()
