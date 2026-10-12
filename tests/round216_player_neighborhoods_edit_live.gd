extends "res://tests/round216_player_neighborhoods_live.gd"
## Only the unresolved native editing/save step from the first 25/26 run.
func _run() -> void:
	output = "res://验证记录/round216_玩家街坊_集成/edit_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.archive_directory = output+"isolated_archives"
	root.add_child(demo)
	await process_frame
	var saved: Dictionary = CityArchive.latest("res://验证记录/round216_玩家街坊_集成/live_2026-10-12T22-09-58/isolated_archives")
	demo._start_world(saved["city"])
	demo.clock.start_output(demo.model._mix_frame,{},saved["city"]["renderer"])
	await create_timer(0.6).timeout
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","actual_gpu_wasapi_edit_followup")
	# Repeat the preceding real retune/right-cancel/F9 handoff with a complete
	# button press/release pair; the first fixture left right mouse held down.
	var renderer_state: Dictionary = demo.clock.renderer.snapshot()
	demo.clock.stop_output()
	var source_id := str(demo.player_neighborhoods.records()[0]["member_ids"][0])
	var retune: Dictionary = demo.model.submit({"kind":"retune","id":source_id,"midi":55})
	var pending: Array = demo.model.world.pending_actions.duplicate(true)
	var sounds: Array = demo.model.sound_events.duplicate(true)
	await tap(KEY_K)
	for pressed in [true,false]:
		var right := InputEventMouseButton.new()
		right.button_index = MOUSE_BUTTON_RIGHT
		right.pressed = pressed
		right.position = Vector2(32,180)
		right.global_position = right.position
		Input.parse_input_event(right)
		await process_frame
	check(retune["accepted"] and not demo.neighborhood_editor.opened and demo.model.world.pending_actions == pending and demo.model.sound_events == sounds,"complete_native_right_cancel_keeps_real_pending_work")
	demo.clock.start_output(demo.model._mix_frame,{},renderer_state)
	var baseline_save: Dictionary = demo.save_city("隔离编辑基线")
	await tap(KEY_F9)
	await create_timer(0.4).timeout
	check(baseline_save["ok"] and demo.player_neighborhoods.records().size() == 1,"native_f9_handoff_keeps_existing_authorship")
	await tap(KEY_K)
	await press_button(demo.neighborhood_editor.saved_rows.get_child(0))
	await create_timer(0.5).timeout
	var record: Dictionary = demo.player_neighborhoods.records()[0]
	var other_id := str(record["member_ids"][1])
	check(await click_house(other_id),"native_edit_can_hit_the_actual_second_member")
	await click_map(demo.neighborhood_editor.name_edit.get_global_rect().get_center())
	print("EDIT_BEFORE text=",demo.neighborhood_editor.name_edit.text," focus=",root.gui_get_focus_owner()," members=",demo.neighborhood_editor.selected_ids," heard=",demo.clock.renderer.transport.audible_frame," previous=",record["modified_audio_frame"])
	demo.neighborhood_editor.name_edit.select_all()
	await type_text("石桥小街")
	print("EDIT_TYPED text=",demo.neighborhood_editor.name_edit.text," focus=",root.gui_get_focus_owner()," button=",demo.neighborhood_editor.confirm_button.get_global_rect()," disabled=",demo.neighborhood_editor.confirm_button.disabled)
	await capture("00_实际修改草稿")
	await press_button(demo.neighborhood_editor.confirm_button)
	await process_frame
	print("EDIT_AFTER opened=",demo.neighborhood_editor.opened," record=",demo.player_neighborhoods.record(record["id"])," notice=",demo.notice)
	var revised: Dictionary = demo.player_neighborhoods.record(record["id"])
	check(not demo.neighborhood_editor.opened and revised["revision"] == 2 and revised["name"] == "石桥小街" and revised["member_ids"].size() == 1,"native_confirm_updates_existing_record_and_closes")
	await create_timer(0.3).timeout
	check(demo.neighborhood_labels.visible and demo.neighborhood_labels.labels.any(func(label: Dictionary) -> bool: return label["id"] == revised["id"]),"confirmation_frames_remaining_member_and_exposes_its_saved_map_name")
	await capture("01_修改确认后")
	var disk: Dictionary = CityArchive.latest(demo.archive_directory)
	check(disk["ok"] and disk["city"]["authorship"] == demo.player_neighborhoods.snapshot(),"revised_identity_name_members_and_revision_are_saved")
	var dna: Dictionary = CityArchive.export_dna(demo.capture_city(),output+"isolated_exports")
	var dna_read: Dictionary = CityArchive.read_dna(dna["path"]) if dna["ok"] else {}
	check(dna_read.get("ok",false) and dna_read["authorship"] == demo.player_neighborhoods.snapshot(),"revised_actual_demo_city_dna_roundtrip")
	await tap(KEY_F9)
	await create_timer(0.3).timeout
	check(demo.player_neighborhoods.record(record["id"]) == revised,"native_f9_restores_revised_members_name_and_revision")
	await aim_house(str(revised["member_ids"][0]))
	var image: Image = demo.building_geometry[source_id]["image"]
	var sprite: Node2D = demo.sprites[source_id]
	for y in range(8,image.get_height()-8,4):
		if demo.hover_id == source_id: break
		for x in range(8,image.get_width()-8,4):
			var at := sprite.to_global(sprite.offset+Vector2(x,y))
			if demo._hit(at) == source_id:
				await at_pointer(at)
				break
	check(demo.hover_id == source_id and demo.tooltip.text.contains("石桥小街"),"real_house_hover_shows_its_player_defined_name")
	await capture("02_800_房屋回访自己的街坊名字")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await create_timer(0.4).timeout
	await tap(KEY_K)
	await press_button(demo.neighborhood_editor.saved_rows.get_child(0))
	await create_timer(0.6).timeout
	await draft_view("03_1440_已保存石桥小街的精确成员")
	FileAccess.open(output+"edit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"record":revised,"notice":demo.notice},"\t")+"\n")
	print("ROUND216_EDIT ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
