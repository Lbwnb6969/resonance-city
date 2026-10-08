extends SceneTree
const Schema = preload("res://scripts/city/district_schema.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Growth = preload("res://scripts/city/city_growth.gd")
var failed := false
var checks := 0
var empty_events: Array[Vector2i] = []
func _initialize() -> void: call_deferred("run_check")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("PICKING_FAIL "+message)
func frames() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
func click(view: Control,position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = view.get_global_transform()*position
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await frames()
func pixel(view: Control,sprite: Sprite2D,p: Vector2) -> bool:
	return sprite.visible and sprite.is_pixel_opaque(sprite.to_local(view.get_global_transform()*p))
func empty_corner(main: Control) -> Vector2:
	var view: Control = main.city_view
	var occupied: Dictionary = {}
	for d in main.model.session.city: occupied[Schema.cell(d)] = true
	for sprite in view.sprites.values():
		if not sprite.visible or not sprite.has_meta("asset_id"): continue
		var rect: Rect2 = sprite.get_rect()
		for y in range(1,32):
			for x in range(1,32):
				var local := rect.position+rect.size*Vector2(x,y)/32.0
				var p: Vector2 = view.get_global_transform().affine_inverse()*sprite.to_global(local)
				if p.y < 220 or p.y > 620 or p.x < 30 or p.x > view.size.x-30: continue
				var cell: Vector2i = view.cell_at(p)
				if cell.x < 0 or cell.y < 0 or cell.x >= 16 or cell.y >= 16 or occupied.has(cell): continue
				var visible := false
				for other in view.sprites.values(): visible = visible or pixel(view,other,p)
				if not visible: return p
	return Vector2(-1,-1)
func roof(main: Control,id: String) -> Vector2:
	var view: Control = main.city_view
	var sprite: Sprite2D = view.sprites[id]
	var rect: Rect2 = sprite.get_rect()
	var occupied: Dictionary = {}
	for d in main.model.session.city: occupied[Schema.cell(d)] = true
	for y in range(2,16):
		for x in range(2,30):
			var local := rect.position+rect.size*Vector2(x,y)/32.0
			var p: Vector2 = view.get_global_transform().affine_inverse()*sprite.to_global(local)
			if not pixel(view,sprite,p) or p.y < 180 or p.y > 620 or occupied.has(view.cell_at(p)): continue
			var covered := false
			for other in view.sprites.values():
				if other != sprite and other.position.y > sprite.position.y: covered = covered or pixel(view,other,p)
			if not covered: return p
	return Vector2(-1,-1)
func capture() -> void:
	await frames()
	root.get_texture().get_image().save_png("res://验证记录/Demo/轮廓点选_透明角落.png")
func run_check() -> void:
	check(DisplayServer.get_name() != "headless","requires actual GPU")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await frames()
	var city := [Schema.create("origin","residential",Vector2i(6,8)),Schema.create("home","residential",Vector2i(7,8)),Schema.create("partner","residential",Vector2i(8,8)),Schema.create("factory","industrial",Vector2i(7,7)),Schema.create("shop","commercial",Vector2i(7,6))]
	city[0]["is_anchor"] = true
	for d in city.slice(0,3):
		d["anchor_id"] = "origin"
		d["form"] = "群" if d["district_id"] != "origin" else "胚"
	Growth.assign_assets(city)
	main.model = Model.new(Session.new(city,"2026100900000002"))
	main.model.session.growth_enabled = true
	main.clock.renderer.source = main.model._mix_frame
	main.clock.renderer.state = main.model.synth.initial_state()
	main.clock.renderer.transport.audible_frame = main.clock.renderer.transport.beat_frame(2)
	var view: Control = main.city_view
	for sprite in view.sprites.values(): sprite.queue_free()
	for label in view.labels.values(): label.queue_free()
	for field in [view.sprites,view.labels,view.forms,view.appearance,view.base_scales]: field.clear()
	view.session = main.model.session
	main._refresh_district_list()
	main._select_district("factory")
	view.zoom_at(view.point(Vector2i(7,8)),2.8)
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	view.view_pan.y += 100.0
	await frames()
	check(city[1].get("visual_partner","") == "partner" and not view.sprites["partner"].visible,"actual whole-image pair fixture")
	view.empty_clicked.connect(func(cell: Vector2i) -> void: empty_events.append(cell))
	var saved: Dictionary = main.model.session.snapshot()
	var p := empty_corner(main)
	check(p.x >= 0,"actual transparent PNG pixel over unoccupied plot")
	var marker := Label.new()
	marker.text = "＋"
	marker.position = p-Vector2(15,18)
	marker.add_theme_font_size_override("font_size",30)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(marker)
	await click(view,p)
	check(empty_events.size() == 1 and empty_events[0] == view.cell_at(p),"transparent image corners pass to the actual empty plot")
	check(main._selected_id() == "factory","empty click does not steal selection")
	await capture()
	if "--repro-only" in OS.get_cmdline_user_args():
		print("PICKING_REPRO %s checks=%d" % ["FAIL" if failed else "PASS",checks])
		quit(1 if failed else 0)
		return
	var body := roof(main,"shop")
	check(body.x >= 0,"visible roof fixture")
	await click(view,body)
	check(main._selected_id() == "shop","opaque roof selects correct district")
	main._select_district("factory")
	var shop: AudioGrowthMask = view.sprites["shop"]
	shop.use_master_clock = false
	shop.begin_at(0)
	shop.sample_frame(shop.STEP_FRAMES*0.5)
	var count := empty_events.size()
	await click(view,body)
	check(empty_events.size() == count+1 and main._selected_id() == "factory","unrevealed roof does not intercept empty plot")
	shop.sample_frame(shop.end_frame())
	await click(view,body)
	check(main._selected_id() == "shop","revealed roof becomes pickable at same position")
	await click(view,view.point(Vector2i(7,8)))
	check(main._selected_id() == "home","compound owner plot independently selected")
	await click(view,view.point(Vector2i(8,8)))
	check(main._selected_id() == "partner","compound second plot independently selected")
	check(main.model.session.snapshot() == saved,"pixel picking does not mutate city/RNG/pending")
	print("PICKING %s checks=%d real_PNG/empty/roof/compound/zoom/readonly" % ["FAIL" if failed else "PASS",checks])
	main.queue_free()
	await frames()
	quit(1 if failed else 0)
