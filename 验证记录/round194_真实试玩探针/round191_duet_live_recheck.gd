extends SceneTree
## Two actual authored neighborhoods, ordinary UI and physical WASAPI time.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const Duet = preload("res://scripts/world/authored_duet.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const OUTPUT := "res://验证记录/round194_真实试玩探针/round191_recheck/"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var images: Dictionary = {}
var first_root := ""
var second_root := ""
var start_skips := 0
var recording: LiveRecording

class LiveRecording extends RefCounted:
	var model: ContinuousAudioModel
	var begin := 0
	var end := 0
	var samples := PackedVector2Array()
	func _mix_frame(_state: Dictionary,_at: int,_rate: int) -> Vector2: return Vector2.ZERO
	func prepare_settlement(at: int,rate: int) -> void: model.prepare_settlement(at,rate)
	func close_background_settlement() -> void: model.close_background_settlement()
	func render_block(state: Dictionary,start: int,count: int,rate: int) -> PackedVector2Array:
		var block := model.render_block(state,start,count,rate)
		if start < end and start+count > begin: samples.append_array(block.slice(maxi(0,begin-start),mini(count,end-start)))
		return block

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)
func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	demo._input(event)
func _click(raw: Array) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(Vector2(float(raw[0]),float(raw[1])))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)
func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false
func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	images[name] = demo.get_viewport().get_texture().get_image()
func _site(cid: String) -> Dictionary:
	for site: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(site["community_id"]) == cid: return site
	return {}
func _heard_root(id: String) -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(demo._first_authored_state(id).get("root_heard_retune",false)): return true
	return false
func _wait_for_qualified_authored_relation() -> bool:
	var deadline := Time.get_ticks_msec()+5000
	while Time.get_ticks_msec() < deadline:
		for pair: Dictionary in Duet.relations(demo.shown_world,demo.model.audible_pitches()):
			if bool(pair["root_pair"]) and bool(pair["qualified"]): return true
		await process_frame
	return false
