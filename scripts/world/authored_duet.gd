extends RefCounted
## Current two-bank authorship and legal spatial opportunities. This query
## never plants a house, chooses a pitch, grants maturity or claims a Reply.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")
const SpatialPlanning = preload("res://scripts/world/city_spatial_planning.gd")

static func _bank(world: RefCounted,p: Vector2) -> int:
	return int(signf(p.x-world.terrain.river_x(p.y)))

static func roots(world: RefCounted,pitches: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_family in world.families:
		var family: Dictionary = world.families[raw_family]
		if not bool(family.get("player_expression",false)): continue
		var id := str(family.get("root",""))
		var root: Dictionary = world.by_id.get(id,{})
		if root.is_empty() or str(root.get("family_id","")) != str(raw_family): continue
		var p := Coupling.position_of(root)
		var members: Array[String] = []
		for house: Dictionary in world.buildings:
			if str(house.get("family_id","")) == str(raw_family): members.append(str(house["district_id"]))
		result.append({"root_id":id,"family_id":str(raw_family),"community_id":str(root["community_id"]),"community_name":str(world.communities.get(str(root["community_id"]),{}).get("name",root["community_id"])),
			"position":root["position"].duplicate(),"expression":str(family.get("expression","")),
			"current_midi":int(pitches.get(id,root["current_midi"])),"bank":_bank(world,p),
			"birth_frame":int(root.get("birth_frame",0)),"member_ids":members})
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if int(a["birth_frame"]) != int(b["birth_frame"]): return int(a["birth_frame"]) < int(b["birth_frame"])
		return str(a["root_id"]) < str(b["root_id"]))
	return result

static func _pool_add(pool: Array[Vector2],p: Vector2) -> void:
	if pool.all(func(other: Vector2) -> bool: return p.distance_squared_to(other) > 0.01): pool.append(p)

static func candidates(world: RefCounted,source_root_id: String,target_cid: String = "",limit: int = 3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if world.terrain.family in ["lake_basin","coastal_plain"]: return result
	var source: Dictionary = {}
	for root: Dictionary in roots(world):
		if str(root["root_id"]) == source_root_id: source = root
	if source.is_empty(): return result
	var pool: Array[Vector2] = []
	var opposite_houses: Array[Dictionary] = []
	var source_bank := int(source["bank"])
	# Sample actual existing street frontages. A second root can close a small
	# gap or extend their end; it does not conjure a new neighborhood offshore.
	for house: Dictionary in world.buildings:
		var origin := Coupling.position_of(house)
		if not target_cid.is_empty() and str(house["community_id"]) != target_cid: continue
		if _bank(world,origin)*source_bank >= 0 or not world.terrain.land_at(origin): continue
		opposite_houses.append(house)
		var frontages: Dictionary = {}
		for segment: Dictionary in world.near_road_segments(origin,1.35):
			if bool(segment["road"].get("bridge",false)): continue
			var q := Geometry2D.get_closest_point_to_segment(origin,segment["a"],segment["b"])
			var distance := origin.distance_to(q)
			if distance > 1.35 or distance < float(house["radius"]): continue
			var road_id := str(segment["road"]["id"])
			if frontages.has(road_id) and float(frontages[road_id]["distance"]) <= distance: continue
			frontages[road_id] = {"distance":distance,"direction":(Vector2(segment["b"])-Vector2(segment["a"])).normalized()}
		for frontage: Dictionary in frontages.values():
			for gap: float in [float(world.cfg["space"]["residential_radius"])*2.0+0.08,1.55,2.05]:
				for direction: float in [-1.0,1.0]: _pool_add(pool,origin+Vector2(frontage["direction"])*gap*direction)
	for lot: Dictionary in world.lots:
		if not target_cid.is_empty() and str(lot["community_id"]) != target_cid: continue
		if not str(lot.get("occupant","")).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		if _bank(world,p)*source_bank < 0: _pool_add(pool,p)
	for p: Vector2 in pool:
		var placement: Dictionary = world.placement(p)
		if not bool(placement.get("allowed",false)) or _bank(world,p)*source_bank >= 0: continue
		var cid := str(placement["community_id"])
		if cid == str(source["community_id"]) or (not target_cid.is_empty() and cid != target_cid): continue
		if Fabric.frontage_directions(world,p).is_empty(): continue
		var nearest_house := INF
		var neighbor := ""
		for house: Dictionary in opposite_houses:
			if str(house["community_id"]) != cid: continue
			var distance := p.distance_to(Coupling.position_of(house))
			if distance < nearest_house:
				nearest_house = distance
				neighbor = str(house["district_id"])
		if nearest_house > 2.4: continue
		var nearest_source := INF
		var source_id := ""
		for id: String in source["member_ids"]:
			var house: Dictionary = world.by_id[id]
			var hp := Coupling.position_of(house)
			var distance := p.distance_to(hp)
			if distance >= 8.0 or _bank(world,hp)*_bank(world,p) >= 0 or not world.terrain.land_at(hp): continue
			if source_id != source_root_id and (id == source_root_id or distance < nearest_source):
				nearest_source = distance
				source_id = id
		if source_id.is_empty(): continue
		var entry := placement.duplicate(true)
		entry.merge({"position":[p.x,p.y],"bank":_bank(world,p),"source_root_id":source_root_id,
			"source_member_id":source_id,"source_distance":nearest_source,"source_is_root":source_id == source_root_id,
			"near_house_id":neighbor,"near_house_distance":nearest_house,"spatial_opportunity":true})
		result.append(entry)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var a_rank := (1000.0 if bool(a["source_is_root"]) else 0.0)+(100.0 if float(a["near_house_distance"]) <= 1.2 else 0.0)-float(a["source_distance"])*5.0-float(a["near_house_distance"])
		var b_rank := (1000.0 if bool(b["source_is_root"]) else 0.0)+(100.0 if float(b["near_house_distance"]) <= 1.2 else 0.0)-float(b["source_distance"])*5.0-float(b["near_house_distance"])
		if not is_equal_approx(a_rank,b_rank): return a_rank > b_rank
		return str(a["position"]) < str(b["position"]))
	return result if limit < 0 else result.slice(0,maxi(0,limit))

