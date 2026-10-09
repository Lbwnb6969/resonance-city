extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Growth = preload("res://scripts/city/city_growth.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Values = preload("res://scripts/spec_values.gd")
const DIR := "res://验证记录/Demo/AUDIO-007_第58轮/"
var test := Contract.new("AUDIO-007","projection_pan_round58")
func _initialize() -> void: call_deferred("run_check")
func _stereo_side(value: Vector2) -> String:
	if value.x > value.y+0.0001: return "left"
	if value.y > value.x+0.0001: return "right"
	return "center"
func _city() -> Array:
	var result: Array = []
	for item in [["left",Vector2i(0,10),"residential"],["center",Vector2i(15,15),"commercial"],["right",Vector2i(10,0),"industrial"]]:
		result.append(Schema.create(item[0],item[2],item[1]))
	return result
func _clear_view(view: Control) -> void:
	for sprite in view.sprites.values(): sprite.queue_free()
	for label in view.labels.values(): label.queue_free()
	for field in [view.sprites,view.labels,view.forms,view.appearance,view.base_scales,view.event_seen]: field.clear()
func draw_save(main: Control,name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+name+".png")
func run_check() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var values: Dictionary = Values.load_values()
	var city := _city()
	var synth := Synth.new(city)
	var route_sides: Dictionary = {}
	for route in synth.routing: route_sides[route["id"]] = _stereo_side(route["stereo"])
	test.check(route_sides == {"left":"left","center":"center","right":"right"},"A16 maps x-y projection to left/center/right, including (15,15) center")
	test.check(is_equal_approx(synth.routing[0]["stereo"].length(),1.0) and is_equal_approx(synth.routing[1]["stereo"].length(),1.0) and is_equal_approx(synth.routing[2]["stereo"].length(),1.0),"A5 equal-power pan values remain unit length")
	var pan_regions: Array = values["synthesis"]["pan_regions"]
	test.check(int(pan_regions[0][0]) == 0 and int(pan_regions[0][1]) == 4 and is_equal_approx(float(pan_regions[0][2]),-0.6) and int(pan_regions[1][0]) == 5 and int(pan_regions[1][1]) == 10 and is_zero_approx(float(pan_regions[1][2])) and int(pan_regions[2][0]) == 11 and int(pan_regions[2][1]) == 15 and is_equal_approx(float(pan_regions[2][2]),0.6),"Formal A5 pan values and protocol fixture remain unchanged")
	var moved_city: Array = [Schema.create("factory","industrial",Vector2i(3,6))]
	var moved := Model.new(Session.new(moved_city,"0000000000000058"))
	var state := moved.synth.initial_state()
	var boundary := moved.next_boundary
	var before := moved.snapshot()
	var request := moved.session.request({"proposal_id":"p0:0:factory:relocate","verb":"relocate","target":[10,0]},boundary-1,boundary-2000.0)
	test.check(request["accepted"] and moved.synth.routing[0]["stereo"] == Vector2(cos(PI/4.0),sin(PI/4.0)),"Relocation is accepted and remains center-panned before its quantized boundary")
	moved.render_block(state,boundary-1,1,22050)
	test.check(moved.synth.routing[0]["stereo"] == Vector2(cos(PI/4.0),sin(PI/4.0)) and moved.session.city[0]["footprint"] == [[3,6]],"Rendered sample before boundary keeps old location and pan")
	moved.render_block(state,boundary,1,22050)
	test.check(moved.session.city[0]["footprint"] == [[10,0]] and _stereo_side(moved.synth.routing[0]["stereo"]) == "right","Quantized relocation changes world pan exactly at the committed boundary")
	test.check(moved.session.snapshot()["phrase_index"] == 1 and moved.session.pending.is_empty(),"Quantized transaction advances only at the real phrase boundary")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	current_scene = main
	await process_frame
	main.set_process(false)
	var gpu_city := _city()
	Growth.assign_assets(gpu_city)
	var gpu_model := Model.new(Session.new(gpu_city,"0000000000000058"))
	main.model = gpu_model
	main.city_view.session = gpu_model.session
	main.clock.renderer.source = gpu_model._mix_frame
	main.clock.renderer.state = gpu_model.synth.initial_state()
	main.clock.renderer.transport.audible_frame = 0
	main.clock.renderer.transport.rendered_frames = 0
	_clear_view(main.city_view)
	main._refresh_district_list()
	main._select_district("center")
	main._process(0)
	await draw_save(main,"投影声像_默认镜头")
	var origin: float = main.city_view.point(Vector2i(15,15)).x
	var left_x: float = main.city_view.point(Vector2i(0,10)).x
	var right_x: float = main.city_view.point(Vector2i(10,0)).x
	test.check(left_x < origin and origin < right_x,"Actual isometric screen projection orders left/center/right by x-y")
	test.check(main.city_view.sprites.size() == 3 and DisplayServer.get_name() != "headless","Actual production viewport supplies the three spatial counterexamples")
	var frozen_city := gpu_model.session.snapshot()
	var stereo_before: Dictionary = {}
	for route in gpu_model.synth.routing: stereo_before[route["id"]] = route["stereo"]
	main.city_view.view_pan = Vector2(180,-95)
	main.city_view.view_zoom = 1.35
	main._process(0)
	await draw_save(main,"投影声像_平移缩放")
	var stereo_after: Dictionary = {}
	for route in gpu_model.synth.routing: stereo_after[route["id"]] = route["stereo"]
	test.check(stereo_before == stereo_after and gpu_model.session.snapshot() == frozen_city,"Camera pan/zoom changes only projection, never route pan or city/RNG state")
	var pan_positions := {"left":main.city_view.point(Vector2i(0,10)),"center":main.city_view.point(Vector2i(15,15)),"right":main.city_view.point(Vector2i(10,0))}
	test.check(pan_positions["left"].x < pan_positions["center"].x and pan_positions["center"].x < pan_positions["right"].x,"Panned camera preserves the same world ordering")
	main.city_view.reset_view()
	await draw_save(main,"投影声像_复位")
	test.check(main.city_view.camera_resetting and stereo_before == stereo_after,"Reset is a view operation and leaves audio world unchanged")
	test.details = {"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"route_sides":route_sides,"screen_x": {"left":left_x,"center":origin,"right":right_x},"images":["投影声像_默认镜头.png","投影声像_平移缩放.png","投影声像_复位.png"],"formal_protocol":"A5 pan values unchanged; this contract tests Demo A16 only"}
	main.queue_free()
	await process_frame
	test.finish(self,"A16 x-y projection, equal-power route pan, quantized relocation and camera read-only behavior; no human localization claim",false)
	quit(0 if test.failures == 0 else 1)
