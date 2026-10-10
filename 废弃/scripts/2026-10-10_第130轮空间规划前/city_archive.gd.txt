class_name CityArchive
extends RefCounted
## Immutable checkpoints. Publish by rename only after a complete flushed write.
const DIRECTORY := "user://resonance_cities"
const MAGIC := "RESONANCE_CITY_1\n"

static func _digest(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

static func save(city: Dictionary, reason: String = "手动保存", directory: String = DIRECTORY) -> Dictionary:
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return {"ok":false,"reason":"无法创建作品目录"}
	var stamp := int(Time.get_unix_time_from_system())
	var path := "%s/%012d_%016d.city" % [directory,stamp,Time.get_ticks_usec()]
	var payload := var_to_bytes({"version":1,"saved_at":stamp,"reason":reason,"city":city})
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return {"ok":false,"reason":"作品写入失败"}
	file.store_buffer(MAGIC.to_utf8_buffer())
	file.store_pascal_string(_digest(payload))
	file.store_32(payload.size())
	file.store_buffer(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return {"ok":false,"reason":"作品未写完；旧版本仍保留"}
	if DirAccess.rename_absolute(path+".tmp",path) != OK: return {"ok":false,"reason":"作品版本未完成；旧版本仍保留"}
	return {"ok":true,"path":path,"bytes":payload.size(),"saved_at":stamp}

static func _json_value(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x,value.y]
	if value is PackedVector2Array:
		var points: Array = []
		for point in value: points.append([point.x,point.y])
		return points
	if value is PackedFloat32Array:
		var floats: Array = []
		for number in value: floats.append(number)
		return floats
	if value is Dictionary:
		var converted: Dictionary = {}
		for key in value: converted[str(key)] = _json_value(value[key])
		return converted
	if value is Array:
		var converted_array: Array = []
		for item in value: converted_array.append(_json_value(item))
		return converted_array
	return value

static func export_dna(city: Dictionary, directory: String = DIRECTORY+"/exports") -> Dictionary:
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return {"ok":false,"reason":"无法创建DNA导出目录"}
	var stamp := int(Time.get_unix_time_from_system())
	var model: Dictionary = city.get("model",{})
	var world: Dictionary = model.get("world",{})
	var plan: Dictionary = world.get("plan",{})
	var mix: Dictionary = model.get("mix",{})
	var dna := {
		"schema":"resonance_city_dna_v1",
		"saved_at":stamp,
		"seed_hex":world.get("seed_hex",""),
		"terrain":world.get("terrain_state",{}),
		"era":world.get("era",1),
		"phrase_index":world.get("phrase_index",0),
		"buildings":world.get("buildings",[]),
		"landmarks":world.get("landmarks",[]),
		"landmark_progress":world.get("landmark_progress",{}),
		"families":world.get("families",{}),
		"plan":{
			"roads":plan.get("roads",[]),
			"lots":plan.get("lots",[]),
			"communities":plan.get("communities",{}),
			"green_corridors":plan.get("green_corridors",[]),
			"centers":plan.get("centers",[]),
			"public_sites":world.get("public_sites",[]),
			"transit_lines":world.get("transit_lines",[])
		},
		"music":{
			"theme":mix.get("theme",{}),
			"response":mix.get("response",{}),
			"rhythms":mix.get("rhythms",[]),
			"gain":model.get("gain",1.0)
		},
		"audio_plan":{
			"schema":"resonance_audio_plan_v1",
			"phrase_frames":world.get("settings",{}).get("timing",{}).get("phrase_frames",0),
			"sample_rate":world.get("settings",{}).get("timing",{}).get("sample_rate",0),
			"world_events":world.get("events",[]),
			"decisions":model.get("decisions",[]),
			"sound_events":model.get("sound_events",[]),
			"sound_trace":model.get("sound_trace",[])
		},
		"runtime":{
			"model":model,
			"renderer":city.get("renderer",{}),
			"view":city.get("view",{})
		},
		"view":city.get("view",{})
	}
	var path := "%s/%012d_%016d.dna.json" % [directory,stamp,Time.get_ticks_usec()]
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return {"ok":false,"reason":"DNA文件写入失败"}
	file.store_string(JSON.stringify(_json_value(dna),"\t")+"\n")
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return {"ok":false,"reason":"DNA文件未写完"}
	if DirAccess.rename_absolute(path+".tmp",path) != OK: return {"ok":false,"reason":"DNA版本未完成"}
	return {"ok":true,"path":path,"bytes":FileAccess.get_file_as_bytes(path).size(),"saved_at":stamp}

static func read_dna(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"ok":false,"reason":"无法读取DNA"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or str(parsed.get("schema","")) != "resonance_city_dna_v1":
		return {"ok":false,"reason":"DNA版本不支持"}
	if not parsed.has("runtime") or not parsed["runtime"] is Dictionary or not parsed["runtime"].has("model"):
		return {"ok":false,"reason":"DNA缺少可恢复运行时"}
	return {"ok":true,"dna":parsed,"model":parsed["runtime"]["model"],"renderer":parsed["runtime"].get("renderer",{}),"view":parsed["runtime"].get("view",{}),"path":path}

static func read(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"ok":false,"reason":"无法读取作品"}
	if file.get_buffer(MAGIC.length()).get_string_from_utf8() != MAGIC: return {"ok":false,"reason":"作品格式不匹配"}
	var digest := file.get_pascal_string()
	var size := file.get_32()
	if size != file.get_length()-file.get_position(): return {"ok":false,"reason":"作品没有完整写入"}
	var bytes := file.get_buffer(size)
	file.close()
	if _digest(bytes) != digest: return {"ok":false,"reason":"作品校验失败"}
	var payload: Variant = bytes_to_var(bytes)
	if not payload is Dictionary or int(payload.get("version",0)) != 1 or not payload.get("city") is Dictionary:
		return {"ok":false,"reason":"作品版本不支持"}
	var city: Dictionary = payload["city"]
	if not city.has_all(["model","renderer","view"]) or not city["model"] is Dictionary or not city["renderer"] is Dictionary:
		return {"ok":false,"reason":"作品内容不完整"}
	return {"ok":true,"city":city,"path":path,"saved_at":payload["saved_at"],"reason":payload["reason"]}

static func latest_dna(directory: String = DIRECTORY+"/exports") -> Dictionary:
	if not DirAccess.dir_exists_absolute(directory): return {"ok":false,"reason":"还没有导出的城市DNA"}
	var paths: Array[String] = []
	for filename in DirAccess.get_files_at(directory):
		if filename.ends_with(".dna.json"): paths.append(directory+"/"+filename)
	paths.sort()
	paths.reverse()
	var skipped := 0
	for path in paths:
		var result := read_dna(path)
		if result["ok"]:
			result["skipped"] = skipped
			return result
		skipped += 1
	return {"ok":false,"reason":"没有完整可读的城市DNA" if skipped > 0 else "还没有导出的城市DNA"}

static func latest(directory: String = DIRECTORY) -> Dictionary:
	if not DirAccess.dir_exists_absolute(directory): return {"ok":false,"reason":"还没有保存的作品"}
	var paths: Array[String] = []
	for filename in DirAccess.get_files_at(directory):
		if filename.ends_with(".city"): paths.append(directory+"/"+filename)
	paths.sort()
	paths.reverse()
	var skipped := 0
	for path in paths:
		var result := read(path)
		if result["ok"]:
			result["skipped"] = skipped
			return result
		skipped += 1
	return {"ok":false,"reason":"没有完整可读的作品" if skipped > 0 else "还没有保存的作品"}
