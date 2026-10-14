extends SceneTree

const Scene = preload("res://scenes/city_creation.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _expect(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _covers(faces: PackedVector3Array, point: Vector2) -> int:
	var covered := 0
	for index in range(0,faces.size(),3):
		var a := Vector2(faces[index].x,faces[index].z)
		var b := Vector2(faces[index+1].x,faces[index+1].z)
		var c := Vector2(faces[index+2].x,faces[index+2].z)
		if Geometry2D.point_is_inside_triangle(point,a,b,c): covered += 1
	return covered

func _run() -> void:
	root.size = Vector2i(1440,900)
	var demo = Scene.instantiate()
	demo.persistence = false
	root.add_child(demo)
	await process_frame
	demo.persistence = false
	var landscape_id: int = demo.town.landscape.get_instance_id()
	var house_id: int = demo.town.house_roots.h1.get_instance_id()
	var road_id: int = demo.town.road_roots.r1.get_instance_id()
	var points: Array[Vector2] = [Vector2(9,-11),Vector2(13,-11),Vector2(13,-7),Vector2(9,-7),Vector2(9,-11)]
	_expect(demo.state.add_water(points,1.8,"pond").ok,"closed pond stroke accepted")
	points = [Vector2(3,-10),Vector2(7.3,-10)]
	_expect(demo.state.add_water(points,2.4,"channel").ok,"channel joins main river and loop")
	points = [Vector2(-15,-8)]
	_expect(demo.state.add_water(points,2.8,"pond").ok,"remote pond accepted")
	points = [Vector2(12,10)]
	_expect(demo.state.add_water(points,3.2,"pond").ok,"second remote pond accepted")
	demo.town.rebuild()
	var water_build: Dictionary = demo.town.water_edit_stats.duplicate()
	var render_build: Dictionary = demo.town.rebuild_stats.duplicate()
	_expect(demo.town.landscape.get_instance_id() == landscape_id and demo.town.house_roots.h1.get_instance_id() == house_id and demo.town.road_roots.r1.get_instance_id() == road_id,"water edit preserves static landscape and unrelated objects")
	var geometry = demo.town._water_polygon_mesh(demo.town.preview,demo.town._water_groups(0.53),0.022,Color.WHITE)
	var faces: PackedVector3Array = geometry.mesh.get_faces()
	_expect(_covers(faces,Vector2(11.13,-8.92)) == 0 and demo.state.water_clearance(Vector2(11.13,-8.92)) > 0,"rendered loop preserves dry island")
	_expect(_covers(faces,Vector2(9.07,-8.43)) == 1,"closed stroke water has exactly one surface")
	_expect(_covers(faces,Vector2(3.23,-9.83)) == 1,"main river/channel junction has one surface without overlap")
	var normals = geometry.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	_expect(normals[0].y > 0.99,"water triangles face upward")
	demo.town.clear_preview()
	points = [Vector2(11,-14),Vector2(11,-4)]
	_expect(demo.state.add_road(points).ok,"bridge crosses both sides of loop")
	demo.town.rebuild()
	demo.life._sync()
	demo.focus = Vector3(0,0.7,0)
	demo.zoom = 38
	demo._update_camera()
	demo.ui_layer.visible = false
	var started := Time.get_ticks_msec()
	while demo.music.audio_report.is_empty() and Time.get_ticks_msec()-started < 12000: await process_frame
	demo.frame_samples.clear()
	for frame in range(300): await process_frame
	var report: Dictionary = demo.diagnostics()
	report.erase("world")
	report["fixture"] = "1440x900; full audio; 6 houses; 7 roads; 4 water strokes including island and junction"
	report["water_build"] = water_build
	report["render_build"] = render_build
	var child_ids: Array[int] = []
	for child in demo.town.water_layer.get_children(): child_ids.append(child.get_instance_id())
	demo.town.rebuild()
	var retained: Array[int] = []
	for child in demo.town.water_layer.get_children(): retained.append(child.get_instance_id())
	_expect(child_ids == retained and not demo.town.water_edit_stats.changed,"unchanged water reuses its mesh")
	_expect(not report.audio.is_empty() and float(report.frame_p95_ms) <= 16.667,"complete audible scene meets 60 FPS frame budget")
	report["failures"] = failures
	report["ok"] = failures.is_empty()
	var output := "res://验证记录/水岸编辑_2026-10-14"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output+"/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t",true,true))
	file.close()
	await process_frame
	if DisplayServer.get_name() != "headless": root.get_texture().get_image().save_png(output+"/water_island.png")
	print("WATER_PERFORMANCE ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
