extends "res://tests/round209_classical_night_live.gd"
## One production UI audition lifecycle, both river banks and real input.
var layouts: Array[Dictionary] = []

func key_event(key: int,pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)

func tap(key: int) -> void:
	key_event(key,true)
	await process_frame
	key_event(key,false)
	await process_frame

func press_button(button: Control) -> void:
	var at := button.get_global_rect().get_center()+Vector2(35,0)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		await process_frame

func playing() -> bool:
	var deadline := Time.get_ticks_msec()+8000
	while not demo.preview_started and Time.get_ticks_msec() < deadline: await process_frame
	return demo.preview_started and demo.preview_player.playing

func drain_worker() -> void:
	var deadline := Time.get_ticks_msec()+8000
	while demo.preview_thread != null and Time.get_ticks_msec() < deadline: await process_frame
	await process_frame

func layout(label: String) -> void:
	var panel := demo.menu.get_global_rect()
	var raw: Array = demo.context["position"]
	var at := Vector2(float(raw[0]),float(raw[1]))
	var target := demo.point(at)
	var bounds := Rect2(target-Vector2(90,100),Vector2(180,170))
	check(panel.size.x >= 348 and panel.size.x <= 366,label+"_compact_actual_panel")
	check(Rect2(Vector2.ZERO,demo.size).encloses(panel) and Rect2(Vector2.ZERO,demo.size).encloses(bounds) and not panel.intersects(bounds),label+"_whole_actual_target_and_panel_visible")
	check(demo.first_sound_focus.visible and demo.first_sound_focus.state["world_position"].is_equal_approx(at) and not panel.intersects(demo.first_sound_focus.state["badge"]),label+"_true_parcel_community_focus")
	check(demo.core_slice_hud.visible and not demo.core_slice_hud.legend_visible and not demo.community_label_layer.visible,label+"_title_retained_and_duplicate_legend_hidden")
	layouts.append({"label":label,"window":str(demo.size),"panel":str(panel),"target":str(bounds),"position":raw,"orientation":demo._street_orientation(at),"selected":demo.expression_choice})

