extends SceneTree
## Production route buttons request real ExpressionPreview PCM through Dummy.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round204_点击即试听/contract.json"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _fresh() -> bool:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.first_composition_mode = true
	var community := str(First.opportunities(city)["community_ids"][0])
	return demo._begin_first_sound_choice(community)

func _pump() -> void:
	await process_frame
	demo._process(0.0)

func _preview_ready() -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline:
		await _pump()
		if demo.preview_started and demo.preview_player.playing and not demo.expression_comparison.is_empty(): return true
	return false

func _drain_worker() -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline:
		await _pump()
		if demo.preview_thread == null: return true
	return false

func _await_click_finish() -> bool:
	var deadline := Time.get_ticks_msec()+5500
	while Time.get_ticks_msec() < deadline:
		await _pump()
		if not demo.preview_requested and not demo.preview_started and not demo.preview_player.playing: return true
	return false

func _run() -> void:
	root.size = Vector2i(800,600)
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	check(AudioServer.get_driver_name() == "Dummy","isolated_dummy_driver")
	check(_fresh(),"real_sound_menu_opens")
	await _pump()
	check(demo.menu.visible and demo.expression_choice.is_empty() and demo.expression_confirm.disabled and not demo.preview_requested and not demo.preview_started and not demo.preview_player.playing,"empty_menu_does_not_choose_or_audition")
	var before := demo.model.world.snapshot()
	var rate := int(demo.clock.renderer.transport.sample_rate)
	demo.expression_choices["deep"].emit_signal("pressed")
	check(demo.expression_choice == "deep" and demo.preview_requested and demo.expression_click_preview and demo.preview_thread != null,"route_click_requests_automatic_audition")
	check(demo.model.world.snapshot() == before and demo.model.world.pending_actions.is_empty(),"click_has_no_city_submission")
	var ready := await _preview_ready()
	check(ready,"real_worker_returns_and_starts_selected_pcm")
	if ready:
		var comparison := demo.expression_comparison.duplicate(true)
		var source_key := str(comparison["source_key"])
		check(int(comparison["seconds"]) == 4 and demo.preview_player.stream.data.size() == rate*4*4 and demo.preview_player.stream.data == comparison["variants"]["deep"]["pcm"],"deep_stream_is_actual_four_second_branch")
		for choice: String in ["weave","warm"]:
			demo.expression_choices[choice].emit_signal("pressed")
			check(demo.preview_started and demo.preview_player.playing and demo.preview_player.stream.data == comparison["variants"][choice]["pcm"] and str(demo.expression_comparison["source_key"]) == source_key,"switch_"+choice+"_uses_same_available_source")
		check(demo.model.world.snapshot() == before and demo.model.world.pending_actions.is_empty(),"three_real_auditions_leave_city_and_pending_unchanged")
		check(await _await_click_finish(),"four_second_playback_automatically_finishes")
		check(not demo.model.synth.ducking and not demo.preview_duck_owned,"natural_finish_restores_city_duck")
		demo.expression_listen.emit_signal("pressed")
		check(demo.preview_requested and demo.preview_started and demo.preview_player.playing and demo.preview_player.stream.data == comparison["variants"]["warm"]["pcm"],"listen_button_replays_selected_actual_branch")
		demo.expression_listen.emit_signal("pressed")
		check(not demo.preview_requested and not demo.preview_started and not demo.preview_player.playing and not demo.model.synth.ducking and not demo.preview_duck_owned,"stop_button_restores_city")
		_key(KEY_SPACE)
		await _pump()
		check(demo.preview_requested and not demo.expression_click_preview and demo.preview_player.playing,"space_starts_hold_audition")
		demo.expression_choices["weave"].emit_signal("pressed")
		check(not demo.expression_click_preview and demo.preview_player.stream.data == comparison["variants"]["weave"]["pcm"],"route_switch_during_space_preserves_hold_mode")
		_key(KEY_SPACE,false)
		await _pump()
		check(not demo.preview_requested and not demo.preview_started and not demo.model.synth.ducking,"space_release_restores_city")
		demo.expression_choices["deep"].emit_signal("pressed")
		demo.clock.renderer.transport.rendered_frames = 4*rate+127
		demo.expression_choices["warm"].emit_signal("pressed")
		check(demo.preview_requested and demo.preview_thread != null and not demo.preview_player.playing,"stale_source_switch_stops_old_playback_before_worker")
		check(await _preview_ready(),"replacement_worker_still_starts_new_choice")
		check(demo.expression_choice == "warm" and demo.preview_player.stream.data == demo.expression_comparison["variants"]["warm"]["pcm"] and str(demo.expression_comparison["source_key"]) != source_key,"replacement_stream_has_current_cursor_source")
		demo.expression_listen.emit_signal("pressed")
		evidence["duration_frames"] = rate*4
		evidence["first_source"] = source_key
		evidence["replacement_source"] = str(demo.expression_comparison["source_key"])
	check(_fresh(),"fresh_menu_for_immediate_confirmation")
	var serial_before := int(demo.model.world.action_serial)
	demo.expression_choices["weave"].emit_signal("pressed")
	check(demo.preview_thread != null and demo.expression_comparison.is_empty(),"immediate_confirmation_fixture_has_inflight_worker")
	_key(KEY_ENTER)
	await process_frame
	_key(KEY_ENTER)
	await process_frame
	var authored_pending: Array = demo.model.world.pending_actions.filter(func(op: Dictionary) -> bool: return bool(op.get("player_expression",false)))
	check(not demo.menu.visible and authored_pending.size() == 1 and authored_pending[0]["expression"] == "weave" and int(demo.model.world.action_serial) == serial_before+1,"enter_confirms_only_once_without_waiting_for_pcm")
	check(not demo.preview_requested and not demo.preview_started and not demo.model.synth.ducking,"immediate_confirmation_cancels_audition_intent")
	check(await _drain_worker(),"confirmation_worker_returns")
	check(not demo.preview_requested and not demo.preview_started and not demo.preview_player.playing,"late_confirmation_result_does_not_restart_playback")
	check(_fresh(),"fresh_menu_for_close_before_pcm")
	before = demo.model.world.snapshot()
	demo.expression_choices["warm"].emit_signal("pressed")
	check(demo.preview_thread != null,"close_fixture_has_inflight_worker")
	var expression_box := demo.menu.get_meta("expression_choices") as Control
	(expression_box.get_child(expression_box.get_child_count()-1) as Button).emit_signal("pressed")
	check(not demo.menu.visible and not demo.preview_requested,"back_button_closes_and_cancels_intent")
	check(await _drain_worker(),"closed_menu_worker_returns")
	check(not demo.preview_started and not demo.preview_player.playing and not demo.model.synth.ducking and demo.model.world.snapshot() == before and demo.model.world.pending_actions.is_empty(),"closed_menu_late_pcm_neither_replays_nor_submits")
	evidence["sample_rate"] = rate
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Dummy production Demo, actual ExpressionPreview worker and four-second playback lifecycle. No device output, screenshots, or human listening verdict."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND204_EXPRESSION_CLICK_AUDITION ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo._stop_preview()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
