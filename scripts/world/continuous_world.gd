class_name ContinuousWorld
extends RefCounted
const Config = preload("res://scripts/world/world_values.gd")
const Terrain = preload("res://scripts/world/valley_terrain.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Index = preload("res://scripts/world/world_spatial_index.gd")
const RandomStreams = preload("res://scripts/city/named_random.gd")
const Legacy = preload("res://scripts/spec_values.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const Terrace = preload("res://scripts/world/terrace_neighborhood.gd")
var cfg: Dictionary = Config.load_values()
var terrain := Terrain.new()
var coupling := Coupling.new()
var index := Index.new()
var rng: NamedRandom
var buildings: Array[Dictionary] = []
var by_id: Dictionary = {}
var lots: Array[Dictionary] = []
var roads: Array[Dictionary] = []
var nodes: Dictionary = {}
var communities: Dictionary = {}
var families: Dictionary = {}
var edge_cache: Dictionary = {}
var pending: Dictionary = {}
var pending_actions: Array[Dictionary] = []
var blocks: Array[Dictionary] = []
var green_corridors: Array[Dictionary] = []
var centers: Array[Dictionary] = []
var public_sites: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var landmark_progress: Dictionary = {}
var network: CityRoadNetwork
var transit: Dictionary = {}
var transit_lines: Array[Dictionary] = []
var environment_cache: Dictionary = {}
var mode := "free"
var profile := "bright"
var action_serial := 0
var events: Array[Dictionary] = []
var bridge := false
var phrase_index := 0
# Transport is a visible part of the city history. The first playable era is classical.
var era := 1
var next_id := 1
var resonance := 100.0
var lifecycle := {"gray":false,"low_phrases":0,"ended":false}
# Derived visual relationships; never part of acoustic state.
var fabric_cache: Dictionary = {"shared_walls":[],"rows":[],"courtyards":[],"community_wall":{}}
var expanded_plan := false
var last_reason := "在河边选择一块临街空地，播下第一段声音"

func _init(seed_hex: String = "2026100900000062", generate_plan: bool = true, terrain_family: String = "river_valley") -> void:
	rng = RandomStreams.new(seed_hex)
	terrain.configure(rng.bounded("terrain",2147483647),float(rng.next_u32("terrain"))/4294967296.0*TAU,terrain_family)
	if generate_plan:
		_plan()
		NeighborhoodPlan.populate(self)
		_refresh_centers()
	network = CityRoadNetwork.new()
	_refresh_public_network()
	refresh_fabric()

func _plan() -> void:
	var t: Dictionary = cfg["terrain"]
	var bridge_y := float(t["template_bridge_y"])
	var ys := [-1.2,8.0,bridge_y,20.0,30.2]
	for bank: int in [-1,1]:
		var prefix := "west" if bank < 0 else "east"
		for region in range(3):
			var cid := "%s-%d" % [prefix,region+1]
			communities[cid] = {"id":cid,"bank":bank,"name":("西岸" if bank < 0 else "东岸")+str(region+1),"members":[],"parent_id":""}
		for i in range(ys.size()):
			var y := float(ys[i])
			var p := Vector2(terrain.river_x(y)+bank*float(t["template_road_bank_offset"]),y)
			nodes["%s-%d" % [prefix,i]] = [p.x,p.y]
			if i == 0: continue
			var path := PackedVector2Array()
			for sample in range(13):
				var sy := lerpf(float(ys[i-1]),y,float(sample)/12.0)
				path.append(Vector2(terrain.river_x(sy)+bank*float(t["template_road_bank_offset"]),sy))
			roads.append({"id":"%s-road-%d" % [prefix,i],"from":"%s-%d" % [prefix,i-1],"to":"%s-%d" % [prefix,i],"path":path,"bridge":false})
		var plot_ys: Array[float] = []
		var y := 0.4
		while y <= 29.0:
			if absf(y-bridge_y) >= 1.4: plot_ys.append(y)
			y += float(t["template_lot_spacing"])
		plot_ys.append(bridge_y)
		plot_ys.sort()
		for i in range(plot_ys.size()):
			for side: int in [-1,1]:
				var py := plot_ys[i]
				var jitter := (float(rng.bounded("form",1000))/999.0-0.5)*0.13 if py != bridge_y else 0.0
				var road_x := terrain.river_x(py)+bank*float(t["template_road_bank_offset"])
				var center := Vector2(road_x+side*float(t["template_lot_road_offset"]),py+jitter)
				var region := mini(2,maxi(0,floori(py/10.0)))
				var half := Vector2(float(t["template_lot_half_width"]),float(t["template_lot_half_length"]))
				var polygon := PackedVector2Array([center-half,center+Vector2(half.x,-half.y),center+half,center+Vector2(-half.x,half.y)])
				if not terrain.valid_footprint(polygon): continue
				var entrance := Vector2(road_x,center.y)
				lots.append({"id":"%s-lot-%d-%d" % [prefix,i,side],"center":[center.x,center.y],"polygon":polygon,
					"entrance":[entrance.x,entrance.y],"use":"commercial" if absf(py-bridge_y) < 4.1 and side == bank else "residential","community_id":"%s-%d" % [prefix,region+1],"bank":bank,"occupant":""})

func _refresh_centers() -> void:
	centers.clear()
	for bank: int in [-1,1]:
		var prefix := "west" if bank < 0 else "east"
		if nodes.has(prefix+"-2") and communities.has(prefix+"-2"):
			var main: Array = nodes[prefix+"-2"]
			centers.append({"id":prefix+"-primary-center","level":"primary","community_id":prefix+"-2","node_id":prefix+"-2","position":[main[0],main[1]],"active":true})
		if nodes.has(prefix+"-garden-2") and communities.has(prefix+"-garden-1"):
			var garden: Array = nodes[prefix+"-garden-2"]
			centers.append({"id":prefix+"-secondary-center","level":"secondary","community_id":prefix+"-garden-1","node_id":prefix+"-garden-2","position":[garden[0],garden[1]],"active":true})
		var index := 1
		while true:
			var terrace_id := "%s-terrace-%d" % [prefix,index]
			var node_id := "%s-terrace-node-%d" % [prefix,index]
			if not nodes.has(node_id) or not communities.has(terrace_id): break
			var terrace: Array = nodes[node_id]
			centers.append({"id":"%s-center" % terrace_id,"level":"terrace","community_id":terrace_id,"node_id":node_id,"position":[terrace[0],terrace[1]],"active":expanded_plan})
			index += 1
		var inner_index := 1
		while true:
			var inner_id := "%s-inner-%d" % [prefix,inner_index]
			var inner_node_id := "%s-inner-node-%d" % [prefix,inner_index]
			if not nodes.has(inner_node_id) or not communities.has(inner_id): break
			var inner: Array = nodes[inner_node_id]
			centers.append({"id":"%s-center" % inner_id,"level":"local","community_id":inner_id,"node_id":inner_node_id,"position":[inner[0],inner[1]],"active":expanded_plan})
			inner_index += 1
	for center in centers:
		var cid := str(center["community_id"])
		if communities.has(cid):
			communities[cid]["center_id"] = center["id"]
			communities[cid]["center_level"] = center["level"]

func center_rank(cid: String) -> int:
	for center in centers:
		if str(center["community_id"]) != cid: continue
		return {"primary":0,"secondary":1,"terrace":2}.get(str(center["level"]),3)
	return 3

func center_for(cid: String) -> Dictionary:
	for center in centers:
		if str(center["community_id"]) == cid: return center
	return {}

func center_order(cid: String) -> int:
	for index in range(centers.size()):
		if str(centers[index]["community_id"]) == cid: return index
	return 999

func road_environment(a: Vector2,b: Vector2) -> Dictionary:
	var key := Vector4(a.x,a.y,b.x,b.y)
	if environment_cache.has(key): return environment_cache[key]
	var result := _road_environment(a,b)
	environment_cache[key] = result
	return result

func _road_environment(a: Vector2,b: Vector2) -> Dictionary:
	var result := terrain.environment(a,b,bridge)
	if float(result["occlusion"]) == 0.0: return result
	for road in roads:
		if road["bridge"]: continue
		var path: PackedVector2Array = road["path"]
		for i in range(path.size()-1):
			if Geometry2D.segment_intersects_segment(a,b,path[i],path[i+1]) != null:
				result["occlusion"] = 0.0
				return result
	return result

func edges() -> Array:
	return edge_cache.values()

func _cache_entity(id: String) -> void:
	var a: Dictionary = by_id[id]
	for other_id in index.query_circle(Coupling.position_of(a),float(a["radius"])+float(cfg["space"]["gap_cutoff"])):
		if other_id == id: continue
		var b: Dictionary = by_id[other_id]
		var pair := [id,other_id]
		pair.sort()
		var key := str(pair[0])+":"+str(pair[1])
		var weight := coupling.coefficient(a,b,road_environment(Coupling.position_of(a),Coupling.position_of(b)))
		if weight > 0.0: edge_cache[key] = {"a":pair[0],"b":pair[1],"coupling":weight}
		else: edge_cache.erase(key)

func rebuild_graph() -> void:
	environment_cache.clear()
	edge_cache.clear()
	for building in buildings: _cache_entity(building["district_id"])

func refresh_fabric() -> void:
	fabric_cache = Fabric.rebuild(self)

func musicality() -> Dictionary:
	var result: Dictionary = {}
	for id in by_id:
		var total := 0.0
		var same := 0.0
		for edge in near_edges(id):
			var other: String = edge["b"] if edge["a"] == id else edge["a"]
			total += float(edge["coupling"])
			if int(by_id[id]["current_midi"]) == int(by_id[other]["current_midi"]): same += float(edge["coupling"])
		var occupancy := same/total if total > 0.0 else 0.0
		var homogeneous := occupancy > float(cfg["space"]["homogeneity_threshold"])
		result[id] = {"occupancy":occupancy,"M":float(cfg["space"]["homogeneity_M"]) if homogeneous else 1.0,
			"dv_scale":float(cfg["space"]["homogeneity_dv_scale"]) if homogeneous else 1.0}
	return result

func musical_edges(modifiers: Dictionary) -> Array:
	var result: Array = []
	for edge in edges():
		var copy: Dictionary = edge.duplicate()
		copy["coupling"] = float(edge["coupling"])*minf(float(modifiers[edge["a"]]["M"]),float(modifiers[edge["b"]]["M"]))
		result.append(copy)
	return result

func building_polygon(p: Vector2) -> PackedVector2Array:
	var half := float(cfg["space"]["residential_radius"])/sqrt(2.0)
	return PackedVector2Array([p+Vector2(-half,-half),p+Vector2(half,-half),p+Vector2(half,half),p+Vector2(-half,half)])

func placement(p: Vector2) -> Dictionary:
	var polygon := building_polygon(p)
	if not terrain.valid_footprint(polygon): return {"allowed":false,"reason":"这里是水域或岸线，房子需要完整的陆地占地"}
	var radius := float(cfg["space"]["residential_radius"])
	if Fabric.on_road(self,p,radius): return {"allowed":false,"reason":"这里是成路，留出道路的连续通行面"}
	if Fabric.reserved(self,p): return {"allowed":false,"reason":"这里是公园或公共设施保留地"}
	for site in public_sites:
		if not Geometry2D.intersect_polygons(polygon,site["polygon"]).is_empty(): return {"allowed":false,"reason":"建筑占地不能压进公共保留地"}
	for id in index.query_circle(p,radius):
		if p.distance_to(Coupling.position_of(by_id[id])) < radius+float(by_id[id]["radius"])-1e-6:
			return {"allowed":false,"reason":"与已有建筑太近，留一点呼吸的空隙"}
	for lot in lots:
		if not str(lot["occupant"]).is_empty(): continue
		var contained := true
		for corner in polygon:
			if not Geometry2D.is_point_in_polygon(corner,lot["polygon"]): contained = false
		if contained:
			var tier := Fabric.tier_for(self,p,str(lot["id"]),str(lot["community_id"]))
			tier["allowed"] = true
			tier["reason"] = str(tier["preview"])+"；下一乐句落定"
			return tier
	var courtyard := Fabric.courtyard_at(self,p)
	if not courtyard.is_empty():
		var courtyard_tier := {"allowed":true,"tier":"L2","frontage":0,"lot_id":"courtyard:"+str(courtyard["id"]),
			"courtyard_id":str(courtyard["id"]),"community_id":str(courtyard.get("community_id",Fabric.community_for_position(self,p))),
			"preview":"庭院内地块 · 可成长","growth_delay":2,"max_form":"腔",
			"reason":"庭院内地块 · 下一乐句落定"}
		return courtyard_tier
	var tier := Fabric.tier_for(self,p)
	tier["allowed"] = true
	tier["lot_id"] = ""
	tier["reason"] = str(tier["preview"])+"；任意合法陆地都能播种"
	return tier


func landmark_specs() -> Array[Dictionary]:
	if era <= 1:
		return [
			{"name":"元老院","glyph":"政","radius":1.35,"condition":"全城R≥75 · 至少1个央"},
			{"name":"神殿","glyph":"和","radius":1.15,"condition":"存在腔 · 至少2条同音共鸣"},
			{"name":"圆形剧场","glyph":"节","radius":1.55,"condition":"两家族成群 · 距离≤6 · 城中有道路"}
		]
	if era == 2:
		return [
			{"name":"市政厅","glyph":"政","radius":1.35,"condition":"R≥75 · ≥2个央 · ≥2条道路"},
			{"name":"大教堂","glyph":"和","radius":1.45,"condition":"存在腔 · 全城R≥80"},
			{"name":"行会大厅","glyph":"商","radius":1.25,"condition":"商业≥12 · 至少1个商业群"}
		]
	return []

func _landmark_condition(name: String) -> bool:
	var core_count := 0
	var chamber_count := 0
	var commercial_count := 0
	var commercial_group := 0
	var group_positions: Array[Dictionary] = []
	for building in buildings:
		var form := str(building.get("form","胚"))
		if form == "央": core_count += 1
		if form == "腔": chamber_count += 1
		if str(building.get("type","")) == "commercial": commercial_count += 1
		if form in ["群","央","腔"] and str(building.get("type","")) == "commercial": commercial_group += 1
		if form in ["群","央","腔"]:
			group_positions.append({"family":str(building.get("family_id","")),"position":Coupling.position_of(building)})
	var road_count := roads.size()
	if name == "元老院": return resonance >= 75.0 and core_count >= 1
	if name == "神殿":
		if chamber_count < 1: return false
		var same_edges := 0
		for edge in musical_edges(musicality()):
			if float(edge.get("coupling",0.0)) >= 0.9: same_edges += 1
		return same_edges >= 2
	if name == "圆形剧场":
		for i in range(group_positions.size()):
			for j in range(i+1,group_positions.size()):
				if group_positions[i]["family"] == group_positions[j]["family"]: continue
				if Vector2(group_positions[i]["position"]).distance_to(Vector2(group_positions[j]["position"])) <= 6.0 and road_count > 0: return true
		return false
	if name == "市政厅": return resonance >= 75.0 and core_count >= 2 and road_count >= 2
	if name == "大教堂": return chamber_count >= 1 and resonance >= 80.0
	if name == "行会大厅": return commercial_count >= 12 and commercial_group >= 1
	return false

func landmark_candidates() -> Array[Dictionary]:
	var has_group := buildings.any(func(building: Dictionary) -> bool: return str(building.get("form","胚")) in ["群","央","腔"])
	if not has_group and landmarks.is_empty(): return []
	var result: Array[Dictionary] = []
	for spec in landmark_specs():
		var name := str(spec["name"])
		var record: Dictionary = landmark_progress.get(name,{})
		var candidate := spec.duplicate(true)
		candidate["ready"] = _landmark_condition(name)
		candidate["streak"] = int(record.get("streak",0))
		candidate["awakened"] = bool(record.get("awakened",false))
		candidate["required_streak"] = 2
		candidate["built"] = landmark_exists(name)
		result.append(candidate)
	return result

func landmark_status(name: String) -> Dictionary:
	for candidate in landmark_candidates():
		if str(candidate["name"]) == name: return candidate
	return {}

func landmark_exists(name: String) -> bool:
	return landmarks.any(func(item: Dictionary) -> bool: return str(item.get("name","")) == name)

func _advance_landmark_progress(frame: int) -> void:
	for spec in landmark_specs():
		var name := str(spec["name"])
		if landmark_exists(name): continue
		var record: Dictionary = landmark_progress.get(name,{"streak":0,"awakened":false,"last_phrase":-1}).duplicate(true)
		record["streak"] = int(record.get("streak",0))+1 if _landmark_condition(name) else 0
		record["last_phrase"] = phrase_index
		if int(record["streak"]) >= 2 and not bool(record.get("awakened",false)):
			record["awakened"] = true
			events.append({"kind":"landmark_awakened","name":name,"frame":frame,"phrase":phrase_index})
		landmark_progress[name] = record

func _landmark_distance_to_segment(p: Vector2,a: Vector2,b: Vector2) -> float:
	var delta := b-a
	var length_squared := delta.length_squared()
	if length_squared <= 0.0001: return p.distance_to(a)
	var t := clampf((p-a).dot(delta)/length_squared,0.0,1.0)
	return p.distance_to(a+delta*t)

func landmark_site_clear(position: Vector2,radius: float) -> bool:
	if not terrain.land_at(position): return false
	for site in public_sites:
		var site_position := Vector2(float(site["position"][0]),float(site["position"][1]))
		if position.distance_to(site_position) < radius+1.1: return false
	for road in roads:
		var path: PackedVector2Array = road["path"]
		for i in range(path.size()-1):
			if _landmark_distance_to_segment(position,path[i],path[i+1]) < radius+0.30: return false
	for landmark in landmarks:
		var other := Vector2(float(landmark["position"][0]),float(landmark["position"][1]))
		if position.distance_to(other) < radius+float(landmark.get("radius",1.0)): return false
	return true

func _remove_building_for_landmark(id: String,landmark_id: String) -> Dictionary:
	if not by_id.has(id): return {}
	var building: Dictionary = by_id[id].duplicate(true)
	by_id.erase(id)
	index.remove(id)
	for i in range(buildings.size()-1,-1,-1):
		if str(buildings[i]["district_id"]) == id: buildings.remove_at(i)
	var community_id := str(building.get("community_id",""))
	if communities.has(community_id):
		communities[community_id]["members"].erase(id)
	for lot in lots:
		if str(lot.get("occupant","")) == id:
			lot["occupant"] = landmark_id
			lot["landmark_id"] = landmark_id
	for family_id in families:
		if str(families[family_id].get("root","")) != id: continue
		var replacement := ""
		for other in buildings:
			if str(other.get("family_id","")) == family_id:
				replacement = str(other["district_id"])
				break
		families[family_id]["root"] = replacement
	return building

func _commit_landmark(operation: Dictionary,frame: int) -> void:
	var name := str(operation.get("name",""))
	if landmark_exists(name): return
	var position := Vector2(float(operation["position"][0]),float(operation["position"][1]))
	var radius := float(operation.get("radius",1.0))
	var landmark_id := "landmark-%02d" % (landmarks.size()+1)
	var spec := landmark_status(name)
	var landmark := {"id":landmark_id,"name":name,"glyph":str(spec.get("glyph","地")),"era":era,
		"position":[position.x,position.y],"radius":radius,"frame":frame,
		"reveal_frame":frame,"reveal_frames":maxi(1,int(cfg["timing"]["phrase_frames"])/8),
		"voice_level":0.34,"motif":[],"absorbed_buildings":[],"active":false}
	var candidates: Array[Dictionary] = []
	for building in buildings:
		var form := str(building.get("form","胚"))
		if form not in ["群","央","腔"]: continue
		var distance := position.distance_to(Coupling.position_of(building))
		if distance <= radius+float(building["radius"]): candidates.append({"id":str(building["district_id"]),"distance":distance})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if float(a["distance"]) != float(b["distance"]): return float(a["distance"]) < float(b["distance"])
		return str(a["id"]) < str(b["id"]))
	var capacity := 4 if name in ["元老院","圆形剧场"] else 3
	for candidate in candidates.slice(0,mini(capacity,candidates.size())):
		var absorbed := _remove_building_for_landmark(str(candidate["id"]),landmark_id)
		if absorbed.is_empty(): continue
		landmark["absorbed_buildings"].append(str(absorbed["district_id"]))
		landmark["motif"].append({"id":str(absorbed["district_id"]),"midi":int(absorbed["current_midi"])})
	landmarks.append(landmark)
	landmark_progress[name] = {"streak":2,"awakened":true,"last_phrase":phrase_index}
	rebuild_graph()
	refresh_fabric()
	events.append({"kind":"landmark","id":landmark_id,"name":name,"frame":frame,"absorbed":landmark["absorbed_buildings"].duplicate()})

func request(operation: Dictionary, frame: int) -> Dictionary:
	if lifecycle["ended"]: return {"accepted":false,"reason":"这一段已结束，按R重新播种"}
	var kind := str(operation.get("kind",""))
	if kind == "seed":
		var check := placement(Vector2(float(operation["position"][0]),float(operation["position"][1])))
		if not check["allowed"]: return {"accepted":false,"reason":check["reason"]}
		for op in pending_actions:
			if op["kind"] != "seed": continue
			if not str(check["lot_id"]).is_empty() and op.get("lot_id","") == check["lot_id"]:
				return {"accepted":false,"reason":"这块地已经播下声音，下一句会长出来"}
			if str(check["lot_id"]).is_empty() and Vector2(float(op["position"][0]),float(op["position"][1])).distance_to(Vector2(float(operation["position"][0]),float(operation["position"][1]))) < 0.9:
				return {"accepted":false,"reason":"附近已经播下声音，给孤屋留一点呼吸"}
		operation = operation.duplicate(true)
		operation["lot_id"] = check["lot_id"]
		operation["placement_tier"] = check["tier"]
	elif kind == "retune":
		if not by_id.has(operation.get("id","")): return {"accepted":false,"reason":"请选择一栋建筑"}
	elif kind == "bridge":
		if bridge or pending_actions.any(func(op: Dictionary) -> bool: return op["kind"] == "bridge"): return {"accepted":false,"reason":"桥已经连接或正在等待落定"}
	elif kind == "landmark":
		var name := str(operation.get("name",""))
		var status := landmark_status(name)
		if status.is_empty() or bool(status.get("built",false)): return {"accepted":false,"reason":"这座地标当前不可用"}
		if not bool(status.get("awakened",false)): return {"accepted":false,"reason":"地标还需要连续两句满足条件"}
		if pending_actions.any(func(op: Dictionary) -> bool: return op["kind"] == "landmark"): return {"accepted":false,"reason":"已有一座地标等待下一句落成"}
		var site_position := Vector2(float(operation["position"][0]),float(operation["position"][1]))
		var site_radius := float(operation.get("radius",status.get("radius",1.0)))
		if not landmark_site_clear(site_position,site_radius): return {"accepted":false,"reason":"预影位置已被道路、公共空间或另一座地标占用"}
		operation = operation.duplicate(true)
		operation["radius"] = site_radius
		operation["era"] = era
	elif kind in ["park","civic"]:
		var found := false
		for site in public_sites:
			if site["id"] == operation.get("id","") and site["kind"] == kind and not site["active"]: found = true
		if not found: return {"accepted":false,"reason":"请在公共保留地营造公园或设施"}
	else: return {"accepted":false,"reason":"未知操作"}
	if kind in ["seed","retune"]:
		var midi := int(operation["midi"])
		var allowed: Array = Legacy.load_values()["proposals"]["allowed_pitches"]
		if not allowed.any(func(pitch: float) -> bool: return int(pitch) == midi or int(pitch) == midi+12): return {"accepted":false,"reason":"请选择当前时代的五声音阶"}
	# Repeated retuning replaces this building's future structural intent only.
	pending_actions = pending_actions.filter(func(op: Dictionary) -> bool:
		return not (op["kind"] == kind and kind != "seed" and op.get("id","") == operation.get("id","")))
	action_serial += 1
	pending = operation.duplicate(true)
	pending["frame"] = frame
	pending["event_id"] = action_serial
	pending_actions.append(pending.duplicate(true))
	return {"accepted":true,"frame":frame,"event_id":action_serial}

func _birth(p: Vector2, midi: int, family: String, root: bool, frame: int) -> String:
	var check := placement(p)
	assert(check["allowed"])
	var id := "building-%05d" % next_id
	next_id += 1
	var type := "residential"
	for lot in lots:
		if lot["id"] == check["lot_id"]: type = str(lot["use"])
	var building := {"district_id":id,"position":[p.x,p.y],"footprint":[[p.x,p.y]],"radius":cfg["space"]["residential_radius"],
		"current_midi":midi,"base_midi":midi,"type":type,"vitality":cfg["harmony"]["initial_vitality"],
		"community_id":check["community_id"],"lot_id":check["lot_id"],"placement_tier":str(check.get("tier","L1")),
		"fabric_frontage":int(check.get("frontage",0)),"family_id":family,"anchor_id":family,
		"expression":str(families.get(family,{}).get("expression",profile)),"family_anchor":root,"is_anchor":false,"era":1,"form":"胚","form_count":0,"birth_frame":frame,"voice_level":0.2}
	buildings.append(building)
	by_id[id] = building
	for lot in lots:
		if lot["id"] == check["lot_id"]: lot["occupant"] = id
	communities[check["community_id"]]["members"].append(id)
	index.put(id,p,float(building["radius"]))
	_cache_entity(id)
	events.append({"kind":"birth","district_id":id,"frame":frame})
	return id

func settle(frame: int) -> void:
	phrase_index += 1
	update_era(frame)
	var costs: Dictionary = {}
	var buildings_before_growth := buildings.size()
	# Compatibility with preserved direct world probes that assign one pending operation.
	if pending_actions.is_empty() and not pending.is_empty(): pending_actions.append(pending.duplicate(true))
	var committed := pending_actions.duplicate(true)
	pending_actions.clear()
	pending.clear()
	for op in committed:
		assert(int(op["frame"]) == frame)
		match str(op["kind"]):
			"seed":
				var p := Vector2(float(op["position"][0]),float(op["position"][1]))
				if not placement(p)["allowed"]: continue
				var family := "family-%05d" % next_id
				families[family] = {"root":"","created_phrase":phrase_index,"expression":op.get("expression",profile)}
				var root := _birth(p,int(op["midi"]),family,true,frame)
				families[family]["root"] = root
				var root_tier := str(by_id[root].get("placement_tier","L1"))
				families[family]["next_growth_phrase"] = phrase_index+(2 if root_tier != "L1" else 1)
			"retune":
				by_id[op["id"]]["current_midi"] = int(op["midi"])
				costs[op["id"]] = float(Legacy.load_values()["proposals"]["retune_cost"])
				events.append({"kind":"retune","district_id":op["id"],"frame":frame})
			"bridge":
				bridge = true
				var a: Array = nodes["west-2"]
				var b: Array = nodes["east-2"]
				roads.append({"id":"river-bridge","from":"west-2","to":"east-2","path":PackedVector2Array([Vector2(a[0],a[1]),Vector2(b[0],b[1])]),"bridge":true})
				rebuild_graph()
				events.append({"kind":"bridge","frame":frame})
			"landmark":
				_commit_landmark(op,frame)
			"park","civic":
				for site in public_sites:
					if site["id"] != op["id"]: continue
					site["active"] = true
					site["frame"] = frame
					events.append({"kind":op["kind"],"id":site["id"],"frame":frame})
	if not lifecycle["ended"]:
		for family in families:
			if int(families[family]["created_phrase"]) == phrase_index: continue
			_grow(family,frame)
	var forms_dirty := not committed.is_empty() or buildings.size() != buildings_before_growth
	var modifiers := musicality()
	var effective := musical_edges(modifiers)
	resonance = coupling.resonance(buildings,effective)
	var vitalities := coupling.vitality(buildings,effective,resonance,costs,modifiers)
	for building in buildings: building["vitality"] = vitalities[building["district_id"]]
	if forms_dirty: _update_forms(frame)
	_advance_landmark_progress(frame)
	if resonance < float(cfg["harmony"]["gray_entry"]): lifecycle["gray"] = true
	elif resonance > float(cfg["harmony"]["gray_exit"]): lifecycle["gray"] = false
	lifecycle["low_phrases"] = int(lifecycle["low_phrases"])+1 if resonance < float(cfg["harmony"]["gray_entry"]) else 0
	lifecycle["ended"] = mode != "free" and int(lifecycle["low_phrases"]) >= int(cfg["harmony"]["collapse_phrases"])
	_refresh_public_network(frame)
	# Courtyard geometry is a derived visual cache. Rebuilding every phrase made
	# long growth quadratic; explicit structural actions stay immediate, while
	# organic growth refreshes on alternating phrases.
	if forms_dirty and (not committed.is_empty() or phrase_index % 2 == 0): refresh_fabric()

func _grow(family: String, frame: int) -> void:
	if str(families[family].get("root","")).is_empty() or not by_id.has(str(families[family].get("root",""))): return
	if phrase_index < int(families[family].get("next_growth_phrase",0)):
		return
	var root: Dictionary = by_id[families[family]["root"]]
	var origin := Coupling.position_of(root)
	# Growth searches a bounded frontier. The old all-history search became quadratic
	# once dozens of communities had several generations of L3 candidates.
	var owned_positions: Array[Vector2] = []
	for owned in buildings:
		if str(owned["family_id"]) == family: owned_positions.append(Coupling.position_of(owned))
	var frontier: Array[Vector2] = []
	var frontier_start := maxi(0,owned_positions.size()-4)
	for index in range(frontier_start,owned_positions.size()): frontier.append(owned_positions[index])
	if frontier.is_empty(): frontier.append(origin)
	var candidates: Array[Dictionary] = []
	for lot in lots:
		if not str(lot["occupant"]).is_empty(): continue
		var lot_position := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var lot_near_frontier := false
		for frontier_point in frontier:
			if lot_position.distance_to(frontier_point) <= 8.0:
				lot_near_frontier = true
				break
		if lot_near_frontier: candidates.append({"position":lot_position,"use":str(lot["use"])})
	for courtyard in fabric_cache.get("courtyards",[]):
		var court_center := Vector2(float(courtyard["center"][0]),float(courtyard["center"][1]))
		var court_near_frontier := false
		for frontier_point in frontier:
			if court_center.distance_to(frontier_point) <= 8.0:
				court_near_frontier = true
				break
		if court_near_frontier: candidates.append({"position":court_center,"use":"residential","courtyard_id":str(courtyard["id"])})
	# L3 candidates make the city grow into open land instead of exhausting a parcel grid.
	for origin_point in frontier:
		for radius: float in [1.05,1.55,2.05,2.35]:
			for step in range(12):
				var angle := TAU*float(step)/12.0+float(posmod(origin_point.x*37.0+origin_point.y*19.0,1.0))*0.22
				var p := origin_point+Vector2.from_angle(angle)*radius
				var duplicate := false
				for candidate in candidates:
					if p.distance_to(candidate["position"]) < 0.78: duplicate = true; break
				if not duplicate: candidates.append({"position":p,"use":"residential"})
	var best: Dictionary = {}
	var best_check: Dictionary = {}
	var best_distance := INF
	var best_rank := -1
	for candidate in candidates:
		var p: Vector2 = Vector2(candidate["position"])
		var check := placement(p)
		if not check["allowed"]: continue
		var connected := false
		for owned in buildings:
			if owned["family_id"] != family: continue
			var op := Coupling.position_of(owned)
			if p.distance_to(op) <= 2.4 and float(road_environment(p,op)["occlusion"]) > 0.0 and not frozen(owned["district_id"]):
				connected = true
		if not connected: continue
		var clashes := false
		var ranked: Array = []
		var probe := {"position":[p.x,p.y],"radius":cfg["space"]["residential_radius"],"type":candidate["use"],"current_midi":root["current_midi"],"placement_tier":check["tier"]}
		for other_id in index.query_circle(p,float(probe["radius"])+float(cfg["space"]["gap_cutoff"])):
			var other: Dictionary = by_id[other_id]
			var weight := coupling.coefficient(probe,other,road_environment(p,Coupling.position_of(other)))
			if weight > 0.0: ranked.append({"id":other_id,"coupling":weight})
		ranked.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if a["coupling"] != b["coupling"]: return a["coupling"] > b["coupling"]
			return a["id"] < b["id"])
		if ranked.is_empty() or float(coupling.interval(int(root["current_midi"]),int(by_id[ranked[0]["id"]]["current_midi"]))["score"]) < 0.60: continue
		for neighbor in ranked.slice(0,int(cfg["space"]["near_neighbour_count"])):
			if float(coupling.interval(int(root["current_midi"]),int(by_id[neighbor["id"]]["current_midi"]))["score"]) <= 0.05: clashes = true
		if clashes: continue
		var tier_rank := 3 if check["tier"] == "L1" else (2 if check["tier"] == "L2" else 1)
		var distance := p.distance_squared_to(origin)
		if tier_rank > best_rank or (tier_rank == best_rank and distance < best_distance):
			best_rank = tier_rank
			best_distance = distance
			best = {"position":p}
			best_check = check
	if best.is_empty():
		last_reason = "这一家族暂缺可达空地；可以在另一侧播种新主题"
		return
	var p: Vector2 = best["position"]
	_birth(p,int(root["current_midi"]),family,false,frame)
	families[family]["next_growth_phrase"] = phrase_index+int(best_check.get("growth_delay",1))

