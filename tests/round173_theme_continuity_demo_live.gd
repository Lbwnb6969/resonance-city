extends SceneTree
## Round 173: retune through real P/source/note controls exactly when a
## mature theme source next sings. Only the production output advances time.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT_DIRECTORY := "res://验证记录/round173_主题改音衔接"
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

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	demo._input(event)

func _button_with_text(parent: Node,text: String) -> Button:
	for child in parent.get_children():
		if child is Button and str(child.text) == text: return child
		var nested := _button_with_text(child,text)
		if nested != null: return nested
	return null

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

func _marks() -> Array:
	return demo.music_activity_layer.get("marks")

func _snapshot() -> Dictionary:
	var af := float(demo.music_activity_layer.get("audible_frame"))
	return {"audible_frame":af,"device_frame":demo.clock.renderer.transport.audible_frame,
		"rendered_frame":demo.model.rendered_until,"actual_rows":demo.model.audible_music_activity(af),
		"marks":_plain(_marks()),"phrase":demo.shown_world.phrase_index,
		"buildings":demo.shown_world.buildings.size(),"underruns":demo.clock.underruns}

func _marks_match_actual() -> bool:
	var af := float(demo.music_activity_layer.get("audible_frame"))
	if af > float(demo.clock.renderer.transport.audible_frame): return false
	var actual: Dictionary = {}
	for row in demo.model.audible_music_activity(af): actual[str(row["event_id"])] = row
	for mark: Dictionary in _marks():
		var id := str(mark.get("event_id",""))
		if not actual.has(id): return false
		var row: Dictionary = actual[id]
		var performer := str(row["source_id"] if int(row["generation"]) == 0 else row["receiver_id"])
		if str(mark.get("performer_id","")) != performer or not demo.shown_world.by_id.has(performer): return false
		if int(mark["pitch"]) != int(row["pitch"]) or int(mark["onset"]) != int(row["onset"]): return false
		if af < int(row["onset"]) or af >= int(row["end_frame"]): return false
		if af < int(row["render_start"]) or af >= int(row["render_end"]): return false
		if af-float(row["onset"]) > float(demo.clock.renderer.transport.sample_rate)*0.55: return false
		var position: Array = demo.shown_world.by_id[performer]["position"]
		var expected := demo.point(Vector2(float(position[0]),float(position[1])))
		if (mark["position"] as Vector2).distance_to(expected) > 0.01: return false
	return true

func _same_beat_target() -> Dictionary:
	# Schedule is only used to choose a real waiting window. Activity and
	# brightness still have to come from rendered PCM at the device cursor.
	var begin: int = demo.model.rendered_until
	var boundary: int = demo.model.next_boundary
	var rate: int = demo.clock.renderer.transport.sample_rate
	var theme: Dictionary = demo.model.audible_theme()
	var leads: Array[Dictionary] = []
	var replies: Array[Dictionary] = []
	# Search the known deterministic opening's late source/reply pair from the
	# live node schedule. The numbers are assertions for this evidence, never a
	# cursor jump or a hand-rendered event.
	var search_until: int = maxi(boundary,948150+demo.model.beat_frames)
	for node: Dictionary in demo.model.synth.musical_nodes.values():
		if not bool(node.get("active",false)) or str(node["pattern"].get("cid","")) != str(theme.get("cid","")): continue
		for row in demo.model.synth.musical_events(node,begin,maxi(0,search_until-begin),rate):
			if int(row["onset"]) < begin: continue
			if bool(node["answer"]): replies.append(row)
			else: leads.append(row)
	leads.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a["onset"]) < int(b["onset"]))
	replies.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a["onset"]) < int(b["onset"]))
	for lead in leads:
		if str(lead.get("source_id","")) != "building-00006" or int(lead["onset"]) != 948150: continue
		for reply in replies:
			if int(reply["onset"]) == 937125 and int(lead["onset"])-int(reply["onset"]) == demo.model.beat_frames:
				return {"lead":lead,"preceding_reply":reply,"next_boundary":boundary,
					"sample_rate":rate,"opening_rendered_frame":begin}
	for reply in replies:
		for lead in leads:
			if int(lead["onset"])-int(reply["onset"]) == demo.model.beat_frames:
				return {"lead":lead,"preceding_reply":reply,"next_boundary":boundary,
					"sample_rate":rate,"opening_rendered_frame":begin}
	return {}

