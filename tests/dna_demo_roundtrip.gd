extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Demo = preload("res://scripts/ui/continuous_valley_demo.gd")

var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var demo: ContinuousValleyDemo = DemoScene.instantiate() as ContinuousValleyDemo
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var before_seed := demo.model.world.rng.seed_hex
	var before_buildings := demo.model.world.buildings.size()
	var before_terrain := demo.model.world.terrain.family
	var exported := demo.export_dna()
	check(bool(exported.get("ok",false)),"live Demo exports City DNA")
	if bool(exported.get("ok",false)):
		check(demo.load_dna(),"live Demo loads the latest City DNA")
		check(demo.model.world.rng.seed_hex == before_seed and demo.model.world.terrain.family == before_terrain,"live Demo restores seed and terrain")
		check(demo.model.world.buildings.size() == before_buildings,"live Demo restores building count")
		demo.scenery.sync(demo)
		check(demo.scenery.props.size() > 0,"live Demo rebuilds traveler props after DNA load")
		DirAccess.remove_absolute(str(exported["path"]))
	if is_instance_valid(demo.clock): demo.clock.stop_output()
	demo.free()
	await process_frame
	print("DNA_DEMO_ROUNDTRIP ",JSON.stringify({"failures":failures,"buildings":before_buildings,"seed":before_seed}))
	quit(0 if failures.is_empty() else 1)
