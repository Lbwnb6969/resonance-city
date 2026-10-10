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
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const RiverResponse = preload("res://scripts/world/river_call_response.gd")
const PublicRelocation = preload("res://scripts/world/public_site_relocation.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
var cfg: Dictionary = Config.load_values()
var terrain := Terrain.new()
var coupling := Coupling.new()
var index := Index.new()
var road_index := Index.new()
var road_segments: Dictionary = {}
var road_index_identity := ""
var parcel_index := Index.new()
var parcel_index_identity := ""
var parcel_records: Dictionary = {}
var fabric_anchor_cache: Dictionary = {}
var fabric_profile: Dictionary = {}
var fabric_geometry_identity := ""
var incident_edge_cache: Dictionary = {}
var near_edge_cache: Dictionary = {}
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
var planning_reservations: Array[Dictionary] = []
var development_charters: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var landmark_progress: Dictionary = {}
var network: CityRoadNetwork
var transit: Dictionary = {}
var transit_lines: Array[Dictionary] = []
# Smoothed stop activity is a light-weight memory shared by transport, growth,
# and music; it is not a full economy simulation.
var transit_demand: Dictionary = {}
# Stop observations commit after growth; the next phrase consumes this pressure.
var transit_flow_pending: Array[Dictionary] = []
# Ephemeral task version; snapshots restore without pending worker tasks.
var planning_revision := 0
# Service pressure is derived from public coverage and cached within a planning pass.
var public_service_cache: Dictionary = {}
var settle_profile: Dictionary = {}
# Functional districts are derived from active communities and public infrastructure.
# They provide a stable bridge between city layout, UI language, and musical phrasing.
var functional_zones: Array[Dictionary] = []
var environment_cache: Dictionary = {}
# Queries made while a worker owns the frozen base remain private to this World.
var environment_pending: Dictionary = {}
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

func active_community_count() -> int:
	var count := 0
	for cid in communities:
		if bool(communities[cid].get("active",true)): count += 1
	return count

func _active_community_ids() -> Array[String]:
	var ids: Array[String] = []
	for cid in communities:
		if not bool(communities[cid].get("active",true)): continue
		if communities[cid].get("members",[]).is_empty(): continue
		ids.append(str(cid))
	ids.sort_custom(func(a: String,b: String) -> bool:
		var ar := center_order(a)
		var br := center_order(b)
		if ar != br: return ar < br
		return a < b)
	return ids

func _community_usage(cid: String) -> Dictionary:
	var result := {"residential":0,"commercial":0,"industrial":0,"public":0}
	if not communities.has(cid): return result
	for id in communities[cid].get("members",[]):
		if not by_id.has(id): continue
		var kind := str(by_id[id].get("type","residential"))
		if not result.has(kind): result[kind] = 0
		result[kind] = int(result[kind])+1
	return result

func community_public_service(cid: String) -> Dictionary:
	return public_service_cache.get(cid,{"member_count":0,"civic_count":0,"park_count":0,
		"facility_count":0,"cultural_target":0,"cultural_gap":0,"covered_count":0,
		"cultural_served":0,"coverage_ratio":0.0,"pressure":0.0}).duplicate(true)

func public_service_summary() -> Dictionary:
	var served := 0
	var covered := 0
	var reachable := 0
	for service in public_service_cache.values():
		served += int(service.get("cultural_served",0))
		covered += int(service.get("covered_count",0))
		reachable += int(service.get("cultural_reachable",0))
	var facilities := 0
	var capacity := 0
	for site in public_sites:
		if bool(site.get("active",false)) and str(site.get("kind","")) == "civic":
			facilities += 1
			capacity += int(site.get("service_capacity",18))
	return {"members":buildings.size(),"facilities":facilities,"capacity":capacity,
		"covered":covered,"reachable":reachable,"served":served,"unserved":buildings.size()-served}

func _refresh_public_service() -> void:
	public_service_cache.clear()
	var destinations: Dictionary = {}
	for cid in _active_community_ids():
		var count: int = communities[cid]["members"].size()
		public_service_cache[cid] = {"member_count":count,"civic_count":0,"park_count":0,
			"facility_count":0,"cultural_target":ceili(float(count)/18.0),"cultural_gap":0,
			"covered_count":0,"cultural_reachable":0,"cultural_served":0,"coverage_ratio":0.0,"pressure":0.0}
	for site in public_sites:
		site["service_capacity"] = 18*int(site.get("service_level",1)) if site["kind"] == "civic" else 0
		site["service_demand"] = 0
		site["served"] = []
		if not bool(site.get("active",false)): continue
		var served_communities: Dictionary = {}
		for building_id in site.get("covered",[]):
			if not by_id.has(building_id): continue
			var cid := str(by_id[building_id]["community_id"])
			served_communities[cid] = true
			if not destinations.has(building_id): destinations[building_id] = {"public":true,"civic":[]}
			if site["kind"] == "civic": destinations[building_id]["civic"].append(site)
		for cid in served_communities:
			var service: Dictionary = public_service_cache[cid]
			var key := "civic_count" if site["kind"] == "civic" else "park_count"
			service[key] = int(service[key])+1
			service["facility_count"] = int(service["facility_count"])+1
	# Each house requests one cultural place. Overflow can use another reachable
	# facility; neither overlapping catchments nor community splits duplicate users.
	var ids: Array = destinations.keys()
	ids.sort()
	for building_id in ids:
		var cid := str(by_id[building_id]["community_id"])
		var service: Dictionary = public_service_cache[cid]
		service["covered_count"] = int(service["covered_count"])+1
		var choices: Array = destinations[building_id]["civic"]
		if choices.is_empty(): continue
		service["cultural_reachable"] = int(service["cultural_reachable"])+1
		var position := Coupling.position_of(by_id[building_id])
		choices.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			var da := position.distance_squared_to(Vector2(a["entrance"][0],a["entrance"][1]))
			var db := position.distance_squared_to(Vector2(b["entrance"][0],b["entrance"][1]))
			return str(a["id"]) < str(b["id"]) if is_equal_approx(da,db) else da < db)
		choices[0]["service_demand"] = int(choices[0]["service_demand"])+1
		for site in choices:
			if site["served"].size() >= int(site["service_capacity"]): continue
			site["served"].append(building_id)
			service["cultural_served"] = int(service["cultural_served"])+1
			break
	for service in public_service_cache.values():
		var count := int(service["member_count"])
		var unserved := count-int(service["cultural_served"])
		service["cultural_gap"] = ceili(float(unserved)/18.0)
		service["coverage_ratio"] = float(service["covered_count"])/float(maxi(1,count))
		service["pressure"] = float(unserved)/float(maxi(1,count))

func record_transit_flow(stop_id: String, boarded: int, alighted: int, transfers: int = 0) -> void:
	if stop_id.is_empty(): return
	transit_flow_pending.append({"stop_id":stop_id,"boarded":boarded,"alighted":alighted,"transfers":transfers})

func _commit_transit_flow() -> void:
	for observation in transit_flow_pending:
		var key := str(observation["stop_id"])
		var record: Dictionary = transit_demand.get(key,{"score":0.0,"boarded":0,"alighted":0,"transfers":0,"visits":0})
		var boarded := maxi(0,int(observation["boarded"]))
		var alighted := maxi(0,int(observation["alighted"]))
		var transfers := maxi(0,int(observation["transfers"]))
		var activity := float(boarded+alighted)+float(transfers)*1.5
		record["score"] = minf(8.0,float(record.get("score",0.0))*0.985+activity*0.35)
		record["boarded"] = int(record.get("boarded",0))+boarded
		record["alighted"] = int(record.get("alighted",0))+alighted
		record["transfers"] = int(record.get("transfers",0))+transfers
		record["visits"] = int(record.get("visits",0))+1
		transit_demand[key] = record
	transit_flow_pending = []

func transit_demand_score(stop_id: String) -> float:
	return clampf(float(transit_demand.get(str(stop_id),{}).get("score",0.0)),0.0,8.0)

func _decay_transit_demand() -> void:
	for stop_id in transit_demand:
		var record: Dictionary = transit_demand[stop_id]
		record["score"] = float(record.get("score",0.0))*0.94
		transit_demand[stop_id] = record

func _community_transit_demand(cid: String) -> float:
	var center := center_for(cid)
	if center.is_empty(): return 0.0
	var demand := transit_demand_score(str(center.get("node_id","")))
	var service := community_public_service(cid)
	# Reachable but undersupplied civic services create a bounded trip pressure.
	if int(service.get("cultural_reachable",0)) > 0:
		demand = minf(8.0,demand+float(service.get("pressure",0.0))*0.35)
	return demand

func functional_zone_roles(cid: String) -> Array[String]:
	var roles: Array[String] = []
	for zone in functional_zones:
		if zone.get("community_ids",[]).has(cid):
			roles.append(str(zone.get("music_role",zone.get("role","mixed"))))
	return roles

