extends RefCounted
## First playable era slice. State lives in the session, including held city time.
const Schema = preload("res://scripts/city/district_schema.gd")
const Roads = preload("res://scripts/city/city_roads.gd")

static func enable(session: Object, preview: bool = false) -> void:
	session.run = {"era":1,"chapter":3 if preview else 1,"phrase":11 if preview else 0,
		"era_chapters":2 if preview else 0,"resolved":{},"phase":"playing",
		"offset":-session.transport.phrase_frame(35) if preview else 0,
		"transition":{},"history":[],"preview":preview}
	if preview: session.phrase_index = 35
	for d in session.city: d["era"] = 1
	configure(session)
	apply_assets(session.city)
	session._refresh_catalog()

static func configure(session: Object) -> void:
	if session.run.is_empty(): return
	session.growth_values = session.growth_values.duplicate(true)
	session.settings = session.settings.duplicate(true)
	var era := int(session.run["era"])
	var side := 16 if era == 1 else 20
	session.growth_values["city"]["width"] = side
	session.growth_values["city"]["height"] = side
	# Reserve two actual voices for the first visitors, without increasing the budget.
	session.growth_values["growth"]["max_entities"] = 25 if era == 1 else 27
	session.settings["allowed_pitches"] = [48,50,52,55,57] if era == 1 else [48,50,52,53,55,57,59]
	session.harmony.space = session.growth_values["city"].duplicate(true)

static func asset_id(kind: String, era: int) -> String:
	return "era%d_%s_01" % [era,kind]

static func apply_assets(city: Array) -> void:
	for d in city:
		if not d.has("era") or d.get("is_anchor",false) or d.get("landmark",false): continue
		d.erase("visual_partner")
		d.erase("visual_owner")
		d["manifest_id"] = asset_id(str(d["type"]),int(d["era"]))

static func next_boundary(session: Object) -> int:
	var run: Dictionary = session.run
	if not run.is_empty() and run["phase"] == "transition":
		var t: Dictionary = run["transition"]
		return int(t["start"])+session.transport.bar_frame(5 if not t["arrived"] else 8)
	return session.city_frame(session.phrase_index+1)

static func after_settle(session: Object, at: int) -> void:
	var run: Dictionary = session.run
	if run.is_empty() or run["phase"] != "playing": return
	var result: Dictionary = session.last_result
	var before: Dictionary = {}
	var after: Dictionary = {}
	for d in result["before"]: before[d["district_id"]] = d
	for d in result["after"]: after[d["district_id"]] = d
	var prior: Dictionary = {}
	for e in result["before_edges"]:
		var pair: Array = [e["a"],e["b"]]
		pair.sort()
		prior[JSON.stringify(pair)] = absi(int(before[e["a"]]["current_midi"])-int(before[e["b"]]["current_midi"]))%12
	for e in result["after_edges"]:
		var pair: Array = [e["a"],e["b"]]
		pair.sort()
		var key := JSON.stringify(pair)
		if prior.get(key,-1) in [2,3] and session.harmony.interval(int(after[e["a"]]["current_midi"]),int(after[e["b"]]["current_midi"]))["relation"] in ["协和","共鸣"]:
			run["resolved"][key] = true
	run["phrase"] = int(run["phrase"])+1
	if bool(session.lifecycle["ended"]):
		run["phase"] = "finished"
		return
	if int(run["phrase"]) < 12: return
	run["era_chapters"] = int(run["era_chapters"])+1
	var perfect: bool = run["resolved"].size() >= 3 and float(result["after_r"]) >= 70.0
	var record := {"chapter":run["chapter"],"era":run["era"],"frame":at,
		"resolved":run["resolved"].size(),"r":result["after_r"],"perfect":perfect}
	run["history"].append(record)
	if int(run["chapter"]) == 7:
		run["phase"] = "finished"
		session.lifecycle["ended"] = true
		return
	if int(run["era"]) == 1 and ((perfect and int(run["era_chapters"]) >= 2) or int(run["era_chapters"]) >= 3):
		var origin: Vector2i = Schema.cell(session.city[0])
		for d in session.city:
			if d.get("is_anchor",false):
				origin = Schema.cell(d)
				break
		run["phase"] = "transition"
		run["transition"] = {"start":at,"arrived":false,"origin":[origin.x,origin.y],
			"perfect":perfect,"r":result["after_r"],"chapter":run["chapter"],"resolved":run["resolved"].size()}
		result["era_event"] = "departure"
	else:
		run["chapter"] = int(run["chapter"])+1
		run["phrase"] = 0
		run["resolved"] = {}

