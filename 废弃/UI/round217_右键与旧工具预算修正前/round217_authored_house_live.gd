extends "res://tests/round216_player_neighborhoods_live.gd"
## One new authored house, then its native return/retune/continue journey.
var author_layouts: Array[Dictionary] = []

func card_view(label: String,id: String) -> void:
	await create_timer(0.55).timeout
	var card = demo.authored_house_card
	var panel: Rect2 = demo.menu.get_global_rect()
	var sprite: Sprite2D = demo.sprites[id]
	var box := sprite.get_rect()
	var bounds := Rect2(sprite.to_global(box.position),box.size*sprite.scale*demo.view_zoom)
	check(panel.size.x <= 357 and panel.size.x >= 355 and Rect2(Vector2.ZERO,demo.size).encloses(panel),label+"_356_native_panel_inside_window")
	check(card.scale == Vector2.ONE and not demo.core_slice_hud.legend_visible and card.thumbnail.texture == sprite.texture,label+"_native_type_real_angle_and_no_duplicate_legend")
	check(not bounds.intersects(panel) and Rect2(Vector2(0,90),demo.size-Vector2(0,148)).encloses(bounds),label+"_full_actual_roof_and_door_are_clear")
	author_layouts.append({"label":label,"panel":str(panel),"house":str(bounds),"heard":card.heard_label.text,"pending":card.pending_label.text,"name":card.place_label.text})
	await capture(label)

func _run() -> void:
	output = "res://验证记录/round217_作者回访_集成/live_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.archive_directory = output+"isolated_archives"
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","actual_gpu_wasapi")
	check(await until_frame(rate*5),"opening_reaches_device")
	check(demo._begin_first_sound_choice("west-2"),"existing_legitimate_sound_entry")
	await create_timer(0.6).timeout
	await press_button(demo.expression_choices["warm"])
	await tap(KEY_ENTER)
	var boundary := int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(boundary > 0 and await until_frame(boundary+rate*2),"real_warm_house_is_heard_and_revealed")
	var work: Dictionary = demo._first_authored_state()
	var id := str(work.get("root_id",""))
	if id.is_empty():
		check(false,"actual_author_root_exists")
		quit(1)
		return
	var members: Array[String] = [id]
	var named: Dictionary = demo.player_neighborhoods.confirm(demo.shown_world,demo.clock.renderer.transport.audible_frame,members,"橄榄庭街")
	check(named["ok"],"actual_player_named_house_fixture")
	check(await click_house(id) and demo.menu.visible and demo._compact_authored_card(),"native_actual_house_opens_new_card")
	check(demo.authored_house_card.place_label.text == "橄榄庭街" and demo.authored_house_card.land_button.visible,"own_name_and_real_land_are_available")
	await card_view("00_800_你的暖庭与真实门面",id)
	var solo := str(demo.model.audible_score().get("listener_community",""))
	var focus_before := root.gui_get_focus_owner()
	await tap(KEY_TAB)
	check(root.gui_get_focus_owner() != focus_before and demo.authored_house_card.is_ancestor_of(root.gui_get_focus_owner()) and str(demo.model.audible_score().get("listener_community","")) == solo,"native_tab_stays_in_card_and_keeps_listening")
	await press_button(demo.authored_house_card.tools_button)
	check(demo.authored_card_advanced and (demo.menu.get_meta("legacy_shell") as Control).visible and not demo.authored_house_card.visible,"more_tools_preserves_legacy_shell")
	await press_button(demo.menu.get_meta("back_to_house"))
	check(demo._compact_authored_card() and demo.authored_house_card.visible,"native_back_returns_to_compact_card")
	await press_button(demo.authored_house_card.land_button)
	check(demo.context.get("kind","") == "reservation" and demo.context.get("id","") == work["reservation_id"],"native_land_targets_this_authored_family")
	await tap(KEY_ESCAPE)
	check(await click_house(id),"native_return_after_land")
	await press_button(demo.authored_house_card.naming_button)
	check(demo.neighborhood_editor.opened and demo.neighborhood_editor.selected_ids == members,"native_name_initially_selects_only_this_house")
	await tap(KEY_ESCAPE)
	check(await click_house(id),"native_return_after_name_cancel")
	var old_pitch := int(demo.model.audible_pitches().get(id,demo.shown_world.by_id[id]["current_midi"]))
	var base := 55 if posmod(old_pitch,12) != 7 else 52
	var pitch := demo._note_pitch(base)
	await press_button(demo.authored_house_card.note_buttons[base])
	check(not demo.menu.visible and demo.model.decisions[-1]["operation"].get("id","") == id and demo.model.decisions[-1]["operation"].get("midi",-1) == pitch,"native_note_requests_this_house_and_auto_closes")
	var sound_frame := int(demo.model.decisions[-1]["sound_frame"])
	demo._open_authored_root(id)
	check(demo.authored_house_card.heard_label.text.contains(demo.note_name(old_pitch)) and not demo.authored_house_card.pending_label.text.is_empty(),"before_heard_beat_card_keeps_old_note_and_shows_pending")
	await capture("01_800_改音已排队_已听与待播分开")
	check(await until_frame(sound_frame+rate/5),"actual_retune_reaches_device")
	await process_frame
	check(int(demo.model.audible_pitches().get(id,-1)) == pitch and demo.authored_house_card.heard_label.text == "已听 · %s%d" % [demo.note_name(pitch),pitch/12-1] and demo.authored_house_card.pending_label.text.is_empty(),"heard_beat_updates_note_and_clears_pending")
	await card_view("02_800_已经听到你的改音",id)
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_reach_actual_wasapi")
	var peak := 0.0
	var clipped := 0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1 or absf(sample.y) >= 1: clipped += 1
	check(recording.samples.size() == rate*4 and peak > 0.001 and clipped == 0 and demo.clock.underruns == underruns,"actual_pcm_no_clipping_or_new_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"你的暖庭改音_设备输入.wav")
	await tap(KEY_ESCAPE)
	DisplayServer.window_set_size(Vector2i(1440,900))
	await create_timer(0.3).timeout
	check(await click_house(id),"native_large_window_return")
	await card_view("03_1440_作者回访与石街",id)
	demo.authored_house_card.next_button.grab_focus()
	await tap(KEY_ENTER)
	check(demo.planning_guide.opened and not demo.menu.visible and demo.composition_source_id == id,"native_enter_continues_the_actual_authored_source")
	await capture("04_1440_继续下一段发展方向")
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"layouts":author_layouts,"root_id":id,"old_pitch":old_pitch,"pitch":pitch,"sound_frame":sound_frame,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underrun_delta":demo.clock.underruns-underruns},"\t")+"\n")
	print("ROUND217_LIVE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
