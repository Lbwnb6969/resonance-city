class_name CityArchive
extends RefCounted
## Immutable checkpoints. Publish by rename only after a complete flushed write.
const AudioModel = preload("res://scripts/audio/continuous_audio_model.gd")
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
			"planning_reservations":world.get("planning_reservations",[]),
			"development_charters":world.get("development_charters",[]),
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

static func _audio_source(source: Variant) -> Dictionary:
	if source is String:
		return read_dna(str(source))
	if not source is Dictionary:
		return {"ok":false,"reason":"AudioPlan来源不是DNA路径或对象"}
	var value: Dictionary = source
	if value.has("dna") and value["dna"] is Dictionary:
		value = value["dna"]
	if value.has("runtime") and value["runtime"] is Dictionary and value["runtime"].has("model"):
		return {"ok":true,"dna":value,"model":value["runtime"]["model"],"renderer":value["runtime"].get("renderer",{}),"view":value["runtime"].get("view",{})}
	if value.has("model") and value["model"] is Dictionary:
		return {"ok":true,"dna":{},"model":value["model"],"renderer":value.get("renderer",{}),"view":value.get("view",{})}
	return {"ok":false,"reason":"AudioPlan缺少runtime.model"}

static func validate_audio_plan(source: Variant) -> Dictionary:
	var loaded := _audio_source(source)
	if not bool(loaded.get("ok",false)): return loaded
	var dna: Dictionary = loaded.get("dna",{})
	var plan: Dictionary = dna.get("audio_plan",{})
	if plan.is_empty() or str(plan.get("schema","")) != "resonance_audio_plan_v1":
		return {"ok":false,"reason":"AudioPlan版本不支持"}
	var model: Dictionary = loaded.get("model",{})
	var world: Dictionary = model.get("world",{})
	var timing: Dictionary = world.get("settings",{}).get("timing",{})
	var phrase_frames := int(plan.get("phrase_frames",0))
	var sample_rate := int(plan.get("sample_rate",0))
	if phrase_frames <= 0 or sample_rate <= 0:
		return {"ok":false,"reason":"AudioPlan缺少有效时间基准"}
	if phrase_frames != int(timing.get("phrase_frames",0)) or sample_rate != int(timing.get("sample_rate",0)):
		return {"ok":false,"reason":"AudioPlan时间基准与运行时不一致"}
	var sound_events: Array = plan.get("sound_events",[])
	var previous_sound_frame := -1
	for event in sound_events:
		if not event is Dictionary or not event.has("sound_frame"):
			return {"ok":false,"reason":"AudioPlan声音事件缺少sound_frame"}
		var frame := int(event["sound_frame"])
		if frame < previous_sound_frame:
			return {"ok":false,"reason":"AudioPlan声音事件未按时间排序"}
		previous_sound_frame = frame
	var renderer: Dictionary = loaded.get("renderer",{})
	var transport: Dictionary = renderer.get("transport",{}) if renderer is Dictionary else {}
	var rendered_until := int(model.get("rendered_until",0))
	if transport.has("rendered_frames") and int(transport["rendered_frames"]) != rendered_until:
		return {"ok":false,"reason":"AudioPlan与PCM渲染游标不一致"}
	return {"ok":true,"dna":dna,"model":model,"renderer":renderer,"plan":plan,
		"phrase_frames":phrase_frames,"sample_rate":sample_rate,
		"rendered_until":rendered_until,"sound_event_count":sound_events.size(),
		"decision_count":(plan.get("decisions",[]) as Array).size()}

static func _pcm_digest(block: PackedVector2Array) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(block.to_byte_array())
	return hash.finish().hex_encode()

static func _hydrate_replay_state(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			var name := str(key)
			if name.begins_with("_pad_stereo_") and value[key] is Array and value[key].size() >= 2:
				result[key] = Vector2(float(value[key][0]),float(value[key][1]))
			else:
				result[key] = _hydrate_replay_state(value[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item in value: result_array.append(_hydrate_replay_state(item))
		return result_array
	return value

static func replay_audio_plan(source: Variant, frame_count: int = 0, initial_state: Dictionary = {}) -> Dictionary:
	var checked := validate_audio_plan(source)
	if not bool(checked.get("ok",false)): return checked
	var model: ContinuousAudioModel = AudioModel.from_state(checked["model"])
	var rate := int(checked["sample_rate"])
	var start := int(model.rendered_until)
	var count := frame_count if frame_count > 0 else mini(int(checked["phrase_frames"]),1024)
	if count <= 0: return {"ok":false,"reason":"回放长度必须大于零"}
	var state := initial_state.duplicate(true)
	if state.is_empty():
		var renderer: Dictionary = checked.get("renderer",{})
		state = renderer.get("state",{}).duplicate(true) if renderer is Dictionary else {}
	state = _hydrate_replay_state(state)
	var pcm := model.render_block(state,start,count,rate)
	var peak := 0.0
	var energy := 0.0
	for sample in pcm:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		energy += sample.length_squared()
	var summary := {"schema":"resonance_audio_replay_v1","start_frame":start,
		"end_frame":start+pcm.size(),"sample_rate":rate,"frames":pcm.size(),
		"sha256":_pcm_digest(pcm),"peak":peak,
		"rms":sqrt(energy/float(maxi(1,pcm.size()*2))),
		"sound_event_count":int(checked["sound_event_count"]),
		"decision_count":int(checked["decision_count"])}
	return {"ok":true,"pcm":pcm,"state":state,"model":model,"summary":summary}

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
