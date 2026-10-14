class_name CityCreationDemo
extends Node3D
## The editable town and its clock are independent of the legacy audio simulation.
const State = preload("res://scripts/world/city_creation_state.gd")
const TownRenderer = preload("res://scripts/visual/city_creation_renderer.gd")
const Music = preload("res://scripts/audio/city_creation_music.gd")
const Life = preload("res://scripts/world/city_creation_life.gd")
const Stroke = preload("res://scripts/world/city_creation_stroke.gd")
const UI = preload("res://scripts/ui/valley_ui_theme.gd")
const SAVE_PATH := "user://city_creation_v1.json"
const UNIT := 1.8
const FLOOR := 1.7
const TOOL_NAMES := ["房屋", "露台", "道路", "移除", "用途", "植被", "水岸", "街坊"]
const DISTRICT_STYLES := ["warm", "deep", "weave"]
const DISTRICT_STYLE_NAMES := {"warm":"暖庭", "deep":"深流", "weave":"织机"}
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
var concert_button: Button
var concert_info: Label
var concert_progress: ProgressBar
var bakery_info: Label
var bakery_progress: ProgressBar
var bakery_button: Button
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
var road_preview: Array[Vector2] = []
var road_straight := false
var road_panel: PanelContainer
var road_status: Label
var vegetation_drawing := false
var vegetation_erasing := false
var vegetation_points: Array[Vector2] = []
var vegetation_radius := 1.4
var vegetation_kind := "olive"
var vegetation_panel: PanelContainer
var water_panel: PanelContainer
var water_status: Label
var water_drawing := false
var water_points: Array[Vector2] = []
var water_kind := "pond"
var water_width := 3.2
var district_panel: PanelContainer
var district_name: LineEdit
var district_style_picker: OptionButton
var district_description: Label
var district_music_status: Label
var district_drawing := false
var district_points: Array[Vector2] = []
var district_distance := 0.0
var district_start_id := ""
var district_width := 5.6
var district_style := "warm"
var selected_district := ""
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
	persistence = persistence and not "--isolated-session" in OS.get_cmdline_user_args()
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
	life.concert_callback = _on_concert_event
	life.production_callback = func(_house_id:String,_quantity:int)->void: music.play_edit("bakery")
	music.set_concert_active(str(life.concert_status().phase) == "playing")
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
	env.ambient_light_color = Color("d4e2df")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff1d7")
	sun.light_energy = 0.58
	sun.shadow_opacity = 0.70
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
	toolbar.offset_left = -518
	toolbar.offset_right = 518
	toolbar.offset_top = -97
	toolbar.offset_bottom = -24
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	toolbar.add_child(row)
	for index in range(TOOL_NAMES.size()):
		var button := _button("%d  %s" % [index + 1, TOOL_NAMES[index]], func() -> void: select_tool(index))
		button.name = "Tool%d" % index
		button.custom_minimum_size = Vector2(100, 48)
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
	concert_button = _button("♫ 邀请街坊演出",_invite_concert)
	concert_button.name = "InviteConcert"
	place_column.add_child(concert_button)
	concert_info = _label("",14)
	concert_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	concert_info.custom_minimum_size.x = 250
	place_column.add_child(concert_info)
	concert_progress = ProgressBar.new()
	concert_progress.show_percentage = false
	concert_progress.custom_minimum_size.y = 8
	place_column.add_child(concert_progress)
	bakery_info = _label("",14)
	bakery_info.name = "BakeryInfo"
	bakery_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bakery_info.custom_minimum_size.x = 250
	place_column.add_child(bakery_info)
	bakery_progress = ProgressBar.new()
	bakery_progress.name = "BakeryProgress"
	bakery_progress.show_percentage = false
	bakery_progress.custom_minimum_size.y = 8
	place_column.add_child(bakery_progress)
	bakery_button = _button("暂停烘焙",func()->void:
		var status: Dictionary = life.bakery_status(selected_house)
		_after_edit(state.set_bakery_open(selected_house,not bool(status.open)),"terrace"))
	bakery_button.name = "BakeryOpen"
	place_column.add_child(bakery_button)
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
	road_panel = PanelContainer.new()
	road_panel.name = "RoadOptions"
	road_panel.add_theme_stylebox_override("panel",UI.panel(16))
	root.add_child(road_panel)
	road_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	road_panel.offset_left = -310
	road_panel.offset_right = -24
	road_panel.offset_top = 84
	var road_column := VBoxContainer.new()
	road_column.add_theme_constant_override("separation",8)
	road_panel.add_child(road_column)
	road_column.add_child(_label("顺着河湾画一条路",18))
	var road_mode := OptionButton.new()
	road_mode.name = "RoadMode"
	for label: String in ["自由曲线", "两点直拉"]: road_mode.add_item(label)
	road_mode.item_selected.connect(func(index:int)->void:
		_cancel_draft()
		road_straight = index == 1)
	road_column.add_child(road_mode)
	road_status = _label("自由拖动，松开铺好。\n接到已有路面，路口自动融合。",14)
	road_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	road_status.custom_minimum_size.x = 260
	road_column.add_child(road_status)
	road_panel.visible = false
	water_panel = PanelContainer.new()
	water_panel.name = "WaterOptions"
	water_panel.add_theme_stylebox_override("panel", UI.panel(16))
	root.add_child(water_panel)
	water_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	water_panel.offset_left = -310
	water_panel.offset_right = -24
	water_panel.offset_top = 84
	var water_column := VBoxContainer.new()
	water_column.add_theme_constant_override("separation",8)
	water_panel.add_child(water_column)
	water_column.add_child(_label("为河湾留一片水",18))
	var water_mode := OptionButton.new()
	water_mode.name = "WaterMode"
	for label: String in ["挖一片池塘", "从水边引出支流"]: water_mode.add_item(label)
	water_mode.item_selected.connect(func(index:int)->void:
		_cancel_draft()
		water_kind = ["pond","channel"][index])
	water_column.add_child(water_mode)
	var water_size := OptionButton.new()
	water_size.name = "WaterWidth"
	for label: String in ["窄岸 · 1.8米", "舒展 · 3.2米", "开阔 · 5米"]: water_size.add_item(label)
	water_size.select(1)
	water_size.item_selected.connect(func(index:int)->void:
		_cancel_draft()
		water_width = [1.8,3.2,5.0][index])
	water_column.add_child(water_size)
	water_status = _label("拖出曲线，松开留下水岸。\nShift 点击移除自己画的水。",14)
	water_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	water_status.custom_minimum_size.x = 260
	water_column.add_child(water_status)
	water_panel.visible = false
	_setup_district_panel(root)
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

