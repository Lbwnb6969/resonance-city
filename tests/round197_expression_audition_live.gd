extends SceneTree
## One physical first-choice pass: real branches, visible ghosts, queued-to-heard handoff.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round197_声画预影/"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)
func _click(raw: Array) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(Vector2(float(raw[0]),float(raw[1])))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)
func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+5000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false
func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	demo.get_viewport().get_texture().get_image().save_png(OUTPUT+name+".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var skips := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","physical_window_and_audio")
	demo.planning_guide.open_tool()
	var guide = demo.planning_guide
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": site = possible; break
	_click(site["position"])
	guide.confirm.emit_signal("pressed")
	guide.actions.get_child(3).emit_signal("pressed")
	var public_boundary := demo.model.next_boundary
	_click(site["position"])
	check(await _until(public_boundary+rate/5),"anchor_reaches_actual_device_boundary")
	guide.next_action_button.emit_signal("pressed")
	var before := demo.model.world.snapshot()
	demo.expression_choices["deep"].emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline and demo.expression_audition_layer.ghost.is_empty(): await process_frame
	check(not demo.expression_audition_layer.ghost.is_empty() and demo.preview_requested and demo.preview_player.playing,"choosing_auditions_actual_branch_with_house_ghost")
	var entries: Array[String] = []
	var source_key := str(demo.expression_comparison.get("source_key",""))
	for choice: String in ["deep","weave","warm"]:
		demo._cancel_preview_playback()
		demo.expression_choices[choice].emit_signal("pressed")
		await process_frame
		await process_frame
		var variant: Dictionary = demo.expression_comparison["variants"][choice]
		var ghost: Dictionary = demo.expression_audition_layer.ghost
		check(not ghost.is_empty() and ghost["expression"] == choice and ghost["root_id"] == variant["birth"]["building"]["district_id"],choice+"_ghost_uses_accepted_branch_house")
		entries.append(str(ghost.get("entry_id","")))
		await process_frame
		await process_frame
		deadline = Time.get_ticks_msec()+2500
		var heard_pulse: Dictionary = {}
		while Time.get_ticks_msec() < deadline:
			await process_frame
			ghost = demo.expression_audition_layer.ghost
			if not ghost.is_empty() and float(ghost["pulse"]) > 0.35:
				heard_pulse = ghost.duplicate()
				break
		check(not heard_pulse.is_empty() and int(heard_pulse.get("pulse_onset",-1)) <= float(heard_pulse.get("preview_frame",-2)),choice+"_ghost_pulse_follows_playing_branch_event")
		check(demo.preview_player.stream.data == variant["pcm"] and str(demo.expression_comparison["source_key"]) == source_key,choice+"_audition_and_ghost_share_frozen_source")
		evidence[choice] = {"entry_id":ghost.get("entry_id",""),"pulse":heard_pulse.get("pulse",0),"pulse_onset":heard_pulse.get("pulse_onset",-1),"preview_frame":heard_pulse.get("preview_frame",-1),"reservations":variant["consequences"]["reservation_count"]}
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = rate
		wav.stereo = true
		wav.data = variant["pcm"]
		wav.save_to_wav(OUTPUT+choice+"_试听.wav")
		await _capture(choice+"_声画预影")
	check(entries[0] != entries[1] and entries[1] != entries[2] and demo.model.world.snapshot() == before,"three_visual_identities_leave_real_city_unchanged")
	demo.expression_choices["weave"].emit_signal("pressed")
	var operation := demo.PlayerExpression.operation("weave",demo.context["position"])
	var boundary := demo.model.next_boundary
	demo.expression_confirm.emit_signal("pressed")
	await process_frame
	await process_frame
	check(demo.expression_audition_layer.ghost.get("mode","") == "待落成" and not demo.preview_started,"accepted_choice_keeps_its_house_as_queued_ghost")
	await _capture("织机_等待落成")
	var cancel := InputEventMouseButton.new()
	cancel.position = demo.pointer
	cancel.button_index = MOUSE_BUTTON_RIGHT
	cancel.pressed = true
	demo._gui_input(cancel)
	await process_frame
	await process_frame
	check(demo.expression_audition_layer.ghost.is_empty() and demo.model.world.pending_actions.is_empty(),"right_click_withdraws_real_choice_and_its_ghost")
	demo._begin_first_sound_choice("west-2")
	demo.expression_choices["weave"].emit_signal("pressed")
	deadline = Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline and demo.expression_audition_layer.ghost.is_empty(): await process_frame
	operation = demo.PlayerExpression.operation("weave",demo.context["position"])
	boundary = demo.model.next_boundary
	demo.expression_confirm.emit_signal("pressed")
	check(await _until(boundary-2205),"reaches_last_tenth_second_before_birth")
	check(demo.shown_world.buildings.size() == 24 and demo.expression_audition_layer.ghost.get("mode","") == "待落成","ghost_survives_render_ahead_without_claiming_real_birth")
	check(await _until(boundary+rate/5),"authored_house_reaches_audible_boundary")
	var actual_root := ""
	for building: Dictionary in demo.shown_world.buildings:
		if building["position"] == operation["position"] and bool(building.get("player_expression",false)): actual_root = str(building["district_id"])
	check(not actual_root.is_empty() and demo.expression_audition_layer.ghost.is_empty() and demo.expression_audition_layer.arrivals.any(func(row: Dictionary) -> bool: return str(row["id"]) == actual_root),"ghost_hands_off_to_actual_house_and_audible_birth_gesture")
	await _capture("织机_真正落成")
	demo._begin_first_sound_choice("west-2")
	demo.expression_choices["deep"].emit_signal("pressed")
	deadline = Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline and demo.expression_audition_layer.ghost.is_empty(): await process_frame
	var old_comparison_boundary := int(demo.expression_comparison["boundary_frame"])
	check(await _until(old_comparison_boundary+rate/5),"idle_selected_choice_crosses_next_real_phrase")
	deadline = Time.get_ticks_msec()+5000
	while Time.get_ticks_msec() < deadline and int(demo.expression_comparison["boundary_frame"]) <= old_comparison_boundary: await process_frame
	check(int(demo.expression_comparison["boundary_frame"]) > old_comparison_boundary and demo.expression_comparison_key == demo._expression_preview_identity() and not demo.preview_player.playing,"idle_choice_rebuilds_after_boundary_without_autoplay")
	demo.menu.hide()
	demo._home_city()
	await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
	await _capture("作者街面_全景")
	check(demo.clock.underruns == skips,"no_new_audio_underrun")
	evidence["houses"] = demo.shown_world.buildings.size()
	evidence["underruns"] = demo.clock.underruns-skips
	demo._stop_preview()
	demo.clock.stop_output()
	FileAccess.open(OUTPUT+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Actual Windows/WASAPI first-composition controls and branch PCM; screenshots verify style and read-only ghost handoff."},"\t")+"\n")
	print("ROUND197_EXPRESSION_AUDITION ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
