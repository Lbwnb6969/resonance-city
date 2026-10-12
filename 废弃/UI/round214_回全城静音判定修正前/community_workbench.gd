extends PanelContainer
## A read-only workbench for the community heard by the player.
const Description = preload("res://scripts/world/community_workbench_state.gd")
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")

signal listen_requested(cid: String)
signal planning_requested(cid: String)
signal author_requested(root_id: String)
signal closed

var demo: Control
var opened := false
var community_id := ""
var state: Dictionary = {}
var title_label: Label
var summary_label: Label
var status_label: Label
var public_label: Label
var pitch_label: Label
var pitch_chart: HeardPitchChart
var author_heading: Label
var author_rows: VBoxContainer
var community_rows: HFlowContainer
var scroll: ScrollContainer
var body: VBoxContainer
var header: HBoxContainer
var footer: VBoxContainer
var planning_button: Button
var listen_button: Button
var all_city_button: Button
var close_button: Button
var content_key := -1

class HeardPitchChart extends Control:
	var counts: Array[int] = []
	var total_count := 0
	const NOTE_NAMES := ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
	func _init() -> void:
		custom_minimum_size = Vector2(264,66)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		counts.resize(12)
	func set_counts(midi_counts: Dictionary) -> void:
		counts.fill(0)
		total_count = 0
		for midi: Variant in midi_counts:
			var count := int(midi_counts[midi])
			counts[posmod(int(midi),12)] += count
			total_count += count
		queue_redraw()
	func _draw() -> void:
		var font := get_theme_font("font","Label")
		var maximum := 1
		for count: int in counts: maximum = maxi(maximum,count)
		var column := size.x/12.0
		var base := size.y-22.0
		for pc in range(12):
			var x := column*(float(pc)+0.5)
			var bar_width := minf(12.0,column-10.0)
			draw_style_box(_track(),Rect2(x-bar_width*0.5,2,bar_width,base-2))
			if counts[pc] > 0:
				var height := (base-3.0)*float(counts[pc])/float(maximum)
				draw_rect(Rect2(x-bar_width*0.5,base-height,bar_width,height),Ui.GREEN.lightened(0.10))
			var label: String = NOTE_NAMES[pc]
			var text_width := font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			draw_string(font,Vector2(x-text_width*0.5,size.y-4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Ui.INK if counts[pc] > 0 else Ui.MUTED)
	func _track() -> StyleBoxFlat:
		var track := StyleBoxFlat.new()
		track.bg_color = Color("e5e4d4")
		track.set_corner_radius_all(3)
		return track

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	name = "CommunityWorkbench"
	theme = Ui.make_theme()
	z_index = 125
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.x = 356
	add_theme_stylebox_override("panel",Ui.panel(16))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	add_child(column)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	column.add_child(header)
	title_label = _label("街坊",19)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	close_button = _button("收起 · C")
	close_button.pressed.connect(close_tool)
	header.add_child(close_button)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	scroll.add_child(body)
	community_rows = HFlowContainer.new()
	community_rows.add_theme_constant_override("h_separation",5)
	community_rows.add_theme_constant_override("v_separation",5)
	body.add_child(community_rows)
	summary_label = _label("")
	body.add_child(summary_label)
	pitch_label = _label("已听音级")
	body.add_child(pitch_label)
	pitch_chart = HeardPitchChart.new()
	body.add_child(pitch_chart)
	status_label = _label("")
	status_label.add_theme_color_override("font_color",Ui.MUTED)
	body.add_child(status_label)
	public_label = _label("")
	body.add_child(public_label)
	author_heading = _label("你的声音",16)
	body.add_child(author_heading)
	author_rows = VBoxContainer.new()
	author_rows.add_theme_constant_override("separation",5)
	body.add_child(author_rows)
	footer = VBoxContainer.new()
	footer.add_theme_constant_override("separation",6)
	column.add_child(footer)
	planning_button = _button("规划这个街坊")
	Ui.primary(planning_button)
	planning_button.pressed.connect(func() -> void: planning_requested.emit(community_id))
	footer.add_child(planning_button)
	var listening_row := HBoxContainer.new()
	listening_row.add_theme_constant_override("separation",6)
	footer.add_child(listening_row)
	listen_button = _button("听这个街坊")
	listen_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listen_button.pressed.connect(func() -> void: listen_requested.emit(community_id))
	listening_row.add_child(listen_button)
	all_city_button = _button("回到全城合奏")
	all_city_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_city_button.pressed.connect(func() -> void: listen_requested.emit(""))
	listening_row.add_child(all_city_button)
	hide()

func _label(value: String,font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 38
	button.focus_mode = Control.FOCUS_ALL
	return button

func open_community(cid: String) -> void:
	community_id = cid
	opened = true
	content_key = -1
	scroll.scroll_vertical = 0
	sync()
	if opened:
		planning_button.grab_focus()
		call_deferred("_fit")

func close_tool() -> void:
	if not opened: return
	opened = false
	state = {}
	hide()
	closed.emit()

func _communities(world: RefCounted,frame: int) -> Array[Dictionary]:
	var heard: Dictionary = {}
	for building: Dictionary in world.buildings:
		if int(building.get("birth_frame",0)) > frame: continue
		var cid := str(building.get("community_id",""))
		if not world.communities.has(cid) or not bool(world.communities[cid].get("active",true)): continue
		if not world.communities[cid].get("members",[]).has(str(building["district_id"])): continue
		heard[cid] = true
	var ids: Array = heard.keys()
	ids.sort()
	var result: Array[Dictionary] = []
	for cid: String in ids:
		result.append({"id":cid,"name":str(world.communities[cid].get("name",cid))})
	return result

func sync() -> void:
	if not opened: return
	var frame := int(demo.clock.renderer.transport.audible_frame)
	var description: Dictionary = Description.describe(demo.shown_world,community_id,frame,demo.model.audible_pitches())
	if not bool(description["available"]):
		close_tool()
		return
	var communities := _communities(demo.shown_world,frame)
	var next_key := hash([description,communities])
	state = description
	state["audible_frame"] = frame
	if next_key != content_key:
		content_key = next_key
		_refresh(communities)
	var score: Dictionary = demo.model.audible_score()
	var listening := str(score.get("listener_community","")) == community_id
	listen_button.text = "正在听这个街坊" if listening else "听这个街坊"
	listen_button.disabled = listening
	all_city_button.disabled = str(score.get("listener_community","")).is_empty() and str(score.get("focused_community","")).is_empty() and score.get("muted_communities",[]).is_empty()
	visible = not bool(demo.get("black"))
	_fit()

func _clear(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _refresh(communities: Array[Dictionary]) -> void:
	title_label.text = str(state["name"])
	_clear(community_rows)
	for community: Dictionary in communities:
		var cid := str(community["id"])
		var button := _button(str(community["name"]))
		button.toggle_mode = true
		button.set_pressed_no_signal(cid == community_id)
		button.set_meta("community_id",cid)
		button.pressed.connect(open_community.bind(cid))
		community_rows.add_child(button)
	var uses: Array[String] = []
	for kind: String in ["residential","commercial","industrial"]:
		var count := int(state["type_counts"].get(kind,0))
		if count > 0: uses.append(str({"residential":"住宅","commercial":"商业","industrial":"工业"}[kind])+str(count))
	summary_label.text = "%d栋 · %s" % [int(state["count"])," / ".join(uses)]
	pitch_label.text = "已听音级 · %d个声音" % int(state["count"])
	pitch_chart.set_counts(state["midi_counts"])
	status_label.text = str(state["status_text"])
	var public_uses: Dictionary = {}
	for site: Dictionary in state["public_sites"]:
		var kind := "文化馆" if str(site["kind"]) == "civic" else "公园"
		public_uses[kind] = int(public_uses.get(kind,0))+1
	var public_parts: Array[String] = []
	for kind: String in ["文化馆","公园"]:
		if public_uses.has(kind): public_parts.append(kind+str(public_uses[kind]))
	if not state["reservations"].is_empty(): public_parts.append("作者留白"+str(state["reservations"].size()))
	public_label.text = " · ".join(public_parts)
	public_label.visible = not public_parts.is_empty()
	_clear(author_rows)
	author_heading.visible = not state["authors"].is_empty()
	author_rows.visible = author_heading.visible
	for author: Dictionary in state["authors"]:
		var root_id := str(author["root_id"])
		var route := str({"deep":"深流","weave":"织机","warm":"暖庭"}.get(str(author["expression"]),"声音"))
		var button := _button("%s · %s · 改一个音" % [route,_note_name(int(author["current_midi"]))])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set_meta("author_root_id",root_id)
		button.pressed.connect(func() -> void: author_requested.emit(root_id))
		author_rows.add_child(button)

func _note_name(midi: int) -> String:
	return "%s%d" % [HeardPitchChart.NOTE_NAMES[posmod(midi,12)],floori(float(midi)/12.0)-1]

func _fit() -> void:
	if not opened: return
	var maximum_height := maxf(0.0,demo.size.y-100.0)
	var fixed_height := 32.0+header.get_combined_minimum_size().y+footer.get_combined_minimum_size().y+20.0
	var scroll_height := minf(body.get_combined_minimum_size().y,maxf(0.0,maximum_height-fixed_height))
	scroll.custom_minimum_size.y = scroll_height
	size = Vector2(356,minf(maximum_height,fixed_height+scroll_height))
	position = Vector2(demo.size.x-368.0,76.0)
