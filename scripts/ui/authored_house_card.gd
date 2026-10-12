extends VBoxContainer
## The owner supplies heard facts and handles every action; this card is display only.
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
const BASES := [48,50,52,55,57]
signal note_requested(base: int)
signal next_requested
signal land_requested
signal naming_requested
signal tools_requested
signal closed

var note_buttons: Dictionary = {}
var next_button: Button
var land_button: Button
var naming_button: Button
var tools_button: Button
var close_button: Button
var title_label: Label
var place_label: Label
var heard_label: Label
var pending_label: Label
var growth_label: Label
var cost_label: Label
var thumbnail: TextureRect
var state: Dictionary = {}

func setup() -> void:
	name = "AuthoredHouseCard"
	theme = Ui.make_theme()
	custom_minimum_size.x = 324
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",12)
	add_child(header)
	thumbnail = TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(72,76)
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(thumbnail)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation",3)
	header.add_child(identity)
	title_label = _label("",18)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(title_label)
	place_label = _label("")
	place_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	place_label.clip_text = true
	place_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	place_label.add_theme_color_override("font_color",Ui.MUTED)
	identity.add_child(place_label)
	heard_label = _label("",16)
	identity.add_child(heard_label)
	pending_label = _label("")
	pending_label.add_theme_color_override("font_color",Color("876b42"))
	add_child(pending_label)
	growth_label = _label("")
	growth_label.add_theme_color_override("font_color",Ui.MUTED)
	add_child(growth_label)
	var notes := HBoxContainer.new()
	notes.add_theme_constant_override("separation",5)
	add_child(notes)
	for base: int in BASES:
		var button := _button("")
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size",16)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(_request_note.bind(base))
		notes.add_child(button)
		note_buttons[base] = button
	cost_label = _label("")
	cost_label.add_theme_color_override("font_color",Ui.MUTED)
	add_child(cost_label)
	next_button = _button("")
	next_button.custom_minimum_size.y = 42
	Ui.primary(next_button)
	next_button.pressed.connect(func() -> void: next_requested.emit())
	add_child(next_button)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation",6)
	add_child(secondary)
	land_button = _button("照看留下的空地")
	land_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	land_button.pressed.connect(func() -> void: land_requested.emit())
	secondary.add_child(land_button)
	naming_button = _button("给街道起名")
	naming_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	naming_button.pressed.connect(func() -> void: naming_requested.emit())
	secondary.add_child(naming_button)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",6)
	add_child(footer)
	tools_button = _button("更多工具")
	tools_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools_button.pressed.connect(func() -> void: tools_requested.emit())
	footer.add_child(tools_button)
	close_button = _button("回到城市 · Esc")
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(func() -> void: closed.emit())
	footer.add_child(close_button)

func _label(value: String,font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 38
	button.focus_mode = Control.FOCUS_ALL
	return button

func set_state(data: Dictionary) -> void:
	state = data.duplicate(true)
	title_label.text = str(data["title"])
	title_label.tooltip_text = title_label.text
	place_label.text = str(data["place"])
	place_label.tooltip_text = place_label.text
	place_label.visible = not place_label.text.is_empty()
	heard_label.text = str(data["heard"])
	pending_label.text = str(data["pending"])
	pending_label.visible = not pending_label.text.is_empty()
	growth_label.text = str(data["growth"])
	growth_label.visible = not growth_label.text.is_empty()
	cost_label.text = str(data["cost"])
	cost_label.visible = not cost_label.text.is_empty()
	thumbnail.texture = data["texture"]
	land_button.visible = bool(data["has_land"])
	next_button.text = str(data["next_label"])
	for choice: Dictionary in data["choices"]:
		var base := int(choice["base"])
		var button: Button = note_buttons[base]
		button.text = str(choice["text"])
		button.tooltip_text = "改成 %s · 下一可写拍生效" % str(choice["text"])
		button.set_meta("heard_current",bool(choice["current"]))
		button.set_meta("pitch",int(choice["pitch"]))
		button.set_pressed_no_signal(bool(choice["current"]))

func _request_note(base: int) -> void:
	# A click requests a future change. Keep the highlight on the heard pitch
	# until the owner supplies a new audible state, including after Enter.
	for button: Button in note_buttons.values():
		button.set_pressed_no_signal(bool(button.get_meta("heard_current",false)))
	note_requested.emit(base)
