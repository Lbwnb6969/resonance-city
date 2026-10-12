extends Node2D
## A small, clickable signature for each surviving authored root in the heard city.
const Duet = preload("res://scripts/world/authored_duet.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Identity = preload("res://scripts/visual/first_expression_identity.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const FONT_SIZE := 12
var badges: Array[Dictionary] = []
var style: StyleBoxFlat

func sync(demo: Control) -> void:
	visible = demo.first_composition_mode and not demo.black and not demo.menu.visible and not demo.planning_guide.opened and not demo.preview_started
	badges.clear()
	if not visible: return
	var frame: float = demo.clock.renderer.transport.audible_frame
	var font := ThemeDB.fallback_font
	for root: Dictionary in Duet.roots(demo.shown_world,demo.model.audible_pitches()):
		if int(root["birth_frame"]) > frame: continue
		var id := str(root["root_id"])
		var building: Dictionary = demo.shown_world.by_id[id]
		var family: Dictionary = demo.shown_world.families[str(root["family_id"])]
		var identity := Identity.identity(building,family)
		var pitch := int(root["current_midi"])
		var label := "你的%s · %s%d" % [PlayerExpression.definition(str(root["expression"]))["label"],demo.note_name(pitch),pitch/12-1]
		var at: Vector2 = demo.point(Coupling.position_of(building))
		var extent := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE)+Vector2(24,10)
		var bounds := Rect2(at+Vector2(-extent.x*0.5,20),extent)
		# Multiple roots can be close together. Keep their hit targets separate.
		for earlier: Dictionary in badges:
			if bounds.grow(3).intersects(earlier["bounds"]): bounds.position.y = earlier["bounds"].end.y+5.0
		if not Rect2(Vector2(12,142),demo.size-Vector2(24,210)).encloses(bounds): continue
		badges.append({"root_id":id,"position":at,"bounds":bounds,"label":label,"ink":identity["ink"],
			"hovered":demo.pointer_inside and bounds.has_point(demo.pointer)})
	queue_redraw()

func hit_root(screen_position: Vector2) -> String:
	if not visible: return ""
	for badge in badges:
		if badge["bounds"].has_point(screen_position): return str(badge["root_id"])
	return ""

func _draw() -> void:
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = Color("f4f0df",0.96)
		style.set_corner_radius_all(5)
	var font := ThemeDB.fallback_font
	for badge in badges:
		var bounds: Rect2 = badge["bounds"]
		var ink: Color = badge["ink"]
		var hovered: bool = badge["hovered"]
		draw_line(badge["position"]+Vector2(0,5),Vector2(bounds.get_center().x,bounds.position.y),Color(ink,0.72),1.0,true)
		draw_style_box(style,bounds)
		draw_circle(bounds.position+Vector2(8,bounds.size.y*0.5),3.0,ink)
		draw_string(font,bounds.position+Vector2(16,5+font.get_ascent(FONT_SIZE)),badge["label"],HORIZONTAL_ALIGNMENT_LEFT,-1,FONT_SIZE,ink.darkened(0.28))
		if hovered:
			draw_rect(bounds,Color(ink,0.8),false,1.2)
