extends PanelContainer
## A transient planning tool. Closing it never removes a committed city choice.
const Charter = preload("res://scripts/world/development_charter.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")
var comparison: Dictionary = {}
var comparison_key: Array = []
var demo: Control
var stage := "charter"
var plan_id := ""
var card_id := ""
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
var actions: HBoxContainer
var cards: HBoxContainer
var card_choices: HBoxContainer
var drawn_card_ids: Array[String] = []
var confirm: Button
var candidate: Dictionary = {}
## A player-drawn conversion is a fixed target, independent of the pointer.
var partial_site: Dictionary = {}
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
	detail = Label.new()
	detail.custom_minimum_size.x = 720
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color",Color("51665c"))
	detail.add_theme_font_size_override("font_size",15)
	box.add_child(detail)
	next_action_row = HBoxContainer.new()
	next_action_row.add_theme_constant_override("separation",8)
	next_action_button = Button.new()
	next_action_button.text = "定位落地房屋 · 继续调音"
	next_action_button.tooltip_text = "选中刚落地的房屋，打开已有聚焦与调音入口"
	next_action_button.pressed.connect(_take_next_action)
	next_action_row.add_child(next_action_button)
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
	scope.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_polygons.clear()
	scope_version.clear()
	preview_key.clear()
	comparison.clear()
	comparison_key.clear()
	candidate.clear()
	partial_site.clear()
	observed_phrase = demo.shown_world.phrase_index
	opened = demo.model.world.development_charters.is_empty()
	causal_feedback_count = 0 if opened else 2
	next_action.clear()
	stage = "charter"
	plan_id = ""
	card_id = ""
	refresh()

func open_tool() -> void:
	partial_site.clear()
	comparison.clear()
	comparison_key.clear()
	demo.menu.hide()
	opened = true
	stage = "charter"
	plan_id = ""
	card_id = ""
	scope.clear()
	scope_seed.clear()
	scope_source.clear()
	scope_version.clear()
	refresh()

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
	return "公交站已预选实际覆盖范围 · %d个社区、%d栋已覆盖房屋\n点击社区可替换，Shift点击继续多选" % [community_count,building_count]

func hide_tool() -> void:
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	opened = false
	hide()
	candidate.clear()
	partial_site.clear()
	demo.queue_redraw()

## Keep every component, courtyard and source revision exactly as authored.
## The demo owns submission; this panel only chooses and compares branches.
func begin_partial_comparison(site: Dictionary,selected_kind: String) -> void:
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
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

func clear_partial_comparison() -> void:
	if stage != "partial_anchor" and partial_site.is_empty(): return
	if demo.preview_public: demo._cancel_preview_playback()
	partial_site.clear()
	candidate.clear()
	preview.clear()
	comparison.clear()
	comparison_key.clear()
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
	if stage in ["anchor","partial_anchor"]: update_candidate(demo.world_at(demo.pointer))
	if demo.preview_requested and not comparison.is_empty(): demo._request_preview()

func refresh() -> void:
	cards.visible = stage == "charter"
	card_choices.visible = stage == "card"
	actions.visible = stage != "charter"
	confirm.visible = stage == "scope"
	next_action_row.visible = opened and stage == "feedback" and next_action.get("state","") == "ready"
	var partial_feedback := next_action_row.visible and bool(next_action.get("partial",false))
	next_action_button.text = "定位落成公建 · 继续规划" if partial_feedback else "定位落地房屋 · 继续调音"
	next_action_button.tooltip_text = "打开真实落成公共设施的规划入口" if partial_feedback else "选中刚落地的房屋，打开已有聚焦与调音入口"
	next_partial_row.visible = partial_feedback
	next_reservation_button.visible = partial_feedback and not next_action.get("remaining_reservation_ids",[]).is_empty()
	next_served_button.visible = partial_feedback and not next_action.get("served_building_ids",[]).is_empty()
	confirm.disabled = scope.is_empty()
	for i in range(1,actions.get_child_count()):
		var button: Button = actions.get_child(i)
		button.visible = stage in ["anchor","partial_anchor"]
		button.set_pressed_no_signal(button.get_meta("anchor_kind") == anchor_kind)
	if stage == "charter":
		heading.text = "你想让这片城市怎样生长？"
		detail.text = "先选倾向，再在地图选社区；公园和文化馆由你摆，房屋沿合法空地自动长。"
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
	elif stage == "feedback":
		heading.text = "你的选择已经落地 · 现在轮到你"
		detail.text = _next_action_detail()
	elif stage == "partial_anchor":
		heading.text = "这一片由你安排 · "+str({"park":"公园","civic":"文化馆","none":"暂不兑现"}[anchor_kind])
		_update_partial_detail()
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
	if not bool(preview.get("access",false)):
		demo._message("这片公共空间没有能接入道路的真实入口")
		return true
	var result: Dictionary = demo.model.submit({"kind":anchor_kind,"position":candidate["position"].duplicate()})
	if bool(result["accepted"]):
		var selected_variant: Dictionary = {}
		if comparison.has("variants") and comparison["variants"] is Dictionary:
			selected_variant = comparison["variants"].get(anchor_kind,{})
		_queue_next_action(selected_variant)
		demo.ripple_position = p
		demo.ripple_seconds = 0.6
		demo._message("规划已排入下一乐句 · "+("公园为主题留白" if anchor_kind == "park" else "文化馆按道路与容量支持主题")+"；点击房屋可查看实际声部与下一步")
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
		data = NextAction.from_comparison(comparison,anchor_kind)
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

