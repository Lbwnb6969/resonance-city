extends RefCounted
## One authoritative boundary recognizer, shared by live settlement and forecast forks.
const Schema = preload("res://scripts/city/district_schema.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
const Values = preload("res://scripts/spec_values.gd")
static func inspect(city: Array, roads: Dictionary, anchor: Dictionary, values: Dictionary) -> Dictionary:
	var id: String = anchor["district_id"]
	var record := {"anchor":id,"cell":[Schema.cell(anchor).x,Schema.cell(anchor).y],"members":[],"notes":[],"edges":[],"eligible":false,"status":"none","reason":""}
	var occupied: Dictionary = {}
	for d in city: occupied[Schema.cell(d)] = d
	var family: Dictionary = {id:true}
	var changed := true
	while changed:
		changed = false
		for d in city:
			if str(d.get("anchor_id","")) != id or family.has(d["district_id"]): continue
			for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next: Dictionary = occupied.get(Schema.cell(d)+step,{})
				if not next.is_empty() and family.has(next["district_id"]) and not Roads.blocked(roads,Schema.cell(d),Schema.cell(next)):
					family[d["district_id"]] = true
					changed = true
					break
	var harmony := Harmony.new()
	var cells: Array[Vector2i] = []
	var distinct: Dictionary = {}
	for offset in values["ring"]["offsets"]:
		var cell := Schema.cell(anchor)+Vector2i(offset[0],offset[1])
		var d: Dictionary = occupied.get(cell,{})
		if d.is_empty() or d["type"] != "residential" or str(d.get("anchor_id","")) != id or d.get("is_anchor",false) or d["footprint"].size() != 1:
			record["reason"] = "外围未由同一家族住宅占满"
			return record
		if d.get("form","胚") not in ["群","央","腔"] or not family.has(d["district_id"]):
			record["reason"] = "外围尚未成熟或家族断连"
			return record
		for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Dictionary = occupied.get(cell+step,{})
			if not next.is_empty() and not Roads.blocked(roads,cell,cell+step) and float(harmony.interval(int(d["current_midi"]),int(next["current_midi"]))["score"]) <= float(values["growth"]["freeze_score"]):
				record["reason"] = "外围仍有失谐冻结"
				return record
		cells.append(cell)
		record["members"].append(d["district_id"])
		record["notes"].append(int(d["current_midi"]))
		distinct[posmod(int(d["current_midi"]),12)] = true
	for index in range(cells.size()):
		var pairs := [[cells[index],cells[(index+1)%cells.size()]]]
		if index%2 == 1: pairs.append([Schema.cell(anchor),cells[index]])
		for pair in pairs:
			if Roads.blocked(roads,pair[0],pair[1]):
				record["reason"] = "环内共享边已成路"
				return record
			var a: Dictionary = occupied[pair[0]]
			var b: Dictionary = occupied[pair[1]]
			record["edges"].append({"a":a["district_id"],"b":b["district_id"],"score":harmony.interval(int(a["current_midi"]),int(b["current_midi"]))["score"]})
	if distinct.size() == 1:
		record["status"] = "unison"
		record["reason"] = "雏形·齐唱：让一栋住宅唱出与邻居协和的另一个音"
		return record
	for edge in record["edges"]:
		if float(edge["score"]) < float(values["ring"]["minimum_score"]):
			record["reason"] = "环内12条邻接尚未全部协和"
			return record
	record["eligible"] = true
	record["status"] = "candidate"
	return record

static func advance(city: Array, roads: Dictionary, prior: Dictionary, at: int, values: Dictionary) -> Dictionary:
	var rings: Dictionary = {}
	var events: Array[Dictionary] = []
	var messages: PackedStringArray = []
	for anchor in city:
		if not anchor.get("is_anchor",false) or anchor["type"] != "residential" or anchor["footprint"].size() != 1: continue
		var id: String = anchor["district_id"]
		var old: Dictionary = prior.get(id,{})
		var ring := inspect(city,roads,anchor,values)
		ring["count"] = mini(int(values["ring"]["required_boundaries"]),int(old.get("count",0))+1) if ring["eligible"] else 0
		if int(ring["count"]) >= int(values["ring"]["required_boundaries"]): ring["status"] = "formed"
		ring["changed_at"] = int(old.get("changed_at",at)) if ring["status"] == old.get("status","") else at
		ring["phase_origin"] = 0
		rings[id] = ring
		if ring["status"] == "unison" and old.get("status","") != "unison": events.append({"kind":"ring_unison","district_id":id,"frame":at,"form":"环形雏形","notes":ring["notes"].duplicate()})
		if ring["status"] == "formed" and old.get("status","") != "formed": events.append({"kind":"ring_formed","district_id":id,"frame":at,"form":"环形合唱城","notes":ring["notes"].duplicate()})
		if old.get("status","") == "formed" and ring["status"] != "formed": messages.append("将失去环形合唱城："+str(ring["reason"]))
		elif ring["eligible"] and old.get("status","") != "formed": messages.append("将形成环形合唱城（需连续%d乐句，本次%d/%d）" % [values["ring"]["required_boundaries"],ring["count"],values["ring"]["required_boundaries"]])
	for id in prior:
		if not rings.has(id) and prior[id].get("status","") == "formed": messages.append("将失去环形合唱城：源点已离开")
	return {"rings":rings,"events":events,"messages":messages}

static func describe(rings: Dictionary, selected: String, muted: Dictionary, solo: String, silent: Dictionary, audible: float) -> String:
	var note_names := ["C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
	for ring in rings.values():
		if selected != ring["anchor"] and selected not in ring["members"]: continue
		if ring["status"] not in ["unison","candidate","formed"]: return ""
		var notes: PackedStringArray = []
		for midi in ring["notes"]: notes.append(note_names[posmod(int(midi),12)])
		var state := "环形合唱城 · 轮唱" if ring["status"] == "formed" else ("雏形·齐唱" if ring["status"] == "unison" else "合唱条件已满足，等待成形")
		var text := state+" · 连续%d/2\n" % ring["count"]+" → ".join(notes)
		if ring["status"] == "unison": text += "\n让一栋住宅唱出与邻居协和的另一个音"
		var partial := not solo.is_empty()
		for id in ring["members"]: partial = partial or bool(muted.get(id,false)) or audible < int(silent.get(id,0))
		if partial: text += "\n当前有静音/隔离，只能听到部分声部"
		return text
	return ""
