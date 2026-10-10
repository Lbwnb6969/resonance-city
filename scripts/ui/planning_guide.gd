extends PanelContainer
## A transient planning tool. Closing it never removes a committed city choice.
const Charter = preload("res://scripts/world/development_charter.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
var comparison: Dictionary = {}
var comparison_key: Array = []
var demo: Control
var stage := "charter"
var plan_id := ""
var card_id := ""
var scope: Array = []
var anchor_kind := "park"
var opened := false
var heading: Label
var detail: Label
var actions: HBoxContainer
var cards: HBoxContainer
var card_choices: HBoxContainer
var drawn_card_ids: Array[String] = []
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
	card_choices = HBoxContainer.new()
	card_choices.add_theme_constant_override("separation",10)
	drawn_card_ids = ["infill_pulse","road_echo","anchor_bloom"]
	_rebuild_card_choices()
	box.add_child(card_choices)
	detail = Label.new()
	detail.custom_minimum_size.x = 720
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color",Color("51665c"))
	detail.add_theme_font_size_override("font_size",15)
	box.add_child(detail)
	actions = HBoxContainer.new()
	confirm = Button.new()
	confirm.text = "确认社区范围 → 摆放锚点"
	confirm.pressed.connect(commit_scope)
	actions.add_child(confirm)
	for item in [["暂不建设","none"],["公园 · 留白","park"],["文化馆 · 主题","civic"]]:
		var button := Button.new()
		button.text = item[0]
		button.toggle_mode = true
		button.set_meta("anchor_kind",item[1])
		button.pressed.connect(choose_anchor.bind(item[1]))
		actions.add_child(button)
	box.add_child(actions)
	hide()

func reset_for_city() -> void:
	scope.clear()
	scope_polygons.clear()
	scope_version.clear()
	preview_key.clear()
	comparison.clear()
	comparison_key.clear()
	candidate.clear()
	observed_phrase = demo.shown_world.phrase_index
	opened = demo.model.world.development_charters.is_empty()
	causal_feedback_count = 0 if opened else 2
	stage = "charter"
	plan_id = ""
	card_id = ""
	refresh()

func open_tool() -> void:
	comparison.clear()
	comparison_key.clear()
	demo.menu.hide()
	opened = true
	stage = "charter"
	plan_id = ""
	card_id = ""
	scope.clear()
	scope_version.clear()
	refresh()

func hide_tool() -> void:
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	opened = false
	hide()
	candidate.clear()
	demo.queue_redraw()

func choose_plan(id: String) -> void:
	plan_id = id
	drawn_card_ids = PlanningCard.choices(demo.model.world,plan_id)
	if drawn_card_ids.is_empty(): drawn_card_ids = [PlanningCard.DEFAULT_ID]
	card_id = drawn_card_ids[0]
	_rebuild_card_choices()
	stage = "card"
	scope.clear()
	scope_version.clear()
	refresh()

func choose_card(id: String) -> void:
	if not PlanningCard.valid(id): return
	if not drawn_card_ids.is_empty() and not drawn_card_ids.has(id): return
	card_id = id
	stage = "scope"
	scope.clear()
	scope_version.clear()
	refresh()

func choose_anchor(kind: String) -> void:
	anchor_kind = kind
	preview_key.clear()
	refresh()
	if stage == "anchor": update_candidate(demo.world_at(demo.pointer))
	if demo.preview_requested and not comparison.is_empty(): demo._request_preview()

func refresh() -> void:
	cards.visible = stage == "charter"
	card_choices.visible = stage == "card"
	actions.visible = stage != "charter"
	confirm.visible = stage == "scope"
	confirm.disabled = scope.is_empty()
	for i in range(1,actions.get_child_count()):
		var button: Button = actions.get_child(i)
		button.visible = stage == "anchor"
		button.set_pressed_no_signal(button.get_meta("anchor_kind") == anchor_kind)
	if stage == "charter":
		heading.text = "你想让这片城市怎样生长？"
		detail.text = "先选倾向，再在地图选社区；公园和文化馆由你摆，房屋沿合法空地自动长。"
	elif stage == "card":
		heading.text = str(Charter.PLANS[plan_id]["title"]) + " · 选一张章首变化卡"
		detail.text = "变化卡只影响已有规划关系的候选优先级或生长时机，持续几句后自然退场；不会增加全城活力，也不会锁住公共设施。\n当前默认 · " + str(PlanningCard.CARDS[card_id]["title"]) + "（可直接点地图继续，也可改选下面任意一张）"
	elif stage == "scope":
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · 选择社区范围"
		var names: Array[String] = []
		for cid in scope: names.append(str(demo.model.world.communities[cid]["name"]))
		var summary := Charter.scope_preview(demo.model.world,scope)
		detail.text = ("点击地图选择一个社区；Shift点击可选多个。\n" if scope.is_empty() else "范围 · "+ "、".join(names)+"\n")
		detail.text += "%d栋现有房屋 · %d块合法空置地块 · 不改房屋音级，不封锁其他用途" % [summary["houses"],summary["legal_lots"]]
	else:
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · "+{"park":"摆放公园","civic":"摆放文化馆","none":"暂不建设"}[anchor_kind]
		detail.text = "移动到所选社区的空置地块或公共候选地。\n按住空格比较不建、公园、文化馆；选择一种后点击地图确认。"
		detail.text += "\n不建会保留章程与正常成长，不自动留下永久空地。"
	preview_key.clear()
	reset_size()
	position = Vector2(maxf(16.0,(demo.size.x-size.x)*0.5),76)
	visible = opened and not demo.black

func _rebuild_card_choices() -> void:
	if card_choices == null: return
	for child in card_choices.get_children(): child.free()
	for id: String in drawn_card_ids:
		if not PlanningCard.CARDS.has(id): continue
		var spec: Dictionary = PlanningCard.CARDS[id]
		var button := Button.new()
		button.text = "%s\n\n%s\n取舍 · %s\n持续 · %d句" % [spec["title"],spec["tendency"],spec["tradeoff"],int(spec["duration_phrases"])]
		button.custom_minimum_size = Vector2(224,132)
		button.add_theme_font_size_override("font_size",15)
		button.pressed.connect(choose_card.bind(id))
		card_choices.add_child(button)
	card_choices.visible = stage == "card"

func map_click(p: Vector2,multiple: bool) -> bool:
	if not opened: return false
	if stage == "charter": return true
	if stage == "card":
		# Map-first input accepts the deterministic default card and proceeds;
		# explicit card buttons can replace it before this click.
		choose_card(card_id if not card_id.is_empty() else PlanningCard.DEFAULT_ID)
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
	if anchor_kind == "none":
		demo.model.cancel_planning()
		demo._message("这里暂不建设 · 章程保留，普通成长照常继续")
		hide_tool()
		return true
	if not bool(preview.get("access",false)):
		demo._message("这片公共空间没有能接入道路的真实入口")
		return true
	var result: Dictionary = demo.model.submit({"kind":anchor_kind,"position":candidate["position"].duplicate()})
	if bool(result["accepted"]):
		demo.ripple_position = p
		demo.ripple_seconds = 0.6
		demo._message("规划已排入下一乐句 · "+("公园为主题留白" if anchor_kind == "park" else "文化馆按道路与容量支持主题")+"；点击房屋可查看实际声部与下一步")
		hide_tool()
	else: demo._message(str(result["reason"]))
	return true

func commit_scope() -> void:
	if scope.is_empty(): return
	var result: Dictionary = demo.model.submit({"kind":"charter","plan_id":plan_id,"community_ids":scope.duplicate(),"card_refs":[card_id]})
	if not bool(result["accepted"]):
		demo._message(str(result["reason"]))
		return
	stage = "anchor"
	demo._message("章程与变化卡已排入下一乐句 · "+str(PlanningCard.CARDS.get(card_id,{}).get("title","变化卡")))
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
	detail.text += " · 虚线=规划影响，金点=道路可达\n按住空格比较三种选择；切换按钮听同一时刻的3秒合奏。"
	if not comparison.is_empty() and comparison_key == comparison_identity(): _show_comparison()

func comparison_identity() -> Array:
	if not opened or stage != "anchor": return []
	var site: Dictionary = demo.model.world.planning_candidate(demo.world_at(demo.pointer))
	if site.is_empty() or not bool(site.get("allowed",false)) or not Charter.in_scope(demo.model.world,str(site["community_id"]),scope): return []
	return [demo.model.presentation_token]+PublicPreview.identity(demo.model,site)

func accept_comparison(payload: Dictionary,request_key: Array) -> bool:
	if request_key.is_empty() or request_key != comparison_identity() or payload.get("source_version",[]) != request_key.slice(1): return false
	comparison = payload
	comparison_key = request_key.duplicate(true)
	update_candidate(demo.world_at(demo.pointer))
	return true

func _comparison_role_map_items(mapping: Dictionary) -> Array:
	var aliases := {"Lead":["Lead","theme"],"Bass":["Bass","bass"],
		"Rhythm":["Rhythm","commercial","rhythm"],"Response":["Response","response"]}
	var result: Array = []
	for role: String in ["Lead","Bass","Rhythm","Response"]:
		for key: String in aliases[role]:
			if mapping.has(key) and mapping[key] is Dictionary:
				result.append(mapping[key])
				break
	return result

func _comparison_opportunity_items(variant: Dictionary) -> Array:
	# New preview workers may expose a dedicated opportunity_preview payload. The
	# old public comparison contract keeps the same data under opportunities, so
	# the panel accepts both without inventing role audio for a missing payload.
	var source: Variant = variant.get("opportunity_preview",null)
	if source == null: source = variant.get("opportunities",[])
	if source is Dictionary:
		var object: Dictionary = source
		if object.has("communities") and object["communities"] is Array: source = object["communities"]
		elif object.has("roles") and object["roles"] is Array: source = object["roles"]
		elif object.has("opportunities"): source = object["opportunities"]
		elif object.has("role_opportunities") and object["role_opportunities"] is Dictionary:
			source = _comparison_role_map_items(object["role_opportunities"])
		else:
			var direct: Array = []
			for role: String in ["Lead","Bass","Rhythm","Response"]:
				if object.has(role) and object[role] is Dictionary: direct.append(object[role])
			source = direct
	if not source is Array: return []
	var entries: Array = source
	# public_planning_preview currently returns one community opportunity per
	# entry; select the first community's structured role rows for this compact
	# branch panel. A future direct role-array payload falls through unchanged.
	for raw in entries:
		if not raw is Dictionary: continue
		var community: Dictionary = raw
		if community.has("roles") and community["roles"] is Array: return community["roles"]
		if community.has("roles") and community["roles"] is Dictionary:
			var role_rows: Array = _comparison_role_map_items(community["roles"])
			if not role_rows.is_empty(): return role_rows
		if community.has("role_opportunities") and community["role_opportunities"] is Dictionary:
			var roles: Array = _comparison_role_map_items(community["role_opportunities"])
			if not roles.is_empty(): return roles
		if community.has("opportunities") and community["opportunities"] is Array:
			return community["opportunities"]
	return entries

func _comparison_role_item(items: Array,role: String) -> Dictionary:
	var ids := {
		"Lead":["Lead","P11-COMMUNITY-THEME","主题","社区主题"],
		"Bass":["Bass","P11-BASS","P11-BASS-EXPRESSION","低音","低音表达"],
		"Rhythm":["Rhythm","P11-RHYTHM","P11-COMMERCIAL-RHYTHM","节奏","商业律动"],
		"Response":["Response","P11-RESPONSE","P11-RIVER-RESPONSE","应答","跨岸应答"]}
	for raw in items:
		if not raw is Dictionary: continue
		var item: Dictionary = raw
		if str(item.get("role","")) == role: return item
		for key: String in ["rule_id","title","name"]:
			if ids[role].has(str(item.get(key,""))): return item
	return {}

func _comparison_role_line(items: Array,role: String) -> String:
	var labels := {"Bass":"低音表达","Rhythm":"商业律动","Response":"跨岸应答"}
	var item := _comparison_role_item(items,role)
	if item.is_empty():
		return "%s · 待条件 · 现 暂无本分支机会快照 · 下 重新试听后查看真实条件" % labels[role]
	var qualification: Variant = item.get("qualification",{})
	var qualified := bool(item.get("qualified",qualification.get("qualified",false) if qualification is Dictionary else false))
	var current := str(item.get("current","暂未生成" )).replace("\n","；")
	var next := str(item.get("next","继续规划后刷新" )).replace("\n","；")
	return "%s · %s · 现 %s · 下 %s" % [labels[role],"已就绪" if qualified else "待条件",current,next]

func _show_comparison() -> void:
	var lines: Array[String] = ["下一句真实对照 · 同一快照 / 同一增益 / 各3秒；点击地图才确认",
		"机会行只读同一分支的结构条件；试听是完整合奏，不承诺单独声部未来音频"]
	for kind: String in ["none","park","civic"]:
		var variant: Dictionary = comparison["variants"][kind]
		var title := str({"none":"暂不建","park":"公园","civic":"文化馆"}[kind])
		var prefix := "● " if kind == anchor_kind else "   "
		if not variant["accepted"]:
			lines.append(prefix+title+" · "+str(variant["reason"]))
			continue
		var role := "主题留白" if variant["score"]["theme"].is_empty() else "主题%d次/句" % int(variant["theme_events"])
		var service := "文化服务%d栋" % int(variant["service"]["served"])
		if kind == "civic":
			service = "本馆%d/%d栋 · 全城净增%d栋服务" % [variant["anchor"].get("served",[]).size(),int(variant["anchor"].get("service_capacity",18)),variant["newly_served_ids"].size()-variant["lost_service_ids"].size()]
		lines.append(prefix+title+" · 下一句%d栋 · " % int(variant["houses"])+service+" · "+role)
		var opportunity_items := _comparison_opportunity_items(variant)
		for role_id: String in ["Bass","Rhythm","Response"]:
			lines.append("　"+_comparison_role_line(opportunity_items,role_id))
	var chosen: Dictionary = comparison["variants"][anchor_kind]
	if chosen["accepted"]:
		var chosen_items := _comparison_opportunity_items(chosen)
		var chosen_theme := _comparison_role_item(chosen_items,"Lead")
		if chosen_theme.is_empty() and not chosen_items.is_empty(): chosen_theme = chosen_items[0]
		if not chosen_theme.is_empty() and not str(chosen_theme.get("next","")).is_empty():
			lines.append("下一步 · "+str(chosen_theme["next"]))
	lines.append("不建保留正常成长；公园/文化馆占用这片空地。新选择替换待落定公共规划。")
	detail.text = "\n".join(lines)

func sync() -> void:
	visible = opened and not demo.black
	if observed_phrase != demo.shown_world.phrase_index:
		observed_phrase = demo.shown_world.phrase_index
		for event in demo.shown_world.events:
			if int(event.get("frame",-1)) != observed_phrase*int(demo.shown_world.cfg["timing"]["phrase_frames"]): continue
			if causal_feedback_count < 2 and str(event.get("kind","")) == "birth" and event.has("plan_id"):
				causal_feedback_count += 1
				var building: Dictionary = demo.shown_world.by_id.get(str(event.get("district_id","")),{})
				var plan: Dictionary = Charter.PLANS.get(str(event.get("plan_id", "")),{})
				var title := str(plan.get("title","发展章程"))
				var kind := "律动街" if str(building.get("type","residential")) == "commercial" else ("工坊" if str(building.get("type","residential")) == "industrial" else "长音房")
				var shape := str(building.get("form","胚"))
				var pitch: String = demo.note_name(int(building.get("current_midi",48))) if not building.is_empty() else "待定音级"
				demo._message("%s · %s以%s落地，%s%s；下一步可继续调音或按P规划下一片社区" % [title,kind,shape,"音级"+pitch+" · " if pitch != "待定音级" else "", "沿你的规划生长"])
				break
	if not visible: return
	if stage == "anchor":
		var next_comparison_key := comparison_identity()
		if not comparison.is_empty() and next_comparison_key != comparison_key:
			comparison.clear()
			comparison_key.clear()
			if demo.preview_public: demo._cancel_preview_playback()
		var p: Vector2 = demo.world_at(demo.pointer)
		var key: Array = [p,Charter.version(demo.model.world),anchor_kind,not comparison.is_empty()]
		if key != preview_key:
			update_candidate(p)
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
	for i in range(0 if anchor_kind == "none" else 32):
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
