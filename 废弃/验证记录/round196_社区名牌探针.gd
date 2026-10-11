extends SceneTree

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const OUTPUT := "res://验证记录/round196_首玩界面"

func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	DisplayServer.window_set_size(Vector2i(1440,900))
	var demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	for _i in range(8): await process_frame
	var layer = demo.community_label_layer
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	await _capture(demo,"首屏社区")
	demo.first_composition_guide.emit_signal("pressed")
	await _capture(demo,"发展方向")
	demo.planning_guide.cards.get_child(0).emit_signal("pressed")
	await _capture(demo,"变化卡")
	demo.planning_guide.card_choices.get_child(0).emit_signal("pressed")
	await _capture(demo,"地图选社区")
	demo.planning_guide.hide_tool()
	demo.daylight_manual_phase = 0.5
	demo.pointer_inside = true
	demo.pointer = demo.point(Vector2(8,16))
	await _capture(demo,"夜间图例")
	print("ROUND196_LABEL_PROBE ", {"first_composition":demo.first_composition_mode,"zoom":demo.view_zoom,"overlay":demo.overlay_communities.size(),"visible":layer.visible,"labels":layer.labels,"draw_count":layer.draw_count,"size":demo.size})
	demo.clock.stop_output()
	quit()

func _capture(demo: Control, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	demo.get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+name+".png")