func refresh_functional_zones() -> void:
	var ids := _active_community_ids()
	var next: Array[Dictionary] = []
	var role_specs := [
		{"role":"residential","title":"居住带","music_role":"home","threshold":2},
		{"role":"commercial","title":"商贸核心","music_role":"market","threshold":2},
		{"role":"industrial","title":"工坊带","music_role":"workshop","threshold":1}
	]
	for spec in role_specs:
		var members: Array[String] = []
		var count := 0
		for cid in ids:
			var usage := _community_usage(cid)
			if int(usage.get(spec["role"],0)) < int(spec["threshold"]): continue
			members.append(cid)
			count += int(usage[spec["role"]])
		if members.size() >= 2:
			next.append({"id":"zone-"+str(spec["role"])+ "-core","role":spec["role"],"title":spec["title"],"music_role":spec["music_role"],"community_ids":members,"building_count":count,"site_ids":[],"line_ids":[]})
	var green_members: Array[String] = []
	var green_sites: Array[String] = []
	for site in public_sites:
		if not bool(site.get("active",false)) or str(site.get("kind","")) not in ["park","civic"]: continue
		var cid := str(site.get("community_id",""))
		if cid.is_empty() or not ids.has(cid): continue
		if not green_members.has(cid): green_members.append(cid)
		green_sites.append(str(site.get("id","")))
	if green_members.size() >= 1 and green_corridors.size() > 0:
		green_members.sort_custom(func(a: String,b: String) -> bool: return center_order(a) < center_order(b) if center_order(a) != center_order(b) else a < b)
		var green_pressure := 0.0
		var green_covered := 0
		for cid in green_members:
			var service := community_public_service(cid)
			green_pressure += float(service.get("pressure",0.0))
			green_covered += int(service.get("covered_count",0))
		next.append({"id":"zone-civic-green","role":"civic_green","title":"公园与公共生活带","music_role":"garden","community_ids":green_members,"building_count":0,"site_ids":green_sites,"line_ids":[],"service_pressure":green_pressure,"covered_count":green_covered})
	var cultural_members: Array[String] = []
	var cultural_sites: Array[String] = []
	for site in public_sites:
		if not bool(site.get("active",false)) or str(site.get("kind","")) != "civic": continue
		var cid := str(site.get("community_id",""))
		if cid.is_empty() or not ids.has(cid): continue
		if not cultural_members.has(cid): cultural_members.append(cid)
		cultural_sites.append(str(site.get("id","")))
	if cultural_members.size() >= 2:
		cultural_members.sort_custom(func(a: String,b: String) -> bool: return center_order(a) < center_order(b) if center_order(a) != center_order(b) else a < b)
		var cultural_target := 0
		var cultural_gap := 0
		var cultural_pressure := 0.0
		var cultural_covered := 0
		for cid in cultural_members:
			var service := community_public_service(cid)
			cultural_target += int(service.get("cultural_target",0))
			cultural_gap += int(service.get("cultural_gap",0))
			cultural_pressure += float(service.get("pressure",0.0))
			cultural_covered += int(service.get("covered_count",0))
		next.append({"id":"zone-cultural-core","role":"cultural","title":"文化声场","music_role":"choir","community_ids":cultural_members,"building_count":0,"site_ids":cultural_sites,"line_ids":[],"cultural_target":cultural_target,"cultural_gap":cultural_gap,"service_pressure":cultural_pressure,"covered_count":cultural_covered})
	var mixed_members: Array[String] = []
	for cid in ids:
		var usage := _community_usage(cid)
		var used := 0
		for key in usage:
			if int(usage[key]) > 0: used += 1
		if used >= 2: mixed_members.append(cid)
	if mixed_members.size() >= 2:
		next.append({"id":"zone-mixed-center","role":"mixed","title":"混合中心","music_role":"center","community_ids":mixed_members,"building_count":0,"site_ids":[],"line_ids":[]})
	if transit_lines.size() > 0:
		var transit_members: Array[String] = []
		for cid in ids:
			var center := center_for(cid)
			if center.is_empty(): continue
			var node_id := str(center.get("node_id",""))
			for line in transit_lines:
				if line.get("stops",[]).has(node_id) or line.get("itinerary",[]).has(node_id):
					transit_members.append(cid)
					break
		if transit_members.size() >= 2:
			var line_ids: Array = transit_lines.map(func(line: Dictionary) -> String: return str(line.get("id","")))
			var demand_total := 0.0
			var demand_peak := 0.0
			for cid in transit_members:
				var local_demand := _community_transit_demand(cid)
				demand_total += local_demand
				demand_peak = maxf(demand_peak,local_demand)
			var demand_average := demand_total/float(transit_members.size())
			next.append({"id":"zone-transit-hub","role":"transit","title":"换乘节点","music_role":"pulse_dense" if demand_peak >= 2.5 else "pulse","community_ids":transit_members,"building_count":0,"site_ids":[],"line_ids":line_ids,"transit_demand":demand_average,"peak_demand":demand_peak})
	functional_zones = next

func road_environment(a: Vector2,b: Vector2) -> Dictionary:
	var key := Vector4(a.x,a.y,b.x,b.y)
	if environment_pending.has(key): return environment_pending[key]
	if environment_cache.has(key): return environment_cache[key]
	var result := _road_environment(a,b)
	if environment_cache.is_read_only():
		if environment_pending.is_read_only(): environment_pending = environment_pending.duplicate()
		environment_pending[key] = result
	else: environment_cache[key] = result
	return result

## The first bridge is a real pair of road nodes, rather than a free floating
## cross-river action.  Keep this read-only snapshot shared by the map preview
## and the request/settle boundary so a changed road graph can invalidate an
## old preview without changing the existing bridge commit shape.
func bridge_preview() -> Dictionary:
	if bridge:
		return {"available":false,"built":true,"reason":"桥已经连接","source_topology":network.topology}
	if not nodes.has("west-2") or not nodes.has("east-2"):
		return {"available":false,"built":false,"reason":"当前河段没有成对的两岸道路","source_topology":network.topology}
	var from_node := "west-2"
	var to_node := "east-2"
	var from_raw: Array = nodes[from_node]
	var to_raw: Array = nodes[to_node]
	var from := Vector2(float(from_raw[0]),float(from_raw[1]))
	var to := Vector2(float(to_raw[0]),float(to_raw[1]))
	var road_ids: Array[String] = []
	for road in roads:
		if str(road.get("from","")) in [from_node,to_node] or str(road.get("to","")) in [from_node,to_node]:
			if not bool(road.get("bridge",false)): road_ids.append(str(road.get("id","")))
	road_ids.sort()
	var crossing := terrain.environment(from,to,false)
	var before_route := network.walking_distance(from,to)
	var community_ids: Array[String] = []
	for cid in ["west-2","east-2"]:
		if communities.has(cid): community_ids.append(cid)
	var community_names: Array[String] = []
	for cid in community_ids: community_names.append(str(communities[cid].get("name",cid)))
	var preview_path := PackedVector2Array([from,to])
	return {"available":true,"built":false,"from_node":from_node,"to_node":to_node,
		"from_position":[from.x,from.y],"to_position":[to.x,to.y],"path":preview_path,
		"road_ids":road_ids,"community_ids":community_ids,"community_names":community_names,
		"source_topology":network.topology,"source_world_version":[phrase_index,action_serial,planning_revision],
		"crossing_length":from.distance_to(to),"occlusion_before":float(crossing.get("occlusion",0.0)),
		"route_before":before_route,"route_after":from.distance_to(to),
		"traffic_before":"河谷环线","traffic_after":"两岸联奏线","vehicle":vehicle_label(),
		"role":"连接两岸道路与公共服务，下一句重算路网、交通与空间声学"}

func _road_environment(a: Vector2,b: Vector2) -> Dictionary:
	var result := terrain.environment(a,b,bridge)
	if float(result["occlusion"]) == 0.0: return result
	for id in road_index.query_bounds(Rect2(a,b-a).abs()):
		var segment: Dictionary = road_segments[id]
		if segment["road"]["bridge"]: continue
		if Geometry2D.segment_intersects_segment(a,b,segment["a"],segment["b"]) != null:
			result["occlusion"] = 0.0
			return result
	return result

func edges() -> Array:
	return edge_cache.values()

func _cache_entity(id: String) -> void:
	if edge_cache.is_read_only(): edge_cache = edge_cache.duplicate()
	incident_edge_cache.erase(id)
	near_edge_cache.erase(id)
	var a: Dictionary = by_id[id]
	for other_id in index.query_circle(Coupling.position_of(a),float(a["radius"])+float(cfg["space"]["gap_cutoff"])):
		if other_id == id: continue
		incident_edge_cache.erase(other_id)
		near_edge_cache.erase(other_id)
		var b: Dictionary = by_id[other_id]
		var pair := [id,other_id]
		pair.sort()
		var key := str(pair[0])+":"+str(pair[1])
		var weight := coupling.coefficient(a,b,road_environment(Coupling.position_of(a),Coupling.position_of(b)))
		if weight > 0.0: edge_cache[key] = {"a":pair[0],"b":pair[1],"coupling":weight}
		else: edge_cache.erase(key)

func _refresh_road_index() -> void:
	_refresh_parcel_index()
	var identity: Array = []
	for road in roads: identity.append([road["id"],road["path"],road.get("bridge",false),road.get("kind","")])
	var next_identity := JSON.stringify(identity)
	if next_identity == road_index_identity: return
	road_index_identity = next_identity
	road_index = Index.new()
	road_segments.clear()
	var ordinal := 0
	for road in roads:
		var path: PackedVector2Array = road["path"]
		for step in range(path.size()-1):
			var id := "segment-%05d" % ordinal
			var a: Vector2 = path[step]
			var b: Vector2 = path[step+1]
			road_segments[id] = {"a":a,"b":b,"road":road}
			road_index.put(id,(a+b)*0.5,a.distance_to(b)*0.5)
			ordinal += 1