static func wave_frame(d: Dictionary, transition: Dictionary, transport: Object) -> int:
	var origin := Vector2i(int(transition["origin"][0]),int(transition["origin"][1]))
	var cell := Schema.cell(d)
	if int(d.get("era",1)) == 2: cell -= Vector2i(2,2)
	var radius := mini(12,absi(cell.x-origin.x)+absi(cell.y-origin.y))
	return int(transition["start"])+transport.bar_frame(3)+transport.beat_frame(radius)

static func _distance(cell: Vector2i, city: Array) -> int:
	var result := 100
	for d in city:
		var delta := cell-Schema.cell(d)
		result = mini(result,absi(delta.x)+absi(delta.y))
	return result

static func held_boundary(session: Object, at: int) -> Dictionary:
	var run: Dictionary = session.run
	var transition: Dictionary = run["transition"]
	var events: Array[Dictionary] = []
	if not transition["arrived"]:
		# Shift coordinates by two so every side has new land, preserving old projections.
		for d in session.city:
			var cell := Schema.cell(d)+Vector2i(2,2)
			d["footprint"] = [[cell.x,cell.y]]
			if not d.get("landmark",false): d["era"] = 2
		var roads: Dictionary = {}
		for mark in session.road_marks.values():
			var a := Vector2i(int(mark["start"][0])+2,int(mark["start"][1])+2)
			var b := Vector2i(int(mark["end"][0])+2,int(mark["end"][1])+2)
			mark["start"] = [a.x,a.y]
			mark["end"] = [b.x,b.y]
			roads[Roads.key(a,b)] = mark
		session.road_marks = roads
		session.harmony.road_marks = roads
		if not session.gravity_band.is_empty():
			for key in ["start","end"]:
				session.gravity_band[key][0] += 2
				session.gravity_band[key][1] += 2
		run["era"] = 2
		configure(session)
		var choices: Array[Vector2i] = []
		for y in range(20):
			for x in range(20):
				if x in range(2,18) and y in range(2,18): continue
				var cell := Vector2i(x,y)
				var nearest := 100
				for d in session.city:
					var delta := cell-Schema.cell(d)
					nearest = mini(nearest,absi(delta.x)+absi(delta.y))
				if nearest in [2,3]: choices.append(cell)
		# Empty margins can be farther from the old city; choose the nearest new plots then.
		if choices.size() < 2:
			choices.clear()
			for y in range(20):
				for x in range(20):
					if x in [0,1,18,19] or y in [0,1,18,19]: choices.append(Vector2i(x,y))
			choices.sort_custom(func(a: Vector2i,b: Vector2i) -> bool:
				return _distance(a,session.city) < _distance(b,session.city))
			choices.resize(mini(4,choices.size()))
		for index in range(2):
			var cell: Vector2i = choices.pop_at(session.rng.bounded("terrain",choices.size()))
			var visitor := Schema.create("era2_visitor_%d" % index,"residential" if index == 0 else "commercial",cell)
			visitor["current_midi"] = 53 if index == 0 else 59
			visitor["era"] = 2
			visitor["visitor"] = true
			visitor["anchor_id"] = visitor["district_id"]
			visitor["form"] = "央"
			visitor["voice_level"] = session.growth_values["growth"]["new_voice_level"]
			session.city.append(visitor)
			session.silent_until[visitor["district_id"]] = at+session.transport.bar_frame(1)
			events.append({"district_id":visitor["district_id"],"kind":"birth","frame":at+session.transport.bar_frame(1),"form":"央"})
		transition["arrived"] = true
		apply_assets(session.city)
		session.last_result = {"frame":at,"choice":{},"growth_events":events,"era_event":"arrival"}
	else:
		run["offset"] = int(run["offset"])+session.transport.phrase_frame(1)
		run["phase"] = "playing"
		run["chapter"] = int(run["chapter"])+1
		run["phrase"] = 0
		run["era_chapters"] = 0
		run["resolved"] = {}
		# City deadlines move with the held city clock; acoustic event phases do not.
		for id in session.silent_until:
			if not session._district(id).get("visitor",false): session.silent_until[id] = int(session.silent_until[id])+session.transport.phrase_frame(1)
		session.draft_pause_until += session.transport.phrase_frame(1)
		session._refresh_catalog()
		session.last_result = {"frame":at,"choice":{},"growth_events":[],"era_event":"resume"}
	return session.last_result.duplicate(true)