func _setup_district_panel(root: Control) -> void:
	district_panel = PanelContainer.new()
	district_panel.name = "DistrictOptions"
	district_panel.add_theme_stylebox_override("panel", UI.panel(16))
	root.add_child(district_panel)
	district_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	district_panel.offset_left = -330
	district_panel.offset_right = -24
	district_panel.offset_top = 84
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	district_panel.add_child(column)
	column.add_child(_label("画一片有自己声音的街坊", 18))
	var size_picker := OptionButton.new()
	size_picker.name = "DistrictWidth"
	for text_value: String in ["小庭 · 3.2米", "街坊 · 5.6米", "宽园 · 8.8米"]: size_picker.add_item(text_value)
	size_picker.select(1)
	size_picker.item_selected.connect(func(index: int) -> void:
		_cancel_draft()
		district_width = [3.2, 5.6, 8.8][index])
	column.add_child(size_picker)
	district_name = LineEdit.new()
	district_name.name = "DistrictName"
	district_name.placeholder_text = "先画一片街坊，再为它命名"
	district_name.text_submitted.connect(func(value: String) -> void:
		_after_edit(state.set_district_name(selected_district, value), "terrace")
		district_name.release_focus())
	column.add_child(district_name)
	district_style_picker = OptionButton.new()
	district_style_picker.name = "DistrictStyle"
	for key: String in DISTRICT_STYLES: district_style_picker.add_item(DISTRICT_STYLE_NAMES[key])
	district_style_picker.item_selected.connect(func(index: int) -> void:
		_cancel_draft()
		district_style = DISTRICT_STYLES[index]
		if not selected_district.is_empty():
			_after_edit(state.set_district_style(selected_district, district_style), "terrace"))
	column.add_child(district_style_picker)
	district_description = _label("", 14)
	district_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	district_description.custom_minimum_size.x = 270
	column.add_child(district_description)
	district_music_status = _label("", 14)
	district_music_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(district_music_status)
	column.add_child(_label("自由刷出街坊，松开落定。\n点击已有街坊选择；拖动仍可画新区。\nShift 点击移除整区；Esc 取消。", 13))
	district_panel.visible = false

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
	hint.text = ["点墙向外扩房，点顶向上加层。\n空地点击，建一座新房。", "点墙伸出露台，点顶留出屋顶花园。\n系统补齐栏杆和支撑。", "按住左键，沿空地拉出小路。\n横跨两岸自动搭桥；Esc 取消。", "点击房屋块移除。\n附属上层一并收回，撤销可恢复。", "点击房屋，起名并选择用途。\n居民沿小路采购、聚会，再回家。", "按住左键画树群；Shift+左键擦除。\n树会避开房屋、道路和水岸。\nEsc 取消预览。", "拖出池塘或从已有水边引水。\n红色预影说明与房屋、道路冲突。\nShift 点击移除；Esc 取消。", "自由刷出街坊，给房屋共同的音乐风格。\n点击选区；Shift 点击移除；Esc 取消。\n平移视野，听街坊乐句自然交接。"][tool]
	music.update_city(state)
	_refresh_place()
	_refresh_district()

