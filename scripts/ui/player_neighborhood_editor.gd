extends PanelContainer
## A local naming draft. Only the owner can confirm it into the work.
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")

signal confirm_requested
signal selection_changed
signal closed

var demo: Control
var opened := false
var selected_ids: Array[String] = []
var record_id := ""
var name_edit: LineEdit
var title_label: Label
var hint_label: Label
var count_label: Label
var name_label: Label
var saved_heading: HBoxContainer
var saved_label: Label
var saved_rows: VBoxContainer
var scroll: ScrollContainer
var column: VBoxContainer
var confirm_button: Button
var close_button: Button
var new_button: Button
var _saved_key := -1

func setup(owner_demo: Control) -> void:
	demo = owner_demo
	name = "PlayerNeighborhoodEditor"
	theme = Ui.make_theme()
	z_index = 125
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.x = 356
	add_theme_stylebox_override("panel",Ui.panel(16))
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	column.add_child(header)
	title_label = _label("给街道起名",19)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	close_button = _button("取消 · Esc")
	close_button.pressed.connect(close_tool)
	header.add_child(close_button)
	hint_label = _label("点房屋增减；仅给所选房屋命名")
	hint_label.add_theme_color_override("font_color",Ui.MUTED)
	column.add_child(hint_label)
	count_label = _label("")
	column.add_child(count_label)
	name_label = _label("名字")
	column.add_child(name_label)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "给这片街道一个名字"
	name_edit.custom_minimum_size.y = 42
	name_edit.add_theme_stylebox_override("normal",Ui.button("normal"))
	name_edit.add_theme_stylebox_override("focus",Ui.button("focus"))
	name_edit.add_theme_color_override("font_color",Ui.INK)
	name_edit.add_theme_color_override("font_placeholder_color",Ui.MUTED)
	name_edit.add_theme_color_override("caret_color",Ui.GREEN)
	name_edit.add_theme_font_size_override("font_size",14)
	name_edit.text_changed.connect(func(_text: String) -> void: _refresh_draft())
	name_edit.text_submitted.connect(func(_text: String) -> void: _confirm())
	column.add_child(name_edit)
	saved_heading = HBoxContainer.new()
	saved_heading.add_theme_constant_override("separation",8)
	column.add_child(saved_heading)
	saved_label = _label("已留下的名字")
	saved_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saved_heading.add_child(saved_label)
	new_button = _button("另选一片")
	new_button.pressed.connect(func() -> void: open_selection([]))
	saved_heading.add_child(new_button)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	column.add_child(scroll)
	saved_rows = VBoxContainer.new()
	saved_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saved_rows.add_theme_constant_override("separation",5)
	scroll.add_child(saved_rows)
	confirm_button = _button("留下这个名字")
	confirm_button.custom_minimum_size.y = 42
	Ui.primary(confirm_button)
	confirm_button.pressed.connect(_confirm)
	column.add_child(confirm_button)
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

func _canonical(ids: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in ids:
		var id := str(value)
		if not id.is_empty() and not result.has(id): result.append(id)
	result.sort()
	return result

func open_selection(initial_ids: Array[String],existing_id: String = "") -> void:
	selected_ids = _canonical(initial_ids)
	record_id = existing_id
	name_edit.text = ""
	if not existing_id.is_empty():
		var record: Dictionary = demo.player_neighborhoods.record(existing_id)
		selected_ids = _canonical(record["member_ids"])
		name_edit.text = str(record["name"])
	opened = true
	_saved_key = -1
	scroll.scroll_vertical = 0
	sync()
	selection_changed.emit()
	call_deferred("_fit")

func toggle_member(id: String) -> void:
	if not opened or id.is_empty(): return
	if selected_ids.has(id):
		selected_ids.erase(id)
	else:
		selected_ids.append(id)
		selected_ids.sort()
	_refresh_draft()
	selection_changed.emit()

func close_tool() -> void:
	if not opened: return
	opened = false
	selected_ids.clear()
	record_id = ""
	name_edit.text = ""
	hide()
	closed.emit()

func _confirm() -> void:
	if opened and not confirm_button.disabled: confirm_requested.emit()

func _refresh_draft() -> void:
	count_label.text = "已选 %d 栋房屋" % selected_ids.size()
	confirm_button.disabled = selected_ids.is_empty() or name_edit.text.strip_edges().is_empty()

func sync() -> void:
	if not opened: return
	var records: Array = demo.player_neighborhoods.records()
	var next_key := hash([records,record_id])
	if next_key != _saved_key:
		_saved_key = next_key
		_refresh_saved(records)
	_refresh_draft()
	visible = not bool(demo.get("black"))
	_fit()

func _refresh_saved(records: Array) -> void:
	for child: Node in saved_rows.get_children():
		saved_rows.remove_child(child)
		child.queue_free()
	saved_heading.visible = not records.is_empty()
	scroll.visible = saved_heading.visible
	for record: Dictionary in records:
		var id := str(record["id"])
		var button := _button("%s · %d栋" % [str(record["name"]),record["member_ids"].size()])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = button.text
		button.toggle_mode = true
		button.set_pressed_no_signal(id == record_id)
		button.set_meta("player_neighborhood_id",id)
		button.pressed.connect(func() -> void: open_selection([],id))
		saved_rows.add_child(button)

func _fit() -> void:
	if not opened: return
	var maximum_height := maxf(0.0,demo.size.y-100.0)
	var fixed_height := 32.0+column.get_combined_minimum_size().y-(scroll.get_combined_minimum_size().y if scroll.visible else 0.0)
	var list_height := minf(168.0,minf(saved_rows.get_combined_minimum_size().y,maxf(0.0,maximum_height-fixed_height))) if scroll.visible else 0.0
	scroll.custom_minimum_size.y = list_height
	size = Vector2(356,minf(maximum_height,fixed_height+list_height))
	position = Vector2(demo.size.x-368.0,76.0)
