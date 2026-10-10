extends SceneTree
## Round 161 UI audit: the player can expose multiple separated target pieces
## through the same map preview contract used by the backend.

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
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
	demo.partial_kind = "park"
	demo.partial_multi_component_mode = true
	var first := PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1)])
	var second := PackedVector2Array([Vector2(2,0),Vector2(3,0),Vector2(3,1)])
	var preview := {"accepted":true,"target_polygons":[first,second],"target_polygon":first,"road_id":"west-2","target_community_id":"river-1","remaining_count":3}
	var polygons: Array[PackedVector2Array] = demo._partial_preview_polygons(preview)
	_check(polygons.size() == 2,"preview_exposes_two_components")
	_check(polygons[0] == first and polygons[1] == second,"preview_preserves_component_order")
	var label: String = str(demo._partial_preview_label(preview,true))
	_check(label.contains("自由分块公园"),"label_names_multi_component_action")
	_check(label.contains("按 Enter 确认"),"label_keeps_phrase_confirmation")
	var legacy: Array[PackedVector2Array] = demo._partial_preview_polygons({"target_polygon":second})
	_check(legacy.size() == 1 and legacy[0] == second,"legacy_single_polygon_preview_stays_compatible")
	_check(demo.planning_buttons.has("free_multi_partial_park"),"multi_component_park_menu_exists")
	_check(demo.planning_buttons.has("free_multi_partial_civic"),"multi_component_civic_menu_exists")
	demo.partial_reservation_id = "reservation-test"
	demo.partial_polygon_components.clear()
	demo.partial_polygon_components.append(first)
	demo.partial_polygon_points = PackedVector2Array([Vector2(4,0),Vector2(5,0)])
	demo.partial_polygon_mode = true
	demo._submit_partial_polygon()
	_check(demo.partial_polygon_components.size() == 1,"incomplete_active_component_not_submitted")
	_check(demo.notice.contains("当前组件至少需要三个点"),"incomplete_active_component_feedback")
	print("ROUND161_MULTICOMPONENT_UI_AUDIT checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
