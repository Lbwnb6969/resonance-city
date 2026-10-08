class_name CityDemoView
extends Control
const Schema = preload("res://scripts/city/district_schema.gd")
const Values = preload("res://scripts/spec_values.gd")
const GrowthMask = preload("res://scripts/visual/audio_growth_mask.gd")
signal district_clicked(id: String)
signal empty_clicked(cell: Vector2i)
var session: CityInterventions
var selected_id := ""
var hover_cell := Vector2i(-1,-1)
var preview_cell := Vector2i(-1,-1)
var release_mode := false
var sprites: Dictionary = {}
var textures: Dictionary = {}
var entries: Dictionary = {}
var by_type: Dictionary = {}
var labels: Dictionary = {}
var event_seen: Dictionary = {}
var forms: Dictionary = {}
var cfg: Dictionary
var buildings: Node2D
var label_layer: Control
var point_texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	cfg = Values.load_values()["growth"]
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/P0城市/manifest.json"))
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
			image.set_pixel(x,y,Color(1.0,0.85,0.5,pow(maxf(0.0,1.0-distance),2)))
	point_texture = ImageTexture.create_from_image(image)
	mouse_filter = Control.MOUSE_FILTER_STOP

func point(cell: Vector2i) -> Vector2:
	return Vector2(size.x*0.5,150)+Vector2((cell.x-cell.y)*float(cfg["tile_half_width"]),(cell.x+cell.y)*float(cfg["tile_half_height"]))

func cell_at(position: Vector2) -> Vector2i:
	var p := position-Vector2(size.x*0.5,150)
	return Vector2i(roundi((p.x/float(cfg["tile_half_width"])+p.y/float(cfg["tile_half_height"]))*0.5),roundi((p.y/float(cfg["tile_half_height"])-p.x/float(cfg["tile_half_width"]))*0.5))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_cell = cell_at(event.position)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := cell_at(event.position)
		if not release_mode:
			var ordered: Array = session.city.duplicate()
			ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return point(Schema.cell(a)).y > point(Schema.cell(b)).y)
			for d in ordered:
				var id: String = d["district_id"]
				if not sprites.has(id): continue
				var sprite: Sprite2D = sprites[id]
				if d.get("is_anchor",false):
					if event.position.distance_to(sprite.position) <= 14:
						district_clicked.emit(id)
						accept_event()
						return
				else:
					var entry: Dictionary = entries[sprite.get_meta("asset_id")]
					var crop: Array = entry["image_bounds"]["crop"]
					var rect := Rect2(sprite.position+(sprite.offset+Vector2(crop[0],crop[1]))*sprite.scale,Vector2(crop[2]-crop[0],crop[3]-crop[1])*sprite.scale)
					if rect.has_point(event.position):
						district_clicked.emit(id)
						accept_event()
						return
		if cell.x < 0 or cell.x >= 16 or cell.y < 0 or cell.y >= 16: return
		for d in session.city:
			if Schema.cell(d) == cell:
				district_clicked.emit(d["district_id"])
				return
		empty_clicked.emit(cell)
		accept_event()

func _draw() -> void:
	if cfg == null: return
	var half := Vector2(float(cfg["tile_half_width"]),float(cfg["tile_half_height"]))
	for y in range(16):
		for x in range(16):
			var cell := Vector2i(x,y)
			var center := point(cell)
			var vertices := PackedVector2Array([center+Vector2(-half.x,0),center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y)])
			var color := Color("353e45") if (x+y)%2 == 0 else Color("323a41")
			if cell == hover_cell: color = Color("54655e")
			if cell == preview_cell: color = Color("8b7149")
			draw_colored_polygon(vertices,color)
			draw_polyline(PackedVector2Array([vertices[0],vertices[1],vertices[2],vertices[3],vertices[0]]),Color("495158"),0.6,true)
	if session == null: return
	for d in session.city:
		var center := point(Schema.cell(d))
		if d["district_id"] == selected_id:
			draw_polyline(PackedVector2Array([center+Vector2(-half.x,0),center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y),center+Vector2(-half.x,0)]),Color("ffd98a"),2.5,true)
		if d.get("form","") == "腔":
			draw_arc(center,23,0,TAU,32,Color("7fb8c3"),1.2,true)
		if d.get("is_anchor",false):
			draw_arc(center,11,0,TAU,32,Color("ffd98a"),1.5,true)

func _process(_delta: float) -> void:
	if session == null or buildings == null: return
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
			label.add_theme_color_override("font_outline_color",Color("22272d"))
			label.add_theme_constant_override("outline_size",4)
			label_layer.add_child(label)
			labels[id] = label
			if not events.has(id):
				sprite.progress = 1.0
				sprite.material.set_shader_parameter("growth_progress",1.0)
		if forms.get(id,"") != form:
			forms[id] = form
			var sprite: Sprite2D = sprites[id]
			if d.get("is_anchor",false):
				sprite.texture = point_texture
				sprite.offset = Vector2(-24,-24)
				sprite.scale = Vector2.ONE
			else:
				var candidates: Array = by_type[d["type"]]
				var index := 0 if form == "胚" else (1 if form == "群" else 2)
				var entry: Dictionary = entries[d.get("manifest_id",candidates[mini(index,candidates.size()-1)])]
				var path: String = "res://"+str(entry["texture"])
				if not textures.has(path): textures[path] = load(path)
				sprite.texture = textures[path]
				sprite.offset = -Vector2(float(entry["origin"][0]),float(entry["origin"][1]))
				var width := float(entry["image_bounds"]["crop"][2])-float(entry["image_bounds"]["crop"][0])
				sprite.scale = Vector2.ONE*(48.0 if form == "胚" else (58.0 if form == "群" else 58.0))/width
				sprite.set_meta("asset_id",entry["id"])
		if events.has(id) and event_seen.get(id,-1) != events[id]["frame"]:
			event_seen[id] = events[id]["frame"]
			sprites[id].begin_at(int(events[id]["frame"]))
		sprites[id].position = point(Schema.cell(d))
		sprites[id].modulate = Color(1.0-gray*0.35,1.0-gray*0.35,1.0-gray*0.25,0.45 if clock.renderer.transport.audible_frame < int(session.silent_until.get(id,0)) else 1.0)
		var label: Label = labels[id]
		label.position = point(Schema.cell(d))+Vector2(-24,15)
		label.text = ("● %s" % form if d.get("is_anchor",false) else "%s %.0f" % [form,d["vitality"]]) if d["type"] != "industrial" else "工业 %.0f" % d["vitality"]
		label.visible = sprites[id].progress >= 1.0 and (id == selected_id or Schema.cell(d) == hover_cell)
	queue_redraw()
