extends SceneTree
## Production drawing -> held comparison -> exact commit -> real follow-up.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Neighborhood = preload("res://scripts/world/neighborhood_plan.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func key(demo: Control,code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	demo._input(event)
func capture(demo: Control,label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture") or DisplayServer.get_name() == "headless": return
	demo._sync_buildings()
	demo.scenery.sync(demo)
	demo.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://验证记录/round163_局部规划声音闭环"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var path := directory+"/"+label+".png"
	check(root.get_texture().get_image().save_png(path) == OK,"captures_"+label)

func audition(demo: Control) -> void:
	if not OS.get_cmdline_user_args().has("--capture") or DisplayServer.get_name() == "headless": return
	var directory := "res://验证记录/round163_局部规划声音闭环"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for kind: String in ["none","park","civic"]:
		demo.planning_guide.choose_anchor(kind)
		check(demo.preview_player.playing,"device_starts_"+kind)
		check(demo.preview_player.stream.save_to_wav(directory+"/"+kind+".wav") == OK,"exports_real_branch_"+kind)
		await create_timer(2.6).timeout
		check(demo.preview_player.get_playback_position() > 2.3,"device_clock_advances_"+kind)
		await create_timer(0.6).timeout

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var city := World.new("2026101100000162",true,"river_valley")
	city.build_starter("bright")
	var outer := PackedVector2Array()
	var center := Vector2.ZERO
	for y in range(-36,37):
		for x in range(-36,37):
			var candidate_center := Vector2(float(x)*0.25,float(y)*0.25)
			var polygon := Neighborhood.box(candidate_center,Vector2(0.8,0.8))
			var candidate := {"polygon":polygon,"position":[candidate_center.x,candidate_center.y]}
			if Planning.site_reason(city,candidate).is_empty() and not Planning.public_access(city,candidate).is_empty():
				outer = polygon
				center = candidate_center
				break
		if not outer.is_empty(): break
	check(not outer.is_empty(),"finds_real_road_accessible_courtyard_site")
	if outer.is_empty():
		demo.queue_free()
		quit(1)
		return
	var source := Neighborhood.box(center,Vector2(1.2,1.2))
	var hole := Neighborhood.box(center,Vector2(0.3,0.3))
	var reservation_id := "round163-ui-source"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round163-ui-lot","polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	demo._start_world({},city)
	demo.planning_guide.hide_tool()
	demo.view_zoom = 1.9
	demo.zoom_target = 1.9
	demo.pan = demo.size*0.5-demo.point(center)+demo.pan
	demo.pan_target = demo.pan
	demo.pointer = demo.point(center+Vector2(0.6,0.6))
	demo.pointer_inside = true
	demo.context = {"kind":"reservation","id":reservation_id,"position":[center.x,center.y]}
	demo.clock.stop_output()
	demo.clock.renderer.transport.rendered_frames = demo.model.next_boundary-1
	demo.clock.renderer.transport.audible_frame = float(demo.model.next_boundary-1)
	demo._verb("free_courtyard_park")
	demo._append_partial_polygon_point(outer[0])
	demo._append_partial_polygon_point(outer[1])
	key(demo,KEY_SPACE)
	check(demo.preview_thread == null and not demo.planning_guide.opened,"unfinished_boundary_does_not_start_comparison")
	demo._verb("free_courtyard_park")
	for p in outer: demo._append_partial_polygon_point(p)
	key(demo,KEY_TAB)
	for p in hole: demo._append_partial_polygon_point(p)
	var earlier_choice: Dictionary = demo.model.submit({"kind":"park","partial":true,"source_reservation_id":reservation_id,"target_polygons":[outer],"target_holes":[hole]})
	check(bool(earlier_choice.get("accepted",false)) and city.pending_actions.size() == 1,"earlier_replaceable_public_choice_is_pending")
	var before := city.snapshot()
	var phases: Dictionary = demo.clock.renderer.state.duplicate(true)
	key(demo,KEY_SPACE)
	check(demo.planning_guide.stage == "partial_anchor" and demo.planning_guide.opened,"space_opens_fixed_partial_comparison")
	check(demo.planning_guide.candidate.get("hole_polygons",[]).size() == 1,"comparison_keeps_courtyard")
	var fixed: Dictionary = demo.planning_guide.candidate.duplicate(true)
	demo.pointer += Vector2(80,30)
	demo.planning_guide.update_candidate(demo.world_at(demo.pointer))
	check(demo.planning_guide.candidate == fixed,"moving_pointer_does_not_replace_authored_target")
	while demo.preview_thread != null and demo.preview_thread.is_alive(): await process_frame
	demo._process(0.0)
	check(demo.planning_guide.comparison.get("variants",{}).size() == 3,"worker_result_accepted_by_production_ui")
	check(demo.preview_started and demo.preview_player.stream is AudioStreamWAV,"held_space_routes_real_pcm_to_player")
	await audition(demo)
	demo.planning_guide.choose_anchor("civic")
	check(demo.preview_player.stream.data == demo.planning_guide.comparison.get("variants",{}).get("civic",{}).get("pcm",PackedByteArray()),"branch_button_plays_selected_civic_pcm")
	check(demo._partial_action_title().contains("文化馆"),"map_title_matches_selected_branch")
	check(demo.planning_guide.detail.text.contains("这3秒合奏相同"),"unchanged_pcm_is_explained_to_player")
	var release := InputEventKey.new()
	release.keycode = KEY_SPACE
	release.pressed = false
	demo._input(release)
	check(not demo.preview_started and not demo.model.synth.ducking,"release_restores_live_bus")
	check(city.snapshot() == before and demo.clock.renderer.state == phases,"comparison_and_release_leave_live_world_rng_and_phase_unchanged")
	await capture(demo,"partial_comparison")
	check(demo.planning_guide.size.y < 540.0 and demo.planning_guide.get_global_rect().end.y < demo.size.y-80.0,"comparison_leaves_visible_city_and_bottom_controls")
	demo.planning_guide.choose_anchor("none")
	key(demo,KEY_ENTER)
	check(city.pending_actions.is_empty() and not PartialPublic._reservation(city,reservation_id).is_empty(),"none_enter_keeps_source_without_queued_operation")
	check(not demo.partial_polygon_mode and not demo.planning_guide.opened,"none_clears_transient_draft")
	demo.context = {"kind":"reservation","id":reservation_id,"position":[center.x,center.y]}
	demo._verb("partial_park")
	demo.pointer = demo.point(center)
	var rectangle: Dictionary = demo._partial_comparison_site()
	check(bool(rectangle.get("allowed",false)) and rectangle.get("target_polygons",[]).size() == 1,"fixed_rectangle_uses_same_exact_descriptor")
	demo.planning_guide.begin_partial_comparison(rectangle,"park")
	demo.pointer += Vector2(90,30)
	demo.planning_guide.update_candidate(demo.world_at(demo.pointer))
	check(demo.planning_guide.candidate == rectangle,"fixed_rectangle_comparison_holds_position")
	key(demo,KEY_ESCAPE)
	check(not demo.partial_mode and not demo.planning_guide.opened and city.pending_actions.is_empty(),"escape_cancels_fixed_rectangle_without_truth_change")
	demo.context = {"kind":"reservation","id":reservation_id,"position":[center.x,center.y]}
	demo._verb("free_courtyard_park")
	for p in outer: demo._append_partial_polygon_point(p)
	key(demo,KEY_TAB)
	for p in hole: demo._append_partial_polygon_point(p)
	key(demo,KEY_SPACE)
	while demo.preview_thread != null and demo.preview_thread.is_alive(): await process_frame
	demo._process(0.0)
	demo.planning_guide.choose_anchor("civic")
	key(demo,KEY_ENTER)
	check(city.pending_actions.size() == 1 and city.pending_actions[0].get("kind","") == "civic","enter_submits_selected_branch_kind")
	check(city.pending_actions[0].get("hole_polygons",[]).size() == 1 and city.pending_actions[0].get("target_polygons",[]).size() == 1,"enter_submits_same_components_and_hole")
	check(demo.planning_guide.next_action.get("state","") == "queued" and demo.planning_guide.next_action.get("choice","") == "civic","followup_identifies_actual_chosen_operation")
	check(not demo.preview_started and not demo.partial_polygon_mode,"commit_stops_overlay_and_clears_draft")
	var boundary: int = demo.model.next_boundary
	demo.model.render_block({},boundary-1,2,int(city.cfg["timing"]["sample_rate"]))
	demo.clock.renderer.transport.audible_frame = float(boundary+int(city.cfg["timing"]["sample_rate"]))
	demo._process(0.0)
	check(demo.planning_guide.next_action.get("state","") == "ready","audible_partial_event_activates_feedback")
	check(not str(demo.planning_guide.next_action.get("public_id","")).is_empty(),"feedback_points_to_real_public_site")
	check(not demo.planning_guide.next_action.get("remaining_reservation_ids",[]).is_empty(),"feedback_offers_real_remaining_reservations")
	check(city.public_at(center).is_empty() and not city.planning_at(center).is_empty(),"committed_courtyard_remains_player_land")
	await capture(demo,"partial_followup")
	demo.planning_guide._take_remaining_reservation()
	check(demo.context.get("kind","") == "reservation" and not str(demo.context.get("id","")).is_empty(),"continue_action_opens_existing_reservation_menu")
	print("ROUND163_PARTIAL_PREVIEW_UI checks=",checks," failures=",JSON.stringify(failures)," driver=",AudioServer.get_driver_name())
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
