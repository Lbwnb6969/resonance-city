extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const Reference = preload("res://tests/round129_display_reference.gd")
var checks: Dictionary = {}
var images: Array = []
var actual: Control
var reference: Control

func _initialize() -> void: call_deferred("_run")

func _make(old: bool) -> Control:
	var demo: Control = DemoScene.instantiate()
	if old: demo.set_script(Reference.make_script())
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	return demo

func _draw(demo: Control,frame: float) -> Image:
	demo.clock.renderer.transport.audible_frame = frame
	demo.shown_world = demo.model.presentation_world(frame)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	demo._hit(Vector2(-1000,-1000))
	demo.queue_redraw()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _compare(frame: float,label: String) -> void:
	actual.hide()
	reference.show()
	var expected: Image = await _draw(reference,frame)
	reference.hide()
	actual.show()
	var image: Image = await _draw(actual,frame)
	var sum := 0.0
	var samples := 0
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			var a := image.get_pixel(x,y)
			var b := expected.get_pixel(x,y)
			sum += (absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b))/3.0
			samples += 1
	var error := sum/samples
	checks[label+"_pixels"] = error < 0.00005
	checks[label+"_physical_graph"] = actual.shown_world.network.roads == reference.shown_world.network.roads
	checks[label+"_bindings"] = actual.city_ground_layer.city == actual.shown_world and actual.scenery.site_key[0] == actual.shown_world
	images.append({"label":label,"mean_rgb_error":error,"ground_updates":actual.city_ground_layer.update_count,"reference_ground_updates":reference.city_ground_layer.update_count,"building_syncs":actual.building_sync_count,"reference_building_syncs":reference.building_sync_count})
	if label == "growth": image.save_png("res://验证记录/连续河谷/第129轮_显示版本_成长.png")

func _prepare(demo: Control) -> void:
	demo.model.enable_background_settlement()
	demo.model.prepare_settlement(demo.model.next_boundary-22050,22050)
	while not demo.model.settlement_job.completed(): await process_frame
	demo.model.prepare_settlement(demo.model.next_boundary-22050,22050)

func _run() -> void:
	actual = _make(false)
	actual.hide()
	reference = _make(true)
	await _compare(33075,"opening")
	var ground: int = actual.city_ground_layer.update_count
	var building: int = actual.building_sync_count
	var overlay: int = actual.overlay_rebuild_count
	var hit: int = actual.hit_sort_count
	var old_city: ContinuousWorld = actual.shown_world
	var before: Dictionary = actual.model.world.snapshot()
	for demo in [actual,reference]:
		demo.model.submit({"kind":"bridge"})
		await _prepare(demo)
	var at: int = actual.model.next_boundary
	for demo in [actual,reference]: demo.model.render_block({},at-128,256,22050)
	await _compare(at-1,"before_reveal")
	checks["old_view_new_object"] = actual.shown_world != old_city and actual.shown_world.phrase_index == 0 and actual.model.world.phrase_index == 1
	checks["old_view_keeps_commands"] = actual.city_ground_layer.update_count == ground and actual.building_sync_count == building and actual.overlay_rebuild_count == overlay and actual.hit_sort_count == hit
	checks["bridge_hidden"] = not actual.shown_world.bridge and actual.model.world.bridge
	await _compare(at+33075,"growth")
	checks["one_audible_structural_refresh"] = actual.city_ground_layer.update_count == ground+1 and actual.building_sync_count == building+1 and actual.overlay_rebuild_count == overlay+1 and actual.hit_sort_count == hit+1
	checks["bridge_revealed"] = actual.shown_world.bridge and actual.sprites.size() == actual.shown_world.buildings.size()
	var played: String = actual.shown_world.buildings[0]["district_id"]
	var beat := 0
	for demo in [actual,reference]:
		beat = int(demo.model.submit({"kind":"retune","id":played,"midi":36})["sound_frame"])
		demo.model.render_block({},beat-64,128,22050)
	ground = actual.city_ground_layer.update_count
	building = actual.building_sync_count
	await _compare(beat-1,"before_sound")
	checks["sound_copy_keeps_commands"] = actual.city_ground_layer.update_count == ground and actual.building_sync_count == building
	await _compare(beat+33075,"retune")
	checks["audible_retune_tint"] = actual.city_ground_layer.update_count == ground and actual.building_sync_count == building+1 and is_equal_approx(actual.sprites[played].modulate.b,0.92)
	for view in [{"zoom":0.54,"pan":Vector2(100,-150)},{"zoom":1.2,"pan":Vector2(-60,45)}]:
		for demo in [actual,reference]:
			demo.view_zoom = view["zoom"]
			demo.pan = view["pan"]
		await _compare(beat+33075,"camera_"+str(view["zoom"]))
	var projection_error := 0.0
	for id in actual.sprites:
		projection_error = maxf(projection_error,actual.sprites[id].global_position.distance_to(actual.point(WorldCoupling.position_of(actual.shown_world.by_id[id]))))
	checks["projection_exact"] = projection_error < 0.001
	var sprite: Sprite2D = actual.sprites[played]
	var texture_image: Image = actual.asset_images[actual.shown_world.by_id[played]["type"]]
	var clicked := ""
	for y in range(texture_image.get_height()/2,texture_image.get_height(),7):
		for x in range(0,texture_image.get_width(),7):
			if texture_image.get_pixel(x,y).a <= 0.9: continue
			var screen := sprite.to_global(sprite.offset+Vector2(x,y))
			clicked = actual._hit(screen)
			if not clicked.is_empty():
				checks["alpha_hit_exact"] = clicked == reference._hit(screen)
				break
		if not clicked.is_empty(): break
	checks["alpha_hit_visible"] = not clicked.is_empty()
	var saved: Dictionary = actual.model.capture_state()
	var resumed := Model.from_state(saved)
	checks["runtime_token_not_saved"] = not saved.has("presentation_token") and resumed.presentation_token != actual.model.presentation_token
	var old_token: RefCounted = actual.model.presentation_token
	ground = actual.city_ground_layer.update_count
	# Load another legal branch with the same seed and phrase but no bridge.
	for demo in [actual,reference]:
		var branch := World.new()
		branch.build_starter("bright")
		branch.settle(at)
		var state: Dictionary = demo.capture_city()
		state["model"] = Model.new(branch,demo.fixed_gain).capture_state()
		demo._start_world(state)
	await process_frame
	await _compare(at+33075,"new_session_same_phrase")
	checks["new_session_invalidates"] = actual.model.presentation_token != old_token and actual.city_ground_layer.update_count > ground and not actual.shown_world.bridge
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"images":images,"max_projection_error":projection_error,"opening_buildings":before["buildings"].size()}
	FileAccess.open("res://验证记录/连续河谷/第129轮_显示版本.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("DISPLAY_VERSION ",JSON.stringify(result))
	actual.queue_free()
	reference.queue_free()
	await process_frame
	quit(0 if result["passed"] else 1)