func incident_edges(id: String) -> Array:
	var nearby: Array = []
	var building: Dictionary = by_id[id]
	for other_id in index.query_circle(Coupling.position_of(building),float(building["radius"])+float(cfg["space"]["gap_cutoff"])):
		if other_id == id: continue
		var pair := [id,other_id]
		pair.sort()
		var key := str(pair[0])+":"+str(pair[1])
		if edge_cache.has(key): nearby.append(edge_cache[key])
	return nearby

func near_edges(id: String) -> Array:
	var nearby := incident_edges(id)
	nearby.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a["coupling"] != b["coupling"]: return a["coupling"] > b["coupling"]
		return str(a["a"])+":"+str(a["b"]) < str(b["a"])+":"+str(b["b"]))
	return nearby.slice(0,int(cfg["space"]["near_neighbour_count"]))

func frozen(id: String) -> bool:
	for edge in near_edges(id):
		var other: String = edge["b"] if edge["a"] == id else edge["a"]
		if float(coupling.interval(int(by_id[id]["current_midi"]),int(by_id[other]["current_midi"]))["score"]) <= 0.05: return true
	return false

func _update_forms(frame: int) -> void:
	var modifiers := musicality()
	for building in buildings:
		var neighbors := near_edges(building["district_id"])
		var scores: Array[float] = []
		for edge in neighbors:
			var other: String = edge["b"] if edge["a"] == building["district_id"] else edge["a"]
			scores.append(float(coupling.interval(int(building["current_midi"]),int(by_id[other]["current_midi"]))["score"]))
		if scores.any(func(s: float) -> bool: return s <= 0.05):
			building["form_count"] = 0
			continue
		var good := scores.filter(func(s: float) -> bool: return s >= 0.85).size()
		var near := 0
		var radius := 4.0 if building["form"] == "胚" else 5.0
		for id in index.query_circle(Coupling.position_of(building),radius-float(building["radius"])):
			if by_id[id]["type"] == building["type"] and not by_id[id]["family_anchor"]: near += 1
		var local_edges: Array = []
		for edge in incident_edges(building["district_id"]):
			var copy: Dictionary = edge.duplicate()
			copy["coupling"] = float(edge["coupling"])*minf(float(modifiers[edge["a"]]["M"]),float(modifiers[edge["b"]]["M"]))
			local_edges.append(copy)
		var target := ""
		var duration := 2
		if building["form"] == "胚" and good >= 2 and near >= 3 and coupling.resonance(buildings,local_edges) >= 60.0: target = "群"
		elif building["form"] == "群" and str(building.get("placement_tier","L1")) != "L3":
			if good >= 3 and scores.has(1.0) and near >= 6:
				target = "央"
				duration = 3
			elif good >= 3 and good == scores.size(): target = "腔"
		building["form_count"] = int(building["form_count"])+1 if not target.is_empty() else 0
		if not target.is_empty() and int(building["form_count"]) >= duration:
			building["form"] = target
			building["form_count"] = 0
			events.append({"kind":"upgrade","district_id":building["district_id"],"frame":frame,"form":target})