func _check(key: String) -> String:
	return "●" if completed.has(key) else "○"

func select_tool(index: int) -> void:
	tool = index
	_cancel_draft()
	place_panel.visible = tool == 4 and not selected_house.is_empty()
	vegetation_panel.visible = tool == 5
	water_panel.visible = tool == 6
	road_panel.visible = tool == 2
	district_panel.visible = tool == 7
	town.show_districts(tool == 7)
	_refresh_ui()

func _update_camera() -> void:
	if town != null and town.meadow != null: town.meadow.set_view_scale(zoom)
	if town != null and town.shore != null: town.shore.set_view_scale(zoom)
	camera.size = zoom
	var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	camera.position = focus + direction * 42.0
	camera.look_at(focus)
	if music != null: music.set_listener_focus(Vector2(focus.x, focus.z))

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
		pointer = event.position
		if event.button_index == MOUSE_BUTTON_RIGHT: orbiting = false
		if event.button_index == MOUSE_BUTTON_MIDDLE: panning = false
		if event.button_index == MOUSE_BUTTON_LEFT and road_drawing: _finish_road()
		if event.button_index == MOUSE_BUTTON_LEFT and vegetation_drawing: _finish_vegetation()
		if event.button_index == MOUSE_BUTTON_LEFT and water_drawing: _finish_water()
		if event.button_index == MOUSE_BUTTON_LEFT and district_drawing: _finish_district()
	if event is InputEventKey and event.pressed and not event.echo:
		if get_viewport().gui_get_focus_owner() is LineEdit: return
		if event.ctrl_pressed:
			if event.keycode == KEY_Z: _history(event.shift_pressed)
			elif event.keycode == KEY_Y: _history(true)
			elif event.keycode == KEY_S: save_city()
			else: return
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8: select_tool(event.keycode - KEY_1)
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
				elif tool == 6:
					if event.shift_pressed:
						_after_edit(state.remove_water_at(_ground_at(pointer)), "erase")
					else:
						water_drawing = true
						water_points.clear()
						_append_water_point()
				elif tool == 7:
					if event.shift_pressed:
						_after_edit(state.remove_district_at(_ground_at(pointer)), "erase")
					else:
						district_drawing = true
						district_points.clear()
						district_distance = 0.0
						var district: Dictionary = state.district_at(_ground_at(pointer))
						district_start_id = str(district.get("id", ""))
						_append_district_point()
				else:
					_update_hover()
					_commit_click()

