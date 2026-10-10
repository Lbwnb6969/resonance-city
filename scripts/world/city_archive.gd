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
	if value.has("dna"):
		if not value["dna"] is Dictionary:
			return {"ok":false,"reason":"AudioPlan的dna来源格式不支持"}
		value = value["dna"]
	if value.has("runtime"):
		if not value["runtime"] is Dictionary:
			return {"ok":false,"reason":"AudioPlan运行时容器格式不支持"}
		var runtime: Dictionary = value["runtime"]
		if not runtime.has("model"):
			return {"ok":false,"reason":"AudioPlan缺少runtime.model"}
		if not runtime["model"] is Dictionary:
			return {"ok":false,"reason":"AudioPlan的runtime.model格式不支持"}
		if runtime.has("renderer") and not runtime["renderer"] is Dictionary:
			return {"ok":false,"reason":"AudioPlan渲染器快照格式不支持"}
		return {"ok":true,"dna":value,"model":runtime["model"],"renderer":runtime.get("renderer",{}),"view":runtime.get("view",{})}
	if value.has("model") and value["model"] is Dictionary:
		return {"ok":true,"dna":{},"model":value["model"],"renderer":value.get("renderer",{}),"view":value.get("view",{})}
	return {"ok":false,"reason":"AudioPlan缺少runtime.model"}

static func _is_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	var number := float(value)
	return number == number and floor(number) == number

static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func _has_dictionary_fields(value: Dictionary, fields: Array, reason: String) -> Dictionary:
	for field in fields:
		if not value.has(field): return {"ok":false,"reason":reason+field}
	return {"ok":true}

static func _validate_audio_model_shape(model: Dictionary) -> Dictionary:
	var required := ["world","gain","next_boundary","rendered_until","event_cursor",
		"sound_events","sound_trace","sound_overrides","decisions","presentation_history",
		"transition_remaining","transition_total","mix"]
	var fields := _has_dictionary_fields(model,required,"AudioPlan运行时模型缺少")
	if not bool(fields.get("ok",false)): return fields
	if not model["world"] is Dictionary: return {"ok":false,"reason":"AudioPlan缺少WorldSnapshot"}
	if not _is_number(model["gain"]): return {"ok":false,"reason":"AudioPlan运行时增益格式不支持"}
	for field in ["next_boundary","rendered_until","event_cursor","transition_remaining","transition_total"]:
		if not _is_integer(model[field]) or int(model[field]) < 0:
			return {"ok":false,"reason":"AudioPlan运行时游标格式不支持"}
	if int(model["next_boundary"]) < int(model["rendered_until"]):
		return {"ok":false,"reason":"AudioPlan运行时边界早于渲染游标"}
	if not model["sound_events"] is Array or not model["sound_trace"] is Array:
		return {"ok":false,"reason":"AudioPlan声音轨迹格式不支持"}
	if not model["sound_overrides"] is Dictionary or not model["decisions"] is Array:
		return {"ok":false,"reason":"AudioPlan决策记录格式不支持"}
	if not model["presentation_history"] is Array or not model["mix"] is Dictionary:
		return {"ok":false,"reason":"AudioPlan运行时状态格式不支持"}
	var world: Dictionary = model["world"]
	var world_fields := _has_dictionary_fields(world,["schema_version","seed_hex","settings","terrain_state","plan","transit","buildings","families","pending","events","bridge","phrase_index","era","next_id","lifecycle","rng"],"AudioPlan WorldSnapshot缺少")
	if not bool(world_fields.get("ok",false)): return world_fields
	if not _is_integer(world["schema_version"]) or int(world["schema_version"]) != 2:
		return {"ok":false,"reason":"AudioPlan WorldSnapshot版本不支持"}
	if not world["seed_hex"] is String or str(world["seed_hex"]).is_empty():
		return {"ok":false,"reason":"AudioPlan WorldSnapshot缺少有效seed"}
	if not world["settings"] is Dictionary or not world["terrain_state"] is Dictionary or not world["plan"] is Dictionary:
		return {"ok":false,"reason":"AudioPlan WorldSnapshot格式不支持"}
	if not world["transit"] is Dictionary or not world["buildings"] is Array or not world["families"] is Dictionary:
		return {"ok":false,"reason":"AudioPlan WorldSnapshot实体格式不支持"}
	if not world["pending"] is Dictionary or not world["events"] is Array or typeof(world["bridge"]) != TYPE_BOOL:
		return {"ok":false,"reason":"AudioPlan WorldSnapshot状态格式不支持"}
	for field in ["phrase_index","era","next_id"]:
		if not _is_integer(world[field]) or int(world[field]) < 0:
			return {"ok":false,"reason":"AudioPlan WorldSnapshot计数格式不支持"}
	if not world["lifecycle"] is Dictionary or not world["rng"] is Dictionary:
		return {"ok":false,"reason":"AudioPlan WorldSnapshot运行时格式不支持"}
	var plan: Dictionary = world["plan"]
	for field in ["lots","roads","nodes","blocks","communities"]:
		if not plan.has(field): return {"ok":false,"reason":"AudioPlan WorldSnapshot计划缺少"+field}
	if not plan["lots"] is Array or not plan["roads"] is Array or not plan["nodes"] is Dictionary or not plan["blocks"] is Array or not plan["communities"] is Dictionary:
		return {"ok":false,"reason":"AudioPlan WorldSnapshot计划格式不支持"}
	return {"ok":true}

