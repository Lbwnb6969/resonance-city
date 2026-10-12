extends "res://tests/round217_authored_house_live.gd"
## Only the two issues found in independent review, not the 31-check journey.
func _run() -> void:
	output = "res://验证记录/round217_作者回访_集成/handoff_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.archive_directory = output+"isolated_archives"
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	check(demo._begin_first_sound_choice("west-2"),"real_sound_entry")
	await create_timer(0.5).timeout
	await press_button(demo.expression_choices["warm"])
	await tap(KEY_ENTER)
	var boundary := int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(boundary > 0 and await until_frame(boundary+rate*2),"real_authored_house_reaches_device")
	var work: Dictionary = demo._first_authored_state()
	var id := str(work["root_id"])
	check(await click_house(id),"native_author_card_entry")
	await press_button(demo.authored_house_card.tools_button)
	await press_button(demo.menu.get_meta("city_toggle"))
	await press_button(demo.menu.get_meta("public_toggle"))
	await press_button(demo.menu.get_meta("details_toggle"))
	await create_timer(0.3).timeout
	var bounds := demo.menu.get_global_rect()
	var scroll: ScrollContainer = demo.menu.get_meta("scroll")
	check(Rect2(Vector2.ZERO,demo.size).encloses(bounds) and scroll.get_v_scroll_bar().max_value > scroll.size.y and (demo.menu.get_meta("back_to_house") as Control).is_visible_in_tree(),"800_long_legacy_tools_scroll_inside_window_with_fixed_back_button")
	await capture("00_800_长工具在窗口内滚动")
	await press_button(demo.menu.get_meta("back_to_house"))
	check(demo._compact_authored_card() and demo.authored_house_card.visible,"native_fixed_back_returns_to_house")
	# Hold the actual source to exercise cancellation before its audible beat.
	demo.clock.stop_output()
	var submit: Dictionary = demo.model.submit({"kind":"retune","id":id,"midi":55})
	var pending: Array = demo.model.world.pending_actions.duplicate(true)
	var events: Array = demo.model.sound_events.duplicate(true)
	var model_before: Dictionary = demo.model.snapshot()
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_RIGHT
		event.pressed = pressed
		event.position = Vector2(30,180)
		event.global_position = event.position
		Input.parse_input_event(event)
		await process_frame
	check(submit["accepted"] and not demo.menu.visible and demo.model.world.pending_actions == pending and demo.model.sound_events == events and demo.model.snapshot() == model_before,"native_map_right_closes_card_without_cancelling_any_submitted_work")
	FileAccess.open(output+"handoff.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"panel":str(bounds),"scroll":str(scroll.get_global_rect()),"pending_count":pending.size(),"sound_event_count":events.size(),"display":DisplayServer.get_name(),"audio_driver":AudioServer.get_driver_name()},"\t")+"\n")
	print("ROUND217_HANDOFF ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
