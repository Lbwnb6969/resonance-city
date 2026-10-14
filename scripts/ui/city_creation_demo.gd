class_name CityCreationDemo
extends Node3D
## The editable town and its clock are independent of the legacy audio simulation.
const State = preload("res://scripts/world/city_creation_state.gd")
const TownRenderer = preload("res://scripts/visual/city_creation_renderer.gd")
const Music = preload("res://scripts/audio/city_creation_music.gd")
const Life = preload("res://scripts/world/city_creation_life.gd")
const UI = preload("res://scripts/ui/valley_ui_theme.gd")
const SAVE_PATH := "user://city_creation_v1.json"
const UNIT := 1.8
const FLOOR := 1.7
const TOOL_NAMES := ["房屋", "露台", "道路", "移除", "用途", "植被"]
var state := State.new()
var town: Node3D
var music: Node
var life: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var ui_layer: CanvasLayer
var info: Label
var hint: Label
var toast: Label
var quest: Label
var tool_buttons: Array[Button] = []
var undo_button: Button
var redo_button: Button
var music_button: Button
var life_info: Label
var place_panel: PanelContainer
var place_name: LineEdit
var place_description: Label
var selected_house := ""
var life_ui_timer := 0.0
var tool := 0
var focus := Vector3(-3, 0.7, 0)
var yaw := 0.62
var pitch := 0.64
var zoom := 25.0
var pointer := Vector2.ZERO
var orbiting := false
var panning := false
var road_drawing := false
var road_points: Array[Vector2] = []
var vegetation_drawing := false
var vegetation_erasing := false
var vegetation_points: Array[Vector2] = []
var vegetation_radius := 1.4
var vegetation_kind := "olive"
var vegetation_panel: PanelContainer
var life_save_timer := 15.0
var hovered: Dictionary = {}
var candidate: Dictionary = {}
var preview_key := ""
var toast_time := 0.0
var save_delay := -1.0
var persistence := true
var save_blocked := false
var evening := false
var completed: Dictionary = {}
var frame_samples: Array[float] = []
var edit_samples: Array[float] = []

func _ready() -> void:
	persistence = not "--isolated-session" in OS.get_cmdline_user_args()
	state.initialize()
	if "--creation-example" in OS.get_cmdline_user_args():
		persistence = false
		state.restore(JSON.parse_string(FileAccess.get_file_as_string("res://数据/创作河湾样例.json")))
	if persistence and FileAccess.file_exists(SAVE_PATH):
		var loaded: Dictionary = state.load_city(SAVE_PATH)
		if not loaded.ok: save_blocked = true
	_setup_world()
	town = TownRenderer.new()
	town.name = "Town"
	add_child(town)
	town.setup(state)
	music = Music.new()
	music.name = "TownMusic"
	add_child(music)
	music.setup(state)
	life = Life.new()
	life.name = "StreetLife"
	add_child(life)
	life.setup(state)
	life.arrival_callback = func(_kind: String) -> void: music.play_edit("terrace")
	_setup_ui()
	_refresh_ui()
	_message("从一面墙开始。点墙扩房，点屋顶加层。")
	if save_blocked: _message("作品读取失败，原文件已保留。当前河湾不会覆盖它。")
	_update_camera()

func _setup_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("cbd9d4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e7eee3")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0cd")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_bias = 0.03
	add_child(sun)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 140.0
	add_child(camera)
	camera.current = true

