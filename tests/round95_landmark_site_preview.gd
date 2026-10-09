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
	var ready_index := -1
	for i in range(candidates.size()):
		if bool(candidates[i].get("ready",false)):
			ready_index = i
			break
	check(ready_index >= 0,"a ready landmark candidate exists")
	var first_sites: Array[Dictionary] = demo._landmark_preview_positions(ready_index)
	var second_sites: Array[Dictionary] = demo._landmark_preview_positions(ready_index)
	check(first_sites.size() <= 1,"preview exposes at most one deterministic site")
	check(first_sites == second_sites,"preview site is stable across redraw queries")
	check(not first_sites.is_empty(),"ready candidate exposes a continuous site preview")
	if not first_sites.is_empty():
		var site: Dictionary = first_sites[0]
		var position := Vector2(float(site["position"][0]),float(site["position"][1]))
		check(demo.shown_world.terrain.land_at(position),"preview site is on continuous land")
		check(demo._landmark_site_clear(position,float(site["radius"])),"preview site clears roads and public spaces")
	demo.selected_landmark_candidate = ready_index
	await process_frame
	if is_instance_valid(demo.clock):
		demo.clock.stop_output()
		if is_instance_valid(demo.clock.player): demo.clock.player.stream = null
	demo.free()
	await process_frame
	print("LANDMARK_SITE_PREVIEW ",JSON.stringify({"checks":checks,"failures":failures,"ready_index":ready_index,"sites":first_sites}))
	quit(0 if failures.is_empty() else 1)
