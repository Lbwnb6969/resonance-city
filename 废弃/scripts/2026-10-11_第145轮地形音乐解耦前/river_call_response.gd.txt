extends RefCounted
## T3-a: spatial musical relations, deliberately separate from physical R edges.
const Coupling = preload("res://scripts/world/world_coupling.gd")

static func pairs(world: RefCounted,overrides: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# The current lake and coastal templates describe lake/sea water, not a river.
	if world.terrain.family in ["lake_basin","coastal_plain"]: return result
	for a in world.buildings:
		var aid := str(a["district_id"])
		var ap := Coupling.position_of(a)
		var abank := signf(ap.x-world.terrain.river_x(ap.y))
		for bid in world.index.query_circle(ap,8.0):
			if bid <= aid: continue
			var b: Dictionary = world.by_id[bid]
			var bp := Coupling.position_of(b)
			if ap.distance_squared_to(bp) >= 64.0: continue
			if abank*signf(bp.x-world.terrain.river_x(bp.y)) >= 0.0: continue
			if not world.terrain.land_at(ap) or not world.terrain.land_at(bp): continue
			var score: float = world.coupling.interval(int(overrides.get(aid,a["current_midi"])),int(overrides.get(bid,b["current_midi"])))["score"]
			if score < 0.85: continue
			result.append({"a":aid,"b":bid,"distance":ap.distance_to(bp),"score":score})
	return result

static func bonuses(relations: Array) -> Dictionary:
	var result: Dictionary = {}
	for pair in relations:
		for id in [pair["a"],pair["b"]]: result[id] = float(result.get(id,0.0))+2.0
	return result

static func reply(world: RefCounted,source: Dictionary,relations: Array,overrides: Dictionary = {}) -> Dictionary:
	var options: Dictionary = {}
	for pair in relations:
		for direction in [[pair["a"],pair["b"]],[pair["b"],pair["a"]]]:
			var aid := str(direction[0])
			var bid := str(direction[1])
			if not source["source_ids"].has(aid): continue
			var receiver: Dictionary = world.by_id[bid]
			var cid := str(receiver["community_id"])
			if cid == str(source["cid"]): continue
			if not options.has(cid): options[cid] = {}
			var previous: Dictionary = options[cid].get(aid,{})
			if previous.is_empty() or float(pair["distance"]) < float(previous["distance"]) or (float(pair["distance"]) == float(previous["distance"]) and bid < str(previous["id"])):
				options[cid][aid] = {"id":bid,"distance":pair["distance"]}
	var candidates: Array = options.keys()
	candidates.sort_custom(func(a: String,b: String)->bool:
		if options[a].size() != options[b].size(): return options[a].size() > options[b].size()
		return a < b)
	if candidates.is_empty(): return {}
	var selected := str(candidates[0])
	var notes: Array = []
	var receivers: Array = []
	for aid in source["source_ids"]:
		var receiver: Dictionary = options[selected].get(aid,{})
		var bid := str(receiver.get("id",""))
		receivers.append(bid)
		notes.append(-1 if bid.is_empty() else int(overrides.get(bid,world.by_id[bid]["current_midi"])))
	return {"cid":selected,"notes":notes,"source":source["cid"],"source_ids":source["source_ids"].duplicate(),
		"receiver_ids":receivers,"pair_count":options[selected].size(),"generation":1}