func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_skips = demo.clock.underruns
	var rate := demo.clock.renderer.transport.sample_rate
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","real_window_and_device")
	_key(KEY_P)
	var guide = demo.planning_guide
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site := _site("west-2")
	_click(site["position"])
	guide.confirm.emit_signal("pressed")
	guide.actions.get_child(3).emit_signal("pressed")
	var public_boundary := demo.model.next_boundary
	_click(site["position"])
	check(await _until(public_boundary+rate/5),"first_public_place_reaches_device_boundary")
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty(),"first_voice_has_no_default_choice")
	demo.expression_choices["deep"].emit_signal("pressed")
	demo.expression_listen.emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started,"first_direction_has_actual_audition")
	var root_boundary := demo.model.next_boundary
	demo.expression_confirm.emit_signal("pressed")
	check(await _until(root_boundary+rate/5),"first_voice_becomes_real_house")
	first_root = str(demo._first_authored_state().get("root_id",""))
	check(demo._begin_authored_theme(first_root),"first_author_theme_opens")
	if first_root.is_empty() or not failures.is_empty(): await _finish(); return
	demo._choose_note(52)
	check(await _heard_root(first_root),"first_authored_E_is_actually_heard")
	demo.model.submit({"kind":"solo","community":"west-2"})
	await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
	demo.first_composition_guide.sync()
	check(demo.first_composition_guide.action == "compose","heard_first_voice_invites_another_composition")
	demo.first_composition_guide.emit_signal("pressed")
	await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
	check(guide.opened and guide.stage == "charter" and guide.scope.is_empty() and guide.plan_id.is_empty(),"second_composition_requires_fresh_choices")
	check(str(demo.model.audible_score()["focused_community"]).is_empty() and str(demo.model.audible_score()["listener_community"]).is_empty(),"second_composition_releases_focus_and_solo")
	guide.cards.get_child(2).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	site = _site("east-2")
	_click(site["position"])
	check(guide.scope == ["east-2"],"player_selects_actual_other_bank")
	guide.confirm.emit_signal("pressed")
	guide.actions.get_child(2).emit_signal("pressed")
	check(not guide.composition_public_hint.is_empty(),"real_public_hint_preserves_space_for_second_voice")
	await _capture("second_public_choice")
	site = guide.composition_public_hint
	public_boundary = demo.model.next_boundary
	_click(site["position"])
	check(await _until(public_boundary+rate/5),"second_public_place_reaches_device_boundary")
	guide.hide_tool()
	_key(KEY_P)
	check(guide.opened and guide.stage == "feedback" and guide.ready_sound_community() == "east-2","P_restores_unfinished_real_sound_choice")
	guide.hide_tool()
	demo.first_composition_guide.sync()
	check(demo.first_composition_guide.action == "sound","light_entry_restores_second_community_sound_choice")
	demo.first_composition_guide.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty() and str(demo.context.get("community_id","")) == "east-2","second_voice_has_real_opposite_site_and_no_default")
	var candidates: Array = Duet.candidates(demo.shown_world,first_root,"east-2",1)
	check(not candidates.is_empty() and candidates[0]["position"] == demo.context["position"],"second_voice_uses_actual_cross_bank_street_opportunity")
	await _capture("second_sound_choice")
	demo.expression_choices["weave"].emit_signal("pressed")
	root_boundary = demo.model.next_boundary
	demo.expression_confirm.emit_signal("pressed")
	check(await _until(root_boundary+rate/5),"second_voice_becomes_real_commercial_house")
	second_root = str(demo._first_authored_state().get("root_id",""))
	check(first_root != second_root and Duet.roots(demo.shown_world).size() == 2,"both_real_authored_families_survive")
	check(demo._composition_title() == "河湾 · 两岸合奏","title_acknowledges_two_authored_sections")
	check(demo._begin_authored_theme(second_root),"second_author_theme_opens")
	if not failures.is_empty(): await _finish(); return
	check(demo.authored_composition_choices.visible,"both_compositions_have_stable_menu_entries")
	demo._choose_note(50)
	check(await _heard_root(second_root),"second_authored_D_is_actually_heard")
	check(Duet.relations(demo.shown_world,demo.model.audible_pitches()).all(func(pair: Dictionary) -> bool: return not bool(pair["root_pair"]) or not bool(pair["qualified"])),"player_D_keeps_the_two_actual_roots_unpaired")
	demo._begin_authored_theme(second_root)
	check((demo.menu.get_meta("notes") as Control).get_child(4).text.contains("呼应"),"A_button_explains_actual_opposite_author_relation")
	await _capture("two_composition_controls")
	demo._choose_note(57)
	check(await _heard_root(second_root),"second_authored_A_is_actually_heard")
	check(await _wait_for_qualified_authored_relation(),"player_A_qualifies_real_root_to_root_relation")
	recording = LiveRecording.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*16
	demo.clock.renderer.source = recording._mix_frame
	demo._listen_authored_duet(first_root)
	var witnessed := false
	deadline = Time.get_ticks_msec()+24000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		for trail: Dictionary in demo.music_activity_layer.trails:
			if str(trail["source_id"]) == first_root and str(demo.shown_world.by_id.get(str(trail["receiver_id"]),{}).get("family_id","")) == str(demo.shown_world.by_id.get(second_root,{}).get("family_id","")):
				evidence["actual_root_reply"] = trail.duplicate(true)
				witnessed = true
				break
		if witnessed: break
	check(witnessed,"real_authored_Lead_Reply_is_seen_after_it_is_heard")
	if witnessed:
		var trail: Dictionary = evidence["actual_root_reply"]
		check(int(trail["onset"])-int(trail["source_onset"]) == rate,"actual_author_reply_delays_exactly_two_beats")
		await _capture("actual_two_bank_reply")
	demo._begin_authored_theme(first_root)
	check(str(demo.context["id"]) == first_root and demo.menu_info.text.contains("深流") and not demo.menu_info.text.contains("织机"),"returning_to_first_voice_shows_its_own_family")
	await _capture("first_composition_kept")
	demo._resume_full_composition()
	await _until(maxi(int(demo.clock.renderer.transport.audible_frame)+rate,demo.model.phrase_frames*8+rate))
	check(str(demo.model.audible_score()["focused_community"]).is_empty() and str(demo.model.audible_score()["listener_community"]).is_empty(),"full_composition_restores_city_rotation")
	await _capture("two_minutes_two_banks")
	check(demo.clock.underruns == start_skips,"physical_composition_has_no_audio_underrun")
	evidence["houses"] = demo.shown_world.buildings.size()
	evidence["authors"] = Duet.roots(demo.shown_world,demo.model.audible_pitches())
	evidence["relations"] = Duet.relations(demo.shown_world,demo.model.audible_pitches())
	evidence["audible_score"] = demo.model.audible_score()
	evidence["audible_frame"] = demo.clock.renderer.transport.audible_frame
	evidence["underruns"] = demo.clock.underruns-start_skips
	await _finish()

func _finish() -> void:
	demo._stop_preview()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for name: String in images: images[name].save_png(OUTPUT+name+".png")
	if recording != null:
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = demo.clock.renderer.transport.sample_rate
		wav.stereo = true
		wav.data = Renderer.pcm16(recording.samples)
		wav.save_to_wav(OUTPUT+"actual_duet_device_input.wav")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Production player controls, actual WASAPI time and device input PCM. No human fun/listening verdict."}
	FileAccess.open(OUTPUT+"live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND191_DUET ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

