extends SceneTree
## Round 153: keep the bridge choice visible through queue, commit, and the
## next planning step. This is a UI continuity contract; it does not replace
## the bridge geometry/audio tests or claim human listening quality.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
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

	var model: Model = demo.model
	var queued := model.submit({"kind":"bridge"})
	check(bool(queued.get("accepted",false)), "bridge queues through the production action path")
	check(demo._planning_status_hint().contains("待播规划") and demo._planning_status_hint().contains("跨河连接"), "queued bridge remains in the persistent planning caption")

	var boundary := int(model.next_boundary)
	model.world.settle(boundary)
	check(model.world.bridge, "bridge commits at the phrase boundary")
	check(demo._planning_status_hint().contains("跨河已连接") and demo._planning_status_hint().contains("合奏已接通"), "committed bridge leaves a visible road and ensemble result")

	demo.queue_free()
	await process_frame
	await process_frame
	print("ROUND153_PLAYABLE_AUDIT checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
