class_name ContinuousWorld
extends RefCounted
const Config = preload("res://scripts/world/world_values.gd")
const Terrain = preload("res://scripts/world/valley_terrain.gd")
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Index = preload("res://scripts/world/world_spatial_index.gd")
const RandomStreams = preload("res://scripts/city/named_random.gd")
const Legacy = preload("res://scripts/spec_values.gd")
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
var events: Array[Dictionary] = []
var bridge := false
var phrase_index := 0
var next_id := 1
var resonance := 100.0
var lifecycle := {"gray":false,"low_phrases":0,"ended":false}
var last_reason := "在河边选择一块临街空地，播下第一段声音"

func _init(seed_hex: String = "2026100900000062") -> void:
	rng = RandomStreams.new(seed_hex)
	terrain.configure(rng.bounded("terrain",2147483647),float(rng.next_u32("terrain"))/4294967296.0*TAU)
	_plan()

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

func road_environment(a: Vector2,b: Vector2) -> Dictionary:
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
	edge_cache.clear()
	for building in buildings: _cache_entity(building["district_id"])

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
	for id in index.query_circle(p,radius):
		if p.distance_to(Coupling.position_of(by_id[id])) < radius+float(by_id[id]["radius"])-1e-6:
			return {"allowed":false,"reason":"与已有建筑太近，留一点呼吸的空隙"}
	for lot in lots:
		if not str(lot["occupant"]).is_empty(): continue
		var contained := true
		for corner in polygon:
			if not Geometry2D.is_point_in_polygon(corner,lot["polygon"]): contained = false
		if contained: return {"allowed":true,"lot_id":lot["id"],"community_id":lot["community_id"],"reason":"临街地块，可在下一乐句落定"}
	return {"allowed":false,"reason":"靠近岸边街道旁的空地；道路和岸线需要留空"}

func request(operation: Dictionary, frame: int) -> Dictionary:
	if lifecycle["ended"]: return {"accepted":false,"reason":"这一段已结束，按R重新播种"}
	var kind := str(operation.get("kind",""))
	if kind == "seed":
		if buildings.size() >= int(cfg["terrain"]["template_slice_building_budget"]): return {"accepted":false,"reason":"河谷首片已达当前供音预算"}
		var check := placement(Vector2(float(operation["position"][0]),float(operation["position"][1])))
		if not check["allowed"]: return {"accepted":false,"reason":check["reason"]}
	elif kind == "retune":
		if not by_id.has(operation.get("id","")): return {"accepted":false,"reason":"请选择一栋建筑"}
	elif kind == "bridge":
		if bridge: return {"accepted":false,"reason":"桥已经连接两岸"}
	else: return {"accepted":false,"reason":"未知操作"}
	if kind in ["seed","retune"]:
		var midi := int(operation["midi"])
		var allowed: Array = Legacy.load_values()["proposals"]["allowed_pitches"]
		var legal := false
		for pitch in allowed:
			if int(pitch) == midi or int(pitch) == midi+12: legal = true
		if not legal: return {"accepted":false,"reason":"请选择当前时代的五声音阶"}
	pending = operation.duplicate(true)
	pending["frame"] = frame
	return {"accepted":true,"frame":frame}

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
		"community_id":check["community_id"],"lot_id":check["lot_id"],"family_id":family,"anchor_id":family,
		"family_anchor":root,"is_anchor":false,"era":1,"form":"胚","form_count":0,"birth_frame":frame,"voice_level":0.2}
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
	var costs: Dictionary = {}
	if not pending.is_empty():
		assert(int(pending["frame"]) == frame)
		match str(pending["kind"]):
			"seed":
				var family := "family-%05d" % next_id
				var p := Vector2(float(pending["position"][0]),float(pending["position"][1]))
				var root := _birth(p,int(pending["midi"]),family,true,frame)
				families[family] = {"root":root,"created_phrase":phrase_index}
			"retune":
				by_id[pending["id"]]["current_midi"] = int(pending["midi"])
				costs[pending["id"]] = float(Legacy.load_values()["proposals"]["retune_cost"])
				events.append({"kind":"retune","district_id":pending["id"],"frame":frame})
			"bridge":
				bridge = true
				var a: Array = nodes["west-2"]
				var b: Array = nodes["east-2"]
				roads.append({"id":"river-bridge","from":"west-2","to":"east-2","path":PackedVector2Array([Vector2(a[0],a[1]),Vector2(b[0],b[1])]),"bridge":true})
				rebuild_graph()
				events.append({"kind":"bridge","frame":frame})
		pending.clear()
	if not lifecycle["ended"]:
		for family in families:
			if int(families[family]["created_phrase"]) == phrase_index: continue
			_grow(family,frame)
	var modifiers := musicality()
	var effective := musical_edges(modifiers)
	resonance = coupling.resonance(buildings,effective)
	var vitalities := coupling.vitality(buildings,effective,resonance,costs,modifiers)
	for building in buildings: building["vitality"] = vitalities[building["district_id"]]
	_update_forms(frame)
	if resonance < float(cfg["harmony"]["gray_entry"]): lifecycle["gray"] = true
	elif resonance > float(cfg["harmony"]["gray_exit"]): lifecycle["gray"] = false
	lifecycle["low_phrases"] = int(lifecycle["low_phrases"])+1 if resonance < float(cfg["harmony"]["gray_entry"]) else 0
	lifecycle["ended"] = int(lifecycle["low_phrases"]) >= int(cfg["harmony"]["collapse_phrases"])

