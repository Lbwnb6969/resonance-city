extends SceneTree
## Native panel input and draft isolation without the Demo, World or device.
const Editor = preload("res://scripts/ui/player_neighborhood_editor.gd")
const OUTPUT := "res://验证记录/round216_玩家街坊_面板/panel.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var layouts: Array[Dictionary] = []
var requests: Array[Dictionary] = []
var changes := 0
var closes := 0
var map_hits := 0

class Records extends RefCounted:
	var values: Array[Dictionary] = [{"id":"player-street-1","name":"石桥边","member_ids":["house-2","house-8"]}]
	func records() -> Array[Dictionary]: return values.duplicate(true)
	func record(id: String) -> Dictionary:
		for value: Dictionary in values:
			if str(value["id"]) == id: return value.duplicate(true)
		return {}

class Fixture extends Control:
	var player_neighborhoods := Records.new()
	var black := false

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _mouse(at: Vector2,down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)

func _click(control: Control) -> void:
	_mouse(control.get_global_rect().get_center(),true)
	await process_frame
	_mouse(control.get_global_rect().get_center(),false)
	await process_frame

func _key(code: Key,unicode: int = 0) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.unicode = unicode
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _settle(panel: PanelContainer) -> void:
	for step in range(4):
		panel.sync()
		await process_frame

