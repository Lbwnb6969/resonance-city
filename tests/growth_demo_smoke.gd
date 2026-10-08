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
	main._select_empty(chosen)
	assert(main.model.session.pending.get("verb") == "release")
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
			if d.get("is_anchor",false) or str(d.get("anchor_id","")).is_empty(): continue
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
		assert(view.view_zoom == 1.0 and view.view_pan == Vector2.ZERO)
		assert(view.cell_at(view.point(chosen)) == chosen and main.model.session.city == before)
		print("DEMO_CAMERA PASS wheel_anchor + pan + clicked_building + reset + unchanged_city")
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
