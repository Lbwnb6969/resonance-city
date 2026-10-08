class_name CityDemoView
extends Control
const Landscape = preload("res://scripts/visual/community_landscape.gd")
const Diagnosis = preload("res://scripts/visual/boundary_diagnosis.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Values = preload("res://scripts/spec_values.gd")
const GrowthMask = preload("res://scripts/visual/audio_growth_mask.gd")
signal district_clicked(id: String)
signal empty_clicked(cell: Vector2i)
signal draft_requested(start: Vector2i, end: Vector2i)
signal tread_selected(start: Vector2i, end: Vector2i)
var diagnosis := Diagnosis.new()
var diagnosis_enabled := false
var reduced_motion := false
var diagnosis_edges: Array[Dictionary] = []
var session: CityInterventions
var selected_id := ""
var hover_cell := Vector2i(-1,-1)
var preview_cell := Vector2i(-1,-1)
var release_mode := false
var release_midi := 48
var pointer_position := Vector2.ZERO
var pointer_inside := false
var tread_mode := false
var tread_start := Vector2i(-1,-1)
var tread_candidate: Dictionary = {}
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
var camera_focusing := false
var pan_target := Vector2.ZERO
var base_scales: Dictionary = {}
var view_pan := Vector2.ZERO
var pan_active := false
var camera_cfg: Dictionary
var cfg: Dictionary
var landscape_cfg: Dictionary
var tree_ids: Array[String] = []
var landscape_slots: Array[Dictionary] = []
var landscape_sprites: Dictionary = {}
var landscape_key := ""
var terrain_cfg: Dictionary
var map_size := Vector2i.ZERO
var buildings: Node2D
var label_layer: Control
var point_texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cfg = Values.load_values()["growth"]
	terrain_cfg = Values.load_values()["terrain"]
	landscape_cfg = Values.load_values()["landscape"]
	var space: Dictionary = Values.load_values()["city"]
	map_size = Vector2i(int(space["width"]),int(space["height"]))
	camera_cfg = Values.load_values()["camera"]
	view_zoom = float(camera_cfg["default_zoom"])
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/Demo城市/manifest.json"))
	for entry in manifest["entries"]:
		entries[entry["id"]] = entry
		if entry["category"] == "tree": tree_ids.append(entry["id"])
		if entry["category"] in ["residential","commercial","industrial"]:
			if not by_type.has(entry["category"]): by_type[entry["category"]] = []
			by_type[entry["category"]].append(entry["id"])
	tree_ids.sort_custom(func(a: String,b: String) -> bool: return float(entries[a]["model_bounds"]["size"][1]) < float(entries[b]["model_bounds"]["size"][1]))
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
	mouse_exited.connect(func() -> void:
		pointer_inside = false
		hover_cell = Vector2i(-1,-1))

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
	camera_focusing = false

func reset_view() -> void:
	zoom_from = view_zoom
	zoom_target = float(camera_cfg["default_zoom"])
	pan_from = view_pan
	pan_active = false
	camera_age = 0.0
	camera_resetting = true
	camera_focusing = false

func focus_selected() -> bool:
	var district := session._district(selected_id)
	if district.is_empty(): return false
	var owner: String = district.get("visual_owner",selected_id)
	if not sprites.has(owner): return false
	var sprite: Sprite2D = sprites[owner]
	if not sprite.visible: return false
	var rect := sprite.get_rect()
	var scale_at_one: Vector2 = base_scales[owner]
	var world := (_display_point(session._district(owner))-_view_origin())/view_zoom+rect.get_center()*scale_at_one
	var upper := float(camera_cfg["header_height"])
	var bottom := size.y
	var notice := get_node_or_null("MapNotice") as Control
	if notice != null: bottom = minf(bottom,notice.position.y)
	var available := Vector2(size.x,maxf(1.0,bottom-upper))
	var target := Vector2(available.x*0.5,upper+available.y*0.5)
	var extent := rect.size*scale_at_one
	var fit := minf(available.x/extent.x,available.y/extent.y)*float(camera_cfg["focus_margin"])
	zoom_from = view_zoom
	zoom_target = clampf(minf(maxf(view_zoom,float(camera_cfg["focus_zoom"])),fit),float(camera_cfg["minimum_zoom"]),float(camera_cfg["maximum_zoom"]))
	pan_from = view_pan
	pan_target = target-Vector2(size.x*0.5,float(camera_cfg["origin_y"]))-world*zoom_target
	pan_active = false
	camera_age = 0.0
	camera_resetting = false
	camera_focusing = true
	return true

func _sample_camera(delta: float) -> void:
	var duration := float(camera_cfg["smooth_seconds"])
	if camera_age >= duration: return
	camera_age = minf(camera_age+delta,duration)
	var t := 1.0-pow(1.0-camera_age/duration,3.0)
	view_zoom = lerpf(zoom_from,zoom_target,t)
	if camera_resetting or camera_focusing:
		view_pan = pan_from.lerp(pan_target if camera_focusing else Vector2.ZERO,t)
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

func _contains_visible_pixel(sprite: AudioGrowthMask, position: Vector2) -> bool:
	var local := sprite.to_local(get_global_transform()*position)
	if not sprite.is_pixel_opaque(local): return false
	var rect := sprite.get_rect()
	return 1.0-(local.y-rect.position.y)/rect.size.y <= sprite.progress

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer_position = event.position
		pointer_inside = event.position.y >= float(camera_cfg["header_height"]) and Rect2(Vector2.ZERO,size).has_point(event.position)
		hover_cell = cell_at(pointer_position) if pointer_inside and not pan_active else Vector2i(-1,-1)
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
				camera_focusing = false
				camera_resetting = false
				camera_age = float(camera_cfg["smooth_seconds"])
				zoom_target = view_zoom
				tread_start = Vector2i(-1,-1)
				draft_start = Vector2i(-1,-1)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and tread_start.x >= 0:
			var end := cell_at(event.position)
			if event.position.y >= float(camera_cfg["header_height"]) and Roads.valid(tread_start,end): tread_selected.emit(tread_start,end)
			tread_start = Vector2i(-1,-1)
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
		if tread_mode:
			if cell.x >= 0 and cell.y >= 0 and cell.x < 16 and cell.y < 16: tread_start = cell
			accept_event()
			return
		if draft_mode:
			if cell.x >= 0 and cell.y >= 0 and cell.x < 16 and cell.y < 16: draft_start = cell
			accept_event()
			return
		if release_mode:
			empty_clicked.emit(cell)
			accept_event()
			return
		if not release_mode:
			var ordered: Array = session.city.duplicate()
			ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return _display_point(a).y > _display_point(b).y)
			for d in ordered:
				var id: String = d["district_id"]
				if not sprites.has(id): continue
				var sprite: AudioGrowthMask = sprites[id]
				if not sprite.visible: continue
				if d.get("is_anchor",false):
					if event.position.distance_to(sprite.position) <= 14*view_zoom:
						district_clicked.emit(id)
						accept_event()
						return
				else:
					if _contains_visible_pixel(sprite,event.position):
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

