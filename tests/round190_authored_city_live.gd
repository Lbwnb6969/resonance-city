extends SceneTree
## Observe a real authored route through two minutes of physical device time.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round190_首作继续组合/"
var demo: ContinuousValleyDemo
var route := "weave"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var images: Dictionary = {}
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
		if start < end and start+count > begin:
			samples.append_array(block.slice(maxi(0,begin-start),mini(count,end-start)))
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

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	images[name] = demo.get_viewport().get_texture().get_image()

func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false

func _run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument in ["deep","weave","warm"]: route = argument
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
	var public_candidates: Array = First.opportunities(demo.shown_world)["public_candidates"]
	# Also exercise an authored community with actual houses on the other bank.
	var site: Dictionary = public_candidates[1 if route == "deep" else 0]
	_click(site["position"])
	guide.confirm.emit_signal("pressed")
	guide.actions.get_child(3).emit_signal("pressed")
	_click(site["position"])
	check(await _until(demo.model.phrase_frames+rate/5),"real_first_public_boundary")
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty(),"player_is_offered_real_sound_parcel")
	var recommendation: Dictionary = First.opportunities(demo.shown_world)["seed_candidates"].filter(func(candidate: Dictionary) -> bool: return str(candidate["community_id"]) == str(site["community_id"]))[0]
	check(demo.context["position"] == recommendation["position"],"real_public_followup_uses_the_connected_street_opportunity")
	demo.expression_choices[route].emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline and not demo.preview_started: await process_frame
	check(demo.preview_started,"chosen_route_four_second_audition_plays")
	demo.expression_confirm.emit_signal("pressed")
	check(await _until(demo.model.phrase_frames*2+rate/5),"chosen_route_lands_in_real_city")
	var work := demo._first_authored_state()
	check(not work.is_empty() and str(work.get("expression","")) == route,"actual_family_has_player_chosen_route")
	if work.is_empty():
		await _finish()
		return
	var root_id := str(work["root_id"])
	var root_opened := demo._begin_first_authored_theme()
	check(root_opened,"actual_authored_root_can_be_opened")
	if not root_opened:
		evidence["blocked_work"] = work
		evidence["status"] = preload("res://scripts/world/community_music_rules.gd").status(demo.shown_world,str(work["community_id"]))
		await _capture("theme_entry_blocked")
		await _finish()
		return
	demo._choose_note(52)
	recording = LiveRecording.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*16
	demo.clock.renderer.source = recording._mix_frame
	var heard := false
	deadline = Time.get_ticks_msec()+26000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		work = demo._first_authored_state()
		if bool(work.get("root_heard_retune",false)):
			heard = true
			break
	check(heard,"authored_retune_reaches_actual_device_score")
	evidence["heard_retune_frame"] = demo.clock.renderer.transport.audible_frame
	if heard: await _capture("actual_authored_note")
	demo.first_composition_guide.sync()
	if route == "warm":
		check(demo.first_composition_guide.visible and demo.first_composition_guide.action == "continuation","heard_warm_keeps_real_open_space_action")
		demo.first_composition_guide.emit_signal("pressed")
		check(demo.menu.visible and demo._authored_reservation_context() and (demo.menu.get_meta("authored_reservation_choices") as Control).visible and not (demo.menu.get_meta("notes") as Control).visible,"warm_open_space_has_three_direct_existing_actions")
		await _capture("open_space_choices")
		demo.menu.hide()
		await process_frame
		var parcels: Array = demo.authored_reservation_layer.parcels
		check(parcels.size() == 1,"only_the_actual_authored_reservation_is_marked")
		if not parcels.is_empty():
			var event := InputEventMouseButton.new()
			event.position = (parcels[0]["label_bounds"] as Rect2).get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			demo._gui_input(event)
			check(demo.menu.visible and demo.context.get("id","") == parcels[0]["reservation_id"],"clicking_the_land_label_opens_the_real_reservation")
			(menu_choices(demo).get_child(0) as Button).emit_signal("pressed")
			check(not demo.menu.visible,"keeping_open_land_returns_to_the_city")
	else:
		check(demo.first_composition_guide.visible and demo.first_composition_guide.action == "compose","heard_route_keeps_next_composition_action")
		demo.first_composition_guide.emit_signal("pressed")
		check(guide.opened and guide.stage == "charter" and guide.scope.is_empty() and guide.plan_id.is_empty(),"next_composition_asks_for_real_new_player_choices")
		await _capture("next_composition")
		guide.hide_tool()
		await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
		check(str(demo.model.audible_score().get("focused_community","" )).is_empty(),"next_composition_releases_previous_theme_focus")
	check(await _until(demo.model.phrase_frames*4+rate/2),"four_phrases_reach_physical_device")
	demo._home_city()
	await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
	await _capture("minute_one")
	print("ROUND190_ROUTE_PROGRESS ",route," phrase ",demo.shown_world.phrase_index)
	check(await _until(demo.model.phrase_frames*8+rate/2),"two_minutes_reach_physical_device")
	demo._home_city()
	await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
	await _capture("minute_two")
	var family_id := str(demo.shown_world.by_id[root_id]["family_id"])
	var houses: Array = demo.shown_world.buildings.filter(func(b: Dictionary) -> bool: return str(b["family_id"]) == family_id)
	var root_position: Array = demo.shown_world.by_id[root_id]["position"]
	demo.planning_guide._focus_planning_position(root_position)
	await _until(int(demo.clock.renderer.transport.audible_frame)+rate)
	await _capture("author_street")
	check(houses.size() > 1 and houses.all(func(b: Dictionary) -> bool: return str(demo.building_geometry[str(b["district_id"])]["entry"].get("first_expression_style","")) == route),"real_family_growth_keeps_its_visible_route")
	check(demo.shown_world.buildings.size() >= 26 and demo.shown_world.buildings.size() <= 30,"two_minute_city_keeps_the_small_authored_slice")
	var heard_frame: float = float(evidence.get("heard_retune_frame",-1.0))
	evidence = {"route":route,"phrase":demo.shown_world.phrase_index,"houses":demo.shown_world.buildings.size(),"family_houses":houses.duplicate(true),
		"reservations":demo.shown_world.planning_reservations.duplicate(true),"score":demo.model.audible_score(),
		"heard_retune_frame":heard_frame,"audible_frame":demo.clock.renderer.transport.audible_frame,"underruns":demo.clock.underruns-start_skips,"max_voices":demo.model.synth.max_voice_count}
	check(int(evidence["underruns"]) == 0,"physical_city_continues_without_new_underrun")
	if route == "warm":
		check(demo._begin_first_authored_continuation(),"real_preserved_land_can_be_reopened_after_two_minutes")
		var reservation_id := str(demo.context.get("id",""))
		var public_boundary := demo.model.next_boundary
		(menu_choices(demo).get_child(1) as Button).emit_signal("pressed")
		check(demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "park"),"open_land_park_choice_uses_existing_public_transaction")
		check(await _until(public_boundary+rate/2),"planned_park_lands_at_real_audio_boundary")
		check(demo.shown_world.planning_reservations.all(func(reservation: Dictionary) -> bool: return str(reservation.get("reservation_id","")) != reservation_id) and demo.shown_world.public_sites.any(func(public_site: Dictionary) -> bool: return bool(public_site.get("active",false)) and str(public_site.get("kind","")) == "park" and bool(public_site.get("player_planned",false))),"planning_consumes_actual_reservation_into_actual_park")
		await _capture("open_land_becomes_park")
		check(demo.authored_reservation_layer.parcels.is_empty(),"consumed_reservation_has_no_stale_land_label")
		evidence["park_score"] = demo.model.audible_score()
	await _finish()

func menu_choices(owner: ContinuousValleyDemo) -> Control:
	return owner.menu.get_meta("authored_reservation_choices")

func _finish() -> void:
	demo._stop_preview()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT+route))
	for name: String in images: images[name].save_png(OUTPUT+route+"/"+name+".png")
	if recording != null:
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = demo.clock.renderer.transport.sample_rate
		wav.stereo = true
		wav.data = SampleRenderer.pcm16(recording.samples)
		wav.save_to_wav(OUTPUT+route+"/actual_retune_device_input.wav")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Real production UI, physical WASAPI time, natural eight phrases and screenshots. No human fun/listening verdict."}
	FileAccess.open(OUTPUT+route+"/live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND190_AUTHORED_CITY ",route," ",JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures,"evidence":evidence}))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