func _layout(panel: PanelContainer,fixture: Control) -> bool:
	var rect := panel.get_global_rect()
	var valid: bool = rect.size.x == 356.0 and rect.size.y <= fixture.size.y-100.0 and rect.position == Vector2(fixture.size.x-368.0,76.0) and Rect2(Vector2.ZERO,fixture.size).encloses(rect)
	var shaped: Array[Dictionary] = []
	for label: Label in [panel.title_label,panel.hint_label,panel.count_label,panel.name_label,panel.saved_label]:
		if not label.is_visible_in_tree(): continue
		valid = valid and label.get_theme_font_size("font_size") >= 14 and label.get_visible_line_count() == label.get_line_count() and label.size.y+0.01 >= label.get_minimum_size().y
		shaped.append({"text":label.text,"font_pixels":label.get_theme_font_size("font_size"),"rect":label.get_global_rect(),"lines":label.get_line_count(),"visible_lines":label.get_visible_line_count()})
	for control: Control in [panel.close_button,panel.name_edit,panel.confirm_button]:
		valid = valid and rect.encloses(control.get_global_rect()) and control.focus_mode == Control.FOCUS_ALL
	for button: Button in [panel.close_button,panel.confirm_button,panel.new_button]:
		if not button.is_visible_in_tree(): continue
		var font: Font = button.get_theme_font("font")
		valid = valid and font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+28.0 <= button.size.x+0.01
	layouts.append({"window":fixture.size,"panel":rect,"name_edit":panel.name_edit.get_global_rect(),"confirm":panel.confirm_button.get_global_rect(),"saved_scroll":panel.scroll.get_global_rect(),"body_minimum":panel.column.get_combined_minimum_size(),"labels":shaped})
	return valid

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_native_ui_without_demo_world_or_device")
	root.size = Vector2i(800,600)
	var fixture := Fixture.new()
	fixture.size = Vector2(800,600)
	root.add_child(fixture)
	var map := Button.new()
	map.position = Vector2(80,180)
	map.size = Vector2(240,220)
	map.text = "地图命中夹具"
	map.pressed.connect(func() -> void: map_hits += 1)
	fixture.add_child(map)
	var panel := Editor.new()
	panel.setup(fixture)
	fixture.add_child(panel)
	panel.selection_changed.connect(func() -> void: changes += 1)
	panel.closed.connect(func() -> void: closes += 1)
	panel.confirm_requested.connect(func() -> void: requests.append({"record_id":panel.record_id,"name":panel.name_edit.text,"member_ids":panel.selected_ids.duplicate()}))
	var original := fixture.player_neighborhoods.records()
	panel.open_selection(["house-3","house-1","house-1"])
	await _settle(panel)
	check(panel.opened and panel.selected_ids == ["house-1","house-3"] and panel.name_edit.text.is_empty() and panel.confirm_button.disabled and root.gui_get_focus_owner() != panel.name_edit and changes == 1 and fixture.player_neighborhoods.records() == original,"opening_only_normalizes_explicit_ids_and_keeps_map_first_focus_without_writing_a_record")
	await _click(map)
	check(map_hits == 1 and panel.opened and panel.selected_ids == ["house-1","house-3"],"native_map_click_outside_the_356px_panel_is_not_intercepted")
	await _click(panel.name_edit)
	for character: String in "河畔小街": await _key(KEY_NONE,character.unicode_at(0))
	await _settle(panel)
	await _click(panel.confirm_button)
	check(panel.name_edit.text == "河畔小街" and not panel.confirm_button.disabled and requests == [{"record_id":"","name":"河畔小街","member_ids":["house-1","house-3"]}] and fixture.player_neighborhoods.records() == original,"native_chinese_typing_and_confirm_emit_the_draft_only_without_persistence_or_sound_actions")
	panel.toggle_member("house-1")
	panel.toggle_member("house-4")
	check(panel.selected_ids == ["house-3","house-4"] and changes == 3 and panel.count_label.text == "已选 2 栋房屋" and fixture.player_neighborhoods.records() == original,"individual_member_toggle_changes_only_the_explicit_draft_and_not_saved_members")
	await _click(panel.name_edit)
	await _key(KEY_ENTER)
	check(requests.size() == 2 and requests[-1]["member_ids"] == ["house-3","house-4"],"native_enter_in_name_edit_submits_exactly_one_valid_request")
	await _key(KEY_TAB)
	check(root.gui_get_focus_owner() is Button and panel.is_ancestor_of(root.gui_get_focus_owner()),"native_tab_moves_from_text_input_to_a_panel_button")
	panel.name_edit.text = "   "
	panel.sync()
	var blank_name_disabled: bool = panel.confirm_button.disabled
	await _click(panel.confirm_button)
	panel.name_edit.text = "有名字但没有房屋"
	panel.toggle_member("house-3")
	panel.toggle_member("house-4")
	await _click(panel.confirm_button)
	check(blank_name_disabled and panel.confirm_button.disabled and panel.selected_ids.is_empty() and requests.size() == 2,"whitespace_name_and_empty_members_disable_native_confirmation")
	panel.scroll.ensure_control_visible(panel.saved_rows.get_child(0))
	await process_frame
	await _click(panel.saved_rows.get_child(0))
	await _settle(panel)
	check(panel.record_id == "player-street-1" and panel.name_edit.text == "石桥边" and panel.selected_ids == ["house-2","house-8"] and not panel.confirm_button.disabled and fixture.player_neighborhoods.records() == original,"clicking_a_real_saved_name_loads_only_its_exact_members_into_an_uncommitted_edit")
	var fits := _layout(panel,fixture)
	for index in range(2,15):
		fixture.player_neighborhoods.values.append({"id":"player-street-%d" % index,"name":"靠河的一段很长的玩家自定义街道名字 %d" % index,"member_ids":["house-%d" % (100+index)]})
	var many_records := fixture.player_neighborhoods.records()
	await _settle(panel)
	fits = _layout(panel,fixture) and fits
	var scrolls: bool = panel.scroll.get_v_scroll_bar().visible and not panel.scroll.get_h_scroll_bar().visible
	fixture.size = Vector2(1440,900)
	root.size = Vector2i(1440,900)
	await _settle(panel)
	fits = _layout(panel,fixture) and fits
	check(fits and scrolls and panel.saved_rows.get_child_count() == 14,"native_14px_labels_and_fixed_name_confirm_fit_800_and_1440_while_many_long_saved_names_scroll_vertically")
	var last: Button = panel.saved_rows.get_child(-1)
	panel.scroll.ensure_control_visible(last)
	await process_frame
	await _click(last)
	await _settle(panel)
	check(panel.record_id == "player-street-14" and panel.selected_ids == ["house-114"] and panel.name_edit.text == str(many_records[-1]["name"]) and fixture.player_neighborhoods.records() == many_records,"the_last_scrolled_saved_name_is_natively_clickable_and_keeps_its_full_name_and_identity")
	await _click(panel.new_button)
	await _settle(panel)
	check(panel.opened and panel.record_id.is_empty() and panel.selected_ids.is_empty() and panel.name_edit.text.is_empty() and panel.confirm_button.disabled and fixture.player_neighborhoods.records() == many_records,"another_selection_starts_a_clean_draft_without_replacing_an_existing_record")
	panel.toggle_member("house-2")
	panel.name_edit.text = "取消的名字"
	await _click(panel.close_button)
	panel.close_tool()
	check(not panel.opened and not panel.visible and panel.selected_ids.is_empty() and panel.name_edit.text.is_empty() and panel.record_id.is_empty() and closes == 1 and fixture.player_neighborhoods.records() == many_records,"cancel_discards_the_draft_once_and_preserves_all_saved_records")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"layouts":layouts,"requests":requests,"scope":"Dummy native PanelContainer, Buttons and LineEdit over an independent read-only record fixture. Map hit outside the panel, exact draft members, existing-record editing, native typing/Enter/Tab and 800/1440 layout only. Root owns real-building eligibility, Escape/right-click routing, persistence, GPU and user experience."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND216_NEIGHBORHOOD_PANEL ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
