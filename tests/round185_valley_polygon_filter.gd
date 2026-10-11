extends SceneTree
## Projection-level guard for the tiny height-clipped river face seen at 800x600.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const Geometry = preload("res://scripts/visual/valley_terrain_visual_geometry.gd")
const OUTPUT := "res://验证记录/round185_河谷退化面/valley_polygon_filter.json"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	root.size = Vector2i(800,600)
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var prior_rebuilds: int = demo.terrain_layer.terrain_geometry_rebuilds
	var world := World.new("2026101100000184",true,"river_valley")
	world.build_first_composition_starter()
	demo._start_world({},world)
	demo.size = Vector2(800,600)
	demo.clock.stop_output()
	demo.set_process(false)
	await process_frame
	await process_frame
	var skips: int = demo.terrain_layer.terrain_surface_skips
	check(skips >= 1,"known_near_zero_river_face_is_filtered_before_canvas_draw")
	var data := Geometry.build(world.terrain)
	var projected_invalid := 0
	for surface in data["surfaces"]:
		var polygon: PackedVector2Array = demo.terrain_layer._project_polygon(surface["polygon"])
		if not demo.terrain_layer._is_drawable_polygon(polygon): projected_invalid += 1
	check(projected_invalid == skips,"filtered_surface_count_matches_projection_guard")
	check(demo.terrain_layer.terrain_geometry_rebuilds == prior_rebuilds+1,"filter_keeps_retained_geometry_single_prepare")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"surface_count":data["surfaces"].size(),"skipped_surfaces":skips,"projected_invalid":projected_invalid,"scope":"800x600 Dummy first-composition river draw; skips only projected degenerate faces."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND185_VALLEY_POLYGON_FILTER "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
