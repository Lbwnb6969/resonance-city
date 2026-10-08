class_name CityPerformanceFixture
extends Node2D
## Static baked-sprite budget. Performance requires a real display server.

@export var diagnostic_only := false
var config: Dictionary = {}
var buildings: Node2D
var windows: Sprite2D
var samples: Array[float] = []
var draw_calls: Array[float] = []
var loaded_textures: Dictionary = {}
var warmup_start := 0
var measure_previous := 0
var measuring := false
var finished := false
var captured := false
var output_directory := ""

func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://资源/P0城市/performance_layout.json"))
	if not diagnostic_only and DisplayServer.get_name() == "headless":
		push_error("PERF-001 requires real rendering; headless is not a performance result")
		get_tree().quit(1)
		return
	if not diagnostic_only:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(int(config["viewport"][0]),int(config["viewport"][1])))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	RenderingServer.set_default_clear_color(Color("343943"))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	buildings = Node2D.new()
	buildings.name = "Buildings"
	buildings.y_sort_enabled = true
	add_child(buildings)
	for entry in config["entries"]:
		var path: String = "res://"+str(entry["texture"])
		if not loaded_textures.has(path):
			loaded_textures[path] = load(path)
		var sprite := Sprite2D.new()
		sprite.name = "Building_%03d" % buildings.get_child_count()
		sprite.texture = loaded_textures[path]
		sprite.centered = false
		sprite.offset = -Vector2(float(entry["origin"][0]),float(entry["origin"][1]))
		sprite.position = Vector2(float(entry["position"][0]),float(entry["position"][1]))
		sprite.scale = Vector2.ONE*float(entry["scale"])
		sprite.set_meta("asset_id",entry["asset_id"])
		buildings.add_child(sprite)
	windows = Sprite2D.new()
	windows.name = "WholeCityWindows"
	windows.texture = load("res://"+str(config["window_texture"]))
	windows.centered = false
	windows.z_index = 1
	windows.modulate.a = float(config["window_strength"])
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	windows.material = material
	add_child(windows)
	output_directory = "res://验证记录/P0/性能/"+Time.get_datetime_string_from_system().replace(":","-")
	if not diagnostic_only:
		DirAccess.make_dir_recursive_absolute(output_directory)
	warmup_start = Time.get_ticks_usec()
	set_process(not diagnostic_only)
	print("PERF_READY buildings=%d textures=%d warmup=%.0fs measure=%.0fs" % [buildings.get_child_count(),loaded_textures.size(),config["warmup_seconds"],config["measurement_seconds"]])

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image.save_png(output_directory+"/实际窗口.png") == OK)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var elapsed := float(now-warmup_start)/1000000.0
	if not captured and elapsed >= 5.0:
		captured = true
		_capture()
	if not measuring:
		if elapsed >= float(config["warmup_seconds"]):
			measuring = true
			measure_previous = now
			print("PERF_MEASURING")
		return
	var frame_ms := float(now-measure_previous)/1000.0
	measure_previous = now
	samples.append(frame_ms)
	draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if _total_seconds() >= float(config["measurement_seconds"]):
		_finish(true)

var measured_ms := 0.0
var accumulated_count := 0
func _total_seconds() -> float:
	while accumulated_count < samples.size():
		measured_ms += samples[accumulated_count]
		accumulated_count += 1
	return measured_ms/1000.0

func _budget(node: Node, depth: int = 0) -> Dictionary:
	var result := {"max_depth":depth,"particles":0,"sprites":0,"children_on_building":0}
	if node is Sprite2D:
		result["sprites"] = 1
		if node.get_parent() == buildings:
			result["children_on_building"] = node.get_child_count()
	if node is GPUParticles2D or node is CPUParticles2D:
		result["particles"] = 1
	for child in node.get_children():
		var sub := _budget(child,depth+1)
		result["max_depth"] = maxi(int(result["max_depth"]),int(sub["max_depth"]))
		result["particles"] += sub["particles"]
		result["sprites"] += sub["sprites"]
		result["children_on_building"] += sub["children_on_building"]
	return result

func _finish(complete: bool) -> void:
	if finished:
		return
	finished = true
	set_process(false)
	var duration := _total_seconds()
	var sorted := samples.duplicate()
	sorted.sort()
	var fps := float(samples.size())/duration if duration > 0 else 0.0
	var p95: float = sorted[ceili(sorted.size()*0.95)-1] if not sorted.is_empty() else INF
	var budgets := _budget(self)
	var structural: bool = buildings.get_child_count() == int(config["count"]) and int(budgets["sprites"]) == 701 and int(budgets["max_depth"]) <= 6 and int(budgets["particles"]) <= 12 and int(budgets["children_on_building"]) == 0
	var viewport_size := Vector2i(get_viewport_rect().size)
	var environment: bool = DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() == "gl_compatibility" and viewport_size == Vector2i(1440,900) and DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED
	var passed: bool = complete and structural and environment and duration >= float(config["measurement_seconds"]) and fps >= float(config["min_fps"]) and p95 <= float(config["max_p95_ms"])
	var result := {"rule_id":"UI-004","acceptance":"PERF-001","status":"PASS" if passed else "FAIL","complete":complete,
		"frame_count":samples.size(),"duration_seconds":duration,"average_fps":fps,"p95_ms":p95,"max_ms":sorted.back() if not sorted.is_empty() else INF,
		"warmup_seconds":float(config["warmup_seconds"]),"thresholds":{"min_fps":config["min_fps"],"max_p95_ms":config["max_p95_ms"]},
		"budgets":budgets,"building_count":buildings.get_child_count(),"window_layers":1,"texture_count":loaded_textures.size(),
		"viewport":[viewport_size.x,viewport_size.y],"window_size":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],
		"rendering_method":RenderingServer.get_current_rendering_method(),"display_server":DisplayServer.get_name(),"vsync":DisplayServer.window_get_vsync_mode(),"max_fps":Engine.max_fps,
		"gpu":RenderingServer.get_video_adapter_name(),"gpu_vendor":RenderingServer.get_video_adapter_vendor(),"cpu":OS.get_processor_name(),"engine":Engine.get_version_info()["string"],
		"layout_sha256":FileAccess.get_sha256("res://资源/P0城市/performance_layout.json"),"manifest_sha256":config["manifest_sha256"],"spec_sha256":config["spec_sha256"],
		"draw_calls_range":[draw_calls.min(),draw_calls.max()] if not draw_calls.is_empty() else [],"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"scope":"Local fixed static sprite budget; no full audio/dynamic growth/human art claim","arguments":Array(OS.get_cmdline_args()),"evidence_directory":output_directory}
	var csv := FileAccess.open(output_directory+"/frame_times.csv",FileAccess.WRITE)
	csv.store_csv_line(PackedStringArray(["frame","wall_ms","draw_calls_monitor"]))
	for index in range(samples.size()):
		csv.store_csv_line(PackedStringArray([str(index),str(samples[index]),str(draw_calls[index])]))
	csv.close()
	for path in [output_directory+"/result.json","res://验证记录/P0/PERF-001_700.json"]:
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t")+"\n")
		file.close()
	print("PERF-001 %s frames=%d seconds=%.3f average=%.3ffps p95=%.3fms evidence=%s" % [result["status"],samples.size(),duration,fps,p95,output_directory])
	get_tree().quit(0 if passed else 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not diagnostic_only:
		_finish(false)
