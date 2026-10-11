extends SceneTree
## Production scene, real audio boundary, actual neighboring house and viewport captures.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT := "res://验证记录/round181_视觉真实窗口"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var images: Dictionary = {}
var initial_skips := 0
var initial_frame := 0.0

func _initialize() -> void: call_deferred("_run")

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

func _click(p: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(p)
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

func _hit_variants() -> Dictionary:
	var result: Dictionary = {}
	for id: String in demo.sprites:
		var geometry: Dictionary = demo.building_geometry[id]
		var style := str(geometry["entry"]["id"])
		if result.has(style): continue
		var image: Image = geometry["image"]
		var bounds := image.get_used_rect()
		for y in range(bounds.position.y,bounds.end.y,8):
			for x in range(bounds.position.x,bounds.end.x,8):
				if image.get_pixel(x,y).a < .9: continue
				var sprite: AudioGrowthMask = demo.sprites[id]
				var screen := sprite.to_global(Vector2(x,y)+sprite.offset)
				if demo._hit(screen) == id:
					result[style] = {"id":id,"screen":[screen.x,screen.y]}
					break
			if result.has(style): break
	return result

func _neighbor() -> Vector2:
	for building: Dictionary in demo.model.world.buildings:
		var center := Vector2(float(building["position"][0]),float(building["position"][1]))
		for index in range(24):
			var p := center+Vector2.from_angle(TAU*float(index)/24.0)*.95
			var placement: Dictionary = demo.model.world.placement(p)
			if not bool(placement.get("allowed",false)) or placement.get("community_id","") != building["community_id"]: continue
			if not demo.model.world.public_at(p).is_empty() or not demo._hit(demo.point(p)).is_empty(): continue
			_click(p)
			if demo.menu.visible and demo.context.get("kind","") == "seed": return p
	return Vector2.INF

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	initial_skips = demo.clock.underruns
	initial_frame = demo.clock.renderer.transport.audible_frame
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","real_windows_wasapi_scene")
	check(await _until(rate),"starter_revealed_by_actual_device_audio")
	var variants := _hit_variants()
	check(demo.building_catalog.entries.all(func(entry: Dictionary) -> bool: return variants.has(entry["id"])),"all_three_roof_silhouettes_have_actual_per_house_click_targets")
	check(demo.shown_world.buildings.size() == 24 and demo.shown_world.phrase_index == 0,"visuals_keep_the_fresh_24_house_opening")
	evidence["initial_variants"] = variants
	await _capture("young_river_day")
	var neighbor := _neighbor()
	check(neighbor != Vector2.INF,"actual_map_click_opens_legal_residential_neighbor_sound_choice")
	if neighbor == Vector2.INF:
		await _finish()
		return
	var boundary := demo.model.next_boundary
	demo.expression_choices["deep"].emit_signal("pressed")
	_key(KEY_ENTER)
	check(not demo.menu.visible and demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return op.get("expression","") == "deep"),"player_selected_low_residential_house_queued_normally")
	check(demo.street_eaves_layer.diagnostics()["visible_pairs"] == 0,"pending_house_has_no_future_roof_connection")
	check(await _until(boundary+rate),"new_neighbor_reveals_after_actual_audio_boundary")
	var eaves: Dictionary = demo.street_eaves_layer.diagnostics()
	check(eaves["visible_pairs"] > 0 and eaves["pairs"].size() == demo.shown_world.fabric_cache["shared_walls"].size(),"actual_shared_wall_connects_only_after_both_house_reveals")
	evidence["shared_eaves"] = eaves
	evidence["neighbor"] = [neighbor.x,neighbor.y]
	var snapshot := demo.model.world.snapshot()
	var render_state: Dictionary = demo.clock.renderer.state.duplicate(true)
	var terrain_rebuilds: int = demo.terrain_layer.terrain_geometry_rebuilds
	var terrain_draws: int = demo.terrain_layer.rebuild_count
	for phase in [0.0,.28,.5,.78]:
		demo.daylight_manual_phase = phase
		demo._sync_daylight()
	check(demo.model.world.snapshot() == snapshot and demo.clock.renderer.state == render_state,"visual_phase_inspection_does_not_mutate_world_or_render_state")
	check(demo.terrain_layer.terrain_geometry_rebuilds == terrain_rebuilds and demo.terrain_layer.rebuild_count == terrain_draws,"daylight_reuses_existing_terrain_geometry_and_draw_commands")
	for item in [[0.0,"grown_river_day"],[.28,"grown_river_dusk"],[.5,"grown_river_night"],[.78,"grown_river_dawn"]]:
		demo.daylight_manual_phase = float(item[0])
		await _capture(str(item[1]))
	check(demo.music_activity_layer.modulate == Color.WHITE and demo.menu.modulate == Color.WHITE,"night_does_not_dim_music_source_markers_or_choice_panel")
	check(demo.caption.get_theme_color("font_color") == demo.daylight_state["ui_ink"],"floating_instructions_follow_readable_daylight_ink")
	if not eaves["pairs"].is_empty():
		var pair: Array = eaves["pairs"][0]
		var a: Vector2 = demo.building_geometry[pair[0]]["position"]
		var b: Vector2 = demo.building_geometry[pair[1]]["position"]
		demo.zoom_target = 1.9
		demo.view_zoom = 1.9
		demo.pan = -(a+b)*.5*demo.view_zoom
		demo.pan_target = demo.pan
		demo.daylight_manual_phase = 0.0
		await _capture("shared_roofs_close")
	_key(KEY_B)
	await _capture("black_listen")
	check(not demo.street_eaves_layer.visible and not demo.terrain_layer.visible and not demo.buildings_layer.visible and demo.backdrop.color == Color.BLACK,"black_listening_hides_all_new_visual_layers")
	_key(KEY_B)
	demo.daylight_manual_phase = -1.0
	await process_frame
	await process_frame
	var expected := demo.Daylight.sample(demo.clock.renderer.transport.audible_frame,rate)
	check(absf(float(expected["phase"])-float(demo.daylight_state["phase"])) < .001,"production_daylight_resumes_actual_audible_frame_after_inspection")
	check(not demo.capture_city()["view"].has("daylight_manual_phase"),"inspection_phase_is_not_written_into_player_work")
	evidence["terrain_geometry_rebuilds"] = demo.terrain_layer.terrain_geometry_rebuilds
	evidence["terrain_prepare_ms"] = demo.terrain_layer.last_prepare_ms
	evidence["houses"] = demo.shown_world.buildings.size()
	evidence["device_frames"] = demo.clock.renderer.transport.audible_frame-initial_frame
	evidence["new_underruns"] = demo.clock.underruns-initial_skips
	evidence["voices"] = demo.model.synth.max_voice_count
	check(evidence["new_underruns"] == 0 and evidence["device_frames"] > 16*rate,"physical_audio_continues_through_growth_and_visual_inspection")
	await _finish()

func _finish() -> void:
	demo._stop_preview()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for name: String in images: images[name].save_png(OUTPUT+"/"+name+".png")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"Actual young opening, production house choice/growth/hit targets and Windows/WASAPI. Four lighting captures use inspection phase overrides, not elapsed whole-day play. No human visual enjoyment or listening verdict."}
	FileAccess.open(OUTPUT+"/visual_foundation_demo_live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ROUND181_VISUAL_FOUNDATION_LIVE ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