func _close_after_commit() -> void:
	if demo.preview_public: demo._cancel_preview_playback()
	comparison.clear()
	comparison_key.clear()
	partial_site.clear()
	opened = false
	hide()
	demo.queue_redraw()

func _next_action_event_matches(event: Dictionary) -> bool:
	if next_action.get("state","") != "queued": return false
	var event_kind := str(event.get("kind",""))
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
	if bool(next_action.get("partial",false)):
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
	demo._message("局部公共空间已经落成 · 继续规划余地，或查看实际服务")

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
	var choice: String = str({"park":"公园","civic":"文化馆","none":"暂不建设"}.get(str(next_action.get("choice","")),"公共规划"))
	var community_name: String = str(next_action.get("community_id",""))
	if demo != null and demo.shown_world != null:
		community_name = str(demo.shown_world.communities.get(str(next_action.get("community_id","")),{}).get("name",community_name))
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
	return "%s · %s\n%s\n%s" % [choice,community_name,hint,"规划影响已经兑现，下一步可以改一栋的音、聚焦主题或重新规划另一片社区。"]

func _take_next_action() -> void:
	if next_action.get("state","") != "ready": return
	if bool(next_action.get("partial",false)):
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
	if next_action.get("state","") != "ready" or not bool(next_action.get("partial",false)): return
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
	stage = "anchor"
	demo._message("章程与变化卡已排入下一乐句 · "+str(PlanningCard.CARDS.get(card_id,{}).get("title","变化卡")))
	refresh()

func update_candidate(p: Vector2) -> void:
	if stage == "partial_anchor":
		_update_partial_detail()
		return
	candidate = demo.model.world.planning_candidate(p)
	preview.clear()
	if candidate.is_empty(): return
	candidate["planning_scope"] = scope.duplicate()
	preview = Charter.anchor_preview(demo.model.world,candidate,anchor_kind,Planning.public_access(demo.model.world,candidate))
	var name := str(demo.model.world.communities.get(str(candidate["community_id"]),{}).get("name",""))
	var valid: bool = bool(candidate.get("allowed",false)) and bool(preview["access"]) and Charter.in_scope(demo.model.world,str(candidate["community_id"]),scope)
	detail.text = "%s · %s\n" % [name,"占用这片真实空地，房屋会避开" if valid else "此处不可提交 · "+str(candidate.get("reason","请选社区内有入口的空地"))]
	detail.text += "道路可达%d栋" % int(preview["reachable"])
	if anchor_kind == "civic": detail.text += " · 首级容量18栋，重叠服务不重复"
	detail.text += " · 虚线=规划影响，金点=道路可达\n按住空格比较三种选择；切换按钮听同一时刻的3秒合奏。"
	if not comparison.is_empty() and comparison_key == comparison_identity(): _show_comparison()

func _update_partial_detail() -> void:
	var component_count := Planning.footprint_components(partial_site).size()
	var hole_count := Planning.footprint_holes(partial_site).size()
	var remaining_count := int(partial_site.get("remaining_count",partial_site.get("remaining_polygons",[]).size()))
	detail.text = "已固定你画好的%d块范围 · %d处内院 · 保留%d片留地\n" % [component_count,hole_count,remaining_count]
	detail.text += "按住空格听同一范围的不建、公园、文化馆；按钮切换方案，Enter 确认，Esc 取消。\n"
	detail.text += "暂不兑现会保留来源留地；公园/文化馆只占用画好的范围，内院仍可继续规划。"
	if not comparison.is_empty() and comparison_key == comparison_identity(): _show_comparison()