func snapshot() -> Dictionary:
	return {"schema_version":2,"generation_version":66,"settings":cfg.duplicate(true),
		"terrain_state":{"noise_seed":terrain.noise_seed,"river_phase":terrain.river_phase,"family":terrain.family},
		"plan":{"lots":lots.duplicate(true),"roads":roads.duplicate(true),"nodes":nodes.duplicate(true),"blocks":blocks.duplicate(true),"green_corridors":green_corridors.duplicate(true),"centers":centers.duplicate(true),"communities":communities.duplicate(true)},
		"transit":transit.duplicate(true),"transit_lines":transit_lines.duplicate(true),"mode":mode,"profile":profile,"action_serial":action_serial,"public_sites":public_sites.duplicate(true),"landmarks":landmarks.duplicate(true),"landmark_progress":landmark_progress.duplicate(true),"pending_actions":pending_actions.duplicate(true),"seed_hex":rng.seed_hex,"rng":rng.snapshot(),"buildings":buildings.duplicate(true),
		"pending":pending.duplicate(true),"events":events.duplicate(true),"bridge":bridge,"phrase_index":phrase_index,"era":era,"expanded_plan":expanded_plan,
		"next_id":next_id,"families":families.duplicate(true),"lifecycle":lifecycle.duplicate(true),"last_reason":last_reason}

