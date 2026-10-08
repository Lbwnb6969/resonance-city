extends SceneTree

const Contract = preload("res://tests/contract_support.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var contract := Contract.new("ASSET-003", Contract.selected_case("import_scope"))
	contract.check(contract.case_name == "import_scope", "Supported case: import_scope")
	contract.check(FileAccess.file_exists("res://资产/.gdignore"), "Asset source tree is ignored")
	contract.check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Compatibility renderer")
	contract.check(ProjectSettings.get_setting("display/window/size/viewport_width") == 1440, "Viewport width 1440")
	contract.check(ProjectSettings.get_setting("display/window/size/viewport_height") == 900, "Viewport height 900")
	var fixture: Texture2D = load("res://资源/测试/导入隔离.svg")
	contract.check(fixture != null, "Resource outside ignored tree can load")
	var source_records := _import_records("res://资产")
	contract.check(source_records.is_empty(), "No import records in ignored asset tree")
	var imported_assets: Array[String] = []
	for path in _import_records("res://.godot/imported"):
		if path.ends_with(".md5"):
			var content := FileAccess.get_file_as_string(path)
			if content.contains("res://资产/"):
				imported_assets.append(path)
	contract.check(imported_assets.is_empty(), "Import cache has no source references into assets")
	contract.details = {"source_import_records": source_records, "cached_asset_records": imported_assets, "fixture": "资源/测试/导入隔离.svg", "production_assets": "PENDING: not baked"}
	contract.finish(self, "Import isolation + UI-004 renderer/viewport only; production deployment pending")

func _import_records(path: String) -> Array[String]:
	var found: Array[String] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return found
	for filename in directory.get_files():
		if filename.ends_with(".import") or filename.ends_with(".md5"):
			found.append(path.path_join(filename))
	for child in directory.get_directories():
		found.append_array(_import_records(path.path_join(child)))
	return found
