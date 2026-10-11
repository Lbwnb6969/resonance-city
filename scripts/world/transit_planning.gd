class_name TransitPlanning
extends RefCounted
## Authored stop/line intent, separate from the physical road graph and derived routes.
const STOP_MERGE_DISTANCE := 0.18
const STOP_ACCESS_DISTANCE := 0.85
const WALK_RADIUS := 4.5

const MUSIC_ROLE_TITLES := {
	"home":"居住声部",
	"market":"商贸律动",
	"workshop":"工坊低音",
	"garden":"公共绿地",
	"choir":"文化声场",
	"center":"混合中心",
	"pulse":"换乘律动",
	"pulse_dense":"密集换乘律动"
}

static func point(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else Vector2(float(raw[0]),float(raw[1]))

static func stop_preview(world: RefCounted, position: Vector2) -> Dictionary:
	if not is_finite(position.x) or not is_finite(position.y):
		return {"accepted":false,"reason":"请选择道路上的站位"}
	var access: Dictionary = world.network.access(position)
	if access.is_empty() or float(access.get("gap",INF)) > STOP_ACCESS_DISTANCE:
		return {"accepted":false,"reason":"站点需要靠近真实道路"}
	var projected := point(access["position"])
	var id := ""
	var node_ids: Array = world.nodes.keys()
	node_ids.sort()
	for node_id in node_ids:
		if point(world.nodes[node_id]).distance_to(projected) <= STOP_MERGE_DISTANCE:
			id = str(node_id)
			projected = point(world.nodes[node_id])
			break
	if id.is_empty():
		var authored_ids: Array = world.authored_transit_stops.keys()
		authored_ids.sort()
		for stop_id in authored_ids:
			var existing: Dictionary = world.authored_transit_stops[stop_id]
			if str(existing.get("road","")) == str(access["road"]) and point(existing["position"]).distance_to(projected) <= STOP_MERGE_DISTANCE:
				id = str(stop_id)
				projected = point(existing["position"])
				break
	access = world.network.access(projected)
	if id.is_empty():
		id = "stop-"+JSON.stringify([access["road"],access["along"]]).sha256_text().substr(0,20)
	return {"accepted":true,"id":id,"position":[projected.x,projected.y],"road":str(access["road"]),"road_id":str(access["road"]),
		"along":float(access["along"]),"access":access.duplicate(true),"authored":not world.nodes.has(id)}

static func _coverage(world: RefCounted, stops: Array) -> Dictionary:
	var covered: Array[String] = []
	var communities: Array[String] = []
	var lots: Dictionary = {}
	for lot in world.lots: lots[str(lot["id"])] = lot
	for building in world.buildings:
		var lot: Dictionary = lots.get(str(building.get("lot_id","")),{})
		var entrance := point(lot.get("entrance",building["position"]))
		for stop in stops:
			var position := point(stop["position"])
			if entrance.distance_squared_to(position) > WALK_RADIUS*WALK_RADIUS: continue
			if world.network.walking_distance(entrance,position) > WALK_RADIUS: continue
			covered.append(str(building["district_id"]))
			var cid := str(building.get("community_id",""))
			if not cid.is_empty() and not communities.has(cid): communities.append(cid)
			break
	# An unbuilt community may still be a real future stop catchment, using its road center.
	for center in world.centers:
		var cid := str(center.get("community_id",center.get("id","")))
		if cid.is_empty() or communities.has(cid): continue
		var position := point(center["position"])
		for stop in stops:
			var stop_position := point(stop["position"])
			if position.distance_squared_to(stop_position) <= WALK_RADIUS*WALK_RADIUS and world.network.walking_distance(position,stop_position) <= WALK_RADIUS:
				communities.append(cid)
				break
	covered.sort()
	communities.sort()
	return {"covered_building_ids":covered,"community_ids":communities}

## Build the read-only coverage contract shared by route preview, settled lines,
## and the planning guide.  The route itself remains authoritative; this helper
## only counts real walking access and describes the communities already touched
## by that route.  In particular, a center with no house yet is reported as a
## future catchment instead of being turned into a fabricated building.
static func coverage_summary(world: RefCounted, payload: Dictionary) -> Dictionary:
	var stop_records: Array[Dictionary] = []
	var seen_stops: Dictionary = {}
	for raw_stop in payload.get("stops",payload.get("route_stops",payload.get("stop_ids",[]))):
		var record: Dictionary = {}
		if raw_stop is Dictionary:
			record = raw_stop.duplicate(true)
		else:
			var raw_stop_id := str(raw_stop)
			if raw_stop_id.is_empty() or seen_stops.has(raw_stop_id): continue
			if world.has_method("transit_stop_record"):
				record = world.transit_stop_record(raw_stop_id)
			if record.is_empty() and world.nodes.has(raw_stop_id):
				record = stop_preview(world,point(world.nodes[raw_stop_id]))
		if record.is_empty(): continue
		var fallback_id := "" if raw_stop is Dictionary else str(raw_stop)
		var stop_id := str(record.get("id",fallback_id))
		if stop_id.is_empty(): stop_id = "stop-%d" % stop_records.size()
		if seen_stops.has(stop_id): continue
		seen_stops[stop_id] = true
		record["id"] = stop_id
		stop_records.append(record)

	var covered_ids: Array[String] = []
	for raw_id in payload.get("covered_building_ids",[]):
		var id := str(raw_id)
		if not id.is_empty() and not covered_ids.has(id): covered_ids.append(id)
	if covered_ids.is_empty() and not stop_records.is_empty():
		covered_ids.assign(_coverage(world,stop_records).get("covered_building_ids",[]))
	covered_ids.sort()

	var community_ids: Array[String] = []
	for raw_id in payload.get("community_ids",[]):
		var id := str(raw_id)
		if not id.is_empty() and not community_ids.has(id): community_ids.append(id)
	if community_ids.is_empty() and not stop_records.is_empty():
		community_ids.assign(_coverage(world,stop_records).get("community_ids",[]))

	var covered_set: Dictionary = {}
	for id in covered_ids: covered_set[id] = true
	var total_by_community: Dictionary = {}
	var covered_by_community: Dictionary = {}
	for building in world.buildings:
		var id := str(building.get("district_id",building.get("id","")))
		var cid := str(building.get("community_id",""))
		if cid.is_empty(): continue
		total_by_community[cid] = int(total_by_community.get(cid,0))+1
		if covered_set.has(id): covered_by_community[cid] = int(covered_by_community.get(cid,0))+1

	# A stop may reach an existing community even when the caller only retained
	# covered house IDs.  Preserve the stop-level community evidence here.
	for stop in stop_records:
		for raw_id in stop.get("community_ids",[]):
			var cid := str(raw_id)
			if not cid.is_empty() and not community_ids.has(cid): community_ids.append(cid)
	community_ids.sort()

	var transfer_stop_ids: Array[String] = []
	for raw_transfer in payload.get("transfer_stops",[]):
		var transfer_id := str(raw_transfer.get("stop_id",raw_transfer) if raw_transfer is Dictionary else raw_transfer)
		if not transfer_id.is_empty() and not transfer_stop_ids.has(transfer_id): transfer_stop_ids.append(transfer_id)
	if transfer_stop_ids.is_empty() and not stop_records.is_empty():
		for stop in stop_records:
			var stop_id := str(stop.get("id",""))
			if stop_id.is_empty(): continue
			var line_ids: Array = stop.get("line_ids",[])
			if line_ids.is_empty():
				for line in world.transit_lines:
					if line.get("stops",[]).has(stop_id): line_ids.append(str(line.get("id","")))
			if line_ids.size() > 1: transfer_stop_ids.append(stop_id)
	transfer_stop_ids.sort()

	var line_ids: Array[String] = []
	for raw_id in payload.get("line_ids",[]):
		var line_id := str(raw_id)
		if not line_id.is_empty() and not line_ids.has(line_id): line_ids.append(line_id)
	if line_ids.is_empty() and payload.has("id") and not str(payload.get("id","")).is_empty():
		line_ids.append(str(payload.get("id","")))
	var music_feedback: Dictionary = {}
	var raw_music_feedback: Variant = payload.get("music_feedback",{})
	if raw_music_feedback is Dictionary: music_feedback = raw_music_feedback.duplicate(true)
	if music_feedback.is_empty() and payload.has("id") and world.has_method("transit_music_feedback"):
		music_feedback = world.transit_music_feedback(str(payload.get("id",""))).duplicate(true)
	var role := "社区往返线"
	var route_mode := str(payload.get("route_mode",""))
	if not transfer_stop_ids.is_empty(): role = "换乘走廊"
	elif community_ids.size() > 1: role = "跨社区接驳"
	elif route_mode == "loop": role = "社区环线"

	var length := float(payload.get("length",0.0))
	if length <= 0.0:
		for leg in payload.get("legs",[]): length += float(leg.get("length",0.0))
	var communities: Array[Dictionary] = []
	var all_music_roles: Array[String] = []
	for cid in community_ids:
		var total := int(total_by_community.get(cid,0))
		var covered := int(covered_by_community.get(cid,0))
		var roles: Array[String] = []
		if world.has_method("functional_zone_roles"):
			roles.assign(world.functional_zone_roles(cid))
		roles.sort()
		for music_role in roles:
			if not all_music_roles.has(music_role): all_music_roles.append(music_role)
		var line_membership: Array[String] = []
		for line in world.transit_lines:
			if line.get("community_ids",[]).has(cid) or line.get("line_community_ids",[]).has(cid):
				var line_id := str(line.get("id",""))
				if not line_id.is_empty() and not line_membership.has(line_id): line_membership.append(line_id)
		var demand := 0.0
		for stop in stop_records:
			if not stop.get("community_ids",[]).has(cid): continue
			var stop_id := str(stop.get("id",""))
			demand = maxf(demand,float(world.transit_demand.get(stop_id,{}).get("score",0.0)))
		var hint := ""
		if total <= 0: hint = "社区中心进入步行范围，后续成长可接入"
		elif covered >= total: hint = "现有房屋全部接入"
		elif covered > 0: hint = "仍有%d栋房屋在站点步行范围外" % (total-covered)
		else: hint = "当前房屋尚未接入站点步行范围"
		communities.append({"id":cid,"name":str(world.communities.get(cid,{}).get("name",cid)),
			"covered_building_count":covered,"existing_building_count":total,
			"coverage_ratio":float(covered)/float(total) if total > 0 else 0.0,
			"future_catchment":total == 0,"roles":roles,"line_ids":line_membership,
			"demand":demand,"hint":hint})
	all_music_roles.sort()
	var role_titles: Array[String] = []
	for music_role in all_music_roles:
		role_titles.append(str(MUSIC_ROLE_TITLES.get(music_role,music_role)))
	return {"covered_building_ids":covered_ids,"community_ids":community_ids,
		"covered_building_count":covered_ids.size(),"community_count":community_ids.size(),
		"stop_count":stop_records.size(),"stop_ids":stop_records.map(func(stop: Dictionary) -> String: return str(stop.get("id",""))),
		"leg_count":payload.get("legs",[]).size(),"route_length":length,"route_mode":route_mode,
		"line_ids":line_ids,"transfer_stop_ids":transfer_stop_ids,"route_role":role,
		"music_roles":all_music_roles,"music_role_titles":role_titles,"communities":communities,
		"music_feedback":music_feedback}

static func coverage_text(summary: Dictionary, heading := "线路覆盖") -> String:
	var lines: Array[String] = ["%s · %d站 · %s · 覆盖%d栋、%d个社区" % [heading,
		int(summary.get("stop_count",0)),str(summary.get("route_role","社区往返线")),
		int(summary.get("covered_building_count",0)),int(summary.get("community_count",0))]]
	var role_titles: Array = summary.get("music_role_titles",[])
	if not role_titles.is_empty(): lines.append("当前社区角色 · "+"、".join(role_titles))
	for community in summary.get("communities",[]):
		var covered := int(community.get("covered_building_count",0))
		var total := int(community.get("existing_building_count",0))
		lines.append("　%s · %d/%d栋 · %s" % [str(community.get("name",community.get("id",""))),covered,total,str(community.get("hint",""))])
	var music_feedback: Dictionary = summary.get("music_feedback",{})
	if not music_feedback.is_empty():
		lines.append("音乐条件 · "+str(music_feedback.get("message","等待客流条件")))
	if not summary.get("transfer_stop_ids",[]).is_empty(): lines.append("换乘站 · %d处 · 后续可与其他线路接续" % summary["transfer_stop_ids"].size())
	return "\n".join(lines)

static func stop_record(world: RefCounted, id: String) -> Dictionary:
	var result: Dictionary = {}
	if world.authored_transit_stops.has(id): result = world.authored_transit_stops[id].duplicate(true)
	elif world.nodes.has(id): result = stop_preview(world,point(world.nodes[id]))
	if result.is_empty(): return {}
	result.merge(_coverage(world,[result]),true)
	result["vehicle_kind"] = world.vehicle_kind()
	result["era"] = int(world.era)
	var line_ids: Array[String] = []
	for line in world.transit_lines:
		if line.get("stops",[]).has(id): line_ids.append(str(line["id"]))
	result["line_ids"] = line_ids
	return result

static func _directional_edges(world: RefCounted, path: PackedVector2Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(path.size()-1):
		var a := path[index]
		var b := path[index+1]
		if a.distance_to(b) < 0.00001: continue
		var access: Dictionary = world.network.access((a+b)*0.5)
		var road: Dictionary = world.network.road_by_id(str(access["road"]))
		var road_path: PackedVector2Array = road["path"]
		var along := 0.0
		var from_along := 0.0
		var to_along := 0.0
		for part in range(road_path.size()-1):
			var length := road_path[part].distance_to(road_path[part+1])
			var closest := Geometry2D.get_closest_point_to_segment((a+b)*0.5,road_path[part],road_path[part+1])
			if closest.distance_to((a+b)*0.5) < 0.00001:
				from_along = along+road_path[part].distance_to(a)
				to_along = along+road_path[part].distance_to(b)
				break
			along += length
		var forward := to_along > from_along
		if not result.is_empty() and result[-1]["road"] == access["road"] and bool(result[-1]["forward"]) == forward:
			result[-1]["to_along"] = to_along
		else:
			result.append({"road":access["road"],"forward":forward,"from_along":from_along,"to_along":to_along})
	return result

static func preview(world: RefCounted, positions: Array) -> Dictionary:
	var stops: Array[Dictionary] = []
	for raw in positions:
		if not raw is Vector2 and not (raw is Array and raw.size() == 2):
			return {"accepted":false,"reason":"站位需要连续世界坐标","stops":stops}
		var stop := stop_preview(world,point(raw))
		if not bool(stop.get("accepted",false)): return stop
		for previous in stops:
			if point(previous["position"]).distance_to(point(stop["position"])) <= STOP_MERGE_DISTANCE:
				stop = previous.duplicate(true)
				break
		if not stops.is_empty() and stops[-1]["id"] == stop["id"]:
			return {"accepted":false,"reason":"连续两站不能是同一站","stops":stops}
		stops.append(stop)
	if stops.size() < 2: return {"accepted":false,"reason":"至少选择两处不同站位","stops":stops,"source_topology":world.network.topology}
	var closed := str(stops[0]["id"]) == str(stops[-1]["id"])
	if closed and stops.size() < 4:
		return {"accepted":false,"reason":"闭环至少需要三个不同站位","stops":stops}
	var itinerary: Array[Dictionary] = stops.duplicate(true)
	if not closed:
		for index in range(stops.size()-2,-1,-1): itinerary.append(stops[index])
	var legs: Array[Dictionary] = []
	var path := PackedVector2Array()
	var edges: Array[String] = []
	var directional_edges: Array[Dictionary] = []
	var length := 0.0
	for index in range(itinerary.size()-1):
		var from: Dictionary = itinerary[index]
		var to: Dictionary = itinerary[index+1]
		var route: Dictionary = world.network.walking_route(point(from["position"]),point(to["position"]))
		if not is_finite(float(route["distance"])):
			return {"accepted":false,"reason":"这些站点没有真实道路相连；跨河需要先建桥","stops":stops,"source_topology":world.network.topology}
		var part: PackedVector2Array = route["path"]
		var directed := _directional_edges(world,part)
		var leg_edges: Array[String] = []
		for edge in directed: leg_edges.append(str(edge["road"]))
		legs.append({"from":from["id"],"to":to["id"],"path":part,"length":float(route["distance"]),"edges":leg_edges,"directional_edges":directed})
		for p in part:
			if path.is_empty() or path[-1].distance_to(p) > 0.00001: path.append(p)
		edges.append_array(leg_edges)
		directional_edges.append_array(directed)
		length += float(route["distance"])
	var stop_ids: Array[String] = []
	for stop in itinerary.slice(0,-1): stop_ids.append(str(stop["id"]))
	var result := {"accepted":true,"stops":stops,"stop_ids":stop_ids,"legs":legs,"path":path,"edges":edges,"directional_edges":directional_edges,
		"length":length,"route_mode":"loop" if closed else "out_and_back","source_topology":world.network.topology}
	result.merge(_coverage(world,stops),true)
	var stop_positions: Array = []
	for stop in stops: stop_positions.append(stop["position"].duplicate())
	result["stop_positions"] = stop_positions
	result["coverage"] = coverage_summary(world,result)
	result["route_role"] = result["coverage"].get("route_role","社区往返线")
	return result

static func commit(world: RefCounted, operation: Dictionary, frame: int) -> Dictionary:
	if str(operation.get("source_topology","")) != str(world.network.topology):
		return {"accepted":false,"reason":"道路在乐句边界前已经变化，请重新规划线路"}
	var plan := preview(world,operation.get("stop_positions",[]))
	if not bool(plan.get("accepted",false)): return plan
	var id := "player-line-%d" % int(operation["event_id"])
	var chosen_ids: Array[String] = []
	for stop in plan["stops"]:
		var stop_id := str(stop["id"])
		if not world.nodes.has(stop_id): world.authored_transit_stops[stop_id] = stop.duplicate(true)
		chosen_ids.append(stop_id)
	world.authored_transit_lines.append({"id":id,"name":"自定线路 %d" % (world.authored_transit_lines.size()+1),"stop_ids":chosen_ids,
		"route_mode":plan["route_mode"],"frame":frame,"event_id":operation["event_id"],"source_topology":plan["source_topology"]})
	world.events.append({"kind":"transit_line","id":id,"event_id":operation["event_id"],"frame":frame,"stop_ids":chosen_ids,
		"community_ids":plan["community_ids"].duplicate(),"covered_building_ids":plan["covered_building_ids"].duplicate(),"route_mode":plan["route_mode"],
		"source_topology":plan["source_topology"]})
	world.events.back()["coverage"] = plan.get("coverage",coverage_summary(world,plan)).duplicate(true)
	world.events.back()["route_role"] = str(plan.get("route_role","社区往返线"))
	return {"accepted":true,"id":id}

static func derived_lines(world: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for intent in world.authored_transit_lines:
		var positions: Array = []
		for id in intent["stop_ids"]:
			if world.nodes.has(str(id)): positions.append(world.nodes[str(id)])
			elif world.authored_transit_stops.has(str(id)): positions.append(world.authored_transit_stops[str(id)]["position"])
		# A repeated first station is the player's explicit loop marker. Keep it
		# in the intent and feed it back to the preview so reloads preserve a loop
		# instead of silently changing it into an out-and-back service.
		if str(intent.get("route_mode","")) == "loop" and not positions.is_empty() and positions[0] != positions[-1]:
			positions.append(positions[0])
		var plan := preview(world,positions)
		if not bool(plan.get("accepted",false)): continue
		var coverage: Dictionary = plan.get("coverage",coverage_summary(world,plan))
		result.append({"id":intent["id"],"name":intent["name"],"authored":true,"frame":intent["frame"],"stops":plan["stop_ids"],
			"intent_stop_ids":intent["stop_ids"].duplicate(),"route_stops":plan["stop_ids"].duplicate(),"route_mode":plan["route_mode"],"legs":plan["legs"],"path":plan["path"],"edges":plan["edges"],
			"directional_edges":plan["directional_edges"],"community_ids":plan["community_ids"],"covered_building_ids":plan["covered_building_ids"],
			"coverage":coverage,"route_role":coverage.get("route_role","社区往返线")})
	return result
