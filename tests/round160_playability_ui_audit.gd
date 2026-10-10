extends SceneTree
## Round 160 UI audit: a partial public footprint exposes the real access
## route, community and phrase-boundary result while it is being drawn.

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
	demo.partial_kind = "park"
	var path := PackedVector2Array([Vector2(0.0,0.0),Vector2(1.0,0.4)])
	var accepted := {"accepted":true,"road_id":"west-2","target_community_id":"river-1","remaining_count":2,"target_access_path":path}
	check(demo._partial_access_path(accepted) == path,"access_path_is_reused_by_preview")
	var free_label: String = str(demo._partial_preview_label(accepted,true))
	check(free_label.contains("下一乐句落成"),"free_preview_exposes_phrase_result")
	check(free_label.contains("入口 west-2"),"free_preview_exposes_real_road")
	check(free_label.contains("river-1"),"free_preview_exposes_target_community")
	check(free_label.contains("保留2片留地"),"free_preview_exposes_residual_count")
	var rectangular_label: String = str(demo._partial_preview_label(accepted,false))
	check(rectangular_label.contains("点击确认"),"rectangular_preview_keeps_click_confirmation")
	check(not rectangular_label.contains("自由局部"),"rectangular_preview_keeps_distinct_label")
	var rejected := {"accepted":false,"reason":"目标必须是凸足迹"}
	var rejected_label: String = str(demo._partial_preview_label(rejected,true))
	check(rejected_label.contains("目标必须是凸足迹"),"rejected_preview_keeps_geometry_reason")
	check(not rejected_label.contains("下一乐句落成"),"rejected_preview_does_not_claim_phrase_result")

	print("ROUND160_PLAYABILITY_UI_AUDIT checks=%d failures=%s" % [checks,JSON.stringify(failures)])
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
