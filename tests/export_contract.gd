class_name ExportContract
extends SceneTree
## Run this external script against an exported pack mounted in an empty project directory.
var checks: Array[Dictionary] = []
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(condition: bool, message: String) -> void:
	checks.append({"passed":condition,"description":message})
	if not condition:
		failures += 1
		push_error(message)
func _run() -> void:
	check(not FileAccess.file_exists("res://tests/contract_support.gd") and not FileAccess.file_exists("res://资产/许可记录/CityKits/packages.json"),"Pack isolation: tests and production/source trees are unavailable")
	check(root.has_node("AudioClock") and not root.has_node("MCPRuntimeServer"),"Audio singleton works and development server is absent")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/P0城市/manifest.json"))
	var paths: Array = []
	for entry in manifest["entries"]:
		var texture: Texture2D = load("res://"+str(entry["texture"]))
		check(texture != null and texture.get_image().has_mipmaps() and maxf(texture.get_width(),texture.get_height()) >= 2048,"Packed imported master loads with HD dimensions and mipmaps: "+str(entry["id"]))
		paths.append(entry["texture"])
	var palette: Texture2D = load("res://资源/P0城市/palette.png")
	check(palette != null and palette.get_width() == 24 and palette.get_height() == 1,"Packed 24 slot base palette loads")
	var main: Control = load("res://scenes/p0_main.tscn").instantiate()
	main.set("start_audio_on_ready",false)
	root.add_child(main)
	check(main.get("model") != null and main.get("model").session.city.size() == 9,"Packed main scene constructs nine districts without source checkout")
	var listening: Control = load("res://scenes/listening_session.tscn").instantiate()
	listening.set("output_enabled",false)
	root.add_child(listening)
	check(listening.get_script() != null and FileAccess.file_exists("res://数据/listening_fixtures.json"),"Packed listening scene and protocol load")
	var performance: Node2D = load("res://scenes/performance_fixture.tscn").instantiate()
	performance.set("diagnostic_only",true)
	root.add_child(performance)
	check(performance.get_node("Buildings").get_child_count() == 700 and performance.get_node("WholeCityWindows").texture != null,"Packed performance scene instantiates 700 sprites and unified window layer")
	for node in [main,listening,performance]:
		node.queue_free()
	await process_frame
	var result_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--result="):
			result_path = arg.trim_prefix("--result=")
	assert(not result_path.is_empty(),"Pass absolute external --result= path")
	var file := FileAccess.open(result_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rule_id":"ASSET-001","status":"PASS" if failures == 0 else "FAIL","scope":"Actual exported audit pack, isolated resource and scene dependency closure; art approval/release template not claimed","checks":checks,"textures":paths,"engine":Engine.get_version_info()["string"]},"\t")+"\n")
	file.close()
	print("EXPORT_ISOLATED %s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL",checks.size(),failures])
	quit(0 if failures == 0 else 1)
