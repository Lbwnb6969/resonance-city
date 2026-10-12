extends Button
## Compact real route choices. The shared footer owns PCM time and consequences.
const ROUTE_INK := {"deep":Color("628b94"),"weave":Color("bd7958"),"warm":Color("76966b")}
const PAPER := Color("f6f0e1")
const PINE := Color("284f46")
const INK := Color("243f3a")
const MUTED := Color("607166")
const COPPER := Color("c4a568")
const ROW_HEIGHT := 76.0
const TITLE_SIZE := 18
const SOUND_SIZE := 14
const USE_SIZE := 13
var choice_id := ""
var choice: Dictionary = {}
var thumbnail_entry: Dictionary = {}
var thumbnail: Texture2D
var listening := false

func setup(route: Dictionary,owner_demo: Control) -> void:
	choice = route.duplicate(true)
	choice_id = str(choice["id"])
	text = str(choice["label"])
	tooltip_text = "点击听四秒 · "+str(choice["city"])+"；确认才种下"
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(250,ROW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	thumbnail_entry = owner_demo.building_catalog.preview_entry(choice_id)
	thumbnail = owner_demo.building_catalog.texture_for(thumbnail_entry)
	for state: String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var surface := StyleBoxFlat.new()
		surface.bg_color = Color.TRANSPARENT
		surface.set_corner_radius_all(8)
		surface.content_margin_left = 10
		surface.content_margin_right = 10
		surface.content_margin_top = 8
		surface.content_margin_bottom = 8
		if state == "hover": surface.bg_color = Color("e4dfcd")
		elif state in ["pressed","hover_pressed"]:
			surface.bg_color = PINE.lightened(0.025) if state == "hover_pressed" else PINE
		elif state == "disabled": surface.bg_color = Color("d9dccf",0.30)
		elif state == "focus":
			surface.border_color = COPPER
			surface.set_border_width_all(1)
		add_theme_stylebox_override(state,surface)
	# Native Button retains its accessible text and all mouse/keyboard signals.
	# Draw the same label once, aligned with the actual route building.
	for colour: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color","font_focus_color"]:
		add_theme_color_override(colour,Color.TRANSPARENT)
	resized.connect(queue_redraw)
	toggled.connect(func(_pressed: bool) -> void: queue_redraw())
	set_process(false)
	queue_redraw()

func set_listening(value: bool) -> void:
	if listening == value: return
	listening = value
	queue_redraw()

func set_building_entry(entry: Dictionary,owner_demo: Control) -> void:
	if thumbnail_entry.get("id","") == entry["id"]: return
	thumbnail_entry = entry
	thumbnail = owner_demo.building_catalog.texture_for(entry)
	queue_redraw()

func status_text() -> String:
	if listening: return "正在试听"
	return "已选" if button_pressed else "点击试听"

func content_layout() -> Dictionary:
	var font := get_theme_font("font")
	var label := str(choice["label"])
	var use := "商业" if str(choice["type"]) == "commercial" else "住宅"
	var title_width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,TITLE_SIZE).x
	var use_width := font.get_string_size(use,HORIZONTAL_ALIGNMENT_LEFT,-1,USE_SIZE).x
	return {"thumbnail":Rect2(11,7,54,51),"motif":Rect2(12,63,52,7),
		"title":Rect2(80,10,title_width,23),"use":Rect2(80+title_width+10,13,use_width,20),
		"sound":Rect2(80,37,size.x-90,22),"state":Rect2(size.x-39,13,28,20),"use_text":use,
		"title_baseline":Vector2(80,29),"use_baseline":Vector2(80+title_width+10,28),
		"sound_baseline":Vector2(80,54),"state_baseline":Vector2(size.x-39,28)}

func _draw() -> void:
	if choice.is_empty(): return
	var selected := button_pressed and not disabled
	var alpha := 0.42 if disabled else 1.0
	var ink := Color(PAPER if selected else INK,alpha)
	var quiet := Color(PAPER.lerp(COPPER,0.18) if selected else MUTED,alpha)
	var accent: Color = ROUTE_INK[choice_id]
	var font := get_theme_font("font")
	var layout := content_layout()
	var frame: Rect2 = layout["thumbnail"]
	# This is the actual street-facing catalogue texture, without a second box.
	var texture_size := thumbnail.get_size()
	var factor := minf(frame.size.x/texture_size.x,frame.size.y/texture_size.y)
	var fitted := texture_size*factor
	var at := frame.position+(frame.size-fitted)*0.5
	draw_texture_rect(thumbnail,Rect2(at,fitted),false,Color(1,1,1,alpha))
	var motif: Rect2 = layout["motif"]
	_draw_voice_motif(motif.position+Vector2(0,3),PAPER.lerp(accent,0.5) if selected else accent,alpha)
	draw_string(font,layout["title_baseline"],str(choice["label"]),HORIZONTAL_ALIGNMENT_LEFT,-1,TITLE_SIZE,ink)
	draw_string(font,layout["use_baseline"],layout["use_text"],HORIZONTAL_ALIGNMENT_LEFT,-1,USE_SIZE,quiet)
	draw_string(font,layout["sound_baseline"],str(choice["sound"]),HORIZONTAL_ALIGNMENT_LEFT,-1,SOUND_SIZE,quiet)
	if listening:
		draw_string(font,layout["state_baseline"],"试听",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ink)
	elif button_pressed:
		var state: Rect2 = layout["state"]
		var tick := state.position+Vector2(11,11)
		draw_polyline(PackedVector2Array([tick+Vector2(-5,0),tick+Vector2(-1,4),tick+Vector2(6,-4)]),ink,1.7,true)
	if not button_pressed:
		draw_line(Vector2(80,size.y-1),Vector2(size.x-11,size.y-1),Color(COPPER,0.18*alpha),1.0,true)

func _draw_voice_motif(at: Vector2,accent: Color,alpha: float) -> void:
	# Static note-onset / hold marks from this actual route definition. These
	# illustrate the sound pattern; the card never simulates PCM amplitude.
	var marks: Array = choice["theme_steps"]
	var hold := clampf(float(choice["theme_tail"])*2.0,1.0,6.0)
	for step in marks:
		var x := at.x+float(step)*52.0/32.0
		draw_line(Vector2(x,at.y-2),Vector2(x,at.y+2),Color(accent,0.78*alpha),1.25,true)
		draw_line(Vector2(x,at.y),Vector2(x+hold,at.y),Color(accent,0.78*alpha),1.25,true)
