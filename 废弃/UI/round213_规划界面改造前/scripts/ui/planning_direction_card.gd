extends Button
## A small illustrated plan, never a fabricated preview of a future city.
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
var direction := "compact"
var accent := Color("628b94")
var words: VBoxContainer
var illustration_style: StyleBoxFlat

func setup(id: String,spec: Dictionary,variation: bool = false) -> void:
	direction = {"infill_pulse":"compact","road_echo":"corridor","anchor_bloom":"bluegreen"}.get(id,id)
	accent = {"compact":Color("628b94"),"corridor":Color("bd7958"),"bluegreen":Color("76966b")}[direction]
	illustration_style = StyleBoxFlat.new()
	illustration_style.bg_color = accent.lerp(Color("eee8d4"),0.90)
	illustration_style.set_corner_radius_all(6)
	custom_minimum_size = Vector2(232,244)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_text = str(spec["tradeoff"])
	for state: String in ["normal","hover","pressed","focus"]:
		var style := Ui.panel(14)
		style.bg_color = Color("fffbef") if state == "normal" else accent.lerp(Ui.PAPER,0.90 if state == "hover" else 0.8)
		style.border_color = accent if state != "normal" else Color("dfd7c5")
		style.shadow_size = 3 if state == "normal" else 5
		style.set_border_width_all(2 if state == "focus" else 1)
		add_theme_stylebox_override(state,style)
	words = VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_theme_constant_override("separation",8)
	add_child(words)
	var title := Label.new()
	title.text = str(spec["title"])
	title.add_theme_font_size_override("font_size",19)
	title.add_theme_color_override("font_color",Ui.INK)
	words.add_child(title)
	var tendency := Label.new()
	tendency.text = str(spec["tendency"])
	tendency.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tendency.add_theme_font_size_override("font_size",13)
	tendency.add_theme_color_override("font_color",Ui.INK)
	words.add_child(tendency)
	var tradeoff := Label.new()
	tradeoff.text = "取舍 · "+str(spec["tradeoff"])
	tradeoff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tradeoff.add_theme_font_size_override("font_size",12)
	tradeoff.add_theme_color_override("font_color",Ui.MUTED)
	words.add_child(tradeoff)
	if variation:
		var duration := Label.new()
		duration.text = "持续 %d 句" % int(spec["duration_phrases"])
		duration.add_theme_font_size_override("font_size",11)
		duration.add_theme_color_override("font_color",accent)
		words.add_child(duration)
		custom_minimum_size.y = 270
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if words == null: return
	words.position = Vector2(16,109)
	words.size.x = maxf(1,size.x-32)
	queue_redraw()

func _house(at: Vector2,roof: Color) -> void:
	var a := at+Vector2(-12,0)
	var b := at+Vector2(1,7)
	var c := at+Vector2(13,0)
	var d := at+Vector2(0,-7)
	draw_colored_polygon(PackedVector2Array([a,b,b+Vector2(0,16),a+Vector2(0,16)]),Color("d5c4a2"))
	draw_colored_polygon(PackedVector2Array([b,c,c+Vector2(0,16),b+Vector2(0,16)]),Color("ebe0c4"))
	draw_colored_polygon(PackedVector2Array([a+Vector2(-2,0),b+Vector2(0,1),c+Vector2(2,0),d+Vector2(0,-2)]),roof)
	draw_line(a,b,roof.darkened(0.3),1,true)
	draw_line(b,c,roof.darkened(0.3),1,true)
	draw_line(at+Vector2(-7,9),at+Vector2(-3,11),Ui.GREEN,2,true)
	draw_line(at+Vector2(5,10),at+Vector2(9,8),Ui.GREEN,2,true)

func _draw() -> void:
	var center := Vector2(size.x*0.5,53)
	draw_style_box(illustration_style,Rect2(12,12,size.x-24,86))
	var street := PackedVector2Array([center+Vector2(-74,24),center+Vector2(69,-17),center+Vector2(78,-12),center+Vector2(-65,29)])
	draw_colored_polygon(street,Color("c9bea4"))
	draw_polyline(PackedVector2Array([center+Vector2(-65,25),center+Vector2(72,-15)]),Color("f4e8c8"),1,true)
	if direction == "compact":
		for at in [Vector2(-32,-8),Vector2(-5,-22),Vector2(22,-9),Vector2(-3,10)]: _house(center+at,accent)
	elif direction == "corridor":
		for at in [Vector2(-45,5),Vector2(-11,-11),Vector2(24,-27)]: _house(center+at,accent)
		draw_arc(center+Vector2(48,3),5,0,TAU,16,accent,1.4,true)
		draw_line(center+Vector2(43,4),center+Vector2(3,25),accent,1.5,true)
	else:
		_house(center+Vector2(-38,-6),Color("8a9a89"))
		_house(center+Vector2(32,-20),Color("8a9a89"))
		draw_colored_polygon(PackedVector2Array([center+Vector2(-17,-7),center+Vector2(10,-24),center+Vector2(30,-13),center+Vector2(1,4)]),Color("becba4"))
		for at in [Vector2(-2,-7),Vector2(14,-17)]:
			draw_line(center+at,center+at+Vector2(0,10),Color("88785b"),2,true)
			draw_circle(center+at,8,Ui.GREEN.lightened(0.18))
			draw_circle(center+at+Vector2(-2,-2),5,Color("73916b"))
