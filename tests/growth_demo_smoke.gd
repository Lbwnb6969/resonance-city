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