func restore(saved: Dictionary) -> void:
	assert(int(saved["schema_version"]) == 2 and saved["seed_hex"] == rng.seed_hex)
	if saved.has("plan"):
		cfg = saved["settings"].duplicate(true)
		terrain.cfg = cfg["terrain"]
		terrain.configure(int(saved["terrain_state"]["noise_seed"]),float(saved["terrain_state"]["river_phase"]),str(saved["terrain_state"].get("family","river_valley")))
		var plan: Dictionary = saved["plan"]
		lots.assign(plan["lots"].duplicate(true))
		roads.assign(plan["roads"].duplicate(true))
		nodes = plan["nodes"].duplicate(true)
		blocks.assign(plan["blocks"].duplicate(true))
		green_corridors.assign(plan.get("green_corridors",[]).duplicate(true))
		centers.assign(plan.get("centers",[]).duplicate(true))
		communities = plan["communities"].duplicate(true)
		transit = saved["transit"].duplicate(true)
		transit_lines.assign(saved.get("transit_lines",[]).duplicate(true))
	buildings.assign(saved["buildings"].duplicate(true))
	by_id.clear()
	index = Index.new()
	families.clear()
	for community in communities.values(): community["members"].clear()
	for lot in lots: lot["occupant"] = ""
	for building in buildings:
		var id: String = building["district_id"]
		by_id[id] = building
		index.put(id,Coupling.position_of(building),float(building["radius"]))
		communities[building["community_id"]]["members"].append(id)
		for lot in lots:
			if lot["id"] == building["lot_id"]: lot["occupant"] = id
	families = saved["families"].duplicate(true)
	pending = saved["pending"].duplicate(true)
	pending_actions.assign(saved.get("pending_actions",[]).duplicate(true))
	mode = str(saved.get("mode","free"))
	profile = str(saved.get("profile","bright"))
	action_serial = int(saved.get("action_serial",0))
	if saved.has("public_sites"): public_sites.assign(saved["public_sites"].duplicate(true))
	landmarks.assign(saved.get("landmarks",[]).duplicate(true))
	landmark_progress = saved.get("landmark_progress",{}).duplicate(true)
	for landmark in landmarks:
		for lot in lots:
			if str(lot.get("landmark_id","")) == str(landmark.get("id","")): lot["occupant"] = str(landmark["id"])
	events.assign(saved["events"].duplicate(true))
	bridge = bool(saved["bridge"])
	if bridge and not roads.any(func(r: Dictionary) -> bool: return r["bridge"]):
		var a: Array = nodes["west-2"]
		var b: Array = nodes["east-2"]
		roads.append({"id":"river-bridge","from":"west-2","to":"east-2","path":PackedVector2Array([Vector2(a[0],a[1]),Vector2(b[0],b[1])]),"bridge":true})
	elif not bridge: roads = roads.filter(func(r: Dictionary) -> bool: return not r["bridge"])
	phrase_index = int(saved["phrase_index"])
	era = int(saved.get("era",era_for_phrase(phrase_index)))
	expanded_plan = bool(saved.get("expanded_plan",false))
	if centers.is_empty(): _refresh_centers()
	next_id = int(saved["next_id"])
	lifecycle = saved["lifecycle"].duplicate(true)
	last_reason = saved["last_reason"]
	rng.restore(saved["rng"])
	rebuild_graph()
	resonance = coupling.resonance(buildings,musical_edges(musicality()))
	_refresh_public_network()
	refresh_fabric()