static func validate_audio_plan(source: Variant) -> Dictionary:
	var loaded := _audio_source(source)
	if not bool(loaded.get("ok",false)): return loaded
	var dna: Dictionary = loaded.get("dna",{})
	var plan_value: Variant = dna.get("audio_plan",null)
	if not plan_value is Dictionary:
		return {"ok":false,"reason":"AudioPlan字段格式不支持"}
	var plan: Dictionary = plan_value
	if plan.is_empty() or not plan.get("schema","") is String or str(plan["schema"]) != "resonance_audio_plan_v1":
		return {"ok":false,"reason":"AudioPlan版本不支持"}
	var model_value: Variant = loaded.get("model",{})
	if not model_value is Dictionary:
		return {"ok":false,"reason":"AudioPlan运行时模型格式不支持"}
	var model: Dictionary = model_value
	var model_shape := _validate_audio_model_shape(model)
	if not bool(model_shape.get("ok",false)): return model_shape
	var world_value: Variant = model.get("world",{})
	if not world_value is Dictionary: return {"ok":false,"reason":"AudioPlan缺少WorldSnapshot"}
	var world: Dictionary = world_value
	var settings_value: Variant = world.get("settings",{})
	if not settings_value is Dictionary or not settings_value.get("timing",{}) is Dictionary:
		return {"ok":false,"reason":"AudioPlan缺少时间设置"}
	var timing: Dictionary = settings_value["timing"]
	var phrase_value: Variant = plan.get("phrase_frames",null)
	var rate_value: Variant = plan.get("sample_rate",null)
	if not _is_integer(phrase_value) or not _is_integer(rate_value):
		return {"ok":false,"reason":"AudioPlan时间基准格式不支持"}
	var phrase_frames := int(phrase_value)
	var sample_rate := int(rate_value)
	if phrase_frames <= 0 or sample_rate <= 0:
		return {"ok":false,"reason":"AudioPlan缺少有效时间基准"}
	if not _is_integer(timing.get("phrase_frames",null)) or not _is_integer(timing.get("sample_rate",null)):
		return {"ok":false,"reason":"AudioPlan运行时时间基准格式不支持"}
	if phrase_frames != int(timing["phrase_frames"]) or sample_rate != int(timing["sample_rate"]):
		return {"ok":false,"reason":"AudioPlan时间基准与运行时不一致"}
	var world_events_value: Variant = plan.get("world_events",null)
	if not world_events_value is Array: return {"ok":false,"reason":"AudioPlan世界事件格式不支持"}
	for event in world_events_value:
		if not event is Dictionary: return {"ok":false,"reason":"AudioPlan世界事件格式不支持"}
	var sound_events_value: Variant = plan.get("sound_events",null)
	if not sound_events_value is Array:
		return {"ok":false,"reason":"AudioPlan声音事件格式不支持"}
	var sound_events: Array = sound_events_value
	var previous_sound_frame := -1
	for event in sound_events:
		if not event is Dictionary or not event.has("sound_frame") or not event.has("kind"):
			return {"ok":false,"reason":"AudioPlan声音事件缺少sound_frame"}
		if not event["kind"] is String or str(event["kind"]).is_empty() or not _is_integer(event["sound_frame"]):
			return {"ok":false,"reason":"AudioPlan声音事件字段格式不支持"}
		var frame := int(event["sound_frame"])
		if frame < 0: return {"ok":false,"reason":"AudioPlan声音事件帧无效"}
		if frame < previous_sound_frame:
			return {"ok":false,"reason":"AudioPlan声音事件未按时间排序"}
		previous_sound_frame = frame
	var renderer_value: Variant = loaded.get("renderer",{})
	if not renderer_value is Dictionary: return {"ok":false,"reason":"AudioPlan渲染器快照格式不支持"}
	var renderer: Dictionary = renderer_value
	if not renderer.has("transport") or not renderer.has("state"):
		return {"ok":false,"reason":"AudioPlan渲染器状态不完整"}
	var transport_value: Variant = renderer["transport"]
	var state_value: Variant = renderer["state"]
	if not transport_value is Dictionary or not state_value is Dictionary:
		return {"ok":false,"reason":"AudioPlan渲染器状态格式不支持"}
	var transport: Dictionary = transport_value
	var transport_fields := _has_dictionary_fields(transport,["rendered_frames","audible_frame","pending","accepted_events","approved_proposals"],"AudioPlan渲染器状态缺少")
	if not bool(transport_fields.get("ok",false)): return transport_fields
	if not _is_integer(transport["rendered_frames"]) or int(transport["rendered_frames"]) < 0 or not _is_number(transport["audible_frame"]):
		return {"ok":false,"reason":"AudioPlan渲染游标格式不支持"}
	var rendered_until := int(model["rendered_until"])
	var audible_frame := float(transport["audible_frame"])
	if audible_frame != audible_frame or audible_frame < 0.0 or audible_frame > float(int(transport["rendered_frames"])):
		return {"ok":false,"reason":"AudioPlan可听游标格式不支持"}
	if int(transport["rendered_frames"]) != rendered_until:
		return {"ok":false,"reason":"AudioPlan与PCM渲染游标不一致"}
	if not transport["pending"] is Array or not transport["accepted_events"] is Array or not transport["approved_proposals"] is Dictionary:
		return {"ok":false,"reason":"AudioPlan渲染器队列格式不支持"}
	for item in transport["pending"]:
		if not item is Dictionary: return {"ok":false,"reason":"AudioPlan渲染器队列格式不支持"}
	for item in transport["accepted_events"]:
		if not item is Dictionary: return {"ok":false,"reason":"AudioPlan渲染器事件格式不支持"}
	for key in transport["approved_proposals"]:
		if not transport["approved_proposals"][key] is Dictionary:
			return {"ok":false,"reason":"AudioPlan渲染器提案格式不支持"}
	var decisions_value: Variant = plan.get("decisions",[])
	if not decisions_value is Array: return {"ok":false,"reason":"AudioPlan决策记录格式不支持"}
	var decisions: Array = decisions_value
	for decision in decisions:
		if not decision is Dictionary or not decision.has("operation") or not decision["operation"] is Dictionary:
			return {"ok":false,"reason":"AudioPlan决策记录格式不支持"}
	var trace_value: Variant = plan.get("sound_trace",null)
	if not trace_value is Array:
		return {"ok":false,"reason":"AudioPlan声音轨迹格式不支持"}
	for trace in trace_value:
		if not trace is Dictionary: return {"ok":false,"reason":"AudioPlan声音轨迹格式不支持"}
	return {"ok":true,"dna":dna,"model":model,"renderer":renderer,"plan":plan,
		"phrase_frames":phrase_frames,"sample_rate":sample_rate,
		"rendered_until":rendered_until,"sound_event_count":sound_events.size(),
		"decision_count":decisions.size()}

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