func comparison_identity() -> Array:
	if not opened: return []
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
	var partial := stage == "partial_anchor"
	var lines: Array[String] = ["下一句真实对照 · 同一快照 / 同一增益 / 各3秒；点击地图才确认",
		"机会行只读同一分支的结构条件；试听是完整合奏，不承诺单独声部未来音频"]
	if partial: lines = ["同一范围 · 试听是完整合奏 · 每种3秒 · Enter 确认这一范围"]
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
		lines.append(prefix+title+(" · 下一句共%d栋 · " if partial else " · 下一句%d栋 · ") % int(variant["houses"])+service+" · "+role)
		if not partial:
			var opportunity_items := _comparison_opportunity_items(variant)
			for role_id: String in ["Bass","Rhythm","Response"]:
				lines.append("　"+_comparison_role_line(opportunity_items,role_id))
	var chosen: Dictionary = comparison["variants"][anchor_kind]
	if chosen["accepted"]:
		var chosen_items := _comparison_opportunity_items(chosen)
		if partial:
			var baseline: Dictionary = comparison["variants"].get("none",{})
			var baseline_pcm: Variant = baseline.get("pcm",null)
			var same_audio := false
			if bool(baseline.get("accepted",false)) and baseline_pcm is PackedByteArray and not baseline_pcm.is_empty():
				if anchor_kind != "none": same_audio = chosen.get("pcm",PackedByteArray()) == baseline_pcm
				else:
					var compared := 0
					var all_same := true
					for kind: String in ["park","civic"]:
						var other: Dictionary = comparison["variants"].get(kind,{})
						if not bool(other.get("accepted",false)): continue
						compared += 1
						all_same = all_same and other.get("pcm",PackedByteArray()) == baseline_pcm
					same_audio = compared > 0 and all_same
			if same_audio: lines.append("这3秒合奏相同；空间与服务按上方方案变化，声音仍需下列条件。")
			lines.append(str({"none":"暂不兑现","park":"公园","civic":"文化馆"}[anchor_kind])+" · 当前机会")
			for role_id: String in ["Bass","Rhythm","Response"]:
				lines.append(_comparison_role_line(chosen_items,role_id))
		var chosen_theme := _comparison_role_item(chosen_items,"Lead")
		if chosen_theme.is_empty() and not chosen_items.is_empty(): chosen_theme = chosen_items[0]
		if not chosen_theme.is_empty() and not str(chosen_theme.get("next","")).is_empty():
			lines.append("下一步 · "+str(chosen_theme["next"]))
	if partial: lines.append("暂不兑现保留来源留地；公园/文化馆只占画好的范围，内院和余地继续保留。")
	else: lines.append("不建保留正常成长；公园/文化馆占用这片空地。新选择替换待落定公共规划。")
	detail.text = "\n".join(lines)

func sync() -> void:
	visible = opened and not demo.black
	if observed_phrase != demo.shown_world.phrase_index:
		observed_phrase = demo.shown_world.phrase_index
		_expire_next_action_if_stale()
		for event in demo.shown_world.events:
			if int(event.get("frame",-1)) != observed_phrase*int(demo.shown_world.cfg["timing"]["phrase_frames"]): continue
			if bool(next_action.get("partial",false)) and next_action.get("state","") == "queued" and str(event.get("kind","")) == "planning_rejected" and int(event.get("event_id",-2)) == int(next_action.get("event_id",-1)):
				next_action["state"] = "expired"
				next_action["reason"] = "这片公共规划没有落定 · "+str(event.get("reason","请重新选择留地"))
				stage = "feedback"
				opened = true
				refresh()
			if _next_action_event_matches(event):
				_activate_next_action(event)
			if causal_feedback_count < 2 and str(event.get("kind","")) == "birth" and event.has("plan_id"):
				causal_feedback_count += 1
				var building: Dictionary = demo.shown_world.by_id.get(str(event.get("district_id","")),{})
				var plan: Dictionary = Charter.PLANS.get(str(event.get("plan_id", "")),{})
				var title := str(plan.get("title","发展章程"))
				var kind := "律动街" if str(building.get("type","residential")) == "commercial" else ("工坊" if str(building.get("type","residential")) == "industrial" else "长音房")
				var shape := str(building.get("form","胚"))
				var pitch: String = demo.note_name(int(building.get("current_midi",48))) if not building.is_empty() else "待定音级"
				demo._message("%s · %s以%s落地，%s%s；下一步可继续调音或按P规划下一片社区" % [title,kind,shape,"音级"+pitch+" · " if pitch != "待定音级" else "", "沿你的规划生长"])
				if not bool(next_action.get("partial",false)): break
	if not visible: return
	if stage in ["anchor","partial_anchor"]:
		var next_comparison_key := comparison_identity()
		if not comparison.is_empty() and next_comparison_key != comparison_key:
			comparison.clear()
			comparison_key.clear()
			if demo.preview_public: demo._cancel_preview_playback()
		var p: Vector2 = demo.world_at(demo.pointer)
		var key: Array = [comparison_identity(),anchor_kind,not comparison.is_empty()] if stage == "partial_anchor" else [p,Charter.version(demo.model.world),anchor_kind,not comparison.is_empty()]
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
