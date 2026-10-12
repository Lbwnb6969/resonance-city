extends "res://tests/round214_community_followup_live.gd"
## Native map/name/archive cycle in an isolated real GPU/WASAPI session.
var selected: Array[String] = []
var saved_record: Dictionary = {}
var views: Array[Dictionary] = []

func aim_house(id: String) -> void:
	var at: Vector2 = demo.Coupling.position_of(demo.shown_world.by_id[id])
	var center := Vector2((demo.neighborhood_editor.position.x-36)*0.5,demo.size.y*0.52) if demo.neighborhood_editor.opened else demo.size*Vector2(0.5,0.52)
	demo.zoom_target = 2.8
	demo.pan_target = center-demo.size*Vector2(0.5,0.52)-demo.Projection2D.to_screen(at-Vector2(16,16),Vector2.ZERO,2.8,Vector2(28,14),demo.shown_world.terrain.height_at(at))
	await create_timer(0.5).timeout

func click_house(id: String) -> bool:
	await aim_house(id)
	var sprite: Node2D = demo.sprites[id]
	var img: Image = demo.building_geometry[id]["image"]
	var clear := Rect2(Vector2(28,125),demo.size-Vector2(56,220))
	if demo.neighborhood_editor.opened: clear.size.x = demo.neighborhood_editor.position.x-56
	for y in range(0,img.get_height(),3):
		for x in range(0,img.get_width(),3):
			if img.get_pixel(x,y).a < 0.8: continue
			var p := sprite.to_global(sprite.offset+Vector2(x,y))
			if clear.has_point(p) and demo._hit(p) == id:
				await click_map(p)
				return true
	return false

func type_text(text: String) -> void:
	for character in text:
		var event := InputEventKey.new()
		event.pressed = true
		event.unicode = character.unicode_at(0)
		event.keycode = character.to_upper().unicode_at(0) if character.unicode_at(0) < 128 else 0
		Input.parse_input_event(event)
		await process_frame
		event.pressed = false
		Input.parse_input_event(event)
		await process_frame

func draft_view(label: String) -> void:
	var panel: Rect2 = demo.neighborhood_editor.get_global_rect()
	check(panel.size.x == 356 and Rect2(Vector2.ZERO,demo.size).encloses(panel),label+"_native_card_fits_window")
	check(not demo.core_slice_hud.legend_visible and not demo.first_composition_guide.visible,label+"_no_duplicate_first_play_guides")
	views.append({"window":str(demo.size),"panel":str(panel),"selected":demo.neighborhood_editor.selected_ids.duplicate(),"footprints":demo.neighborhood_focus.member_polygons.duplicate(true)})
	await capture(label)

