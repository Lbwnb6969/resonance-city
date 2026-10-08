extends RefCounted
# Presentation-only slots; never reserve a cell or consume city RNG.
const Growth = preload("res://scripts/city/city_growth.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
static func slots(session: CityInterventions, settings: Dictionary, tree_ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if session == null or tree_ids.is_empty(): return result
	var occupied: Dictionary = {}
	var families: Dictionary = {}
	for d in session.city:
		occupied[Schema.cell(d)] = d
		var family: String = d.get("anchor_id","")
		if not family.is_empty() and not d.get("is_anchor",false) and d["type"] in ["residential","commercial"] and d.get("form","胚") in ["群","央","腔"]:
			families[family] = true
	var names: Array = families.keys()
	names.sort()
	var space: Dictionary = session.growth_values["city"]
	var directions := [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]
	for family in names:
		var connected: Dictionary = Growth.connected(session.city,family,session.road_marks)
		var candidates: Dictionary = {}
		for d in session.city:
			if not connected.has(d["district_id"]) or d.get("is_anchor",false) or d.get("form","胚") not in ["群","央","腔"]: continue
			var cell := Schema.cell(d)
			for direction in directions:
				var target: Vector2i = cell+direction
				if target.x < 0 or target.y < 0 or target.x >= int(space["width"]) or target.y >= int(space["height"]) or occupied.has(target) or Roads.blocked(session.road_marks,cell,target): continue
				var industrial := false
				for offset in directions:
					industrial = industrial or occupied.get(target+offset,{}).get("type","") == "industrial"
				if industrial: continue
				var neighbors := 0
				for offset in directions:
					var other: Dictionary = occupied.get(target+offset,{})
					if connected.has(other.get("district_id","")) and other.get("form","胚") in ["群","央","腔"] and not Roads.blocked(session.road_marks,target,target+offset): neighbors += 1
				var key := "%s:%d,%d" % [family,target.x,target.y]
				candidates[target] = {"key":key,"cell":target,"family":family,"neighbors":neighbors,"order":key.sha256_text(),"asset_id":tree_ids[posmod(target.x+target.y,tree_ids.size())]}
		var ordered: Array = candidates.values()
		ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a["neighbors"] > b["neighbors"] if a["neighbors"] != b["neighbors"] else a["order"] < b["order"])
		var count := 0
		for candidate in ordered:
			var spaced := true
			for previous in result:
				var delta: Vector2i = candidate["cell"]-previous["cell"]
				spaced = spaced and absi(delta.x)+absi(delta.y) >= int(settings["minimum_spacing"])
			if not spaced: continue
			result.append(candidate)
			count += 1
			if result.size() >= int(settings["maximum"]): return result
			if count >= int(settings["per_family"]): break
	return result
