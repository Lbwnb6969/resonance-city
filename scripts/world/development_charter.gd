extends RefCounted
## Planning preferences only: geometry, tier, acoustic and service rules stay authoritative.
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const PLANS = {
	"compact":{"title":"紧凑核心","tendency":"围绕社区中心填满街坊","tradeoff":"更少向外伸展的空间","opportunity":"连片街墙与混合中心"},
	"corridor":{"title":"走廊连接","tendency":"沿真实道路与站点延展","tradeoff":"社区会更细长，依赖道路","opportunity":"连接街区与交通脉冲"},
	"bluegreen":{"title":"蓝绿文化网络","tendency":"围绕公园与文化馆组织成长","tradeoff":"公共占地会挤占房屋空间","opportunity":"公园留白与文化主题"}
}
static func version(world: RefCounted) -> Array:
	return [world.phrase_index,world.action_serial,world.planning_revision]

static func in_scope(world: RefCounted,cid: String,scope: Array) -> bool:
	var visited: Array[String] = []
	while world.communities.has(cid) and not visited.has(cid):
		if scope.has(cid): return true
		visited.append(cid)
		cid = str(world.communities[cid].get("parent_id",""))
	return false

static func for_community(world: RefCounted,cid: String) -> Dictionary:
	# A newer local choice overrides an inherited choice; splits retain parent scope.
	var visited: Array[String] = []
	while world.communities.has(cid) and not visited.has(cid):
		for i in range(world.development_charters.size()-1,-1,-1):
			var charter: Dictionary = world.development_charters[i]
			if charter["community_ids"].has(cid): return charter
		visited.append(cid)
		cid = str(world.communities[cid].get("parent_id",""))
	return {}

static func reason(world: RefCounted,operation: Dictionary) -> String:
	if not PLANS.has(str(operation.get("plan_id",""))): return "请选择一种发展章程"
	var scope: Array = operation.get("community_ids",[])
	if scope.is_empty(): return "先在地图上选一个或多个社区"
	for cid in scope:
		if not world.communities.has(str(cid)): return "选中的社区已不存在，请重新选择"
	var raw_cards: Variant = operation.get("card_refs",[])
	if raw_cards is Array:
		for raw_card in raw_cards:
			if not PlanningCard.valid(str(raw_card)): return "变化卡已失效，请重新选择"
	else:
		return "变化卡选择无效，请重新选择"
	return ""

static func commit(world: RefCounted,operation: Dictionary,frame: int) -> bool:
	if not reason(world,operation).is_empty(): return false
	var scope: Array = operation["community_ids"].duplicate()
	scope.sort()
	var card_refs := PlanningCard.normalize_refs(operation.get("card_refs",[]))
	var id := "charter-%05d" % int(operation["event_id"])
	var charter := {"charter_id":id,"community_ids":scope,"plan_id":str(operation["plan_id"]),
		"source_operation":int(operation["event_id"]),"committed_phrase":world.phrase_index,
		"world_version":version(world),"card_refs":card_refs}
	world.development_charters.append(charter)
	world.events.append({"kind":"charter","id":id,"plan_id":charter["plan_id"],"community_ids":scope.duplicate(),"card_refs":card_refs.duplicate(),"frame":frame})
	return true

static func mark_anchor(world: RefCounted,site: Dictionary,reservation_id: String = "") -> void:
	site["anchor_id"] = str(site["id"])
	site["created_phrase"] = world.phrase_index
	site["source_reservation_id"] = reservation_id
	site["influence_config"] = {"relation":"支持" if site["kind"] == "civic" else "吸引",
		"planning_radius":6.0 if site["kind"] == "civic" else 5.0}

