class_name PlayerNeighborhoods
extends RefCounted
## City-level authorship only. Never submits or writes a World/AudioModel.
const SCHEMA := 1
const MAX_JSON_INTEGER := 9007199254740991
var _next_neighborhood_id := 1
var _neighborhoods: Array[Dictionary] = []

func reset() -> void:
	_next_neighborhood_id = 1
	_neighborhoods.clear()

static func _integer(value: Variant, minimum: int) -> bool:
	if typeof(value) not in [TYPE_INT,TYPE_FLOAT]: return false
	var number := float(value)
	return is_finite(number) and number >= float(minimum) and number <= float(MAX_JSON_INTEGER) and floor(number) == number

static func _failure(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}

func restore(saved: Dictionary) -> Dictionary:
	# Do not clear a valid author collection before a complete validation.
	if not _integer(saved.get("schema",null),1) or int(saved["schema"]) != SCHEMA:
		return _failure("街坊作者记录版本不支持")
	if not _integer(saved.get("next_neighborhood_id",null),1) or not saved.get("neighborhoods",null) is Array:
		return _failure("街坊作者容器不完整")
	var restored: Array[Dictionary] = []
	var identities: Dictionary = {}
	for raw in saved["neighborhoods"]:
		if not raw is Dictionary: return _failure("街坊记录格式不支持")
		if not raw.get("id",null) is String or str(raw["id"]).is_empty() or identities.has(raw["id"]):
			return _failure("街坊身份缺失或重复")
		if not raw.get("name",null) is String or str(raw["name"]).strip_edges().is_empty():
			return _failure("街坊名字不能为空")
		if str(raw.get("selection_kind","")) != "explicit_buildings":
			return _failure("街坊选择来源不支持")
		if not _integer(raw.get("revision",null),1) or not _integer(raw.get("created_audio_frame",null),0) or not _integer(raw.get("modified_audio_frame",null),0):
			return _failure("街坊修订或音频帧无效")
		if int(raw["modified_audio_frame"]) < int(raw["created_audio_frame"]):
			return _failure("街坊编辑帧早于创建帧")
		if not raw.get("member_ids",null) is Array or raw["member_ids"].is_empty():
			return _failure("街坊成员不能为空")
		var ids: Array[String] = []
		for id in raw["member_ids"]:
			if not id is String or str(id).is_empty() or ids.has(str(id)):
				return _failure("街坊成员身份无效或重复")
			ids.append(str(id))
		ids.sort()
		restored.append({"id":str(raw["id"]),"name":str(raw["name"]).strip_edges(),"revision":int(raw["revision"]),
			"member_ids":ids,"selection_kind":"explicit_buildings","created_audio_frame":int(raw["created_audio_frame"]),
			"modified_audio_frame":int(raw["modified_audio_frame"])})
		identities[raw["id"]] = true
	_next_neighborhood_id = int(saved["next_neighborhood_id"])
	_neighborhoods = restored
	return {"ok":true,"reason":""}

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"next_neighborhood_id":_next_neighborhood_id,"neighborhoods":_neighborhoods.duplicate(true)}

func records() -> Array[Dictionary]:
	return _neighborhoods.duplicate(true)

func record(id: String) -> Dictionary:
	for item in _neighborhoods:
		if str(item["id"]) == id: return item.duplicate(true)
	return {}

func for_member(building_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in _neighborhoods:
		if item["member_ids"].has(building_id): result.append(item.duplicate(true))
	return result

static func _heard(city: RefCounted, id: String, heard_frame: int) -> bool:
	var by_id: Dictionary = city.get("by_id")
	return by_id.has(id) and int(by_id[id].get("birth_frame",0)) <= heard_frame

func confirm(city: RefCounted, heard_frame: int, member_ids: Array[String], name: String, record_id: String = "") -> Dictionary:
	var clean_name := name.strip_edges()
	if clean_name.is_empty(): return _failure("先给街坊起一个名字")
	if member_ids.is_empty(): return _failure("先选至少一栋已经听见的房屋")
	if city == null or not _integer(heard_frame,0): return _failure("当前可听城市无效")
	var previous := record(record_id)
	if not record_id.is_empty() and previous.is_empty(): return _failure("这份街坊记录已不存在")
	if not previous.is_empty() and heard_frame < int(previous["modified_audio_frame"]):
		return _failure("当前可听时间早于街坊上次编辑")
	var previous_ids: Array = previous.get("member_ids",[])
	var ids: Array[String] = []
	for id in member_ids:
		if id.is_empty() or (not _heard(city,id,heard_frame) and not previous_ids.has(id)):
			return _failure("所选成员不存在或还没有听见："+id)
		if not ids.has(id): ids.append(id)
	# A visible-only editor must not erase an old, currently unavailable source.
	for raw_id in previous_ids:
		var id := str(raw_id)
		if not _heard(city,id,heard_frame) and not ids.has(id): ids.append(id)
	ids.sort()
	var identity := record_id
	var revision := int(previous.get("revision",0))+1
	if revision > MAX_JSON_INTEGER: return _failure("街坊修订已超出保存范围")
	if identity.is_empty():
		var serial := _next_neighborhood_id
		identity = "neighborhood-%06d" % serial
		while not record(identity).is_empty():
			serial += 1
			identity = "neighborhood-%06d" % serial
		if serial >= MAX_JSON_INTEGER: return _failure("街坊身份已超出保存范围")
		_next_neighborhood_id = serial+1
	var confirmed := {"id":identity,"name":clean_name,"revision":revision,"member_ids":ids,
		"selection_kind":"explicit_buildings","created_audio_frame":int(previous.get("created_audio_frame",heard_frame)),
		"modified_audio_frame":heard_frame}
	if previous.is_empty(): _neighborhoods.append(confirmed)
	else:
		for index in range(_neighborhoods.size()):
			if str(_neighborhoods[index]["id"]) == identity:
				_neighborhoods[index] = confirmed
				break
	return {"ok":true,"record":confirmed.duplicate(true),"reason":""}
