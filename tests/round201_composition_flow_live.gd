extends SceneTree
## Device-clock waiting feedback and two player choices without a mandatory retune.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
var output := "res://验证记录/round201_首作节奏/"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var recording: LiveRecording
var auditions: Dictionary = {}

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
func _click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)
func _escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	demo._input(event)
func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+6000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false
func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	demo.get_viewport().get_texture().get_image().save_png(output+name+".png")
func _audition(choice: String,phase: String = "首段") -> void:
	demo.expression_choices[choice].emit_signal("pressed")
	await process_frame
	await process_frame
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started and demo.preview_player.playing,phase+"_"+choice+"_route_click_starts_actual_audition")
	if not demo.preview_started: return
	var variant: Dictionary = demo.expression_comparison["variants"][choice]
	check(demo.preview_player.stream.data == variant["pcm"] and demo.expression_audition_layer.ghost.get("expression","") == choice,phase+"_"+choice+"_playing_pcm_and_visible_house_share_branch")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = demo.clock.renderer.transport.sample_rate
	wav.stereo = true
	wav.data = variant["pcm"]
	wav.save_to_wav(output+phase+"_"+choice+"_点击即试听.wav")
	if not auditions.has(phase): auditions[phase] = {}
	auditions[phase][choice] = {"source_key":demo.expression_comparison["source_key"],"bytes":variant["pcm"].size(),"entry_id":demo.expression_audition_layer.ghost.get("entry_id","")}
	await _capture("试听_"+phase+"_"+choice+"_点击即听")
func _choose_scope(cid: String,plan_index: int) -> Dictionary:
	var guide = demo.planning_guide
	guide.cards.get_child(plan_index).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == cid: site = possible; break
	_click(demo.point(Vector2(float(site["position"][0]),float(site["position"][1]))))
	guide.confirm.emit_signal("pressed")
	return site
