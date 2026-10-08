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
	var name := "聚焦前轮廓复核" if "--focus" in OS.get_cmdline_user_args() else "轮廓点选_透明角落"
	root.get_texture().get_image().save_png("res://验证记录/Demo/"+name+".png")
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
	if "--focus" in OS.get_cmdline_user_args():
		marker.visible = false
		await check_focus(main)
	print("PICKING %s checks=%d real_PNG/empty/roof/compound/zoom/readonly" % ["FAIL" if failed else "PASS",checks])
	main.queue_free()
	await frames()
	quit(1 if failed else 0)

func image_bounds(view: Control,id: String) -> Rect2:
	var sprite: Sprite2D = view.sprites[id]
	return Rect2(sprite.position+sprite.get_rect().position*sprite.scale,sprite.get_rect().size*sprite.scale)
func check_focus(main: Control) -> void:
	var view: Control = main.city_view
	check(main.model.session.request_release(48,Vector2i(2,2),main.clock.renderer.transport.rendered_frames,main.clock.renderer.transport.audible_frame)["accepted"],"pending release fixture")
	main.diagnosis_button.button_pressed = true
	main._select_district("partner")
	await frames()
	var saved: Dictionary = main.model.session.snapshot()
	await click(main,main.focus_button.get_global_rect().get_center())
	check(view.camera_focusing and view.camera_age < float(view.camera_cfg["smooth_seconds"]),"actual focus button starts smooth movement")
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	await frames()
	var bounds := image_bounds(view,"home")
	var top := float(view.camera_cfg["header_height"])
	var bottom: float = view.get_node("MapNotice").position.y
	var center := Vector2(view.size.x*0.5,(top+bottom)*0.5)
	check(bounds.get_center().distance_to(center) < 0.01,"compound centered as whole image, not just its ground point")
	check(bounds.position.y >= top and bounds.end.y <= bottom and bounds.position.x >= 0 and bounds.end.x <= view.size.x,"whole compound clear of header/card/panel")
	check(main._selected_id() == "partner" and main.model.session.snapshot() == saved,"focus retains independent selected half and pending/RNG")
	check(view.view_zoom >= float(view.camera_cfg["focus_zoom"]) and view.view_zoom <= float(view.camera_cfg["maximum_zoom"]),"legal focus zoom")
	await frames()
	root.get_texture().get_image().save_png("res://验证记录/Demo/聚焦选中连宅.png")
	var cursor: Vector2 = view.point(Vector2i(8,8))
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = cursor
	view._gui_input(wheel)
	check(not view.camera_focusing,"wheel takes over focus")
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	check(view.point(Vector2i(8,8)).distance_to(cursor) < 0.01,"wheel preserves pivot after focus")
	await click(main,main.focus_button.get_global_rect().get_center())
	var before_pan: Vector2 = view.view_pan
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	middle.position = cursor
	view._gui_input(middle)
	var motion := InputEventMouseMotion.new()
	motion.position = cursor+Vector2(50,-20)
	motion.relative = Vector2(50,-20)
	view._gui_input(motion)
	middle.pressed = false
	view._gui_input(middle)
	check(not view.camera_focusing and view.view_pan.distance_to(before_pan+motion.relative) < 0.01,"middle drag stops focus without jumping")
	main._select_district("shop")
	await frames()
	await click(main,main.focus_button.get_global_rect().get_center())
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	await frames()
	bounds = image_bounds(view,"shop")
	check(bounds.get_center().distance_to(center) < 0.01 and bounds.position.y >= top and bounds.end.y <= bottom,"single tall building also framed")
	await click(main,main.controls.find_child("ResetView",true,false).get_global_rect().get_center())
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	check(view.view_pan == Vector2.ZERO and view.view_zoom == float(view.camera_cfg["default_zoom"]),"actual adjacent reset restores full map")
	check(main.model.session.snapshot() == saved,"all camera operations leave city/RNG/pending untouched")
	print("FOCUS_CAMERA PASS actual_button/whole_image/visible_area/interrupts/reset/readonly" if not failed else "FOCUS_CAMERA FAIL")
