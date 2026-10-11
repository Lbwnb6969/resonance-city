extends RefCounted
## A route anchors one real charter, while roads, passenger observations and
## growth remain authoritative. Historical lines keep their original source.
const Charter = preload("res://scripts/world/development_charter.gd")
const FIELDS := ["charter_id","plan_id","scope_community_ids","covered_scope_community_ids",
	"uncovered_scope_community_ids","scope_covered_building_ids"]

static func _id(record: Dictionary) -> String:
	return str(record.get("charter_id","charter-%05d" % int(record.get("event_id",-1))))

static func _effective(world: RefCounted,cid: String) -> Dictionary:
	var visited: Array[String] = []
	while world.communities.has(cid) and not visited.has(cid):
		for index in range(world.pending_actions.size()-1,-1,-1):
			var operation: Dictionary = world.pending_actions[index]
			if str(operation.get("kind","")) == "charter" and operation.get("community_ids",[]).has(cid): return operation
		for index in range(world.development_charters.size()-1,-1,-1):
			var charter: Dictionary = world.development_charters[index]
			if charter.get("community_ids",[]).has(cid): return charter
		visited.append(cid)
		cid = str(world.communities[cid].get("parent_id",""))
	return {}

static func source(world: RefCounted,charter_id: String) -> Dictionary:
	var result := {"accepted":false,"reason":"这份发展章程已不存在，请重新选择章程范围",
		"charter_id":charter_id,"plan_id":"","scope_community_ids":[]}
	var record: Dictionary = {}
	for operation in world.pending_actions:
		if str(operation.get("kind","")) == "charter" and _id(operation) == charter_id:
			record = operation
			break
	if record.is_empty():
		for charter in world.development_charters:
			if _id(charter) == charter_id:
				record = charter
				break
	if record.is_empty(): return result
	result["plan_id"] = str(record.get("plan_id",""))
	var scope: Array[String] = []
	for raw_id in record.get("community_ids",[]):
		var cid := str(raw_id)
		if not scope.has(cid): scope.append(cid)
	scope.sort()
	result["scope_community_ids"] = scope
	var reason := Charter.reason(world,record)
	if not reason.is_empty():
		result["reason"] = reason
		return result
	for raw_cid in world.communities:
		var cid := str(raw_cid)
		if Charter.in_scope(world,cid,scope) and _id(_effective(world,cid)) == charter_id:
			result["accepted"] = true
			result["reason"] = ""
			return result
	result["reason"] = "这份发展章程已被新选择替换，请重新选择章程范围"
	return result

static func _route(world: RefCounted,payload: Dictionary) -> Dictionary:
	var positions: Array = payload.get("stop_positions",[]).duplicate(true)
	if positions.is_empty():
		for raw_stop in payload.get("intent_stop_ids",payload.get("stops",payload.get("route_stops",payload.get("stop_ids",[])))):
			if raw_stop is Dictionary:
				positions.append(raw_stop["position"].duplicate())
			else:
				var id := str(raw_stop)
				if world.nodes.has(id): positions.append(world.nodes[id].duplicate())
				elif world.authored_transit_stops.has(id): positions.append(world.authored_transit_stops[id]["position"].duplicate())
	return world.transit_plan_preview(positions)

static func _coverage(world: RefCounted,route: Dictionary,origin: Dictionary,current_only: bool) -> Dictionary:
	var result := {"charter_id":str(origin.get("charter_id","")),"plan_id":str(origin.get("plan_id","")),
		"scope_community_ids":origin.get("scope_community_ids",[]).duplicate(true),
		"covered_scope_community_ids":[],"uncovered_scope_community_ids":[],"scope_covered_building_ids":[]}
	var scope: Array = result["scope_community_ids"]
	for raw_cid in route.get("community_ids",[]):
		var cid := str(raw_cid)
		if current_only and _id(_effective(world,cid)) != result["charter_id"]: continue
		for scope_cid in scope:
			if Charter.in_scope(world,cid,[scope_cid]) and not result["covered_scope_community_ids"].has(scope_cid):
				result["covered_scope_community_ids"].append(scope_cid)
	for raw_id in route.get("covered_building_ids",[]):
		var id := str(raw_id)
		var building: Dictionary = world.by_id.get(id,{})
		var cid := str(building.get("community_id",""))
		if Charter.in_scope(world,cid,scope) and (not current_only or _id(_effective(world,cid)) == result["charter_id"]):
			result["scope_covered_building_ids"].append(id)
	for cid in scope:
		if not result["covered_scope_community_ids"].has(cid): result["uncovered_scope_community_ids"].append(cid)
	result["covered_scope_community_ids"].sort()
	result["scope_covered_building_ids"].sort()
	return result

static func preview(world: RefCounted,route_payload: Dictionary,charter_id: String) -> Dictionary:
	var origin := source(world,charter_id)
	if not bool(origin["accepted"]):
		origin.merge({"covered_scope_community_ids":[],"uncovered_scope_community_ids":origin["scope_community_ids"].duplicate(),"scope_covered_building_ids":[]})
		return origin
	var route := _route(world,route_payload)
	var result := _coverage(world,route,origin,true)
	result["accepted"] = bool(route.get("accepted",false)) and not result["covered_scope_community_ids"].is_empty()
	result["reason"] = str(route.get("reason","")) if not bool(route.get("accepted",false)) else "" if bool(result["accepted"]) else "线路还未接入章程范围，请在所选社区的真实道路上加站"
	return result

## Runtime coverage follows real growth, but changing a later charter never
## deletes a settled route or rewrites its original charter identity.
static func settled_coverage(world: RefCounted,route: Dictionary,origin: Dictionary) -> Dictionary:
	return _coverage(world,route,origin,false)

static func apply(target: Dictionary,association: Dictionary) -> void:
	for field: String in FIELDS:
		if association.has(field):
			var value: Variant = association[field]
			target[field] = value.duplicate(true) if value is Array else value
