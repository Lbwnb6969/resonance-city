extends SceneTree
const Schema = preload("res://scripts/city/district_schema.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Growth = preload("res://scripts/city/city_growth.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
var failed := false
var checks := 0
func _initialize() -> void: call_deferred("run_check")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("BOUNDARY_DIAGNOSIS_FAIL "+message)
func refresh(main: Control, at: float) -> void:
	main.clock.renderer.transport.audible_frame = at
	main._process(0.0)
	main.city_view._process(0.0)
func edge(rows: Array[Dictionary], other: String) -> Dictionary:
	for row in rows:
		if row["a"] == other or row["b"] == other: return row
	return {}
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/Demo/边界诊断_"+name+".png")
func run_check() -> void:
	check(DisplayServer.get_name() != "headless","requires actual GPU")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	var city := [Schema.create("home","residential",Vector2i(7,7)),
		Schema.create("minor","residential",Vector2i(8,7)),
		Schema.create("rough","industrial",Vector2i(7,8)),
		Schema.create("third","commercial",Vector2i(6,7))]
	city[1]["current_midi"] = 49
	Growth.assign_assets(city)
	main.model = Model.new(Session.new(city,"2026100900000001"))
	main.model.session.growth_enabled = true
	main.clock.renderer.source = main.model._mix_frame
	main.clock.renderer.state = main.model.synth.initial_state()
	for sprite in main.city_view.sprites.values(): sprite.queue_free()
	for label in main.city_view.labels.values(): label.queue_free()
	main.city_view.sprites.clear()
	main.city_view.labels.clear()
	main.city_view.forms.clear()
	main.city_view.appearance.clear()
	main.city_view.base_scales.clear()
	main.city_view.session = main.model.session
	main._refresh_district_list()
	main._select_district("home")
	refresh(main,0)
	check(not main.city_view.diagnosis_enabled,"diagnosis default OFF")
	var saved: Dictionary = main.model.snapshot()
	var renderer_saved: Dictionary = main.clock.renderer.snapshot()
	var plain: PackedVector2Array = main.clock.renderer.render(127)
	main.model.restore(saved)
	main.clock.renderer.restore(renderer_saved)
	main.diagnosis_button.button_pressed = true
	refresh(main,0)
	check(main.model.snapshot() == saved,"display toggle and query leave model/RNG untouched")
	var diagnosed: PackedVector2Array = main.clock.renderer.render(127)
	check(plain == diagnosed,"display toggle does not alter PCM")
	refresh(main,0)
	var view = main.city_view
	var rows: Array[Dictionary] = view.diagnosis_edges
	check(rows.size() == 3,"only three actual undirected neighbor edges")
	var minor := edge(rows,"minor")
	var rough := edge(rows,"rough")
	check(minor["kind"] == "抖" and is_equal_approx(minor["beat_hz"],7.78),"real C-C sharp beat")
	check(is_equal_approx(minor["display_hz"],7.78/8.0),"approved visual frequency")
	check(rough["kind"] == "刺" and rough["display_hz"] == 0.0,"tritone is stationary")
	check(edge(rows,"third")["kind"] == "协和","commercial E is not falsely rough")
	check("minor" in main.map_notice.text and "抖" in main.map_notice.text and "rough" in main.map_notice.text and "刺" in main.map_notice.text,"selected card lists real neighbors")
	var first: PackedVector2Array = view.diagnosis_points(minor)
	var rough_first: PackedVector2Array = view.diagnosis_points(rough)
	refresh(main,main.clock.renderer.transport.sample_rate/4.0)
	check(view.diagnosis_points(minor) != first,"ripple follows audible frame")
	check(view.diagnosis_points(rough) == rough_first,"rough teeth do not pulse")
	main.reduced_motion_button.button_pressed = true
	var reduced: PackedVector2Array = view.diagnosis_points(minor,1)
	refresh(main,main.clock.renderer.transport.sample_rate/2.0)
	check(view.diagnosis_points(minor,1) == reduced,"reduced mode is static")
	check(view.diagnosis_points(minor,-1) != reduced,"reduced mode retains two distinct waves")
	main.reduced_motion_button.button_pressed = false
	var cursor: Vector2 = view.point(Vector2i(7,7))
	var wheel := InputEventMouseButton.new()
	wheel.position = cursor
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	for i in range(5): view._gui_input(wheel)
	await create_timer(float(view.camera_cfg["smooth_seconds"])+0.05).timeout
	check(view.point(Vector2i(7,7)).distance_to(cursor) < 0.01,"diagnostic zoom keeps world pivot")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = view.point(Vector2i(7,7))
	view._gui_input(click)
	check(main._selected_id() == "home","zoomed house selection")
	refresh(main,main.clock.renderer.transport.sample_rate/2.0)
	await capture("动态与邻接")
	main.reduced_motion_button.button_pressed = true
	await capture("减弱运动")
	main.model.synth.set_mute("minor",true)
	refresh(main,0)
	check(not edge(view.diagnosis_edges,"minor")["audible"] and "Mute隔离" in main.map_notice.text,"muted neighbor label")
	main.model.synth.set_mute("minor",false)
	main.model.synth.set_solo("home")
	refresh(main,0)
	check(not edge(view.diagnosis_edges,"minor")["audible"] and "Solo隔离" in main.map_notice.text,"solo cannot imply a heard pair")
	main.model.synth.set_solo("")
	main.model.synth.active_layers.erase("drone")
	refresh(main,0)
	check("长音已关闭" in main.map_notice.text,"disabled drone label")
	main.model.synth.active_layers.append("drone")
	# A high/low octave minor interval outside the physical slow range is not called 抖.
	var outside = main.model.session.fork()
	outside._district("minor")["current_midi"] = 59
	check(edge(view.diagnosis.edges(outside,main.model.synth,0),"minor")["kind"] == "其它张力","octave-spanning minor is not a slow beat")
	main.want_preview = true
	main._update_map_notice()
	check("边界来自当前城市；试听是未来声音" in main.map_notice.text,"preview provenance clear")
	main.want_preview = false
	# Actual road and retune settle ahead; diagnosis must wait for the audible frame.
	var period: int = main.model.next_boundary
	var a := Vector2i(7,7)
	var b := Vector2i(7,8)
	var ends := Roads.endpoints(a,b)
	main.model.session.road_marks[Roads.key(a,b)] = {"start":ends[0],"end":ends[1],"count":2,"frame":0}
	check(main.model.session.request_tread(a,b,main.clock.renderer.transport.rendered_frames,0)["accepted"],"road request")
	main.clock.renderer.transport.rendered_frames = period
	main.clock.renderer.render(17)
	refresh(main,period-1)
	check(view.diagnosis_edges.size() == 3,"unheard road keeps edge")
	refresh(main,period)
	check(view.diagnosis_edges.size() == 2 and edge(view.diagnosis_edges,"rough").is_empty(),"heard road removes edge")
	var proposal := "p0:%d:minor:retune" % main.model.session.refresh_cycle
	check(main.model.session.request({"proposal_id":proposal,"target":48},main.clock.renderer.transport.rendered_frames,period)["accepted"],"retune request")
	main.clock.renderer.transport.rendered_frames = 2*period
	main.clock.renderer.render(17)
	refresh(main,2*period-1)
	check(edge(view.diagnosis_edges,"minor")["kind"] == "抖","unheard retune keeps old kind")
	refresh(main,2*period)
	check(edge(view.diagnosis_edges,"minor")["kind"] == "共鸣","heard retune updates kind")
	# Place a formerly isolated house next to home: relation exists but voice is temporarily silent.
	proposal = "p0:%d:rough:relocate" % main.model.session.refresh_cycle
	check(main.model.session.request({"proposal_id":proposal,"target":[7,6]},main.clock.renderer.transport.rendered_frames,2*period)["accepted"],"migration request")
	main.clock.renderer.transport.rendered_frames = 3*period
	main.clock.renderer.render(17)
	refresh(main,3*period)
	check(edge(view.diagnosis_edges,"rough")["kind"] == "刺" and not edge(view.diagnosis_edges,"rough")["audible"],"moved rough relation labeled inaudible")
	check("迁移静音" in main.map_notice.text,"temporary mute reason")
	main.clock.renderer.transport.rendered_frames = 4*period
	main.clock.renderer.render(17)
	refresh(main,4*period)
	check(edge(view.diagnosis_edges,"rough")["audible"],"voice becomes audible after one phrase")
	main.set_black_screen(true)
	check(not main.city_view.visible and not main.panel.visible,"black hides diagnosis")
	main.set_black_screen(false)
	main.diagnosis_button.button_pressed = false
	check(not view.diagnosis_enabled and not main.reduced_motion_button.visible and not main.diagnosis_legend.visible,"OFF collapses diagnosis controls")
	print("BOUNDARY_DIAGNOSIS ","FAIL" if failed else "PASS"," checks=",checks," true_edges/types/audio_frames/reduced/mute/solo/road/retune/move/PCM/camera")
	main.queue_free()
	await process_frame
	quit(1 if failed else 0)
