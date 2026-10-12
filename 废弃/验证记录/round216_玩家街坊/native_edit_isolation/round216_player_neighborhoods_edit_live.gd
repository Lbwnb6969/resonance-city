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
	await capture("01_修改确认后")
	FileAccess.open(output+"edit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"record":revised,"notice":demo.notice},"\t")+"\n")
	print("ROUND216_EDIT ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
