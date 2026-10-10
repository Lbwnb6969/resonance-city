extends SceneTree
## Round 147 UI contract: selected buildings expose the structured P11 role opportunities.

const DemoScene = preload("res://scenes/continuous_valley.tscn")

var failures: Array[String] = []
var checks := 0

func check(condition: bool,label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var chosen: Dictionary = {}
	for building in demo.model.world.buildings:
		if str(building.get("form","胚")) in ["群","央","腔"]:
			chosen = building
			break
	if chosen.is_empty() and not demo.model.world.buildings.is_empty(): chosen = demo.model.world.buildings[0]
	check(not chosen.is_empty(),"continuous valley provides a visible building for the selected-community menu")
	if not chosen.is_empty():
		var id := str(chosen["district_id"])
		demo.selected_id = id
		demo.context = {"kind":"retune","id":id}
		demo._show_context_menu()
		var opportunity_text := demo.menu_info.text
		check(demo.menu.visible,"selected building opens the opportunity menu")
		check(demo.selected_opportunity.get("opportunities",[]).size() == 4,"selected community exposes theme plus three P11 role opportunities")
		for label in ["低音表达","商业律动","跨岸应答"]:
			check(opportunity_text.contains(label),"opportunity menu shows "+label)
	print("ROUND147_OPPORTUNITY_UI checks=",checks," failures=",JSON.stringify(failures))
	demo.menu.hide()
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
