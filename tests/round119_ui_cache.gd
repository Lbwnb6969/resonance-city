extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.clock.renderer.transport.audible_frame = 22050.0
	demo._sync_buildings()
	demo.scenery.sync(demo)
	var rebuilds := demo.shadow_layer.rebuild_count
	for i in range(6): demo._sync_buildings()
	_check(demo.shadow_layer.rebuild_count == rebuilds,"stable city keeps union mask")
	demo.view_zoom = 0.54
	demo.pan = Vector2(100,-150)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	_check(demo.shadow_layer.rebuild_count == rebuilds,"camera does not rebuild shadows")
	var projection_error := 0.0
	for id in demo.sprites:
		projection_error = maxf(projection_error,demo.sprites[id].global_position.distance_to(demo.point(WorldCoupling.position_of(demo.shown_world.by_id[id]))))
	var polygon_error := 0.0
	for lot in demo.shown_world.lots:
		var projected: PackedVector2Array = demo._project_polygon(lot["polygon"])
		for i in range(projected.size()): polygon_error = maxf(polygon_error,projected[i].distance_to(demo.point(lot["polygon"][i])))
	_check(projection_error < 0.001 and polygon_error < 0.001,"cached projection follows camera")
	var sprite: Sprite2D = demo.sprites.values()[0]
	var id: String = demo.sprites.keys()[0]
	var image: Image = demo.asset_images[demo.shown_world.by_id[id]["type"]]
	var hit := ""
	for y in range(image.get_height()/2,image.get_height(),7):
		for x in range(0,image.get_width(),7):
			if image.get_pixel(x,y).a <= 0.9: continue
			hit = demo._hit(sprite.to_global(sprite.offset+Vector2(x,y)))
			if not hit.is_empty(): break
		if not hit.is_empty(): break
	_check(not hit.is_empty(),"alpha hit works after layer transform")
	var played_id: String = demo.shown_world.buildings[0]["district_id"]
	demo.model.sound_overrides[played_id] = 36
	demo._sync_buildings()
	_check(is_equal_approx(demo.sprites[played_id].modulate.b,0.92),"retune invalidates settled building tint")
	var evidence := {"passed":failures.is_empty(),"projection_error":projection_error,"polygon_error":polygon_error,"failures":failures}
	FileAccess.open("res://验证记录/连续河谷/第119轮_显示缓存.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("UI_CACHE ",JSON.stringify(evidence))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
