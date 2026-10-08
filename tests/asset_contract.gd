extends SceneTree

const Contract = preload("res://tests/contract_support.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if Contract.selected_case("import_scope") in ["license","packages"]:
		_packages()
		return
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

func _packages() -> void:
	var test := Contract.new("ASSET-001",Contract.selected_case("packages"))
	var path := "res://资产/许可记录/CityKits/packages.json"
	test.check(FileAccess.file_exists(path),"Approved four-pack evidence exists")
	var packages: Array = JSON.parse_string(FileAccess.get_file_as_string(path))
	test.check(packages.size() == 4,"Exactly four approved City Kit packages")
	var names: Array[String] = []
	var summaries: Array = []
	for package in packages:
		names.append(package["package"])
		var archive: String = "res://"+str(package["archive"])
		var license: String = "res://"+str(package["license_file"])
		test.check(str(package["source_url"]).begins_with("https://kenney.nl/assets/city-kit-") and str(package["download_url"]).begins_with("https://kenney.nl/media/pages/assets/"),"Official source and download: "+package["package"])
		test.check(FileAccess.file_exists(archive) and FileAccess.get_sha256(archive) == package["archive_sha256"],"Real downloaded archive SHA-256 matches: "+package["package"])
		var license_text := FileAccess.get_file_as_string(license)
		test.check(package["license"] == "CC0-1.0" and license_text.contains("CC0") and license_text.contains("("+str(package["package_version"])+")"),"Package license and actual version match: "+package["package"])
		var complete := true
		for file in package["files_sha256"]:
			var original: String = "res://"+str(package["original_directory"])+"/"+str(file)
			complete = complete and FileAccess.file_exists(original) and FileAccess.get_sha256(original) == package["files_sha256"][file]
		test.check(complete,"Every unmodified extracted file matches original archive: "+package["package"])
		test.check(package["formats"] == [".fbx",".glb",".obj"] and int(package["model_count_all_formats"]) > 0,"Actual package model formats recorded: "+package["package"])
		summaries.append({"name":package["package"],"version":package["package_version"],"downloaded_at":package["downloaded_at"],"archive_sha256":package["archive_sha256"]})
	names.sort()
	test.check(names == ["city-kit-commercial","city-kit-industrial","city-kit-roads","city-kit-suburban"],"Whitelist has all requested kits with no replacements")
	var statement := FileAccess.get_file_as_string("res://资产/01_原始素材/已购素材/README.md")
	test.check(statement.contains("不得入库") and statement.contains("构建产物") and statement.contains("资产/2.5D素材/"),"Current prohibited resale-package statement is present")
	var resource_files := _resource_files("res://资源")
	var approved_only := true
	for file in resource_files:
		if file.ends_with(".tscn") or file.ends_with(".tres") or file.ends_with(".json"):
			var text := FileAccess.get_file_as_string(file)
			approved_only = approved_only and not text.contains("res://资产/") and not text.contains("2.5D素材")
	test.check(approved_only,"Current runtime resource references exclude ignored/resale sources")
	test.details = {"packages":summaries,"resource_file_count":resource_files.size(),"baked_assets":"PENDING","final_export_audit":"PENDING"}
	test.finish(self,"Real archive/extraction/license verification; final baked/export dependencies pending")

func _resource_files(path: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	for file in directory.get_files():
		result.append(path.path_join(file))
	for child in directory.get_directories():
		result.append_array(_resource_files(path.path_join(child)))
	return result