func _run() -> void:
	if "--round204-audition" in OS.get_cmdline_user_args(): output = "res://验证记录/round204_点击即试听/"
	if "--round205-placement" in OS.get_cmdline_user_args(): output = "res://验证记录/round205_声音推荐落点/"
	output += "run_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var skips := demo.clock.underruns
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","physical_window_and_audio")
	var guide = demo.planning_guide
	guide.open_tool()
	var site := _choose_scope("west-2",0)
	guide.choose_anchor("none")
	_click(demo.point(Vector2(float(site["position"][0]),float(site["position"][1]))))
	await process_frame
	check(demo.pending_composition_choice.get("kind","") == "none" and demo.caption.text.contains("暂不建设") and demo._show_pending_composition_choice(),"unbuilt_public_choice_explains_its_real_next_step")
	await _capture("01_不建也有下一句_真实等待节拍")
	var frame: int = guide.next_action["expected_boundary_frame"]
	check(await _until(frame+rate/5),"first_charter_reaches_device_boundary")
	check(demo.pending_composition_choice.is_empty() and guide.ready_sound_community() == "west-2","waiting_ends_only_at_actual_heard_charter")
	guide.next_action_button.emit_signal("pressed")
	var before_choices := demo.model.world.snapshot()
	for choice: String in ["deep","weave","warm"]: await _audition(choice)
	check(demo.model.world.snapshot() == before_choices,"route_click_comparison_does_not_submit_city_changes")
	# Reopen to exercise the independent legal fast-confirm path while its new
	# comparison worker is still in flight, after observing all three routes.
	demo._show_context_menu()
	demo.expression_choices["warm"].emit_signal("pressed")
	# Two immediate button presses are legal player input: the asynchronous
	# audition comparison has not returned and has not been played.
	demo.expression_confirm.emit_signal("pressed")
	frame = demo.model.next_boundary
	await process_frame
	await process_frame
	check(demo.expression_audition_layer.queued.is_empty() and demo.pending_composition_choice.get("kind","") == "warm" and demo.caption.text.contains("暖庭已选好"),"confirmation_without_audition_still_has_truthful_wait_feedback")
	check(not demo.expression_audition_layer.pending_marker.is_empty(),"immediate_confirmation_keeps_real_expression_location_marker")
	await _capture("02_暖庭已选好_无需先播放试听")
	check(await _until(frame-rate/10),"reaches_render_ahead_before_root_is_heard")
	await process_frame
	check(demo.model.world.pending_actions.is_empty() and demo.pending_composition_choice.get("kind","") == "warm" and demo._first_authored_state().is_empty(),"render_ahead_keeps_wait_without_claiming_future_author_root")
	check(not demo.expression_audition_layer.pending_marker.is_empty(),"render_ahead_keeps_pending_location_until_heard")
	await _capture("02b_暖庭标记_渲染领先仍待播")
	check(await _until(frame+rate/4),"first_author_root_reaches_device_boundary")
	var work := demo._first_authored_state()
	var first_root := str(work.get("root_id",""))
	check(not first_root.is_empty() and not bool(work["retuned"]) and demo.first_composition_guide.visible and demo.first_composition_guide.action == "authored" and demo.first_composition_guide.text.contains("改音与继续"),"new_author_root_has_reentry_without_maturity_or_retune_gate")
	check(demo.pending_composition_choice.is_empty(),"heard_root_finishes_wait_feedback")
	check(demo.expression_audition_layer.pending_marker.is_empty(),"heard_root_clears_pending_location_marker")
	demo.first_composition_guide.emit_signal("pressed")
	check(demo.menu.visible and demo.selected_id == first_root and (demo.menu.get_meta("compose_more") as Control).visible and (demo.menu.get_meta("care_for_land") as Control).visible,"actual_root_menu_offers_notes_land_and_next_segment")
	await _capture("03_根屋刚落成_改音与继续")
	(demo.menu.get_meta("care_for_land") as Button).emit_signal("pressed")
	var kept_id := str(demo.context.get("id",""))
	check(demo.context.get("kind","") == "reservation" and kept_id == str(work["reservation_id"]),"root_menu_locates_its_actual_reserved_land")
	await _capture("04_照看暖庭留下的空地")
	_escape()
	await process_frame
	demo.first_composition_guide.emit_signal("pressed")
	(demo.menu.get_meta("compose_more") as Button).emit_signal("pressed")
	check(guide.opened and guide.stage == "charter" and not bool(demo._first_authored_state()["retuned"]),"player_starts_next_segment_without_a_forced_retune")
	site = _choose_scope("east-2",2)
	guide.choose_anchor("civic")
	_click(demo.point(Vector2(float(site["position"][0]),float(site["position"][1]))))
	frame = int(guide.next_action["expected_boundary_frame"])
	await process_frame
	check(demo.pending_composition_choice.get("kind","") == "civic" and demo.pending_composition_choice.get("community_id","") == "east-2" and demo.caption.text.contains("文化馆已选好"),"next_public_choice_wait_names_opposite_community_and_civic_space")
	await _capture("05_对岸文化馆_同一节拍等待")
	check(await _until(frame+rate/5),"opposite_civic_space_reaches_device_boundary")
	guide.next_action_button.emit_signal("pressed")
	check(demo.expression_choice.is_empty() and not demo.preview_requested,"second_sound_recommendation_does_not_choose_expression")
	if "--round205-placement" in OS.get_cmdline_user_args():
		for choice: String in ["deep","warm","weave"]: await _audition(choice,"第二段")
	else: await _audition("weave","第二段")
	var finish_deadline := Time.get_ticks_msec()+5500
	while Time.get_ticks_msec() < finish_deadline and demo.preview_requested: await process_frame
	check(not demo.preview_requested and not demo.preview_started and not demo.model.synth.ducking,"click_audition_finishes_and_restores_city")
	demo.expression_listen.emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started,"listen_button_replays_actual_weave_after_auto_finish")
	demo.expression_confirm.emit_signal("pressed")
	frame = demo.model.next_boundary
	await process_frame
	check(demo.pending_composition_choice.get("kind","") == "weave" and demo.caption.text.contains("织机已选好"),"auditioned_voice_uses_same_wait_feedback")
	await _capture("06_织机已选好_下一句长出商业")
	recording = LiveRecording.new()
	recording.model = demo.model
	recording.begin = frame
	recording.end = frame+rate*8
	demo.clock.renderer.source = recording._mix_frame
	check(await _until(frame+rate/4),"second_author_root_reaches_device_boundary")
	var second_root := str(demo._first_authored_state().get("root_id",""))
	check(second_root != first_root and demo._composition_title() == "河湾 · 两岸合奏" and not bool(demo._first_authored_state(first_root)["retuned"]),"two_player_segments_exist_without_mandatory_first_retune")
	demo._open_authored_root(first_root)
	await process_frame
	check((demo.menu.get_meta("care_for_land") as Button).visible,"earlier_warm_segment_keeps_its_land_action")
	(demo.menu.get_meta("care_for_land") as Button).emit_signal("pressed")
	check(demo.context.get("kind","") == "reservation" and str(demo.context.get("id","")) == kept_id,"earlier_root_land_action_is_not_replaced_by_latest_family")
	_escape()
	demo._home_city()
	check(await _until(frame+rate*8),"captures_eight_seconds_of_actual_two_segment_output")
	await _capture("07_两岸合奏_自由接续")
	check(demo.clock.underruns == skips,"no_new_audio_underrun")
	var peak := 0.0
	var clipped := 0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1.0 or absf(sample.y) >= 1.0: clipped += 1
	check(recording.samples.size() == rate*8 and clipped == 0,"two_segment_device_input_has_no_clipping")
	var heard := AudioStreamWAV.new()
	heard.format = AudioStreamWAV.FORMAT_16_BITS
	heard.mix_rate = rate
	heard.stereo = true
	heard.data = Renderer.pcm16(recording.samples)
	heard.save_to_wav(output+"两岸合奏_设备输入.wav")
	demo.clock.stop_output()
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"first_root":first_root,"second_root":second_root,"reservation_id":kept_id,"houses":demo.shown_world.buildings.size(),"underruns":demo.clock.underruns-skips,"sample_rate":rate,"samples":recording.samples.size(),"peak":peak,"clipped":clipped,"auditions":auditions},"scope":"Real Windows/OpenGL/WASAPI route-click audition, automatic four-second finish and replay, immediate-confirmation location marker through render-ahead, audible root entry and two segments; no human fun or listening-quality claim."}
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND201_COMPOSITION_FLOW ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
