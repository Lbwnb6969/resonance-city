extends PanelContainer
## A transient planning tool. Closing it never removes a committed city choice.
const Charter = preload("res://scripts/world/development_charter.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
var demo: Control
var stage := "charter"
var plan_id := ""
var scope: Array = []
var anchor_kind := "park"
var opened := false
var heading: Label
var detail: Label
var actions: HBoxContainer
var cards: HBoxContainer
var confirm: Button
var candidate: Dictionary = {}
var preview: Dictionary = {}
var preview_key: Array = []
var scope_polygons: Array[PackedVector2Array] = []
var scope_version: Array = []
var observed_phrase := -1
var causal_feedback_count := 0

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	name = "PlanningGuide"
	z_index = 120
	mouse_filter = Control.MOUSE_FILTER_STOP
	var theme_style := Theme.new()
	for state: String in ["normal","hover","pressed","disabled","focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("d7e2cd") if state == "hover" else (Color("bfd1b4") if state == "pressed" else Color("e7ebde"))
		button_style.border_color = Color("91a581")
		button_style.set_border_width_all(1 if state != "focus" else 2)
		button_style.set_corner_radius_all(8)
		button_style.content_margin_left = 10
		button_style.content_margin_right = 10
		button_style.content_margin_top = 7
		button_style.content_margin_bottom = 7
		theme_style.set_stylebox(state,"Button",button_style)
	for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		theme_style.set_color(state,"Button",Color("435b50"))
	theme_style.set_color("font_disabled_color","Button",Color("93a08b"))
	theme = theme_style
	var style := StyleBoxFlat.new()
	style.bg_color = Color("eef0e7f5")
	style.border_color = Color("9bab91")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	add_child(box)
	var top := HBoxContainer.new()
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",20)
	heading.add_theme_color_override("font_color",Color("435c59"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	var close := Button.new()
	close.text = "先随便玩 · P收起"
	close.pressed.connect(hide_tool)
	top.add_child(close)
	box.add_child(top)
	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation",10)
	for id: String in ["compact","corridor","bluegreen"]:
		var spec: Dictionary = Charter.PLANS[id]
		var button := Button.new()
		button.text = "%s\n\n%s\n取舍 · %s\n机会 · %s" % [spec["title"],spec["tendency"],spec["tradeoff"],spec["opportunity"]]
		button.custom_minimum_size = Vector2(224,132)
		button.add_theme_font_size_override("font_size",15)
		button.pressed.connect(choose_plan.bind(id))
		cards.add_child(button)
	box.add_child(cards)
	detail = Label.new()
	detail.add_theme_color_override("font_color",Color("51665c"))
	detail.add_theme_font_size_override("font_size",15)
	box.add_child(detail)
	actions = HBoxContainer.new()
	confirm = Button.new()
	confirm.text = "确认社区范围 → 摆放锚点"
	confirm.pressed.connect(commit_scope)
	actions.add_child(confirm)
	for item in [["公园 · 留白","park"],["文化馆 · 主题","civic"]]:
		var button := Button.new()
		button.text = item[0]
		button.pressed.connect(choose_anchor.bind(item[1]))
		actions.add_child(button)
	box.add_child(actions)
	hide()

func reset_for_city() -> void:
	scope.clear()
	scope_polygons.clear()
	scope_version.clear()
	preview_key.clear()
	candidate.clear()
	observed_phrase = demo.shown_world.phrase_index
	opened = demo.model.world.development_charters.is_empty()
	causal_feedback_count = 0 if opened else 2
	stage = "charter"
	refresh()

func open_tool() -> void:
	demo.menu.hide()
	opened = true
	stage = "charter"
	scope.clear()
	scope_version.clear()
	refresh()

func hide_tool() -> void:
	opened = false
	hide()
	candidate.clear()
	demo.queue_redraw()

func choose_plan(id: String) -> void:
	plan_id = id
	stage = "scope"
	scope.clear()
	scope_version.clear()
	refresh()

func choose_anchor(kind: String) -> void:
	anchor_kind = kind
	preview_key.clear()
	refresh()

func refresh() -> void:
	cards.visible = stage == "charter"
	actions.visible = stage != "charter"
	confirm.visible = stage == "scope"
	confirm.disabled = scope.is_empty()
	for i in range(1,actions.get_child_count()): actions.get_child(i).visible = stage == "anchor"
	if stage == "charter":
		heading.text = "你想让这片城市怎样生长？"
		detail.text = "先选倾向，再在地图选社区；公园和文化馆由你摆，房屋沿合法空地自动长。"
	elif stage == "scope":
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · 选择社区范围"
		var names: Array[String] = []
		for cid in scope: names.append(str(demo.model.world.communities[cid]["name"]))
		var summary := Charter.scope_preview(demo.model.world,scope)
		detail.text = ("点击地图选择一个社区；Shift点击可选多个。\n" if scope.is_empty() else "范围 · "+ "、".join(names)+"\n")
		detail.text += "%d栋现有房屋 · %d块合法空置地块 · 不改房屋音级，不封锁其他用途" % [summary["houses"],summary["legal_lots"]]
	else:
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · 摆放"+("公园" if anchor_kind == "park" else "文化馆")
		detail.text = "移动到所选社区的空置地块或公共候选地；点击地图提交。\n公园让主题留白；文化馆支持主题。角色进入仍取决于真实条件与声部竞争。"
	preview_key.clear()
	reset_size()
	position = Vector2(maxf(16.0,(demo.size.x-size.x)*0.5),76)
	visible = opened and not demo.black

func map_click(p: Vector2,multiple: bool) -> bool:
	if not opened: return false
	if stage == "charter": return true
	if stage == "scope":
		var cid := FabricRelations.community_for_position(demo.model.world,p)
		if not demo.model.world.communities.has(cid): return true
		if not multiple: scope.clear()
		if scope.has(cid): scope.erase(cid)
		else: scope.append(cid)
		scope_version.clear()
		refresh()
		return true
	update_candidate(p)
	if candidate.is_empty() or not bool(candidate.get("allowed",false)):
		demo._message("选社区内的合法空置地块或公共候选地")
		return true
	if not Charter.in_scope(demo.model.world,str(candidate["community_id"]),scope):
		demo._message("这里不在所选社区；按P可为另一片社区规划")
		return true
	if not bool(preview.get("access",false)):
		demo._message("这片公共空间没有能接入道路的真实入口")
		return true
	var result: Dictionary = demo.model.submit({"kind":anchor_kind,"position":candidate["position"].duplicate()})
	if bool(result["accepted"]):
		demo.ripple_position = p
		demo.ripple_seconds = 0.6
		demo._message("规划已排入下一乐句 · "+("公园为主题留白" if anchor_kind == "park" else "文化馆按道路与容量支持主题")+"；点击街边播种声音，房屋会自动生长")
		hide_tool()
	else: demo._message(str(result["reason"]))
	return true

func commit_scope() -> void:
	if scope.is_empty(): return
	var result: Dictionary = demo.model.submit({"kind":"charter","plan_id":plan_id,"community_ids":scope.duplicate()})
	if not bool(result["accepted"]):
		demo._message(str(result["reason"]))
		return
	stage = "anchor"
	refresh()

func update_candidate(p: Vector2) -> void:
	candidate = demo.model.world.planning_candidate(p)
	preview.clear()
	if candidate.is_empty(): return
	preview = Charter.anchor_preview(demo.model.world,candidate,anchor_kind,Planning.public_access(demo.model.world,candidate))
	var name := str(demo.model.world.communities.get(str(candidate["community_id"]),{}).get("name",""))
	var valid: bool = bool(candidate.get("allowed",false)) and bool(preview["access"]) and Charter.in_scope(demo.model.world,str(candidate["community_id"]),scope)
	detail.text = "%s · %s\n" % [name,"占用这片真实空地，房屋会避开" if valid else "此处不可提交 · "+str(candidate.get("reason","请选社区内有入口的空地"))]
	detail.text += "道路可达%d栋" % int(preview["reachable"])
	if anchor_kind == "civic": detail.text += " · 首级容量18栋，重叠服务不重复"
	detail.text += " · 虚线=规划影响，金点=道路可达\n按住空格试听当前副本 · 机会 · "+("公园留白；附近合法候选可围绕它生长" if anchor_kind == "park" else "文化主题；需成熟社区和可用主题槽，不保证立即演奏")

func sync() -> void:
	visible = opened and not demo.black
	if observed_phrase != demo.shown_world.phrase_index:
		observed_phrase = demo.shown_world.phrase_index
		for event in demo.shown_world.events:
			if int(event.get("frame",-1)) != observed_phrase*int(demo.shown_world.cfg["timing"]["phrase_frames"]): continue
			if causal_feedback_count < 2 and str(event.get("kind","")) == "birth" and event.has("plan_id"):
				causal_feedback_count += 1
				demo._message(str(Charter.PLANS[event["plan_id"]]["title"])+" · 新房沿你的规划生长；可继续调音或按P规划下一片社区")
				break
	if not visible: return
	if stage == "anchor":
		var key: Array = [demo.pointer,Charter.version(demo.model.world),anchor_kind]
		if key != preview_key:
			update_candidate(demo.world_at(demo.pointer))
			preview_key = key
	var key: Array = [demo.shown_world.phrase_index,scope]
	if key == scope_version: return
	scope_version = [demo.shown_world.phrase_index,scope.duplicate()]
	scope_polygons.clear()
	for lot in demo.shown_world.lots:
		if Charter.in_scope(demo.shown_world,str(lot["community_id"]),scope): scope_polygons.append(lot["polygon"])
	for building in demo.shown_world.buildings:
		if Charter.in_scope(demo.shown_world,str(building["community_id"]),scope):
			scope_polygons.append(demo.shown_world.building_polygon(Vector2(float(building["position"][0]),float(building["position"][1]))))

func draw_map() -> void:
	if not visible: return
	for world_polygon in scope_polygons:
		var polygon: PackedVector2Array = demo._project_polygon(world_polygon)
		demo.draw_colored_polygon(polygon,Color(0.55,0.72,0.57,0.16))
		polygon.append(polygon[0])
		demo.draw_polyline(polygon,Color(0.45,0.62,0.45,0.5),1.1,true)
	if stage != "anchor" or candidate.is_empty(): return
	var polygon: PackedVector2Array = demo._project_polygon(candidate["polygon"])
	var allowed: bool = bool(candidate.get("allowed",false)) and bool(preview.get("access",false)) and Charter.in_scope(demo.model.world,str(candidate["community_id"]),scope)
	var tint := Color("729b70") if allowed else Color("b47664")
	demo.draw_colored_polygon(polygon,Color(tint,0.4))
	polygon.append(polygon[0])
	demo.draw_polyline(polygon,tint,2.0,true)
	# Planning field is dashed and deliberately separate from acoustic/service edges.
	var center := Vector2(float(candidate["position"][0]),float(candidate["position"][1]))
	var radius := 5.0 if anchor_kind == "park" else 6.0
	for i in range(32):
		var a: Vector2 = demo.point(center+Vector2.from_angle(TAU*float(i)/32.0)*radius)
		var b: Vector2 = demo.point(center+Vector2.from_angle(TAU*(float(i)+0.55)/32.0)*radius)
		demo.draw_line(a,b,Color(tint,0.6),1.3,true)
	for id in preview.get("covered",[]):
		if not demo.shown_world.by_id.has(id): continue
		var building: Dictionary = demo.shown_world.by_id[id]
		var p := Vector2(float(building["position"][0]),float(building["position"][1]))
		demo.draw_arc(demo.point(p),9.0,0.0,TAU,20,Color("c2a66b"),1.5,true)
	var access := Planning.public_access(demo.model.world,candidate)
	if not access.is_empty():
		var entrance := Vector2(float(access["entrance"][0]),float(access["entrance"][1]))
		demo.draw_circle(demo.point(entrance),4.0,Color("c2a66b"))
