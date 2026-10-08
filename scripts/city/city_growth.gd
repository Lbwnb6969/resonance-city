class_name CityGrowth
extends RefCounted
const Schema = preload("res://scripts/city/district_schema.gd")
const Values = preload("res://scripts/spec_values.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
static var cached_values: Dictionary = {}

static func config() -> Dictionary:
	if cached_values.is_empty(): cached_values = Values.load_values()["growth"]
	return cached_values

static func connected(city: Array, anchor_id: String) -> Dictionary:
	var result: Dictionary = {}
	if anchor_id.is_empty():
		return result
	for d in city:
		if d["district_id"] == anchor_id:
			result[anchor_id] = true
	var changed := true
	while changed:
		changed = false
		for d in city:
			if d.get("anchor_id","") != anchor_id or result.has(d["district_id"]):
				continue
			for other in city:
				if result.has(other["district_id"]) and (Schema.cell(d)-Schema.cell(other)).length_squared() == 1:
					result[d["district_id"]] = true
					changed = true
					break
	return result

static func conditions(city: Array, d: Dictionary) -> Dictionary:
	var cfg: Dictionary = config()
	var harmony := Harmony.new()
	var neighbors := 0
	var consonant := 0
	var embryo := 0
	var unison := 0
	var frozen := false
	var density_group := 0
	var density_center := 0
	var edges: Array = []
	var cell := Schema.cell(d)
	for other in city:
		var distance := absi(cell.x-Schema.cell(other).x)+absi(cell.y-Schema.cell(other).y)
		if other["type"] == d["type"] and not other.get("is_anchor",false):
			if distance <= int(cfg["group_radius"]):
				density_group += 1
			if distance <= int(cfg["center_radius"]):
				density_center += 1
		if distance != 1:
			continue
		neighbors += 1
		edges.append({"a":d["district_id"],"b":other["district_id"],"shared_boundary_cells":1})
		var score := float(harmony.interval(int(d["current_midi"]),int(other["current_midi"]))["score"])
		embryo += int(score >= float(cfg["embryo_score"]))
		consonant += int(score >= float(cfg["group_score"]))
		unison += int(score == 1.0)
		frozen = frozen or score <= float(cfg["freeze_score"])
	var local_r := harmony.resonance(city,edges)
	var anchor_id: String = d.get("anchor_id","")
	var linked := anchor_id.is_empty() or connected(city,anchor_id).has(d["district_id"])
	return {"neighbors":neighbors,"consonant":consonant,"embryo_neighbors":embryo,"unison":unison,
		"density_group":density_group,"density_center":density_center,"local_r":local_r,"connected":linked,"frozen":frozen}

static func assign_assets(city: Array) -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/P0城市/manifest.json"))
	var groups: Dictionary = {}
	for entry in manifest["entries"]:
		if entry["category"] not in ["residential","commercial","industrial"]: continue
		if not groups.has(entry["category"]): groups[entry["category"]] = []
		groups[entry["category"]].append(entry["id"])
	for list in groups.values(): list.sort()
	for d in city:
		if d.get("is_anchor",false): continue
		var cell := Schema.cell(d)
		var adjacent := 0
		var front := true
		for other in city:
			if other["type"] != d["type"] or other.get("is_anchor",false): continue
			var oc := Schema.cell(other)
			if (cell-oc).length_squared() == 1:
				adjacent += 1
				front = front and cell.x+cell.y >= oc.x+oc.y
		var index := 0
		if d["type"] == "residential":
			# Dense interiors use compact roofs; detached perimeter plots may show side wings.
			index = 0 if adjacent >= 2 else posmod(cell.x*31+cell.y*17,3)
		elif d["type"] == "commercial":
			# A lower front row lets the rear buildings retain readable facades.
			index = 2 if adjacent > 0 and front else posmod(cell.x+cell.y,2)
		d["manifest_id"] = groups[d["type"]][mini(index,groups[d["type"]].size()-1)]

static func draft_priority(cell: Vector2i, kind: String, band: Dictionary) -> Vector2:
	if band.is_empty() or band["bias"] != kind: return Vector2.ZERO
	var start := Vector2(band["start"][0],band["start"][1])
	var direction := Vector2(band["end"][0],band["end"][1])-start
	var along := (Vector2(cell)-start).dot(direction)/direction.length_squared()
	var closest := start+direction*clampf(along,0.0,1.0)
	return Vector2(Vector2(cell).distance_squared_to(closest),along)

static func advance(session: Object, at: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var cfg: Dictionary = config()
	var harmony := Harmony.new()
	var anchors: Array = session.city.filter(func(d: Dictionary) -> bool: return d.get("is_anchor",false))
	for anchor in anchors:
		if at < int(session.draft_pause_until): break
		if session.city.size() >= int(cfg["max_entities"]):
			break
		var family := connected(session.city,anchor["district_id"])
		var occupied: Dictionary = {}
		for d in session.city:
			occupied[Schema.cell(d)] = true
		var candidates: Dictionary = {}
		for d in session.city:
			if not family.has(d["district_id"]) or conditions(session.city,d)["frozen"]:
				continue
			for direction in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
				var cell: Vector2i = Schema.cell(d)+direction
				if cell.x < 0 or cell.y < 0 or cell.x >= int(session.growth_values["city"]["width"]) or cell.y >= int(session.growth_values["city"]["height"]) or occupied.has(cell):
					continue
				var rejected := false
				var compatible := false
				var family_neighbors := 0
				for neighbor in session.city:
					if (Schema.cell(neighbor)-cell).length_squared() != 1:
						continue
					var score := float(harmony.interval(int(anchor["current_midi"]),int(neighbor["current_midi"]))["score"])
					rejected = rejected or score <= float(cfg["freeze_score"])
					compatible = compatible or score >= float(cfg["embryo_score"])
					family_neighbors += int(family.has(neighbor["district_id"]))
				if rejected or not compatible:
					continue
				var origin := Schema.cell(anchor)
				var priority := draft_priority(cell,anchor["type"],session.gravity_band)
				candidates[cell] = {"cell":cell,"draft_distance":priority.x,"draft_forward":priority.y,"neighbors":family_neighbors,"distance":absi(cell.x-origin.x)+absi(cell.y-origin.y)}
		var sorted := candidates.values()
		sorted.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if not is_equal_approx(a["draft_distance"],b["draft_distance"]): return a["draft_distance"] < b["draft_distance"]
			if not is_equal_approx(a["draft_forward"],b["draft_forward"]): return a["draft_forward"] > b["draft_forward"]
			if a["neighbors"] != b["neighbors"]: return a["neighbors"] > b["neighbors"]
			if a["distance"] != b["distance"]: return a["distance"] < b["distance"]
			if a["cell"].y != b["cell"].y: return a["cell"].y < b["cell"].y
			return a["cell"].x < b["cell"].x)
		if sorted.is_empty():
			continue
		session.growth_serial += 1
		var grown := Schema.create("grown_%03d" % session.growth_serial,anchor["type"],sorted[0]["cell"])
		grown["current_midi"] = anchor["current_midi"]
		grown["anchor_id"] = anchor["district_id"]
		grown["voice_level"] = cfg["new_voice_level"]
		grown["form"] = "胚"
		grown["growth_counts"] = [0,0,0,0]
		session.city.append(grown)
		events.append({"district_id":grown["district_id"],"kind":"birth","frame":at+session.transport.beat_frame(1),"form":"胚"})
	for d in session.city:
		if d["type"] == "industrial" or d.get("is_anchor",false):
			continue
		var info := conditions(session.city,d)
		d["growth_conditions"] = info
		var valid: Array = [info["embryo_neighbors"] >= 1,
			info["consonant"] >= cfg["group_neighbors"] and info["local_r"] >= cfg["group_local_r"] and info["density_group"] >= cfg["group_count"],
			info["consonant"] >= cfg["center_neighbors"] and info["unison"] >= 1 and info["density_center"] >= cfg["center_count"],
			info["neighbors"] >= cfg["chamber_neighbors"] and info["consonant"] == info["neighbors"]]
		var counts: Array = d.get("growth_counts",[0,0,0,0])
		for index in range(4):
			counts[index] = int(counts[index])+1 if valid[index] and info["connected"] and not info["frozen"] else 0
		d["growth_counts"] = counts
		var old: String = d.get("form","胚")
		var next := old
		if old == "胚" and counts[1] >= cfg["stage_phrases"][1]: next = "群"
		elif old == "群":
			if counts[2] >= cfg["stage_phrases"][2]: next = "央"
			elif counts[3] >= cfg["stage_phrases"][3]: next = "腔"
		d["form"] = next
		if next != old:
			events.append({"district_id":d["district_id"],"kind":"upgrade","frame":at+session.transport.beat_frame(1),"form":next})
	assign_assets(session.city)
	return events

static func describe(city: Array,d: Dictionary) -> String:
	if d["type"] == "industrial":
		return "工业保留失谐题面，不会自动生长。可调音或迁移。"
	if d.get("is_anchor",false):
		var info := conditions(city,d)
		return "共鸣点：持续发声，每乐句吸引一栋建筑。\n%s" % ("附近有失谐的碴：先调音或迁移，保留已有建筑。" if info["frozen"] else ("声音预算已满：保留现有城市，可继续调音。" if city.size() >= int(config()["max_entities"]) else "从家族连通边界，优先聚合且避开失谐邻居。"))
	var cfg: Dictionary = config()
	var c := conditions(city,d)
	var counts: Array = d.get("growth_counts",[0,0,0,0])
	var progress := "胚→群 %d/%d；群→央 %d/%d；群→腔 %d/%d" % [counts[1],cfg["stage_phrases"][1],counts[2],cfg["stage_phrases"][2],counts[3],cfg["stage_phrases"][3]]
	return "%s%s · 局部R %.0f\n协和邻居 %d；共鸣邻居 %d；密度 群%d/%d / 央%d/%d\n%s\n群需要2协和邻居和R≥60；央需要3协和邻居与1共鸣；腔需要全部≥3邻居协和。" % [
		"碴：暂停生长" if c["frozen"] else "可继续生长"," · 家族断连" if not c["connected"] else "",c["local_r"],c["consonant"],c["unison"],c["density_group"],cfg["group_count"],c["density_center"],cfg["center_count"],progress]