static func public_candidate(world: RefCounted,source_root_id: String,target_cid: String) -> Dictionary:
	var opportunities := candidates(world,source_root_id,target_cid,-1)
	if opportunities.is_empty(): return {}
	var locations: Array[Vector2] = []
	for lot: Dictionary in world.lots:
		if str(lot["community_id"]) != target_cid or not str(lot.get("occupant","")).is_empty(): continue
		_pool_add(locations,Vector2(float(lot["center"][0]),float(lot["center"][1])))
	for court: Dictionary in world.fabric_cache.get("courtyards",[]):
		if str(court.get("community_id","")) == target_cid: _pool_add(locations,Vector2(float(court["center"][0]),float(court["center"][1])))
	var selected: Dictionary = {}
	var best := INF
	var radius := float(world.cfg["space"]["residential_radius"])
	for p: Vector2 in locations:
		var site: Dictionary = world.planning_candidate(p)
		if not bool(site.get("allowed",false)) or str(site.get("community_id","")) != target_cid: continue
		if SpatialPlanning.public_access(world,site).is_empty(): continue
		var kept: Array = []
		var nearest := INF
		for opportunity: Dictionary in opportunities:
			var raw: Array = opportunity["position"]
			var sound := Vector2(float(raw[0]),float(raw[1]))
			if SpatialPlanning.disc_hits(site["polygon"],sound,radius): continue
			kept.append(opportunity)
			nearest = minf(nearest,p.distance_to(sound))
		if kept.is_empty(): continue
		# Keep the public room beside the actual next street, with its voice
		# parcel still free. The player decides the public use and all notes.
		if nearest < best:
			best = nearest
			selected = site.duplicate(true)
			selected["source_root_id"] = source_root_id
			selected["preserved_sound_positions"] = kept.map(func(opportunity: Dictionary) -> Array: return opportunity["position"].duplicate())
	return selected

static func relations(world: RefCounted,pitches: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if world.terrain.family in ["lake_basin","coastal_plain"]: return result
	var authored: Dictionary = {}
	for root: Dictionary in roots(world,pitches):
		for id: String in root["member_ids"]: authored[id] = root
	for aid: String in authored:
		var a: Dictionary = world.by_id[aid]
		var ap := Coupling.position_of(a)
		for bid: String in world.index.query_circle(ap,8.0):
			if bid <= aid or not authored.has(bid): continue
			var b: Dictionary = world.by_id[bid]
			var bp := Coupling.position_of(b)
			if str(a["community_id"]) == str(b["community_id"]) or str(a["family_id"]) == str(b["family_id"]): continue
			if ap.distance_squared_to(bp) >= 64.0 or _bank(world,ap)*_bank(world,bp) >= 0: continue
			if not world.terrain.land_at(ap) or not world.terrain.land_at(bp): continue
			var score := float(world.coupling.interval(int(pitches.get(aid,a["current_midi"])),int(pitches.get(bid,b["current_midi"])))["score"])
			result.append({"a":aid,"b":bid,"a_root_id":authored[aid]["root_id"],"b_root_id":authored[bid]["root_id"],
				"a_family_id":str(a["family_id"]),"b_family_id":str(b["family_id"]),"a_community_id":str(a["community_id"]),"b_community_id":str(b["community_id"]),
				"distance":ap.distance_to(bp),"score":score,"qualified":score >= 0.85,
				"root_pair":aid == str(authored[aid]["root_id"]) and bid == str(authored[bid]["root_id"])})
	return result

static func state(world: RefCounted,source_root_id: String = "",pitches: Dictionary = {}) -> Dictionary:
	var authors := roots(world,pitches)
	var selected := source_root_id
	if selected.is_empty() and not authors.is_empty(): selected = str(authors[-1]["root_id"])
	return {"roots":authors,"source_root_id":selected,"candidates":candidates(world,selected),
		"relations":relations(world,pitches),"actual_only":true}