func _process(delta: float) -> void:
	town.update_house_music(music.active_source() if music.concert_active else music.daily_source())
	frame_samples.append(delta*1000.0)
	if frame_samples.size() > 240: frame_samples.pop_front()
	life_ui_timer -= delta
	if life_ui_timer < 0.0:
		life_ui_timer = 0.5
		life_info.text = life.summary()
		_refresh_concert()
		_refresh_district()
		_refresh_bakeries()
	life_save_timer -= delta
	if life_save_timer < 0.0:
		life_save_timer = 15.0
		if persistence and not save_blocked:
			_capture_journeys()
			var saved: Dictionary = state.save_city(SAVE_PATH) if state.dirty else {"ok":true}
			if not saved.ok: _message(saved.message)
	if toast_time > 0.0:
		toast_time -= delta
		toast.visible = toast_time > 0.0
	if save_delay >= 0.0:
		save_delay -= delta
		if save_delay < 0.0 and state.dirty and persistence and not save_blocked:
			_capture_journeys()
			var saved: Dictionary = state.save_city(SAVE_PATH)
			if not saved.ok: _message(saved.message)
	if not orbiting and not panning:
		if road_drawing: _append_road_point()
		elif vegetation_drawing: _append_vegetation_point()
		elif water_drawing: _append_water_point()
		elif district_drawing: _append_district_point()
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
	if tool == 7:
		var ground := _ground_at(pointer)
		var district: Dictionary = state.district_at(ground)
		var district_key := str([ground, district_width, district_style, district.get("id", "")])
		if preview_key == district_key: return
		preview_key = district_key
		var single: Array[Vector2] = [ground]
		town.show_district_preview(single, district_width, district_style)
		return
	if tool == 6:
		var ground := _ground_at(pointer)
		var water_key := str([ground,water_width,water_kind])
		if preview_key == water_key: return
		preview_key = water_key
		var single: Array[Vector2] = [ground]
		_show_water_preview(single)
		return
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
		if road_straight and road_points.size() == 2: road_points[1] = p
		else: road_points.append(p)
		road_preview = Stroke.road_points(road_points,road_straight)
		var check: Dictionary = state.preview_road(road_preview)
		road_status.text = "松开铺好这条路。" if check.ok else str(check.message)
		town.preview_road(road_preview,bool(check.ok))

func _finish_road() -> void:
	_append_road_point()
	road_drawing = false
	if road_points.size() < 2:
		_cancel_draft()
		return
	var result: Dictionary = state.add_road(road_preview)
	if result.ok: completed["road"] = true
	_after_edit(result, "road")
	road_points.clear()
	road_preview.clear()

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

func _append_water_point() -> void:
	var p := _ground_at(pointer)
	if water_points.is_empty() or water_points[-1].distance_to(p) > 0.30:
		water_points.append(p)
		_show_water_preview(water_points)

func _show_water_preview(points: Array[Vector2]) -> void:
	var check: Dictionary = state.preview_water(points, water_width, water_kind)
	water_status.text = str(check.message) if not str(check.message).is_empty() else "松开留下水岸；Esc 取消。"
	if water_kind == "channel" and not water_drawing:
		water_status.text = "从已有河水或池塘起笔，拖向空地。"
	var names: Array[String] = []
	for conflict: Dictionary in check.get("conflicts",[]):
		names.append(str(conflict.get("name",conflict.id)))
	if not names.is_empty(): water_status.text += "\n" + "、".join(names)
	town.preview_water(points, water_width, bool(check.ok), check.get("conflicts",[]))

