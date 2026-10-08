extends SceneTree
var checks := 0
var failed := false
func _initialize() -> void: call_deferred("run_check")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("CONTROL_PANEL_FAIL "+message)
func frames() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
func mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
func click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await process_frame
	mouse(at,true)
	await process_frame
	mouse(at,false)
	await frames()
func key(code: Key, target: Viewport = null) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		if target is Window: event.window_id = target.get_window_id()
		Input.parse_input_event(event)
		await process_frame
func tool(main: Control,index: int) -> void:
	await click(main.map_tool)
	var previous: int = main.map_tool.get_popup().get_focused_item()
	for step in range(absi(index-previous)):
		await key(KEY_DOWN if index > previous else KEY_UP,main.map_tool.get_popup())
	await key(KEY_ENTER,main.map_tool.get_popup())
	await frames()
	check(main.map_tool.selected == index,"real tool dropdown selection %d" % index)
func reachable(main: Control,node: Control) -> bool:
	return node.is_visible_in_tree() and main.panel.get_global_rect().encloses(node.get_global_rect())
func capture(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/Demo/操作面板_"+name+".png")
func drag(a: Vector2,b: Vector2) -> void:
	mouse(a,true)
	await process_frame
	var move := InputEventMouseMotion.new()
	move.position = b
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(move)
	await process_frame
	mouse(b,false)
	await frames()
func run_check() -> void:
	check(DisplayServer.get_name() != "headless","requires actual Compatibility GPU")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await frames()
	var original: Dictionary = main.model.session.snapshot()
	check(reachable(main,main.preview_button) and reachable(main,main.confirm_button) and reachable(main,main.controls.get_node("Cancel")),"common actions are visible without scrolling")
	check(not main.prediction.visible and not main.condition_text.visible,"long details folded initially")
	await capture("默认")
	await tool(main,1)
	check(main.release_armed and not main.city_view.draft_mode and not main.city_view.tread_mode,"release exclusive")
	check(main.release_pitch.is_visible_in_tree() and not main.preview_button.is_visible_in_tree(),"release has its own parameters, no hidden audition")
	main.map_tool.grab_focus()
	await key(KEY_SPACE)
	if main.map_tool.get_popup().visible: await key(KEY_ESCAPE,main.map_tool.get_popup())
	check(not main.want_preview and main.worker == null,"focused dropdown space does not start future PCM")
	var chosen := Vector2i(-1,-1)
	for cell in main.model.session._empty_cells():
		var location := Vector2i(cell[0],cell[1])
		var point: Vector2 = main.city_view.point(location)
		if point.x > 100 and point.x < 880 and point.y > 250 and point.y < 660:
			chosen = location
			break
	check(chosen.x >= 0,"visible empty plot fixture")
	mouse(main.city_view.point(chosen),true)
	await process_frame
	mouse(main.city_view.point(chosen),false)
	await frames()
	check(main.model.session.pending.get("verb","") == "release","actual map click submits release")
	var release_pending: Dictionary = main.model.session.pending.duplicate(true)
	await capture("释放")
	await tool(main,2)
	check(main.city_view.draft_mode and not main.release_armed and not main.city_view.tread_mode and main.draft_bias.visible,"draft exclusive with visible bias")
	check(main.model.session.pending == release_pending,"tool change preserves submitted release")
	await drag(main.city_view.point(Vector2i(7,7)),main.city_view.point(Vector2i(8,7)))
	check(main.model.session.pending.get("verb","") == "draft","actual draft drag replaces shared slot")
	await click(main.controls.get_node("Cancel"))
	check(main.model.session.pending.is_empty(),"visible cancellation clears shared slot")
	await tool(main,3)
	await drag(main.city_view.point(Vector2i(7,7)),main.city_view.point(Vector2i(8,7)))
	check(main.city_view.tread_mode and not main.city_view.draft_mode and not main.release_armed,"tread exclusive")
	check(reachable(main,main.confirm_button) and main.forecast_available and not main.preview_button.visible,"tread gain/cost confirmation remains reachable")
	await click(main.confirm_button)
	check(main.model.session.pending.get("verb","") == "tread","actual confirmation queues footstep")
	var tread_pending: Dictionary = main.model.session.pending.duplicate(true)
	await tool(main,0)
	check(main.model.session.pending == tread_pending and not main.city_view.tread_mode and main.preview_button.visible,"browse restores proposal controls without discarding pending")
	for district in main.model.session.city:
		main._select_district(district["district_id"])
		if main.target_select.item_count > 0: break
	check(main.forecast_available and "活力" in main.forecast_summary.text,"visible forecast with real gain and cost")
	main.target_select.grab_focus()
	await key(KEY_SPACE)
	if main.target_select.get_popup().visible: await key(KEY_ESCAPE,main.target_select.get_popup())
	check(not main.want_preview and main.worker == null,"focused proposal dropdown space does not start available audition")
	await click(main.diagnosis_button)
	check(main.city_view.diagnosis_enabled and main.reduced_motion_button.visible,"diagnosis reachable by actual click")
	check(reachable(main,main.preview_button) and reachable(main,main.confirm_button) and reachable(main,main.controls.get_node("Cancel")),"diagnosis expanded keeps proposal actions on screen")
	await capture("诊断")
	var before_details: Dictionary = main.model.session.snapshot()
	await click(main.details_button)
	check(main.prediction.is_visible_in_tree() and main.condition_text.is_visible_in_tree() and main.controls.get_node("Restart").visible,"details reveal full information and restart")
	var scroll: ScrollContainer = main.controls.get_parent()
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await capture("明细展开")
	check(scroll.scroll_vertical > 0 and main.panel.get_global_rect().intersects(main.prediction.get_global_rect()) and not main.prediction.text.is_empty(),"full forecast details reachable by scrolling")
	scroll.scroll_vertical = 0
	await frames()
	await click(main.details_button)
	check(not main.prediction.visible and main.model.session.snapshot() == before_details,"folding does not change city/RNG/pending")
	await click(main.controls.get_node("Black"))
	check(main.black_screen and not main.panel.visible and not main.city_view.visible,"black hides compact controls")
	await key(KEY_ESCAPE)
	check(not main.black_screen and main.map_tool.selected == 0 and main.city_view.diagnosis_enabled and not main.details_button.button_pressed,"return keeps tool and fold states")
	await click(main.controls.get_node("Cancel"))
	check(main.model.session.pending.is_empty() and main.model.session.city == original["city"],"only intended pending changes, no premature settlement")
	print("CONTROL_PANEL %s checks=%d real_dropdown/map/drag/confirm/cancel/details/scroll/black/reachability" % ["FAIL" if failed else "PASS",checks])
	main.queue_free()
	await frames()
	quit(1 if failed else 0)