func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "Interface"
	add_child(ui_layer)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.make_theme()
	root.theme.default_font_size = 16
	ui_layer.add_child(root)
	var header := _panel(root, Vector2(24, 24), Vector2(284, 0))
	var title := _label("共鸣之城", 28)
	header.add_child(title)
	header.add_child(_label("河湾晨曲 · 留下你的街坊", 14))
	header.add_child(HSeparator.new())
	quest = _label("", 15)
	header.add_child(quest)
	info = _label("", 13)
	info.add_theme_color_override("font_color", UI.MUTED)
	header.add_child(info)
	life_info = _label("", 13)
	header.add_child(life_info)
	var toolbar := PanelContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_stylebox_override("panel", UI.panel(10))
	root.add_child(toolbar)
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toolbar.offset_left = -422
	toolbar.offset_right = 422
	toolbar.offset_top = -97
	toolbar.offset_bottom = -24
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	toolbar.add_child(row)
	for index in range(6):
		var button := _button("%d  %s" % [index + 1, TOOL_NAMES[index]], func() -> void: select_tool(index))
		button.name = "Tool%d" % index
		button.custom_minimum_size = Vector2(104, 48)
		row.add_child(button)
		tool_buttons.append(button)
	undo_button = _button("↶", func() -> void: _history(false))
	undo_button.tooltip_text = "撤销 · Ctrl+Z"
	undo_button.name = "Undo"
	row.add_child(undo_button)
	redo_button = _button("↷", func() -> void: _history(true))
	redo_button.tooltip_text = "重做 · Ctrl+Shift+Z"
	redo_button.name = "Redo"
	row.add_child(redo_button)
	var actions := HBoxContainer.new()
	actions.name = "Actions"
	root.add_child(actions)
	actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	actions.offset_left = -400
	actions.offset_top = 24
	actions.offset_right = -24
	var save := _button("保存", save_city)
	save.name = "Save"
	actions.add_child(save)
	music_button = _button("♫ 音乐", _toggle_music)
	actions.add_child(music_button)
	actions.add_child(_button("☀ 光线", _toggle_light))
	actions.add_child(_button("全景", home_camera))
	place_panel = PanelContainer.new()
	place_panel.name = "Place"
	place_panel.add_theme_stylebox_override("panel", UI.panel(16))
	root.add_child(place_panel)
	place_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	place_panel.offset_left = -310
	place_panel.offset_right = -24
	place_panel.offset_top = 84
	var place_column := VBoxContainer.new()
	place_column.add_theme_constant_override("separation", 8)
	place_panel.add_child(place_column)
	place_column.add_child(_label("给这个地方一种生活", 17))
	place_name = LineEdit.new()
	place_name.placeholder_text = "街坊名字"
	place_name.text_submitted.connect(func(value:String)->void:
		_after_edit(state.set_house_name(selected_house, value), "room")
		place_name.release_focus())
	place_column.add_child(place_name)
	place_description = _label("", 14)
	place_column.add_child(place_description)
	var roles := HBoxContainer.new()
	place_column.add_child(roles)
	for role: String in ["residential", "bakery", "venue"]:
		roles.add_child(_button({"residential":"居所", "bakery":"面包坊", "venue":"演奏庭"}[role], func()->void: _after_edit(state.set_house_role(selected_house,role),"room")))
	place_panel.visible = false
	vegetation_panel = PanelContainer.new()
	vegetation_panel.name = "VegetationOptions"
	vegetation_panel.add_theme_stylebox_override("panel", UI.panel(16))
	root.add_child(vegetation_panel)
	vegetation_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	vegetation_panel.offset_left = -310
	vegetation_panel.offset_right = -24
	vegetation_panel.offset_top = 84
	var garden := VBoxContainer.new()
	garden.add_theme_constant_override("separation",8)
	vegetation_panel.add_child(garden)
	garden.add_child(_label("种一片自己的花园",18))
	var species := OptionButton.new()
	species.name = "Species"
	for label: String in ["橄榄树群", "地中海柏", "低矮灌木"]: species.add_item(label)
	species.item_selected.connect(func(index:int)->void:
		_cancel_draft()
		vegetation_kind = ["olive","cypress","shrub"][index])
	garden.add_child(species)
	var radius := OptionButton.new()
	radius.name = "BrushSize"
	for label: String in ["小笔刷 · 近庭", "中笔刷 · 树群", "大笔刷 · 林带"]: radius.add_item(label)
	radius.select(1)
	radius.item_selected.connect(func(index:int)->void:
		_cancel_draft()
		vegetation_radius = [0.8,1.4,2.4][index])
	garden.add_child(radius)
	garden.add_child(_label("一笔落成树群，松开后可撤销。\nShift 按住擦除，Esc 取消。",14))
	vegetation_panel.visible = false
	var help := _panel(root, Vector2(24, -168), Vector2(284, 0))
	help.get_parent().set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	var help_panel := help.get_parent() as Control
	help_panel.offset_left = 24
	help_panel.offset_right = 308
	help_panel.offset_top = -260
	help_panel.offset_bottom = -112
	hint = _label("", 14)
	help.add_child(hint)
	help.add_child(_label("滚轮缩放 · 右键转动 · 中键平移\nH 全景 · F 隐藏界面 · Ctrl+S 保存", 12))
	toast = _label("", 16)
	toast.add_theme_color_override("font_color", UI.PAPER)
	var toast_style := UI.panel(12)
	toast_style.bg_color = UI.GREEN
	toast.add_theme_stylebox_override("normal", toast_style)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_left = -260
	toast.offset_right = 260
	toast.offset_top = 28
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _panel(parent: Control, position_value: Vector2, minimum: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = position_value
	panel.custom_minimum_size = minimum
	panel.add_theme_stylebox_override("panel", UI.panel(16))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	return column

func _label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text_value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button

func _refresh_ui() -> void:
	var rooms := 0
	var terraces := 0
	completed.clear()
	for house: Dictionary in state.houses:
		for cell: Dictionary in house.cells:
			if cell.kind == "terrace": terraces += 1
			else: rooms += 1
			if str(cell.get("source","seed")) == "player":
				completed["terrace" if cell.kind == "terrace" else "raise" if int(cell.level) > 0 else "extend"] = true
	for road: Dictionary in state.roads:
		if str(road.get("source","seed")) == "player": completed["road"] = true
	info.text = "%d 座房屋  ·  %d 房间  ·  %d 露台" % [state.houses.size(), rooms, terraces]
	quest.text = "今天，给河湾添一点变化\n%s 扩展一格房屋\n%s 做一处高低屋顶\n%s 留一片露台\n%s 拉一条路到门前" % [_check("extend"), _check("raise"), _check("terrace"), _check("road")]
	for i in range(tool_buttons.size()):
		for visual_state in ["normal", "hover", "pressed"]:
			tool_buttons[i].add_theme_stylebox_override(visual_state, UI.button(visual_state, i == tool))
		tool_buttons[i].add_theme_color_override("font_color", UI.PAPER if i == tool else UI.INK)
	hint.text = ["点墙向外扩房，点顶向上加层。\n空地点击，建一座新房。", "点墙伸出露台，点顶留出屋顶花园。\n系统补齐栏杆和支撑。", "按住左键，沿空地拉出小路。\n横跨两岸自动搭桥；Esc 取消。", "点击房屋块移除。\n附属上层一并收回，撤销可恢复。", "点击房屋，起名并选择用途。\n居民沿小路采购、聚会，再回家。", "按住左键画树群；Shift+左键擦除。\n树会避开房屋、道路和水岸。\nEsc 取消预览。"][tool]
	music.update_city(state)
	_refresh_place()

func _check(key: String) -> String:
	return "●" if completed.has(key) else "○"

func select_tool(index: int) -> void:
	tool = index
	_cancel_draft()
	place_panel.visible = tool == 4 and not selected_house.is_empty()
	vegetation_panel.visible = tool == 5
	_refresh_ui()

func _update_camera() -> void:
	camera.size = zoom
	var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	camera.position = focus + direction * 42.0
	camera.look_at(focus)

func home_camera() -> void:
	focus = Vector3(-3, 0.7, 0)
	yaw = 0.62
	pitch = 0.64
	zoom = 25.0
	_update_camera()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = event.position
		if orbiting:
			yaw -= event.relative.x * 0.008
			pitch = clampf(pitch + event.relative.y * 0.005, 0.3, 1.2)
			_update_camera()
			get_viewport().set_input_as_handled()
		elif panning:
			var right := camera.global_basis.x
			var forward := Vector3(-right.z, 0, right.x)
			focus += (-right * event.relative.x + forward * event.relative.y) * zoom / get_viewport().get_visible_rect().size.y
			_update_camera()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: orbiting = false
		if event.button_index == MOUSE_BUTTON_MIDDLE: panning = false
		if event.button_index == MOUSE_BUTTON_LEFT and road_drawing: _finish_road()
		if event.button_index == MOUSE_BUTTON_LEFT and vegetation_drawing: _finish_vegetation()
	if event is InputEventKey and event.pressed and not event.echo:
		if get_viewport().gui_get_focus_owner() is LineEdit: return
		if event.ctrl_pressed:
			if event.keycode == KEY_Z: _history(event.shift_pressed)
			elif event.keycode == KEY_Y: _history(true)
			elif event.keycode == KEY_S: save_city()
			else: return
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6: select_tool(event.keycode - KEY_1)
		elif event.keycode == KEY_H: home_camera()
		elif event.keycode == KEY_F: ui_layer.visible = not ui_layer.visible
		elif event.keycode == KEY_ESCAPE: _cancel_draft()
		else: return
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		pointer = event.position
		if not event.pressed: return
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom = maxf(9.0, zoom * 0.9)
				_update_camera()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = minf(50.0, zoom * 1.1)
				_update_camera()
			MOUSE_BUTTON_RIGHT: orbiting = true
			MOUSE_BUTTON_MIDDLE: panning = true
			MOUSE_BUTTON_LEFT:
				if tool == 2:
					road_drawing = true
					road_points.clear()
					_append_road_point()
				elif tool == 5:
					vegetation_drawing = true
					vegetation_erasing = event.shift_pressed or Input.is_key_pressed(KEY_SHIFT)
					vegetation_points.clear()
					_append_vegetation_point()
				else:
					_update_hover()
					_commit_click()

func _process(delta: float) -> void:
	frame_samples.append(delta*1000.0)
	if frame_samples.size() > 240: frame_samples.pop_front()
	life_ui_timer -= delta
	if life_ui_timer < 0.0:
		life_ui_timer = 0.5
		life_info.text = life.summary()
	life_save_timer -= delta
	if life_save_timer < 0.0:
		life_save_timer = 15.0
		if state.life_progress_dirty and persistence and not save_blocked:
			var saved: Dictionary = state.save_city(SAVE_PATH)
			if not saved.ok: _message(saved.message)
	if toast_time > 0.0:
		toast_time -= delta
		toast.visible = toast_time > 0.0
	if save_delay >= 0.0:
		save_delay -= delta
		if save_delay < 0.0 and state.dirty and persistence and not save_blocked:
			var saved: Dictionary = state.save_city(SAVE_PATH)
			if not saved.ok: _message(saved.message)
	if not orbiting and not panning:
		if road_drawing: _append_road_point()
		elif vegetation_drawing: _append_vegetation_point()
		elif not ui_layer.visible:
			town.clear_preview()
			preview_key = ""
		elif get_viewport().gui_get_hovered_control() == null: _update_hover()
		else:
			town.clear_preview()
			preview_key = ""

func _ray_hit(screen: Vector2) -> Dictionary:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 120.0)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _ground_at(screen: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	var distance := -origin.y / direction.y
	var p := origin + direction * distance
	return Vector2(p.x, p.z)

func _update_hover() -> void:
	hovered = _ray_hit(pointer)
	candidate.clear()
	if tool == 2: return
	if tool == 5:
		var ground := _ground_at(pointer)
		var brush_key := str([ground,vegetation_radius,Input.is_key_pressed(KEY_SHIFT)])
		if preview_key == brush_key: return
		preview_key = brush_key
		if town.has_method("show_vegetation_brush"):
			town.show_vegetation_brush(ground, vegetation_radius, Input.is_key_pressed(KEY_SHIFT))
		return
	var body: Object = hovered.get("collider")
	if body != null and body.has_meta("house_id"):
		var house_id := str(body.get_meta("house_id"))
		var cell_id := str(body.get_meta("cell_id"))
		var cell := _find_cell(house_id, cell_id)
		if cell.is_empty(): return
		if tool == 4:
			candidate = {"select":house_id}
		elif tool == 3:
			candidate = {"house_id": house_id, "cell_id": cell_id, "erase": true}
		else:
			var normal: Vector3 = hovered.normal
			var target := cell.duplicate(true)
			if normal.y > 0.45: target.level = int(cell.level) + 1
			elif absf(normal.x) > absf(normal.z): target.x = int(cell.x) + (1 if normal.x > 0.0 else -1)
			else: target.z = int(cell.z) + (1 if normal.z > 0.0 else -1)
			target.kind = "terrace" if tool == 1 else "room"
			candidate = {"house_id": house_id, "cell": target}
			var check: Dictionary = state.validate_add_cell(house_id, int(target.x), int(target.z), int(target.level), str(target.kind))
			candidate["valid"] = check.ok
			candidate["reason"] = check.message
	elif tool == 0:
		var position_value := _ground_at(pointer)
		var check: Dictionary = state.validate_add_house(position_value)
		candidate = {"new_house": position_value, "valid": check.ok, "reason": check.message}
	var key := str(candidate)
	if key == preview_key: return
	preview_key = key
	town.clear_preview()
	if candidate.has("cell"):
		town.set_preview(str(candidate.house_id), candidate.cell, bool(candidate.valid))
	elif candidate.has("new_house"):
		# A standalone preview has its own origin; it never enters the state.
		town.set_preview("", {"x":0, "z":0, "level":0, "kind":"room", "origin":[candidate.new_house.x, candidate.new_house.y]}, bool(candidate.valid))

func _find_cell(house_id: String, cell_id: String) -> Dictionary:
	for house: Dictionary in state.houses:
		if str(house.id) == house_id:
			for cell: Dictionary in house.cells:
				if str(cell.id) == cell_id: return cell
	return {}

func _commit_click() -> void:
	if candidate.is_empty(): return
	if candidate.has("select"):
		selected_house = str(candidate.select)
		place_panel.visible = true
		_refresh_place()
		return
	var result: Dictionary
	var action_kind := "room"
	if candidate.has("erase"):
		result = state.remove_cell(str(candidate.house_id), str(candidate.cell_id))
		action_kind = "erase"
	elif candidate.has("new_house"):
		result = state.add_house(candidate.new_house)
	elif candidate.has("cell"):
		var cell: Dictionary = candidate.cell
		result = state.add_cell(str(candidate.house_id), int(cell.x), int(cell.z), int(cell.level), str(cell.kind))
		action_kind = str(cell.kind)
		if result.ok:
			completed["terrace" if cell.kind == "terrace" else "raise" if int(cell.level) > 0 else "extend"] = true
	else: return
	_after_edit(result, action_kind)

func _append_road_point() -> void:
	var p := _ground_at(pointer)
	if road_points.is_empty() or road_points[-1].distance_to(p) > 0.25:
		road_points.append(p)
		town.preview_road(road_points)

func _finish_road() -> void:
	road_drawing = false
	if road_points.size() < 2:
		_cancel_draft()
		return
	var result: Dictionary = state.add_road(road_points)
	if result.ok: completed["road"] = true
	_after_edit(result, "road")
	road_points.clear()

func _append_vegetation_point() -> void:
	var p := _ground_at(pointer)
	if vegetation_points.is_empty() or vegetation_points[-1].distance_to(p) > 0.22:
		vegetation_points.append(p)
		if town.has_method("show_vegetation_brush"):
			town.show_vegetation_brush(p, vegetation_radius, vegetation_erasing, vegetation_points)

func _finish_vegetation() -> void:
	vegetation_drawing = false
	if vegetation_points.is_empty():
		_cancel_draft()
		return
	var result: Dictionary
	if vegetation_erasing:
		result = state.erase_vegetation_stroke(vegetation_points, vegetation_radius)
	else:
		result = state.add_vegetation_stroke(vegetation_points, vegetation_kind, vegetation_radius)
	_after_edit(result, "erase" if vegetation_erasing else "terrace")
	vegetation_points.clear()

func _after_edit(result: Dictionary, kind: String) -> void:
	_message(str(result.message))
	if not result.ok: return
	var started := Time.get_ticks_usec()
	town.clear_preview()
	town.rebuild()
	preview_key = ""
	music.play_edit(kind)
	save_delay = 3.0
	_refresh_ui()
	edit_samples.append(float(Time.get_ticks_usec()-started)/1000.0)

func _history(forward: bool) -> void:
	_cancel_draft()
	_after_edit(state.redo() if forward else state.undo(), "history")

func _cancel_draft() -> void:
	road_drawing = false
	road_points.clear()
	vegetation_drawing = false
	vegetation_points.clear()
	candidate.clear()
	preview_key = ""
	if town != null: town.clear_preview()

func save_city() -> void:
	if save_blocked:
		_message("原作品读取失败，已保留原文件；当前试玩可继续编辑。")
		return
	var result: Dictionary = state.save_city(SAVE_PATH)
	_message("河湾已保存，下次从这里继续。" if result.ok else str(result.message))

func _toggle_music() -> void:
	music.set_muted(not music.muted)
	music_button.text = "♫ 静音" if music.muted else "♫ 音乐"

func _toggle_light() -> void:
	evening = not evening
	sun.light_color = Color("ffc390") if evening else Color("fff0cd")
	sun.light_energy = 0.55 if evening else 0.65
	sun.rotation_degrees.x = -24.0 if evening else -48.0

func _refresh_place() -> void:
	if selected_house.is_empty() or place_name == null: return
	for house: Dictionary in state.houses:
		if str(house.id) != selected_house: continue
		if not place_name.has_focus(): place_name.text = str(house.get("name", "无名小屋"))
		var role := str(house.get("role", "residential"))
		place_description.text = {"residential":"一处居所，让街坊有居民。", "bakery":"面包出炉，居民循路来采购。", "venue":"一处演奏庭，招呼街坊来小聚。"}[role]
		place_description.text += "\n门前小路已接通。" if life.house_connected(selected_house) else "\n拉一条小路到门前，让居民能走来。"
		return

func _message(text_value: String) -> void:
	if toast == null: return
	toast.text = text_value
	toast.visible = true
	toast_time = 4.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if persistence and not save_blocked and state.dirty: state.save_city(SAVE_PATH)

func diagnostics() -> Dictionary:
	var sorted := frame_samples.duplicate()
	sorted.sort()
	return {"engine":Engine.get_version_info().string,"fps":Engine.get_frames_per_second(),
		"frame_p95_ms":sorted[int((sorted.size()-1)*0.95)] if not sorted.is_empty() else 0.0,
		"edit_rebuild_ms":edit_samples.duplicate(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render_updates":town.rebuild_stats.duplicate(),"plants":state.plants.size(),
		"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"audio":music.audio_report,"life":{"residents":life.residents.size(),"purchases":life.purchases,"gatherings":life.gatherings},
		"milestones":completed.duplicate(),"world":state.snapshot()}
