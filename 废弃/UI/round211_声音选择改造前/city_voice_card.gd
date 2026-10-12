extends Button
## A real route building and a short sound description share one native Button.
const ROUTE_INK := {"deep":Color("628b94"),"weave":Color("bd7958"),"warm":Color("76966b")}
const CITY_COPY := {"deep":"住宅慢生长，留出规划时间","weave":"商业优先生长，织成活跃街坊","warm":"住宅沿街生长，留住邻近空地"}
const PAPER := Color("f5f0e4")
const PINE := Color("24483b")
const MUTED := Color("728075")
const COPPER := Color("a78a58")
var choice_id := ""
var choice: Dictionary = {}
var thumbnail_entry: Dictionary = {}
var thumbnail: Texture2D
var listening := false
var listen_seconds := 0.0

func setup(route: Dictionary,owner_demo: Control) -> void:
	choice = route.duplicate(true)
	choice_id = str(choice["id"])
	text = str(choice["label"])
	tooltip_text = "点击听四秒 · "+str(choice["city"])+"；确认才种下"
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(250,94)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	thumbnail_entry = owner_demo.building_catalog.preview_entry(choice_id)
	thumbnail = owner_demo.building_catalog.texture_for(thumbnail_entry)
	var accent: Color = ROUTE_INK[choice_id]
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var surface := StyleBoxFlat.new()
		surface.bg_color = PAPER
		surface.border_color = Color("d8cfbb")
		surface.set_border_width_all(1)
		surface.set_corner_radius_all(10)
		surface.content_margin_left = 12
		surface.content_margin_right = 12
		surface.content_margin_top = 8
		surface.content_margin_bottom = 8
		if state == "hover":
			surface.bg_color = Color("fffaef")
			surface.border_color = accent.lerp(COPPER,0.28)
		elif state in ["pressed","hover_pressed"]:
			surface.bg_color = accent.lerp(Color("fcf6e8"),0.89)
			surface.border_color = accent
			surface.set_border_width_all(2)
		elif state == "disabled":
			surface.bg_color = Color("e9e6dc")
			surface.border_color = Color("d8d4c7")
		elif state == "focus":
			surface.bg_color = Color.TRANSPARENT
			surface.border_color = COPPER
			surface.set_border_width_all(2)
		add_theme_stylebox_override(state,surface)
	# Keep the native accessible label and Button input while drawing its four
	# short lines at a fixed hierarchy, instead of a centred multiline label.
	for colour: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_focus_color"]:
		add_theme_color_override(colour,Color.TRANSPARENT)
	resized.connect(queue_redraw)
	toggled.connect(func(_pressed: bool) -> void: queue_redraw())
	set_process(false)
	queue_redraw()

func set_listening(value: bool) -> void:
	if listening == value: return
	listening = value
	listen_seconds = 0.0
	set_process(listening)
	queue_redraw()

func set_building_entry(entry: Dictionary,owner_demo: Control) -> void:
	if thumbnail_entry.get("id","") == entry["id"]: return
	thumbnail_entry = entry
	thumbnail = owner_demo.building_catalog.texture_for(entry)
	queue_redraw()

func status_text() -> String:
	if listening: return "正在试听 · 4秒后回到城市"
	return "已选 · 再听四秒" if button_pressed else "点击试听 · 4秒"

func _process(delta: float) -> void:
	listen_seconds += delta
	queue_redraw()

