extends Button
## Native vectors keep the paper palette sharp at every UI scale.
const Stamp=preload("res://scripts/ui/city_creation_prototype_stamp.gd")
const UI=preload("res://scripts/ui/valley_ui_theme.gd")
const LANDMARKS={
	"bell_keep":[[-.55,.7],[-.55,-.5],[-.7,-.5],[0,-1.],[.7,-.5],[.55,-.5],[.55,.7]],
	"watermill":[[-.95,.7],[-.95,-.2],[-.45,-.75],[.05,-.2],[.05,.7]],
	"music_academy":[[-.95,.7],[-.95,0],[-.5,0],[-.5,-.4],[0,-.8],[.5,-.4],[.5,0],[.95,0],[.95,.7]],
	"botanical_palace":[[-.95,.7],[-.95,-.05],[-.5,-.55],[0,-.75],[.5,-.55],[.95,-.05],[.95,.7]],
	"clockwork_depot":[[-.95,.7],[-.95,-.1],[-.35,-.1],[-.35,-.65],[0,-.9],[.35,-.65],[.35,-.1],[.95,-.1],[.95,.7]],
	"floating_amphitheater":[[-1.,.65],[-1.,0],[-.5,-.2],[0,-.8],[.5,-.2],[1.,0],[1.,.65]],
	"riverbank":[[-.6,.7],[-.3,-.55],[-.45,-.55],[-.45,-.8],[0,-1.],[.45,-.8],[.45,-.55],[.3,-.55],[.6,.7]],
	"highland":[[-1.,.65],[-1.,.35],[-.65,.35],[-.65,.1],[.65,.1],[.65,.35],[1.,.35],[1.,.65]],
	"courtyard":[[-.95,.7],[-.95,.3],[-.65,.3],[-.65,-.1],[-.3,-.1],[-.3,-.5],[.3,-.5],[.3,-.1],[.65,-.1],[.65,.3],[.95,.3],[.95,.7]],
	"artisan":[[-.65,.7],[-.65,-.2],[-.35,-.2],[-.35,-.65],[0,-1.],[.35,-.65],[.35,-.2],[.65,-.2],[.65,.7]]}
var shape_key:=""
var caption:=""
var active:bool:
	get:return button_pressed
	set(value):button_pressed=value;queue_redraw()
func configure(key:String,label:String)->void:
	shape_key=key;caption=label;text="";custom_minimum_size=Vector2(96,88)
	for state_name:String in ["normal","hover","pressed","focus"]:add_theme_stylebox_override(state_name,UI.button(state_name,state_name=="pressed"))
	add_theme_stylebox_override("hover_pressed",UI.button("hover",true))
	queue_redraw()
func _draw()->void:
	var ink:=get_theme_color("font_disabled_color" if disabled else "font_pressed_color" if active or is_pressed() else "font_color")
	if active and not disabled:ink=UI.PAPER
	var gold:=Color("b38b49");var at:=Vector2(size.x*.5,34);var r:=24.
	if shape_key.begins_with("prototype/"):Stamp.draw(self,shape_key.trim_prefix("prototype/"),at,r,ink,gold)
	elif shape_key.begins_with("style/"):_house_stamp(shape_key.get_slice("/",1),at)
	else:
		var key:=shape_key.get_slice("/",1);var rows:Array=LANDMARKS.get(key,[]);var points:=PackedVector2Array()
		for point:Array in rows:points.append(at+Vector2(point[0],point[1])*r)
		if points.size()>2:
			draw_colored_polygon(points,Color(ink,.09));points.append(points[0]);draw_polyline(points,ink,1.7,true)
		if key=="watermill":
			draw_arc(at+Vector2(10,6),11,0,TAU,24,ink,1.5,true)
			for angle:float in [0.,PI*.5,PI*.25,PI*.75]:draw_line(at+Vector2(10,6)-Vector2.from_angle(angle)*11,at+Vector2(10,6)+Vector2.from_angle(angle)*11,ink,1.,true)
		elif key in ["bell_keep","clockwork_depot","artisan"]:draw_arc(at+Vector2(0,-8),5,0,TAU,20,ink,1.2,true)
		elif key=="highland":
			draw_arc(at+Vector2(0,-6),12,0,TAU,24,ink,1.5,true);draw_line(at+Vector2(-12,1),at+Vector2(12,-13),gold,1.4,true)
		elif key=="botanical_palace":
			for x:float in [-12.,0.,12.]:draw_line(at+Vector2(x,-8),at+Vector2(x,14),ink,1.,true)
	var font:=get_theme_font("font");var label:=caption
	if font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>size.x-8:
		while label.length()>1 and font.get_string_size(label+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>size.x-8:label=label.left(-1)
		label+="…"
	var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_string(font,Vector2(maxf(4,(size.x-width)*.5),size.y-12),label,HORIZONTAL_ALIGNMENT_LEFT,size.x-8,12,ink)
	if active:draw_line(Vector2(12,size.y-5),Vector2(size.x-12,size.y-5),gold,2.,true)

func _face(at:Vector2,coords:Array,color:Color)->void:
	var points:=PackedVector2Array()
	for index in range(0,coords.size(),2):points.append(at+Vector2(coords[index],coords[index+1]))
	draw_colored_polygon(points,color);points.append(points[0]);draw_polyline(points,Color("534c43"),1.,true)

func _house_stamp(kind:String,at:Vector2)->void:
	var beam:=Color("695244");var slate:=Color("586f77");var wall:=Color("f0dfa9")
	if kind=="round_tower":
		_face(at,[-14,-5,14,-5,14,12,10,16,0,18,-10,16,-14,12],Color("c8bda0"))
		_face(at,[4,-5,14,-5,14,12,10,16,4,17],Color("a9997e"))
		_face(at,[-18,-6,-3,-23,1,-26,18,-6,10,-2,0,0,-11,-2],slate)
		draw_rect(Rect2(at+Vector2(-6,4),Vector2(4,8)),beam);return
	var stone:=kind=="stone";var timber:=kind=="timber"
	var ridge:=-22 if timber else (-12 if stone else -16)
	_face(at,[-19,-2,-7,ridge,6,-4,6,16,-19,14],Color("b8c3ba") if stone else wall)
	_face(at,[6,-4,21,-8,21,11,6,16],Color("899b99") if stone else Color("c7ad85"))
	_face(at,[-8,ridge,7,ridge-3,24,-8,6,-2],slate if stone or timber else Color("bd7958"))
	draw_line(at+Vector2(-22,0),at+Vector2(-7,ridge),beam,2.5,true)
	if timber:
		for post:int in [-17,-7,4]:draw_line(at+Vector2(post,-2),at+Vector2(post,14),beam,2.5,true)
		draw_line(at+Vector2(-18,-2),at+Vector2(5,-2),beam,2.5,true);draw_line(at+Vector2(-17,12),at+Vector2(-8,1),beam,2.,true)
	elif stone:
		for course in range(3):
			var base:=at+Vector2(-19,course*5);draw_rect(Rect2(base,Vector2(5+course%2*3,4)),Color("e0dac6"));draw_line(base+Vector2(0,4),base+Vector2(22,5),slate,1.,true)
	else:
		draw_rect(Rect2(at+Vector2(-16,2),Vector2(6,6)),slate);draw_line(at+Vector2(-17,9),at+Vector2(-9,9),beam,1.5,true)
	draw_rect(Rect2(at+Vector2(-4,6),Vector2(6,9)),beam);draw_rect(Rect2(at+Vector2(12,-1),Vector2(4,6)),slate.darkened(.25))
