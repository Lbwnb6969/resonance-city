extends RefCounted
## Edit one authored route in place. Retained stations let in-flight vehicles
## finish their old leg and physically rejoin the same stable service.
const CharterAnchor = preload("res://scripts/world/transit_charter_anchor.gd")

static func _intent(world: RefCounted,line_id: String) -> Dictionary:
	for intent in world.authored_transit_lines:
		if str(intent.get("id","")) == line_id: return intent
	return {}

static func _revision(intent: Dictionary) -> String:
	return JSON.stringify([str(intent.get("id","")),intent.get("stop_ids",[]),str(intent.get("route_mode","out_and_back")),int(intent.get("revision",0))]).sha256_text()

static func _position(world: RefCounted,stop_id: String) -> Variant:
	if world.nodes.has(stop_id): return world.nodes[stop_id].duplicate()
	if world.authored_transit_stops.has(stop_id): return world.authored_transit_stops[stop_id]["position"].duplicate()
	return null

static func candidate(world: RefCounted,line_id: String) -> Dictionary:
	var result := {"accepted":false,"reason":"这条作者线路已不存在，请重新选择线路","id":line_id,"edit_id":line_id}
	var intent := _intent(world,line_id)
	if intent.is_empty(): return result
	var positions: Array = []
	for raw_id in intent.get("stop_ids",[]):
		var position: Variant = _position(world,str(raw_id))
		if position == null:
			result["reason"] = "线路原站位已不存在，请先恢复道路站位"
			return result
		positions.append(position)
	if str(intent.get("route_mode","")) == "loop" and not positions.is_empty() and positions[0] != positions[-1]: positions.append(positions[0].duplicate())
	result.merge({"accepted":true,"reason":"","line_name":str(intent.get("name","自定线路")),
		"source_revision":_revision(intent),"stop_positions":positions,"source_topology":world.network.topology,
		"edit_revision":int(intent.get("revision",0)),"original_event_id":int(intent.get("event_id",0)),"created_frame":int(intent.get("frame",0))},true)
	CharterAnchor.apply(result,intent)
	return result