func _finish_water() -> void:
	water_drawing = false
	if water_points.is_empty():
		_cancel_draft()
		return
	_after_edit(state.add_water(water_points, water_width, water_kind), "terrace")
	water_points.clear()

func _append_district_point() -> void:
	var at := _ground_at(pointer)
	if district_points.is_empty() or district_points[-1].distance_to(at) > 0.20:
		if not district_points.is_empty(): district_distance += district_points[-1].distance_to(at)
		district_points.append(at)
		town.show_district_preview(district_points, district_width, district_style)

func _finish_district() -> void:
	_append_district_point()
	district_drawing = false
	if not district_start_id.is_empty() and district_distance < 0.6:
		selected_district = district_start_id
		_cancel_draft()
		_refresh_district()
		var selected := _selected_district_row()
		if not selected.is_empty(): _show_selected_district(selected)
		return
	var result: Dictionary = state.add_district(district_points, district_width, district_style)
	if result.ok:
		var created: Dictionary = state.district_at(district_points[-1])
		selected_district = str(created.get("id", ""))
	_after_edit(result, "terrace")
	district_points.clear()
	district_start_id = ""
	district_distance = 0.0

func _selected_district_row() -> Dictionary:
	for district: Dictionary in state.districts:
		if str(district.id) == selected_district: return district
	return {}

func _show_selected_district(district: Dictionary) -> void:
	var points: Array[Vector2] = []
	for at: Array in district.points: points.append(Vector2(float(at[0]), float(at[1])))
	town.show_district_preview(points, float(district.width), str(district.style))

func _refresh_district() -> void:
	if district_panel == null or tool != 7: return
	var district := _selected_district_row()
	if district.is_empty(): selected_district = ""
	district_name.editable = not district.is_empty()
	if district.is_empty():
		if not district_name.has_focus(): district_name.text = ""
		district_description.text = "沿房屋与庭院画一笔，把它们留在同一片街坊。\n三种声音共用晨曲节拍，留白与和声自然相融。"
	else:
		if not district_name.has_focus(): district_name.text = str(district.name)
		district_style = str(district.style)
		district_style_picker.select(DISTRICT_STYLES.find(district_style))
		var members: Array = state.district_members(selected_district)
		var counts := {"residential":0, "bakery":0, "venue":0}
		var reachable := {"bakery":0, "venue":0}
		for house: Dictionary in state.houses:
			if str(house.id) not in members: continue
			var role := str(house.role)
			counts[role] = int(counts[role]) + 1
			if role == "residential":
				for service: String in ["bakery", "venue"]:
					if _district_home_has_service(str(house.id), service): reachable[service] = int(reachable[service]) + 1
		district_description.text = "%d 座房屋 · %d 居所 · %d 面包坊 · %d 演奏庭\n区内居所可沿路抵达：\n面包坊 %d / %d · 演奏庭 %d / %d\n服务包含街坊外的实际可达地点。" % [members.size(), int(counts.residential), int(counts.bakery), int(counts.venue), int(reachable.bakery), int(counts.residential), int(reachable.venue), int(counts.residential)]
		if int(counts.residential) == 0: district_description.text += "\n先为这片庭园留下自己的声音。"
	var report: Dictionary = music.district_music_report()
	var audible_name: String = DISTRICT_STYLE_NAMES[str(report.style)]
	district_music_status.text = "♫ 正在听见 · " + audible_name if bool(report.audible) else "♫ 晨曲静候 · " + audible_name
	if bool(report.audible):
		for source: Dictionary in state.houses:
			if str(source.id) == str(report.source_id):
				district_music_status.text += "\n" + str(source.name) + " 正在演奏"
				break
	if bool(report.pending): district_music_status.text += "\n" + str(DISTRICT_STYLE_NAMES[str(report.pending_style)]) + " · 等待下一乐句"

