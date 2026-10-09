extends Control
## A single notification rail consuming only audible facts from the live model.
signal focus_requested(district_id: String)
const Values = preload("res://scripts/spec_values.gd")
const Growth = preload("res://scripts/city/city_growth.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
var cfg: Dictionary = Values.load_values()["formation_notice"]
var enabled := true
var first_seen: Dictionary = {}
var queue: Array[Dictionary] = []
var current: Dictionary = {}
var read_remaining := 0.0
var gap_remaining := 0.0
var entry_remaining := 0.0
var hovered := false
var card: PanelContainer
var title: RichTextLabel
var happened: Label
var meaning: Label
var next_step: Label
var gap_phrase := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card = PanelContainer.new()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f6f4eaff")
	style.border_color = Color("8c9d8aff")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel",style)
	add_child(card)
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation",8)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rows)
	var first := HBoxContainer.new()
	first.name = "Header"
	first.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(first)
	title = RichTextLabel.new()
	title.bbcode_enabled = true
	title.add_theme_color_override("default_color",Color("536574"))
	title.fit_content = true
	title.scroll_active = false
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("normal_font_size",14)
	first.add_child(title)
	var close := Button.new()
	close.name = "Close"
	close.text = "×"
	close.tooltip_text = "收起成形提示"
	close.custom_minimum_size = Vector2(26,26)
	close.pressed.connect(dismiss)
	first.add_child(close)
	happened = _row(rows,"Happened")
	meaning = _row(rows,"Meaning")
	next_step = _row(rows,"NextStep")
	card.mouse_entered.connect(func() -> void: hovered = true)
	card.mouse_exited.connect(func() -> void: hovered = false)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not current.is_empty():
			focus_requested.emit(str(current["event"]["district_id"]))
			card.accept_event())
	card.hide()

func _row(rows: VBoxContainer, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",14)
	rows.add_child(label)
	return label

func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		queue.clear()
		current.clear()
		read_remaining = 0.0
		gap_remaining = 0.0
		card.hide()

func reset() -> void:
	first_seen.clear()
	queue.clear()
	current.clear()
	read_remaining = 0.0
	gap_remaining = 0.0
	entry_remaining = 0.0
	hovered = false
	card.hide()

func consume(history: Array[Dictionary], audible: float) -> void:
	var eligible: Array[Dictionary] = []
	for fact in history:
		var event: Dictionary = fact["event"]
		if int(event["frame"]) <= audible and str(event["form"]) not in first_seen: eligible.append(fact)
	eligible.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a["event"]["frame"] != b["event"]["frame"]: return a["event"]["frame"] < b["event"]["frame"]
		var rank := ["群","央","腔"]
		if a["event"]["form"] != b["event"]["form"]: return rank.find(a["event"]["form"]) < rank.find(b["event"]["form"])
		return str(a["event"]["district_id"]) < str(b["event"]["district_id"]))
	for fact in eligible:
		var form: String = fact["event"]["form"]
		if first_seen.has(form): continue
		first_seen[form] = str(fact["event"]["district_id"])
		if enabled: queue.append(fact.duplicate(true))

static func direction(cell: Vector2i) -> String:
	var column := 0 if cell.x-cell.y <= -5 else (2 if cell.x-cell.y >= 5 else 1)
	var row := 0 if cell.x+cell.y <= 10 else (2 if cell.x+cell.y >= 20 else 1)
	return [["左上","上方","右上"],["左侧","中部","右侧"],["左下","下方","右下"]][row][column]

func _show_fact(fact: Dictionary, session: CityInterventions, reduced: bool) -> void:
	current = fact
	gap_phrase = -1
	read_remaining = float(cfg["read_seconds"])
	entry_remaining = 0.0 if reduced else float(cfg["entry_seconds"])
	var form: String = fact["event"]["form"]
	var badges := ""
	for step in ["胚","群","央","腔"]:
		badges += ("[bgcolor=#b9ceb3][color=#293d30] " + step + " [/color][/bgcolor]" if step == form else "[color=#687367] " + step + " [/color]")
	title.text = badges+"\n第一次形成「"+form+"」"
	var d: Dictionary = fact["district"]
	var kind := {"residential":"住宅","commercial":"商业","industrial":"工业"}
	var notes := ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
	happened.text = "%s的%s（%s）长成了%s" % [direction(Schema.cell(d)),kind[d["type"]],notes[posmod(int(fact["anchor_midi"]),12)],form]
	meaning.text = {"群":"它和至少两个邻居协和，社区成形了", "央":"群里出现了同音的共鸣邻居，它长成了中心", "腔":"它的每个邻居都与它协和，这是一处共鸣腔"}[form]
	if fact["stage_voice"]:
		meaning.text += "；"+{"群":"它的节奏加入了合奏", "央":"装饰旋律开始点缀", "腔":"每个乐句开头它会敲响一声高处的钟"}[form]
	_refresh_gap(session)
	card.show()

func _refresh_gap(session: CityInterventions) -> void:
	if current.is_empty() or gap_phrase == session.phrase_index: return
	gap_phrase = session.phrase_index
	if current["event"]["form"] in ["央","腔"]:
		next_step.text = "央与腔都是成熟形态"
		return
	var d: Dictionary = session._district(str(current["event"]["district_id"]))
	if d.is_empty():
		next_step.text = "这栋建筑已离开当前城市"
		return
	if d.get("form","胚") in ["央","腔"]:
		next_step.text = "央与腔都是成熟形态"
		return
	var info := Growth.conditions(session.city,d,session.road_marks)
	var center := Growth.stage_gaps(info,2)
	var chamber := Growth.stage_gaps(info,3)
	next_step.text = "下一阶 · 央：%s；腔：%s" % ["；".join(center) if not center.is_empty() else "条件已满足，等待连续乐句", "；".join(chamber) if not chamber.is_empty() else "条件已满足，等待连续乐句"]

func tick(delta: float, audible: float, session: CityInterventions, black: bool, reduced: bool) -> void:
	visible = not black
	if black or not enabled: return
	var width := minf(float(cfg["width"]),maxf(100.0,get_parent().size.x-2.0*float(cfg["left"])))
	card.size = Vector2(width,0.0)

	if current.is_empty():
		gap_remaining = maxf(0.0,gap_remaining-delta)
		if gap_remaining > 0.0 or queue.is_empty(): return
		var ready := int(queue[0]["event"]["frame"])+session.transport.beat_frame(int(cfg["delay_beats"]))
		if audible < ready: return
		_show_fact(queue.pop_front(),session,reduced)
		delta = 0.0
	_refresh_gap(session)
	if reduced: entry_remaining = 0.0
	if entry_remaining > 0.0:
		entry_remaining = maxf(0.0,entry_remaining-delta)
		card.position.x = -float(cfg["entry_px"])*entry_remaining/float(cfg["entry_seconds"])
		card.modulate.a = 1.0-entry_remaining/float(cfg["entry_seconds"])
	else:
		card.position.x = 0.0
		card.modulate.a = 1.0
		if not hovered: read_remaining = maxf(0.0,read_remaining-delta)
		if read_remaining <= 0.0: dismiss()

func _process(_delta: float) -> void:
	# RichTextLabel recomputes wrapped minimum after its Container pass.
	if not current.is_empty(): card.size.y = card.get_combined_minimum_size().y

func dismiss() -> void:
	if current.is_empty(): return
	current.clear()
	card.hide()
	read_remaining = 0.0
	gap_remaining = float(cfg["gap_seconds"])
	hovered = false