func _draw_tread_edge(a: Vector2i,b: Vector2i,count: int,color: Color) -> void:
	var middle := (point(a)+point(b))*0.5
	var half := Vector2(float(cfg["tile_half_width"]),float(cfg["tile_half_height"]))*view_zoom
	var span := (Vector2(-half.x,half.y) if a.x != b.x else Vector2(half.x,half.y))*0.45
	var formed := count >= int(Roads.settings()["tread"]["threshold"])
	draw_line(middle-span,middle+span,Color("f5f0e6"),7.0*view_zoom,true)
	draw_line(middle-span,middle+span,color,(4.0 if formed else 1.2)*view_zoom,true)
	if not formed:
		var total := int(Roads.settings()["tread"]["threshold"])
		for i in range(total):
			var position := (middle-span).lerp(middle+span,float(i+1)/float(total+1))
			draw_circle(position,2.4*view_zoom,color if i < count else Color(color,0.22))

func diagnosis_points(edge: Dictionary, band: int = 0) -> PackedVector2Array:
	var a: Vector2i = edge["cell_a"]
	var b: Vector2i = edge["cell_b"]
	var middle := (point(a)+point(b))*0.5
	var half := Vector2(cfg["tile_half_width"],cfg["tile_half_height"])*view_zoom
	var span := (Vector2(-half.x,half.y) if a.x != b.x else Vector2(half.x,half.y))*float(diagnosis.cfg["span_ratio"])
	var normal := Vector2(-span.y,span.x).normalized()
	var points := PackedVector2Array()
	var count := int(diagnosis.cfg["samples"])
	var amplitude := float(diagnosis.cfg["amplitude_px"])*view_zoom
	var static_wave: bool = reduced_motion or not edge["audible"]
	var phase := 0.0
	if not static_wave and edge["kind"] == "抖":
		var clock := get_node("/root/AudioClock")
		phase = TAU*float(edge["display_hz"])*clock.renderer.transport.audible_frame/clock.renderer.transport.sample_rate
	for i in range(count+1):
		var t := float(i)/count
		var offset := 0.0
		if edge["kind"] == "抖":
			var separation := float(diagnosis.cfg["reduced_offset_px"])*view_zoom if static_wave else 0.0
			offset = sin(TAU*float(diagnosis.cfg["wave_cycles"])*t-phase)*(amplitude-separation)+band*separation
		else:
			offset = amplitude*(1.0 if i%2 else -1.0)
		offset *= sin(PI*t)
		points.append(middle-span+span*2.0*t+normal*offset)
	return points

