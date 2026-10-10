extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Ground = preload("res://scripts/visual/valley_ground_layer.gd")
const Job = preload("res://scripts/world/world_settlement_job.gd")
var samples: Array = []
func _initialize() -> void: call_deferred("_run")
static func profile_script() -> GDScript:
	var methods := ""
	for name in ["_draw_center_markers","_draw_green_corridors","_draw_public_space","_draw_fabric_overlay","_draw_urban"]:
		methods += "func "+name+"() -> void:\n\tvar began := Time.get_ticks_usec()\n\tsuper."+name+"()\n\tstages[\""+name+"\"] = float(Time.get_ticks_usec()-began)/1000.0\n"
	var script := GDScript.new()
	script.source_code = "extends \"res://scripts/visual/valley_ground_layer.gd\"\nvar stages: Dictionary = {}\n"+methods
	assert(script.reload() == OK)
	return script
func _sample(demo: ContinuousValleyDemo,ground: Node2D,label: String) -> void:
	demo._prepare_ground()
	ground.sync(demo)
	await RenderingServer.frame_post_draw
	samples.append({"label":label,"draw_ms":ground.last_draw_ms,"stages":ground.get("stages").duplicate(),"fabric_hash":hash(demo.shown_world.fabric_cache),
		"walls":demo.shown_world.fabric_cache.get("shared_walls",[]).size(),"rows":demo.shown_world.fabric_cache.get("rows",[]).size(),"courtyards":demo.shown_world.fabric_cache.get("courtyards",[]).size(),"lots":demo.shown_world.lots.size()})
func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var city := ContinuousWorld.regional_sample()
	demo.model = ContinuousAudioModel.new(city)
	demo.shown_world = city
	demo.size = Vector2(1024,768)
	demo.pan = Vector2.ZERO
	demo.view_zoom = 0.35
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024,768)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var ground: Node2D = profile_script().new()
	ground.role = "urban"
	viewport.add_child(ground)
	await _sample(demo,ground,"regional1511")
	var job := Job.new()
	job.start(city,[],int(city.cfg["timing"]["phrase_frames"])*(city.phrase_index+1))
	while not job.completed(): await process_frame
	job.join()
	job.adopt(city)
	await _sample(demo,ground,"regional1525")
	FileAccess.open("res://验证记录/连续河谷/第141轮_地面分项_原版.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"\t")+"\n")
	print("GROUND_PROFILE ",JSON.stringify(samples))
	viewport.queue_free()
	demo.queue_free()
	await process_frame
	quit()