func fork() -> RefCounted:
	var copy: RefCounted = get_script().new(rng.seed_hex,false)
	copy.restore(snapshot())
	return copy


func era_for_phrase(value: int) -> int:
	# Twelve phrases is one readable city chapter. Vehicle history follows the music boundary.
	return clampi(1 + maxi(0,value) / 12,1,5)

func era_title() -> String:
	return ["古典","中世纪","文艺复兴","工业","现代"][clampi(era,1,5)-1]

func terrain_title() -> String:
	return terrain.family_title(terrain.family)

func vehicle_kind() -> String:
	return "carriage" if era <= 3 else ("tram" if era == 4 else "bus")

func vehicle_label() -> String:
	return {"carriage":"马车","tram":"有轨车","bus":"公交"}[vehicle_kind()]

func update_era(frame: int = 0) -> bool:
	var next_era := era_for_phrase(phrase_index)
	if next_era == era: return false
	era = next_era
	events.append({"kind":"era","era":era,"title":era_title(),"vehicle":vehicle_kind(),"frame":frame})
	_refresh_public_network(frame)
	return true

func _refresh_public_network(frame: int = 0) -> void:
	network.rebuild(nodes,roads,terrain)
	for site in public_sites:
		var covered: Array[String] = []
		if site["active"]:
			var entrance := Vector2(site["entrance"][0],site["entrance"][1])
			for building in buildings:
				var lot: Dictionary = {}
				for candidate in lots:
					if candidate["id"] == building["lot_id"]: lot = candidate
				var p := Coupling.position_of(building) if lot.is_empty() else Vector2(lot["entrance"][0],lot["entrance"][1])
				if network.walking_distance(entrance,p) <= float(cfg["city"]["service_walk_radius"]): covered.append(building["district_id"])
		site["covered"] = covered
	var lines: Array[Dictionary] = []
	if public_sites.any(func(site: Dictionary) -> bool: return site["id"] == "west-civic" and site["active"]):
		var itinerary: Array = ["west-1","west-2","west-3","west-outer-3","west-outer-2","west-outer-1","west-1"]
		if bridge: itinerary = ["west-1","west-2","east-2","east-1","east-2","east-3","east-2","west-2","west-3","west-2","west-1"]
		lines.append(_make_transit_line("valley-line","两岸联奏线" if bridge else "河谷环线",itinerary,frame))
	if public_sites.any(func(site: Dictionary) -> bool: return site["id"] == "east-civic" and site["active"]):
		var itinerary: Array = ["east-1","east-2","east-3","east-outer-3","east-outer-2","east-outer-1","east-1"]
		if nodes.has("east-garden-1"): itinerary = ["east-1","east-2","east-3","east-outer-3","east-garden-3","east-garden-2","east-garden-1","east-outer-1","east-1"]
		lines.append(_make_transit_line("garden-line","林荫支线",itinerary,frame))
	if expanded_plan and public_sites.any(func(site: Dictionary) -> bool: return site["id"] == "west-civic" and site["active"]):
		var terrace_itinerary: Array = ["west-1"]
		var index := 1
		while nodes.has("west-terrace-node-%d" % index):
			terrace_itinerary.append("west-terrace-node-%d" % index)
			index += 1
		terrace_itinerary.append("west-1")
		if terrace_itinerary.size() > 2:
			lines.append(_make_transit_line("terrace-line","台地回声线",terrace_itinerary,frame))
		var inner_itinerary: Array = ["west-1"]
		var inner_index := 1
		while nodes.has("west-inner-node-%d" % inner_index):
			inner_itinerary.append("west-inner-node-%d" % inner_index)
			inner_index += 1
		inner_itinerary.append("west-1")
		if inner_itinerary.size() > 2:
			lines.append(_make_transit_line("inland-line","内台接驳线",inner_itinerary,frame))
	transit_lines.assign(lines)
	transit = lines[0] if not lines.is_empty() else {}

