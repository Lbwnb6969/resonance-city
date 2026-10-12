extends Button
## Compact illustrated intentions, never a fabricated preview of a future city.
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
const ROW_HEIGHT := 116.0
const TITLE_SIZE := 18
const BODY_SIZE := 14
var choice_id := ""
var direction := "compact"
var accent := Color("628b94")
var definition: Dictionary = {}
var is_variation := false
var title_label: Label
var tendency_label: Label
var tradeoff_label: Label
var duration_label: Label
var illustration_style: StyleBoxFlat

func setup(id: String,spec: Dictionary,variation: bool = false) -> void:
	choice_id = id
	definition = spec.duplicate(true)
	is_variation = variation
	direction = {"infill_pulse":"compact","road_echo":"corridor","anchor_bloom":"bluegreen"}.get(id,id)
	accent = {"compact":Color("628b94"),"corridor":Color("bd7958"),"bluegreen":Color("76966b")}[direction]
	text = str(definition["title"])
	tooltip_text = str(definition["tendency"])+"；取舍 · "+str(definition["tradeoff"])
	if variation: tooltip_text += "；持续 %d 句" % int(definition["duration_phrases"])
	custom_minimum_size = Vector2(280,ROW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var surface := StyleBoxFlat.new()
		surface.set_corner_radius_all(8)
		surface.content_margin_left = 12
		surface.content_margin_right = 12
		surface.content_margin_top = 10
		surface.content_margin_bottom = 10
		surface.bg_color = Color("ebe5d4",0.34)
		if state == "hover": surface.bg_color = Color("e5deca")
		elif state in ["pressed","hover_pressed"]:
			surface.bg_color = Ui.GREEN.lightened(0.035) if state == "hover_pressed" else Ui.GREEN
		elif state == "disabled": surface.bg_color = Color("dfdfd0",0.24)
		elif state == "focus":
			surface.bg_color = Color.TRANSPARENT
			surface.border_color = Ui.GOLD
			surface.set_border_width_all(1)
		add_theme_stylebox_override(state,surface)
	# Native Button keeps its accessible title and full-row input. Labels draw
	# the actual specification once without intercepting mouse or focus.
	for color: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_focus_color"]:
		add_theme_color_override(color,Color.TRANSPARENT)
	illustration_style = StyleBoxFlat.new()
	illustration_style.bg_color = accent.lerp(Ui.PAPER,0.86)
	illustration_style.set_corner_radius_all(6)
	title_label = _label(str(definition["title"]),TITLE_SIZE,false)
	tendency_label = _label(str(definition["tendency"]),BODY_SIZE,true)
	tradeoff_label = _label("取舍 · "+str(definition["tradeoff"]),BODY_SIZE,true)
	duration_label = _label("%d句" % int(definition.get("duration_phrases",0)),BODY_SIZE,false)
	duration_label.visible = variation
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resized.connect(_layout)
	toggled.connect(func(_pressed: bool) -> void: _colours())
	button_down.connect(_colours)
	button_up.connect(_colours)
	_layout()
	_colours()

func _label(value: String,font_size: int,wrap: bool) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_constant_override("line_spacing",0)
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label

func _layout() -> void:
	if title_label == null: return
	title_label.position = Vector2(86,10)
	title_label.size = Vector2(maxf(1,size.x-98-(44 if is_variation else 0)),27)
	tendency_label.position = Vector2(86,39)
	tendency_label.size = Vector2(maxf(1,size.x-98),36)
	tradeoff_label.position = Vector2(12,78)
	tradeoff_label.size = Vector2(maxf(1,size.x-24),36)
	duration_label.position = Vector2(size.x-54,14)
	duration_label.size = Vector2(42,22)
	queue_redraw()

func _colours() -> void:
	var selected := button_pressed or is_pressed()
	var ink := Ui.PAPER if selected else Ui.INK
	var muted := Color("ddd7c5") if selected else Color("607166")
	if disabled:
		ink = Color("889287")
		muted = Color("889287")
	title_label.add_theme_color_override("font_color",ink)
	tendency_label.add_theme_color_override("font_color",ink)
	tradeoff_label.add_theme_color_override("font_color",muted)
	duration_label.add_theme_color_override("font_color",Color("e0c48d") if selected else accent.darkened(0.15))
	queue_redraw()

func _house(at: Vector2,roof: Color) -> void:
	var a := at+Vector2(-7,0)
	var b := at+Vector2(0,4)
	var c := at+Vector2(7,0)
	var d := at+Vector2(0,-4)
	draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(0,8),a+Vector2(0,8)]),Color("bdad91"))
	draw_colored_polygon(PackedVector2Array([b,c,c+Vector2(0,8),b+Vector2(0,8)]),Color("e8d8b8"))
	draw_colored_polygon(PackedVector2Array([a+Vector2(-1,0),b+Vector2(0,1),c+Vector2(1,0),d+Vector2(0,-2)]),roof)
	draw_line(a,b,roof.darkened(0.23),0.7,true)
	draw_line(b,c,roof.darkened(0.23),0.7,true)
	draw_line(at+Vector2(-4,4),at+Vector2(-4,7),Ui.GREEN,1.3,true)
	draw_line(at+Vector2(4,4),at+Vector2(4,6),Ui.GREEN,1.3,true)