static func _historical_stops(intent: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_id in intent.get("retained_stop_ids",[])+intent.get("stop_ids",[]):
		var id := str(raw_id)
		if not result.has(id): result.append(id)
	return result

static func _coverage(world: RefCounted,plan: Dictionary,intent: Dictionary) -> Dictionary:
	var payload := plan.duplicate(true)
	payload["id"] = str(intent["id"])
	if not str(intent.get("charter_id","")).is_empty():
		CharterAnchor.apply(payload,CharterAnchor.settled_coverage(world,plan,intent))
	return world.transit_line_coverage_summary(payload)

static func _difference(after: Array,before: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_id in after:
		var id := str(raw_id)
		if not before.has(id) and not result.has(id): result.append(id)
	result.sort()
	return result

## Keep and edit must validate the same authored source before changing any
## pending intent. Growth and derived ridership do not change this revision.
static func source(world: RefCounted,operation: Dictionary) -> Dictionary:
	var line_id := str(operation.get("edit_id",operation.get("id","")))
	var original := candidate(world,line_id)
	if not bool(original.get("accepted",false)): return original
	if str(operation.get("source_revision","")) != str(original["source_revision"]):
		return {"accepted":false,"reason":"这条线路已被改站，请重新打开当前站序","edit_id":line_id}
	if str(operation.get("source_topology",original["source_topology"])) != str(original["source_topology"]):
		return {"accepted":false,"reason":"道路已经变化，请重新查看改站预影","edit_id":line_id}
	return original

static func preview(world: RefCounted,operation: Dictionary) -> Dictionary:
	var original := source(world,operation)
	if not bool(original.get("accepted",false)): return original
	var line_id := str(original["id"])
	if bool(operation.get("keep",false)):
		# Keeping never requires a new route or reconnect. A broken old route
		# remains the player's line while its queued replacement is withdrawn.
		var current := _intent(world,line_id).duplicate(true)
		for line in world.transit_lines:
			if str(line.get("id","")) == line_id:
				current = line.duplicate(true)
				break
		var coverage: Dictionary = current.get("coverage",{}).duplicate(true)
		if coverage.is_empty():
			var stops: Array[Dictionary] = []
			for raw_id in _intent(world,line_id).get("stop_ids",[]):
				stops.append({"id":str(raw_id),"position":_position(world,str(raw_id))})
			var payload := current.duplicate(true)
			payload["stops"] = stops
			coverage = world.transit_line_coverage_summary(payload)
		current.merge(original,true)
		current.merge({"keep":true,"edit":false,"old_coverage":coverage.duplicate(true),"new_coverage":coverage.duplicate(true),
			"coverage":coverage,"added_covered_building_ids":[],"removed_covered_building_ids":[],"added_community_ids":[],"removed_community_ids":[]},true)
		return current
	var plan: Dictionary = world.transit_plan_preview(operation.get("stop_positions",[]))
	if not bool(plan.get("accepted",false)): return plan
	var intent := _intent(world,line_id)
	var first: Array = plan["stops"][0]["position"]
	var target := Vector2(float(first[0]),float(first[1]))
	for id in _historical_stops(intent):
		var position: Variant = _position(world,id)
		if position == null: return {"accepted":false,"reason":"在途车辆的旧站位已不存在，无法原路接回","edit_id":line_id}
		var p := Vector2(float(position[0]),float(position[1]))
		var reconnect: Dictionary = world.network.walking_route(p,target)
		if not is_finite(float(reconnect.get("distance",INF))) or reconnect.get("path",PackedVector2Array()).is_empty():
			return {"accepted":false,"reason":"旧站没有真实道路接回新线路；先连通道路再改站","edit_id":line_id,"disconnected_stop_id":id}
	var old_plan: Dictionary = world.transit_plan_preview(original["stop_positions"])
	var old_coverage := _coverage(world,old_plan,intent)
	var new_coverage := _coverage(world,plan,intent)
	plan.merge({"edit":true,"id":line_id,"edit_id":line_id,"line_name":original["line_name"],"source_revision":original["source_revision"],
		"edit_revision":original["edit_revision"],"original_event_id":original["original_event_id"],"created_frame":original["created_frame"],
		"old_coverage":old_coverage,"new_coverage":new_coverage,"coverage":new_coverage.duplicate(true),
		"added_covered_building_ids":_difference(new_coverage["covered_building_ids"],old_coverage["covered_building_ids"]),
		"removed_covered_building_ids":_difference(old_coverage["covered_building_ids"],new_coverage["covered_building_ids"]),
		"added_community_ids":_difference(new_coverage["community_ids"],old_coverage["community_ids"]),
		"removed_community_ids":_difference(old_coverage["community_ids"],new_coverage["community_ids"]),
		"line_ids":new_coverage["line_ids"].duplicate(),"transfer_stop_ids":new_coverage["transfer_stop_ids"].duplicate(),"route_role":new_coverage["route_role"]},true)
	if not str(intent.get("charter_id","")).is_empty(): CharterAnchor.apply(plan,new_coverage)
	return plan

static func keep(world: RefCounted,operation: Dictionary) -> Dictionary:
	var original := source(world,operation)
	if not bool(original.get("accepted",false)): return original
	var line_id := str(original["id"])
	var remaining: Array[Dictionary] = world.pending_actions.filter(func(op: Dictionary) -> bool:
		return not (str(op.get("kind","")) == "transit_line" and str(op.get("edit_id","")) == line_id))
	# pending is the legacy mirror consumed by settle when the queue is empty.
	# Clear/repoint that mirror as well so a canceled edit cannot return later.
	var changed: bool = remaining.size() != world.pending_actions.size() or (str(world.pending.get("kind","")) == "transit_line" and str(world.pending.get("edit_id","")) == line_id)
	if changed:
		world.pending_actions = remaining
		world.pending = remaining[-1].duplicate(true) if not remaining.is_empty() else {}
	return {"accepted":true,"kept":true,"changed":changed,"frame":-1,"id":line_id,"edit_id":line_id}

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> Dictionary:
	if bool(operation.get("keep",false)): return keep(world,operation)
	var plan := preview(world,operation)
	if not bool(plan.get("accepted",false)): return plan
	var intent := _intent(world,str(plan["id"]))
	var retained := _historical_stops(intent)
	var chosen: Array[String] = []
	for stop in plan["stops"]:
		var id := str(stop["id"])
		if not world.nodes.has(id): world.authored_transit_stops[id] = stop.duplicate(true)
		chosen.append(id)
	intent["stop_ids"] = chosen
	intent["route_mode"] = plan["route_mode"]
	intent["source_topology"] = plan["source_topology"]
	intent["retained_stop_ids"] = retained
	intent["edited_frame"] = frame
	intent["edit_event_id"] = int(operation["event_id"])
	intent["revision"] = int(intent.get("revision",0))+1
	intent["line_ids"] = plan["line_ids"].duplicate()
	intent["transfer_stop_ids"] = plan["transfer_stop_ids"].duplicate()
	intent["route_role"] = plan["route_role"]
	if not str(intent.get("charter_id","")).is_empty(): CharterAnchor.apply(intent,plan)
	var event := {"kind":"transit_line","edit":true,"id":str(intent["id"]),"event_id":int(operation["event_id"]),"frame":frame,
		"original_event_id":int(intent["event_id"]),"created_frame":int(intent["frame"]),"edit_revision":int(intent["revision"]),
		"edited_frame":frame,"edit_event_id":int(operation["event_id"]),"stop_ids":chosen.duplicate(),
		"community_ids":plan["community_ids"].duplicate(),"covered_building_ids":plan["covered_building_ids"].duplicate(),
		"route_mode":plan["route_mode"],"source_topology":plan["source_topology"],"source_revision":str(plan["source_revision"]),
		"coverage":plan["new_coverage"].duplicate(true),"line_ids":plan["line_ids"].duplicate(),"transfer_stop_ids":plan["transfer_stop_ids"].duplicate(),
		"route_role":plan["route_role"],"music_feedback":{}}
	for key: String in ["old_coverage","new_coverage","added_covered_building_ids","removed_covered_building_ids","added_community_ids","removed_community_ids"]:
		event[key] = plan[key].duplicate(true)
	if not str(intent.get("charter_id","")).is_empty(): CharterAnchor.apply(event,plan)
	world.events.append(event)
	return {"accepted":true,"edit":true,"id":str(intent["id"]),"edit_revision":int(intent["revision"])}
