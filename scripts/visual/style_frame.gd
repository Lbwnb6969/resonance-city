extends Control
## A standalone art review scene; no city simulation or audio output.
const Values = preload("res://scripts/spec_values.gd")
var layout: Dictionary
var entries: Dictionary = {}
var textures: Dictionary = {}
var sprites: Array[Sprite2D] = []
var cells: Dictionary = {}
var camera_cfg: Dictionary
var view_zoom := 1.0
var view_pan := Vector2.ZERO
var zoom_from := 1.0
var zoom_target := 1.0
var pivot := Vector2.ZERO
var fixed_world := Vector2.ZERO
var pan_from := Vector2.ZERO
var camera_age := 1.0
var resetting := false
var panning := false
var show_grid := true
var capture_prefix := "风格小景"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var classical := "--classical-frame" in OS.get_cmdline_user_args()
	var layout_path := "res://资源/古典建筑候选/layout.json" if classical else "res://资源/风格小景/layout.json"
	capture_prefix = "古典建筑小景" if classical else "风格小景"
	layout = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	camera_cfg = Values.load_values()["camera"]
	camera_age = float(camera_cfg["smooth_seconds"])
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(layout.get("manifest","res://资源/风格小景/manifest.json")))
	for entry in manifest["entries"]:
		entries[entry["id"]] = entry
		textures[entry["id"]] = load("res://"+str(entry["texture"]))
		assert(textures[entry["id"]] is Texture2D,"Missing review texture")
	for y in range(layout["land_rows"].size()):
		var row: Array = layout["land_rows"][y]
		for x in range(int(row[0]),int(row[1])+1): cells[Vector2i(x,y)] = true
	var buildings := Node2D.new()
	buildings.y_sort_enabled = true
	add_child(buildings)
	for placement in layout["placements"]:
		var sprite := Sprite2D.new()
		var entry: Dictionary = entries[placement["id"]]
		sprite.texture = textures[placement["id"]]
		sprite.centered = false
		sprite.offset = -Vector2(entry["origin"][0],entry["origin"][1])
		var bounds: Array = entry["model_bounds"]["size"]
		var horizontal := (float(bounds[0])+float(bounds[2]))/sqrt(2.0)
		var camera_span := maxf(horizontal,float(bounds[1])*cos(PI/6.0)+horizontal*0.5)*1.1
		var crop: Array = entry["image_bounds"]["crop"]
		var ppu := float(entry.get("pixels_per_world",2048.0*2048.0/(camera_span*maxf(float(crop[2]),float(crop[3])))))
		var scale_base: float = float(layout["half_width"])*sqrt(2.0)*float(placement["span"])/maxf(float(bounds[0]),float(bounds[2]))/ppu
		sprite.set_meta("base_scale",scale_base)
		sprite.set_meta("cell",Vector2(placement["cell"][0],placement["cell"][1]))
		buildings.add_child(sprite)
		sprites.append(sprite)
	var title := Label.new()
	title.text = layout["name"]
	title.position = Vector2(46,38)
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",Color("526473"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var hint := Label.new()
	hint.text = "滚轮缩放 · 中键轻移 · Home复位 · G网格"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 46
	hint.offset_top = -54
	hint.add_theme_font_size_override("font_size",15)
	hint.add_theme_color_override("font_color",Color("7f939e"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	print("STYLE_FRAME_READY textures=%d placements=%d renderer=%s" % [textures.size(),sprites.size(),RenderingServer.get_current_rendering_method()])
	if "--capture-style-frame" in OS.get_cmdline_user_args(): _capture.call_deferred()

func origin() -> Vector2:
	return Vector2(size.x*0.5,float(layout["origin_y"]))+view_pan

func point(cell: Vector2) -> Vector2:
	return origin()+Vector2((cell.x-cell.y)*float(layout["half_width"]),(cell.x+cell.y)*float(layout["half_height"]))*view_zoom

func polygon(cell: Vector2) -> PackedVector2Array:
	var center := point(cell)
	var half := Vector2(layout["half_width"],layout["half_height"])*view_zoom
	return PackedVector2Array([center+Vector2(-half.x,0),center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y)])

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("e9edf2"))
	if layout == null or layout.is_empty(): return
	# A single soft shadow per tile, with no stacked blur layers.
	for cell in cells:
		var shape := polygon(Vector2(cell))
		for i in range(shape.size()): shape[i] += Vector2(-20,23)*view_zoom
		draw_colored_polygon(shape,Color(0.52,0.64,0.68,0.25))
	for cell in cells:
		var shape := polygon(Vector2(cell))
		var drop := Vector2(0,18)*view_zoom
		if not cells.has(cell+Vector2i.RIGHT): draw_colored_polygon(PackedVector2Array([shape[2],shape[3],shape[3]+drop,shape[2]+drop]),Color("c4d1c9"))
		if not cells.has(cell+Vector2i.DOWN): draw_colored_polygon(PackedVector2Array([shape[0],shape[3],shape[3]+drop,shape[0]+drop]),Color("b8c8c2"))
	for cell in cells:
		draw_colored_polygon(polygon(Vector2(cell)),Color("dde3d7") if posmod(cell.x+cell.y,3) else Color("e1e6db"))
		var shape := polygon(Vector2(cell))
		var directions := [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]
		for i in range(4):
			if not cells.has(cell+directions[i]): draw_line(shape[i],shape[(i+1)%4],Color("eee5d7"),5.0*view_zoom,true)
	var route: PackedVector2Array = []
	for cell in layout["path"]: route.append(point(Vector2(cell[0],cell[1])))
	draw_polyline(route,Color("f5f0e6"),19.0*view_zoom,true)
	for spot in route: draw_circle(spot,9.5*view_zoom,Color("f5f0e6"))
	for branch in layout.get("branches",[]):
		var connection: PackedVector2Array = []
		for cell in branch: connection.append(point(Vector2(cell[0],cell[1])))
		draw_polyline(connection,Color("f5f0e6"),12.0*view_zoom,true)
		for spot in connection: draw_circle(spot,6.0*view_zoom,Color("f5f0e6"))
	if show_grid:
		for cell in cells:
			var shape := polygon(Vector2(cell))
			for i in [0,1]: draw_line(shape[i],shape[i+1],Color(1,1,1,0.38),0.6,true)
			if not cells.has(cell+Vector2i.RIGHT): draw_line(shape[2],shape[3],Color(1,1,1,0.38),0.6,true)
			if not cells.has(cell+Vector2i.DOWN): draw_line(shape[3],shape[0],Color(1,1,1,0.38),0.6,true)

