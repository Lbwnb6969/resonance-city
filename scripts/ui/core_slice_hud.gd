extends Node2D
## Map buildings never occlude this compact first-play legend.
var demo: Control
var panel_style: StyleBoxFlat

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("f4f0df",0.96)
	panel_style.border_color = Color("b5b89d",0.72)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)

func sync() -> void:
	visible = demo.first_composition_mode and not demo.black
	if visible: queue_redraw()

func _draw() -> void:
	var ink := Color("435c59")
	var panel := Rect2(demo.size.x-386.0,24.0,350.0,86.0)
	draw_style_box(panel_style,panel)
	draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,21),"这座城市会演奏",HORIZONTAL_ALIGNMENT_LEFT,-1,16,ink)
	draw_string(ThemeDB.fallback_font,panel.position+Vector2(14,41),"选方向 · 放锚点 · 听它沿街生长",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(ink,0.76))
	var chips := [["深流","低音 · 慢拍",Color("6f8d92")],["织机","高音 · 短拍",Color("bd8760")],["留地","中音 · 留白",Color("809475")]]
	var x := panel.position.x+14.0
	for chip: Array in chips:
		draw_circle(Vector2(x+5,panel.position.y+65),4.0,chip[2])
		draw_string(ThemeDB.fallback_font,Vector2(x+13,panel.position.y+63),str(chip[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,11,chip[2])
		draw_string(ThemeDB.fallback_font,Vector2(x+13,panel.position.y+77),str(chip[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color(ink,0.66))
		x += 98.0