func _district_home_has_service(home_id: String, role: String) -> bool:
	if not life.house_connected(home_id): return false
	var start: String = str(life.connected_houses[home_id])
	for house: Dictionary in state.houses:
		if str(house.role) != role or not life.house_connected(str(house.id)): continue
		if not life._route(start, str(life.connected_houses[house.id])).is_empty(): return true
	return false

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
	road_preview.clear()
	vegetation_drawing = false
	vegetation_points.clear()
	water_drawing = false
	water_points.clear()
	district_drawing = false
	district_points.clear()
	district_start_id = ""
	district_distance = 0.0
	candidate.clear()
	preview_key = ""
	if town != null: town.clear_preview()

func save_city() -> void:
	if save_blocked:
		_message("原作品读取失败，已保留原文件；当前试玩可继续编辑。")
		return
	_capture_journeys()
	var result: Dictionary = state.save_city(SAVE_PATH)
	_message("河湾已保存，下次从这里继续。" if result.ok else str(result.message))

func _toggle_music() -> void:
	music.set_muted(not music.muted)
	music_button.text = "♫ 静音" if music.muted else "♫ 音乐"

func _toggle_light() -> void:
	evening = not evening
	sun.light_color = Color("ffcf9f") if evening else Color("fff1d7")
	sun.light_energy = 0.50 if evening else 0.58
	sun.rotation_degrees.x = -24.0 if evening else -48.0

func _refresh_place() -> void:
	if selected_house.is_empty() or place_name == null: return
	for house: Dictionary in state.houses:
		if str(house.id) != selected_house: continue
		if not place_name.has_focus(): place_name.text = str(house.get("name", "无名小屋"))
		var role := str(house.get("role", "residential"))
		place_description.text = {"residential":"一处居所，让街坊有居民。", "bakery":"面包出炉，居民循路来采购。", "venue":"一处演奏庭，招呼街坊来小聚。"}[role]
		place_description.text += "\n门前小路已接通。" if life.house_connected(selected_house) else "\n拉一条小路到门前，让居民能走来。"
		concert_button.visible = role == "venue"
		_refresh_bakeries()
		_refresh_concert()
		return

func _refresh_bakeries() -> void:
	var statuses := {}
	for house: Dictionary in state.houses:
		if str(house.role)=="bakery": statuses[str(house.id)]=life.bakery_status(str(house.id))
	town.update_bakery_supply(statuses)
	if bakery_info == null: return
	var selected: Dictionary = statuses.get(selected_house,{})
	bakery_info.visible = not selected.is_empty()
	bakery_progress.visible = not selected.is_empty()
	bakery_button.visible = not selected.is_empty()
	if selected.is_empty(): return
	bakery_info.text = "柜台面包 %d / %d · 每炉 %d份\n累计出炉 %d份 · 街坊买走 %d份" % [int(selected.stock),int(selected.capacity),int(selected.batch_size),int(selected.produced),int(selected.served)]
	var phase := str(selected.worker_phase)
	var activity: String = {"walking":"正在沿路来开炉","baking":"正在揉面、烘焙","returning":"正在沿路回家","resting":"正在家里小歇","paused":"等小路重新接通","unassigned":"接通一处居所，让街坊来当面包师"}.get(phase,"等街坊来开炉")
	if not bool(selected.open): activity = "炉火小歇，柜台面包仍能买走"
	elif int(selected.stock)+int(selected.batch_size)>int(selected.capacity): activity = "面包已备好，等街坊来买"
	bakery_info.text += "\n" + (str(selected.worker_name)+" · " if not str(selected.worker_name).is_empty() else "") + activity
	bakery_info.text += "\n扩出房间能增加每炉份数与柜台容量。"
	bakery_progress.max_value = float(selected.duration)
	bakery_progress.value = float(selected.elapsed)
	bakery_button.text = "暂停烘焙" if bool(selected.open) else "继续开炉"

func _capture_journeys() -> void:
	state.set_journey_checkpoint(life.checkpoint())

