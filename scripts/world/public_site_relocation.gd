extends RefCounted
## Read-only preview for moving an already active public site.
##
## The preview owns no world truth and never queues or settles an action.  It
## keeps the site's stable ID while translating its existing footprint and
## asking the shared planning module for exclusion and road access.  Service
## impact is simulated from the same covered-building and civic-capacity rules
## used by ContinuousWorld._refresh_public_network().

const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const FabricRelations = preload("res://scripts/world/fabric_relations.gd")

static func _site(world: RefCounted,site_id: String) -> Dictionary:
	for site in world.public_sites:
		if str(site.get("id", "")) == site_id:
			return site
	return {}

static func _source_revision(world: RefCounted,site: Dictionary) -> String:
	# Phrase progression and derived coverage do not invalidate a geometric
	# relocation preview; the boundary itself may grow buildings. Canonical site
	# identity, footprint, entrance, use and capacity do detect real edits.
	var basis := [site.get("id", ""),site.get("frame", 0),site.get("kind", ""),site.get("service_level", 1),
		site.get("position", []),site.get("polygon", PackedVector2Array()),site.get("footprint_components",[]),site.get("hole_polygons",site.get("target_holes",[])),site.get("entrance", [])]
	return JSON.stringify(basis).sha256_text()

static func _translated_polygon(site: Dictionary,target: Vector2) -> PackedVector2Array:
	var origin := Vector2(float(site["position"][0]),float(site["position"][1]))
	var result := PackedVector2Array()
	for point in site.get("polygon", PackedVector2Array()):
		result.append(Vector2(point)+target-origin)
	return result

static func _translated_components(site: Dictionary,target: Vector2) -> Array[PackedVector2Array]:
	var origin := Vector2(float(site["position"][0]),float(site["position"][1]))
	var result: Array[PackedVector2Array] = []
	for component in SpatialPlanning.footprint_components(site):
		var translated := PackedVector2Array()
		for point in component: translated.append(Vector2(point)+target-origin)
		result.append(translated)
	return result

static func _translated_holes(site: Dictionary,target: Vector2) -> Array[PackedVector2Array]:
	var origin := Vector2(float(site["position"][0]),float(site["position"][1]))
	var result: Array[PackedVector2Array] = []
	for hole in SpatialPlanning.footprint_holes(site):
		var translated := PackedVector2Array()
		for point in hole: translated.append(Vector2(point)+target-origin)
		result.append(translated)
	return result

static func _building_access_position(world: RefCounted,building: Dictionary) -> Vector2:
	for lot in world.lots:
		if str(lot.get("occupant", "")) == str(building.get("district_id", "")):
			return Vector2(float(lot["entrance"][0]),float(lot["entrance"][1]))
	return Coupling.position_of(building)

static func _covered(world: RefCounted,entrance: Vector2) -> Array[String]:
	var result: Array[String] = []
	var radius := float(world.cfg["city"]["service_walk_radius"])
	for building in world.buildings:
		var position := _building_access_position(world,building)
		if entrance.distance_squared_to(position) > radius*radius: continue
		if world.network.walking_distance(entrance,position) <= radius:
			result.append(str(building["district_id"]))
	result.sort()
	return result

static func _service_allocation(world: RefCounted,target_id: String,target_covered: Array[String]) -> Dictionary:
	var records: Array[Dictionary] = []
	for site in world.public_sites:
		if not bool(site.get("active",false)) or str(site.get("kind", "")) != "civic": continue
		var id := str(site.get("id", ""))
		var covered: Array = target_covered.duplicate() if id == target_id else site.get("covered", []).duplicate()
		records.append({"id":id,"entrance":site.get("entrance",[]).duplicate(),"covered":covered,
			"capacity":18*int(site.get("service_level",1)),"served":[]})
	var target_record: Dictionary = {}
	for item in records:
		if str(item["id"]) == target_id:
			target_record = item
			break
	if target_record.is_empty(): return {"served":[],"capacity":0}
	var served_by_id: Dictionary = {}
	for record in records:
		for building_id in record["covered"]:
			if not served_by_id.has(str(building_id)): served_by_id[str(building_id)] = []
			served_by_id[str(building_id)].append(record)
	for building_id in served_by_id:
		var choices: Array = served_by_id[building_id]
		var building: Dictionary = world.by_id.get(building_id,{})
		if building.is_empty(): continue
		var position := Coupling.position_of(building)
		choices.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			var ap := Vector2(float(a["entrance"][0]),float(a["entrance"][1]))
			var bp := Vector2(float(b["entrance"][0]),float(b["entrance"][1]))
			var ad := position.distance_squared_to(ap)
			var bd := position.distance_squared_to(bp)
			return str(a["id"]) < str(b["id"]) if is_equal_approx(ad,bd) else ad < bd)
		for record in choices:
			if record["served"].size() >= int(record["capacity"]): continue
			record["served"].append(building_id)
			break
	var target_served: Array[String] = []
	for record in records:
		if str(record["id"]) == target_id:
			target_served.assign(record["served"])
			break
	target_served.sort()
	return {"served":target_served,"capacity":int(target_record["capacity"])}