func _draw_diagnosis() -> void:
	if not diagnosis_enabled: return
	for edge in diagnosis_edges:
		if edge["kind"] not in ["抖","刺"]: continue
		var color := Color(diagnosis.cfg["slow_color"] if edge["kind"] == "抖" else diagnosis.cfg["rough_color"])
		color.a = float(diagnosis.cfg["max_alpha"] if edge["audible"] else diagnosis.cfg["inactive_alpha"])
		var width := float(diagnosis.cfg["width_px"])*view_zoom
		if edge["kind"] == "抖" and (reduced_motion or not edge["audible"]):
			draw_polyline(diagnosis_points(edge,-1),color,width,true)
			draw_polyline(diagnosis_points(edge,1),color,width,true)
		else: draw_polyline(diagnosis_points(edge),color,width,true)

func ground_shape(half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		point(Vector2i.ZERO)+Vector2(0,-half.y),
		point(Vector2i(map_size.x-1,0))+Vector2(half.x,0),
		point(map_size-Vector2i.ONE)+Vector2(0,half.y),
		point(Vector2i(0,map_size.y-1))+Vector2(-half.x,0)])

func _sync_landscape(audible: float, gray: float) -> void:
	var key := "%d:%d" % [session.get_instance_id(),session.phrase_index]
	if key != landscape_key:
		landscape_key = key
		landscape_slots = Landscape.slots(session,landscape_cfg,tree_ids)
		var keep: Dictionary = {}
		for slot in landscape_slots:
			keep[slot["key"]] = true
			if landscape_sprites.has(slot["key"]): continue
			var entry: Dictionary = entries[slot["asset_id"]]
			var path: String = "res://"+str(entry["texture"])
			if not textures.has(path): textures[path] = load(path)
			var sprite := GrowthMask.new()
			sprite.name = "Landscape_"+str(landscape_sprites.size())
			sprite.centered = false
			sprite.texture = textures[path]
			sprite.offset = -Vector2(float(entry["origin"][0]),float(entry["origin"][1]))
			sprite.set_meta("asset_id",slot["asset_id"])
			buildings.add_child(sprite)
			landscape_sprites[slot["key"]] = sprite
			if session.last_result.is_empty():
				sprite.progress = 1.0
				sprite.material.set_shader_parameter("growth_progress",1.0)
			else:
				sprite.begin_at(int(session.last_result["frame"])+get_node("/root/AudioClock").renderer.transport.beat_frame(1))
		for obsolete in landscape_sprites.keys():
			if not keep.has(obsolete):
				landscape_sprites[obsolete].queue_free()
				landscape_sprites.erase(obsolete)
	for slot in landscape_slots:
		var sprite: Sprite2D = landscape_sprites[slot["key"]]
		var cell: Vector2i = slot["cell"]
		var index := tree_ids.find(slot["asset_id"])
		var height: float = landscape_cfg["tree_heights_px"][mini(index,landscape_cfg["tree_heights_px"].size()-1)]
		sprite.scale = Vector2.ONE*height/sprite.texture.get_height()*view_zoom
		var offset := Vector2(float(posmod(cell.x*7+cell.y*3,3)-1)*0.12*float(cfg["tile_half_width"]),-0.12*float(cfg["tile_half_height"]))
		sprite.position = point(cell)+offset*view_zoom
		sprite.visible = not release_mode and (not pointer_inside or cell != hover_cell)
		sprite.modulate = Color(1.0-gray*0.35,1.0-gray*0.35,1.0-gray*0.25,1.0)

func _draw_landscape_ground() -> void:
	var half := Vector2(float(cfg["tile_half_width"]),float(cfg["tile_half_height"]))*view_zoom*float(landscape_cfg["ground_ratio"])
	for slot in landscape_slots:
		var sprite: AudioGrowthMask = landscape_sprites[slot["key"]]
		if not sprite.visible or sprite.progress <= 0.0: continue
		var center := point(slot["cell"])
		var color := Color(landscape_cfg["ground_color"])
		color.a = float(landscape_cfg["ground_alpha"])*sprite.progress
		draw_colored_polygon(PackedVector2Array([center+Vector2(-half.x,0),center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y)]),color)