func _invite_concert() -> void:
	var active: Dictionary = life.concert_status()
	var result: Dictionary = life.cancel_concert() if str(active.phase) != "idle" and str(active.venue_id) == selected_house else life.invite_concert(selected_house)
	_message(str(result.message))
	if result.ok:
		_capture_journeys()
		save_delay = 3.0
	_refresh_concert()

func _on_concert_event(event: String, venue_id: String) -> void:
	music.set_concert_active(event == "started")
	var name_value := "演奏庭"
	for house: Dictionary in state.houses:
		if house.id == venue_id: name_value = str(house.name)
	_message({"started":"街坊到齐了，%s 的演出开始。","finished":"%s 的演出落幕，街坊继续自己的日常。","cancelled":"%s 的演出已结束，街坊继续自己的日常。"}[event] % name_value)
	_capture_journeys()
	save_delay = 3.0
	_refresh_concert()

func _refresh_concert() -> void:
	if concert_info == null: return
	var status: Dictionary = life.concert_status()
	var homes: Array[String] = []
	for resident: Dictionary in life.residents:
		if resident.has("daily_snapshot"): homes.append(str(resident.home_id))
	music.set_concert_sources(str(status.venue_id),homes)
	music.set_concert_active(str(status.phase) == "playing")
	concert_button.text = "结束这场演出" if str(status.phase) != "idle" and str(status.venue_id) == selected_house else "♫ 邀请街坊演出"
	concert_button.disabled = (str(status.phase) != "idle" and str(status.venue_id) != selected_house) or not life.house_connected(selected_house)
	concert_info.visible = concert_button.visible or str(status.phase) != "idle"
	concert_progress.visible = str(status.phase) != "idle"
	concert_progress.max_value = float(status.duration) if str(status.phase) == "playing" else maxi(1,int(status.invited))
	concert_progress.value = float(status.elapsed) if str(status.phase) == "playing" else int(status.arrived)
	concert_info.text = "邀请街坊沿路来听一场演出。\n演出结束后，街坊回到自己的日常。"
	if str(status.phase) == "gathering": concert_info.text = "街坊正在沿路赶来 · %d / %d 已抵达" % [int(status.arrived),int(status.invited)]
	elif str(status.phase) == "playing": concert_info.text = "♫ 街坊合奏 · %d 位听众\n还有 %d 秒落幕" % [int(status.invited),ceili(float(status.duration)-float(status.elapsed))]
	if str(status.phase) == "playing":
		var source: Dictionary = music.active_source()
		if bool(source.get("audible",false)):
			for house: Dictionary in state.houses:
				if house.id == source.source_id: concert_info.text += "\n"+str(house.name)+(" 正在主奏" if str(source.role) == "lead" else " 正在应答")
	town.show_concert(status)

func _message(text_value: String) -> void:
	if toast == null: return
	toast.text = text_value
	toast.visible = true
	toast_time = 4.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if persistence and not save_blocked:
			_capture_journeys()
			if state.dirty: state.save_city(SAVE_PATH)

func diagnostics() -> Dictionary:
	var sorted := frame_samples.duplicate()
	sorted.sort()
	return {"engine":Engine.get_version_info().string,"fps":Engine.get_frames_per_second(),
		"frame_p95_ms":sorted[int((sorted.size()-1)*0.95)] if not sorted.is_empty() else 0.0,
		"edit_rebuild_ms":edit_samples.duplicate(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"render_updates":town.rebuild_stats.duplicate(),"plants":state.plants.size(),"water_updates":town.water_edit_stats.duplicate(),
		"meadow":town.meadow.diagnostics(),
		"shore":town.shore.diagnostics(),"water_field":town.water_field.diagnostics(),
		"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"audio":music.audio_report,"life":{"residents":life.residents.size(),"purchases":life.purchases,"gatherings":life.gatherings},
		"concert":life.concert_status(),"concert_music":music.music_report(),
		"milestones":completed.duplicate(),"world":state.snapshot()}
