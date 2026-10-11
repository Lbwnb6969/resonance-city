extends RefCounted
## Change the use of an already authored public footprint in place. The site
## remains one stable object; no land is selected, released or created here.
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")

static func _site(world: RefCounted,site_id: String) -> Dictionary:
	for site in world.public_sites:
		if str(site.get("id","")) == site_id: return site
	return {}

static func _source_revision(site: Dictionary) -> String:
	# Derived service/coverage and phrase progression are not authored edits.
	# Use, capacity, geometry and provenance do invalidate the old choice.
	var basis := [str(site.get("id","")),int(site.get("frame",0)),str(site.get("kind","")),
		int(site.get("service_level",1)),site.get("position",[]),site.get("entrance",[]),
		SpatialPlanning.normalize_polygon(site.get("polygon",[])),SpatialPlanning.footprint_components(site),SpatialPlanning.footprint_holes(site),
		str(site.get("source_site_id","")),site.get("source_lot_ids",[]),str(site.get("source_reservation_id",""))]
	return JSON.stringify(basis).sha256_text()

static func candidate(world: RefCounted,site_id: String) -> Dictionary:
	var result := {"allowed":false,"reason":"找不到这座公共设施","reuse":true,
		"public_id":site_id,"source_site_id":site_id}
	var site := _site(world,site_id)
	if site.is_empty(): return result
	if not bool(site.get("active",false)):
		result["reason"] = "设施尚未落成，先完成公共空间营造"
		return result
	if str(site.get("kind","")) not in ["park","civic"]:
		result["reason"] = "这处设施不能改作公园或文化馆"
		return result
	for key: String in ["position","polygon","footprint_components","target_polygons","hole_polygons","target_holes",
			"community_id","target_community_ids","entrance","road_id","access_path","service_level","name"]:
		if not site.has(key): continue
		var value: Variant = site[key]
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value.duplicate() if value is PackedVector2Array else value
	result["current_kind"] = str(site["kind"])
	result["source_revision"] = _source_revision(site)
	result["allowed"] = true
	result["reason"] = "保留现有占地，可在下一句改用"
	return result

static func validate(world: RefCounted,operation: Dictionary) -> Dictionary:
	var site_id := str(operation.get("id",operation.get("public_id","")))
	var current := candidate(world,site_id)
	current["accepted"] = bool(current.get("allowed",false))
	if not bool(current["accepted"]): return current
	if str(operation.get("kind","")) not in ["park","civic"]:
		current["accepted"] = false
		current["reason"] = "原位改用只支持公园或文化馆"
	elif str(operation.get("source_revision",current["source_revision"])) != str(current["source_revision"]):
		current["accepted"] = false
		current["reason"] = "这处公共设施已变化，请重新比较用途"
	elif operation.get("position",current["position"]) != current["position"]:
		current["accepted"] = false
		current["reason"] = "原位改用保留现有位置；移动设施请使用搬迁"
	return current

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> Dictionary:
	var current := validate(world,operation)
	if not bool(current.get("accepted",false)): return current
	var site_id := str(current["public_id"])
	var site := _site(world,site_id)
	var previous_kind := str(site["kind"])
	var kind := str(operation["kind"])
	# Keep every authored field, including capacity investment, source lots and
	# components/holes. Only the use and its planning influence change.
	site["kind"] = kind
	site["frame"] = frame
	var influence: Dictionary = site.get("influence_config",{}).duplicate(true)
	influence["relation"] = "支持" if kind == "civic" else "吸引"
	influence["planning_radius"] = 6.0 if kind == "civic" else 5.0
	site["influence_config"] = influence
	world._refresh_parcel_index()
	var event := {"kind":kind,"reuse":true,"id":site_id,"source_site_id":site_id,
		"previous_kind":previous_kind,"event_id":int(operation.get("event_id",-1)),"frame":frame,
		"source_revision":str(current["source_revision"]),"position":site["position"].duplicate(true),
		"polygon":site["polygon"].duplicate(),"community_id":str(site.get("community_id","")),
		"service_level":int(site.get("service_level",1))}
	for key: String in ["footprint_components","target_polygons","hole_polygons","target_holes","target_community_ids","source_lot_ids"]:
		if site.has(key): event[key] = site[key].duplicate(true)
	world.events.append(event)
	return {"accepted":true,"id":site_id,"kind":kind,"previous_kind":previous_kind,"event_id":event["event_id"],"frame":frame}