func zoom_at(cursor: Vector2,factor: float) -> void:
	zoom_from = view_zoom
	zoom_target = clampf(zoom_target*factor,float(camera_cfg["minimum_zoom"]),float(camera_cfg["maximum_zoom"]))
	pivot = cursor
	fixed_world = (cursor-origin())/view_zoom
	camera_age = 0.0
	resetting = false

func reset_view() -> void:
	zoom_from = view_zoom
	zoom_target = float(camera_cfg["default_zoom"])
	pan_from = view_pan
	camera_age = 0.0
	resetting = true

func _process(delta: float) -> void:
	var duration := float(camera_cfg["smooth_seconds"])
	if camera_age < duration:
		camera_age = minf(camera_age+delta,duration)
		var t := 1.0-pow(1.0-camera_age/duration,3.0)
		view_zoom = lerpf(zoom_from,zoom_target,t)
		view_pan = pan_from.lerp(Vector2.ZERO,t) if resetting else pivot-Vector2(size.x*0.5,float(layout["origin_y"]))-fixed_world*view_zoom
	for sprite in sprites:
		sprite.position = point(sprite.get_meta("cell"))
		sprite.scale = Vector2.ONE*float(sprite.get_meta("base_scale"))*view_zoom
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			if panning:
				camera_age = float(camera_cfg["smooth_seconds"])
				zoom_target = view_zoom
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position,float(camera_cfg["wheel_multiplier"]) if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/float(camera_cfg["wheel_multiplier"]))
	elif event is InputEventMouseMotion and panning: view_pan += event.relative

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_HOME: reset_view()
		elif event.keycode == KEY_G: show_grid = not show_grid

func _capture() -> void:
	assert(DisplayServer.get_name() != "headless","Review capture needs actual rendering")
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://验证记录/Demo/%s_白网格.png" % capture_prefix)
	show_grid = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://验证记录/Demo/%s_净画面.png" % capture_prefix)
	var cell := Vector2(2.5,2.5)
	var cursor := point(cell)
	var wheel := InputEventMouseButton.new()
	wheel.position = cursor
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	for i in range(4): _gui_input(wheel)
	await get_tree().create_timer(float(camera_cfg["smooth_seconds"])+0.05).timeout
	assert(view_zoom > 1.6 and point(cell).distance_to(cursor) < 0.001)
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	_gui_input(middle)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(48,24)
	var before := view_pan
	_gui_input(motion)
	assert(view_pan == before+motion.relative)
	middle.pressed = false
	_gui_input(middle)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://验证记录/Demo/%s_推近.png" % capture_prefix)
	var home := InputEventKey.new()
	home.pressed = true
	home.keycode = KEY_HOME
	_input(home)
	await get_tree().create_timer(float(camera_cfg["smooth_seconds"])+0.05).timeout
	assert(is_equal_approx(view_zoom,1.0) and view_pan.length() < 0.001)
	for texture in textures.values(): assert(texture.get_image().has_mipmaps())
	print("STYLE_FRAME_CAPTURE actual_GPU two_views + cursor_zoom + middle_pan + Home_reset + imported_mipmaps; human_art=PENDING")
	get_tree().quit()
