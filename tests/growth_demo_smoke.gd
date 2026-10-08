extends SceneTree
func _initialize() -> void:
	call_deferred("run_demo")
func run_demo() -> void:
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	main.release_armed = true
	var empty: Array = main.model.session._empty_cells()
	empty.sort_custom(func(a: Array,b: Array) -> bool: return Vector2(a[0]-8,a[1]-8).length_squared() < Vector2(b[0]-8,b[1]-8).length_squared())
	var chosen := Vector2i(-1,-1)
	for cell in empty:
		var safe := true
		for d in main.model.session.city:
			if d["type"] == "industrial":
				var location: Array = d["footprint"][0]
				safe = safe and absi(cell[0]-location[0])+absi(cell[1]-location[1]) > 5
		if safe:
			chosen = Vector2i(cell[0],cell[1])
			break
	assert(chosen.x >= 0)
	if "--placement" in OS.get_cmdline_user_args(): await _check_placement(main,chosen)
	main._select_empty(chosen)
	assert(main.model.session.pending.get("verb") == "release")
	main.release_button.set_pressed_no_signal(false)
	main.release_armed = false
	main.city_view.release_mode = false
	var forms: Dictionary = {}
	for phrase in range(12):
		var at: int = main.model.next_boundary
		main.clock.renderer.transport.rendered_frames = at
		var pcm: PackedVector2Array = main.clock.renderer.render(17)
		main.clock.renderer.transport.audible_frame = at+11042
		assert(pcm.size() == 17)
		await process_frame
		for d in main.model.session.city:
			forms[d.get("form","胚")] = true
	assert(main.model.session.city.size() > 11)
	assert(main.model.synth.routing.size() == main.model.session.city.size())
	assert(forms.has("群") and (forms.has("央") or forms.has("腔")))
	assert(main.city_view.sprites.size() == main.model.session.city.size())
	if "--community" in OS.get_cmdline_user_args():
		var templates: Dictionary = {}
		var pairs := 0
		for d in main.model.session.city:
			if d["type"] == "residential" and not d.get("is_anchor",false): templates[d["manifest_id"]] = true
			if d.has("visual_partner"):
				pairs += 1
				var other: Dictionary = main.model.session._district(d["visual_partner"])
				assert(other["visual_owner"] == d["district_id"] and not main.city_view.sprites[other["district_id"]].visible)
				assert(d["current_midi"] == other["current_midi"])
		assert(pairs > 0 and templates.size() >= 3)
		main.city_view.zoom_at(main.city_view.point(chosen),2.4)
		await create_timer(float(main.city_view.camera_cfg["smooth_seconds"])+0.05).timeout
		main.clock.renderer.transport.audible_frame = main.model.session.transport.phrase_frame(main.model.session.phrase_index)+2*main.clock.renderer.transport.beat_frame(1)
		await process_frame
		# Selecting the other logical half must keep its own solo/mute/retune controls.
		for d in main.model.session.city:
			if not d.has("visual_partner"): continue
			var other: Dictionary = main.model.session._district(d["visual_partner"])
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			event.position = main.city_view.point(Vector2i(other["footprint"][0][0],other["footprint"][0][1]))
			main.city_view._gui_input(event)
			assert(main._selected_id() == other["district_id"])
			break
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("res://验证记录/Demo/协调房群.png")
		print("DEMO_COMMUNITY PASS paired_whole_images=",pairs," templates=",templates.size()," independent_voices=",main.model.synth.routing.size())
		main.city_view.reset_view()
		await create_timer(float(main.city_view.camera_cfg["smooth_seconds"])+0.05).timeout
	if "--camera" in OS.get_cmdline_user_args():
		var view = main.city_view
		var before: Array = main.model.session.city.duplicate(true)
		var cursor: Vector2 = view.point(chosen)
		for step in range(6):
			var wheel := InputEventMouseButton.new()
			wheel.position = cursor
			wheel.button_index = MOUSE_BUTTON_WHEEL_UP
			wheel.pressed = true
			view._gui_input(wheel)
		await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
		assert(view.view_zoom > 2.0 and view.cell_at(cursor) == chosen)
		var middle := InputEventMouseButton.new()
		middle.button_index = MOUSE_BUTTON_MIDDLE
		middle.position = cursor
		middle.pressed = true
		view._gui_input(middle)
		var motion := InputEventMouseMotion.new()
		motion.position = cursor+Vector2(0,120)
		motion.relative = Vector2(0,120)
		view._gui_input(motion)
		middle.pressed = false
		middle.position = motion.position
		view._gui_input(middle)
		assert(view.cell_at(motion.position) == chosen)
		await process_frame
		var front: Dictionary = {}
		for d in main.model.session.city:
			if d.get("is_anchor",false) or str(d.get("anchor_id","")).is_empty() or not view.sprites[d["district_id"]].visible: continue
			if front.is_empty() or view.point(Vector2i(d["footprint"][0][0],d["footprint"][0][1])).y > view.point(Vector2i(front["footprint"][0][0],front["footprint"][0][1])).y:
				front = d
		var sprite: Sprite2D = view.sprites[front["district_id"]]
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = sprite.position+(sprite.offset+sprite.texture.get_size()*0.5)*sprite.scale
		view._gui_input(click)
		assert(main._selected_id() == front["district_id"])
		assert(main.model.session.city == before)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("res://验证记录/Demo/镜头推近.png")
		main.controls.get_node("ResetView").pressed.emit()
		await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
		assert(view.view_zoom == 1.0 and view.view_pan == Vector2.ZERO)
		assert(view.cell_at(view.point(chosen)) == chosen and main.model.session.city == before)
		print("DEMO_CAMERA PASS wheel_anchor + pan + clicked_building + reset + unchanged_city")
	if "--draft" in OS.get_cmdline_user_args():
		_check_draft_policy()
		main.draft_button.button_pressed = true
		var end := chosen+Vector2i(4,0)
		_drag_band(main.city_view,chosen,end)
		assert(main.model.session.pending.get("verb","") == "draft")
		var at: int = main.model.next_boundary
		main.clock.renderer.transport.rendered_frames = at
		main.clock.renderer.render(17)
		main.clock.renderer.transport.audible_frame = at+11042
		await process_frame
		assert(main.model.session.gravity_band["end"] == [end.x,end.y])
		var count: int = main.model.session.city.size()
		_drag_band(main.city_view,chosen,chosen+Vector2i(0,4))
		at = main.model.next_boundary
		main.clock.renderer.transport.rendered_frames = at
		main.clock.renderer.render(17)
		main.clock.renderer.transport.audible_frame = at+11042
		await process_frame
		assert(main.model.session.city.size() == count)
		assert(main.model.session.draft_pause_until == at+main.clock.renderer.transport.phrase_frame(1))
		if DisplayServer.get_name() != "headless":
			main.city_view.zoom_at(main.city_view.point(chosen),1.8)
			await create_timer(float(main.city_view.camera_cfg["smooth_seconds"])+0.05).timeout
			await process_frame
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("res://验证记录/Demo/引力带.png")
		at = main.model.next_boundary
		main.clock.renderer.transport.rendered_frames = at
		main.clock.renderer.render(17)
		main.clock.renderer.transport.audible_frame = at+11042
		await process_frame
		assert(main.model.session.city.size() == count+1)
		assert(main.model.synth.routing.size() == main.model.session.city.size())
		main.city_view.reset_view()
		await create_timer(float(main.city_view.camera_cfg["smooth_seconds"])+0.05).timeout
		print("DEMO_DRAFT PASS actual_drag + boundary_commit + redraw_one_phrase + resumed_routes")
	main.set_black_screen(true)
	assert(not main.city_view.visible and not main.panel.visible)
	main.set_black_screen(false)
	assert(main.city_view.visible and main.panel.visible)
	main._select_district(main.model.session.city.back()["district_id"])
	assert(main.district_select.selected == main.model.session.city.size()-1)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://验证记录/Demo")
		get_root().get_texture().get_image().save_png("res://验证记录/Demo/城市生长.png")
	print("DEMO_SMOKE PASS entities=",main.model.session.city.size()," forms=",forms," real_manifest_sprites=",main.city_view.sprites.size())
	main.queue_free()
	await process_frame
	quit()

