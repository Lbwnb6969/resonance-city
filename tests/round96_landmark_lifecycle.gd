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
	var index := -1
	for i in range(candidates.size()):
		if bool(candidates[i].get("ready",false)):
			index = i
			break
	check(index >= 0,"a condition-ready candidate exists")
	if index < 0:
		_finish(demo)
		return
	var name := str(candidates[index]["name"])
	var initial_status: Dictionary = demo.model.world.landmark_status(name)
	check(int(initial_status.get("streak",0)) == 0 and not bool(initial_status.get("awakened",false)),"candidate starts before two-boundary awakening")
	var phrase := int(demo.model.phrase_frames)
	demo.model.world.settle(phrase)
	demo.model.world.settle(phrase*2)
	var awakened: Dictionary = demo.model.world.landmark_status(name)
	check(int(awakened.get("streak",0)) >= 2 and bool(awakened.get("awakened",false)),"candidate awakens after two actual phrase boundaries")
	demo.shown_world = demo.model.world
	var sites: Array[Dictionary] = demo._landmark_preview_positions(index)
	check(not sites.is_empty(),"awakened candidate keeps a legal continuous site")
	if sites.is_empty():
		_finish(demo)
		return
	var site: Dictionary = sites[0]
	var request := demo.model.world.request({"kind":"landmark","name":name,"position":site["position"],"radius":site["radius"]},phrase*3)
	check(bool(request.get("accepted",false)),"landmark confirmation enters the normal pending queue")
	demo.model.world.settle(phrase*3)
	check(demo.model.world.landmarks.size() == 1,"confirmed landmark settles at the next phrase boundary")
	if not demo.model.world.landmarks.is_empty():
		var landmark: Dictionary = demo.model.world.landmarks[0]
		check(landmark.get("name","") == name and landmark.get("reveal_frames",0) > 0,"landmark has staged reveal metadata")
		check(landmark.get("motif",[]).size() == landmark.get("absorbed_buildings",[]).size(),"absorbed pitches are retained in the landmark motif")
	var audio_city: Array = demo.model.audio_city()
	check(audio_city.any(func(item: Dictionary) -> bool: return bool(item.get("landmark",false))),"landmark contributes an independent audio entity")
	demo.model.synth.update_city(audio_city,{}, {},[])
	demo.model.synth.configure_score(demo.model.world,demo.model.sound_overrides)
	var audio_block := demo.model.synth.render_block({},0,128,int(demo.model.world.cfg["timing"]["sample_rate"]))
	check(audio_block.size() == 128,"landmark voice renders through the existing synth path")
	var restored := demo.model.world.fork() as ContinuousWorld
	check(restored.landmarks.size() == demo.model.world.landmarks.size() and restored.landmark_progress == demo.model.world.landmark_progress,"landmark state survives world snapshot restore")
	_finish(demo)

func _finish(demo: ContinuousValleyDemo) -> void:
	if is_instance_valid(demo.clock):
		demo.clock.stop_output()
		if is_instance_valid(demo.clock.player): demo.clock.player.stream = null
	demo.free()
	await process_frame
	print("LANDMARK_LIFECYCLE ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