func _draw_ground_base(shape: PackedVector2Array) -> void:
	var shadow := shape.duplicate()
	var offset := Vector2(terrain_cfg["shadow_offset"][0],terrain_cfg["shadow_offset"][1])*view_zoom
	for i in range(shadow.size()): shadow[i] += offset
	var tint := Color(terrain_cfg["shadow_color"])
	tint.a = float(terrain_cfg["shadow_alpha"])
	draw_colored_polygon(shadow,tint)
	var drop := Vector2(0,float(terrain_cfg["depth_px"]))*view_zoom
	draw_colored_polygon(PackedVector2Array([shape[1],shape[2],shape[2]+drop,shape[1]+drop]),Color(terrain_cfg["side_light"]))
	draw_colored_polygon(PackedVector2Array([shape[2],shape[3],shape[3]+drop,shape[2]+drop]),Color(terrain_cfg["side_dark"]))

func _draw() -> void:
	if cfg == null: return
	var half := Vector2(float(cfg["tile_half_width"]),float(cfg["tile_half_height"]))*view_zoom
	var ground := ground_shape(half)
	_draw_ground_base(ground)
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
			if cell == hover_cell:
				color = Color("d3e0df")
				if release_mode and not session.release_feedback(release_midi,cell)["allowed"]: color = Color("dfc9c7")
			if cell == preview_cell: color = Color("e8d4bb")
			var pending_here: bool = session != null and session.pending.get("verb","") == "release" and session.pending["target"] == [cell.x,cell.y]
			if pending_here: color = Color("e8d4bb")
			draw_colored_polygon(vertices,color)
			draw_polyline(PackedVector2Array([vertices[0],vertices[1],vertices[2],vertices[3],vertices[0]]),Color(1.0,1.0,1.0,0.38),0.6,true)
	ground.append(ground[0])
	draw_polyline(ground,Color(terrain_cfg["rim_color"]),float(terrain_cfg["rim_width_px"])*view_zoom,true)
	if session == null: return
	_draw_landscape_ground()
	_draw_diagnosis()
	if session.pending.get("verb","") == "release":
		var target: Array = session.pending["target"]
		var center := point(Vector2i(target[0],target[1]))
		draw_circle(center,9.0*view_zoom,Color("d2af79"))
		draw_arc(center,13.0*view_zoom,0,TAU,32,Color("ba9673"),1.5,true)
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
			if occupied.has(neighbor) and occupied[neighbor].get("anchor_id","") == family and not Roads.blocked(session.road_marks,cell,neighbor):
				draw_line(point(cell),point(neighbor),Color("f5f0e6"),3.0*view_zoom,true)
	var audible := float(get_node("/root/AudioClock").renderer.transport.audible_frame)
	for mark in session.road_marks.values():
		var count := int(mark["count"])-(1 if audible < int(mark["frame"]) else 0)
		if count > 0: _draw_tread_edge(Vector2i(mark["start"][0],mark["start"][1]),Vector2i(mark["end"][0],mark["end"][1]),count,Color("8ca3af"))
	var candidate: Dictionary = session.pending if session.pending.get("verb","") == "tread" else tread_candidate
	if not candidate.is_empty():
		var a := Vector2i(candidate["start"][0],candidate["start"][1])
		var b := Vector2i(candidate["end"][0],candidate["end"][1])
		if not Roads.blocked(session.road_marks,a,b): _draw_tread_edge(a,b,Roads.count(session.road_marks,a,b),Color("ba9673"))
	if tread_start.x >= 0 and Roads.valid(tread_start,hover_cell): _draw_tread_edge(tread_start,hover_cell,0,Color("ba9673"))
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
			if not occupied.has(neighbor) or occupied[neighbor].get("anchor_id","") != family or Roads.blocked(session.road_marks,cell,neighbor):
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
	hover_cell = cell_at(pointer_position) if pointer_inside and not pan_active else Vector2i(-1,-1)
	if pan_active and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE): pan_active = false
	var clock := get_node("/root/AudioClock")
	var audible := float(clock.renderer.transport.audible_frame)
	var gray: float = clock.renderer.source.get_object().synth.gray_level(int(audible),clock.renderer.transport.sample_rate) if clock.renderer.source.is_valid() else 0.0
	if diagnosis_enabled and clock.renderer.source.is_valid():
		diagnosis_edges.assign(diagnosis.edges(session,clock.renderer.source.get_object().synth,audible))
	else:
		diagnosis_edges.clear()
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
	_sync_landscape(audible,gray)
	queue_redraw()
