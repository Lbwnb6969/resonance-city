extends SceneTree
## One production menu and accepted ExpressionPreview, isolated to Dummy.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Focus = preload("res://scripts/visual/first_sound_focus.gd")
const OUTPUT := "res://验证记录/round211_声音落点焦点/focus_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var demo: ContinuousValleyDemo
var focus: Node2D

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _sync() -> void:
	demo.expression_audition_layer.sync(demo)
	focus.sync(demo)

func _run() -> void:
	root.size = Vector2i(800,600)
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.first_composition_mode = true
	var cid := str(First.opportunities(city)["community_ids"][0])
	check(AudioServer.get_driver_name() == "Dummy" and demo._begin_first_sound_choice(cid),"actual_first_sound_menu_in_dummy")
	focus = Focus.new()
	demo.add_child(focus)
	_sync()
	var position := Vector2(float(demo.context["position"][0]),float(demo.context["position"][1]))
	var expected := PackedVector2Array()
	for vertex in demo.shown_world.building_polygon(position): expected.append(demo.point(vertex))
	check(focus.visible and focus.state["world_position"] == position and focus.state["polygon"] == expected and focus.state["position"].is_equal_approx(demo.point(position)),"focus_uses_current_real_land_and_actual_height_projection")
	check(demo.expression_choice.is_empty() and not demo.preview_requested and not focus.state["ghost_current"] and focus.state["progress"] < 0.0 and focus.state["community_name"] == demo.shown_world.communities[cid]["name"] and not focus.state.has("texture"),"unselected_focus_is_land_and_short_real_community_name")
	var neighbors_real := true
	var neighbor_ids: Array[String] = []
	for neighbor: Dictionary in focus.state["neighbors"]:
		var id := str(neighbor["id"])
		neighbor_ids.append(id)
		neighbors_real = neighbors_real and demo.shown_world.by_id.has(id) and int(demo.shown_world.by_id[id]["birth_frame"]) <= demo.clock.renderer.transport.audible_frame and demo.shown_world.by_id[id]["community_id"] == cid
	check(neighbors_real and not neighbor_ids.is_empty() and neighbor_ids.size() <= 3,"neighbor_marks_reference_only_actual_heard_same_community_houses")
	var world_before: Dictionary = demo.model.world.snapshot()
	var shown_before: Dictionary = demo.shown_world.snapshot()
	for i in range(4): _sync()
	check(demo.model.world.snapshot() == world_before and demo.shown_world.snapshot() == shown_before and demo.model.world.pending_actions.is_empty() and demo.expression_choice.is_empty(),"focus_does_not_choose_or_write_world_rng_or_pending")
	demo.expression_choices["warm"].emit_signal("pressed")
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline and not demo.preview_player.playing:
		await process_frame
		demo._process(0.0)
	_sync()
	var ready: bool = demo.preview_started and demo.preview_player.playing and not demo.expression_audition_layer.ghost.is_empty()
	check(ready and focus.state["ghost_current"] and focus.state["world_position"] == position and focus.state["position"].is_equal_approx(demo.expression_audition_layer.ghost["position"]),"selected_focus_matches_actual_accepted_same_source_ghost")
	if ready:
		var comparison: Dictionary = demo.expression_comparison
		var pcm: PackedByteArray = demo.preview_player.stream.data.duplicate()
		var preview_choice := str(demo.expression_choice)
		var intent := demo.preview_requested
		world_before = demo.model.world.snapshot()
		shown_before = demo.shown_world.snapshot()
		var frame := float(demo.expression_audition_layer.ghost["preview_frame"])
		var rate := float(demo.clock.renderer.transport.sample_rate)
		var actual_progress := clampf((frame-float(comparison["boundary_frame"]))/rate/demo.preview_player.stream.get_length(),0.0,1.0)
		check(is_equal_approx(float(focus.state["progress"]),actual_progress) and demo.preview_player.stream.data == comparison["variants"]["warm"]["pcm"],"small_progress_ticks_follow_actual_playback_frame_and_real_pcm")
		for i in range(5): focus.sync(demo)
		check(demo.preview_player.stream.data == pcm and demo.expression_comparison == comparison and demo.expression_choice == preview_choice and demo.preview_requested == intent and demo.model.world.snapshot() == world_before and demo.shown_world.snapshot() == shown_before,"repeated_focus_sync_never_writes_pcm_audition_intent_or_city")
		check(focus.state["community_name"] == demo.shown_world.communities[cid]["name"] and not focus.state.has("text") and not focus.state.has("texture"),"selected_focus_does_not_duplicate_audition_route_label_or_house")
		var old_polygon: PackedVector2Array = focus.state["polygon"]
		var old_position: Vector2 = focus.state["position"]
		demo.pan += Vector2(43,-21)
		demo.view_zoom *= 0.8
		_sync()
		check(focus.state["world_position"] == position and focus.state["polygon"] != old_polygon and focus.state["position"] != old_position and focus.state["position"].is_equal_approx(demo.point(position)) and demo.model.world.snapshot() == world_before,"pan_zoom_projects_same_land_without_world_geometry_writes")
		var current_key: Array = demo.expression_comparison_key
		demo.expression_comparison_key = []
		_sync()
		check(focus.visible and not focus.state["ghost_current"] and focus.state["progress"] < 0.0,"expired_comparison_cannot_lend_old_ghost_or_playback_ticks")
		demo.expression_comparison_key = current_key
	demo.black = true
	focus.sync(demo)
	check(not focus.visible and focus.state.is_empty(),"black_clears_all_focus_state")
	demo.black = false
	demo.menu.hide()
	focus.sync(demo)
	check(not focus.visible and focus.state.is_empty(),"closing_sound_menu_clears_focus")
	demo._cancel_preview_playback()
	demo._show_context_menu()
	demo.first_composition_mode = false
	focus.sync(demo)
	check(not focus.visible and focus.state.is_empty(),"non_first_composition_has_no_focus")
	demo.first_composition_mode = true
	demo.context = {"kind":"retune","id":""}
	focus.sync(demo)
	check(not focus.visible and focus.state.is_empty(),"expired_non_sound_context_has_no_focus")
	demo._start_world({},World.new("2026100900000063",true,"river_valley"))
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	focus.sync(demo)
	check(not focus.visible and focus.state.is_empty(),"switch_city_clears_old_target_and_neighbors")
	evidence = {"position":[position.x,position.y],"community_id":cid,"actual_neighbor_ids":neighbor_ids,"width":800,"height":600,"real_route":"warm","only_playback_driver":"Dummy"}
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"scope":"Production first sound menu, actual accepted four-second ExpressionPreview and real heard neighboring houses. Read-only focus; no device window, screenshot, or human aesthetic verdict."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND211_FIRST_SOUND_FOCUS ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