func _fit_line(font: Font,value: String,width: float,font_size: int) -> String:
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x <= width: return value
	var fitted := value
	while not fitted.is_empty() and font.get_string_size(fitted+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > width:
		fitted = fitted.left(fitted.length()-1)
	return fitted+"…"

func _draw() -> void:
	if choice.is_empty(): return
	var accent: Color = ROUTE_INK[choice_id]
	var alpha := 0.42 if disabled else 1.0
	var ink := Color(PINE,alpha)
	var quiet := Color(MUTED,alpha)
	var font := get_theme_font("font")
	var frame := Rect2(Vector2(10,9),Vector2(minf(84.0,maxf(62.0,size.x*0.22)),76))
	var well := StyleBoxFlat.new()
	well.bg_color = Color(accent.lerp(Color("fff8e9"),0.90),alpha)
	well.border_color = Color(accent,0.18*alpha)
	well.set_border_width_all(1)
	well.set_corner_radius_all(7)
	draw_style_box(well,frame)
	# The thumbnail is the same catalogue texture used by the city, with no
	# authored-house fixture or preview transaction needed to decorate the UI.
	var texture_size := thumbnail.get_size()
	var scale_factor := minf((frame.size.x-9.0)/texture_size.x,60.0/texture_size.y)
	var fitted_size := texture_size*scale_factor
	var at := frame.position+Vector2((frame.size.x-fitted_size.x)*0.5,7)
	draw_texture_rect(thumbnail,Rect2(at,fitted_size),false,Color(1,1,1,alpha))
	_draw_voice_motif(frame.position+Vector2((frame.size.x-28.0)*0.5,65),accent,alpha)
	var text_x := frame.end.x+13.0
	var width := maxf(1.0,size.x-text_x-15.0)
	draw_string(font,Vector2(text_x,27),str(choice["label"]),HORIZONTAL_ALIGNMENT_LEFT,-1,19,ink)
	var type_label := "商业" if str(choice["type"]) == "commercial" else "住宅"
	var tag_width := font.get_string_size(type_label,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+12.0
	var tag := Rect2(Vector2(size.x-tag_width-15.0,13),Vector2(tag_width,19))
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(accent,0.10*alpha)
	chip.set_corner_radius_all(4)
	draw_style_box(chip,tag)
	draw_string(font,tag.position+Vector2(6,13),type_label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(accent.darkened(0.16),alpha))
	draw_string(font,Vector2(text_x,45),_fit_line(font,str(choice["sound"]),width,12),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(accent.darkened(0.13),alpha))
	draw_string(font,Vector2(text_x,62),_fit_line(font,str(CITY_COPY[choice_id]),width,12),HORIZONTAL_ALIGNMENT_LEFT,-1,12,quiet)
	draw_line(Vector2(text_x,69),Vector2(size.x-15,69),Color(COPPER,0.18*alpha),1.0,true)
	if listening:
		_draw_playing(Vector2(text_x+2,80),accent,alpha)
	elif button_pressed:
		draw_polyline(PackedVector2Array([Vector2(text_x+1,79),Vector2(text_x+4,82),Vector2(text_x+9,75)]),Color(accent,alpha),1.8,true)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(text_x+2,75),Vector2(text_x+2,83),Vector2(text_x+8,79)]),Color(COPPER,alpha))
	draw_string(font,Vector2(text_x+17,83),_fit_line(font,status_text(),width-17.0,11),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(accent.darkened(0.20),alpha) if button_pressed or listening else quiet)
	if button_pressed:
		draw_line(Vector2(3,16),Vector2(3,size.y-16),Color(accent,alpha),3.0,true)

func _draw_voice_motif(at: Vector2,accent: Color,alpha: float) -> void:
	var heights: Array = {"deep":[3.0,7.0,4.0],"weave":[3.0,7.0,4.0,8.0,3.0,6.0,3.0],"warm":[3.0,5.0,7.0,5.0,3.0]}[choice_id]
	var stride := 5.0 if choice_id == "weave" else 7.0
	var left := at.x+(28.0-float(heights.size()-1)*stride)*0.5
	for index in range(heights.size()):
		var h := float(heights[index])
		draw_line(Vector2(left+float(index)*stride,at.y-h*0.5),Vector2(left+float(index)*stride,at.y+h*0.5),Color(accent,0.75*alpha),2.0,true)

func _draw_playing(at: Vector2,accent: Color,alpha: float) -> void:
	for index in range(3):
		var height := 3.0+4.0*(0.5+0.5*sin(listen_seconds*5.0+float(index)*1.7))
		draw_line(at+Vector2(float(index)*3.0,-height*0.5),at+Vector2(float(index)*3.0,height*0.5),Color(accent,alpha),1.5,true)
