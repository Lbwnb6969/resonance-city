extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var cases: Array = []

func _initialize() -> void: call_deferred("_run")

func _make(reference: bool) -> Control:
	var demo: Control = DemoScene.instantiate()
	if reference:
		var script := GDScript.new()
		script.source_code = FileAccess.get_file_as_string("res://scripts/ui/continuous_valley_demo.gd").replace("class_name ContinuousValleyDemo","").replace("var scenery := ValleyScenery.new()","var scenery: RefCounted")
		assert(script.reload() == OK)
		demo.set_script(script)
		var scenery_script := GDScript.new()
		scenery_script.source_code = FileAccess.get_file_as_string("res://废弃/scripts/2026-10-10_第123轮交通查询前/valley_scenery.gd.txt").replace("class_name ValleyScenery","")
		assert(scenery_script.reload() == OK)
		demo.scenery = RefCounted.new()
		demo.scenery.set_script(scenery_script)
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	return demo

func _capture(demo: Control, frame: int) -> Image:
	demo.clock.renderer.transport.audible_frame = float(frame)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	demo.queue_redraw()
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _run() -> void:
	var actual := _make(false)
	actual.hide()
	var reference := _make(true)
	var equal := true
	for frame in [0,4410,11025,66150]:
		reference.show()
		var expected := await _capture(reference,frame)
		reference.hide()
		actual.show()
		var image := await _capture(actual,frame)
		var error := 0.0
		for y in range(0,image.get_height(),2):
			for x in range(0,image.get_width(),2):
				var a := image.get_pixel(x,y)
				var b := expected.get_pixel(x,y)
				error = maxf(error,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
		cases.append({"frame":frame,"max_rgb_error":error})
		equal = equal and error == 0.0
		actual.hide()
	actual.show()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/第123轮_小景绘制.png")
	var result := {"passed":equal,"cases":cases,"scope":"Exact GPU pixels versus archived scenery at reveal/animation frames"}
	FileAccess.open("res://验证记录/连续河谷/第123轮_小景绘制.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("SCENERY_RENDER ",JSON.stringify(result))
	actual.queue_free()
	reference.queue_free()
	await process_frame
	quit(0 if equal else 1)
