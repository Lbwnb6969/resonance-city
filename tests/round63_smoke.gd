extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var demo := DemoScene.instantiate()
	root.add_child(demo)
	await process_frame
	await process_frame
	print("ROUND63 ",JSON.stringify(demo.diagnostics()))
	print("BUILDINGS ",demo.model.world.buildings.size()," LOTS ",demo.model.world.lots.size()," PUBLIC ",demo.model.world.public_sites.size()," BLOCKS ",demo.model.world.blocks.size()," TRANSIT ",demo.model.world.transit.size())
	var okay: bool = demo.model.world.buildings.size() >= 12 and demo.model.world.public_sites.size() == 4 and demo.model.world.blocks.size() >= 2 and demo.model.world.transit.size() > 0
	demo.queue_free()
	quit(0 if okay else 1)