func _drag_band(view: Control, start: Vector2i, end: Vector2i) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = view.point(start)
	view._gui_input(event)
	var motion := InputEventMouseMotion.new()
	motion.position = view.point(end)
	view._gui_input(motion)
	event.position = motion.position
	event.pressed = false
	view._gui_input(event)

func _check_draft_policy() -> void:
	var schema = load("res://scripts/city/district_schema.gd")
	var sessions = load("res://scripts/proposals/city_interventions.gd")
	var fixture := [schema.create("home","residential",Vector2i(2,2)),schema.create("shop","commercial",Vector2i(3,2)),schema.create("factory","industrial",Vector2i(12,12))]
	var city = sessions.new(fixture,"2026100800000001")
	city.growth_enabled = true
	var period: int = city.transport.phrase_frame(1)
	var neutral = city.fork()
	assert(city.request_draft(Vector2i(8,8),Vector2i(12,8),"residential",0,0)["accepted"])
	var draft_result: Dictionary = city.settle(period)
	var neutral_result: Dictionary = neutral.settle(period)
	assert(city.city == neutral.city and draft_result["after_r"] == neutral_result["after_r"])
	assert(city.rng.snapshot() == neutral.rng.snapshot())
	# A small controlled family proves direction changes the next legal position, not the building type.
	var family = sessions.new(fixture,"2026100800000001")
	family.growth_enabled = true
	family.request_release(48,Vector2i(8,8),0,0)
	family.settle(period)
	neutral = family.fork()
	family.request_draft(Vector2i(8,8),Vector2i(12,8),"residential",period,period)
	family.settle(2*period)
	neutral.settle(2*period)
	assert(family.city.back()["footprint"] == [[9,8]] and neutral.city.back()["footprint"] == [[7,8]])
	assert(family.city.back()["type"] == "residential" and family.city.back()["current_midi"] == 48)
	var band: Dictionary = family.gravity_band.duplicate(true)
	family.request_draft(Vector2i(8,8),Vector2i(8,12),"residential",2*period,2*period)
	var fork = family.fork()
	var count: int = family.city.size()
	family.settle(3*period)
	fork.settle(3*period)
	assert(family.city.size() == count and family.city == fork.city and family.gravity_band == fork.gravity_band and family.draft_pause_until == fork.draft_pause_until)
	family.settle(4*period)
	assert(family.city.size() == count+1)
	band = family.gravity_band.duplicate(true)
	family.request_draft(Vector2i(8,8),Vector2i(12,8),"commercial",4*period,4*period)
	family.cancel_pending()
	assert(family.gravity_band == band and family.pending.is_empty())
	assert(not family.request_draft(Vector2i(8,8),Vector2i(8,8),"residential",4*period,4*period)["accepted"])
	print("DRAFT_POLICY PASS actual_position_change + same_type_pitch + no_stat_bonus + unchanged_rng + fork_pause + cancel")


