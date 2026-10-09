extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Stage = preload("res://scripts/audio/growth_voice.gd")
const Notice = preload("res://scripts/ui/formation_notice.gd")
const DIR = "res://验证记录/Demo/A13_U15_第56轮/"
func _initialize() -> void: call_deferred("run_check")
func draw_save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+name+".png")
func run_check() -> void:
	var test := Contract.new("UI-005","formation_round56")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	current_scene = main
	await process_frame
	main.set_process(false)
	var notice: Control = main.formation_notice
	test.check(main.formation_button.button_pressed and notice.enabled,"Production formation hints default ON")
	# Conditions are evaluated by the real settlement, including an intentionally non-consonant neighbor.
	var city: Array = []
	for x in range(7,11):
		for y in range(7,10):
			var d := Schema.create("fixture_%d_%d" % [x,y],"residential",Vector2i(x,y))
			d["current_midi"] = 50 if Vector2i(x,y) == Vector2i(8,9) else 48
			d["anchor_id"] = "fixture_source"
			d["voice_level"] = 0.2
			d["form"] = "胚"
			city.append(d)
	var source := Schema.create("fixture_source","residential",Vector2i(6,8))
	source["current_midi"] = 48
	source["anchor_id"] = "fixture_source"
	source["is_anchor"] = true
	source["voice_level"] = 0.2
	city.append(source)
	var model := Model.new(Session.new(city,main.generation["seed"]))
	model.session.growth_enabled = true
	model.synth.guard_enabled = true
	var state := model.synth.initial_state()
	for phrase in range(5):
		model.render_block(state,model.next_boundary,17,22050)
		model.presentation_session(model.next_boundary-352800+11042)
	var forms: Dictionary = {}
	for fact in model.growth_history: forms[fact["event"]["form"]] = true
	test.check(forms.has("群") and forms.has("央") and forms.has("腔"),"Real growth rules produce group, center and chamber in the controlled layout")
	if test.failures > 0:
		test.finish(self,"Controlled actual-settlement fixture unavailable")
		return
	var snapshot := model.snapshot()
	var original_state := state.duplicate(true)
	var first_frame := int(model.growth_history[0]["event"]["frame"])
	notice.consume(model.growth_history,first_frame-1)
	test.check(notice.first_seen.is_empty() and notice.queue.is_empty(),"Pre-rendered future facts do not occupy first records")
	notice.consume(model.growth_history,first_frame)
	notice.tick(0,first_frame+22049,model.session,false,true)
	test.check(notice.current.is_empty(),"Card waits through reveal and its following beat")
	notice.tick(0,first_frame+22050,model.session,false,true)
	test.check(notice.current["event"]["form"] == "群" and notice.read_remaining == 6.0,"First group appears on exact next beat with six seconds reading")
	var chosen: String = notice.current["event"]["district_id"]
	var same_frame: Array[String] = []
	for fact in model.growth_history:
		if fact["event"]["form"] == "群" and int(fact["event"]["frame"]) == first_frame: same_frame.append(str(fact["event"]["district_id"]))
	same_frame.sort()
	test.check(chosen == same_frame[0],"Stable ID resolves same-frame first-stage ties")
	notice.consume(model.growth_history,model.next_boundary)
	var queued: int = notice.queue.size()
	notice.consume(model.growth_history,model.next_boundary)
	test.check(queued == 2 and notice.queue.size() == 2 and notice.first_seen.size() == 3,"Exactly one record per actual stage, repeated history cannot replay")
	test.check(notice.meaning.text.contains("节奏加入") and notice.next_step.text.contains("央") and notice.next_step.text.contains("腔"),"Sound cause and both real mature branches appear")
	# Put the actual controlled city into the production viewport to inspect the real card.
	for sprite in main.city_view.sprites.values(): sprite.queue_free()
	for label in main.city_view.labels.values(): label.queue_free()
	for field in [main.city_view.sprites,main.city_view.labels,main.city_view.forms,main.city_view.appearance,main.city_view.base_scales,main.city_view.event_seen]: field.clear()
	main.model = model
	main.city_view.session = model.session
	main.clock.renderer.source = model._mix_frame
	main.clock.renderer.state = state
	main.clock.renderer.transport.rendered_frames = model.next_boundary-1
	main.clock.renderer.transport.audible_frame = model.next_boundary-1
	main._refresh_district_list()
	main._process(0)
	notice.tick(0,model.next_boundary,model.session,false,true)
	await draw_save("首次成形_群")
	print("CARD_LAYOUT ",notice.card.size," min ",notice.card.get_combined_minimum_size()," title ",notice.title.size," titlemin ",notice.title.get_combined_minimum_size()," rows ",notice.card.get_node("Rows").size," rowmin ",notice.card.get_node("Rows").get_combined_minimum_size())
	test.check(DisplayServer.get_name() != "headless","Actual GPU viewport")
	test.check(notice.card.size.x <= 360.0 and notice.global_position.y >= 154.0 and notice.card.get_global_rect().end.x < main.panel.get_global_rect().position.x and notice.card.get_global_rect().end.y < main.city_view.get_node("MapNotice").get_global_rect().position.y,"Four-row card stays below title, above footer and outside right panel")
	# Use viewport input to exercise actual hover and click dispatch.
	var move := InputEventMouseMotion.new()
	move.position = notice.card.global_position+Vector2(120,80)
	move.global_position = move.position
	Input.parse_input_event(move)
	await process_frame
	test.check(notice.hovered,"Actual pointer hover reaches card")
	var read_before: float = notice.read_remaining
	notice.tick(2,model.next_boundary,model.session,false,true)
	test.check(notice.read_remaining == read_before,"Hover pauses full reading timer")
	main.city_view.selected_id = model.session.city[-1]["district_id"]
	main.model.session.pending = {"test_marker":true}
	var pending: Dictionary = main.model.session.pending.duplicate(true)
	var press := InputEventMouseButton.new()
	press.position = move.position
	press.global_position = press.position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	press = press.duplicate()
	press.pressed = false
	Input.parse_input_event(press)
	await process_frame
	test.check(main._selected_id() == chosen and main.city_view.selected_id == chosen and main.city_view.camera_focusing and main.model.session.pending == pending and not notice.current.is_empty(),"Manual card click selects and focuses its own building, retains card and pending")
	main.model.session.pending.clear()
	main.set_black_screen(true)
	notice.tick(2,model.next_boundary,model.session,true,true)
	test.check(not notice.is_visible_in_tree() and notice.read_remaining == read_before,"B hides card and pauses reading")
	await draw_save("首次成形_黑屏")
	var black_image := root.get_texture().get_image()
	var pixels_black := true
	for point in [Vector2i(0,0),Vector2i(360,200),Vector2i(720,450),Vector2i(1439,899)]:
		var pixel := black_image.get_pixelv(point)
		pixels_black = pixels_black and pixel.r == 0.0 and pixel.g == 0.0 and pixel.b == 0.0
	test.check(pixels_black,"Black screen covers former card, map and panel")
	main.set_black_screen(false)
	notice.hovered = false
	notice.tick(6,model.next_boundary,model.session,false,true)
	test.check(notice.current.is_empty() and notice.gap_remaining == 2.0,"Six-second reading completes before inter-card gap")
	notice.tick(1.99,model.next_boundary,model.session,false,true)
	test.check(notice.current.is_empty(),"No replacement before full two-second gap")
	notice.tick(0.02,model.next_boundary,model.session,false,true)
	test.check(notice.current.get("event",{}).get("form","") == "央","Center follows group in rail")
	await draw_save("首次成形_央")
	test.check(notice.next_step.text == "央与腔都是成熟形态","Mature card describes alternatives, not forced center-to-chamber")
	notice.card.get_node("Rows/Header/Close").pressed.emit()
	test.check(notice.current.is_empty() and notice.gap_remaining == 2.0,"Actual close button dismisses without replay")
	notice.tick(2,model.next_boundary,model.session,false,true)
	test.check(notice.current.get("event",{}).get("form","") == "腔","Chamber follows center")
	await draw_save("首次成形_腔")
	main.formation_button.button_pressed = false
	test.check(notice.current.is_empty() and notice.queue.is_empty() and not notice.enabled,"Settings OFF clears active card and queue")
	main.formation_button.button_pressed = true
	notice.consume(model.growth_history,model.next_boundary)
	notice.tick(2,model.next_boundary,model.session,false,true)
	test.check(notice.current.is_empty() and notice.first_seen.size() == 3,"ON does not replay occurred stages")
	notice.reset()
	notice.set_enabled(false)
	notice.consume(model.growth_history,model.next_boundary)
	notice.set_enabled(true)
	notice.tick(2,model.next_boundary,model.session,false,true)
	test.check(notice.current.is_empty() and notice.first_seen.size() == 3,"Stages occurring while OFF are recorded without later replay")
	# UI reads real facts and gaps without moving any simulation or oscillator state.
	test.check(model.snapshot() == snapshot and state == original_state,"Card, hover, queue, black screen, focus and settings leave model/RNG/PCM state unchanged")
	var baseline := model.fork()
	var live := model.fork()
	var boundary := model.next_boundary-1024
	test.check(baseline.render_block(state.duplicate(true),boundary,512,22050) == live.render_block(state.duplicate(true),boundary,512,22050),"PCM after notification interactions equals untouched fork")
	var preview := model.fork()
	preview.render_block(state.duplicate(true),preview.next_boundary,17,22050)
	notice.reset()
	notice.consume(model.growth_history,first_frame-1)
	test.check(notice.first_seen.is_empty(),"Future fork settlement does not emit live notifications")
	notice.consume(model.growth_history,model.next_boundary)
	notice.tick(0,model.next_boundary,model.session,false,false)
	test.check(notice.entry_remaining == 0.18,"Normal motion uses gentle entry")
	notice.tick(0,model.next_boundary,model.session,false,true)
	test.check(notice.entry_remaining == 0.0 and notice.read_remaining == 6.0,"Reduced motion shows static card without shortening reading")
	test.check(Notice.direction(Vector2i(15,15)) == "下方" and Notice.direction(Vector2i(0,10)) == "左上" and Notice.direction(Vector2i(10,0)) == "右上","Direction follows fixed isometric nine-grid, including x/y counterexample")
	# Exercise the production restart control, which replaces the entire rail instance.
	main.controls.get_node("Restart").pressed.emit()
	await process_frame
	await process_frame
	var restarted: Control = current_scene
	test.check(restarted != main and restarted.formation_notice.first_seen.is_empty() and restarted.formation_notice.queue.is_empty() and restarted.formation_notice.current.is_empty(),"Production restart clears per-run records and rail")
	test.details = {"actual_facts":model.growth_history,"source":"controlled layout; actual CityInterventions/Growth.advance, not a natural player run","display":DisplayServer.get_name(),"rendering_method":RenderingServer.get_current_rendering_method(),"images":["首次成形_群.png","首次成形_央.png","首次成形_腔.png","首次成形_黑屏.png"]}
	restarted.clock.stop_output()
	test.finish(self,"Actual GPU four-row rail; real settlement facts; audible gates, one-per-stage, hover/click/close/queue/OFF/B/restart/reduced motion; model/RNG and PCM read-only",false)
	restarted.queue_free()
	await process_frame
	await process_frame
	quit(0 if test.failures == 0 else 1)
