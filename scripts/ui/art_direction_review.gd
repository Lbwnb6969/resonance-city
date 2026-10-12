extends PanelContainer
## Shown only by the art review launcher. The ordinary opening keeps its HUD.
const Art = preload("res://scripts/visual/city_art_direction.gd")
var demo: Control
var buttons: Dictionary = {}
var light_button: Button
var light_index := 0
const PHASES := [0.0,0.30,0.54,-1.0]
const LIGHT_LABELS := ["白昼","黄昏","夜晚","自动昼夜"]

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	z_index = 120
	theme = demo.planning_guide.theme
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4f0e3",0.96)
	style.border_color = Color("b5b89d",0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel",style)
	var column := VBoxContainer.new()
	add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var label := Label.new()
	label.text = "同一河湾 · 美术候选"
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color("435c59"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	light_button = Button.new()
	light_button.text = LIGHT_LABELS[light_index]
	light_button.add_theme_font_size_override("font_size",12)
	light_button.pressed.connect(func() -> void:
		light_index = (light_index+1)%PHASES.size()
		demo.daylight_manual_phase = PHASES[light_index]
		light_button.text = LIGHT_LABELS[light_index])
	heading.add_child(light_button)
	var row := HBoxContainer.new()
	column.add_child(row)
	for id: String in Art.STYLE_IDS:
		var button := Button.new()
		button.text = Art.LABELS[id]
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size",12)
		button.custom_minimum_size.x = 90
		button.pressed.connect(func() -> void: demo.set_art_direction(id))
		row.add_child(button)
		buttons[id] = button
	var hint := Label.new()
	hint.text = "切换建筑、树木与环境色；城市继续演奏"
	hint.add_theme_font_size_override("font_size",11)
	hint.add_theme_color_override("font_color",Color("66766d"))
	column.add_child(hint)
	sync()

func sync() -> void:
	visible = not demo.black and not demo.planning_guide.opened and not demo.menu.visible
	size = get_combined_minimum_size()
	position = Vector2(demo.size.x*0.5-size.x*0.5,20)
	for id: String in buttons: buttons[id].set_pressed_no_signal(id == demo.art_direction.selected_id)
