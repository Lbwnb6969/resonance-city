class_name CityGrowth
extends RefCounted
const Schema = preload("res://scripts/city/district_schema.gd")
const Values = preload("res://scripts/spec_values.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
static var cached_values: Dictionary = {}

static func config() -> Dictionary:
	if cached_values.is_empty(): cached_values = Values.load_values()["growth"]
	return cached_values

static func connected(city: Array, anchor_id: String, road_marks: Dictionary = {}) -> Dictionary:
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
				if result.has(other["district_id"]) and (Schema.cell(d)-Schema.cell(other)).length_squared() == 1 and not Roads.blocked(road_marks,Schema.cell(d),Schema.cell(other)):
					result[d["district_id"]] = true
					changed = true
					break
	return result

static func conditions(city: Array, d: Dictionary, road_marks: Dictionary = {}) -> Dictionary:
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
		if distance != 1 or Roads.blocked(road_marks,cell,Schema.cell(other)):
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
	var linked := anchor_id.is_empty() or connected(city,anchor_id,road_marks).has(d["district_id"])
	return {"neighbors":neighbors,"consonant":consonant,"embryo_neighbors":embryo,"unison":unison,
		"density_group":density_group,"density_center":density_center,"local_r":local_r,"connected":linked,"frozen":frozen}

static func stage_valid(info: Dictionary) -> Array:
	var cfg: Dictionary = config()
	return [info["embryo_neighbors"] >= 1,
		info["consonant"] >= cfg["group_neighbors"] and info["local_r"] >= cfg["group_local_r"] and info["density_group"] >= cfg["group_count"],
		info["consonant"] >= cfg["center_neighbors"] and info["unison"] >= 1 and info["density_center"] >= cfg["center_count"],
		info["neighbors"] >= cfg["chamber_neighbors"] and info["consonant"] == info["neighbors"]]

static func assign_assets(city: Array, road_marks: Dictionary = {}) -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://资源/Demo城市/manifest.json"))
	var groups: Dictionary = {}
	var compounds: Array[String] = []
	var occupied: Dictionary = {}
	var by_id: Dictionary = {}
	var previous: Dictionary = {}
	for entry in manifest["entries"]:
		if entry["category"] == "compound":
			compounds.append(entry["id"])
		elif entry["category"] in ["residential","commercial","industrial"]:
			if not groups.has(entry["category"]): groups[entry["category"]] = []
			groups[entry["category"]].append(entry["id"])
	for list in groups.values(): list.sort()
	compounds.sort()
	for d in city:
		occupied[Schema.cell(d)] = d
		by_id[d["district_id"]] = d
		if d.has("visual_partner"): previous[d["district_id"]] = {"partner":d["visual_partner"],"asset":d["manifest_id"]}
		d.erase("visual_partner")
		d.erase("visual_owner")
	for d in city:
		if d.get("is_anchor",false): continue
		var cell := Schema.cell(d)
		var adjacent := 0
		var front := true
		for other in city:
			if other["type"] != d["type"] or other.get("is_anchor",false): continue
			var oc := Schema.cell(other)
			if (cell-oc).length_squared() == 1 and not Roads.blocked(road_marks,cell,oc):
				adjacent += 1
				front = front and cell.x+cell.y >= oc.x+oc.y
		var index := 0
		if d["type"] == "residential":
			var motif := posmod(cell.x*13+cell.y*7,7)
			index = (2 if motif in [1,4] else 0) if adjacent >= 2 else posmod(cell.x*31+cell.y*17,3)
		elif d["type"] == "commercial":
			index = 2 if adjacent > 0 and front else posmod(cell.x+cell.y,2)
		d["manifest_id"] = groups[d["type"]][mini(index,groups[d["type"]].size()-1)]
	var paired: Dictionary = {}
	# Keep accepted pairs stable as new neighbors mature.
	for id in previous:
		var d: Dictionary = by_id[id]
		var other: Dictionary = by_id.get(previous[id]["partner"],{})
		if _can_pair(d,other,road_marks) and previous[id]["asset"] in compounds:
			d["visual_partner"] = other["district_id"]
			d["manifest_id"] = previous[id]["asset"]
			other["visual_owner"] = id
			paired[id] = true
			paired[other["district_id"]] = true
	var ordered: Array = city.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		return Schema.cell(a).y < Schema.cell(b).y if Schema.cell(a).y != Schema.cell(b).y else Schema.cell(a).x < Schema.cell(b).x)
	for d in ordered:
		if compounds.is_empty() or paired.has(d["district_id"]): continue
		var cell := Schema.cell(d)
		if posmod(cell.x+cell.y,3) != 0: continue
		var other: Dictionary = occupied.get(cell+Vector2i.RIGHT,{})
		if other.is_empty() or paired.has(other["district_id"]) or not _can_pair(d,other,road_marks): continue
		d["visual_partner"] = other["district_id"]
		d["manifest_id"] = compounds[posmod(cell.x+cell.y,compounds.size())]
		other["visual_owner"] = d["district_id"]
		paired[d["district_id"]] = true
		paired[other["district_id"]] = true

