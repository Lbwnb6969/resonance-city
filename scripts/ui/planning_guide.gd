extends PanelContainer
## A transient planning tool. Closing it never removes a committed city choice.
const Charter = preload("res://scripts/world/development_charter.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
const PublicReuse = preload("res://scripts/world/public_site_reuse.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")
const TransitCharter = preload("res://scripts/world/transit_charter_anchor.gd")
const TransitRework = preload("res://scripts/world/transit_line_rework.gd")
var comparison: Dictionary = {}
var comparison_key: Array = []
var comparison_community_id := ""
var comparison_community_choices: HFlowContainer
var demo: Control
var stage := "charter"
var plan_id := ""
var card_id := ""
var committed_charter_id := ""
var scope: Array = []
## A transit station can hand its real catchment into the normal planning flow.
## Keep this seed separate from the editable scope so choosing a charter/card
## never loses the station's spatial suggestion before the player reaches scope.
var scope_seed: Array = []
var scope_source: Dictionary = {}
var anchor_kind := "park"
var opened := false
var heading: Label
var detail: Label
var theme_rework_button: Button
var charter_theme_key: Array = []
var actions: HBoxContainer
var cards: HBoxContainer
var card_choices: HBoxContainer
var drawn_card_ids: Array[String] = []
var confirm: Button
var transit_anchor_button: Button
var transit_edit_row: HBoxContainer
var transit_redraw_button: Button
var transit_edit_cancel_button: Button
var transit_compare_row: HBoxContainer
var transit_keep_button: Button
var transit_change_button: Button
var transit_choice := "edit"
var transit_comparison: Dictionary = {}
var transit_comparison_key: Array = []
var candidate: Dictionary = {}
var composition_public_hint: Dictionary = {}
## A player-drawn conversion is a fixed target, independent of the pointer.
var partial_site: Dictionary = {}
## An existing facility stays fixed even when the pointer leaves its parcel.
var reuse_site: Dictionary = {}
var preview: Dictionary = {}
var preview_key: Array = []
var scope_polygons: Array[PackedVector2Array] = []
var scope_version: Array = []
var observed_phrase := -1
var causal_feedback_count := 0
## A queued self-directed follow-up survives the transient planning panel. It is
## populated from the selected public-preview branch and becomes actionable
## only when a matching charter birth is visible in the presentation world.
var next_action: Dictionary = {}
var next_action_row: HBoxContainer
var next_action_button: Button
var next_combo_button: Button
var next_replan_button: Button
var next_partial_row: HBoxContainer
var next_reservation_button: Button
var next_served_button: Button

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
	comparison_community_choices = HFlowContainer.new()
	comparison_community_choices.add_theme_constant_override("h_separation",6)
	comparison_community_choices.add_theme_constant_override("v_separation",6)
	box.add_child(comparison_community_choices)
	detail = Label.new()
	detail.custom_minimum_size.x = 720
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color",Color("51665c"))
	detail.add_theme_font_size_override("font_size",15)
	box.add_child(detail)
	theme_rework_button = Button.new()
	theme_rework_button.pressed.connect(_take_theme_building)
	box.add_child(theme_rework_button)
	next_action_row = HBoxContainer.new()
	next_action_row.add_theme_constant_override("separation",8)
	next_action_button = Button.new()
	next_action_button.text = "定位落地房屋 · 继续调音"
	next_action_button.tooltip_text = "选中刚落地的房屋，打开已有聚焦与调音入口"
	next_action_button.pressed.connect(_take_next_action)
	next_action_row.add_child(next_action_button)
	next_combo_button = Button.new()
	next_combo_button.text = "沿组合范围继续规划"
	next_combo_button.tooltip_text = "保留真实多社区范围，重新选择章程、变化卡和公共落点"
	next_combo_button.pressed.connect(_continue_combo_planning)
	next_action_row.add_child(next_combo_button)
	next_replan_button = Button.new()
	next_replan_button.text = "重新规划另一片社区"
	next_replan_button.tooltip_text = "回到章程、变化卡和社区范围选择"
	next_replan_button.pressed.connect(_replan_next_action)
	next_action_row.add_child(next_replan_button)
	box.add_child(next_action_row)
	next_partial_row = HBoxContainer.new()
	next_partial_row.add_theme_constant_override("separation",8)
	next_reservation_button = Button.new()
	next_reservation_button.text = "继续规划剩余留地"
	next_reservation_button.pressed.connect(_take_remaining_reservation)
	next_partial_row.add_child(next_reservation_button)
	next_served_button = Button.new()
	next_served_button.text = "定位已服务房屋 · 调音"
	next_served_button.pressed.connect(_take_served_building)
	next_partial_row.add_child(next_served_button)
	box.add_child(next_partial_row)
	actions = HBoxContainer.new()
	confirm = Button.new()
	confirm.text = "确认社区范围 → 摆放锚点"
	confirm.pressed.connect(_confirm_stage)
	actions.add_child(confirm)
	for item in [["暂不建设","none"],["公园 · 留白","park"],["文化馆 · 主题","civic"],["留地 · 呼吸","reserve"]]:
		var button := Button.new()
		button.text = item[0]
		button.toggle_mode = true
		button.set_meta("anchor_kind",item[1])
		button.pressed.connect(choose_anchor.bind(item[1]))
		actions.add_child(button)
	box.add_child(actions)
	transit_anchor_button = Button.new()
	transit_anchor_button.text = "公交 · 连接社区"
	transit_anchor_button.pressed.connect(_choose_transit_anchor)
	box.add_child(transit_anchor_button)
	transit_edit_row = HBoxContainer.new()
	transit_redraw_button = Button.new()
	transit_redraw_button.text = "清空站序 · 重画"
	transit_redraw_button.pressed.connect(func() -> void: demo._redraw_transit_edit())
	transit_edit_row.add_child(transit_redraw_button)
	transit_edit_cancel_button = Button.new()
	transit_edit_cancel_button.text = "取消改站"
	transit_edit_cancel_button.pressed.connect(hide_tool)
	transit_edit_row.add_child(transit_edit_cancel_button)
	box.add_child(transit_edit_row)
	transit_compare_row = HBoxContainer.new()
	for item in [["保留原线","keep"],["改站","edit"]]:
		var button := Button.new()
		button.text = item[0]
		button.toggle_mode = true
		button.pressed.connect(choose_transit_variant.bind(str(item[1])))
		transit_compare_row.add_child(button)
		if item[1] == "keep": transit_keep_button = button
		else: transit_change_button = button
	box.add_child(transit_compare_row)
	hide()

## Read-only entry point for the route UI.  The main Demo owns pointer input
## and route drawing; keeping this adapter here lets the planning guide and
## any future compact card use exactly the same coverage/community contract.
func transit_preview_feedback(payload: Dictionary, settled := false) -> Dictionary:
	if demo == null or demo.model == null or demo.model.world == null: return {}
	var summary := TransitPlanning.coverage_summary(demo.model.world,payload)
	summary["text"] = TransitPlanning.coverage_text(summary,"线路已落定" if settled else "线路预影")
	summary["settled"] = settled
	return summary

func transit_line_feedback(line: Dictionary) -> Dictionary:
	return transit_preview_feedback(line,true)

func transit_feedback_text(payload: Dictionary, settled := false) -> String:
	var summary := transit_preview_feedback(payload,settled)
	return str(summary.get("text",""))

func reset_for_city() -> void:
	composition_public_hint.clear()
	committed_charter_id = ""
	scope.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_polygons.clear()
	scope_version.clear()
	preview_key.clear()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	candidate.clear()
	partial_site.clear()
	reuse_site.clear()
	observed_phrase = demo.shown_world.phrase_index
	opened = demo.model.world.development_charters.is_empty() and not _first_composition_mode()
	causal_feedback_count = 0 if opened else 2
	next_action.clear()
	stage = "charter"
	plan_id = ""
	card_id = ""
	refresh()

func open_tool() -> void:
	composition_public_hint.clear()
	if not demo.transit_charter_context.is_empty() or not demo.transit_edit_context.is_empty(): demo._clear_transit_route()
	committed_charter_id = ""
	partial_site.clear()
	reuse_site.clear()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	demo.menu.hide()
	opened = true
	stage = "charter"
	plan_id = ""
	card_id = ""
	scope.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_version.clear()
	if not ready_sound_community().is_empty(): stage = "feedback"
	refresh()

func ready_sound_community() -> String:
	if not _first_composition_mode() or next_action.get("state","") != "ready" or not bool(next_action.get("first_composition_anchor",false)): return ""
	return str(_first_composition_anchor().get("community_id",""))

func _first_composition_mode() -> bool:
	return bool(demo.get("first_composition_mode"))

## Open the ordinary P planning guide from a real transit station.  The guide
## still goes through the existing charter and change-card steps; when it
## reaches community scope the station's authoritative catchment is already
## selected and remains editable with normal click/Shift-click behavior.
func open_tool_from_transit_station(station: Dictionary) -> void:
	open_tool()
	var record: Dictionary = station.get("record",station)
	for raw_id in record.get("community_ids",[]):
		var id := str(raw_id)
		if id.is_empty() or scope_seed.has(id): continue
		if demo.model.world.communities.has(id): scope_seed.append(id)
	scope_seed.sort()
	var covered: Array = []
	for raw_id in record.get("covered_building_ids",[]):
		var id := str(raw_id)
		if not id.is_empty() and not covered.has(id): covered.append(id)
	scope_source = {"kind":"transit_station","station_id":str(station.get("id",record.get("id",""))),
		"community_ids":scope_seed.duplicate(),"covered_building_ids":covered}
	# Seed is already visible in the eventual scope stage. Keep the transient
	# panel open even when an unusual station has no current catchment, so the
	# player can select a neighboring community manually.
	refresh()

func _apply_scope_seed() -> void:
	if scope_seed.is_empty(): return
	scope = scope_seed.duplicate()
	scope.sort()
	scope_version.clear()

func _scope_source_hint() -> String:
	if scope_source.is_empty(): return ""
	var community_count: int = scope_source.get("community_ids",[]).size()
	var building_count: int = scope_source.get("covered_building_ids",[]).size()
	if str(scope_source.get("kind","")) == "community_combo":
		return "沿上一句真实组合预选范围 · %d个社区\n点击社区可替换，Shift点击继续多选" % community_count
	if str(scope_source.get("kind","")) == "transit_charter":
		return "沿公交章程预选范围 · %d个社区\n点击社区可替换，Shift点击继续多选" % community_count
	return "公交站已预选实际覆盖范围 · %d个社区、%d栋已覆盖房屋\n点击社区可替换，Shift点击继续多选" % [community_count,building_count]

func hide_tool() -> void:
	if stage in ["transit_anchor","transit_edit"]: demo._clear_transit_route()
	committed_charter_id = ""
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	opened = false
	hide()
	candidate.clear()
	partial_site.clear()
	reuse_site.clear()
	demo.queue_redraw()

## Keep every component, courtyard and source revision exactly as authored.
## The demo owns submission; this panel only chooses and compares branches.
func begin_partial_comparison(site: Dictionary,selected_kind: String) -> void:
	committed_charter_id = ""
	reuse_site.clear()
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	preview_key.clear()
	partial_site = site.duplicate(true)
	partial_site["partial"] = true
	partial_site["polygon"] = partial_site.get("polygon",partial_site.get("target_polygon",PackedVector2Array()))
	partial_site["position"] = partial_site.get("position",partial_site.get("target_position",[]))
	partial_site["community_id"] = partial_site.get("community_id",partial_site.get("target_community_id",""))
	partial_site["allowed"] = bool(partial_site.get("allowed",partial_site.get("accepted",true)))
	candidate = partial_site.duplicate(true)
	anchor_kind = selected_kind if selected_kind in ["none","park","civic"] else "park"
	plan_id = ""
	card_id = ""
	scope.clear()
	scope_polygons.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_version.clear()
	stage = "partial_anchor"
	opened = true
	demo.menu.hide()
	refresh()
	demo.queue_redraw()

func begin_public_reuse(site: Dictionary) -> void:
	committed_charter_id = ""
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	preview_key.clear()
	preview.clear()
	partial_site.clear()
	reuse_site = site.duplicate(true)
	candidate = reuse_site.duplicate(true)
	anchor_kind = "none"
	plan_id = ""
	card_id = ""
	scope.clear()
	scope_polygons.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_version.clear()
	stage = "reuse_anchor"
	opened = true
	demo.menu.hide()
	refresh()
	demo.queue_redraw()

func public_reuse_is_current() -> bool:
	if reuse_site.is_empty(): return false
	var current := PublicReuse.candidate(demo.model.world,str(reuse_site.get("public_id","")))
	return bool(current.get("allowed",false)) and str(current.get("source_revision","")) == str(reuse_site.get("source_revision",""))

func begin_transit_edit(source: Dictionary) -> void:
	clear_transit_comparison()
	transit_choice = "edit"
	committed_charter_id = ""
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	preview_key.clear()
	preview.clear()
	partial_site.clear()
	reuse_site.clear()
	candidate.clear()
	plan_id = str(source.get("plan_id",""))
	card_id = ""
	scope.clear()
	scope_polygons.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_version.clear()
	stage = "transit_edit"
	opened = true
	refresh()
	demo.queue_redraw()

func clear_transit_comparison() -> void:
	transit_comparison.clear()
	transit_comparison_key.clear()

func transit_comparison_is_current() -> bool:
	if not opened or stage != "transit_edit" or transit_comparison.is_empty() or not demo._transit_edit_is_current(): return false
	var operation: Dictionary = demo._transit_route_operation({})
	return transit_comparison_key == demo._transit_preview_identity(operation["stop_positions"])

func accept_transit_comparison(payload: Dictionary,request_key: Array) -> bool:
	if not opened or stage != "transit_edit" or not demo._transit_edit_is_current(): return false
	var operation: Dictionary = demo._transit_route_operation({})
	if request_key.is_empty() or request_key != demo._transit_preview_identity(operation["stop_positions"]): return false
	if payload.get("contract","") != "P12-TRANSIT-REWORK-COMPARE/v1": return false
	transit_comparison = payload
	transit_comparison_key = request_key.duplicate(true)
	refresh()
	return true

func choose_transit_variant(choice: String) -> void:
	if stage != "transit_edit" or choice not in ["keep","edit"]: return
	transit_choice = choice
	refresh()
	if demo.preview_requested and transit_comparison_is_current(): demo._play_transit_comparison()

func _confirm_stage() -> void:
	if stage in ["transit_anchor","transit_edit"]: demo._submit_transit_route()
	elif stage == "reuse_anchor": demo._submit_public_reuse()
	else: commit_scope()

func _choose_transit_anchor() -> void:
	if stage == "transit_anchor":
		demo._clear_transit_route()
		stage = "anchor"
		refresh()
		demo.queue_redraw()
		return
	if stage != "anchor" or committed_charter_id.is_empty(): return
	var source := TransitCharter.source(demo.model.world,committed_charter_id)
	if not bool(source.get("accepted",false)):
		demo._message(str(source.get("reason","章程已经变化，请重新选择社区")))
		return
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	candidate.clear()
	preview.clear()
	if demo.preview_requested: demo._cancel_preview_playback()
	demo._begin_charter_transit({"charter_id":committed_charter_id,"plan_id":plan_id,"card_id":card_id,
		"scope_community_ids":source["scope_community_ids"].duplicate()})
	stage = "transit_anchor"
	refresh()
	demo.queue_redraw()

func clear_partial_comparison() -> void:
	if stage != "partial_anchor" and partial_site.is_empty(): return
	if demo.preview_public: demo._cancel_preview_playback()
	partial_site.clear()
	candidate.clear()
	preview.clear()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	preview_key.clear()
	opened = false
	hide()
	demo.queue_redraw()

func choose_plan(id: String) -> void:
	plan_id = id
	drawn_card_ids = PlanningCard.choices(demo.model.world,plan_id)
	if drawn_card_ids.is_empty(): drawn_card_ids = [PlanningCard.DEFAULT_ID]
	card_id = drawn_card_ids[0]
	_rebuild_card_choices()
	stage = "card"
	if scope_source.is_empty(): scope.clear()
	else: _apply_scope_seed()
	scope_version.clear()
	refresh()

func choose_card(id: String) -> void:
	if not PlanningCard.valid(id): return
	if not drawn_card_ids.is_empty() and not drawn_card_ids.has(id): return
	card_id = id
	stage = "scope"
	if scope_source.is_empty(): scope.clear()
	else: _apply_scope_seed()
	scope_version.clear()
	refresh()

func choose_anchor(kind: String) -> void:
	anchor_kind = kind
	preview_key.clear()
	refresh()
	if stage in ["anchor","partial_anchor","reuse_anchor"]: update_candidate(demo.world_at(demo.pointer))
	if demo.preview_requested and not comparison.is_empty(): demo._request_preview()

func refresh() -> void:
	if comparison.is_empty(): _clear_comparison_community()
	cards.visible = stage == "charter"
	card_choices.visible = stage == "card"
	var audible_theme: Dictionary = demo.model.audible_theme()
	charter_theme_key = [str(audible_theme.get("cid","")),audible_theme.get("source_ids",[])]
	var has_theme_house: bool = audible_theme.get("source_ids",[]).any(func(raw_id: Variant) -> bool: return demo.shown_world.by_id.has(str(raw_id)))
	var authored: Dictionary = demo._first_authored_state() if _first_composition_mode() else {}
	if not authored.is_empty(): has_theme_house = bool(authored["theme_eligible"])
	theme_rework_button.visible = stage == "charter" and has_theme_house
	actions.visible = stage != "charter"
	confirm.visible = stage in ["scope","reuse_anchor","transit_anchor","transit_edit"]
	confirm.text = ("确认保留原线" if transit_choice == "keep" else "确认改站 · 下一句") if stage == "transit_edit" else "确认线路 · 下一句" if stage == "transit_anchor" else "确认原位改用" if stage == "reuse_anchor" else "确认社区范围 → 摆放锚点"
	transit_edit_row.visible = stage == "transit_edit"
	transit_compare_row.visible = stage == "transit_edit"
	transit_keep_button.set_pressed_no_signal(transit_choice == "keep")
	transit_change_button.set_pressed_no_signal(transit_choice == "edit")
	transit_anchor_button.visible = stage in ["anchor","transit_anchor"] and (stage == "transit_anchor" or not _first_composition_mode())
	transit_anchor_button.disabled = committed_charter_id.is_empty()
	transit_anchor_button.text = "返回公园 / 文化馆选择" if stage == "transit_anchor" else "公交 · 连接社区"
	next_action_row.visible = opened and stage == "feedback" and next_action.get("state","") == "ready"
	var partial_feedback := next_action_row.visible and (bool(next_action.get("partial",false)) or bool(next_action.get("reuse",false)))
	var combo_ids := _combo_community_ids()
	var transit_feedback := next_action_row.visible and bool(next_action.get("transit_anchor",false))
	var first_sound_feedback := next_action_row.visible and bool(next_action.get("first_composition_anchor",false))
	next_combo_button.visible = next_action_row.visible and (combo_ids.size() > 1 or transit_feedback and not combo_ids.is_empty())
	if next_combo_button.visible:
		next_combo_button.text = "沿%d社区组合继续规划" % combo_ids.size()
		if transit_feedback: next_combo_button.text = "沿%d个章程社区继续规划" % combo_ids.size()
	next_action_button.text = "定位落成公建 · 继续规划" if partial_feedback else "定位落地房屋 · 继续调音"
	if transit_feedback: next_action_button.text = "定位线路站点 · 继续经营"
	if first_sound_feedback:
		next_action_button.text = "选一个声音，沿这个社区继续"
		next_combo_button.hide()
		next_replan_button.hide()
	else: next_replan_button.show()
	next_action_button.tooltip_text = "打开真实落成公共设施的规划入口" if partial_feedback else "选中刚落地的房屋，打开已有聚焦与调音入口"
	if first_sound_feedback: next_action_button.tooltip_text = "在这处实际落成公共空间所属社区，亲自试听与选择声音"
	next_partial_row.visible = partial_feedback
	next_reservation_button.visible = partial_feedback and not next_action.get("remaining_reservation_ids",[]).is_empty()
	next_served_button.visible = partial_feedback and not next_action.get("served_building_ids",[]).is_empty()
	confirm.disabled = not public_reuse_is_current() if stage == "reuse_anchor" else scope.is_empty()
	if stage in ["transit_anchor","transit_edit"]: confirm.disabled = not bool(demo._transit_route_preview().get("accepted",false))
	if stage == "transit_edit" and transit_choice == "keep": confirm.disabled = not demo._transit_edit_is_current()
	if stage == "transit_edit" and transit_choice == "edit" and transit_comparison_is_current(): confirm.disabled = confirm.disabled or not bool(transit_comparison["variants"]["edit"].get("accepted",false))
	for i in range(1,actions.get_child_count()):
		var button: Button = actions.get_child(i)
		button.visible = stage in ["anchor","partial_anchor","reuse_anchor"]
		var button_kind := str(button.get_meta("anchor_kind"))
		button.visible = button.visible and (button_kind != "reserve" or stage == "anchor")
		if button_kind == "none": button.text = "保留当前用途" if stage == "reuse_anchor" else "暂不建设"
		elif button_kind == "reserve":
			button.text = "留地 · 呼吸"
			button.tooltip_text = "下一句普通成长绕开这里；留地本身不新增声部"
		button.set_pressed_no_signal(button.get_meta("anchor_kind") == anchor_kind)
	if stage == "charter":
		heading.text = "你想让这片城市怎样生长？"
		detail.text = "先选倾向，再在地图选社区；公园和文化馆由你摆，房屋沿合法空地自动长。"
		if _first_composition_mode():
			heading.text = "写第一段 · 先选发展章程" if authored.is_empty() else "再写一段 · 选择生长方向"
			detail.text = "选一种生长方向，再点一片社区。公园、文化馆或留地由你安排，随后亲自选一个声音。"
		if not authored.is_empty() and bool(authored["theme_eligible"]):
			theme_rework_button.text = "改写"+str(authored["community_name"])+" · 你种下的"+str(demo.PlayerExpression.definition(str(authored["expression"]))["label"])
			detail.text += "\n你的社区已有主题；回到亲自种下的房屋，改一个音。"
		elif not audible_theme.is_empty():
			var theme_cid := str(audible_theme.get("cid",""))
			var theme_name := str(demo.shown_world.communities.get(theme_cid,{}).get("name","当前社区"))
			theme_rework_button.text = "改编"+theme_name+"主题 · 自己选一个音"
			detail.text += "\n"+theme_name+"已有主题；可以先改一个音，也可继续安排公共空间。"
		var source_hint := _scope_source_hint()
		if not source_hint.is_empty(): detail.text += "\n"+source_hint+"；选完章程和变化卡后会带入社区范围。"
	elif stage == "card":
		heading.text = str(Charter.PLANS[plan_id]["title"]) + " · 选一张章首变化卡"
		detail.text = "变化卡只影响已有规划关系的候选优先级或生长时机，持续几句后自然退场；不会增加全城活力，也不会锁住公共设施。\n当前默认 · " + str(PlanningCard.CARDS[card_id]["title"]) + "（可直接点地图继续，也可改选下面任意一张）"
		var source_hint := _scope_source_hint()
		if not source_hint.is_empty(): detail.text += "\n"+source_hint
	elif stage == "scope":
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · 选择社区范围"
		var names: Array[String] = []
		for cid in scope: names.append(str(demo.model.world.communities[cid]["name"]))
		var summary := Charter.scope_preview(demo.model.world,scope)
		var source_hint := _scope_source_hint()
		detail.text = ""
		if not source_hint.is_empty(): detail.text = source_hint+"\n"
		detail.text += ("点击地图选择一个社区；Shift点击可选多个。\n" if scope.is_empty() else "范围 · "+ "、".join(names)+"\n")
		detail.text += "%d栋现有房屋 · %d块合法空置地块 · 不改房屋音级，不封锁其他用途" % [summary["houses"],summary["legal_lots"]]
		if _first_composition_mode() and demo.shown_world.by_id.has(str(demo.composition_source_id)):
			var source_cid := str(demo.shown_world.by_id[demo.composition_source_id]["community_id"])
			var bank := int(demo.shown_world.communities[source_cid]["bank"])
			var opposite: Array[String] = []
			for cid: String in demo.shown_world.communities:
				if int(demo.shown_world.communities[cid]["bank"]) != bank and not demo.shown_world.communities[cid]["members"].is_empty(): opposite.append(str(demo.shown_world.communities[cid]["name"]))
			if not opposite.is_empty(): detail.text += "\n试试对岸的"+"、".join(opposite)+"，给它另一种声音；仍可自由选择街坊。"
	elif stage == "feedback":
		heading.text = "你的选择已经落地 · 现在轮到你"
		detail.text = _next_action_detail()
	elif stage == "partial_anchor":
		heading.text = "这一片由你安排 · "+str({"park":"公园","civic":"文化馆","reserve":"留地","none":"暂不兑现"}.get(anchor_kind,"公共规划"))
		_update_partial_detail()
	elif stage == "reuse_anchor":
		heading.text = "原位改用 · "+str({"park":"公园","civic":"文化馆","reserve":"留地","none":"保留当前用途"}.get(anchor_kind,"公共规划"))
		_update_reuse_detail()
	elif stage == "transit_anchor":
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · 公交连接社区"
		_update_transit_detail()
	elif stage == "transit_edit":
		heading.text = "改站 · "+str(demo.transit_edit_context.get("line_name","作者线路"))
		_update_transit_edit_detail()
	else:
		heading.text = str(Charter.PLANS[plan_id]["title"])+" · "+{"park":"摆放公园","civic":"摆放文化馆","reserve":"留下呼吸","none":"暂不建设"}[anchor_kind]
		detail.text = "移动到所选社区的空置地块或公共候选地。\n按住空格比较不建、留地、公园、文化馆；选择一种后点击地图确认。"
		if not composition_public_hint.is_empty(): detail.text += "\n地图标出一处公建落点，给河岸街段留出第二个声音；也可自由安排。"
		detail.text += "\n不建会保留章程与正常成长；留地才会让下一句绕开这里，暂时不新增声音。"
		if not _first_composition_mode(): detail.text += "\n也可选择公交锚点，沿真实道路连接这些社区。"
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
	if stage in ["transit_anchor","transit_edit"]: return true
	if stage == "reuse_anchor":
		if Planning.point_in_footprint(reuse_site,p): demo._submit_public_reuse()
		return true
	if stage == "partial_anchor": return true
	if stage == "charter": return true
	if stage == "feedback": return true
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
		var none_variant: Dictionary = {}
		if comparison.has("variants") and comparison["variants"] is Dictionary:
			none_variant = comparison["variants"].get("none",{})
		if none_variant.is_empty(): none_variant = {"accepted":true,"choice":"none","opportunity_preview":{}}
		_queue_next_action(none_variant)
		demo.model.cancel_planning()
		demo._message("这里暂不建设 · 章程保留，普通成长照常继续")
		_close_after_commit()
		return true
	if anchor_kind != "reserve" and not bool(preview.get("access",false)):
		demo._message("这片公共空间没有能接入道路的真实入口")
		return true
	var result: Dictionary = demo.model.submit({"kind":anchor_kind,"position":candidate["position"].duplicate()})
	if bool(result["accepted"]):
		var selected_variant: Dictionary = {}
		if comparison.has("variants") and comparison["variants"] is Dictionary:
			selected_variant = comparison["variants"].get(anchor_kind,{})
		_queue_next_action(selected_variant)
		if _first_composition_mode(): _queue_first_composition_anchor(result)
		demo.ripple_position = p
		demo.ripple_seconds = 0.6
		var choice_message: String = str({"reserve":"留地让下一句绕开这里，保留一处无声空间","park":"公园为主题留白","civic":"文化馆按道路与容量支持主题"}.get(anchor_kind,"公共规划"))
		demo._message("规划已排入下一乐句 · "+str(choice_message)+"；点击房屋可查看实际声部与下一步")
		_close_after_commit()
	else: demo._message(str(result["reason"]))
	return true

## Build the stable UI-side contract from a public-preview branch. World code
## may add richer fields later; these fields remain sufficient to route the
## player to a real community/building without inventing a new action type.
static func next_action_from_variant(variant: Dictionary,candidate: Dictionary) -> Dictionary:
	var raw_preview: Variant = variant.get("opportunity_preview",{})
	var preview: Dictionary = raw_preview if raw_preview is Dictionary else {}
	var action: Dictionary = NextAction.from_preview(preview,str(preview.get("choice",variant.get("choice",""))))
	var owner := str(candidate.get("community_id",action.get("community_id","")))
	if not owner.is_empty():
		action["community_id"] = owner
	var ids: Array = action.get("affected_communities",[])
	if ids.is_empty() and not owner.is_empty(): action["affected_communities"] = [owner]
	action["state"] = "queued"
	action["building_id"] = ""
	return action

func _queue_next_action(variant: Dictionary) -> void:
	var data: Dictionary = {}
	if not comparison.is_empty() and comparison.has("variants"):
		data = NextAction.from_comparison(comparison,anchor_kind,comparison_community_id)
	else:
		data = next_action_from_variant(variant,candidate)
	if data.get("community_id","") == "" and candidate.has("community_id"): data["community_id"] = str(candidate["community_id"])
	if data.get("affected_communities",[]).is_empty() and data.get("community_id","") != "": data["affected_communities"] = [data["community_id"]]
	# Keep the live commit identity beside the read-only preview token.  The
	# preview branch has its own world copy; action_serial is the small stable
	# piece that lets us reject another operation queued after this choice while
	# still allowing the expected phrase boundary to advance phrase_index.
	data["queued_world_version"] = Charter.version(demo.model.world)
	data["plan_id"] = plan_id
	data["expected_boundary_frame"] = int(data.get("boundary_frame",demo.model.next_boundary))
	data["scope"] = scope.duplicate()
	data["state"] = "queued"
	next_action = data

func _queue_first_composition_anchor(result: Dictionary) -> void:
	next_action["first_composition_anchor"] = true
	next_action["choice"] = anchor_kind
	next_action["event_id"] = int(result["event_id"])
	next_action["expected_boundary_frame"] = int(result["frame"])
	var public_id := str(candidate.get("public_id",""))
	if public_id.is_empty() and anchor_kind == "reserve": public_id = "reservation-%05d" % int(result["event_id"])
	next_action["public_id"] = public_id if not public_id.is_empty() else "player-"+anchor_kind+"-%05d" % int(result["event_id"])
	next_action["community_id"] = str(candidate["community_id"])

func queue_partial_action(site: Dictionary,result: Dictionary) -> void:
	if not bool(result.get("accepted",false)): return
	anchor_kind = str(site.get("kind",anchor_kind))
	if anchor_kind == "none":
		clear_partial_comparison()
		return
	if stage != "partial_anchor" or str(partial_site.get("source_reservation_id","")) != str(site.get("source_reservation_id","")):
		comparison.clear()
		comparison_key.clear()
	candidate = site.duplicate(true)
	candidate["community_id"] = site.get("community_id",site.get("target_community_id",""))
	_queue_next_action({})
	next_action["partial"] = true
	next_action["plan_id"] = ""
	next_action["choice"] = anchor_kind
	next_action["source_reservation_id"] = str(site.get("source_reservation_id",site.get("reservation_id","")))
	next_action["source_revision"] = str(site.get("source_revision",""))
	next_action["event_id"] = int(result.get("event_id",-1))
	next_action["expected_boundary_frame"] = int(result.get("frame",demo.model.next_boundary))
	next_action["community_id"] = str(site.get("community_id",site.get("target_community_id",next_action.get("community_id",""))))
	var affected: Array = next_action.get("affected_communities",[])
	for cid in site.get("target_community_ids",[]):
		if not affected.has(str(cid)): affected.append(str(cid))
	if affected.is_empty() and not str(next_action["community_id"]).is_empty(): affected.append(str(next_action["community_id"]))
	next_action["affected_communities"] = affected
	_close_after_commit()

func queue_public_reuse_action(site: Dictionary,result: Dictionary) -> void:
	if not bool(result.get("accepted",false)): return
	candidate = site.duplicate(true)
	_queue_next_action({})
	next_action["reuse"] = true
	next_action["plan_id"] = ""
	next_action["choice"] = anchor_kind
	next_action["public_id"] = str(site["public_id"])
	next_action["source_revision"] = str(site["source_revision"])
	next_action["event_id"] = int(result.get("event_id",-1))
	next_action["expected_boundary_frame"] = int(result.get("frame",demo.model.next_boundary))
	_close_after_commit()

func queue_transit_anchor_action(preview: Dictionary,result: Dictionary,context: Dictionary) -> void:
	var anchor: Dictionary = preview.get("charter_anchor",{})
	next_action = {"contract":NextAction.CONTRACT,"state":"queued","transit_anchor":true,"choice":"transit_line",
		"charter_id":str(context["charter_id"]),"plan_id":str(context.get("plan_id","")),"card_id":str(context.get("card_id","")),
		"scope":anchor.get("scope_community_ids",context.get("scope_community_ids",[])).duplicate(),
		"covered_scope_community_ids":anchor.get("covered_scope_community_ids",[]).duplicate(),
		"uncovered_scope_community_ids":anchor.get("uncovered_scope_community_ids",[]).duplicate(),
		"event_id":int(result["event_id"]),"expected_boundary_frame":int(result["frame"]),
		"queued_world_version":Charter.version(demo.model.world),"building_id":""}
	_close_after_commit()
	committed_charter_id = ""

func queue_transit_edit_action(preview: Dictionary,result: Dictionary,context: Dictionary) -> void:
	next_action = {"contract":NextAction.CONTRACT,"state":"queued","transit_anchor":true,"transit_edit":true,"choice":"transit_line",
		"edit_id":str(context["id"]),"source_revision":str(context["source_revision"]),
		"charter_id":str(context.get("charter_id","")),"plan_id":str(context.get("plan_id","")),
		"scope":context.get("scope_community_ids",[]).duplicate(),"scope_community_ids":context.get("scope_community_ids",[]).duplicate(),
		"event_id":int(result["event_id"]),"expected_boundary_frame":int(result["frame"]),"building_id":""}
	for key: String in ["added_covered_building_ids","removed_covered_building_ids","added_community_ids","removed_community_ids"]:
		next_action[key] = preview.get(key,[]).duplicate()
	_close_after_commit()
	committed_charter_id = ""

func _close_after_commit() -> void:
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	_clear_comparison_community()
	partial_site.clear()
	reuse_site.clear()
	candidate.clear()
	opened = false
	hide()
	demo.queue_redraw()

func _next_action_event_matches(event: Dictionary) -> bool:
	if next_action.get("state","") != "queued": return false
	var event_kind := str(event.get("kind",""))
	if bool(next_action.get("first_composition_anchor",false)):
		return event_kind == str(next_action["choice"]) and str(event.get("id","")) == str(next_action["public_id"]) and int(event.get("frame",-1)) == int(next_action["expected_boundary_frame"])
	if bool(next_action.get("transit_edit",false)):
		return event_kind == "transit_line" and bool(event.get("edit",false)) and str(event.get("id","")) == str(next_action["edit_id"]) \
			and int(event.get("event_id",-2)) == int(next_action["event_id"]) \
			and int(event.get("frame",-1)) == int(next_action["expected_boundary_frame"])
	if bool(next_action.get("transit_anchor",false)):
		return event_kind == "transit_line" and not bool(event.get("edit",false)) and str(event.get("charter_id","")) == str(next_action.get("charter_id","")) \
			and int(event.get("event_id",-2)) == int(next_action.get("event_id",-1)) \
			and int(event.get("frame",-1)) == int(next_action.get("expected_boundary_frame",-2))
	if bool(next_action.get("reuse",false)):
		return event_kind == str(next_action.get("choice","")) and bool(event.get("reuse",false)) \
			and str(event.get("id","")) == str(next_action.get("public_id","")) \
			and str(event.get("source_revision","")) == str(next_action.get("source_revision","")) \
			and int(event.get("event_id",-2)) == int(next_action.get("event_id",-1)) \
			and int(event.get("frame",-1)) == int(next_action.get("expected_boundary_frame",-2))
	if bool(next_action.get("partial",false)):
		if event_kind != str(next_action.get("choice","")) or not bool(event.get("partial",false)): return false
		if str(event.get("source_reservation_id","")) != str(next_action.get("source_reservation_id","")): return false
		var source_revision := str(next_action.get("source_revision",""))
		if not source_revision.is_empty() and str(event.get("source_revision","")) != source_revision: return false
		var event_id := int(next_action.get("event_id",-1))
		if event_id >= 0 and int(event.get("event_id",-2)) != event_id: return false
		return int(event.get("frame",-1)) == int(next_action.get("expected_boundary_frame",-2))
	# A public anchor can be the only structural change at its boundary.  The
	# old follow-up contract listened only for a birth, leaving a valid park or
	# civic choice queued forever when no house happened to grow in that phrase.
	# The event is authoritative: it is emitted by the same WorldDelta that
	# accepted the previewed facility choice.
	if event_kind in ["park","civic"]:
		if str(next_action.get("choice","")) != event_kind: return false
		var expected_public_frame := int(next_action.get("expected_boundary_frame",next_action.get("boundary_frame",-1)))
		return expected_public_frame < 0 or int(event.get("frame",-1)) == expected_public_frame
	if event_kind != "birth": return false
	if not event.has("plan_id") or not event.has("district_id"): return false
	if not str(next_action.get("plan_id","")).is_empty() and str(event.get("plan_id","")) != str(next_action["plan_id"]): return false
	var expected_frame := int(next_action.get("expected_boundary_frame",next_action.get("boundary_frame",-1)))
	if expected_frame >= 0 and int(event.get("frame",-1)) != expected_frame: return false
	if demo.shown_world == null or not demo.shown_world.by_id.has(str(event["district_id"])): return false
	var cid := str(demo.shown_world.by_id[str(event["district_id"])].get("community_id",""))
	var ids: Array = next_action.get("affected_communities",[])
	if ids.is_empty() or ids.has(cid): return true
	# A community may have split since the preview.  Treat a descendant as part
	# of its planned parent scope, while still rejecting unrelated districts.
	for owner in ids:
		if Charter.in_scope(demo.shown_world,cid,[str(owner)]): return true
	return false

func _expire_next_action_if_stale() -> void:
	if next_action.get("state","") != "queued" or demo.shown_world == null: return
	if bool(next_action.get("first_composition_anchor",false)):
		for pending in demo.model.world.pending_actions:
			if str(pending.get("kind","")) == str(next_action["choice"]) and int(pending.get("event_id",-2)) == int(next_action["event_id"]) and int(pending.get("frame",-1)) == int(next_action["expected_boundary_frame"]): return
		for event in demo.model.world.events:
			if _next_action_event_matches(event): return
			if str(event.get("kind","")) == "planning_rejected" and int(event.get("event_id",-2)) == int(next_action["event_id"]) and int(event.get("frame",-1)) == int(next_action["expected_boundary_frame"]): return
		next_action["state"] = "expired"
		next_action["reason"] = "这处公共锚点已撤回或换了位置；按P重新选择。"
		return
	if bool(next_action.get("transit_anchor",false)):
		# Independent authoring changes action_serial without cancelling a line.
		# Rendering can also settle it before the device reaches its boundary.
		for pending in demo.model.world.pending_actions:
			var source_matches := str(pending.get("edit_id","")) == str(next_action["edit_id"]) if bool(next_action.get("transit_edit",false)) else str(pending.get("charter_id","")) == str(next_action["charter_id"]) and str(pending.get("edit_id","")).is_empty()
			if str(pending.get("kind","")) == "transit_line" and source_matches and int(pending.get("event_id",-2)) == int(next_action["event_id"]) and int(pending.get("frame",-1)) == int(next_action["expected_boundary_frame"]): return
		for event in demo.model.world.events:
			if _next_action_event_matches(event): return
			if str(event.get("kind","")) == "planning_rejected" and str(event.get("operation_kind","")) == "transit_line" and int(event.get("event_id",-2)) == int(next_action["event_id"]) and int(event.get("frame",-1)) == int(next_action["expected_boundary_frame"]): return
		next_action["state"] = "expired"
		next_action["reason"] = "这次改站已被撤回或替换，请重新打开原线路" if bool(next_action.get("transit_edit",false)) else "这条待播线路已被撤回或替换，请重新选择公交锚点"
		stage = "feedback"
		opened = true
		visible = not demo.black
		refresh()
		return
	var queued: Array = next_action.get("queued_world_version",[])
	var current := Charter.version(demo.model.world)
	# action_serial changes for every accepted operation.  A later operation
	# means this follow-up no longer identifies the same planning transaction.
	if queued.size() >= 2 and current.size() >= 2 and int(queued[1]) != int(current[1]):
		next_action["state"] = "expired"
		next_action["reason"] = "城市已经排入另一项操作，这条规划提示已过期"
		stage = "feedback"
		opened = true
		visible = not demo.black
		refresh()
		return
	var boundary := int(next_action.get("expected_boundary_frame",next_action.get("boundary_frame",-1)))
	var phrase_frames := int(demo.shown_world.cfg["timing"]["phrase_frames"])
	var now_frame: int = int(demo.shown_world.phrase_index)*phrase_frames
	if boundary >= 0 and now_frame > boundary:
		next_action["state"] = "expired"
		next_action["reason"] = "规划边界已经过去，未兑现的提示已清除"
		stage = "feedback"
		opened = true
		visible = not demo.black
		refresh()

func _activate_next_action(event: Dictionary) -> void:
	if bool(next_action.get("first_composition_anchor",false)):
		_activate_first_composition_anchor(event)
		return
	if bool(next_action.get("transit_anchor",false)):
		_activate_transit_next_action(event)
		return
	if bool(next_action.get("partial",false)) or bool(next_action.get("reuse",false)):
		_activate_partial_next_action(event)
		return
	var id := str(event.get("district_id",""))
	if demo.shown_world != null and not demo.shown_world.by_id.has(id): id = ""
	if id.is_empty():
		var target := str(next_action.get("community_id",next_action.get("target",{}).get("community_id","") if next_action.get("target",{}) is Dictionary else ""))
		if demo.shown_world != null:
			for building in demo.shown_world.buildings:
				if target.is_empty() or str(building.get("community_id","")) == target:
					id = str(building.get("district_id",""))
					break
	var cid := str(next_action.get("community_id",""))
	if not id.is_empty() and demo.shown_world != null and demo.shown_world.by_id.has(id):
		cid = str(demo.shown_world.by_id[id].get("community_id",cid))
	var local_target := NextAction.community_target(next_action,cid)
	if not local_target.is_empty():
		next_action["target"] = local_target.duplicate(true)
		next_action["roles"] = local_target.get("roles",{}).duplicate(true)
		next_action["qualification"] = local_target.get("qualification",{}).duplicate(true)
		next_action["role"] = local_target.get("role","")
		next_action["role_id"] = local_target.get("role_id","")
		next_action["anchor_id"] = local_target.get("anchor_id","")
		next_action["anchor_ids"] = local_target.get("anchor_ids",[]).duplicate()
	next_action["state"] = "ready"
	next_action["building_id"] = id
	next_action["community_id"] = cid
	stage = "feedback"
	opened = true
	visible = not demo.black
	refresh()
	demo._message("规划结果已经落地 · 下一次行动由你选择")

func _first_composition_anchor() -> Dictionary:
	if str(next_action.get("choice","")) == "reserve":
		for reservation: Dictionary in demo.shown_world.planning_reservations:
			if str(reservation.get("reservation_id",reservation.get("id",""))) != str(next_action.get("public_id","")): continue
			var kept := reservation.duplicate(true)
			kept["community_id"] = str(next_action.get("community_id",""))
			return kept
	for site: Dictionary in demo.shown_world.public_sites:
		if str(site["id"]) == str(next_action.get("public_id","")) and bool(site.get("active",false)) and str(site["kind"]) == str(next_action.get("choice","")) and int(site.get("frame",-1)) == int(next_action.get("expected_boundary_frame",-2)):
			return site
	return {}

func _activate_first_composition_anchor(_event: Dictionary) -> void:
	var site := _first_composition_anchor()
	if site.is_empty(): return
	next_action["state"] = "ready"
	next_action["community_id"] = str(site["community_id"])
	next_action["anchor_position"] = site["position"].duplicate()
	stage = "feedback"
	opened = true
	refresh()
	demo._message("你留下的空间已保留 · 选一个声音，沿这个社区继续" if str(next_action.get("choice","")) == "reserve" else "你放的公共空间已落成 · 选一个声音，沿这个社区继续")

func _activate_transit_next_action(event: Dictionary) -> void:
	var line_id := str(event.get("id",event.get("line_id","")))
	for line in demo.shown_world.transit_lines:
		if str(line.get("id","")) != line_id: continue
		var stops: Array[String] = []
		for raw_id in line.get("stops",[]):
			var id := str(raw_id)
			if not demo.shown_world.transit_stop_record(id).is_empty(): stops.append(id)
		if stops.is_empty(): return
		next_action["state"] = "ready"
		next_action["line_id"] = line_id
		next_action["line_name"] = str(line.get("name","公交线路"))
		next_action["stop_ids"] = stops
		next_action["covered_building_ids"] = event.get("covered_building_ids",[]).duplicate()
		var anchor: Dictionary
		if bool(next_action.get("transit_edit",false)):
			var current := TransitRework.candidate(demo.shown_world,line_id)
			var route := TransitPlanning.preview(demo.shown_world,current.get("stop_positions",[]))
			next_action["covered_building_ids"] = route.get("covered_building_ids",[]).duplicate()
			anchor = TransitCharter.settled_coverage(demo.shown_world,route,next_action)
		else: anchor = TransitCharter.preview(demo.shown_world,event,str(next_action["charter_id"]))
		for key: String in ["scope_community_ids","covered_scope_community_ids","uncovered_scope_community_ids","scope_covered_building_ids"]:
			if anchor.has(key): next_action[key] = anchor[key].duplicate()
		stage = "feedback"
		opened = true
		refresh()
		demo._message("公交锚点已经落定 · 定位真实站点，或沿章程范围继续规划")
		return

func _activate_partial_next_action(event: Dictionary) -> void:
	var facility_id := str(event.get("id",""))
	var site := _partial_public_site(facility_id)
	if site.is_empty(): return
	var remaining_ids: Array[String] = []
	for raw_id in event.get("remaining_reservation_ids",[]):
		var reservation := _remaining_reservation(str(raw_id),facility_id)
		if not reservation.is_empty(): remaining_ids.append(str(raw_id))
	var served_ids: Array[String] = []
	for raw_id in site.get("served",[]):
		if demo.shown_world.by_id.has(str(raw_id)): served_ids.append(str(raw_id))
	served_ids.sort()
	var cid := str(site.get("community_id",next_action.get("community_id","")))
	var local_target := NextAction.community_target(next_action,cid)
	if not local_target.is_empty():
		next_action["target"] = local_target.duplicate(true)
		next_action["roles"] = local_target.get("roles",{}).duplicate(true)
	next_action["state"] = "ready"
	next_action["public_id"] = facility_id
	next_action["community_id"] = cid
	next_action["remaining_reservation_ids"] = remaining_ids
	next_action["served_building_ids"] = served_ids
	next_action["building_id"] = ""
	stage = "feedback"
	opened = true
	refresh()
	demo._message("公共空间已经原位改用 · 可继续比较用途或查看实际服务" if bool(next_action.get("reuse",false)) else "局部公共空间已经落成 · 继续规划余地，或查看实际服务")

func _partial_public_site(id: String) -> Dictionary:
	if demo.shown_world == null: return {}
	for site in demo.shown_world.public_sites:
		if str(site.get("id","")) == id and bool(site.get("active",false)): return site
	return {}

func _remaining_reservation(id: String,facility_id: String) -> Dictionary:
	if demo.shown_world == null: return {}
	for reservation in demo.shown_world.planning_reservations:
		if str(reservation.get("reservation_id",reservation.get("id",""))) == id and str(reservation.get("converted_by","")) == facility_id: return reservation
	return {}

func _next_action_detail() -> String:
	if next_action.get("state","") == "expired":
		return str(next_action.get("reason","上一项规划提示已过期"))+"；按P重新规划另一片社区。"
	var choice: String = str({"park":"公园","civic":"文化馆","reserve":"留地 · 呼吸","none":"暂不建设"}.get(str(next_action.get("choice","")),"公共规划"))
	var combo_hint := ""
	var raw_combo: Variant = next_action.get("community_combo",{})
	if raw_combo is Dictionary and int(raw_combo.get("count",0)) > 1:
		combo_hint = str(raw_combo.get("message",raw_combo.get("next","")))
	var community_name: String = str(next_action.get("community_id",""))
	if demo != null and demo.shown_world != null:
		community_name = str(demo.shown_world.communities.get(str(next_action.get("community_id","")),{}).get("name",community_name))
	if bool(next_action.get("first_composition_anchor",false)):
		return "%s · %s · %s\n选择低音、协和或节奏方向，试听后由你决定。房屋会沿真实章程与锚点继续生长。" % [choice,community_name,"已保留" if str(next_action.get("choice","")) == "reserve" else "已落成"]
	if bool(next_action.get("transit_anchor",false)):
		var covered := "、".join(demo._transit_community_names(next_action.get("covered_scope_community_ids",[])))
		var missed := "、".join(demo._transit_community_names(next_action.get("uncovered_scope_community_ids",[])))
		if bool(next_action.get("transit_edit",false)):
			var lines: Array[String] = ["%s · 已更新原线路\n当前实际覆盖%d栋房屋 · 线路身份与在途车辆保留" % [next_action.get("line_name","作者线路"),next_action.get("covered_building_ids",[]).size()]]
			if not str(next_action.get("charter_id","")).is_empty():
				lines.append("原章程范围 · "+covered+" · %d栋房屋" % next_action.get("scope_covered_building_ids",[]).size())
				lines.append("尚未覆盖 · "+missed if not missed.is_empty() else "原章程社区已全部接入")
			lines.append("实际客流达到脉冲条件才带来声音；定位真实站点可继续改站经营。")
			return "\n".join(lines)
		return "%s · 已沿章程落定\n实际覆盖 · %s · %d栋房屋\n%s\n实际客流达到脉冲条件才带来声音；可定位站点继续组合，或沿章程社区安排下一步。" % [next_action.get("line_name","公交线路"),covered if not covered.is_empty() else "暂无",next_action.get("scope_covered_building_ids",[]).size(),"尚未覆盖 · "+missed if not missed.is_empty() else "所选社区已全部接入"]
	if bool(next_action.get("reuse",false)):
		var lines: Array[String] = ["%s · %s · 已原位改用" % [choice,community_name],"原占地、内院与设施身份保留；可再次比较用途。"]
		if str(next_action.get("choice","")) == "civic": lines.append("当前实际服务%d栋房屋；可定位其中一栋继续调音。" % next_action.get("served_building_ids",[]).size())
		lines.append("定位公建继续经营；文化馆仍可扩容，移动位置使用搬迁。")
		return "\n".join(lines)
	if bool(next_action.get("partial",false)):
		var remaining_count: int = next_action.get("remaining_reservation_ids",[]).size()
		var served_count: int = next_action.get("served_building_ids",[]).size()
		var partial_lines: Array[String] = ["%s · %s · 已落成" % [choice,community_name],
			"画好的范围已经落成，保留%d片留地可继续组合。" % remaining_count]
		if str(next_action.get("choice","")) == "civic": partial_lines.append("当前服务%d栋房屋；可定位其中一栋继续调音。" % served_count)
		var partial_roles: Dictionary = next_action.get("roles",{})
		for role in ["theme","commercial","bass","response"]:
			var row: Dictionary = partial_roles.get(role,{})
			if not str(row.get("next","")).is_empty():
				partial_lines.append("下一步 · "+str(row["next"]).replace("\n","；"))
				break
		if not combo_hint.is_empty(): partial_lines.append("组合机会 · "+combo_hint)
		partial_lines.append("定位文化馆可搬迁或扩容；剩余留地可再兑现。" if str(next_action.get("choice","")) == "civic" else "定位公园可继续搬迁；剩余留地可再兑现。")
		return "\n".join(partial_lines)
	var hint := "点击下方定位落地房屋，进入已有调音、独听与聚焦入口。"
	var roles: Variant = next_action.get("roles",{})
	if roles is Dictionary:
		for role in ["theme","commercial","bass","response"]:
			var row: Dictionary = roles.get(role,{})
			if not row.is_empty() and not str(row.get("next","")).is_empty():
				hint = str(row["next"]).replace("\n","；")+"\n点击下方定位这片社区，继续由你决定。"
				break
	var lines: Array[String] = ["%s · %s" % [choice,community_name],hint]
	if not combo_hint.is_empty(): lines.append("组合机会 · "+combo_hint)
	lines.append("规划影响已经兑现，下一步可以改一栋的音、聚焦主题或重新规划另一片社区。")
	return "\n".join(lines)

func _combo_community_ids() -> Array[String]:
	var raw: Variant = {"community_ids":next_action.get("scope_community_ids",next_action.get("scope",[]))} if bool(next_action.get("transit_anchor",false)) else next_action.get("community_combo",{})
	if not raw is Dictionary: return []
	var result: Array[String] = []
	for item in raw.get("community_ids",[]):
		var cid := str(item)
		if not cid.is_empty() and demo.model.world.communities.has(cid) and not result.has(cid): result.append(cid)
	return result

## Reopen the normal planning flow with the real multi-community combo as its
## editable scope.  This only seeds the next choice; it does not submit a
## charter, add a voice, or turn an ephemeral relation into saved state.
func _continue_combo_planning() -> void:
	if next_action.get("state","") != "ready": return
	var ids := _combo_community_ids()
	var transit := bool(next_action.get("transit_anchor",false))
	if ids.is_empty() or not transit and ids.size() < 2: return
	next_action["state"] = "consumed"
	open_tool()
	scope_seed = ids.duplicate()
	scope_seed.sort()
	scope_source = {"kind":"transit_charter" if transit else "community_combo","community_ids":scope_seed.duplicate()}
	_apply_scope_seed()
	demo._message("沿真实社区组合继续规划 · 可删减或加入社区，再选择下一片公共落点")
	refresh()

func _take_theme_building() -> void:
	if _first_composition_mode() and not demo._first_authored_state().is_empty():
		demo._begin_first_authored_theme()
		return
	var theme: Dictionary = demo.model.audible_theme()
	var sources: Array = theme.get("source_ids",[])
	var id := ""
	for raw_id in sources:
		if demo.shown_world.by_id.has(str(raw_id)):
			id = str(raw_id)
			break
	if id.is_empty(): return
	# Prefer a real source that will sing after the next writable beat. This
	# locates a house; its pitch and listening controls remain the player's choice.
	var start: int = (demo.model.rendered_until/demo.model.beat_frames+1)*demo.model.beat_frames
	var first_onset := int(demo.model.next_boundary)
	for node in demo.model.synth.musical_nodes.values():
		if bool(node["answer"]) or not bool(node.get("active",false)) or str(node["pattern"]["cid"]) != str(theme.get("cid","")): continue
		for event in demo.model.synth.musical_events(node,start,maxi(0,first_onset-start),int(demo.model.world.cfg["timing"]["sample_rate"])):
			var source_id := str(event["source_id"])
			if int(event["onset"]) < start or int(event["onset"]) >= first_onset or not sources.has(source_id) or not demo.shown_world.by_id.has(source_id): continue
			id = source_id
			first_onset = int(event["onset"])
	hide_tool()
	demo.selected_id = id
	demo.context = {"kind":"retune","id":id}
	_focus_planning_position(demo.shown_world.by_id[id]["position"])
	demo._show_context_menu()
	demo.queue_redraw()

func _take_next_action() -> void:
	if next_action.get("state","") != "ready": return
	if bool(next_action.get("first_composition_anchor",false)):
		var site := _first_composition_anchor()
		if site.is_empty():
			next_action["state"] = "expired"
			hide_tool()
			return
		var raw: Array = site["position"]
		var cid := str(site["community_id"])
		if bool(demo._begin_first_sound_choice(cid,Vector2(float(raw[0]),float(raw[1])))):
			next_action["state"] = "consumed"
		else:
			opened = true
			refresh()
		return
	if bool(next_action.get("transit_anchor",false)):
		_take_transit_anchor_station()
		return
	if bool(next_action.get("partial",false)) or bool(next_action.get("reuse",false)):
		_take_partial_public()
		return
	var id := str(next_action.get("building_id",""))
	if demo.shown_world == null or id.is_empty() or not demo.shown_world.by_id.has(id):
		demo._message("落地房屋已离开当前画面；点击另一栋房屋继续调音")
		hide_tool()
		return
	demo.selected_id = id
	demo.context = {"kind":"retune","id":id}
	# Existing focus verb supplies camera movement and a one-shot focus event;
	# opening the context menu afterwards keeps the real note/solo/mute controls.
	demo._verb("focus")
	demo._show_context_menu()
	next_action["state"] = "consumed"
	next_action_row.visible = false
	opened = false
	hide()

func _take_transit_anchor_station() -> void:
	for line in demo.shown_world.transit_lines:
		if str(line.get("id","")) != str(next_action.get("line_id","")): continue
		for raw_id in next_action.get("stop_ids",[]):
			var id := str(raw_id)
			if not line.get("stops",[]).has(id): continue
			var record: Dictionary = demo.shown_world.transit_stop_record(id)
			if record.is_empty(): continue
			_focus_planning_position(record["position"])
			demo.selected_id = ""
			demo.transit_station_focus_id = id
			demo.context = {"kind":"transit_station","id":id}
			var line_ids: Array = demo._transit_line_ids_at_stop(id,demo.shown_world)
			demo.menu_info.text = demo._transit_station_context_text({"id":id,"record":record,"line_ids":line_ids,"line_names":demo._transit_line_names(line_ids,demo.shown_world)})
			demo._show_context_menu()
			_consume_partial_action()
			return
	demo._message("这条线路的站点已经变化，请在地图选择当前站点")
	hide_tool()

func _focus_planning_position(raw: Array) -> void:
	if raw.size() != 2: return
	var p := Vector2(float(raw[0]),float(raw[1]))-Vector2(16,16)
	demo.zoom_target = 1.65
	demo.pan_target = -Vector2((p.x-p.y)*28,(p.x+p.y)*14)*demo.zoom_target
	demo.pointer = demo.size*0.5

func _consume_partial_action() -> void:
	next_action["state"] = "consumed"
	opened = false
	next_action_row.hide()
	next_partial_row.hide()
	hide()
	demo.queue_redraw()

func _take_partial_public() -> void:
	var site := _partial_public_site(str(next_action.get("public_id","")))
	if site.is_empty():
		demo._message("这处公共设施已变化 · 点击当前设施继续规划")
		hide_tool()
		return
	_focus_planning_position(site.get("position",[]))
	demo.selected_id = ""
	demo.context = {"kind":str(site.get("kind","")),"id":str(site.get("id",""))}
	demo.menu_info.text = str(site.get("name","局部公共空间"))+" · 已落成，可继续规划"
	demo._show_context_menu()
	_consume_partial_action()

func _take_remaining_reservation() -> void:
	if next_action.get("state","") != "ready" or not bool(next_action.get("partial",false)): return
	for raw_id in next_action.get("remaining_reservation_ids",[]):
		var reservation := _remaining_reservation(str(raw_id),str(next_action.get("public_id","")))
		if reservation.is_empty(): continue
		_focus_planning_position(reservation.get("position",[]))
		demo.selected_id = ""
		demo.context = {"kind":"reservation","id":str(raw_id),"position":reservation.get("position",[]).duplicate()}
		demo.menu_info.text = "保留下来的留地 · 可继续画公园、文化馆或内院"
		demo._show_context_menu()
		_consume_partial_action()
		return
	demo._message("剩余留地已经变化 · 点击地图上的当前留地继续规划")
	hide_tool()

func _take_served_building() -> void:
	if next_action.get("state","") != "ready" or not (bool(next_action.get("partial",false)) or bool(next_action.get("reuse",false))): return
	var site := _partial_public_site(str(next_action.get("public_id","")))
	for raw_id in next_action.get("served_building_ids",[]):
		var id := str(raw_id)
		if not demo.shown_world.by_id.has(id) or not site.get("served",[]).has(id): continue
		demo.selected_id = id
		demo.context = {"kind":"retune","id":id}
		demo._verb("focus")
		demo._show_context_menu()
		_consume_partial_action()
		return
	demo._message("文化服务已经变化 · 点击当前房屋查看服务与调音")
	hide_tool()

func _replan_next_action() -> void:
	next_action.clear()
	open_tool()

func commit_scope() -> void:
	if scope.is_empty(): return
	var operation := {"kind":"charter","plan_id":plan_id,"community_ids":scope.duplicate(),"card_refs":[card_id]}
	var result: Dictionary = demo.model.submit(operation)
	if not bool(result["accepted"]):
		demo._message(str(result["reason"]))
		return
	committed_charter_id = "charter-%05d" % int(result["event_id"])
	stage = "anchor"
	composition_public_hint.clear()
	if _first_composition_mode() and demo.shown_world.by_id.has(str(demo.composition_source_id)):
		composition_public_hint = demo.AuthoredDuet.public_candidate(demo.model.world,demo.composition_source_id,str(scope[0]))
	demo._message("章程与变化卡已排入下一乐句 · "+str(PlanningCard.CARDS.get(card_id,{}).get("title","变化卡")))
	refresh()

func _update_transit_detail() -> void:
	var route: Dictionary = demo._transit_route_preview()
	var anchor: Dictionary = route.get("charter_anchor",{})
	var source := TransitCharter.source(demo.model.world,committed_charter_id)
	var names: Array[String] = demo._transit_community_names(source.get("scope_community_ids",[]))
	var lines: Array[String] = ["章程范围 · "+"、".join(names),"左键沿道路加站 · Backspace撤回 · 按住空格试听 · Enter确认"]
	if demo.transit_route_stops.size() < 2: lines.append("已放%d站 · 至少两站，实际覆盖一个所选社区后可确认" % demo.transit_route_stops.size())
	else:
		lines.append("实际覆盖 · "+"、".join(demo._transit_community_names(anchor.get("covered_scope_community_ids",[])))+" · %d栋" % anchor.get("scope_covered_building_ids",[]).size())
		var missed := "、".join(demo._transit_community_names(anchor.get("uncovered_scope_community_ids",[])))
		lines.append("尚未覆盖 · "+missed if not missed.is_empty() else "所选社区已全部接入")
		if not bool(route.get("accepted",false)): lines.append(str(route.get("reason","继续沿真实道路加站")))
	lines.append("线路不占新建筑用地；实际客流达到脉冲条件才带来声音。")
	detail.text = "\n".join(lines)

func _update_transit_edit_detail() -> void:
	var route: Dictionary = demo._transit_route_preview()
	var lines: Array[String] = ["沿用原线路身份与原章程来源；沿道路加站，Backspace撤回或清空重画。","按住空格取得同源3秒合奏 · 按钮切换保留 / 改站 · Enter确认当前选择"]
	lines.append("当前%d站 · 至少两站" % demo.transit_route_stops.size())
	if bool(route.get("accepted",false)):
		lines.append("实际覆盖 · %d → %d栋房屋 · 新接入%d栋，移出%d栋" % [route["old_coverage"].get("covered_building_ids",[]).size(),route["new_coverage"].get("covered_building_ids",[]).size(),route.get("added_covered_building_ids",[]).size(),route.get("removed_covered_building_ids",[]).size()])
		var source_names := "、".join(demo._transit_community_names(demo.transit_edit_context.get("scope_community_ids",[])))
		if not source_names.is_empty(): lines.append("保留原章程范围 · "+source_names)
	elif not route.is_empty(): lines.append(str(route.get("reason","继续沿真实道路加站")))
	if transit_comparison_is_current():
		lines = ["同一下一句的3秒合奏 · 按住空格时切换，Enter确认当前选择"]
		for choice: String in ["keep","edit"]:
			var variant: Dictionary = transit_comparison["variants"][choice]
			var title := "保留原线" if choice == "keep" else "改站"
			if not bool(variant.get("accepted",false)):
				lines.append(title+" · "+str(variant.get("reason","草稿还未完成")))
				continue
			var coverage: Dictionary = variant.get("coverage",{})
			lines.append("%s · 实际覆盖%d栋、%d社区 · %s" % [title,coverage.get("covered_building_ids",[]).size(),coverage.get("community_ids",[]).size(),str(coverage.get("route_role","社区往返线"))])
			var music_message := str(variant.get("music_feedback",{}).get("message","实际客流达到脉冲条件才带来声音")).replace("pulse_dense","密集脉冲节奏").replace("pulse","脉冲节奏")
			lines.append("　"+music_message)
		var selected: Dictionary = transit_comparison["variants"][transit_choice]
		var opportunities: Array = selected.get("opportunities",[])
		for opportunity: Dictionary in opportunities.slice(0,2):
			var cid := str(opportunity.get("community_id",""))
			var names: Array[String] = demo._transit_community_names([cid])
			lines.append((names[0] if not names.is_empty() else cid)+" · "+str(opportunity.get("current","")))
		if bool(selected.get("accepted",false)) and not bool(transit_comparison.get("pcm_changed",false)) and bool(transit_comparison["variants"]["edit"].get("accepted",false)): lines.append("这3秒合奏相同；覆盖与客流条件按各方案变化。")
	else: lines.append("实际客流达到脉冲条件才带来声音；保留可撤回这条线的待播改站。")
	detail.text = "\n".join(lines)

func update_candidate(p: Vector2) -> void:
	if stage == "partial_anchor":
		_update_partial_detail()
		return
	if stage == "reuse_anchor":
		_update_reuse_detail()
		return
	candidate = demo.model.world.planning_candidate(p)
	preview.clear()
	if candidate.is_empty(): return
	candidate["planning_scope"] = scope.duplicate()
	var access := Planning.public_access(demo.model.world,candidate)
	preview = Charter.anchor_preview(demo.model.world,candidate,anchor_kind,access)
	if anchor_kind == "reserve": preview["access"] = true
	var name := str(demo.model.world.communities.get(str(candidate["community_id"]),{}).get("name",""))
	var valid: bool = bool(candidate.get("allowed",false)) and (anchor_kind == "reserve" or bool(preview["access"])) and Charter.in_scope(demo.model.world,str(candidate["community_id"]),scope)
	detail.text = "%s · %s\n" % [name,"占用这片真实空地，房屋会避开" if valid else "此处不可提交 · "+str(candidate.get("reason","请选社区内有入口的空地"))]
	detail.text += "道路可达%d栋" % int(preview["reachable"])
	if anchor_kind == "civic": detail.text += " · 首级容量18栋，重叠服务不重复"
	if anchor_kind == "reserve": detail.text += " · 留地本身不发声，下一句普通成长绕开这里"
	detail.text += " · 虚线=规划影响，金点=道路可达\n按住空格比较规划选择；切换按钮听同一时刻的3秒合奏。"
	if not comparison.is_empty() and comparison_key == comparison_identity(): _show_comparison()

func _update_partial_detail() -> void:
	var component_count := Planning.footprint_components(partial_site).size()
	var hole_count := Planning.footprint_holes(partial_site).size()
	var remaining_count := int(partial_site.get("remaining_count",partial_site.get("remaining_polygons",[]).size()))
	detail.text = "已固定你画好的%d块范围 · %d处内院 · 保留%d片留地\n" % [component_count,hole_count,remaining_count]
	detail.text += "按住空格听同一范围的不建、公园、文化馆；按钮切换方案，Enter 确认，Esc 取消。\n"
	detail.text += "暂不兑现会保留来源留地；公园/文化馆只占用画好的范围，内院仍可继续规划。"
	if not comparison.is_empty() and comparison_key == comparison_identity(): _show_comparison()

func _update_reuse_detail() -> void:
	var current := "公园" if str(reuse_site.get("current_kind","")) == "park" else "文化馆"
	detail.text = "当前用途 · %s · 固定%d块原占地、%d处内院\n" % [current,Planning.footprint_components(reuse_site).size(),Planning.footprint_holes(reuse_site).size()]
	detail.text += "按住空格比较保留、公园、文化馆；按钮切换同一时刻的3秒完整合奏。\n"
	detail.text += "点击确认或原占地排入下一句，Esc取消。保留当前用途不改变设施；文化馆原有扩容仍可使用。"
	if not comparison.is_empty() and comparison_key == comparison_identity(): _show_comparison()

func comparison_identity() -> Array:
	if not opened: return []
	if stage == "reuse_anchor":
		if not public_reuse_is_current(): return []
		return [demo.model.presentation_token]+PublicPreview.identity(demo.model,reuse_site)
	if stage == "partial_anchor":
		if partial_site.is_empty() or not bool(partial_site.get("allowed",false)): return []
		return [demo.model.presentation_token]+PublicPreview.identity(demo.model,partial_site)
	if stage != "anchor": return []
	var site: Dictionary = demo.model.world.planning_candidate(demo.world_at(demo.pointer))
	if site.is_empty() or not bool(site.get("allowed",false)) or not Charter.in_scope(demo.model.world,str(site["community_id"]),scope): return []
	site["planning_scope"] = scope.duplicate()
	return [demo.model.presentation_token]+PublicPreview.identity(demo.model,site)

func accept_comparison(payload: Dictionary,request_key: Array) -> bool:
	if request_key.is_empty() or request_key != comparison_identity() or payload.get("source_version",[]) != request_key.slice(1): return false
	comparison = payload
	comparison_key = request_key.duplicate(true)
	update_candidate(demo.world_at(demo.pointer))
	return true

func _clear_comparison_community() -> void:
	comparison_community_id = ""
	if comparison_community_choices != null: comparison_community_choices.hide()

func _comparison_community_records(variant: Dictionary) -> Array:
	var preview: Variant = variant.get("opportunity_preview",{})
	if preview is Dictionary and preview.get("communities",[]) is Array and not preview.get("communities",[]).is_empty():
		return preview["communities"]
	return variant.get("opportunities",[])

func _comparison_community_name(cid: String) -> String:
	var variants: Dictionary = comparison.get("variants",{})
	for record in _comparison_community_records(variants.get(anchor_kind,{})):
		if record is Dictionary and str(record.get("community_id","")) == cid and not str(record.get("community_name","")).is_empty():
			return str(record["community_name"])
	if demo != null and demo.has_method("_request_preview") and demo.model != null:
		return str(demo.model.world.communities.get(cid,{}).get("name",cid))
	return cid

func _sync_comparison_communities() -> void:
	var variants: Dictionary = comparison.get("variants",{})
	var ids: Array[String] = []
	for record in _comparison_community_records(variants.get(anchor_kind,{})):
		if not record is Dictionary: continue
		var cid := str(record.get("community_id",""))
		if not cid.is_empty() and not ids.has(cid): ids.append(cid)
	if not ids.has(comparison_community_id): comparison_community_id = ids[0] if not ids.is_empty() else ""
	var current_ids: Array[String] = []
	for child in comparison_community_choices.get_children():
		if child is Button: current_ids.append(str(child.get_meta("community_id","")))
	if current_ids != ids:
		for child in comparison_community_choices.get_children():
			comparison_community_choices.remove_child(child)
			child.queue_free()
		var label := Label.new()
		label.text = "查看社区"
		label.add_theme_color_override("font_color",Color("51665c"))
		comparison_community_choices.add_child(label)
		for cid in ids:
			var button := Button.new()
			button.text = _comparison_community_name(cid)
			button.toggle_mode = true
			button.set_meta("community_id",cid)
			button.tooltip_text = "查看这片社区的真实机会条件；试听保持完整合奏"
			button.pressed.connect(choose_comparison_community.bind(cid))
			comparison_community_choices.add_child(button)
	for child in comparison_community_choices.get_children():
		if child is Button: child.set_pressed_no_signal(str(child.get_meta("community_id","")) == comparison_community_id)
	comparison_community_choices.visible = ids.size() > 1

func choose_comparison_community(cid: String) -> void:
	var variants: Dictionary = comparison.get("variants",{})
	var records := _comparison_community_records(variants.get(anchor_kind,{}))
	if not records.any(func(record: Variant) -> bool: return record is Dictionary and str(record.get("community_id","")) == cid): return
	comparison_community_id = cid
	_show_comparison()

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
	# Community records follow the viewed community; direct role arrays keep
	# the older comparison format without borrowing a neighboring record.
	var scoped_entries: Array = entries
	if not comparison_community_id.is_empty():
		var selected: Array = entries.filter(func(raw: Variant) -> bool: return raw is Dictionary and str(raw.get("community_id","")) == comparison_community_id)
		if not selected.is_empty(): scoped_entries = selected
		elif entries.any(func(raw: Variant) -> bool: return raw is Dictionary and raw.has("community_id")): return []
	for raw in scoped_entries:
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
	return scoped_entries

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

func _comparison_kinds() -> Array[String]:
	var result: Array[String] = []
	for kind: String in ["none","reserve","park","civic"]:
		if comparison.get("variants",{}).has(kind): result.append(kind)
	return result

func _show_comparison() -> void:
	_sync_comparison_communities()
	var partial := stage == "partial_anchor"
	var reuse := stage == "reuse_anchor"
	var lines: Array[String] = ["下一句真实对照 · 同一时刻 / 同一增益 / 各3秒",
		"试听是完整合奏 · 切换下方方案对比，点击地图确认"]
	if partial: lines = ["同一范围 · 试听是完整合奏 · 每种3秒 · Enter 确认这一范围"]
	if reuse: lines = ["同一原占地 · 每种3秒完整合奏 · 按住空格试听，确认后下一句改用"]
	if not comparison_community_id.is_empty(): lines.append("查看 · "+_comparison_community_name(comparison_community_id)+" · 当前方案的声部条件")
	for kind: String in _comparison_kinds():
		var variant: Dictionary = comparison["variants"][kind]
		var title := str({"none":"暂不建","reserve":"留地 · 呼吸","park":"公园","civic":"文化馆"}[kind])
		if reuse and kind == "none": title = "保留当前用途"
		var prefix := "● " if kind == anchor_kind else "   "
		if not variant["accepted"]:
			lines.append(prefix+title+" · "+str(variant["reason"]))
			continue
		var role := "主题留白" if variant["score"]["theme"].is_empty() else "主题%d次/句" % int(variant["theme_events"])
		var service := "文化服务%d栋" % int(variant["service"]["served"])
		if kind == "reserve": service = "留地 · 下一句绕开这里"
		if kind == "civic":
			service = "本馆%d/%d栋 · 全城净增%d栋服务" % [variant["anchor"].get("served",[]).size(),int(variant["anchor"].get("service_capacity",18)),variant["newly_served_ids"].size()-variant["lost_service_ids"].size()]
		lines.append(prefix+title+(" · 下一句共%d栋 · " if partial else " · 下一句%d栋 · ") % int(variant["houses"])+service+" · "+role)
	var chosen: Dictionary = comparison["variants"][anchor_kind]
	if chosen["accepted"]:
		var raw_combo: Variant = chosen.get("opportunity_preview",{}).get("community_combo",{}) if chosen.get("opportunity_preview",{}) is Dictionary else {}
		if raw_combo is Dictionary and int(raw_combo.get("count",0)) > 1:
			var combo_message := str(raw_combo.get("message",raw_combo.get("next","")))
			if not combo_message.is_empty(): lines.append("组合听觉机会 · "+combo_message)
		var chosen_items := _comparison_opportunity_items(chosen)
		if partial or reuse or anchor_kind == "reserve":
			var baseline: Dictionary = comparison["variants"].get("none",{})
			var baseline_pcm: Variant = baseline.get("pcm",null)
			var same_audio := false
			if bool(baseline.get("accepted",false)) and baseline_pcm is PackedByteArray and not baseline_pcm.is_empty():
				if anchor_kind != "none": same_audio = chosen.get("pcm",PackedByteArray()) == baseline_pcm
				else:
					var compared := 0
					var all_same := true
					for kind: String in ["reserve","park","civic"]:
						var other: Dictionary = comparison["variants"].get(kind,{})
						if not bool(other.get("accepted",false)): continue
						compared += 1
						all_same = all_same and other.get("pcm",PackedByteArray()) == baseline_pcm
					same_audio = compared > 0 and all_same
			if same_audio:
				lines.append("这3秒合奏相同；留地不新增声部，下一句普通成长绕开这里。" if anchor_kind == "reserve" else "这3秒合奏相同；空间与服务按上方方案变化，声音仍需下列条件。")
		lines.append(str({"none":"保留当前用途" if reuse else "暂不兑现" if partial else "暂不建设","reserve":"留地 · 当前保持安静","park":"公园","civic":"文化馆"}[anchor_kind])+" · 当前机会")
		for role_id: String in ["Bass","Rhythm","Response"]:
			lines.append(_comparison_role_line(chosen_items,role_id))
		var chosen_theme := _comparison_role_item(chosen_items,"Lead")
		if chosen_theme.is_empty() and not chosen_items.is_empty(): chosen_theme = chosen_items[0]
		if not chosen_theme.is_empty() and not str(chosen_theme.get("next","")).is_empty():
			lines.append("下一步 · "+str(chosen_theme["next"]))
	if partial: lines.append("暂不兑现保留来源留地；公园/文化馆只占画好的范围，内院和余地继续保留。")
	elif reuse: lines.append("保留沿用当前用途；改用保留原占地、内院和设施身份，下一乐句生效。")
	elif anchor_kind == "reserve": lines.append("留地保留真实空地；它本身不发声、不增加活力，下一句普通成长绕开这里，试听可能因此更疏，之后可释放或改作公共用途。")
	else: lines.append("不建保留正常成长；公园/文化馆占用这片空地。新选择替换待落定公共规划。")
	detail.text = "\n".join(lines)

func sync() -> void:
	visible = opened and not demo.black
	if (bool(next_action.get("transit_anchor",false)) or bool(next_action.get("first_composition_anchor",false))) and next_action.get("state","") == "queued": _expire_next_action_if_stale()
	if observed_phrase != demo.shown_world.phrase_index:
		observed_phrase = demo.shown_world.phrase_index
		_expire_next_action_if_stale()
		for event in demo.shown_world.events:
			if int(event.get("frame",-1)) != observed_phrase*int(demo.shown_world.cfg["timing"]["phrase_frames"]): continue
			if (bool(next_action.get("partial",false)) or bool(next_action.get("reuse",false)) or bool(next_action.get("transit_anchor",false)) or bool(next_action.get("first_composition_anchor",false))) and next_action.get("state","") == "queued" and str(event.get("kind","")) == "planning_rejected" and int(event.get("event_id",-2)) == int(next_action.get("event_id",-1)):
				next_action["state"] = "expired"
				next_action["reason"] = "这片公共规划没有落定 · "+str(event.get("reason","请重新选择留地"))
				stage = "feedback"
				opened = true
				refresh()
			if _next_action_event_matches(event):
				_activate_next_action(event)
			if not bool(next_action.get("first_composition_anchor",false)) and causal_feedback_count < 2 and str(event.get("kind","")) == "birth" and event.has("plan_id"):
				causal_feedback_count += 1
				var building: Dictionary = demo.shown_world.by_id.get(str(event.get("district_id","")),{})
				var plan: Dictionary = Charter.PLANS.get(str(event.get("plan_id", "")),{})
				var title := str(plan.get("title","发展章程"))
				var kind := "律动街" if str(building.get("type","residential")) == "commercial" else ("工坊" if str(building.get("type","residential")) == "industrial" else "长音房")
				var shape := str(building.get("form","胚"))
				var pitch: String = demo.note_name(int(building.get("current_midi",48))) if not building.is_empty() else "待定音级"
				demo._message("%s · %s以%s落地，%s%s；下一步可继续调音或按P规划下一片社区" % [title,kind,shape,"音级"+pitch+" · " if pitch != "待定音级" else "", "沿你的规划生长"])
				if not (bool(next_action.get("partial",false)) or bool(next_action.get("reuse",false)) or bool(next_action.get("transit_anchor",false))): break
	if not visible: return
	if stage == "charter":
		var audible_theme: Dictionary = demo.model.audible_theme()
		var theme_key: Array = [str(audible_theme.get("cid","")),audible_theme.get("source_ids",[])]
		if theme_key != charter_theme_key: refresh()
	if stage == "reuse_anchor" and not public_reuse_is_current():
		hide_tool()
		demo._message("这处公共空间已经变化，请重新点选用途")
		return
	if stage in ["transit_anchor","transit_edit"]:
		if not demo._transit_source_is_current():
			hide_tool()
			demo._message("线路或道路已经变化，请重新选择作者线路" if stage == "transit_edit" else "章程已经变化，公交草稿已关闭；按P选择当前范围")
			return
		var operation: Dictionary = demo._transit_route_operation({})
		var transit_key: Array = demo._transit_preview_identity(operation["stop_positions"])
		if stage == "transit_edit" and ((not transit_comparison.is_empty() and transit_comparison_key != transit_key) or (demo.preview_requested and demo.preview_context_key != transit_key)):
			demo._invalidate_transit_preview()
		if transit_key != preview_key:
			refresh()
			preview_key = transit_key
	if stage in ["anchor","partial_anchor","reuse_anchor"]:
		var next_comparison_key := comparison_identity()
		if not comparison.is_empty() and next_comparison_key != comparison_key:
			comparison.clear()
			comparison_key.clear()
			_clear_comparison_community()
			if demo.preview_public: demo._cancel_preview_playback()
		var p: Vector2 = demo.world_at(demo.pointer)
		var key: Array = [comparison_identity(),anchor_kind,not comparison.is_empty()] if stage in ["partial_anchor","reuse_anchor"] else [p,Charter.version(demo.model.world),anchor_kind,not comparison.is_empty()]
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
	if stage == "reuse_anchor":
		var tint := Color("729b70")
		var fill_site := candidate.duplicate()
		fill_site["target_polygons"] = Planning.footprint_components(candidate)
		for fill in demo._partial_preview_fill_polygons(fill_site):
			demo.draw_colored_polygon(demo._project_polygon(fill),Color(tint,0.3))
		for world_polygon in Planning.footprint_components(candidate)+Planning.footprint_holes(candidate):
			var polygon: PackedVector2Array = demo._project_polygon(world_polygon)
			polygon.append(polygon[0])
			demo.draw_polyline(polygon,tint,2.0,true)
		return
	for world_polygon in scope_polygons:
		var polygon: PackedVector2Array = demo._project_polygon(world_polygon)
		demo.draw_colored_polygon(polygon,Color(0.55,0.72,0.57,0.16))
		polygon.append(polygon[0])
		demo.draw_polyline(polygon,Color(0.45,0.62,0.45,0.5),1.1,true)
	if stage == "anchor" and not composition_public_hint.is_empty():
		var raw: Array = composition_public_hint["position"]
		var at: Vector2 = demo.point(Vector2(float(raw[0]),float(raw[1])))
		demo.draw_arc(at,13.0,0.0,TAU,32,Color("92764b"),1.5,true)
		demo.draw_string(ThemeDB.fallback_font,at+Vector2(18,-14),"公建落点 · 河岸留给声音",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("596d58"))
	if stage != "anchor" or candidate.is_empty(): return
	var polygon: PackedVector2Array = demo._project_polygon(candidate["polygon"])
	var allowed: bool = bool(candidate.get("allowed",false)) and (anchor_kind == "reserve" or bool(preview.get("access",false))) and Charter.in_scope(demo.model.world,str(candidate["community_id"]),scope)
	var tint := Color("849b78") if anchor_kind == "reserve" and allowed else (Color("729b70") if allowed else Color("b47664"))
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
	if anchor_kind == "reserve" and allowed:
		demo.draw_string(ThemeDB.fallback_font,demo.point(center)+Vector2(10,-10),"留地 · 下一句保留",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("63785e"))
	var access := Planning.public_access(demo.model.world,candidate)
	if not access.is_empty():
		var entrance := Vector2(float(access["entrance"][0]),float(access["entrance"][1]))
		demo.draw_circle(demo.point(entrance),4.0,Color("c2a66b"))