static func _affected_communities(world: RefCounted,ids: Array) -> Array[String]:
	var result: Array[String] = []
	for building_id in ids:
		if not world.by_id.has(str(building_id)): continue
		var cid := str(world.by_id[str(building_id)].get("community_id", ""))
		if not cid.is_empty() and not result.has(cid): result.append(cid)
	result.sort()
	return result

static func preview(world: RefCounted,site_id: String,target_position: Vector2) -> Dictionary:
	var site := _site(world,site_id)
	if site.is_empty(): return {"accepted":false,"reason":"找不到这座公共设施","source_site_id":site_id}
	if not bool(site.get("active",false)):
		return {"accepted":false,"reason":"设施尚未落成，先完成公共空间营造","source_site_id":site_id}
	var source_position := Vector2(float(site["position"][0]),float(site["position"][1]))
	var target_components := _translated_components(site,target_position)
	var target_holes := _translated_holes(site,target_position)
	var target_polygon := target_components[0] if not target_components.is_empty() else _translated_polygon(site,target_position)
	if target_polygon.size() < 3:
		return {"accepted":false,"reason":"设施没有有效占地","source_site_id":site_id}
	if source_position.distance_squared_to(target_position) < 0.000001:
		return {"accepted":false,"reason":"请选择不同的合法位置","source_site_id":site_id}
	var candidate := {"source_site_id":site_id,"public_id":site_id,"position":[target_position.x,target_position.y],
		"polygon":target_polygon,"footprint_components":target_components,"hole_polygons":target_holes,"target_holes":target_holes,"community_id":FabricRelations.community_for_position(world,target_position)}
	for component in target_components:
		var component_candidate := candidate.duplicate(true)
		component_candidate["polygon"] = component
		component_candidate["footprint_components"] = [component]
		var component_holes: Array[PackedVector2Array] = []
		for hole in target_holes:
			if SpatialPlanning._contains_polygon(component,hole): component_holes.append(hole)
		component_candidate["hole_polygons"] = component_holes
		component_candidate["target_holes"] = component_holes
		var component_reason := SpatialPlanning.site_reason(world,component_candidate,site_id)
		if not component_reason.is_empty():
			candidate["allowed"] = false
			candidate["reason"] = component_reason
			break
	if not candidate.has("reason"):
		var candidate_access := SpatialPlanning.public_access(world,candidate)
		if candidate_access.is_empty():
			candidate["allowed"] = false
			candidate["reason"] = "新位置没有可达的真实道路入口"
		else:
			candidate.merge(candidate_access)
			candidate["allowed"] = true
			candidate["reason"] = "可搬迁到这片合法空地"
	if not bool(candidate.get("allowed",false)):
		return {"accepted":false,"reason":str(candidate.get("reason","这片空间不可用于搬迁")),"source_site_id":site_id,
			"source_revision":_source_revision(world,site),"target_position":[target_position.x,target_position.y],
			"target_polygon":target_polygon,"target_polygons":target_components.duplicate(true),"footprint_components":target_components.duplicate(true),"hole_polygons":target_holes.duplicate(true),"target_holes":target_holes.duplicate(true)}
	var access: Dictionary = candidate
	var target_entrance := Vector2(float(candidate["entrance"][0]),float(candidate["entrance"][1]))
	var before_covered: Array = site.get("covered", []).duplicate()
	var after_covered := _covered(world,target_entrance)
	var before_served: Array = site.get("served", []).duplicate()
	var allocation := _service_allocation(world,site_id,after_covered)
	var after_served: Array = allocation["served"]
	var all_ids: Array = before_covered.duplicate()
	all_ids.append_array(after_covered)
	all_ids.append_array(before_served)
	all_ids.append_array(after_served)
	var gained: Array[String] = []
	var lost: Array[String] = []
	for id in after_covered:
		if not before_covered.has(id): gained.append(str(id))
	for id in before_covered:
		if not after_covered.has(id): lost.append(str(id))
	gained.sort(); lost.sort()
	var affected := _affected_communities(world,all_ids)
	return {"accepted":true,"reason":"可搬迁到这片合法空地","source_site_id":site_id,
		"source_revision":_source_revision(world,site),"kind":str(site.get("kind", "")),
		"source_position":site.get("position",[]).duplicate(),"source_entrance":site.get("entrance",[]).duplicate(),
		"source_community_id":str(site.get("community_id", "")),"target_community_id":str(candidate.get("community_id", "")),
		"target_position":[target_position.x,target_position.y],"target_polygon":target_polygon,
		"target_polygons":target_components.duplicate(true),"footprint_components":target_components.duplicate(true),"hole_polygons":target_holes.duplicate(true),"target_holes":target_holes.duplicate(true),
		"target_entrance":[target_entrance.x,target_entrance.y],"road_id":str(access.get("road_id",access.get("road", ""))),
		"target_access_path":candidate.get("access_path",PackedVector2Array()).duplicate(),
		"covered_before":before_covered,"covered_after":after_covered,"served_before":before_served,
		"served_after":after_served,"added_covered":gained,"lost_covered":lost,
		"affected_communities":affected,"service_delta":{"covered":after_covered.size()-before_covered.size(),
			"served":after_served.size()-before_served.size(),"capacity":int(allocation["capacity"])} }

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> Dictionary:
	## Commit only after request() has stored the read-only preview fields.  This
	## function is intentionally standalone so ContinuousWorld can call it from
	## its phrase-boundary transaction without duplicating service bookkeeping.
	var site_id := str(operation.get("id",operation.get("source_site_id", "")))
	var raw_target: Array = operation.get("target_position",operation.get("position",[]))
	if raw_target.size() != 2: return {"accepted":false,"reason":"搬迁位置缺失"}
	var target := Vector2(float(raw_target[0]),float(raw_target[1]))
	var current := preview(world,site_id,target)
	if not bool(current.get("accepted",false)): return {"accepted":false,"reason":str(current.get("reason","搬迁条件已失效"))}
	var expected := str(operation.get("source_revision", ""))
	if not expected.is_empty() and expected != str(current.get("source_revision", "")):
		return {"accepted":false,"reason":"公共设施所在城市已经变化，请重新查看搬迁预影"}
	if operation.has("target_polygon") and operation["target_polygon"] != current.get("target_polygon",PackedVector2Array()):
		return {"accepted":false,"reason":"搬迁范围已经变化，请重新查看预影"}
	if operation.has("target_polygons") and operation["target_polygons"] != current.get("target_polygons",[]):
		return {"accepted":false,"reason":"搬迁范围已经变化，请重新查看预影"}
	if operation.has("hole_polygons") and operation["hole_polygons"] != current.get("hole_polygons",[]):
		return {"accepted":false,"reason":"搬迁孔洞已经变化，请重新查看预影"}
	if operation.has("target_holes") and operation["target_holes"] != current.get("target_holes",[]):
		return {"accepted":false,"reason":"搬迁孔洞已经变化，请重新查看预影"}
	var site := _site(world,site_id)
	if site.is_empty(): return {"accepted":false,"reason":"找不到这座公共设施"}
	var before_position: Array = site.get("position",[]).duplicate()
	var before_entrance: Array = site.get("entrance",[]).duplicate()
	var before_community := str(site.get("community_id", ""))
	site["position"] = current["target_position"].duplicate()
	site["polygon"] = current["target_polygon"].duplicate()
	site["target_polygons"] = current.get("target_polygons",[current["target_polygon"]]).duplicate(true)
	site["footprint_components"] = current.get("footprint_components",site["target_polygons"]).duplicate(true)
	site["hole_polygons"] = current.get("hole_polygons",[]).duplicate(true)
	site["target_holes"] = current.get("target_holes",site["hole_polygons"]).duplicate(true)
	site["entrance"] = current["target_entrance"].duplicate()
	site["road_id"] = str(current.get("road_id",site.get("road_id","")))
	site["access_path"] = current.get("target_access_path",PackedVector2Array()).duplicate()
	site["community_id"] = str(current.get("target_community_id",current.get("target_community",before_community)))
	site["frame"] = frame
	world._refresh_parcel_index()
	world._refresh_public_network(frame)
	var result := {"accepted":true,"id":site_id,"source_site_id":site_id,"kind":str(site.get("kind", "")),
		"source_position":before_position,"target_position":site["position"].duplicate(),
		"target_polygons":site["target_polygons"].duplicate(true),
		"hole_polygons":site.get("hole_polygons",[]).duplicate(true),"target_holes":site.get("target_holes",[]).duplicate(true),
		"source_entrance":before_entrance,"target_entrance":site["entrance"].duplicate(),
		"source_community_id":before_community,"target_community_id":str(site.get("community_id", "")),
		"covered_before":current.get("covered_before",[]).duplicate(),"covered_after":site.get("covered",[]).duplicate(),
		"served_before":current.get("served_before",[]).duplicate(),"served_after":site.get("served",[]).duplicate(),
		"source_revision":str(current.get("source_revision", "")),"frame":frame}
	world.events.append({"kind":"relocate_public","id":site_id,"source_site_id":site_id,
		"source_position":before_position.duplicate(true),"target_position":site["position"].duplicate(true),
		"source_entrance":before_entrance.duplicate(true),"target_entrance":site["entrance"].duplicate(true),
		"source_community_id":before_community,"target_community_id":str(site.get("community_id", "")),"target_polygons":site["target_polygons"].duplicate(true),"footprint_components":site["footprint_components"].duplicate(true),"hole_polygons":site.get("hole_polygons",[]).duplicate(true),"target_holes":site.get("target_holes",[]).duplicate(true),
		"covered_before":result["covered_before"].duplicate(true),"covered_after":result["covered_after"].duplicate(true),
		"served_before":result["served_before"].duplicate(true),"served_after":result["served_after"].duplicate(true),"frame":frame})
	return result