func _refresh_parcel_index() -> void:
	var identity: Array = []
	for group in [lots,public_sites,planning_reservations]:
		for record in group: identity.append([record["id"],record["polygon"]])
	var next_identity := JSON.stringify(identity)
	if next_identity == parcel_index_identity: return
	parcel_index_identity = next_identity
	parcel_index = Index.new()
	parcel_records.clear()
	for group in [lots,public_sites,planning_reservations]:
		var prefix := "reservation" if group == planning_reservations else ("lot" if group == lots else "site")
		for ordinal in range(group.size()):
			var polygon: PackedVector2Array = group[ordinal]["polygon"]
			var bounds := Rect2(polygon[0],Vector2.ZERO)
			for point in polygon: bounds = bounds.expand(point)
			var id := "%s-%05d" % [prefix,ordinal]
			parcel_records[id] = ordinal
			parcel_index.put(id,bounds.get_center(),bounds.size.length()*0.5)

func near_lots(p: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in parcel_index.query_circle(p,0.0):
		if id.begins_with("lot-"): result.append(lots[int(parcel_records[id])])
	return result

func near_public_sites(p: Vector2,reach: float = 0.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in parcel_index.query_circle(p,reach):
		if id.begins_with("site-"): result.append(public_sites[int(parcel_records[id])])
	return result

func near_planning_reservations(p: Vector2,reach: float = 0.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in parcel_index.query_circle(p,reach):
		if id.begins_with("reservation-"): result.append(planning_reservations[int(parcel_records[id])])
	return result

func planning_candidate(p: Vector2) -> Dictionary:
	return SpatialPlanning.candidate(self,p)

## Read-only relocation preview. The action pipeline consumes the same result
## when a relocate_public operation is requested.
func public_site_relocation_preview(site_id: String,target_position: Vector2) -> Dictionary:
	return PublicRelocation.preview(self,site_id,target_position)

func planning_at(p: Vector2) -> Dictionary:
	return SpatialPlanning.reservation_at(self,p)

func near_road_segments(p: Vector2,reach: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in road_index.query_circle(p,reach): result.append(road_segments[id])
	return result

func rebuild_graph() -> void:
	_refresh_road_index()
	environment_cache = {}
	environment_pending = {}
	edge_cache = {}
	incident_edge_cache.clear()
	near_edge_cache.clear()
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
	if not terrain.valid_footprint(polygon): return {"allowed":false,"reason":"这里是水域或地图边界，需要完整的陆地占地"}
	var radius := float(cfg["space"]["residential_radius"])
	if Fabric.on_road(self,p,radius): return {"allowed":false,"reason":"这里是成路，留出道路的连续通行面"}
	for id in index.query_circle(p,radius):
		if p.distance_to(Coupling.position_of(by_id[id])) < radius+float(by_id[id]["radius"])-1e-6:
			return {"allowed":false,"reason":"与已有建筑太近，留一点呼吸的空隙"}
	var excluded := SpatialPlanning.exclusion(self,polygon)
	if not excluded.is_empty(): return {"allowed":false,"reason":excluded}
	for lot in near_lots(p):
		if not str(lot["occupant"]).is_empty(): continue
		var contained := true
		for corner in polygon:
			if not Geometry2D.is_point_in_polygon(corner,lot["polygon"]):
				contained = false
				break
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


func landmark_at(position: Vector2) -> Dictionary:
	for landmark in landmarks:
		var center := Vector2(float(landmark["position"][0]),float(landmark["position"][1]))
		if center.distance_to(position) <= float(landmark.get("radius",1.0)): return landmark
	return {}

func _landmark_record(name: String) -> Dictionary:
	for landmark in landmarks:
		if str(landmark.get("name","")) == name and bool(landmark.get("active",false)): return landmark
	return {}

func landmark_intervention_slots() -> int:
	return 2 if not _landmark_record("元老院").is_empty() else 1

func _landmark_near(name: String,position: Vector2,radius: float) -> Dictionary:
	var landmark := _landmark_record(name)
	if landmark.is_empty(): return {}
	var center := Vector2(float(landmark["position"][0]),float(landmark["position"][1]))
	return landmark if center.distance_to(position) <= radius else {}

func _landmark_same_pitch(landmark: Dictionary,midi: int) -> bool:
	var anchor := int(landmark.get("anchor_midi",48))
	return posmod(absi(midi-anchor),12) == 0

func _update_landmark_activation(frame: int) -> void:
	for landmark in landmarks:
		if bool(landmark.get("active",false)): continue
		var reveal_end := int(landmark.get("reveal_frame",frame))+int(landmark.get("reveal_frames",1))
		if frame < reveal_end: continue
		landmark["active"] = true
		events.append({"kind":"landmark_active","id":landmark["id"],"name":landmark["name"],"frame":frame})

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


func landmark_upgrade_duration(building: Dictionary,base_duration: int) -> int:
	var temple := _landmark_near("神殿",Coupling.position_of(building),4.0)
	if not temple.is_empty() and _landmark_same_pitch(temple,int(building["current_midi"])):
		return maxi(1,base_duration-1)
	return base_duration

func landmark_growth_connected(position: Vector2,connected: bool) -> bool:
	return connected or not _landmark_near("圆形剧场",position,5.0).is_empty()

func landmark_vitality_bonus(position: Vector2) -> float:
	return 2.0 if not _landmark_near("圆形剧场",position,4.0).is_empty() else 0.0

func landmark_commercial_bonus(building: Dictionary) -> float:
	if str(building.get("type","")) != "commercial": return 0.0
	return 2.0 if not _landmark_near("行会大厅",Coupling.position_of(building),4.0).is_empty() else 0.0

func landmark_allows_dissonance(position: Vector2) -> bool:
	return not _landmark_near("大教堂",position,4.5).is_empty()

func _landmark_distance_to_segment(p: Vector2,a: Vector2,b: Vector2) -> float:
	var delta := b-a
	var length_squared := delta.length_squared()
	if length_squared <= 0.0001: return p.distance_to(a)
	var t := clampf((p-a).dot(delta)/length_squared,0.0,1.0)
	return p.distance_to(a+delta*t)

func landmark_site_clear(position: Vector2,radius: float,ignore_reservation: String = "") -> bool:
	var polygon := PackedVector2Array()
	for i in range(32): polygon.append(position+Vector2.from_angle(TAU*i/32.0)*radius)
	if not SpatialPlanning.exclusion(self,polygon,ignore_reservation).is_empty(): return false
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

func landmark_reservation(position: Vector2,radius: float) -> Dictionary:
	for reservation in planning_reservations:
		if SpatialPlanning.reservation_contains_disc(reservation,position,radius): return reservation
	return {}

func _split_landmark_reservation(position: Vector2,radius: float,landmark_id: String) -> Array[String]:
	var fragment_ids: Array[String] = []
	var circle_reservations: Array[Dictionary] = []
	for reservation in planning_reservations:
		if SpatialPlanning.reservation_contains_disc(reservation,position,radius): circle_reservations.append(reservation)
	if circle_reservations.is_empty(): return fragment_ids
	for reservation in circle_reservations:
		var source_id := str(reservation.get("reservation_id",reservation.get("id","")))
		var fragments := SpatialPlanning.subtract_disc(reservation["polygon"],position,radius)
		planning_reservations = planning_reservations.filter(func(item: Dictionary) -> bool:
			return str(item.get("reservation_id",item.get("id",""))) != source_id)
		var part := 0
		for polygon in fragments:
			var part_id := "%s-part-%02d" % [source_id,part+1]
			var center := SpatialPlanning.bounds(polygon).get_center()
			planning_reservations.append({"id":part_id,"reservation_id":part_id,"parent_reservation_id":source_id,
				"source_site_id":reservation.get("source_site_id",""),"polygon":polygon,"position":[center.x,center.y],
				"created_phrase":reservation.get("created_phrase",phrase_index),"converted_by":landmark_id})
			fragment_ids.append(part_id)
			part += 1
	_refresh_parcel_index()
	return fragment_ids

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
	var source_reservation := landmark_reservation(position,radius)
	var source_reservation_id := str(operation.get("source_reservation_id",source_reservation.get("reservation_id","")))
	if not source_reservation_id.is_empty() and (source_reservation.is_empty() or str(source_reservation.get("reservation_id","")) != source_reservation_id): return
	if not landmark_site_clear(position,radius,source_reservation_id): return
	var landmark_id := "landmark-%02d" % (landmarks.size()+1)
	var spec := landmark_status(name)
	var landmark := {"id":landmark_id,"name":name,"glyph":str(spec.get("glyph","地")),"era":era,
		"position":[position.x,position.y],"radius":radius,"frame":frame,
		"reveal_frame":frame,"reveal_frames":maxi(1,int(cfg["timing"]["phrase_frames"])/8),
		"voice_level":0.34,"anchor_midi":48,"motif":[],"absorbed_buildings":[],"source_communities":[],"active":false}
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
		var source_community := str(absorbed.get("community_id",""))
		if not source_community.is_empty() and not landmark["source_communities"].has(source_community):
			landmark["source_communities"].append(source_community)
		landmark["motif"].append({"id":str(absorbed["district_id"]),"midi":int(absorbed["current_midi"])})
	if not landmark["motif"].is_empty(): landmark["anchor_midi"] = int(landmark["motif"][0]["midi"])
	landmarks.append(landmark)
	var fragment_ids := _split_landmark_reservation(position,radius,landmark_id)
	landmark_progress[name] = {"streak":2,"awakened":true,"last_phrase":phrase_index}
	rebuild_graph()
	refresh_fabric()
	events.append({"kind":"landmark","id":landmark_id,"name":name,"frame":frame,"absorbed":landmark["absorbed_buildings"].duplicate(),
		"converted_reservation":source_reservation_id,"reservation_fragments":fragment_ids.duplicate()})

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
	elif kind == "charter":
		var reason := Charter.reason(self,operation)
		if not reason.is_empty(): return {"accepted":false,"reason":reason}
		operation = operation.duplicate(true)
		var scope: Array = []
		for cid in operation["community_ids"]:
			if not scope.has(str(cid)): scope.append(str(cid))
		scope.sort()
		operation["community_ids"] = scope
		operation["id"] = "scope:"+",".join(scope)
	elif kind == "retune":
		if not by_id.has(operation.get("id","")): return {"accepted":false,"reason":"请选择一栋建筑"}
	elif kind == "relocate_public":
		var site_id := str(operation.get("id",""))
		var raw_target: Array = operation.get("position",operation.get("target_position",[]))
		if raw_target.size() != 2: return {"accepted":false,"reason":"请选择公共设施的新位置"}
		var target := Vector2(float(raw_target[0]),float(raw_target[1]))
		var relocation := PublicRelocation.preview(self,site_id,target)
		if not bool(relocation.get("accepted",false)): return relocation
		var source_revision := str(operation.get("source_revision",relocation.get("source_revision","")))
		if not source_revision.is_empty() and source_revision != str(relocation.get("source_revision","")):
			return {"accepted":false,"reason":"公共设施所在城市已经变化，请重新查看搬迁预影","source_site_id":site_id}
		operation = operation.duplicate(true)
		operation["id"] = site_id
		operation["position"] = relocation["target_position"].duplicate(true)
		operation["target_position"] = relocation["target_position"].duplicate(true)
		operation["target_polygon"] = relocation["target_polygon"].duplicate()
		operation["target_entrance"] = relocation["target_entrance"].duplicate(true)
		operation["target_access_path"] = relocation.get("target_access_path",PackedVector2Array())
		operation["target_community_id"] = str(relocation.get("target_community_id",relocation.get("target_community", "")))
		operation["source_revision"] = str(relocation.get("source_revision",""))
	elif kind in ["park","civic"] and bool(operation.get("partial",false)):
		var reservation_id := str(operation.get("source_reservation_id",operation.get("reservation_id","")))
		var raw_target: Array = operation.get("position",operation.get("target_position",[]))
		if raw_target.size() != 2: return {"accepted":false,"reason":"请选择局部公共空间的位置"}
		var partial := PartialPublic.preview(self,reservation_id,kind,Vector2(float(raw_target[0]),float(raw_target[1])))
		if not bool(partial.get("accepted",false)): return partial
		var source_revision := str(operation.get("source_revision",partial.get("source_revision","")))
		if not source_revision.is_empty() and source_revision != str(partial.get("source_revision","")):
			return {"accepted":false,"reason":"留地已经变化，请重新查看局部兑现预影","source_reservation_id":reservation_id}
		operation = operation.duplicate(true)
		operation["partial"] = true
		operation["source_reservation_id"] = reservation_id
		operation["position"] = partial["target_position"].duplicate(true)
		operation["target_position"] = partial["target_position"].duplicate(true)
		operation["target_polygon"] = partial["target_polygon"].duplicate()
		operation["target_entrance"] = partial["target_entrance"].duplicate(true)
		operation["target_access_path"] = partial.get("target_access_path",PackedVector2Array())
		operation["source_revision"] = str(partial.get("source_revision",""))
	elif kind == "bridge":
		var bridge_check := bridge_preview()
		if not bool(bridge_check.get("available",false)): return {"accepted":false,"reason":str(bridge_check.get("reason","桥位当前不可用"))}
		if pending_actions.any(func(op: Dictionary) -> bool: return op["kind"] == "bridge"): return {"accepted":false,"reason":"桥已经连接或正在等待落定"}
		var source_topology := str(operation.get("source_topology",bridge_check.get("source_topology","")))
		if not source_topology.is_empty() and source_topology != str(bridge_check.get("source_topology","")):
			return {"accepted":false,"reason":"桥位道路已经变化，请重新查看预影"}
		operation = operation.duplicate(true)
		operation["source_topology"] = str(bridge_check.get("source_topology",""))
		operation["from_node"] = str(bridge_check.get("from_node","west-2"))
		operation["to_node"] = str(bridge_check.get("to_node","east-2"))
		operation["from_position"] = bridge_check.get("from_position",[]).duplicate(true)
		operation["to_position"] = bridge_check.get("to_position",[]).duplicate(true)
	elif kind == "landmark":
		var name := str(operation.get("name",""))
		var status := landmark_status(name)
		if status.is_empty() or bool(status.get("built",false)): return {"accepted":false,"reason":"这座地标当前不可用"}
		if not bool(status.get("awakened",false)): return {"accepted":false,"reason":"地标还需要连续两句满足条件"}
		if pending_actions.any(func(op: Dictionary) -> bool: return op["kind"] == "landmark"): return {"accepted":false,"reason":"已有一座地标等待下一句落成"}
		var site_position := Vector2(float(operation["position"][0]),float(operation["position"][1]))
		var site_radius := float(operation.get("radius",status.get("radius",1.0)))
		var source_reservation := landmark_reservation(site_position,site_radius)
		var source_reservation_id := str(operation.get("source_reservation_id",source_reservation.get("reservation_id","")))
		if not source_reservation_id.is_empty() and (source_reservation.is_empty() or str(source_reservation.get("reservation_id","")) != source_reservation_id): return {"accepted":false,"reason":"这片留地已变化，请重新选择地标位置"}
		if not landmark_site_clear(site_position,site_radius,source_reservation_id): return {"accepted":false,"reason":"预影位置已被道路、公共空间或另一座地标占用"}
		operation = operation.duplicate(true)
		operation["radius"] = site_radius
		operation["era"] = era
		if not source_reservation_id.is_empty(): operation["source_reservation_id"] = source_reservation_id
	elif kind in ["reserve","release_reservation"] or (kind in ["park","civic"] and operation.has("position") and not bool(operation.get("partial",false))):
		if kind == "release_reservation":
			if not planning_reservations.any(func(item: Dictionary) -> bool: return str(item["reservation_id"]) == str(operation.get("id",""))):
				return {"accepted":false,"reason":"这片留地已经释放"}
		elif kind == "reserve" and operation.has("polygon"):
			var raw_polygon_anchor: Array = operation.get("position",[])
			var polygon_anchor := Vector2.INF
			if raw_polygon_anchor.size() == 2: polygon_anchor = Vector2(float(raw_polygon_anchor[0]),float(raw_polygon_anchor[1]))
			var polygon_candidate := SpatialPlanning.polygon_candidate(self,operation["polygon"],polygon_anchor)
			if polygon_candidate.is_empty(): return {"accepted":false,"reason":"自由留地需要一片连续、非自交且完全落在空置地块内的范围"}
			if not bool(polygon_candidate.get("allowed",false)): return {"accepted":false,"reason":str(polygon_candidate.get("reason","这片范围暂时不能留地"))}
			operation = operation.duplicate(true)
			operation["position"] = polygon_candidate["position"].duplicate()
			operation["polygon"] = polygon_candidate["polygon"].duplicate()
			operation["source_site_id"] = polygon_candidate["source_site_id"]
		else:
			var p := Vector2(float(operation["position"][0]),float(operation["position"][1]))
			var candidate := planning_candidate(p)
			if candidate.is_empty(): return {"accepted":false,"reason":"请先选择空置地块、庭院净空或公共候选地"}
			if not bool(candidate["allowed"]): return {"accepted":false,"reason":candidate["reason"]}
			if kind == "reserve" and (candidate.has("reservation_id") or candidate.has("public_id")):
				return {"accepted":false,"reason":"这里已是留地，请选择释放或公共用途"}
			if kind in ["park","civic"] and SpatialPlanning.public_access(self,candidate).is_empty():
				return {"accepted":false,"reason":"公共空间需要能接入道路的真实入口"}
			operation = operation.duplicate(true)
			operation["position"] = candidate["position"].duplicate()
			operation["polygon"] = candidate["polygon"].duplicate()
			operation["source_site_id"] = candidate["source_site_id"]
		# One replaceable planning intent; the historical demo's other queued verbs remain.
		pending_actions = pending_actions.filter(func(op: Dictionary) -> bool:
			return not (str(op["kind"]) in ["reserve","release_reservation","relocate_public"] or (str(op["kind"]) in ["park","civic"] and op.has("position"))))
	elif kind in ["park","civic"]:
		var found := false
		for site in public_sites:
			if site["id"] != operation.get("id","") or site["kind"] != kind: continue
			if not site["active"]: found = true
			elif kind == "civic":
				if int(site.get("service_level",1)) >= 3: return {"accepted":false,"reason":"文化设施已完成三级扩容"}
				found = true
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

func _birth(p: Vector2, midi: int, family: String, root: bool, frame: int, requested_type: String = "") -> String:
	var check := placement(p)
	assert(check["allowed"])
	var id := "building-%05d" % next_id
	next_id += 1
	var type := "residential"
	for lot in lots:
		if lot["id"] == check["lot_id"]: type = str(lot["use"])
	if str(check.get("lot_id","")).is_empty() and requested_type in ["residential","commercial","industrial"]:
		type = requested_type
	var building := {"district_id":id,"position":[p.x,p.y],"footprint":[[p.x,p.y]],"radius":cfg["space"]["residential_radius"],
		"current_midi":midi,"base_midi":midi,"type":type,"vitality":cfg["harmony"]["initial_vitality"],
		"community_id":check["community_id"],"lot_id":check["lot_id"],"placement_tier":str(check.get("tier","L1")),
		"fabric_frontage":int(check.get("frontage",0)),"family_id":family,"anchor_id":family,
		"expression":str(families.get(family,{}).get("expression",profile)),"family_anchor":root,"is_anchor":false,"era":era,"form":"胚","form_count":0,"birth_frame":frame,"voice_level":0.2}
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
	var phase_started := Time.get_ticks_usec()
	settle_profile.clear()
	phrase_index += 1
	_decay_transit_demand()
	_update_landmark_activation(frame)
	update_era(frame)
	var costs: Dictionary = {}
	var buildings_before_growth := buildings.size()
	# Compatibility with preserved direct world probes that assign one pending operation.
	if pending_actions.is_empty() and not pending.is_empty(): pending_actions.append(pending.duplicate(true))
	var committed := pending_actions.duplicate(true)
	pending_actions.clear()
	pending.clear()
	# Public space is reserved before any queued seed or natural growth in this phrase.
	var successful_planning: Array[Dictionary] = []
	for op in committed:
		if str(op["kind"]) == "charter": Charter.commit(self,op,frame)
		if str(op["kind"]) in ["reserve","release_reservation"] or (str(op["kind"]) in ["park","civic"] and op.has("position") and not bool(op.get("partial",false))):
			if SpatialPlanning.commit(self,op,frame): successful_planning.append(op)
			else:
				events.append({"kind":"planning_rejected","operation_kind":str(op.get("kind","")),"event_id":op["event_id"],
					"source_site_id":str(op.get("source_site_id","")),"position":op.get("position",[]).duplicate(true),
					"reason":SpatialPlanning.rejection_reason(self,op),"frame":frame})
		elif str(op["kind"]) == "relocate_public":
			var relocation_result: Dictionary = PublicRelocation.commit(self,op,frame)
			if bool(relocation_result.get("accepted",false)): successful_planning.append(op)
			else:
				events.append({"kind":"planning_rejected","operation_kind":"relocate_public","event_id":op["event_id"],
					"source_site_id":str(op.get("id",op.get("source_site_id",""))),"position":op.get("position",[]).duplicate(true),
					"reason":str(relocation_result.get("reason","公共设施所在城市已经变化，请重新查看搬迁预影")),"frame":frame})
		elif str(op["kind"]) in ["park","civic"] and bool(op.get("partial",false)):
			var partial_result: Dictionary = PartialPublic.commit(self,op,frame)
			if bool(partial_result.get("accepted",false)): successful_planning.append(op)
			else:
				events.append({"kind":"planning_rejected","operation_kind":str(op["kind"]),"event_id":op["event_id"],
					"source_reservation_id":str(op.get("source_reservation_id","")),"position":op.get("position",[]).duplicate(true),
					"reason":str(partial_result.get("reason","局部兑现条件已失效，请重新查看预影")),"frame":frame})
	for op in committed:
		assert(int(op["frame"]) == frame)
		if str(op["kind"]) in ["charter","reserve","release_reservation","relocate_public"] or (str(op["kind"]) in ["park","civic"] and op.has("position")): continue
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
				var bridge_check := bridge_preview()
				var source_topology := str(op.get("source_topology",""))
				if not bool(bridge_check.get("available",false)) or (not source_topology.is_empty() and source_topology != str(bridge_check.get("source_topology",""))):
					events.append({"kind":"planning_rejected","operation_kind":"bridge","event_id":op["event_id"],
						"source_site_id":"river-bridge","position":op.get("from_position",[]).duplicate(true),
						"reason":"桥位道路在乐句边界前已变化，请重新查看两岸预影","frame":frame})
					continue
				bridge = true
				var from_node := str(op.get("from_node","west-2"))
				var to_node := str(op.get("to_node","east-2"))
				var a: Array = nodes[from_node]
				var b: Array = nodes[to_node]
				roads.append({"id":"river-bridge","from":from_node,"to":to_node,"path":PackedVector2Array([Vector2(a[0],a[1]),Vector2(b[0],b[1])]),"bridge":true})
				rebuild_graph()
				network.rebuild(nodes,roads,terrain)
				events.append({"kind":"bridge","frame":frame,"from_node":from_node,"to_node":to_node,
					"source_topology":str(op.get("source_topology","")),"community_ids":["west-2","east-2"],
					"road_ids":bridge_check.get("road_ids",[]).duplicate(true),"traffic":"两岸联奏线","role":"连接两岸道路与公共服务"})
			"landmark":
				_commit_landmark(op,frame)
			"park","civic":
				for site in public_sites:
					if site["id"] != op["id"]: continue
					if bool(site["active"]) and op["kind"] == "civic":
						site["service_level"] = mini(3,int(site.get("service_level",1))+1)
					else:
						site["active"] = true
						site["frame"] = frame
						events.append({"kind":op["kind"],"id":site["id"],"frame":frame})
	# Facility actions become available to the same phrase's growth search.
	if committed.any(func(op: Dictionary) -> bool: return str(op["kind"]) in ["civic","park","relocate_public"]):
		_refresh_public_service()
	if not lifecycle["ended"]:
		for family in families:
			if int(families[family]["created_phrase"]) == phrase_index: continue
			_grow(family,frame)
	settle_profile["actions_growth_ms"] = float(Time.get_ticks_usec()-phase_started)/1000.0
	phase_started = Time.get_ticks_usec()
	var split_events := split_oversized_communities(frame)
	settle_profile["split_ms"] = float(Time.get_ticks_usec()-phase_started)/1000.0
	phase_started = Time.get_ticks_usec()
	var musical_action := committed.any(func(op: Dictionary) -> bool:
		return str(op["kind"]) not in ["charter","reserve","release_reservation"] and not (str(op["kind"]) in ["park","civic"] and op.has("position")))
	musical_action = musical_action or successful_planning.any(func(op: Dictionary) -> bool: return str(op["kind"]) in ["park","civic","relocate_public"])
	var forms_dirty := musical_action or buildings.size() != buildings_before_growth or not split_events.is_empty()
	var modifiers := musicality()
	var effective := musical_edges(modifiers)
	resonance = coupling.resonance(buildings,effective)
	# River call/response is an audible relationship. It does not grant automatic
	# growth vitality; otherwise filling both banks becomes the dominant strategy.
	var vitalities := coupling.vitality(buildings,effective,resonance,costs,modifiers)
	for building in buildings: building["vitality"] = vitalities[building["district_id"]]
	for building in buildings:
		var bonus := landmark_vitality_bonus(Coupling.position_of(building))+landmark_commercial_bonus(building)
		if bonus > 0.0:
			building["vitality"] = minf(float(cfg["harmony"]["maximum_vitality"]),float(building["vitality"])+bonus)
	if forms_dirty: _update_forms(frame,modifiers)
	_advance_landmark_progress(frame)
	if resonance < float(cfg["harmony"]["gray_entry"]): lifecycle["gray"] = true
	elif resonance > float(cfg["harmony"]["gray_exit"]): lifecycle["gray"] = false
	lifecycle["low_phrases"] = int(lifecycle["low_phrases"])+1 if resonance < float(cfg["harmony"]["gray_entry"]) else 0
	lifecycle["ended"] = mode != "free" and int(lifecycle["low_phrases"]) >= int(cfg["harmony"]["collapse_phrases"])
	settle_profile["music_forms_ms"] = float(Time.get_ticks_usec()-phase_started)/1000.0
	phase_started = Time.get_ticks_usec()
	_refresh_public_network(frame)
	settle_profile["public_network_ms"] = float(Time.get_ticks_usec()-phase_started)/1000.0
	phase_started = Time.get_ticks_usec()
	# Theme eligibility consumes real frontage and courtyards, so changed geometry
	# must be current at this audible phrase rather than a phrase-old visual hint.
	var geometry_action := committed.any(func(op: Dictionary) -> bool: return str(op["kind"]) in ["seed","bridge","landmark","park","civic","reserve","release_reservation","relocate_public"])
	if buildings.size() != buildings_before_growth or not split_events.is_empty() or geometry_action: refresh_fabric()
	settle_profile["fabric_ms"] = float(Time.get_ticks_usec()-phase_started)/1000.0
	_commit_transit_flow()

func _transit_growth_bonus(position: Vector2,use: String = "residential") -> float:
	var bonus := 0.0
	for line in transit_lines:
		for stop_id in line.get("stops",[]):
			if not network.nodes.has(str(stop_id)): continue
			var node: Array = network.nodes[str(stop_id)]
			var stop_position := Vector2(float(node[0]),float(node[1]))
			var distance := position.distance_to(stop_position)
			if distance > 4.5: continue
			var local := (4.5-distance)/4.5
			if use in ["commercial","industrial"]: local *= 1.35
			if line.get("transfer_stops",[]).any(func(transfer: Dictionary) -> bool: return str(transfer.get("stop_id","")) == str(stop_id)):
				local += 0.75
			bonus = maxf(bonus,local)
	return bonus

func community_land_use_quota(cid: String) -> Dictionary:
	var result := {"residential":0,"commercial":0,"industrial":0}
	if not communities.has(cid): return result
	var member_count: int = communities[cid].get("members",[]).size()
	var has_commercial_anchor := false
	var has_industrial_anchor := false
	for lot in lots:
		if str(lot.get("community_id","")) != cid: continue
		if str(lot.get("use","")) == "commercial": has_commercial_anchor = true
		if str(lot.get("use","")) == "industrial": has_industrial_anchor = true
	result["residential"] = maxi(2,mini(6,2+member_count/18))
	if has_commercial_anchor: result["commercial"] = mini(4,2+member_count/20)
	if has_industrial_anchor: result["industrial"] = mini(4,2+member_count/16)
	return result

func _near_use_anchor(cid: String,position: Vector2,use: String) -> bool:
	for lot in lots:
		if str(lot.get("community_id","")) != cid or str(lot.get("use","")) != use: continue
		var anchor := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if position.distance_to(anchor) <= 5.0: return true
	return false

func _growth_use_for_candidate(cid: String,position: Vector2,requested: String,quota: Dictionary = {},usage: Dictionary = {}) -> String:
	if requested != "residential": return requested
	if quota.is_empty(): quota = community_land_use_quota(cid)
	if usage.is_empty(): usage = _community_usage(cid)
	if int(quota.get("industrial",0)) > int(usage.get("industrial",0)) and _near_use_anchor(cid,position,"industrial"):
		return "industrial"
	if int(quota.get("commercial",0)) > int(usage.get("commercial",0)) and _near_use_anchor(cid,position,"commercial"):
		return "commercial"
	return requested

func _land_use_quota_bonus(cid: String,use: String) -> float:
	var quota := community_land_use_quota(cid)
	var usage := _community_usage(cid)
	return maxf(0.0,float(int(quota.get(use,0))-int(usage.get(use,0)))) if quota.has(use) else 0.0

func _public_service_growth_bonus(cid: String,position: Vector2) -> float:
	if not communities.has(cid): return 0.0
	var bonus := 0.0
	for site in public_sites:
		if not bool(site.get("active",false)) or str(site.get("kind","")) != "civic": continue
		var capacity := int(site.get("service_capacity",18))
		var spare: int = capacity-site.get("served",[]).size()
		if spare <= 0: continue
		var site_position := Vector2(float(site["entrance"][0]),float(site["entrance"][1]))
		if position.distance_to(site_position) > float(cfg["city"]["service_walk_radius"]): continue
		if network.walking_distance(site_position,position) > float(cfg["city"]["service_walk_radius"]): continue
		bonus = maxf(bonus,float(spare)/float(capacity))
	return bonus

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
	# Revisit older pockets as well as the newest edge; bounded samples avoid all-history growth.
	for sample in range(4):
		if owned_positions.is_empty(): break
		var old_point := owned_positions[mini(owned_positions.size()-1,sample*owned_positions.size()/4)]
		if not frontier.has(old_point): frontier.append(old_point)
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
	var best_growth_score := -INF
	var quotas: Dictionary = {}
	var usages: Dictionary = {}
	for candidate in candidates:
		var p: Vector2 = Vector2(candidate["position"])
		var check := placement(p)
		if not check["allowed"]: continue
		var cid := str(check.get("community_id",""))
		if not quotas.has(cid):
			quotas[cid] = community_land_use_quota(cid)
			usages[cid] = _community_usage(cid)
		var candidate_use := _growth_use_for_candidate(cid,p,str(candidate.get("use","residential")),quotas[cid],usages[cid])
		var tier_rank := 3 if check["tier"] == "L1" else (2 if check["tier"] == "L2" else 1)
		var distance := p.distance_squared_to(origin)
		var transit_bonus := _transit_growth_bonus(p,candidate_use)
		var quota_bonus := maxf(0.0,float(int(quotas[cid].get(candidate_use,0))-int(usages[cid].get(candidate_use,0))))
		var compact_neighbors := 0
		for neighbor_id in index.query_circle(p,1.35):
			var neighbor: Dictionary = by_id[neighbor_id]
			if p.distance_to(Coupling.position_of(neighbor)) > 1.8: continue
			if str(neighbor["community_id"]) == cid or str(neighbor["family_id"]) == family: compact_neighbors += 1
		var compact_bonus := float(mini(6,compact_neighbors))*float(cfg["city"].get("growth_compact_neighbor_weight",10000.0))
		var planning_bonus := Charter.growth_bonus(self,cid,p,compact_neighbors)
		var base_score := float(tier_rank)*100000.0+compact_bonus+quota_bonus*1000.0+transit_bonus*100.0+planning_bonus-distance
		# Exact upper bound: acoustic checks cannot rescue a candidate whose
		# placement score plus the maximum civic bonus cannot beat the winner.
		if base_score+50.0 <= best_growth_score: continue
		var connected := false
		for owned in buildings:
			if owned["family_id"] != family: continue
			var op := Coupling.position_of(owned)
			if p.distance_to(op) <= 2.4 and float(road_environment(p,op)["occlusion"]) > 0.0 and not frozen(owned["district_id"]):
				connected = true
				break
		connected = landmark_growth_connected(p,connected)
		if not connected: continue
		var clashes := false
		var ranked: Array = []
		var probe := {"position":[p.x,p.y],"radius":cfg["space"]["residential_radius"],"type":candidate_use,"current_midi":root["current_midi"],"placement_tier":check["tier"]}
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
		var service_bonus := _public_service_growth_bonus(str(check.get("community_id","")),p)
		# Tier remains primary; compact community infill precedes use/transit/service ties.
		# This placement preference does not alter acoustic coupling or R/V.
		var growth_score := base_score+service_bonus*50.0
		if growth_score > best_growth_score:
			best_growth_score = growth_score
			best_rank = tier_rank
			best_distance = distance
			best = {"position":p,"transit_bonus":transit_bonus,"quota_bonus":quota_bonus,"service_bonus":service_bonus,"use":candidate_use}
			best_check = check
	if best.is_empty():
		last_reason = "这一家族暂缺可达空地；可以在另一侧播种新主题"
		return
	var p: Vector2 = best["position"]
	_birth(p,int(root["current_midi"]),family,false,frame,str(best.get("use","residential")))
	var charter := Charter.for_community(self,str(best_check["community_id"]))
	if not charter.is_empty():
		events.back()["charter_id"] = charter["charter_id"]
		events.back()["plan_id"] = charter["plan_id"]
		events.back()["card_refs"] = charter.get("card_refs",[]).duplicate()
	var growth_delay := Charter.growth_delay(self,str(best_check.get("community_id","")),p,int(best_check.get("growth_delay",1)),str(best_check.get("tier","L1")))
	families[family]["next_growth_phrase"] = phrase_index+growth_delay


func _community_adjacency(ids: Array) -> Dictionary:
	var adjacency: Dictionary = {}
	for raw_id in ids:
		adjacency[str(raw_id)] = []
	for i in range(ids.size()):
		var a_id := str(ids[i])
		if not by_id.has(a_id): continue
		var a: Dictionary = by_id[a_id]
		for j in range(i+1,ids.size()):
			var b_id := str(ids[j])
			if not by_id.has(b_id): continue
			var b: Dictionary = by_id[b_id]
			# Planning adjacency is local enough to read as one connected neighborhood;
			# the acoustic cutoff remains wider and is not reused as a district boundary.
			var max_gap := minf(float(cfg["space"]["gap_cutoff"])+float(a["radius"])+float(b["radius"]),3.2)
			if Coupling.position_of(a).distance_to(Coupling.position_of(b)) > max_gap: continue
			var environment := road_environment(Coupling.position_of(a),Coupling.position_of(b))
			if float(environment.get("occlusion",1.0)) <= 0.0: continue
			if coupling.coefficient(a,b,environment) <= 0.0: continue
			adjacency[a_id].append(b_id)
			adjacency[b_id].append(a_id)
	for id in adjacency:
		adjacency[id].sort()
	return adjacency

func _community_components(ids: Array, adjacency: Dictionary) -> Array:
	var remaining: Dictionary = {}
	for raw_id in ids: remaining[str(raw_id)] = true
	var components: Array = []
	while not remaining.is_empty():
		var keys := remaining.keys()
		keys.sort()
		var start := str(keys[0])
		var queue: Array[String] = [start]
		remaining.erase(start)
		var component: Array[String] = []
		while not queue.is_empty():
			var current: String = str(queue.pop_front())
			component.append(current)
			for next in adjacency.get(current,[]):
				if remaining.has(next):
					remaining.erase(next)
					queue.append(str(next))
		component.sort()
		components.append(component)
	return components

func _community_split_seeds(component: Array, count: int) -> Array:
	var ordered: Array = component.duplicate()
	ordered.sort()
	var seeds: Array = [str(ordered[0])]
	while seeds.size() < count:
		var best_id := ""
		var best_distance := -1.0
		for raw_id in ordered:
			var id := str(raw_id)
			if seeds.has(id): continue
			var nearest := INF
			for seed in seeds:
				if not by_id.has(seed): continue
				nearest = minf(nearest,Coupling.position_of(by_id[id]).distance_to(Coupling.position_of(by_id[seed])))
			if nearest > best_distance or (is_equal_approx(nearest,best_distance) and (best_id.is_empty() or id < best_id)):
				best_id = id
				best_distance = nearest
		if best_id.is_empty(): break
		seeds.append(best_id)
	return seeds

func _community_distance_to_group(id: String, group: Array) -> float:
	if not by_id.has(id): return INF
	var position := Coupling.position_of(by_id[id])
	var nearest := INF
	for member in group:
		if by_id.has(str(member)):
			nearest = minf(nearest,position.distance_to(Coupling.position_of(by_id[str(member)])))
	return nearest

func _community_grow_partition(component: Array, adjacency: Dictionary, max_members: int) -> Array:
	var group_count := maxi(2,ceili(float(component.size())/float(max_members)))
	var seeds := _community_split_seeds(component,group_count)
	var groups: Array = []
	var assigned: Dictionary = {}
	for seed in seeds:
		groups.append({"members":[seed]})
		assigned[seed] = true
	while assigned.size() < component.size():
		var best_group := -1
		var best_id := ""
		var best_size := INF
		var best_distance := INF
		for group_index in range(groups.size()):
			var group: Dictionary = groups[group_index]
			var members: Array = group["members"]
			if members.size() >= max_members: continue
			var frontier: Array = []
			for member in members:
				for candidate in adjacency.get(str(member),[]):
					var candidate_id := str(candidate)
					if assigned.has(candidate_id) or frontier.has(candidate_id): continue
					frontier.append(candidate_id)
			for candidate_id in frontier:
				var distance := _community_distance_to_group(candidate_id,members)
				if members.size() < best_size or (members.size() == best_size and (distance < best_distance or (is_equal_approx(distance,best_distance) and (best_id.is_empty() or candidate_id < best_id)))):
					best_group = group_index
					best_id = candidate_id
					best_size = members.size()
					best_distance = distance
		if best_group < 0:
			# Connected components are normally handled separately. This fallback
			# keeps an isolated node deterministic when a plan has a hard gap.
			for candidate in component:
				var candidate_id := str(candidate)
				if assigned.has(candidate_id): continue
				for group_index in range(groups.size()):
					if groups[group_index]["members"].size() < max_members:
						best_group = group_index
						best_id = candidate_id
						break
				if best_group >= 0: break
		if best_group < 0 or best_id.is_empty(): break
		groups[best_group]["members"].append(best_id)
		assigned[best_id] = true
	var partitions: Array = []
	for group in groups:
		var members: Array = group["members"]
		members.sort()
		partitions.append(members)
	return partitions

func _community_partitions(ids: Array, max_members: int) -> Array:
	var adjacency := _community_adjacency(ids)
	var partitions: Array = []
	for component in _community_components(ids,adjacency):
		if component.size() <= max_members:
			partitions.append(component)
		else:
			partitions.append_array(_community_grow_partition(component,adjacency,max_members))
	return partitions

func _community_centroid(ids: Array) -> Vector2:
	if ids.is_empty(): return Vector2.ZERO
	var center := Vector2.ZERO
	var count := 0
	for id in ids:
		if not by_id.has(str(id)): continue
		center += Coupling.position_of(by_id[str(id)])
		count += 1
	return center/float(maxi(1,count))

func _nearest_child_for(position: Vector2, child_ids: Array, child_centers: Dictionary) -> String:
	var nearest := ""
	var best_distance := INF
	for raw_id in child_ids:
		var id := str(raw_id)
		var distance := position.distance_squared_to(child_centers[id])
		if distance < best_distance or (is_equal_approx(distance,best_distance) and (nearest.is_empty() or id < nearest)):
			nearest = id
			best_distance = distance
	return nearest

func split_oversized_communities(frame: int) -> Array:
	var max_members := int(cfg["space"].get("community_max",40))
	var candidates: Array = []
	for cid in communities:
		var community: Dictionary = communities[cid]
		if not bool(community.get("active",true)): continue
		if not community.get("split_children",[]).is_empty(): continue
		var members: Array = community.get("members",[])
		if members.size() > max_members: candidates.append(str(cid))
	var split_events: Array = []
	for cid in candidates:
		if not communities.has(cid): continue
		var parent: Dictionary = communities[cid]
		var partitions := _community_partitions(parent["members"],max_members)
		if partitions.size() < 2: continue
		var child_ids: Array = []
		var child_centers: Dictionary = {}
		for index in range(partitions.size()):
			var child_id := "%s/%02d" % [cid,index+1]
			var suffix := 2
			while communities.has(child_id):
				child_id = "%s/%02d-%d" % [cid,index+1,suffix]
				suffix += 1
			var child: Dictionary = parent.duplicate(true)
			child["id"] = child_id
			child["name"] = str(parent.get("name",cid))+"·"+str(index+1)
			child["parent_id"] = cid
			child["members"] = partitions[index].duplicate()
			child["split_children"] = []
			child["split_index"] = index
			child["active"] = true
			child.erase("center_id")
			child.erase("center_level")
			communities[child_id] = child
			child_ids.append(child_id)
			child_centers[child_id] = _community_centroid(partitions[index])
			for member_id in partitions[index]:
				if by_id.has(str(member_id)):
					by_id[str(member_id)]["community_id"] = child_id
		parent["members"] = []
		parent["split_children"] = child_ids.duplicate()
		parent["active"] = false
		parent["is_parent"] = true
		parent["split_frame"] = frame
		for lot in lots:
			if str(lot.get("community_id","")) != cid: continue
			var lot_position := Vector2(float(lot["center"][0]),float(lot["center"][1]))
			lot["community_id"] = _nearest_child_for(lot_position,child_ids,child_centers)
		for site in public_sites:
			if str(site.get("community_id","")) != cid: continue
			var site_position := Vector2(float(site["position"][0]),float(site["position"][1]))
			site["community_id"] = _nearest_child_for(site_position,child_ids,child_centers)
		for block in blocks:
			if str(block.get("community_id","")) != cid: continue
			var block_position := Vector2.ZERO
			var block_polygon: PackedVector2Array = block.get("polygon",PackedVector2Array())
			for point in block_polygon: block_position += point
			if not block_polygon.is_empty(): block_position /= float(block_polygon.size())
			block["community_id"] = _nearest_child_for(block_position,child_ids,child_centers)
		for center in centers:
			if str(center.get("community_id","")) != cid: continue
			var center_position := Vector2(float(center["position"][0]),float(center["position"][1]))
			var assigned := _nearest_child_for(center_position,child_ids,child_centers)
			center["community_id"] = assigned
			communities[assigned]["center_id"] = center["id"]
			communities[assigned]["center_level"] = center["level"]
		rebuild_graph()
		refresh_fabric()
		var event := {"kind":"community_split","community":cid,"children":child_ids.duplicate(),"counts":[],"frame":frame}
		for child_id in child_ids: event["counts"].append(communities[child_id]["members"].size())
		events.append(event)
		split_events.append(event)
	return split_events

func incident_edges(id: String) -> Array:
	if incident_edge_cache.has(id): return incident_edge_cache[id]
	var nearby: Array = []
	var building: Dictionary = by_id[id]
	for other_id in index.query_circle(Coupling.position_of(building),float(building["radius"])+float(cfg["space"]["gap_cutoff"])):
		if other_id == id: continue
		var pair := [id,other_id]
		pair.sort()
		var key := str(pair[0])+":"+str(pair[1])
		if edge_cache.has(key): nearby.append(edge_cache[key])
	incident_edge_cache[id] = nearby
	return nearby

func near_edges(id: String) -> Array:
	if near_edge_cache.has(id): return near_edge_cache[id]
	var nearby := incident_edges(id).duplicate()
	nearby.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a["coupling"] != b["coupling"]: return a["coupling"] > b["coupling"]
		return str(a["a"])+":"+str(a["b"]) < str(b["a"])+":"+str(b["b"]))
	near_edge_cache[id] = nearby.slice(0,int(cfg["space"]["near_neighbour_count"]))
	return near_edge_cache[id]

func frozen(id: String) -> bool:
	if not by_id.has(id): return false
	if landmark_allows_dissonance(Coupling.position_of(by_id[id])): return false
	for edge in near_edges(id):
		var other: String = edge["b"] if edge["a"] == id else edge["a"]
		if float(coupling.interval(int(by_id[id]["current_midi"]),int(by_id[other]["current_midi"]))["score"]) <= 0.05: return true
	return false

func _update_forms(frame: int, modifiers: Dictionary = {}) -> void:
	if modifiers.is_empty(): modifiers = musicality()
	for building in buildings:
		if building["form"] not in ["胚","群"]:
			building["form_count"] = 0
			continue
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
		var target := ""
		var duration := 2
		if building["form"] == "胚" and good >= 2 and near >= 3:
			var local_edges: Array = []
			for edge in incident_edges(building["district_id"]):
				var copy: Dictionary = edge.duplicate()
				copy["coupling"] = float(edge["coupling"])*minf(float(modifiers[edge["a"]]["M"]),float(modifiers[edge["b"]]["M"]))
				local_edges.append(copy)
			if coupling.resonance_from_index(by_id,local_edges) >= 60.0: target = "群"
		elif building["form"] == "群" and str(building.get("placement_tier","L1")) != "L3":
			if good >= 3 and scores.has(1.0) and near >= 6:
				target = "央"
				duration = 3
			elif good >= 3 and good == scores.size(): target = "腔"
			if not target.is_empty():
				duration = landmark_upgrade_duration(building,duration)
		building["form_count"] = int(building["form_count"])+1 if not target.is_empty() else 0
		if not target.is_empty() and int(building["form_count"]) >= duration:
			building["form"] = target
			building["form_count"] = 0
			events.append({"kind":"upgrade","district_id":building["district_id"],"frame":frame,"form":target})

func snapshot() -> Dictionary:
	return {"schema_version":2,"generation_version":136,"settings":cfg.duplicate(true),"planning_reservations":planning_reservations.duplicate(true),"development_charters":development_charters.duplicate(true),
		"terrain_state":{"noise_seed":terrain.noise_seed,"river_phase":terrain.river_phase,"family":terrain.family},
		"plan":{"lots":lots.duplicate(true),"roads":roads.duplicate(true),"nodes":nodes.duplicate(true),"blocks":blocks.duplicate(true),"green_corridors":green_corridors.duplicate(true),"centers":centers.duplicate(true),"communities":communities.duplicate(true)},
		"transit":transit.duplicate(true),"transit_lines":transit_lines.duplicate(true),"transit_demand":transit_demand.duplicate(true),"transit_flow_pending":transit_flow_pending.duplicate(true),"functional_zones":functional_zones.duplicate(true),"mode":mode,"profile":profile,"action_serial":action_serial,"public_sites":public_sites.duplicate(true),"landmarks":landmarks.duplicate(true),"landmark_progress":landmark_progress.duplicate(true),"pending_actions":pending_actions.duplicate(true),"seed_hex":rng.seed_hex,"rng":rng.snapshot(),"buildings":buildings.duplicate(true),
		"pending":pending.duplicate(true),"events":events.duplicate(true),"bridge":bridge,"phrase_index":phrase_index,"era":era,"expanded_plan":expanded_plan,
		"next_id":next_id,"families":families.duplicate(true),"lifecycle":lifecycle.duplicate(true),"last_reason":last_reason}

static func _geometry_from_json(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array: return value
	var polygon := PackedVector2Array()
	for point in value: polygon.append(point if point is Vector2 else Vector2(float(point[0]),float(point[1])))
	return polygon

func _restore_geometry() -> void:
	for group in [lots,blocks,public_sites,planning_reservations]:
		for item in group:
			if item.has("polygon"): item["polygon"] = _geometry_from_json(item["polygon"])
			if item.has("access_path"): item["access_path"] = _geometry_from_json(item["access_path"])
	for group in [roads,green_corridors,transit_lines]:
		for item in group:
			if item.has("path"): item["path"] = _geometry_from_json(item["path"])
			for leg in item.get("legs",[]): leg["path"] = _geometry_from_json(leg["path"])
	for item in pending_actions:
		if item.has("polygon"): item["polygon"] = _geometry_from_json(item["polygon"])
		if item.has("target_polygon"): item["target_polygon"] = _geometry_from_json(item["target_polygon"])
		if item.has("target_access_path"): item["target_access_path"] = _geometry_from_json(item["target_access_path"])
	if pending.has("polygon"): pending["polygon"] = _geometry_from_json(pending["polygon"])
	if pending.has("target_polygon"): pending["target_polygon"] = _geometry_from_json(pending["target_polygon"])
	if pending.has("target_access_path"): pending["target_access_path"] = _geometry_from_json(pending["target_access_path"])

func restore(saved: Dictionary, rebuild_derived: bool = true) -> void:
	assert(int(saved["schema_version"]) == 2 and saved["seed_hex"] == rng.seed_hex)
	environment_cache = {}
	environment_pending = {}
	edge_cache = {}
	road_index_identity = ""
	parcel_index_identity = ""
	fabric_anchor_cache.clear()
	fabric_geometry_identity = ""
	incident_edge_cache.clear()
	near_edge_cache.clear()
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
		transit_demand = saved.get("transit_demand",{}).duplicate(true)
		transit_flow_pending.assign(saved.get("transit_flow_pending",[]).duplicate(true))
		functional_zones.assign(saved.get("functional_zones",[]).duplicate(true))
	buildings.assign(saved["buildings"].duplicate(true))
	by_id.clear()
	index = Index.new()
	families.clear()
	for community in communities.values(): community["members"].clear()
	# Restore occupancy in linear passes. Preserve every matching lot and the
	# original last-building-wins order, without searching all lots per house.
	var building_occupants: Dictionary = {}
	for building in buildings:
		var id: String = building["district_id"]
		by_id[id] = building
		index.put(id,Coupling.position_of(building),float(building["radius"]))
		communities[building["community_id"]]["members"].append(id)
		building_occupants[building["lot_id"]] = id
	for lot in lots: lot["occupant"] = building_occupants.get(lot["id"],"")
	families = saved["families"].duplicate(true)
	pending = saved["pending"].duplicate(true)
	pending_actions.assign(saved.get("pending_actions",[]).duplicate(true))
	mode = str(saved.get("mode","free"))
	profile = str(saved.get("profile","bright"))
	action_serial = int(saved.get("action_serial",0))
	if saved.has("public_sites"): public_sites.assign(saved["public_sites"].duplicate(true))
	planning_reservations.assign(saved.get("planning_reservations",[]).duplicate(true))
	development_charters.assign(saved.get("development_charters",[]).duplicate(true))
	landmarks.assign(saved.get("landmarks",[]).duplicate(true))
	landmark_progress = saved.get("landmark_progress",{}).duplicate(true)
	_restore_geometry()
	var landmark_occupants: Dictionary = {}
	for landmark in landmarks: landmark_occupants[str(landmark.get("id",""))] = str(landmark["id"])
	for lot in lots:
		var landmark_id := str(lot.get("landmark_id",""))
		if landmark_occupants.has(landmark_id): lot["occupant"] = landmark_occupants[landmark_id]
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
	if not rebuild_derived:
		_refresh_road_index()
		network.rebuild(nodes,roads,terrain)
		return
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
	var coverage_started := Time.get_ticks_usec()
	public_service_cache.clear()
	network.rebuild(nodes,roads,terrain)
	_refresh_road_index()
	var lots_by_id: Dictionary = {}
	for lot in lots: lots_by_id[str(lot["id"])] = lot
	for site in public_sites:
		var covered: Array[String] = []
		if site["active"]:
			var entrance := Vector2(site["entrance"][0],site["entrance"][1])
			for building in buildings:
				var lot: Dictionary = lots_by_id.get(str(building["lot_id"]),{})
				var p := Coupling.position_of(building) if lot.is_empty() else Vector2(lot["entrance"][0],lot["entrance"][1])
				var radius := float(cfg["city"]["service_walk_radius"])
				if entrance.distance_squared_to(p) > radius*radius: continue
				if network.walking_distance(entrance,p) <= radius: covered.append(building["district_id"])
		site["covered"] = covered
	settle_profile["coverage_ms"] = float(Time.get_ticks_usec()-coverage_started)/1000.0
	coverage_started = Time.get_ticks_usec()
	_refresh_public_service()
	settle_profile["service_allocation_ms"] = float(Time.get_ticks_usec()-coverage_started)/1000.0
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
	for reach in range(1,int(cfg["city"].get("regional_count",1))):
		var prefix := "reach-%d-" % reach
		var previous := "" if reach == 1 else "reach-%d-" % (reach-1)
		for side: String in ["west","east"]:
			if not public_sites.any(func(site: Dictionary) -> bool: return site["id"] == prefix+side+"-civic" and site["active"]): continue
			var itinerary: Array = [previous+side+"-4",prefix+side+"-1",prefix+side+"-2",prefix+side+"-3",prefix+side+"-4",prefix+side+"-outer-3",prefix+side+"-outer-2",prefix+side+"-outer-1",prefix+side+"-1",previous+side+"-4"]
			lines.append(_make_transit_line(prefix+side+"-line","河段接驳线%d" % reach,itinerary,frame))
	transit_lines.assign(lines)
	_annotate_transfers()
	refresh_functional_zones()
	transit = transit_lines[0] if not transit_lines.is_empty() else {}

func _annotate_transfers() -> void:
	for index in range(transit_lines.size()):
		var transfers: Array[Dictionary] = []
		var stops: Array = transit_lines[index].get("stops",[])
		for other_index in range(transit_lines.size()):
			if other_index == index: continue
			var other: Dictionary = transit_lines[other_index]
			for stop in stops:
				if not other.get("stops",[]).has(stop): continue
				transfers.append({"stop_id":str(stop),"line_id":str(other.get("id","")),"line_index":other_index,"name":str(other.get("name",""))})
		transfers.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if str(a.get("stop_id","")) != str(b.get("stop_id","")):
				return str(a.get("stop_id","")) < str(b.get("stop_id",""))
			return int(a.get("line_index",-1)) < int(b.get("line_index",-1)))
		transit_lines[index]["transfer_stops"] = transfers

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

static func regional_sample() -> ContinuousWorld:
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/demo_regional_city.json"))
	var raw := Marshalls.base64_to_raw(record["world_zstd_base64"]).decompress(int(record["world_bytes"]),FileAccess.COMPRESSION_ZSTD)
	var saved: Dictionary = bytes_to_var(raw)
	var city := ContinuousWorld.new(saved["seed_hex"],false)
	city.restore(saved)
	return city

func build_regional_town(count: int = 3) -> void:
	if int(cfg["city"].get("regional_count",1)) > 1: return
	expand_plan()
	preload("res://scripts/world/regional_neighborhood.gd").populate(self,count)
	build_town()

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

func community_theme_sources(cid: String) -> Array:
	var members: Array = communities[cid]["members"].duplicate()
	members.sort_custom(func(a: String,b: String) -> bool:
		var aa := Coupling.position_of(by_id[a])
		var bb := Coupling.position_of(by_id[b])
		if aa.x+aa.y != bb.x+bb.y: return aa.x+aa.y < bb.x+bb.y
		return a < b)
	# Historical motif notes have no surviving house; they cannot fabricate a
	# current cross-river spatial relation.
	var sources: Array = []
	sources.resize(community_theme(cid).size()-members.size())
	sources.fill("")
	sources.append_array(members)
	return sources

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
		notes.append(pitch)
	# A landmark rewrites its source community around the absorbed motif. Keep
	# the motif first and stable across saves, then let surviving members answer it.
	var lineage: Array = [cid]
	var lineage_cursor: String = cid
	while communities.has(lineage_cursor):
		var parent_id := str(communities[lineage_cursor].get("parent_id",""))
		if parent_id.is_empty() or lineage.has(parent_id): break
		lineage.append(parent_id)
		lineage_cursor = parent_id
	var motif_notes: Array = []
	for source_cid in lineage:
		for landmark in landmarks:
			var source_communities: Array = landmark.get("source_communities",[])
			if not source_communities.has(source_cid): continue
			for motif_entry in landmark.get("motif",[]):
				var motif_pitch := int(motif_entry.get("midi",0))
				if not motif_notes.has(motif_pitch): motif_notes.append(motif_pitch)
	if motif_notes.is_empty(): return notes
	var composed: Array = motif_notes.duplicate()
	composed.append_array(notes)
	return composed
