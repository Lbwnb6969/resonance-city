extends SceneTree
## Real-window interrupted planning and the first heard authored street extension.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
var output := "res://验证记录/round200_首玩接续/"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
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
func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
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
func _run() -> void:
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
	var queue := demo.clock
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","physical_window_and_audio")
	check(demo.shown_world.buildings.size() == 24,"fresh_24_house_river_bend")
	var guide = demo.planning_guide
	guide.open_tool()
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": site = possible; break
	var at := demo.point(Vector2(float(site["position"][0]),float(site["position"][1])))
	_click_at(at)
	guide.confirm.emit_signal("pressed")
	var charter_id: String = guide.committed_charter_id
	var charter_frame: int = guide.committed_charter_frame
	var plan: String = guide.plan_id
	var card: String = guide.card_id
	var pending_count: int = demo.model.world.pending_actions.size()
	guide.choose_anchor("civic")
	await _capture("01_已选社区_安排公共空间")
	guide.hide_tool()
	await process_frame
	demo.first_composition_guide.sync()
	check(demo.first_composition_guide.visible and demo.first_composition_guide.text.contains("公共"),"closed_anchor_has_clear_light_reentry")
	await _capture("02_收起后_保留公共空间入口")
	demo.first_composition_guide.emit_signal("pressed")
	check(guide.opened and guide.stage == "anchor" and guide.committed_charter_id == charter_id and guide.plan_id == plan and guide.card_id == card and guide.scope == ["west-2"] and guide.anchor_kind == "civic","light_entry_restores_same_plan_card_scope_and_choice")
	_key(KEY_P)
	_key(KEY_P)
	check(guide.opened and guide.stage == "anchor" and guide.committed_charter_id == charter_id and demo.model.world.pending_actions.size() == pending_count,"P_resume_does_not_resubmit_charter")
	check(await _until(charter_frame+rate/5),"charter_reaches_device_boundary")
	_key(KEY_ESCAPE)
	await process_frame
	demo.first_composition_guide.sync()
	demo.first_composition_guide.emit_signal("pressed")
	check(guide.opened and guide.stage == "anchor" and guide.committed_charter_id == charter_id and demo.shown_world.development_charters.any(func(row: Dictionary) -> bool: return row["charter_id"] == charter_id),"resume_survives_pending_to_heard_charter")
	guide.choose_anchor("park")
	await _capture("03_回到同一社区_公园预影")
	_click_at(demo.point(Vector2(float(site["position"][0]),float(site["position"][1]))))
	var anchor_frame: int = guide.next_action.get("expected_boundary_frame",-1)
	check(not guide.opened and anchor_frame > charter_frame,"resumed_public_space_submits_once_to_next_phrase")
	check(await _until(anchor_frame+rate/5),"public_space_reaches_device_boundary")
	check(guide.ready_sound_community() == "west-2","completed_anchor_hands_same_community_to_sound")
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty(),"sound_is_still_chosen_by_player")
	demo.expression_choices["warm"].emit_signal("pressed")
	demo.expression_listen.emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+8000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started,"warm_route_real_audition")
	await _capture("04_暖庭_真实试听")
	var birth_frame := demo.model.next_boundary
	recording = LiveRecording.new()
	recording.model = demo.model
	recording.begin = birth_frame
	recording.end = birth_frame+rate*8
	demo.clock.renderer.source = recording._mix_frame
	demo.expression_confirm.emit_signal("pressed")
	check(await _until(birth_frame+rate/5),"first_author_root_reaches_device_boundary")
	var work := demo._first_authored_state()
	var root_id := str(work.get("root_id",""))
	check(not root_id.is_empty() and demo.authored_growth_trail.trails.is_empty(),"root_is_authored_but_does_not_claim_a_family_extension")
	await _capture("05_真实根屋_同一暖庭")
	deadline = Time.get_ticks_msec()+90000
	var trail: Dictionary = {}
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not demo.authored_growth_trail.trails.is_empty():
			trail = demo.authored_growth_trail.trails[0].duplicate(true)
			break
	check(not trail.is_empty() and demo.shown_world.by_id.has(str(trail.get("id",""))) and str(trail.get("from_id","")) == root_id and trail.get("label","").contains("你的暖庭"),"first_real_child_links_back_to_heard_author_family")
	if not trail.is_empty():
		await _capture("06_自动长出下一栋_作者成长短线")
		check(await _until(int(trail["birth_frame"])+rate*3),"growth_caption_finishes_in_its_short_window")
		check(demo.authored_growth_trail.trails.is_empty(),"growth_caption_does_not_stay_over_the_city")
	check(demo.clock == queue and demo.clock.underruns == skips,"same_audio_queue_no_new_underrun")
	var samples := recording.samples
	var peak := 0.0
	var sum_squared := 0.0
	var clipped := 0
	for sample: Vector2 in samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		sum_squared += sample.length_squared()
		if absf(sample.x) >= 1.0 or absf(sample.y) >= 1.0: clipped += 1
	check(samples.size() == rate*8 and clipped == 0,"eight_seconds_device_input_recorded_without_clipping")
	var heard := AudioStreamWAV.new()
	heard.format = AudioStreamWAV.FORMAT_16_BITS
	heard.mix_rate = rate
	heard.stereo = true
	heard.data = Renderer.pcm16(samples)
	heard.save_to_wav(output+"暖庭落成_设备输入.wav")
	demo.clock.stop_output()
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":{"charter_id":charter_id,"root_id":root_id,"trail":trail,"houses":demo.shown_world.buildings.size(),"underruns":demo.clock.underruns-skips,"sample_rate":rate,"samples":samples.size(),"peak":peak,"rms":sqrt(sum_squared/maxi(1,samples.size()*2)),"clipped":clipped},"scope":"Real Windows/OpenGL/WASAPI planning close/resume, heard public anchor and authored growth. Screenshot and technical evidence; no human fun or listening-quality claim."}
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND200_FIRST_PLAY ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