func _make_transit_line(id: String, title: String, itinerary: Array, frame: int) -> Dictionary:
	var legs: Array[Dictionary] = []
	var path := PackedVector2Array()
	var edge_ids: Array = []
	for i in range(itinerary.size()-1):
		var journey := network.route(itinerary[i],itinerary[i+1])
		legs.append({"from":itinerary[i],"to":itinerary[i+1],"path":journey["path"],"length":journey["distance"]})
		path.append_array(journey["path"])
		edge_ids.append_array(journey["edges"])
	var started := frame
	for line in transit_lines:
		if line["id"] == id: started = int(line["frame"])
	return {"id":id,"name":title,"legs":legs,"path":path,"edges":edge_ids,"frame":started,"stops":itinerary.slice(0,-1)}

func public_at(p: Vector2) -> Dictionary:
	for site in public_sites:
		if Geometry2D.is_point_in_polygon(p,site["polygon"]): return site
	return {}

func expand_plan() -> void:
	if expanded_plan: return
	Terrace.populate(self)
	expanded_plan = true
	_refresh_centers()
	network.rebuild(nodes,roads,terrain)
	_refresh_public_network()
	refresh_fabric()

func build_expanded_town() -> void:
	expand_plan()
	build_town()

func build_town() -> void:
	profile = "bright"
	var ids: Array = communities.keys()
	ids.sort()
	var candidates: Dictionary = {}
	var roots: Dictionary = {}
	var tones := [48,55,52,43,36,48,55,52,36,43]
	for index in range(ids.size()):
		var cid: String = ids[index]
		var choices: Array = lots.filter(func(lot: Dictionary) -> bool: return lot["community_id"] == cid)
		choices.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["id"] < b["id"])
		candidates[cid] = choices
		roots[cid] = {"midi":tones[index%tones.size()],"count":0,"family":"town-"+cid}
		families["town-"+cid] = {"root":"","created_phrase":0,"expression":"deep" if cid.contains("garden") else "bright"}
	var progressed := true
	while progressed:
		progressed = false
		for cid in ids:
			if candidates[cid].is_empty(): continue
			var lot: Dictionary = candidates[cid].pop_front()
			var p := Vector2(lot["center"][0],lot["center"][1])
			if not placement(p)["allowed"]: continue
			var root: Dictionary = roots[cid]
			var pitch := int(root["midi"])
			if not str(cid).contains("garden") and int(root["count"]) in [2,5,8]:
				pitch = [48,52,55][int(root["count"])%3]
			var id := _birth(p,pitch,root["family"],int(root["count"]) == 0,-int(cfg["timing"]["sample_rate"])*4)
			if int(root["count"]) == 0: families[root["family"]]["root"] = id
			root["count"] = int(root["count"])+1
			progressed = true
	for site in public_sites:
		site["active"] = true
		site["frame"] = -int(cfg["timing"]["sample_rate"])*4
	_update_forms(-int(cfg["timing"]["sample_rate"])*2)
	_update_forms(-int(cfg["timing"]["sample_rate"]))
	_refresh_public_network()
	refresh_fabric()
	resonance = coupling.resonance(buildings,musical_edges(musicality()))

