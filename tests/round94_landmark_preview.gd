extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")

var failures: Array[String] = []
var checks: Dictionary = {}

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate() as ContinuousValleyDemo
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var candidates: Array[Dictionary] = demo._landmark_candidates()
	check(candidates.size() == 3,"first formed city reveals three era candidates")
	check(candidates[0].get("name","") == "元老院" and candidates[1].get("name","") == "神殿" and candidates[2].get("name","") == "圆形剧场","era one candidate order is stable")
	check(candidates.any(func(item: Dictionary) -> bool: return bool(item.get("ready",false))),"candidate bar reports actionable progress")
	if is_instance_valid(demo.clock):
		demo.clock.stop_output()
		if is_instance_valid(demo.clock.player): demo.clock.player.stream = null
	demo.free()
	await process_frame
	print("LANDMARK_PREVIEW ",JSON.stringify({"checks":checks,"failures":failures,"candidates":candidates}))
	quit(0 if failures.is_empty() else 1)
