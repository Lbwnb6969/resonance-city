extends Node2D
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
## Map buildings never occlude this compact first-play legend.
var demo: Control
var panel_style: StyleBoxFlat
var title_style: StyleBoxFlat
var legend_visible := true

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	panel_style = Ui.panel(0)
	title_style = Ui.panel(0)
	title_style.bg_color = Ui.GREEN
	title_style.border_color = Color("416356")

func sync() -> void:
	visible = demo.first_composition_mode and not demo.black
	legend_visible = not (demo.planning_guide.opened or demo.community_workbench.opened or demo.neighborhood_editor.opened or demo.menu.visible and demo._expression_context())
	if visible: queue_redraw()

func _draw() -> void:
	var ink := Ui.INK
	var font := ThemeDB.fallback_font
	draw_style_box(title_style,Rect2(24,24,244,82 if legend_visible else 44))
	# A restrained music mark and clear title stay readable over any terrain.
	for i in range(5):
		draw_line(Vector2(42+i*5,42-i%3*3),Vector2(42+i*5,60+i%2*4),Ui.GOLD,2,true)
	draw_string(font,Vector2(80,57 if legend_visible else 54),"共鸣之城",HORIZONTAL_ALIGNMENT_LEFT,-1,24 if legend_visible else 20,Ui.PAPER)
	if not legend_visible: return
	draw_string(font,Vector2(80,83),demo._composition_title(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c2d1bd"))
	var panel := Rect2(demo.size.x-386.0,24.0,350.0,86.0)
	var roots: Array = demo.AuthoredDuet.roots(demo.shown_world,demo.model.audible_pitches())
	if roots.size() >= 2: panel.size.y = 44+mini(3,roots.size())*24
	draw_style_box(panel_style,panel)
	draw_string(font,panel.position+Vector2(16,25),"你的城市声谱" if roots.size() >= 2 else "一座会演奏的河湾",HORIZONTAL_ALIGNMENT_LEFT,-1,16,ink)
	if roots.size() >= 2:
		for i in range(mini(3,roots.size())):
			var root: Dictionary = roots[i]
			var choice: Dictionary = demo.PlayerExpression.definition(str(root["expression"]))
			var y := panel.position.y+49+i*24
			var route_ink: Color = demo.FirstExpressionIdentity.STYLES[str(root["expression"])]["ink"]
			draw_circle(Vector2(panel.position.x+21,y-4),4,route_ink)
			var pitch := int(root["current_midi"])
			var text := "%s · %s   %s%d" % [str(root["community_name"]),str(choice["label"]),demo.note_name(pitch),pitch/12-1]
			draw_string(font,Vector2(panel.position.x+34,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)
		return
	var chips := [["深流","低音 · 慢拍",Color("628b94")],["织机","高音 · 短拍",Color("bd7958")],["暖庭","中音 · 和声",Color("76966b")]]
	var x := panel.position.x+14.0
	for chip: Array in chips:
		draw_circle(Vector2(x+5,panel.position.y+53),4.0,chip[2])
		draw_string(font,Vector2(x+15,panel.position.y+54),str(chip[0]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,chip[2].darkened(0.15))
		draw_string(font,Vector2(x+15,panel.position.y+72),str(chip[1]),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Ui.MUTED)
		x += 98.0