static func influence_edges(world: RefCounted,cid: String,p: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for site in world.near_public_sites(p,6.0):
		if not bool(site.get("active",false)): continue
		var center := Vector2(float(site["position"][0]),float(site["position"][1]))
		var radius := float(site.get("influence_config",{}).get("planning_radius",6.0 if site["kind"] == "civic" else 5.0))
		var distance := center.distance_to(p)
		if distance > radius: continue
		var entrance := Vector2(float(site["entrance"][0]),float(site["entrance"][1]))
		var reachable: bool = world.network.walking_distance(entrance,p) <= float(world.cfg["city"]["service_walk_radius"])
		var capacity := int(site.get("service_capacity",18))
		var used: int = site.get("served",[]).size()
		var pressure := float(used)/float(maxi(1,capacity)) if site["kind"] == "civic" else 0.0
		result.append({"anchor_id":str(site.get("anchor_id",site["id"])),"target_community":cid,
			"target_position":[p.x,p.y],"relation":"支持" if site["kind"] == "civic" else "吸引",
			"spatial_strength":1.0-distance/radius,"road_reachable":reachable,"capacity_pressure":pressure,
			"planning_version":version(world)})
	return result

static func growth_bonus(world: RefCounted,cid: String,p: Vector2,compact_neighbors: int) -> float:
	var charter := for_community(world,cid)
	if charter.is_empty(): return 0.0
	var card_bonus := PlanningCard.priority_bonus(world,charter,cid,p,compact_neighbors)
	match str(charter["plan_id"]):
		"compact":
			var center_strength := 0.0
			for center in world.centers:
				if not bool(center.get("active",true)) or not in_scope(world,str(center["community_id"]),charter["community_ids"]): continue
				var q := Vector2(float(center["position"][0]),float(center["position"][1]))
				center_strength = maxf(center_strength,maxf(0.0,1.0-p.distance_to(q)/8.0))
			return 20000.0*(float(mini(compact_neighbors,4))/4.0*0.65+center_strength*0.35)+card_bonus
		"corridor":
			var strength := 0.0
			for segment in world.near_road_segments(p,2.0):
				var q := Geometry2D.get_closest_point_to_segment(p,segment["a"],segment["b"])
				strength = maxf(strength,maxf(0.0,1.0-p.distance_to(q)/2.0))
			return 20000.0*strength+5000.0*minf(1.0,world._transit_growth_bonus(p))+card_bonus
		"bluegreen":
			# Merge by relation using maximum influence, rather than stacking facilities.
			var relations: Dictionary = {}
			for edge in influence_edges(world,cid,p):
				if not bool(edge["road_reachable"]) or float(edge["capacity_pressure"]) >= 1.0: continue
				var label := str(edge["relation"])
				relations[label] = maxf(float(relations.get(label,0.0)),float(edge["spatial_strength"]))
			return 25000.0*maxf(float(relations.get("吸引",0.0)),float(relations.get("支持",0.0)))+card_bonus
	return 0.0

static func growth_delay(world: RefCounted,cid: String,p: Vector2,base_delay: int,tier: String) -> int:
	var charter := for_community(world,cid)
	if charter.is_empty(): return base_delay
	return PlanningCard.growth_delay(world,charter,p,base_delay,tier)

static func scope_preview(world: RefCounted,scope: Array) -> Dictionary:
	var legal := 0
	var houses := 0
	for building in world.buildings:
		if in_scope(world,str(building["community_id"]),scope): houses += 1
	for lot in world.lots:
		if not str(lot["occupant"]).is_empty() or not in_scope(world,str(lot["community_id"]),scope): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if bool(world.placement(p)["allowed"]): legal += 1
	return {"houses":houses,"legal_lots":legal,"world_version":version(world)}

static func anchor_preview(world: RefCounted,candidate: Dictionary,kind: String,access: Dictionary) -> Dictionary:
	var result := {"reachable":0,"covered":[],"capacity":18 if kind == "civic" else 0,"access":not access.is_empty(),
		"community_id":str(candidate.get("community_id","")),"world_version":version(world)}
	if access.is_empty(): return result
	var entrance := Vector2(float(access["entrance"][0]),float(access["entrance"][1]))
	var lots_by_id: Dictionary = {}
	for lot in world.lots: lots_by_id[str(lot["id"])] = lot
	for building in world.buildings:
		var destination := Vector2(float(building["position"][0]),float(building["position"][1]))
		var lot: Dictionary = lots_by_id.get(str(building.get("lot_id","")),{})
		if lot.has("entrance"): destination = Vector2(float(lot["entrance"][0]),float(lot["entrance"][1]))
		var radius := float(world.cfg["city"]["service_walk_radius"])
		if entrance.distance_to(destination) <= radius and world.network.walking_distance(entrance,destination) <= radius:
			result["reachable"] += 1
			result["covered"].append(str(building["district_id"]))
	return result
