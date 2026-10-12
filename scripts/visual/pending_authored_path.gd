extends Node2D
## A read-only spatial sentence from an heard authored root to a queued target.
## It exists only while the player's next seed is still a preview or pending
## device-bound transaction; it never changes World, audio, or save state.
const AuthoredDuet = preload("res://scripts/world/authored_duet.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Identity = preload("res://scripts/visual/first_expression_identity.gd")

var demo: Control
var line: PackedVector2Array = PackedVector2Array()
var ink := Color("a89059")
var label := ""
var alpha := 0.0

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	z_index = 53

func sync() -> void:
	line = PackedVector2Array()
	label = ""
	alpha = 0.0
	if demo == null or not bool(demo.first_composition_mode) or bool(demo.black):
		queue_redraw()
		return
	if demo.planning_guide.opened or demo.menu.visible and not demo._expression_context():
		queue_redraw()
		return
	var target := _target_position()
	if target == Vector2.INF or demo.shown_world == null:
		queue_redraw()
		return
	var roots: Array[Dictionary] = AuthoredDuet.roots(demo.shown_world,demo.model.audible_pitches())
	if roots.is_empty():
		queue_redraw()
		return
	var selected: Dictionary = {}
	var nearest := INF
	for root: Dictionary in roots:
		var p := Coupling.position_of(demo.shown_world.by_id[str(root["root_id"])])
		var distance := p.distance_squared_to(target)
		if distance < nearest:
			nearest = distance
			selected = root
	if selected.is_empty():
		queue_redraw()
		return
	var from := Coupling.position_of(demo.shown_world.by_id[str(selected["root_id"])])
	var screen_from: Vector2 = demo.point(from)
	var screen_to: Vector2 = demo.point(target)
	var distance: float = screen_from.distance_to(screen_to)
	if distance < 18.0:
		queue_redraw()
		return
	var control: Vector2 = (screen_from+screen_to)*0.5+Vector2(0,-clampf(distance*0.16,12.0,42.0))
	for i in range(17):
		var t := float(i)/16.0
		line.append(screen_from*(1.0-t)*(1.0-t)+control*2.0*(1.0-t)*t+screen_to*t*t)
	var source_expression := str(selected.get("expression",""))
	var target_expression := _target_expression()
	var expression_for_ink := target_expression if not target_expression.is_empty() else source_expression
	ink = Color(Identity.STYLES.get(expression_for_ink,{"ink":Color("a89059")})["ink"])
	var source_label := str({"deep":"深流","weave":"织机","warm":"暖庭"}.get(source_expression,source_expression))
	var target_label := str({"deep":"深流","weave":"织机","warm":"暖庭"}.get(target_expression,"下一句"))
	label = "你的%s → %s" % [source_label,target_label]
	alpha = 0.72 if _has_preview_or_pending() else 0.0
	queue_redraw()

func _has_preview_or_pending() -> bool:
	if not demo.pending_expression_choice.is_empty(): return true
	if not demo.menu.visible or not demo._expression_context() or demo.expression_choice.is_empty(): return false
	return not demo.expression_comparison.is_empty() and demo.expression_comparison_key == demo._expression_preview_identity() \
		and bool(demo.expression_comparison.get("variants",{}).get(demo.expression_choice,{}).get("accepted",false))

func _target_position() -> Vector2:
	if not demo.pending_expression_choice.is_empty():
		var operation: Dictionary = demo.pending_expression_choice.get("operation",{})
		return _raw_position(operation.get("position",[]))
	if not demo.menu.visible or not demo._expression_context() or demo.expression_choice.is_empty(): return Vector2.INF
	if demo.expression_comparison.is_empty() or demo.expression_comparison_key != demo._expression_preview_identity(): return Vector2.INF
	var variant: Dictionary = demo.expression_comparison.get("variants",{}).get(demo.expression_choice,{})
	if not bool(variant.get("accepted",false)): return Vector2.INF
	return _raw_position(variant.get("birth",{}).get("building",{}).get("position",[]))

func _target_expression() -> String:
	if not demo.pending_expression_choice.is_empty():
		return str(demo.pending_expression_choice.get("operation",{}).get("expression",""))
	return str(demo.expression_choice)

func _raw_position(raw: Variant) -> Vector2:
	if not raw is Array or raw.size() != 2: return Vector2.INF
	return Vector2(float(raw[0]),float(raw[1]))

func _draw() -> void:
	if line.size() < 2 or alpha <= 0.0: return
	for i in range(line.size()-1):
		var a := float(i)/float(line.size()-2)
		draw_dashed_line(line[i],line[i+1],Color(ink,alpha*(0.82-0.20*a)),2.0,5.0,true)
	draw_circle(line[0],4.0,Color(ink,alpha*0.9))
	draw_arc(line[-1],8.0,0.0,TAU,24,Color(ink,alpha),1.5,true)
	var font := ThemeDB.fallback_font
	var mid := line[line.size()/2]+Vector2(0,-11)
	var width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_rect(Rect2(mid-Vector2(width*0.5+5,13),Vector2(width+10,18)),Color("f4f0df",0.96),true)
	draw_string(font,mid+Vector2(-width*0.5,4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,11,ink.darkened(0.28))
