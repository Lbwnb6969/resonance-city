extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Fixture = preload("res://tests/ring_fixture.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Preview = preload("res://scripts/proposals/proposal_preview.gd")
const Presentation = preload("res://scripts/ui/proposal_presentation.gd")
const DIR = "res://验证记录/Demo/CITY-005_第57轮/"
var main: Control
var model: CityAudioModel
var state: Dictionary
var test := Contract.new("CITY-005","ring_demo_round57")
func _initialize() -> void: call_deferred("run_check")
func show_at(at: int) -> void:
	main.clock.renderer.transport.audible_frame = at
	main.clock.renderer.transport.rendered_frames = maxi(at,model.next_boundary)
	main._process(0)
func draw_save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	if not name.is_empty(): root.get_texture().get_image().save_png(DIR+name+".png")
func choice(id: String, verb: String, target: Variant) -> Dictionary:
	for proposal in model.session.catalog:
		if proposal["district_id"] == id and proposal["verb"] == verb:
			return {"proposal_id":proposal["proposal_id"],"verb":verb,"target":target}
	return {}
func run_check() -> void:
	main = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	current_scene = main
	await process_frame
	main.set_process(false)
	var city := Fixture.city(false)
	load("res://scripts/city/city_growth.gd").assign_assets(city)
	model = Model.new(Session.new(city,"0000000000000057"))
	model.session.growth_enabled = true
	model.session.draft_pause_until = 22050*1000
	state = model.synth.initial_state()
	var view: Control = main.city_view
	for sprite in view.sprites.values(): sprite.queue_free()
	for label in view.labels.values(): label.queue_free()
	for field in [view.sprites,view.labels,view.forms,view.appearance,view.base_scales,view.event_seen]: field.clear()
	main.model = model
	view.session = model.session
	main.clock.renderer.source = model._mix_frame
	main.clock.renderer.state = state
	main.clock.renderer.transport.audible_frame = 0
	main._refresh_district_list()
	main._select_district("ring_source")
	var first := model.next_boundary
	model.render_block(state,first,1,22050)
	show_at(first-1)
	await draw_save("")
	test.check(view.session.rings.is_empty() and main.formation_notice.first_seen.is_empty(),"Future ring identity and notice wait for audible boundary")
	show_at(first+22050)
	main.formation_notice.tick(0.2,first+22050,view.session,false,false)
	await draw_save("环形雏形")
	test.check(DisplayServer.get_name() != "headless" and view.sprites.size() == 9,"Actual GPU production city with all nine controlled entities")
	test.check(view.session.rings["ring_source"]["status"] == "unison" and view.ring_overlay.last_dots.is_empty() and model.synth.ring_snapshot().is_empty(),"Unison draws prototype without dot or audio replacement")
	test.check(main.map_notice.text.contains("雏形·齐唱") and main.map_notice.text.contains("C → C") and main.formation_notice.title.text.contains("环形雏形") and main.formation_notice.card.modulate.a == 1.0,"Selected source condition and first prototype notice use real ordered notes")
	test.check(view.ring_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE,"Overlay allows existing map interaction")
	main.formation_notice.card.get_node("Rows/Header/Close").pressed.emit()
	main.formation_notice.tick(2,first+22050,view.session,false,true)
	var retune := choice("ring_1","retune",52)
	var forecast := Preview.forecast(model.session,retune,model.next_boundary,model.next_boundary)
	test.check(forecast["accepted"] and Presentation.summary(forecast["result"]).contains("本次1/2"),"Real retune forecast displays consecutive count")
	model.session.request(retune,model.next_boundary,model.next_boundary)
	model.render_block(state,model.next_boundary,1,22050)
	show_at(model.next_boundary-352800)
	await draw_save("")
	test.check(main.map_notice.text.contains("连续1/2") and view.ring_overlay.last_dots.is_empty(),"First mixed boundary shows waiting condition without dot")
	var formed := model.next_boundary
	model.render_block(state,formed,1,22050)
	show_at(formed-1)
	await draw_save("")
	test.check(view.session.rings["ring_source"]["status"] == "candidate" and view.ring_overlay.last_dots.is_empty(),"Prefilled second boundary remains visually candidate until audible")
	show_at(formed+22050)
	for queued in range(4):
		if main.formation_notice.title.text.contains("环形合唱城"): break
		main.formation_notice.dismiss()
		main.formation_notice.tick(2,formed+22050,view.session,false,true)
	await draw_save("环形成形")
	test.check(view.session.rings["ring_source"]["status"] == "formed" and main.map_notice.text.contains("C → E → C") and main.formation_notice.title.text.contains("环形合唱城"),"Second real mixed boundary names ring through unified notice rail")
	test.check(main.formation_notice.first_seen.has("环形雏形") and main.formation_notice.first_seen.has("环形合唱城") and model.ring_history.size() == 2 and not view.camera_focusing,"Only two ring discoveries and no automatic camera focus")
	var saved := model.snapshot()
	for index in range(8):
		var at := formed+88200+index*11025+1102
		show_at(at)
		await draw_save("")
		var dot: Dictionary = view.ring_overlay.last_dots["ring_source"]
		var offset: Array = view.ring_overlay.cfg["offsets"][index]
		test.check(dot["index"] == index and dot["position"].distance_to(view.point(Vector2i(8,8)+Vector2i(offset[0],offset[1]))) < 0.001,"Actual audible dot rests on sounding member %d" % index)
	show_at(formed+88200+8268)
	await draw_save("轮唱光点")
	var dot: Dictionary = view.ring_overlay.last_dots["ring_source"]
	var half: Vector2 = view.point(Vector2i(7,7)).lerp(view.point(Vector2i(8,7)),0.5)
	test.check(dot["position"].distance_to(half) < 0.1,"After sound tail dot eases toward next actual member")
	view.reduced_motion = true
	await draw_save("")
	test.check(view.ring_overlay.last_dots["ring_source"]["position"] == view.point(Vector2i(7,7)),"Reduced motion holds static sounding member until next beat")
	view.view_zoom = 1.2
	view.view_pan = Vector2(25,-10)
	await draw_save("")
	test.check(view.ring_overlay.last_dots["ring_source"]["position"] == view.point(Vector2i(7,7)),"Ring uses the same map zoom and pan")
	model.synth.set_solo("ring_0")
	main._update_map_notice()
	test.check(main.map_notice.text.contains("只能听到部分声部"),"Solo warning in ring condition area")
	model.synth.set_solo("")
	test.check(model.snapshot() == saved,"Presentation, dot, camera and temporary Solo restoration leave simulation and oscillator snapshot unchanged")
	main.set_black_screen(true)
	await draw_save("环形黑屏")
	test.check(not main.formation_notice.is_visible_in_tree(),"Black screen also hides discovery rail")
	main.set_black_screen(false)
	# Real relocation is forecast and settled, preserving the nine buildings.
	var relocate := choice("ring_0","relocate",[1,1])
	var before := model.snapshot()
	var lost := Preview.forecast(model.session,relocate,model.next_boundary,model.next_boundary)
	test.check(lost["accepted"] and Presentation.summary(lost["result"]).contains("将失去环形合唱城") and model.snapshot() == before,"Real relocation forecasts loss without changing city")
	model.session.request(relocate,model.next_boundary,model.next_boundary)
	var exit := model.next_boundary
	model.render_block(state,exit,1,22050)
	show_at(exit-1)
	await draw_save("")
	test.check(view.session.rings["ring_source"]["status"] == "formed","Old audible ring survives before relocation boundary")
	show_at(exit)
	await draw_save("")
	test.check(view.session.rings["ring_source"]["count"] == 0 and view.ring_overlay.last_dots.is_empty() and model.session.city.size() == 9 and model.session._district("ring_0")["footprint"] == [[1,1]],"Actual relocation resets identity and keeps houses; exit fade remains audio-only")
	test.details = {"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"facts":model.ring_history,"images":["环形雏形.png","环形成形.png","轮唱光点.png","环形黑屏.png"],"scope":"Controlled layout and actual transactions/settlements; actual production GPU. Not a natural player run or human art approval."}
	main.clock.stop_output()
	test.finish(self,"Actual production GPU, audible prototype/formed/dot gates, ordered conditions/notices, camera/reduced motion/B, actual relocation forecast and loss",false)
	main.queue_free()
	await process_frame
	await process_frame
	quit(0 if test.failures == 0 else 1)