func _run() -> void:
	output = "res://验证记录/round216_玩家街坊_集成/live_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.archive_directory = output+"isolated_archives"
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_gpu_window_and_wasapi")
	check(await until_frame(rate*5),"real_opening_is_heard")
	var first_id := str(demo.shown_world.buildings[0]["district_id"])
	var first_cid := str(demo.shown_world.by_id[first_id]["community_id"])
	var other_id := ""
	for house: Dictionary in demo.shown_world.buildings:
		if str(house["community_id"]) != first_cid: other_id = str(house["district_id"]); break
	selected.assign([first_id,other_id])
	selected.sort()
	check(await click_house(first_id) and demo.menu.visible,"native_real_house_opens_its_menu")
	await press_button(demo.menu.get_meta("neighborhood_button"))
	await create_timer(0.4).timeout
	check(demo.neighborhood_editor.opened and demo.neighborhood_editor.selected_ids == [first_id],"native_house_verb_starts_with_only_one_house")
	check(await click_house(other_id),"native_other_partition_house_can_be_clicked")
	check(demo.neighborhood_editor.selected_ids == selected and demo.neighborhood_focus.member_polygons.size() == 2,"explicit_cross_cid_selection_has_only_two_actual_footprints")
	await click_house(other_id)
	check(demo.neighborhood_editor.selected_ids == [first_id],"second_native_click_removes_only_that_house")
	await click_house(other_id)
	await click_map(demo.neighborhood_editor.name_edit.get_global_rect().get_center())
	var seed_before: String = demo.shown_world.rng.seed_hex
	await type_text("河畔NTYREBK135")
	check(demo.neighborhood_editor.name_edit.text == "河畔NTYREBK135" and demo.neighborhood_editor.opened and not demo.black and demo.shown_world.rng.seed_hex == seed_before and demo.shown_world.buildings.size() == 24 and demo.model.world.pending_actions.is_empty(),"native_chinese_and_global_shortcut_letters_are_text_only")
	await draft_view("00_1440_跨分组逐栋选房命名")
	DisplayServer.window_set_size(Vector2i(800,600))
	await create_timer(0.6).timeout
	await draft_view("01_800_保留逐栋草稿与原生输入框")
	await tap(KEY_ENTER)
	await create_timer(0.2).timeout
	var records: Array = demo.player_neighborhoods.records()
	saved_record = records[0] if not records.is_empty() else {}
	check(records.size() == 1 and saved_record.get("member_ids",[]) == selected and saved_record.get("name","") == "河畔NTYREBK135" and saved_record.get("revision",0) == 1 and not demo.neighborhood_editor.opened,"native_enter_confirms_exact_members_once")
	var disk: Dictionary = demo.CityArchive.latest(demo.archive_directory)
	check(bool(disk["ok"]) and disk["city"]["authorship"] == demo.player_neighborhoods.snapshot(),"confirmation_actively_saves_metadata_without_a_world_event")
	await tap(KEY_K)
	await process_frame
	var saved_button: Button = demo.neighborhood_editor.saved_rows.get_child(0)
	await press_button(saved_button)
	await create_timer(0.4).timeout
	check(demo.neighborhood_editor.record_id == saved_record["id"] and demo.neighborhood_editor.selected_ids == selected,"native_saved_name_reopens_exact_existing_members")
	await click_map(demo.neighborhood_editor.name_edit.get_global_rect().get_center())
	demo.neighborhood_editor.name_edit.select_all()
	await type_text("不保存的草稿")
	await tap(KEY_ESCAPE)
	check(not demo.neighborhood_editor.opened and demo.player_neighborhoods.record(saved_record["id"]) == saved_record,"escape_discards_only_unconfirmed_name_edit")
	# Stop only the device clock briefly, to test a real accepted pending retune
	# without the next writable beat racing this cancellation assertion.
	var renderer_state: Dictionary = demo.clock.renderer.snapshot()
	demo.clock.stop_output()
	var requested: Dictionary = demo.model.submit({"kind":"retune","id":first_id,"midi":55})
	var pending_before: Array = demo.model.world.pending_actions.duplicate(true)
	var sound_before: Array = demo.model.sound_events.duplicate(true)
	await tap(KEY_K)
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	right.position = Vector2(32,180)
	right.global_position = right.position
	Input.parse_input_event(right)
	await process_frame
	check(bool(requested["accepted"]) and not demo.neighborhood_editor.opened and demo.model.world.pending_actions == pending_before and demo.model.sound_events == sound_before,"right_cancel_keeps_actual_pending_retune_and_sound_event")
	demo.clock.start_output(demo.model._mix_frame,{},renderer_state)
	await tap(KEY_F9)
	await create_timer(0.6).timeout
	check(demo.player_neighborhoods.record(saved_record["id"]) == saved_record,"native_f9_restores_the_saved_player_name_and_members")
	check(not demo.neighborhood_labels.labels.is_empty() and demo.neighborhood_labels.visible,"restored_player_name_has_a_visible_real_member_anchor")
	await capture("02_800_读档后的玩家名字")
	if not demo.neighborhood_labels.labels.is_empty(): await click_map(demo.neighborhood_labels.labels[0]["bounds"].get_center())
	await create_timer(0.4).timeout
	check(demo.neighborhood_editor.opened and demo.neighborhood_editor.record_id == saved_record["id"],"native_map_player_name_opens_its_edit")
	await click_house(other_id)
	await click_map(demo.neighborhood_editor.name_edit.get_global_rect().get_center())
	demo.neighborhood_editor.name_edit.select_all()
	await type_text("石桥小街")
	await press_button(demo.neighborhood_editor.confirm_button)
	await process_frame
	var revised: Dictionary = demo.player_neighborhoods.record(saved_record["id"])
	check(revised.get("revision",0) == 2 and revised.get("member_ids",[]) == [first_id] and revised.get("name","") == "石桥小街","native_edit_keeps_identity_updates_name_and_removes_only_selected_member")
	var dna: Dictionary = demo.CityArchive.export_dna(demo.capture_city(),output+"isolated_exports")
	var dna_read: Dictionary = demo.CityArchive.read_dna(dna["path"]) if dna["ok"] else {}
	check(bool(dna_read.get("ok",false)) and dna_read["authorship"] == demo.player_neighborhoods.snapshot(),"actual_demo_city_dna_roundtrip_keeps_revised_authorship")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await create_timer(0.5).timeout
	await tap(KEY_K)
	await press_button(demo.neighborhood_editor.saved_rows.get_child(0))
	await create_timer(0.6).timeout
	await draft_view("03_1440_保存后继续精确修改")
	await tap(KEY_ESCAPE)
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_of_current_city_audio_reach_device")
	var peak := 0.0
	var clipped := 0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1 or absf(sample.y) >= 1: clipped += 1
	check(recording.samples.size() == rate*4 and peak > 0.001 and clipped == 0 and demo.clock.underruns == underruns,"naming_and_reload_keep_nonzero_device_audio_without_clipping_or_new_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"玩家街坊_设备输入.wav")
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"views":views,"initial_record":saved_record,"revised_record":revised,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns,"scope":"One isolated actual GPU/WASAPI city: native individual map clicks across CID, text input, confirm/edit/cancel, .city/F9, map labels and DNA. InputEvent unicode tests native LineEdit text, not the OS IME composition UI. Device PCM is renderer input, not speaker loopback. No human aesthetics/audio/fun verdict."},"\t")+"\n")
	print("ROUND216_PLAYER_NEIGHBORHOODS_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

