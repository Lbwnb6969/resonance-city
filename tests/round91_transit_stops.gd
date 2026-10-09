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
	var unique_stops := {}
	for line in demo.shown_world.transit_lines:
		for stop_id in line.get("stops",[]):
			unique_stops[str(stop_id)] = true
	var marker_count := 0
	for key in demo.scenery.props:
		if str(key).begins_with("stop-"): marker_count += 1
	check(not unique_stops.is_empty(),"active transit exposes route stops")
	check(marker_count == unique_stops.size(),"one visual marker per shared stop")
	var on_roads := true
	for stop_id in unique_stops:
		var node: Array = demo.shown_world.network.nodes[stop_id]
		var access := demo.shown_world.network.access(Vector2(float(node[0]),float(node[1])))
		on_roads = on_roads and not access.is_empty()
	check(on_roads,"every stop marker is anchored to the physical road graph")
	if is_instance_valid(demo.clock): demo.clock.stop_output()
	demo.queue_free()
	await process_frame
	await process_frame
	print("TRANSIT_STOPS ",JSON.stringify({"checks":checks,"failures":failures,"stops":unique_stops.size(),"markers":marker_count}))
	quit(0 if failures.is_empty() else 1)
