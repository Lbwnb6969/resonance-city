extends SceneTree
## Round 159 UI contract: a reservation opens the free target-footprint tool,
## drawing is kept separate from free-reservation and rectangular partial modes,
## and Escape/right-click cancel without queuing an operation.  Geometry and
## boundary settlement belong to the world contract tests.

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _run() -> void:
	var scene: PackedScene = load("res://scenes/continuous_valley.tscn")
	var demo = scene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.context = {"kind":"reservation","id":"reservation-round159-ui"}
	demo._planning_menu()
	check(not demo.planning_buttons["free_partial_park"].disabled,"reservation_enables_free_partial_park")
	check(not demo.planning_buttons["free_partial_civic"].disabled,"reservation_enables_free_partial_civic")
	check(demo.planning_buttons["partial_park"].disabled == false and demo.planning_buttons["partial_civic"].disabled == false,"rectangular_partial_buttons_remain_available")

	demo._verb("free_partial_park")
	check(bool(demo.partial_polygon_mode) and not bool(demo.partial_mode),"free_partial_mode_is_distinct_from_click_to_place")
	check(str(demo.partial_kind) == "park" and str(demo.partial_reservation_id) == "reservation-round159-ui","free_partial_keeps_kind_and_source")
	demo._append_partial_polygon_point(Vector2(-1.0,-1.0))
	demo._append_partial_polygon_point(Vector2(1.0,-1.0))
	demo._append_partial_polygon_point(Vector2(1.0,1.0))
	check(demo.partial_polygon_points.size() == 3,"free_partial_collects_three_target_points")
	check(not demo.reservation_draw_mode and demo.reservation_draw_points.is_empty(),"free_partial_does_not_enter_reservation_draw")

	var cancel := InputEventMouseButton.new()
	cancel.button_index = MOUSE_BUTTON_RIGHT
	cancel.pressed = true
	cancel.position = Vector2(10,10)
	demo._gui_input(cancel)
	check(not demo.partial_polygon_mode and demo.partial_polygon_points.is_empty(),"right_click_cancels_target_footprint")
	check(demo.partial_kind.is_empty() and demo.partial_reservation_id.is_empty(),"right_click_clears_target_source")

	demo.context = {"kind":"reservation","id":"reservation-round159-ui"}
	demo._verb("free_partial_civic")
	demo._append_partial_polygon_point(Vector2(-1.0,-1.0))
	demo._append_partial_polygon_point(Vector2(1.0,-1.0))
	demo._append_partial_polygon_point(Vector2(0.0,1.0))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	demo._input(escape)
	check(not demo.partial_polygon_mode and demo.partial_polygon_points.is_empty(),"escape_cancels_target_footprint")
	check(str(demo.partial_kind).is_empty() and str(demo.partial_reservation_id).is_empty(),"escape_clears_target_source")
	check(demo.model.world.pending_actions.is_empty(),"ui_cancel_does_not_queue_operation")

	print("ROUND159_PARTIAL_FOOTPRINT_UI checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