func _run() -> void:
	output = "res://验证记录/round211_声音选择舞台/run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","actual_windows_gpu_and_audio")
	check(await until_frame(rate*5),"opening_reaches_device")
	check(demo.shown_world.buildings.size() == 24,"unchanged_actual_24_house_opening")
	check(demo._begin_first_sound_choice("west-2"),"actual_west_production_sound_entry")
	await create_timer(0.7).timeout
	layout("west_800_empty")
	check(demo.expression_choice.is_empty() and demo.expression_confirm.disabled and demo.expression_listen.disabled,"no_automatic_choice_or_confirmation")
	await capture("00_800_声音选择与真实落点")
	var before := demo.model.world.snapshot()
	var listener: String = demo.model.synth.listener_community
	await tap(KEY_TAB)
	check(root.gui_get_focus_owner() == demo.expression_choices["weave"] and demo.model.synth.listener_community == listener,"native_tab_moves_card_focus_without_city_solo")
	await press_button(demo.expression_choices["weave"])
	await press_button(demo.expression_choices["warm"])
	check(await playing(),"rapid_real_card_switch_plays_current_warm")
	check(demo.expression_choice == "warm" and demo.expression_choices["warm"].button_pressed and not demo.expression_choices["weave"].button_pressed and demo.expression_choices["warm"].listening,"unique_actual_selected_and_listening_card")
	check(demo.preview_player.stream.data == demo.expression_comparison["variants"]["warm"]["pcm"] and is_equal_approx(demo.preview_player.stream.get_length(),4.0),"actual_selected_context_four_second_pcm")
	var preview := demo.preview_player.stream as AudioStreamWAV
	preview.save_to_wav(output+"暖庭_实际四秒试听.wav")
	await create_timer(0.8).timeout
	var status: Dictionary = demo.expression_status.state.duplicate()
	check(bool(status.get("playing",false)) and float(status.get("progress",-1)) > 0.0 and absf(float(status.get("elapsed",-1))-(demo.preview_player.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())) < 0.12,"footer_progress_reads_actual_player")
	check(demo.first_sound_focus.state.get("ghost_current",false) and demo.expression_audition_layer.ghost.get("expression","") == "warm","accepted_warm_ghost_uses_same_actual_parcel")
	await capture("01_800_暖庭真实试听与播放进度")
	var deadline := Time.get_ticks_msec()+6000
	while demo.preview_requested and Time.get_ticks_msec() < deadline: await process_frame
	check(not demo.preview_requested and not demo.preview_player.playing and not demo.preview_duck_owned and demo.expression_choice == "warm" and demo.expression_choices["warm"].button_pressed and not demo.expression_choices["warm"].listening,"full_four_seconds_finish_and_restore_city_keep_choice")
	check(demo.model.world.snapshot() == before,"card_selection_and_full_audition_do_not_write_world")
	DisplayServer.window_set_size(Vector2i(1440,900))
	await create_timer(0.7).timeout
	layout("west_1440_selected")
	await capture("02_1440_保留选择与古典街坊")
	await tap(KEY_ENTER)
	var boundary := int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(boundary > 0 and not demo.menu.visible and demo.model.world.pending_actions.size() == 1,"enter_submits_one_actual_chosen_seed")
	check(await until_frame(boundary+rate),"confirmed_author_house_reaches_actual_device")
	var root_id := str(demo._first_authored_state().get("root_id",""))
	check(not root_id.is_empty() and demo.shown_world.by_id.has(root_id) and demo.shown_world.by_id[root_id]["expression"] == "warm" and not demo.first_sound_focus.visible,"heard_chosen_house_clears_menu_focus")
	await capture("03_暖庭落成后回到城市")
	check(demo._begin_first_sound_choice("east-2"),"actual_east_production_sound_entry")
	await create_timer(0.7).timeout
	layout("east_1440_empty")
	DisplayServer.window_set_size(Vector2i(800,600))
	await create_timer(0.7).timeout
	layout("east_800_empty")
	await capture("04_800_对岸声音选择与地块")
	before = demo.model.world.snapshot()
	await press_button(demo.expression_choices["warm"])
	await press_button(demo.menu.get_meta("expression_back"))
	await drain_worker()
	check(not demo.menu.visible and not demo.preview_requested and not demo.preview_player.playing and not demo.preview_duck_owned and not demo.first_sound_focus.visible,"back_cancels_preparing_preview_and_late_result")
	check(demo.model.world.snapshot() == before,"back_without_confirmation_keeps_city")
	check(demo._begin_first_sound_choice("east-2"),"reopen_east_after_cancel")
	await press_button(demo.expression_choices["deep"])
	check(await playing(),"real_deep_preview_for_keyboard_lifecycle")
	key_event(KEY_SPACE,true)
	await process_frame
	key_event(KEY_SPACE,false)
	await process_frame
	check(demo.expression_choice == "deep" and not demo.preview_requested and not demo.preview_player.playing and not demo.preview_duck_owned,"space_release_stops_only_current_preview")
	await press_button(demo.expression_listen)
	check(await playing(),"real_relisten_starts")
	await tap(KEY_B)
	check(demo.black and not demo.menu.visible and not demo.preview_player.playing and not demo.preview_duck_owned and not demo.first_sound_focus.visible,"black_hides_picker_and_immediately_restores_actual_city_audio")
	await tap(KEY_B)
	await drain_worker()
	check(not demo.black and not demo.menu.visible and not demo.preview_player.playing,"return_from_black_does_not_restart_cancelled_preview")
	check(demo.model.world.snapshot() == before,"space_black_and_cancel_do_not_submit_city_choice")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_actual_city_pcm_reach_device")
	var peak := 0.0
	var clipped := 0
	for sample_frame: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample_frame.x),absf(sample_frame.y)))
		if absf(sample_frame.x) >= 1.0 or absf(sample_frame.y) >= 1.0: clipped += 1
	check(recording.samples.size() == rate*4 and clipped == 0 and demo.clock.underruns == underruns,"actual_city_pcm_no_clipping_or_added_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"作者街坊_实际设备输入.wav")
	demo.clock.stop_output()
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"layouts":layouts,"progress":status,"root_id":root_id,"sample_rate":rate,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"underruns":demo.clock.underruns-underruns},"scope":"Windows/OpenGL/WASAPI; native card/Tab/Space/Enter input, full four-second selected preview, true heard author house, preparing/back/black cancellation; two actual river banks at 800 and 1440. Human aesthetic/fun/listening judgement unverified."},"\t")+"\n")
	print("ROUND211_SOUND_STAGE ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
