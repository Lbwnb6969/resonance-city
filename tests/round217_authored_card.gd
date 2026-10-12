extends SceneTree
## Pure display state, native controls and minimum sufficient narrow layout.
const Card = preload("res://scripts/ui/authored_house_card.gd")
const Ui = preload("res://scripts/ui/valley_ui_theme.gd")
const OUTPUT := "res://验证记录/round217_作者回访_面板/card.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var requests: Array = []
var layouts: Array[Dictionary] = []
var map_hits := 0

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

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _layout(card: VBoxContainer,panel: PanelContainer,window: Vector2) -> bool:
	var rect := panel.get_global_rect()
	var valid: bool = rect.size.x == 356.0 and card.size.x == 324.0 and rect.size.y <= window.y-100.0 and Rect2(Vector2.ZERO,window).encloses(rect)
	var shaped: Array[Dictionary] = []
	for label: Label in [card.title_label,card.place_label,card.heard_label,card.pending_label,card.growth_label,card.cost_label]:
		if not label.is_visible_in_tree(): continue
		valid = valid and label.get_theme_font_size("font_size") >= 14 and rect.encloses(label.get_global_rect())
		if label not in [card.title_label,card.place_label]:
			valid = valid and label.get_visible_line_count() == label.get_line_count() and label.size.y+0.01 >= label.get_minimum_size().y
		shaped.append({"text":label.text,"font_pixels":label.get_theme_font_size("font_size"),"rect":label.get_global_rect(),"lines":label.get_line_count(),"visible_lines":label.get_visible_line_count()})
	var buttons: Array[Button] = [card.next_button,card.land_button,card.naming_button,card.tools_button,card.close_button]
	for button: Button in card.note_buttons.values(): buttons.append(button)
	var note_y := -1.0
	for button: Button in buttons:
		if not button.is_visible_in_tree(): continue
		valid = valid and rect.encloses(button.get_global_rect()) and button.focus_mode == Control.FOCUS_ALL
		var font: Font = button.get_theme_font("font")
		valid = valid and font.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+28.0 <= button.size.x+0.01
	for button: Button in card.note_buttons.values():
		if note_y < 0.0: note_y = button.get_global_rect().position.y
		valid = valid and button.get_global_rect().position.y == note_y
	layouts.append({"window":window,"panel":rect,"card":card.get_global_rect(),"thumbnail":card.thumbnail.get_global_rect(),"next":card.next_button.get_global_rect(),"labels":shaped})
	return valid

func _settle(panel: PanelContainer,window: Vector2) -> void:
	root.size = Vector2i(window)
	for step in range(4):
		panel.size = Vector2(356,panel.get_combined_minimum_size().y)
		panel.position = Vector2(window.x-368,76)
		await process_frame

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_native_panel_without_demo_world_audio_or_gpu")
	var map := Button.new()
	map.size = Vector2(1440,900)
	map.pressed.connect(func() -> void: map_hits += 1)
	root.add_child(map)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",Ui.panel(16))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	var card := Card.new()
	card.setup()
	panel.add_child(card)
	card.note_requested.connect(func(base: int) -> void: requests.append(base))
	card.next_requested.connect(func() -> void: requests.append("next"))
	card.land_requested.connect(func() -> void: requests.append("land"))
	card.naming_requested.connect(func() -> void: requests.append("naming"))
	card.tools_requested.connect(func() -> void: requests.append("tools"))
	card.closed.connect(func() -> void: requests.append("closed"))
	var actual_texture: Texture2D = load("res://资源/精制河湾/整图/refined_house_terrace.png")
	var data := {"title":"你种下的深流","place":"沿河橄榄树旁由玩家亲自选择并命名的一段很长的街道名字",
		"heard":"已听 · C3 · 群","pending":"待播 · E3 · 下一可写拍换音",
		"growth":"这段已长出4栋房屋 · 其中2栋成熟",
		"cost":"改音代价沿当前操作 · Shift低一个八度，最低C2",
		"texture":actual_texture,"choices":[],"has_land":true,"next_label":"下一段 · 继续创作"}
	for base: int in [48,50,52,55,57]:
		data["choices"].append({"base":base,"pitch":base,"text":{48:"C3",50:"D3",52:"E3",55:"G3",57:"A3"}[base],"current":base == 48})
	var original := data.duplicate(true)
	card.set_state(data)
	await _settle(panel,Vector2(800,600))
	check(card.thumbnail.texture == actual_texture and card.title_label.text == data["title"] and card.place_label.tooltip_text == data["place"] and card.heard_label.text == data["heard"] and card.pending_label.text == data["pending"] and card.pending_label.visible and requests.is_empty() and data == original,"real_catalogue_thumbnail_full_name_tooltip_and_separate_heard_pending_facts_are_read_only")
	var fits := _layout(card,panel,Vector2(800,600))
	await _settle(panel,Vector2(1440,900))
	fits = _layout(card,panel,Vector2(1440,900)) and fits
	check(fits,"native_356px_card_with_long_place_name_and_pending_state_fits_800_and_1440_with_five_notes_in_one_row")
	for base: int in [48,50,52,55,57]: await _click(card.note_buttons[base])
	check(requests == [48,50,52,55,57] and card.note_buttons[48].button_pressed and not card.note_buttons[52].button_pressed and card.heard_label.text == original["heard"] and card.pending_label.text == original["pending"] and data == original,"five_native_candidate_clicks_emit_only_requested_bases_and_keep_the_heard_pitch_highlight")
	card.note_buttons[52].grab_focus()
	await _key(KEY_ENTER)
	card.next_button.grab_focus()
	await _key(KEY_ENTER)
	await _key(KEY_TAB)
	check(requests == [48,50,52,55,57,52,"next"] and root.gui_get_focus_owner() == card.land_button,"native_enter_emits_each_focused_action_once_and_tab_uses_native_focus_order")
	for button: Button in [card.land_button,card.naming_button,card.tools_button,card.close_button]: await _click(button)
	check(requests == [48,50,52,55,57,52,"next","land","naming","tools","closed"] and map_hits == 0 and data == original,"secondary_and_close_buttons_emit_only_their_signals_and_consume_clicks_without_modifying_state")
	var updated := data.duplicate(true)
	updated["pending"] = ""
	updated["heard"] = "已听 · E3 · 群"
	updated["has_land"] = false
	for choice: Dictionary in updated["choices"]: choice["current"] = int(choice["base"]) == 52
	card.naming_button.grab_focus()
	var count := requests.size()
	card.set_state(updated)
	card.set_state(updated)
	await _settle(panel,Vector2(800,600))
	check(not card.pending_label.visible and not card.land_button.visible and card.heard_label.text == "已听 · E3 · 群" and card.note_buttons[52].button_pressed and not card.note_buttons[48].button_pressed and root.gui_get_focus_owner() == card.naming_button and requests.size() == count and _layout(card,panel,Vector2(800,600)),"new_heard_state_updates_highlight_and_hides_absent_pending_land_without_recreating_focus_or_firing_actions")
	_mouse(Vector2(100,400),true)
	await process_frame
	_mouse(Vector2(100,400),false)
	await process_frame
	check(map_hits == 1,"map_click_outside_the_interactive_card_remains_available")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"layouts":layouts,"requests":requests,"scope":"Dummy pure authored_house_card with an existing real catalogue texture and independent dictionary fixture. Native candidates/Enter/Tab/actions, read-only heard/pending state and narrow layout only. Root owns source identity, PCM timing, legacy tools, cancellation lifecycle, camera, GPU and human feedback."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND217_AUTHORED_CARD ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