func _tree(at: Vector2) -> void:
	draw_line(at+Vector2(0,3),at+Vector2(0,9),Color("88785b"),1.3,true)
	draw_circle(at+Vector2(0,1),4.5,Color("4d7960"))
	draw_circle(at+Vector2(-1,-1),3.0,Color("6d9270"))

func _civic(at: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([at+Vector2(-7,4),at+Vector2(0,8),at+Vector2(8,3),at+Vector2(1,-1)]),Color("d7c6a4"))
	for x: float in [-5,-1,3]:
		draw_line(at+Vector2(x,-2),at+Vector2(x,4),Color("f0dfbc"),1.7,true)
	draw_colored_polygon(PackedVector2Array([at+Vector2(-8,-2),at+Vector2(0,-7),at+Vector2(8,-2),at+Vector2(0,2)]),Color("b97859"))
	draw_line(at+Vector2(-8,-2),at+Vector2(0,2),Color("e8d8b8"),1.2,true)

func _draw() -> void:
	if illustration_style == null: return
	draw_style_box(illustration_style,Rect2(12,11,64,60))
	var center := Vector2(44,36)
	var street := PackedVector2Array([center+Vector2(-28,15),center+Vector2(24,-11),center+Vector2(29,-7),center+Vector2(-23,19)])
	draw_colored_polygon(street,Color("c7b58f"))
	draw_polyline(PackedVector2Array([center+Vector2(-25,16),center+Vector2(26,-8)]),Color("f4e8c8"),0.8,true)
	if direction == "compact":
		for at: Vector2 in [Vector2(-15,-5),Vector2(1,-14),Vector2(16,-5),Vector2(0,9)]: _house(center+at,accent)
	elif direction == "corridor":
		for at: Vector2 in [Vector2(-19,1),Vector2(-3,-7),Vector2(13,-15)]: _house(center+at,accent)
		draw_line(center+Vector2(-14,23),center+Vector2(24,3),accent,1.2,true)
		draw_circle(center+Vector2(19,6),2.4,Ui.PAPER)
		draw_arc(center+Vector2(19,6),2.4,0,TAU,12,accent,1.1,true)
	else:
		draw_colored_polygon(PackedVector2Array([center+Vector2(-18,4),center+Vector2(4,-10),center+Vector2(20,-2),center+Vector2(-2,12)]),Color("bccba4"))
		_house(center+Vector2(-18,-9),Color("728a72"))
		_civic(center+Vector2(14,0))
		_tree(center+Vector2(-2,0))
		_tree(center+Vector2(5,-6))