static func _can_pair(a: Dictionary,b: Dictionary, road_marks: Dictionary) -> bool:
	return not b.is_empty() and not Roads.blocked(road_marks,Schema.cell(a),Schema.cell(b)) and a["type"] == "residential" and b["type"] == "residential" and not a.get("is_anchor",false) and not b.get("is_anchor",false) and not str(a.get("anchor_id","")).is_empty() and a.get("anchor_id","") == b.get("anchor_id","") and a["current_midi"] == b["current_midi"] and Schema.cell(b)-Schema.cell(a) == Vector2i.RIGHT and a.get("form","胚") in ["群","央","腔"] and b.get("form","胚") in ["群","央","腔"]

static func draft_priority(cell: Vector2i, kind: String, band: Dictionary) -> Vector2:
	if band.is_empty() or band["bias"] != kind: return Vector2.ZERO
	var start := Vector2(band["start"][0],band["start"][1])
	var direction := Vector2(band["end"][0],band["end"][1])-start
	var along := (Vector2(cell)-start).dot(direction)/direction.length_squared()
	var closest := start+direction*clampf(along,0.0,1.0)
	return Vector2(Vector2(cell).distance_squared_to(closest),along)

static func advance(session: Object, at: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var newborn: Dictionary = {}
	var cfg: Dictionary = config()
	var harmony := Harmony.new()
	var anchors: Array = session.city.filter(func(d: Dictionary) -> bool: return d.get("is_anchor",false))
	for anchor in anchors:
		if at < int(session.draft_pause_until): break
		if session.city.size() >= int(cfg["max_entities"]):
			break
		var family := connected(session.city,anchor["district_id"],session.road_marks)
		var occupied: Dictionary = {}
		for d in session.city:
			occupied[Schema.cell(d)] = true
		var candidates: Dictionary = {}
		for d in session.city:
			if not family.has(d["district_id"]) or conditions(session.city,d,session.road_marks)["frozen"]:
				continue
			for direction in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
				var cell: Vector2i = Schema.cell(d)+direction
				if cell.x < 0 or cell.y < 0 or cell.x >= int(session.growth_values["city"]["width"]) or cell.y >= int(session.growth_values["city"]["height"]) or occupied.has(cell) or Roads.blocked(session.road_marks,Schema.cell(d),cell):
					continue
				var rejected := false
				var compatible := false
				var family_neighbors := 0
				for neighbor in session.city:
					if (Schema.cell(neighbor)-cell).length_squared() != 1 or Roads.blocked(session.road_marks,cell,Schema.cell(neighbor)):
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
		grown["growth_stalled_phrases"] = 0
		newborn[grown["district_id"]] = true
		session.city.append(grown)
		events.append({"district_id":grown["district_id"],"kind":"birth","frame":at+session.transport.beat_frame(1),"form":"胚"})
	for d in session.city:
		if d["type"] == "industrial" or d.get("is_anchor",false):
			continue
		var info := conditions(session.city,d,session.road_marks)
		d["growth_conditions"] = info
		var valid: Array = stage_valid(info)
		var counts: Array = d.get("growth_counts",[0,0,0,0])
		var before_counts: Array = counts.duplicate()
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
		var progressing: bool = counts[1] > before_counts[1] if old == "胚" else (counts[2] > before_counts[2] or counts[3] > before_counts[3])
		if next != old or progressing or next in ["央","腔"] or newborn.has(d["district_id"]):
			d["growth_stalled_phrases"] = 0
		else:
			d["growth_stalled_phrases"] = int(d.get("growth_stalled_phrases",0))+1
		if next != old:
			events.append({"district_id":d["district_id"],"kind":"upgrade","frame":at+session.transport.beat_frame(1),"form":next})
	assign_assets(session.city,session.road_marks)
	return events

static func stage_gaps(info: Dictionary, index: int) -> PackedStringArray:
	var cfg: Dictionary = config()
	var gaps: PackedStringArray = []
	if info["frozen"]: gaps.append("失谐邻接仍在，升级暂停")
	if not info["connected"]: gaps.append("家族断连")
	var neighbors_needed: int = cfg["group_neighbors"] if index == 1 else (cfg["center_neighbors"] if index == 2 else cfg["chamber_neighbors"])
	var actual: int = info["neighbors"] if index == 3 else info["consonant"]
	if actual < neighbors_needed: gaps.append("缺%d个%s邻居" % [neighbors_needed-actual,"相邻" if index == 3 else "协和"])
	if index == 1:
		if float(info["local_r"]) < float(cfg["group_local_r"]): gaps.append("局部R还差%.1f" % (float(cfg["group_local_r"])-float(info["local_r"])))
		if int(info["density_group"]) < int(cfg["group_count"]): gaps.append("%d格内缺%d栋同类" % [cfg["group_radius"],int(cfg["group_count"])-int(info["density_group"])])
	elif index == 2:
		if int(info["unison"]) < 1: gaps.append("缺1个共鸣邻居")
		if int(info["density_center"]) < int(cfg["center_count"]): gaps.append("%d格内缺%d栋同类" % [cfg["center_radius"],int(cfg["center_count"])-int(info["density_center"])])
	elif int(info["consonant"]) < int(info["neighbors"]):
		gaps.append("%d个邻居尚未协和" % (int(info["neighbors"])-int(info["consonant"])))
	return gaps

static func describe(city: Array,d: Dictionary, road_marks: Dictionary = {}) -> String:
	if d["type"] == "industrial":
		return "工业保留失谐题面，不会自动生长。可调音或迁移。"
	var cfg: Dictionary = config()
	var c := conditions(city,d,road_marks)
	if d.get("is_anchor",false):
		return "共鸣点：持续发声，每乐句尝试扩张。\n%s" % ("附近有失谐的碴：该格暂停向外生长，已有建筑保留。" if c["frozen"] else ("声音预算已满：保留现有城市，可继续调音。" if city.size() >= int(cfg["max_entities"]) else "只从连通家族的合法边界扩张；道路和失谐可能挡住位置。"))
	var form: String = d.get("form","胚")
	if form in ["央","腔"]:
		return "已成熟：%s，保留现有形态。\n%s · 局部R %.1f" % [form,"家族断连，暂停向外扩张" if not c["connected"] else ("失谐冻结，暂停向外扩张" if c["frozen"] else "家族连通，仍按合法位置尝试扩张"),c["local_r"]]
	var counts: Array = d.get("growth_counts",[0,0,0,0])
	var lines: PackedStringArray = []
	var stalled := int(d.get("growth_stalled_phrases",0))
	if stalled >= int(cfg["stall_phrases"]): lines.append("已等待%d乐句 · 当前缺口如下" % stalled)
	var stages: Array = [1] if form == "胚" else [2,3]
	var names := ["胚","群","央","腔"]
	for index in stages:
		var gaps := stage_gaps(c,index)
		var progress := "%d/%d乐句" % [counts[index],cfg["stage_phrases"][index]]
		if gaps.is_empty():
			lines.append("等待%s：条件已满足，连续%s" % [names[index],progress])
		else:
			lines.append("等待%s：%s；连续%s" % [names[index],"；".join(gaps),progress])
	lines.append("协和邻居%d/%d · 共鸣%d · 局部R %.1f" % [c["consonant"],c["neighbors"],c["unison"],c["local_r"]])
	lines.append("同类密度：%d格内%d/%d，%d格内%d/%d（含自己、不含共鸣点）" % [cfg["group_radius"],c["density_group"],cfg["group_count"],cfg["center_radius"],c["density_center"],cfg["center_count"]])
	return "\n".join(lines)