func build_starter(expression: String = "bright") -> void:
	profile = expression
	var ids := ["west-1","west-2","east-2"]
	var roots := [48,52,55] if expression == "bright" else [36,43,48]
	for region in range(ids.size()):
		var candidates: Array = lots.filter(func(lot: Dictionary) -> bool: return lot["community_id"] == ids[region])
		# A stable street-front walk, not arbitrary point scattering.
		candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["id"] < b["id"])
		var family := "family-%05d" % next_id
		families[family] = {"root":"","created_phrase":0,"expression":expression}
		var count := 0
		for lot in candidates:
			var p := Vector2(lot["center"][0],lot["center"][1])
			if not placement(p)["allowed"]: continue
			var pitch: int = roots[region]
			if expression == "bright" and count in [2,4]: pitch = [48,52,55][(region+count)%3]
			var id := _birth(p,pitch,family,count == 0,-int(cfg["timing"]["sample_rate"])*4)
			if count == 0: families[family]["root"] = id
			count += 1
			if count >= int(cfg["city"]["starter_buildings_per_region"]): break
	for site in public_sites:
		if site["id"] in ["west-park","west-civic"]:
			site["active"] = true
			site["frame"] = -int(cfg["timing"]["sample_rate"])*4
	_update_forms(-int(cfg["timing"]["sample_rate"])*2)
	_update_forms(-int(cfg["timing"]["sample_rate"]))
	_refresh_public_network()
	refresh_fabric()
	resonance = coupling.resonance(buildings,musical_edges(musicality()))

func community_theme(cid: String, pitches: Dictionary = {}) -> Array:
	var members: Array = communities[cid]["members"].duplicate()
	members.sort_custom(func(a: String,b: String) -> bool:
		var aa := Coupling.position_of(by_id[a])
		var bb := Coupling.position_of(by_id[b])
		if aa.x+aa.y != bb.x+bb.y: return aa.x+aa.y < bb.x+bb.y
		return a < b)
	var notes: Array = []
	for id in members:
		var pitch := int(pitches.get(id,by_id[id]["current_midi"]))
		if not notes.has(pitch): notes.append(pitch)
	return notes
