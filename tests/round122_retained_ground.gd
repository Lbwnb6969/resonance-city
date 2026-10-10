extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var checks: Dictionary = {}
var pixel_cases: Array = []

func _initialize() -> void: call_deferred("_run")

func _make(reference: bool) -> Control:
	var demo: Control = DemoScene.instantiate()
	if reference:
		var source := FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第122轮静态绘制前/continuous_valley_demo.gd.txt")
		var script := GDScript.new()
		script.source_code = source.replace("class_name ContinuousValleyDemo\n","")
		assert(script.reload() == OK)
		demo.set_script(script)
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	return demo

func _draw_demo(demo: Control) -> Image:
	demo.clock.renderer.transport.audible_frame = 66150.0
	demo._sync_buildings()
	demo.scenery.sync(demo)
	demo.queue_redraw()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _run() -> void:
	var actual := _make(false)
	actual.hide()
	var reference := _make(true)
	for view in [{"zoom":0.88,"pan":Vector2.ZERO},{"zoom":0.54,"pan":Vector2(100,-150)},{"zoom":1.2,"pan":Vector2(-60,45)}]:
		actual.view_zoom = view["zoom"]
		reference.view_zoom = view["zoom"]
		actual.pan = view["pan"]
		reference.pan = view["pan"]
		reference.show()
		var expected: Image = await _draw_demo(reference)
		reference.hide()
		actual.show()
		var image: Image = await _draw_demo(actual)
		var total_error := 0.0
		var changed := 0
		for y in range(0,image.get_height(),2):
			for x in range(0,image.get_width(),2):
				var a := image.get_pixel(x,y)
				var b := expected.get_pixel(x,y)
				var error := absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
				total_error += error/3.0
				if error > 0.06: changed += 1
		var samples := ceili(image.get_width()/2.0)*ceili(image.get_height()/2.0)
		var mean := total_error/samples
		var fraction := float(changed)/samples
		pixel_cases.append({"zoom":view["zoom"],"mean_rgb_error":mean,"changed_fraction":fraction})
		checks["appearance_"+str(view["zoom"])] = mean < 0.01 and fraction < 0.05
		actual.hide()
	reference.queue_free()
	await process_frame
	actual.show()
	actual.view_zoom = 0.88
	actual.pan = Vector2.ZERO
	await _draw_demo(actual)
	var terrain_draws: int = actual.terrain_layer.rebuild_count
	var city_draws: int = actual.city_ground_layer.rebuild_count
	var water_draws: int = actual.water_flow.draws
	var before: Dictionary = actual.model.world.snapshot()
	for i in range(5):
		actual.pan += Vector2(12,-6)
		await _draw_demo(actual)
	checks["pan_reuses_draw_commands"] = actual.terrain_layer.rebuild_count == terrain_draws and actual.city_ground_layer.rebuild_count == city_draws
	checks["water_keeps_animating"] = actual.water_flow.draws > water_draws
	checks["camera_keeps_world"] = actual.model.world.snapshot() == before
	var error := 0.0
	for lot in actual.shown_world.lots:
		var local: PackedVector2Array = actual.city_ground_layer._project_polygon(lot["polygon"])
		for i in range(local.size()):
			error = maxf(error,actual.city_ground_layer.to_global(local[i]).distance_to(actual.point(lot["polygon"][i])))
	checks["projection"] = error < 0.001
	actual.clock.renderer.source = actual.model._mix_frame
	var boundary: int = actual.model.next_boundary
	actual.model.submit({"kind":"bridge"})
	actual.clock.renderer.transport.rendered_frames = boundary
	actual.clock.renderer.render(512)
	actual.shown_world = actual.model.presentation_world(boundary-1)
	await _draw_demo(actual)
	checks["not_revealed_early"] = not actual.shown_world.bridge
	actual.shown_world = actual.model.presentation_world(boundary+33075)
	await _draw_demo(actual)
	checks["bridge_invalidates_city_ground"] = actual.city_ground_layer.rebuild_count > city_draws and actual.shown_world.bridge
	actual.black = true
	actual._sync_buildings()
	checks["black_hides_all_ground"] = not actual.terrain_layer.visible and not actual.city_ground_layer.visible and not actual.water_flow.visible and actual.backdrop.color == Color.BLACK
	actual.black = false
	actual._sync_buildings()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/第122轮_静态绘制.png")
	var result := {"passed":checks.values().all(func(ok: bool) -> bool: return ok),"checks":checks,"pixel_cases":pixel_cases,"max_projection_error":error,
		"terrain_rebuilds":actual.terrain_layer.rebuild_count,"city_rebuilds":actual.city_ground_layer.rebuild_count,"water_frames":actual.water_flow.draws}
	FileAccess.open("res://验证记录/连续河谷/第122轮_静态绘制.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("RETAINED_GROUND ",JSON.stringify(result))
	actual.queue_free()
	await process_frame
	quit(0 if result["passed"] else 1)