func _wait_actual_reply_edit_window(target: Dictionary) -> Dictionary:
	var onset := int(target["lead"]["onset"])
	var reply_id := str(target["preceding_reply"]["event_id"])
	var rate: int = demo.clock.renderer.transport.sample_rate
	var seconds := maxf(1.0,(float(onset)-float(demo.clock.renderer.transport.audible_frame))/rate+0.5)
	var deadline := Time.get_ticks_msec()+roundi(seconds*1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame
		await RenderingServer.frame_post_draw
		var af := float(demo.music_activity_layer.get("audible_frame"))
		if af >= onset or demo.model.rendered_until >= onset: return {}
		var writable: int = (demo.model.rendered_until/demo.model.beat_frames+1)*demo.model.beat_frames
		if writable != onset: continue
		for row in demo.model.audible_music_activity(af):
			if str(row["event_id"]) != reply_id or float(row["strength"]) < 0.008: continue
			return {"reply":row.duplicate(true),"audible_frame":af,
				"rendered_frame":demo.model.rendered_until,"next_writable_frame":writable,
				"buffer_ahead_frames":float(demo.model.rendered_until)-af}
	return {}

func _capture(name: String) -> void:
	# Avoid PNG compression while a physical generator queue is playing.
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
		check(end_frame-start_frame >= float(demo.clock.renderer.transport.sample_rate)*0.75,"physical_output_advances_during_real_operation")
		check(demo.clock.underruns == start_skips,"physical_small_city_operation_adds_no_underruns")
		demo.clock.stop_output()
		demo.light_player.stop()
		demo.preview_player.stop()
		await process_frame
		await process_frame
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
		"scope":"Physical WASAPI production default city, late actual Reply, P/source/note callbacks, same-onset first new Lead and surviving previous Reply tail. No manual live render/settle, invented eligibility, later-repeat substitute, human-listening or large-city claim"}
	var file := FileAccess.open(OUTPUT_DIRECTORY+"/theme_continuity_demo_live.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(evidence,"\t")+"\n")
		file.close()
	else: check(false,"live_json_saved")
	print("ROUND173_THEME_CONTINUITY_DEMO_LIVE ",JSON.stringify(evidence))
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
	check(demo.clock.active and demo.model.world.phrase_index == 2 and demo.model.world.rng.seed_hex == "2026100900000062" and demo.model.world.terrain.family == "river_valley","production_mature_default_small_city_is_playing")
	check(demo.model.decisions.is_empty() and demo.model.world.pending_actions.is_empty(),"opening_does_not_fabricate_player_decisions")
	var target := _same_beat_target()
	observations["selected_wait_schedule"] = target
	check(not target.is_empty(),"real_mature_score_has_reply_then_next_beat_theme_source")
	if target.is_empty():
		await _finish()
		return
	check(str(target["lead"]["source_id"]) == "building-00006" and int(target["lead"]["onset"]) == 948150 and int(target["preceding_reply"]["onset"]) == 937125,"selected_window_reproduces_round172_first_note_regression")
	var window := await _wait_actual_reply_edit_window(target)
	check(not window.is_empty(),"device_hears_real_late_reply_before_same_beat_edit_window")
	if window.is_empty():
		observations["missed_window"] = _snapshot()
		await _finish()
		return
	observations["actual_reply_edit_window"] = window
	check(_marks_match_actual(),"pre_edit_marks_match_actual_audible_pcm_events")
	await _capture("theme_preceding_reply_live")
	# These are synchronous production callbacks. No synthetic clock changes or
	# artificial source selection are inserted between P and the note button.
	_key(KEY_P)
	var rework: Button = demo.planning_guide.get("theme_rework_button") as Button
	check(demo.planning_guide.opened and rework != null and rework.is_visible_in_tree() and not rework.disabled,"production_p_opens_real_theme_rework_shortcut")
	if rework == null or rework.disabled:
		await _finish()
		return
	var decision_count: int = demo.model.decisions.size()
	rework.emit_signal("pressed")
	var source_id := str(demo.selected_id)
	check(source_id == str(target["lead"]["source_id"]) and demo.model.audible_theme().get("source_ids",[]).has(source_id) and demo.menu.visible and demo.context.get("kind","") == "retune" and demo.context.get("id","") == source_id,"real_shortcut_selects_the_upcoming_source_house")
	check(demo.model.decisions.size() == decision_count and demo.model.world.pending_actions.is_empty(),"source_shortcut_only_locates_without_choosing_music")
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
	check(note_button != null and note_button.is_visible_in_tree(),"real_source_menu_offers_player_note_choice")
	if note_button == null:
		await _finish()
		return
	var requested_frame: int = demo.model.rendered_until
	note_button.emit_signal("pressed")
	var decision: Dictionary = demo.model.decisions.back() if demo.model.decisions.size() > decision_count else {}
	var sound_frame := int(decision.get("sound_frame",-1))
	check(demo.model.decisions.size() == decision_count+1 and decision.get("operation",{}).get("kind","") == "retune" and decision.get("operation",{}).get("id","") == source_id and int(decision.get("operation",{}).get("midi",-1)) == new_pitch,"player_note_submits_one_same_source_retune")
	check(sound_frame == (requested_frame/demo.model.beat_frames+1)*demo.model.beat_frames and sound_frame == int(target["lead"]["onset"]),"real_next_writable_beat_is_exactly_source_first_new_onset")
	edit = {"source_id":source_id,"old_pitch":old_pitch,"new_pitch":new_pitch,
		"requested_frame":requested_frame,"sound_frame":sound_frame,"expected_onset":target["lead"]["onset"]}
	var captured: Dictionary = {}
	var first_actual: Dictionary = {}
	var survived_reply: Dictionary = {}
	var samples: Array[Dictionary] = []
	var queued_observed := false
	var future_mark_leaked := false
	var old_pitch_restarted := false
	var deadline := Time.get_ticks_msec()+2000
	var rate: int = demo.clock.renderer.transport.sample_rate
	while Time.get_ticks_msec() < deadline:
		await process_frame
		await RenderingServer.frame_post_draw
		var af := float(demo.music_activity_layer.get("audible_frame"))
		if af >= float(sound_frame)+rate*0.55: break
		var actual: Array[Dictionary] = demo.model.audible_music_activity(af)
		for row in actual:
			if int(row["generation"]) == 1 and str(row["event_id"]) == str(target["preceding_reply"]["event_id"]) and af >= sound_frame:
				survived_reply = row.duplicate(true)
			if int(row["generation"]) != 0 or str(row["source_id"]) != source_id or int(row["onset"]) != sound_frame: continue
			if not str(row["source_event_id"]).ends_with(":"+str(new_pitch)): old_pitch_restarted = true
			elif first_actual.is_empty(): first_actual = row.duplicate(true)
		var frame_alpha := 0.0
		for mark: Dictionary in _marks():
			if int(mark["generation"]) != 0 or str(mark["source_id"]) != source_id or int(mark["onset"]) != sound_frame or not str(mark["source_event_id"]).ends_with(":"+str(new_pitch)): continue
			frame_alpha = maxf(frame_alpha,float(mark["alpha"]))
			if af < sound_frame: future_mark_leaked = true
			if float(mark["alpha"]) >= CAPTURE_ALPHA and captured.is_empty(): captured = mark.duplicate(true)
		if af < sound_frame and demo.model.rendered_until > sound_frame:
			if not queued_observed: observations["rendered_but_not_audible"] = _snapshot()
			queued_observed = true
		samples.append({"audible_frame":af,"rendered_frame":demo.model.rendered_until,"target_mark_alpha":frame_alpha})
		if not captured.is_empty():
			await _capture("theme_same_onset_new_note_live")
			break
	edit["first_actual_new_event"] = first_actual
	edit["same_onset_mark"] = _plain(captured)
	edit["previous_reply_surviving_after_switch"] = survived_reply
	observations["same_onset_frames"] = samples
	check(queued_observed and not future_mark_leaked,"queued_new_note_waits_for_actual_device_frame")
	check(not first_actual.is_empty() and int(first_actual.get("onset",-1)) == sound_frame and posmod(int(first_actual.get("pitch",-1)),12) == posmod(new_pitch,12),"actual_pcm_trace_contains_first_new_note_on_the_switch_beat")
	check(not captured.is_empty() and float(captured.get("alpha",0.0)) >= CAPTURE_ALPHA and int(captured.get("onset",-1)) == sound_frame,"first_same_beat_new_note_reaches_clear_map_brightness")
	check(not captured.is_empty() and str(captured.get("performer_id","")) == source_id and str(captured.get("note","")) == demo.note_name(new_pitch) and _marks_match_actual(),"clear_same_onset_mark_shows_player_pitch_at_actual_house")
	check(not old_pitch_restarted,"replaced_source_does_not_restart_old_pitch_on_switch_beat")
	check(not survived_reply.is_empty() and int(survived_reply.get("onset",sound_frame)) < sound_frame,"existing_real_reply_tail_survives_the_theme_change")
	check(demo.model.world.phrase_index == 2 and int(demo.model.world.by_id[source_id]["current_midi"]) == old_pitch and demo.model.world.pending_actions.any(func(operation: Dictionary) -> bool: return str(operation.get("kind","")) == "retune" and str(operation.get("id","")) == source_id),"sound_changes_first_and_city_intent_stays_pending_until_real_phrase")
	await _finish()
