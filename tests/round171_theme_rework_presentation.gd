extends SceneTree
## The rework entry follows audible presentation, including natural rest.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var failures: Array[String] = []
var checks: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	guide.open_tool()
	check(guide.theme_rework_button.visible,"mature_opening_exposes_real_theme_rework")
	var phases: Dictionary = demo.clock.renderer.state
	var rate := int(demo.model.world.cfg["timing"]["sample_rate"])
	while demo.model.world.phrase_index < 5:
		var boundary := demo.model.next_boundary
		demo.model.render_block(phases,boundary-1,2,rate)
		demo.shown_world = demo.model.presentation_world(boundary)
		guide.sync()
	check(not demo.model.audible_theme().is_empty(),"five_real_phrase_settlements_keep_a_theme")
	var rest_boundary := demo.model.next_boundary
	demo.model.render_block(phases,rest_boundary-1,2,rate)
	demo.shown_world = demo.model.presentation_world(rest_boundary-1)
	guide.sync()
	check(demo.model.synth.theme.is_empty() and not demo.model.audible_theme().is_empty() and guide.theme_rework_button.visible,"queued_rest_does_not_hide_still_audible_theme")
	demo.shown_world = demo.model.presentation_world(rest_boundary)
	guide.sync()
	check(demo.model.audible_theme().is_empty() and not guide.theme_rework_button.visible and not guide.detail.text.contains("已有主题"),"audible_rest_refreshes_text_and_hides_rework_entry")
	var next_boundary := demo.model.next_boundary
	demo.model.render_block(phases,next_boundary-1,2,rate)
	demo.shown_world = demo.model.presentation_world(next_boundary)
	guide.sync()
	check(not demo.model.audible_theme().is_empty() and guide.theme_rework_button.visible and guide.detail.text.contains("已有主题"),"real_theme_return_restores_rework_entry")
	print("ROUND171_THEME_REWORK_PRESENTATION ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
