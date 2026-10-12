extends "res://tests/round213_planning_live.gd"
## Only the missing integration evidence: map entry, heard listen, real revisit.
var listening: Array[Dictionary] = []

func press_button(button: Control) -> void:
	# Community-name buttons are narrower than the original voice-card fixture.
	await click_map(button.get_global_rect().get_center())

func hear_controls() -> void:
	var frame := int(demo.clock.renderer.transport.rendered_frames)
	for event: Dictionary in demo.model.sound_events: frame = maxi(frame,int(event["sound_frame"]))
	await until_frame(frame+int(demo.clock.renderer.transport.sample_rate*0.2))

func map_community(cid: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var at := Vector2.INF
	for label: Dictionary in demo.community_label_layer.labels:
		if str(label["id"]) == cid: at = label["bounds"].get_center(); break
	check(at != Vector2.INF,"actual_visible_map_label_"+cid)
	if at != Vector2.INF: await click_map(at)
	await create_timer(0.5).timeout

func _run() -> void:
	output = "res://验证记录/round214_社区工作台/followup_"+Time.get_datetime_string_from_system().replace(":","-")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	DisplayServer.window_set_size(Vector2i(800,600))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	var underruns := demo.clock.underruns
	check(await until_frame(rate*5),"actual_opening_reaches_device")
	await map_community("west-2")
	var panel = demo.community_workbench
	check(panel.opened and panel.community_id == "west-2" and panel.state["count"] == 8,"native_map_name_opens_the_actual_eight_member_community")
	await press_button(panel.listen_button)
	await hear_controls()
	check(demo.model.audible_score().get("listener_community","") == "west-2" and demo.model.audible_score().get("focused_community","").is_empty(),"selected_community_is_actually_heard_at_its_writable_beat")
	await capture("00_石桥实际独听与成员")
	recording = DeviceInput.new()
	recording.model = demo.model
	recording.begin = demo.clock.renderer.transport.rendered_frames
	recording.end = recording.begin+rate*4
	demo.clock.renderer.source = recording._mix_frame
	check(await until_frame(recording.end),"four_seconds_of_actual_community_reach_wasapi")
	var peak := 0.0
	var clipped := 0
	for sample: Vector2 in recording.samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		if absf(sample.x) >= 1.0 or absf(sample.y) >= 1.0: clipped += 1
	check(recording.samples.size() == rate*4 and peak > 0.001 and clipped == 0 and demo.clock.underruns == underruns,"actual_community_pcm_has_samples_and_no_clipping_or_new_underrun")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = Renderer.pcm16(recording.samples)
	wav.save_to_wav(output+"石桥实际独听_设备输入.wav")
	await tap(KEY_C)
	await hear_controls()
	check(demo.model.audible_score().get("listener_community","").is_empty() and not demo.community_listening_owned,"closing_the_workbench_restores_original_full_city_at_the_device")
	demo.model.submit({"kind":"solo","community":"west-1"})
	demo.model.submit({"kind":"mute","community":"east-2","enabled":true})
	await hear_controls()
	await tap(KEY_C)
	await create_timer(0.4).timeout
	for button: Button in panel.community_rows.get_children():
		if str(button.get_meta("community_id","")) == "east-2": await press_button(button); break
	await create_timer(0.4).timeout
	check(panel.community_id == "east-2" and panel.state["count"] == 8 and demo.community_member_focus.member_polygons.all(func(member: Dictionary) -> bool: return demo.shown_world.by_id[member["id"]]["community_id"] == "east-2"),"native_community_switch_uses_east_members_and_camera")
	await press_button(panel.listen_button)
	await hear_controls()
	check(demo.model.audible_score().get("listener_community","") == "east-2" and not bool(demo.model.audible_score().get("muted_communities",{}).get("east-2",false)),"temporary_listen_hears_even_the_previously_muted_community")
	await tap(KEY_ESCAPE)
	await hear_controls()
	check(demo.model.audible_score().get("listener_community","") == "west-1" and bool(demo.model.audible_score().get("muted_communities",{}).get("east-2",false)),"closing_preserves_the_players_previous_solo_and_mute")
	demo.model.submit({"kind":"solo","community":""})
	demo.model.submit({"kind":"mute","community":"east-2","enabled":false})
	await hear_controls()
	await tap(KEY_C)
	await create_timer(0.4).timeout
	for button: Button in panel.community_rows.get_children():
		if str(button.get_meta("community_id","")) == "west-2": await press_button(button); break
	await create_timer(0.3).timeout
	await press_button(panel.planning_button)
	await create_timer(0.3).timeout
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	check(demo.planning_guide.stage == "scope" and demo.planning_guide.scope == ["west-2"],"actual_named_community_is_preserved_through_direction_and_card")
	await tap(KEY_ENTER)
	await create_timer(0.6).timeout
	var public: Dictionary = {}
	for possible: Dictionary in First.opportunities(demo.shown_world)["public_candidates"]:
		if str(possible["community_id"]) == "west-2": public = possible; break
	var at := Vector2(float(public["position"][0]),float(public["position"][1]))
	for button: Button in demo.planning_guide.actions.get_children():
		if str(button.get_meta("anchor_kind","")) == "civic": await press_button(button); break
	await click_map(demo.point(at))
	var boundary: int = demo.planning_guide.next_action.get("expected_boundary_frame",-1)
	check(boundary > 0,"workbench_planning_submits_a_real_public_place")
	check(await until_frame(boundary+rate),"real_public_place_reaches_device")
	if not demo.planning_guide.opened: await tap(KEY_P)
	await create_timer(0.3).timeout
	await tap(KEY_ENTER)
	await create_timer(0.7).timeout
	check(demo.menu.visible and demo._expression_context(),"real_public_place_continues_to_actual_sound_choice")
	await press_button(demo.expression_choices["warm"])
	await tap(KEY_ENTER)
	boundary = int(demo.pending_expression_choice.get("boundary_frame",-1))
	check(await until_frame(boundary+rate),"new_author_house_reaches_device")
	await tap(KEY_C)
	await create_timer(0.5).timeout
	for button: Button in panel.community_rows.get_children():
		if str(button.get_meta("community_id","")) == "west-2": await press_button(button); break
	await create_timer(0.5).timeout
	check(panel.state["count"] >= 9 and panel.state["public_sites"].size() == 1 and panel.state["authors"].size() == 1 and panel.state["reservations"].size() == 1,"revisiting_same_community_shows_actual_public_author_and_land_results")
	await capture("01_社区回访_你的文化馆暖庭与留白")
	var root_id := str(panel.state["authors"][0]["root_id"]) if not panel.state["authors"].is_empty() else ""
	if not root_id.is_empty():
		await press_button(panel.author_rows.get_child(0))
		check(not panel.opened and demo.menu.visible and demo.selected_id == root_id and demo.context.get("kind","") == "retune","community_author_button_opens_that_actual_root")
	FileAccess.open(output+"live.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"peak":peak,"samples":recording.samples.size(),"clipped":clipped,"underruns":demo.clock.underruns-underruns,"author_root":root_id,"scope":"Focused actual map-name entry, heard solo and restore including prior mute/solo, same-community planning to real civic/warm and truthful community revisit. No bulk retune or SP6 boundary claim; no human verdict."},"\t")+"\n")
	print("ROUND214_COMMUNITY_FOLLOWUP ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures)," output=",output)
	demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
