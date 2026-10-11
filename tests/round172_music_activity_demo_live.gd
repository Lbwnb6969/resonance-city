extends SceneTree
## Round 172: actual rendered music events, a physical output cursor and map
## marks in one small city. The live world is never settled or rendered by hand.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const OUTPUT_DIRECTORY := "res://验证记录/round172_真实演奏来源"
const CAPTURE_ALPHA := 0.3

var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var screenshots: Dictionary = {}
var observations: Dictionary = {}
var edit: Dictionary = {}
var output_window: Dictionary = {}
var start_frame := 0.0
var start_skips := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _button_with_text(parent: Node,text: String) -> Button:
	for child in parent.get_children():
		if child is Button and str(child.text) == text: return child
		var nested := _button_with_text(child,text)
		if nested != null: return nested
	return null

func _marks() -> Array:
	if not is_instance_valid(demo.music_activity_layer): return []
	return demo.music_activity_layer.get("marks")

func _plain(value: Variant) -> Variant:
	if value is Vector2: return [value.x,value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for field in value: result[str(field)] = _plain(value[field])
		return result
	if value is Array:
		var result: Array = []
		for entry in value: result.append(_plain(entry))
		return result
	return value

func _snapshot() -> Dictionary:
	var af := float(demo.music_activity_layer.get("audible_frame"))
	return {"audible_frame":af,"rendered_frame":demo.clock.renderer.transport.rendered_frames,
		"device_frame":demo.clock.renderer.transport.audible_frame,
		"actual_rows":demo.model.audible_music_activity(af),"marks":_plain(_marks()),
		"layer_visible":demo.music_activity_layer.visible,"black":demo.black,
		"preview_requested":demo.preview_requested,"preview_started":demo.preview_started,
		"phrase":demo.shown_world.phrase_index,"buildings":demo.shown_world.buildings.size(),
		"underruns":demo.clock.underruns}

func _marks_match_actual() -> bool:
	var af := float(demo.music_activity_layer.get("audible_frame"))
	if af > float(demo.clock.renderer.transport.audible_frame): return false
	var rows: Array[Dictionary] = demo.model.audible_music_activity(af)
	var by_event: Dictionary = {}
	for row in rows: by_event[str(row["event_id"])] = row
	for mark: Dictionary in _marks():
		var id := str(mark.get("event_id",""))
		if not by_event.has(id): return false
		var row: Dictionary = by_event[id]
		var performer := str(row["source_id"] if int(row["generation"]) == 0 else row["receiver_id"])
		if str(mark.get("performer_id","")) != performer or not demo.shown_world.by_id.has(performer): return false
		var position: Array = demo.shown_world.by_id[performer]["position"]
		var expected_point := demo.point(Vector2(float(position[0]),float(position[1])))
		if (mark.get("position",Vector2.INF) as Vector2).distance_to(expected_point) > 0.01: return false
		if not Rect2(Vector2.ZERO,demo.size).grow(32.0).has_point(expected_point) or float(mark.get("radius",0.0)) <= 0.0: return false
		if int(mark["pitch"]) != int(row["pitch"]) or int(mark["generation"]) != int(row["generation"]): return false
		if int(mark["onset"]) > af or af >= int(mark["end_frame"]): return false
		if int(mark["render_start"]) > af or af >= int(mark["render_end"]): return false
		if af-float(mark["onset"]) > float(demo.clock.renderer.transport.sample_rate)*0.55: return false
		if float(mark.get("alpha",0.0)) <= 0.0 or str(mark.get("note","")) != demo.note_name(int(row["pitch"])): return false
	return true

func _wait_mark(generation: int,source_id := "",authored_pitch := -1,seconds := 8.0) -> Dictionary:
	var deadline := Time.get_ticks_msec()+roundi(seconds*1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame
		await RenderingServer.frame_post_draw
		for mark: Dictionary in _marks():
			if int(mark.get("generation",-1)) != generation: continue
			if not source_id.is_empty() and str(mark.get("source_id","")) != source_id: continue
			if authored_pitch >= 0 and (posmod(int(mark.get("pitch",-1)),12) != posmod(authored_pitch,12) or not str(mark.get("source_event_id","")).ends_with(":"+str(authored_pitch))): continue
			if float(mark.get("alpha",0.0)) < CAPTURE_ALPHA: continue
			return mark.duplicate(true)
	return {}

func _reply_wait_seconds() -> float:
	# Read the already selected production score solely to budget the wait. Marks
	# still have to arrive through the physical cursor and actual PCM trace.
	var af := float(demo.clock.renderer.transport.audible_frame)
	var rate := int(demo.clock.renderer.transport.sample_rate)
	var boundary := demo.model.next_boundary
	var start := floori(af)
	var wait_until := float(boundary)
	var scheduled_onsets: Array[int] = []
	for node: Dictionary in demo.model.synth.musical_nodes.values():
		if not bool(node.get("answer",false)) or not bool(node.get("active",false)): continue
		var tail_seconds := 0.95 if str(node["pattern"]["expression"]) == "deep" else 0.65
		for event in demo.model.synth.musical_events(node,start,maxi(0,boundary-start),rate):
			var onset := int(event["onset"])
			if onset < start: continue
			scheduled_onsets.append(onset)
			wait_until = maxf(wait_until,float(onset)+tail_seconds*rate)
	scheduled_onsets.sort()
	var seconds := maxf(1.0,(wait_until-af)/rate+0.5)
	observations["reply_wait_window"] = {"audible_frame":af,"next_boundary":boundary,
		"scheduled_reply_onsets":scheduled_onsets,"wait_until_frame":wait_until,
		"maximum_seconds":seconds,"capture_alpha":CAPTURE_ALPHA}
	return seconds

func _capture(name: String) -> void:
	# Call after frame_post_draw when a short-lived mark was found. Store Images
	# only; PNG encoding is deferred until physical output has stopped.
	var image: Image = demo.get_viewport().get_texture().get_image()
	check(image != null and image.get_width() >= 800 and image.get_height() >= 600,name+"_window_draws")
	if image != null: screenshots[name] = image
	observations[name] = _snapshot()

func _finish() -> void:
	if is_instance_valid(demo):
		var end_frame := float(demo.clock.renderer.transport.audible_frame)
		output_window = {"audible_before":start_frame,"audible_after":end_frame,
			"advanced_frames":end_frame-start_frame,"sample_rate":demo.clock.renderer.transport.sample_rate,
			"underruns_before":start_skips,"underruns_after":demo.clock.underruns}
		check(end_frame-start_frame >= float(demo.clock.renderer.transport.sample_rate)*0.75,"physical_cursor_advances_during_window_verification")
		check(demo.clock.underruns == start_skips,"small_city_live_verification_adds_no_underruns")
		demo.clock.stop_output()
		demo.light_player.stop()
		demo.preview_player.stop()
		await process_frame
		await process_frame
		check(not demo.music_activity_layer.visible and _marks().is_empty(),"stopped_output_clears_city_music_marks")
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	var screenshot_paths: Dictionary = {}
	for name in screenshots:
		var path := OUTPUT_DIRECTORY+"/"+str(name)+".png"
		check(screenshots[name].save_png(path) == OK,str(name)+"_screenshot_saved")
		screenshot_paths[name] = path
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"observations":observations,"edit":edit,"output_window":output_window,
		"screenshots":screenshot_paths,"display_backend":DisplayServer.get_name(),
		"audio_driver":AudioServer.get_driver_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"engine":Engine.get_version_info()["string"],
		"scope":"One production mature default city, physical WASAPI clock, rendered Lead/Reply marks, P/source/note callbacks, B and held Space. No fabricated eligibility, manual settlement, future-PCM map activity, large-city performance or human-listening claim"}
	var file := FileAccess.open(OUTPUT_DIRECTORY+"/music_activity_demo_live.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(evidence,"\t")+"\n")
		file.close()
	else:
		check(false,"live_json_saved")
		evidence["passed"] = false
	print("ROUND172_MUSIC_ACTIVITY_DEMO_LIVE ",JSON.stringify(evidence))
	if is_instance_valid(demo): demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = float(demo.clock.renderer.transport.audible_frame)
	start_skips = demo.clock.underruns
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","real_window_uses_physical_wasapi")
	check(demo.clock.active and demo.clock.playback != null and demo.model.world.phrase_index == 2 and demo.model.world.rng.seed_hex == "2026100900000062" and demo.model.world.terrain.family == "river_valley","production_default_mature_small_city_is_playing")
	check(is_instance_valid(demo.music_activity_layer) and demo.model.music_activity != null,"production_enables_actual_music_activity_before_live_rendering")
	var score: Dictionary = demo.model.audible_score()
	var theme: Dictionary = score.get("theme",{})
	check(not theme.is_empty() and bool(MusicRules.status(demo.shown_world,str(theme.get("cid",""))).get("theme_eligible",false)),"opening_theme_has_natural_mature_conditions")
	check(not score.get("response",{}).is_empty() and demo.model.synth.response_enabled,"opening_response_uses_real_cross_river_pairing")

	var lead := await _wait_mark(0,"",-1,5.0)
	check(not lead.is_empty(),"real_audible_lead_reaches_map_source")
	if not lead.is_empty():
		check(str(lead["performer_id"]) == str(lead["source_id"]) and demo.shown_world.by_id.has(str(lead["source_id"])) and int(lead["generation"]) == 0 and lead.get("role","") == "lead","lead_mark_belongs_to_actual_source_house_with_lead_style")
		check(_marks_match_actual(),"lead_mark_is_short_and_matches_audible_rendered_pcm_event")
		await _capture("music_lead_live")

	# Rework while the player first sees the theme. Waiting for a late paired
	# reply first can put the edit exactly on its source's next onset/fade ramp.
	_key(KEY_P)
	await process_frame
	var rework: Button = demo.planning_guide.get("theme_rework_button") as Button
	check(demo.planning_guide.opened and rework != null and rework.is_visible_in_tree() and not rework.disabled,"production_p_exposes_real_theme_source_shortcut")
	if rework == null or rework.disabled:
		await _finish()
		return
	rework.emit_signal("pressed")
	var source_id := str(demo.selected_id)
	check(demo.context.get("kind","") == "retune" and demo.context.get("id","") == source_id and demo.menu.visible and theme.get("source_ids",[]).has(source_id),"source_shortcut_opens_existing_house_pitch_menu")
	if not demo.shown_world.by_id.has(source_id):
		await _finish()
		return
	var old_pitch := int(demo.shown_world.by_id[source_id]["current_midi"])
	var choice := 52
	var new_pitch := choice-12 if demo.low_octave.button_pressed else choice
	if new_pitch == old_pitch:
		choice = 55
		new_pitch = choice-12 if demo.low_octave.button_pressed else choice
	var note_button := _button_with_text(demo.menu,"暖和 · E" if choice == 52 else "开阔 · G")
	check(note_button != null and note_button.is_visible_in_tree(),"real_house_pitch_choice_is_available")
	if note_button == null:
		await _finish()
		return
	var decision_count := demo.model.decisions.size()
	var requested_frame := demo.model.rendered_until
	note_button.emit_signal("pressed")
	var decision: Dictionary = demo.model.decisions.back() if demo.model.decisions.size() > decision_count else {}
	var sound_frame := int(decision.get("sound_frame",-1))
	check(demo.model.decisions.size() == decision_count+1 and decision.get("operation",{}).get("kind","") == "retune" and decision.get("operation",{}).get("id","") == source_id and int(decision.get("operation",{}).get("midi",-1)) == new_pitch,"pitch_button_submits_same_real_source_retune")
	check(sound_frame == (requested_frame/demo.model.beat_frames+1)*demo.model.beat_frames,"player_pitch_uses_next_writable_real_beat")
	var tuned := await _wait_mark(0,source_id,new_pitch,10.0)
	check(not tuned.is_empty(),"same_real_source_sings_player_pitch_and_displays_new_note")
	if not tuned.is_empty():
		check(int(tuned["onset"]) >= sound_frame and str(tuned["performer_id"]) == source_id and str(tuned["note"]) == demo.note_name(new_pitch) and _marks_match_actual(),"retuned_source_mark_follows_actual_audible_event")
		await _capture("music_retuned_source_live")
	edit = {"source_id":source_id,"old_pitch":old_pitch,"new_pitch":new_pitch,
		"requested_frame":requested_frame,"sound_frame":sound_frame,"tuned_mark":_plain(tuned)}

	var reply := await _wait_mark(1,"",-1,_reply_wait_seconds())
	check(not reply.is_empty(),"real_audible_reply_reaches_map_receiver")
	if not reply.is_empty():
		check(str(reply["performer_id"]) == str(reply["receiver_id"]) and demo.shown_world.by_id.has(str(reply["receiver_id"])) and str(reply["receiver_id"]) != str(reply["source_id"]) and reply.get("role","") == "reply" and int(reply["onset"])-int(reply["source_onset"]) == 2*demo.model.beat_frames,"reply_mark_uses_actual_receiver_after_two_beats_with_reply_style")
		check(_marks_match_actual(),"reply_mark_matches_actual_pcm_instead_of_future_schedule")
		await _capture("music_reply_live")

	var before_black := float(demo.clock.renderer.transport.audible_frame)
	_key(KEY_B)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(demo.black and not demo.music_activity_layer.visible and _marks().is_empty(),"production_black_listening_hides_city_music_marks")
	await _capture("music_black_listening_live")
	await create_timer(0.3).timeout
	check(demo.clock.active and float(demo.clock.renderer.transport.audible_frame)-before_black >= float(demo.clock.renderer.transport.sample_rate)*0.18,"black_listening_keeps_physical_audio_running")
	_key(KEY_B)
	await process_frame
	await process_frame
	check(not demo.black and demo.music_activity_layer.visible,"production_b_restores_city_activity_layer")

	var before_preview := float(demo.clock.renderer.transport.audible_frame)
	var preview_decisions := demo.model.decisions.size()
	_key(KEY_SPACE)
	check(demo.preview_requested,"held_space_requests_production_future_pcm_preview")
	var preview_deadline := Time.get_ticks_msec()+15000
	while not demo.preview_started and Time.get_ticks_msec() < preview_deadline:
		await process_frame
	check(demo.preview_started and demo.preview_player.playing,"production_future_preview_reaches_physical_player")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(demo.preview_started and not demo.music_activity_layer.visible and _marks().is_empty(),"future_preview_hides_current_city_activity_instead_of_visualizing_forecast")
	await _capture("music_preview_hidden_live")
	check(demo.model.decisions.size() == preview_decisions,"future_preview_does_not_submit_a_city_decision")
	_key(KEY_SPACE,false)
	await process_frame
	await process_frame
	check(not demo.preview_requested and not demo.preview_started and not demo.preview_player.playing and demo.music_activity_layer.visible,"releasing_space_restores_original_live_activity_layer")
	check(demo.clock.active and float(demo.clock.renderer.transport.audible_frame) > before_preview and _marks_match_actual(),"original_physical_cursor_continues_and_only_current_actual_events_return")
	observations["preview_released"] = _snapshot()
	await _finish()