func _grow(family: String, frame: int) -> void:
	if buildings.size() >= int(cfg["terrain"]["template_slice_building_budget"]):
		last_reason = "这一片河谷已长满；城市规模扩展将在编曲预算接入后开放"
		return
	var root: Dictionary = by_id[families[family]["root"]]
	var origin := Coupling.position_of(root)
	var best: Dictionary = {}
	var best_distance := INF
	for lot in lots:
		if not str(lot["occupant"]).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if not placement(p)["allowed"]: continue
		var connected := false
		for owned in buildings:
			if owned["family_id"] != family: continue
			var op := Coupling.position_of(owned)
			if p.distance_to(op) <= 2.4 and float(road_environment(p,op)["occlusion"]) > 0.0 and not frozen(owned["district_id"]): connected = true
		if not connected: continue
		var clashes := false
		var ranked: Array = []
		var probe := {"position":[p.x,p.y],"radius":cfg["space"]["residential_radius"],"type":lot["use"],"current_midi":root["current_midi"]}
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
		var distance := p.distance_squared_to(origin)
		if distance < best_distance:
			best_distance = distance
			best = lot
	if best.is_empty():
		last_reason = "这一家族暂缺可达临街空地；可以在另一侧播种新主题"
		return
	var p := Vector2(float(best["center"][0]),float(best["center"][1]))
	_birth(p,int(root["current_midi"]),family,false,frame)

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
		elif building["form"] == "群":
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
	return {"schema_version":2,"seed_hex":rng.seed_hex,"rng":rng.snapshot(),"buildings":buildings.duplicate(true),
		"pending":pending.duplicate(true),"events":events.duplicate(true),"bridge":bridge,"phrase_index":phrase_index,
		"next_id":next_id,"families":families.duplicate(true),"lifecycle":lifecycle.duplicate(true),"last_reason":last_reason}

func restore(saved: Dictionary) -> void:
	assert(int(saved["schema_version"]) == 2 and saved["seed_hex"] == rng.seed_hex)
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
	events.assign(saved["events"].duplicate(true))
	bridge = bool(saved["bridge"])
	if bridge and not roads.any(func(r: Dictionary) -> bool: return r["bridge"]):
		var a: Array = nodes["west-2"]
		var b: Array = nodes["east-2"]
		roads.append({"id":"river-bridge","from":"west-2","to":"east-2","path":PackedVector2Array([Vector2(a[0],a[1]),Vector2(b[0],b[1])]),"bridge":true})
	elif not bridge: roads = roads.filter(func(r: Dictionary) -> bool: return not r["bridge"])
	phrase_index = int(saved["phrase_index"])
	next_id = int(saved["next_id"])
	lifecycle = saved["lifecycle"].duplicate(true)
	last_reason = saved["last_reason"]
	rng.restore(saved["rng"])
	rebuild_graph()
	resonance = coupling.resonance(buildings,musical_edges(musicality()))

func fork() -> RefCounted:
	var copy: RefCounted = get_script().new(rng.seed_hex)
	copy.restore(snapshot())
	return copy