func _check_placement(main: Control, chosen: Vector2i) -> void:
	main.release_button.button_pressed = true
	var view: Control = main.city_view
	var before: Dictionary = main.model.session.snapshot()
	var motion := InputEventMouseMotion.new()
	motion.position = view.point(chosen)
	view._gui_input(motion)
	view.zoom_at(motion.position,1.7)
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	assert(view.hover_cell == chosen and main.model.session.snapshot() == before)
	assert(main.model.session.release_feedback(48,chosen)["allowed"])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = motion.position
	view._gui_input(click)
	await process_frame
	await process_frame
	assert(main.model.session.pending.get("verb","") == "release" and main.map_notice.text.contains("待落定"))
	var pending: Dictionary = main.model.session.pending.duplicate(true)
	var occupied := Vector2i(main.model.session.city[0]["footprint"][0][0],main.model.session.city[0]["footprint"][0][1])
	click.position = view.point(occupied)
	view._gui_input(click)
	assert(main.model.session.pending == pending and main.status.text.contains("已有"))
	assert(not main.model.session.release_feedback(48,Vector2i(-1,0))["allowed"])
	assert(not main.model.session.release_feedback(49,chosen)["allowed"])
	motion.position = view.point(chosen)
	view._gui_input(motion)
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://验证记录/Demo/释放位置反馈.png")
	main.controls.get_node("Cancel").pressed.emit()
	await process_frame
	assert(main.model.session.pending.is_empty() and main.model.session.city == before["city"] and main.model.session.rng.snapshot() == before["rng"])
	assert(not main.map_notice.text.contains("待落定"))
	var fork = main.model.session.fork()
	fork.lifecycle["ended"] = true
	assert(not fork.release_feedback(48,chosen)["allowed"])
	main.release_button.button_pressed = false
	view.reset_view()
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	main.release_armed = true
	print("DEMO_PLACEMENT PASS readonly_hover + zoom_cursor + actual_click + rejected_cell_preserves_pending + cancel + ended_guard")
