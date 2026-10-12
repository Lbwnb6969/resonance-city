extends SceneTree
## Physical first-play pass through skip-anchor, real authorship and direct map re-entry.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const OUTPUT := "res://验证记录/round198_自由首作/"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
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
func _click_at(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)
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
	check(demo.shown_world.buildings.size() == 24 and demo.authored_voice_badges.badges.is_empty(),"fresh_city_has_no_invented_author_signature")
	await _until(rate*5+rate/5)
	await _capture("01_隔离新河湾")
	var guide = demo.planning_guide
	guide.open_tool()
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": site = possible; break
	_click_at(demo.point(Vector2(float(site["position"][0]),float(site["position"][1]))))
	guide.confirm.emit_signal("pressed")
	guide.actions.get_child(1).emit_signal("pressed")
	var boundary := demo.model.next_boundary
	_click_at(demo.point(Vector2(float(site["position"][0]),float(site["position"][1]))))
	check(not guide.opened and guide.ready_sound_community().is_empty(),"skip_waits_for_its_actual_charter_boundary")
	check(demo.model.world.pending_actions.all(func(op: Dictionary) -> bool: return op["kind"] == "charter"),"skip_queues_no_fake_anchor_or_birth")
	await _capture("02_暂不建设_等待真实章程")
	check(await _until(boundary+rate/5),"charter_reaches_actual_device_boundary")
	check(guide.ready_sound_community() == "west-2" and guide.stage == "feedback","skip_hands_selected_community_to_sound")
	check(demo.shown_world.public_sites.all(func(row: Dictionary) -> bool: return not row.get("active",false)) and demo.shown_world.planning_reservations.is_empty() and demo.shown_world.buildings.size() == 24,"skipping_really_leaves_public_space_unbuilt")
	guide.hide_tool()
	await process_frame
	demo.first_composition_guide.sync()
	check(demo.first_composition_guide.visible and demo.first_composition_guide.action == "sound","light_entry_restores_skipped_anchor_sound_step")
	guide.open_tool()
	check(guide.stage == "feedback" and guide.ready_sound_community() == "west-2","P_panel_restores_same_unfinished_sound_step")
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty() and demo.context["community_id"] == "west-2","player_chooses_sound_without_a_default")
	check(demo.expression_choices["warm"].text.contains("暖庭") and not demo.expression_choices["warm"].text.contains("留地"),"warm_route_is_distinct_from_land_reservation")
	demo.expression_choices["warm"].emit_signal("pressed")
	demo.expression_listen.emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started,"warm_garden_plays_the_real_next_phrase")
	await _capture("03_暖庭_真实声音与住宅预影")
	var variant: Dictionary = demo.expression_comparison["variants"]["warm"]
	var audition := AudioStreamWAV.new()
	audition.format = AudioStreamWAV.FORMAT_16_BITS
	audition.mix_rate = rate
	audition.stereo = true
	audition.data = variant["pcm"]
	audition.save_to_wav(OUTPUT+"暖庭_真实试听.wav")
	boundary = demo.model.next_boundary
	recording = LiveRecording.new()
	recording.model = demo.model
	recording.begin = boundary
	recording.end = boundary+rate*10
	demo.clock.renderer.source = recording._mix_frame
	demo.expression_confirm.emit_signal("pressed")
	check(await _until(boundary-rate/10),"reaches_render_ahead_before_audible_birth")
	check(demo.authored_voice_badges.badges.is_empty(),"signature_never_claims_a_future_rendered_house")
	check(await _until(boundary+rate/3),"author_house_reaches_audible_boundary")
	var work := demo._first_authored_state()
	var root_id := str(work.get("root_id",""))
	check(not root_id.is_empty() and demo.authored_voice_badges.badges.size() == 1 and demo.authored_voice_badges.badges[0]["root_id"] == root_id,"actual_authored_root_gets_its_own_clickable_signature")
	await _capture("04_暖庭_根屋与真实留地")
	var before := demo.model.world.snapshot()
	var badge: Dictionary = demo.authored_voice_badges.badges[0]
	_click_at(badge["bounds"].get_center())
	check(demo.menu.visible and demo.selected_id == root_id and demo.context["kind"] == "retune","map_signature_opens_the_actual_root")
	check(demo.model.world.snapshot() == before,"signature_does_not_build_retune_or_advance_the_city")
	await process_frame
	check(not demo.authored_voice_badges.visible and demo.authored_voice_badges.hit_root(badge["bounds"].get_center()).is_empty(),"root_menu_has_priority_over_map_badges")
	await _capture("05_点作者名牌_改音与继续入口")
	demo._choose_note(52)
	check(await _until(int(demo.clock.renderer.transport.audible_frame)+rate),"retune_reaches_actual_device_beat")
	check(int(demo.model.audible_pitches().get(root_id,-1)) == 52 and demo.authored_voice_badges.badges[0]["label"].contains("E3"),"signature_tracks_the_heard_root_pitch")
	demo._home_city()
	await _until(boundary+rate*10)
	await _capture("06_作者街坊_全景")
	check(demo.clock.underruns == skips,"no_new_audio_underrun")
	evidence = {"root_id":root_id,"route_id":work.get("expression",""),"public_anchor_count":demo.shown_world.public_sites.filter(func(row: Dictionary) -> bool: return row.get("active",false)).size(),"houses":demo.shown_world.buildings.size(),"underruns":demo.clock.underruns-skips,"samples":recording.samples.size()}
	var heard := AudioStreamWAV.new()
	heard.format = AudioStreamWAV.FORMAT_16_BITS
	heard.mix_rate = rate
	heard.stereo = true
	heard.data = Renderer.pcm16(recording.samples)
	heard.save_to_wav(OUTPUT+"落成与改音_设备输入.wav")
	demo.clock.stop_output()
	FileAccess.open(OUTPUT+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Real Windows/OpenGL/WASAPI first-play controls, actual charter and root boundaries; no human fun or listening-quality claim."},"\t")+"\n")
	print("ROUND198_FIRST_COMPOSITION ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
