extends SceneTree
const Schema = preload("res://scripts/city/district_schema.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
var failed := false
var checks := 0
func _initialize() -> void:
	call_deferred("run_check")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("AUDIBLE_CITY_FAIL "+message)
func refresh(main: Control, at: float) -> void:
	main.clock.renderer.transport.audible_frame = at
	main._process(0.0)
	main.city_view._process(0.0)
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/Demo/可听城市同步_"+name+".png")
func run_check() -> void:
	check(DisplayServer.get_name() != "headless","needs actual GPU")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	var before: Array = main.model.session.city.duplicate(true)
	var period: int = main.model.next_boundary
	var beat: int = main.clock.renderer.transport.beat_frame(1)
	var target: Array = main.model.session._empty_cells()[0]
	check(main.model.session.request_release(48,Vector2i(target[0],target[1]),0,0)["accepted"],"release fixture")
	main.clock.renderer.transport.rendered_frames = period
	main.clock.renderer.transport.audible_frame = period-1
	main.clock.renderer.render(17)
	refresh(main,period-1)
	check(main.model.session.phrase_index == 1,"audio renderer must settle first")
	check(main.city_view.session.phrase_index == 0,"visible phase before boundary")
	check(main.city_view.session.city == before,"visible city before boundary")
	check(main.district_select.item_count == before.size(),"selection hides future district")
	check("第1乐句" in main.city_summary.text,"HUD hides future phase")
	check("已排入声音" in main.map_notice.text,"cannot promise cancellation after render")
	await capture("边界前")
	refresh(main,period)
	check(main.city_view.session == main.model.session,"visible model switches at exact boundary")
	check("第2乐句" in main.city_summary.text,"HUD switches at boundary")
	check(main.district_select.item_count == main.model.session.city.size(),"selection updates at boundary")
	var born: String = main.model.session.last_result["choice"]["district_id"]
	main.city_view.sprites[born].sample_frame(period+beat-1)
	check(main.city_view.sprites[born].progress == 0.0,"birth waits for next beat")
	main.city_view.sprites[born].sample_frame(period+2*beat)
	check(main.city_view.sprites[born].progress == 1.0,"reveal ends after exactly one beat")
	refresh(main,period+2*beat)
	await capture("落定后")
	# A render-ahead migration must preserve old location, vitality and conditions.
	var moving: String = before[0]["district_id"]
	var destination: Array = main.model.session._empty_cells().back()
	var proposal: String = "p0:%d:%s:relocate" % [main.model.session.refresh_cycle,moving]
	check(main.model.session.request({"proposal_id":proposal,"target":destination},main.clock.renderer.transport.rendered_frames,period+2*beat)["accepted"],"migration fixture")
	var before_move: Array = main.model.session.city.duplicate(true)
	var old_cell: Vector2i = Schema.cell(main.model.session._district(moving))
	var clone = main.model.fork()
	var clone_state: Dictionary = main.clock.renderer.state.duplicate(true)
	main.clock.renderer.transport.rendered_frames = 2*period
	var block: PackedVector2Array = main.clock.renderer.render(17)
	var scalar := PackedVector2Array()
	for i in range(17): scalar.append(clone._mix_frame(clone_state,2*period+i,main.clock.renderer.transport.sample_rate))
	check(block == scalar,"block and scalar PCM agree with presentation history")
	refresh(main,2*period-1)
	main._select_district(moving)
	check(main.city_view.session.city == before_move,"migration waits for audible frame")
	check(Schema.cell(main.city_view.session._district(moving)) == old_cell,"old migration position shown")
	check(main.city_view._display_point(main.city_view.session._district(moving)).distance_to(main.city_view.point(old_cell)) < 5.0,"sprite remains at old plot")
	var saved: Dictionary = main.model.snapshot()
	var restored = main.model.fork()
	check(restored.presentation_session(2*period-1).city == before_move,"fork keeps unheard state")
	check(main.model.snapshot() == saved,"presentation queries do not mutate audio model")
	# A new pending choice may preview immediately; cancel must not leave it cached.
	var next_empty: Array = main.model.session._empty_cells().back()
	check(main.model.session.request_release(52,Vector2i(next_empty[0],next_empty[1]),main.clock.renderer.transport.rendered_frames,2*period-1)["accepted"],"new pending fixture")
	check(main.model.presentation_session(2*period-1).pending.get("verb","") == "release","new pending previews")
	main.model.session.cancel_pending()
	check(main.model.presentation_session(2*period-1).pending.get("proposal_id","") == proposal,"cancel restores only already-rendered intervention")
	refresh(main,2*period)
	check(Schema.cell(main.city_view.session._district(moving)) == Vector2i(destination[0],destination[1]),"migration changes at audible boundary")
	check(is_equal_approx(main.city_view.sprites[moving].modulate.a,0.45),"migration mute visual synchronized")
	check(main.model.presentation_history.is_empty(),"played history pruned")
	# Third tread mark: before the audio boundary both adjacency and art stay intact.
	var a := Vector2i(7,7)
	var b := Vector2i(8,7)
	var ends := Roads.endpoints(a,b)
	main.model.session.road_marks[Roads.key(a,b)] = {"start":ends[0],"end":ends[1],"count":2,"frame":2*period}
	check(main.model.session.request_tread(a,b,main.clock.renderer.transport.rendered_frames,2*period)["accepted"],"road fixture")
	main.clock.renderer.transport.rendered_frames = 3*period
	main.clock.renderer.render(17)
	refresh(main,3*period-1)
	check(not Roads.blocked(main.city_view.session.road_marks,a,b),"unheard road does not cut shown adjacency")
	check(Roads.blocked(main.model.session.road_marks,a,b),"road already settled in render model")
	# Multiple unread boundaries retain the intermediate city, not only the latest before.
	var multi = main.model.fork()
	var intermediate: Array = multi.session.city.duplicate(true)
	var state: Dictionary = main.clock.renderer.state.duplicate(true)
	multi._mix_frame(state,4*period,main.clock.renderer.transport.sample_rate)
	multi._mix_frame(state,5*period,main.clock.renderer.transport.sample_rate)
	check(multi.presentation_session(3*period-1).phrase_index == 2,"multiple queued boundaries retain oldest audible state")
	check(multi.presentation_session(3*period).city == intermediate,"intermediate state after first queued commit")
	refresh(main,3*period)
	check(Roads.blocked(main.city_view.session.road_marks,a,b),"road changes at audible boundary")
	check(main.city_view.sprites[moving].modulate.a == 1.0,"migration restores after one phrase")
	main.set_black_screen(true)
	check(not main.city_view.visible and not main.panel.visible,"black screen hides synchronized view")
	main.set_black_screen(false)
	print("AUDIBLE_CITY ","FAIL" if failed else "PASS"," checks=",checks," render_ahead/birth/move/road/snapshot/PCM/pending/black")
	main.queue_free()
	await process_frame
	quit(1 if failed else 0)
