class_name CityInterventions
extends RefCounted
## Pure city transaction used by playback and preview forks.

const Era = preload("res://scripts/city/city_era.gd")
const Ring = preload("res://scripts/city/city_ring.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
const Growth = preload("res://scripts/city/city_growth.gd")
const Values = preload("res://scripts/spec_values.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Transport = preload("res://scripts/audio/sample_transport.gd")
const RandomStreams = preload("res://scripts/city/named_random.gd")

var city: Array
var rng: NamedRandom
var harmony := Harmony.new()
var transport := Transport.new()
var settings: Dictionary
var phrase_index := 0
var run: Dictionary = {}

func city_frame(index: int) -> int:
	return transport.phrase_frame(index)+int(run.get("offset",0))

func next_city_boundary() -> int:
	return Era.next_boundary(self)
var refresh_cycle := 0
var catalog: Array[Dictionary] = []
var pending: Dictionary = {}
var silent_until: Dictionary = {}
var lifecycle := {"gray":false, "low_phrases":0, "ended":false}
var last_result: Dictionary = {}
var growth_enabled := false
var growth_serial := 0
var growth_values: Dictionary = {}
var road_marks: Dictionary = {}
var rings: Dictionary = {}
var gravity_band: Dictionary = {}
var draft_pause_until := 0

func _init(initial_city: Array, seed: String, random_state: Dictionary = {}, run_state: Dictionary = {}) -> void:
	city = initial_city.duplicate(true)
	harmony.road_marks = road_marks
	rng = RandomStreams.new(seed)
	if not random_state.is_empty():
		rng.restore(random_state)
	growth_values = Values.load_values()
	settings = growth_values["proposals"]
	run = run_state.duplicate(true)
	Era.configure(self)
	assert(int(settings["per_phrase"]) == 1)
	_refresh_catalog()

func _district(id: String) -> Dictionary:
	for district in city:
		if district["district_id"] == id:
			return district
	return {}

func _pitches(id: String) -> Array[int]:
	var district := _district(id)
	var result: Array[int] = []
	if district.is_empty():
		return result
	if district.get("visitor",false) and not harmony.adjacency(city).any(func(edge: Dictionary) -> bool: return edge["a"] == id or edge["b"] == id):
		for midi in settings["allowed_pitches"]:
			if int(midi) != int(district["current_midi"]): result.append(int(midi))
		return result
	for midi in settings["allowed_pitches"]:
		if int(midi) == int(district["current_midi"]):
			continue
		for edge in harmony.adjacency(city):
			if edge["a"] != id and edge["b"] != id:
				continue
			var other := _district(edge["b"] if edge["a"] == id else edge["a"])
			if harmony.interval(int(midi), int(other["current_midi"]))["relation"] in ["协和", "共鸣"]:
				result.append(int(midi))
				break
	return result

func _empty_cells() -> Array:
	var space: Dictionary = growth_values["city"]
	var occupied: Dictionary = {}
	for district in city:
		occupied[Schema.cell(district)] = true
	var result: Array = []
	for y in range(int(space["height"])):
		for x in range(int(space["width"])):
			if not occupied.has(Vector2i(x,y)):
				result.append([x,y])
	return result

func _refresh_catalog() -> void:
	catalog.clear()
	var empty := _empty_cells()
	for district in city:
		var id: String = district["district_id"]
		var pitches := _pitches(id)
		if not pitches.is_empty():
			catalog.append({"proposal_id":"p0:%d:%s:retune" % [refresh_cycle,id],
				"source_event":"refresh:%d" % refresh_cycle,"verb":"retune","district_id":id,
				"allowed_pitches":pitches,"targets":Array(pitches)})
		if not empty.is_empty():
			catalog.append({"proposal_id":"p0:%d:%s:relocate" % [refresh_cycle,id],
				"source_event":"refresh:%d" % refresh_cycle,"verb":"relocate","district_id":id,
				"allowed_pitches":[],"targets":empty.duplicate(true)})

func proposal(id: String) -> Dictionary:
	for item in catalog:
		if item["proposal_id"] == id:
			return item.duplicate(true)
	return {}

func release_feedback(midi: int, target: Vector2i) -> Dictionary:
	if not growth_enabled: return {"allowed":false,"reason":"当前模式不开放共鸣点。"}
	if bool(lifecycle["ended"]): return {"allowed":false,"reason":"本局已结束，可重新开始。"}
	if target.x < 0 or target.y < 0 or target.x >= int(growth_values["city"]["width"]) or target.y >= int(growth_values["city"]["height"]):
		return {"allowed":false,"reason":"请选择地图内的格子。"}
	if not PackedInt32Array(settings["allowed_pitches"]).has(midi): return {"allowed":false,"reason":"请选择系统提供的音级。"}
	for district in city:
		if Schema.cell(district) == target: return {"allowed":false,"reason":"已有建筑或共鸣点，请选择空格。"}
	if city.size() >= int(growth_values["growth"]["max_entities"])-1:
		return {"allowed":false,"reason":"声音预算不足，需为新建筑保留一个声部。"}
	return {"allowed":true,"reason":"可释放；城市会按和声条件回应。"}

func request_release(midi: int, target: Vector2i, rendered_frames: int, audible_frame: float) -> Dictionary:
	return request({"verb":"release","proposal_id":"release","midi":midi,"target":[target.x,target.y]},rendered_frames,audible_frame)

func request_draft(start: Vector2i, end: Vector2i, bias: String, rendered_frames: int, audible_frame: float) -> Dictionary:
	return request({"verb":"draft","proposal_id":"draft","start":[start.x,start.y],"end":[end.x,end.y],"bias":bias},rendered_frames,audible_frame)

func request_tread(start: Vector2i, end: Vector2i, rendered_frames: int, audible_frame: float) -> Dictionary:
	return request({"verb":"tread","proposal_id":"tread","start":[start.x,start.y],"end":[end.x,end.y]},rendered_frames,audible_frame)

func _legal(choice: Dictionary) -> bool:
	if choice.get("verb","") == "tread":
		if not growth_enabled: return false
		for name in ["start","end"]:
			if not choice.get(name) is Array or choice[name].size() != 2: return false
		var a := Vector2i(int(choice["start"][0]),int(choice["start"][1]))
		var b := Vector2i(int(choice["end"][0]),int(choice["end"][1]))
		return Roads.valid(a,b,growth_values["city"]) and not Roads.blocked(road_marks,a,b)
	if choice.get("verb","") == "draft":
		if not growth_enabled or choice.get("bias","") not in growth_values["draft"]["allowed_biases"]: return false
		for key in ["start","end"]:
			var cell: Variant = choice.get(key)
			if not cell is Array or cell.size() != 2: return false
			if int(cell[0]) < 0 or int(cell[0]) >= int(growth_values["city"]["width"]) or int(cell[1]) < 0 or int(cell[1]) >= int(growth_values["city"]["height"]): return false
		return choice["start"] != choice["end"]
	if choice.get("verb","") == "release":
		var target: Variant = choice.get("target")
		if not target is Array or target.size() != 2: return false
		return _empty_cells().has(target) and bool(release_feedback(int(choice.get("midi",-1)),Vector2i(int(target[0]),int(target[1])))["allowed"])
	var item := proposal(str(choice.get("proposal_id","")))
	if item.is_empty() or _district(item["district_id"]).is_empty():
		return false
	var target: Variant = choice.get("target")
	if item["verb"] == "retune":
		return target is int and item["allowed_pitches"].has(target) and _pitches(item["district_id"]).has(target)
	return target is Array and target.size() == 2 and item["targets"].has(target) and _empty_cells().has(target)

func is_on_grid(requested_audio_frame: float) -> bool:
	var period := transport.phrase_frame(1)
	var anchor := int(run.get("offset",0))
	var nearest := roundi((requested_audio_frame-anchor) / period) * period+anchor
	var window := float(transport.timing["beat_assist_window_ms"]) * transport.sample_rate / 1000.0
	return absf(requested_audio_frame - nearest) <= window

func request(choice: Dictionary, rendered_frames: int, audible_frame: float) -> Dictionary:
	if run.get("phase","") == "transition":
		return {"accepted":false,"reason":"时代正在跨越，音乐继续；新乐章开始后恢复介入。"}
	if bool(lifecycle["ended"]) or not _legal(choice):
		return {"accepted":false,"reason":"Proposal is unavailable or target is no longer legal"}
	transport.rendered_frames = rendered_frames
	var at := city_frame(phrase_index+1)
	while at < rendered_frames: at += transport.phrase_frame(1)
	pending = choice.duplicate(true)
	pending["frame"] = at
	pending["requested_audio_frame"] = audible_frame
	pending["on_grid"] = is_on_grid(audible_frame)
	return {"accepted":true,"frame":at,"requested_audio_frame":audible_frame}

func cancel_pending() -> void:
	pending.clear()

func settle(at: int) -> Dictionary:
	if run.get("phase","") == "transition":
		assert(at == next_city_boundary(),"Only process the next held city boundary")
		return Era.held_boundary(self,at)
	assert(at == city_frame(phrase_index+1), "Only settle the next complete city phrase")
	phrase_index += 1
	if bool(lifecycle["ended"]):
		last_result = {"frame":at,"ended":true,"choice":{}}
		return last_result.duplicate(true)
	var before := city.duplicate(true)
	var old_edges := harmony.adjacency(before)
	var old_roads := road_marks.duplicate(true)
	for id in silent_until.keys():
		if at >= int(silent_until[id]):
			silent_until.erase(id)
	var applied: Dictionary = {}
	var costs: Dictionary = {}
	if not pending.is_empty() and int(pending["frame"]) == at:
		if _legal(pending):
			applied = pending.duplicate(true)
			if applied.get("verb","") == "draft":
				var next := {"start":applied["start"].duplicate(),"end":applied["end"].duplicate(),"bias":applied["bias"]}
				applied["redrawn"] = not gravity_band.is_empty() and gravity_band != next
				if applied["redrawn"]:
					draft_pause_until = at+transport.phrase_frame(int(growth_values["draft"]["redraw_pause_phrases"]))
				gravity_band = next
			elif applied.get("verb","") == "tread":
				var a := Vector2i(applied["start"][0],applied["start"][1])
				var b := Vector2i(applied["end"][0],applied["end"][1])
				var ends := Roads.endpoints(a,b)
				var count := Roads.count(road_marks,a,b)+1
				road_marks[Roads.key(a,b)] = {"start":ends[0],"end":ends[1],"count":count,"frame":at}
				applied["tread_count"] = count
				applied["formed"] = Roads.blocked(road_marks,a,b)
				applied["disconnected"] = []
			else:
				var item := proposal(applied["proposal_id"])
				if applied.get("verb","") == "release":
					growth_serial += 1
					var point := Schema.create("anchor_%03d" % growth_serial,"commercial" if int(applied["midi"]) == 52 else "residential",Vector2i(int(applied["target"][0]),int(applied["target"][1])))
					point["current_midi"] = int(applied["midi"])
					point["is_anchor"] = true
					point["anchor_id"] = point["district_id"]
					point["voice_level"] = growth_values["growth"]["new_voice_level"]
					point["form"] = "共鸣点"
					city.append(point)
					applied["district_id"] = point["district_id"]
					item = {"verb":"release","district_id":point["district_id"]}
				var district := _district(item["district_id"])
				applied["verb"] = item["verb"]
				applied["district_id"] = item["district_id"]
				if item["verb"] == "retune":
					district["current_midi"] = int(applied["target"])
					costs[item["district_id"]] = float(settings["retune_cost"])
				elif item["verb"] == "relocate":
					district["footprint"] = [applied["target"].duplicate()]
					silent_until[item["district_id"]] = city_frame(phrase_index + int(settings["relocate_silent_phrases"]))
				if item["verb"] != "release" and bool(applied["on_grid"]):
					costs[item["district_id"]] = float(costs.get(item["district_id"],0.0)) + float(settings["landing_bonus"])
		pending.clear()
	var growth_events: Array[Dictionary] = []
	if growth_enabled:
		growth_events = Growth.advance(self,at)
		if applied.get("verb","") == "release":
			growth_events.append({"district_id":applied["district_id"],"kind":"birth","frame":at+transport.beat_frame(1),"form":"共鸣点"})
	if applied.get("verb","") == "tread" and applied["formed"]:
		for d in before:
			var family: String = d.get("anchor_id","")
			if not family.is_empty() and Growth.connected(before,family,old_roads).has(d["district_id"]) and not Growth.connected(city,family,road_marks).has(d["district_id"]):
				applied["disconnected"].append(d["district_id"])
	var ring_result := Ring.advance(city,road_marks,rings,at,growth_values) if growth_enabled else {"rings":{},"events":[],"messages":PackedStringArray()}
	rings = ring_result["rings"]
	var edges := harmony.adjacency(city)
	var resonance := harmony.resonance(city,edges)
	var next_v := harmony.vitality(city,edges,resonance,costs)
	for district in city:
		district["vitality"] = next_v[district["district_id"]]
	lifecycle = harmony.lifecycle(lifecycle,resonance)
	var refresh_frames := roundi(float(settings["refresh_seconds"]) * transport.sample_rate)
	if at % refresh_frames == 0 or growth_enabled:
		refresh_cycle = at / refresh_frames
		_refresh_catalog()
	last_result = {"frame":at,"choice":applied,"before":before,"after":city.duplicate(true),
		"before_edges":old_edges,"after_edges":edges,"before_r":harmony.resonance(before,old_edges),
		"after_r":resonance,"growth_events":growth_events,"ring_events":ring_result["events"],"ring_messages":ring_result["messages"],"intervention_deltas":costs.duplicate(true),"silent_until":silent_until.duplicate(true)}
	Era.apply_assets(city)
	last_result["after"] = city.duplicate(true)
	Era.after_settle(self,at)
	return last_result.duplicate(true)

func snapshot() -> Dictionary:
	return {"city":city.duplicate(true),"rng":rng.snapshot(),"phrase_index":phrase_index,"run":run.duplicate(true),
		"rings":rings.duplicate(true),"growth_enabled":growth_enabled,"growth_serial":growth_serial,"road_marks":road_marks.duplicate(true),"gravity_band":gravity_band.duplicate(true),"draft_pause_until":draft_pause_until,"refresh_cycle":refresh_cycle,"catalog":catalog.duplicate(true),"pending":pending.duplicate(true),
		"silent_until":silent_until.duplicate(true),"lifecycle":lifecycle.duplicate(true),"last_result":last_result.duplicate(true)}

func restore(saved: Dictionary) -> void:
	city = saved["city"].duplicate(true)
	rings = saved.get("rings",{}).duplicate(true)
	road_marks = saved.get("road_marks",{}).duplicate(true)
	harmony.road_marks = road_marks
	rng.restore(saved["rng"])
	phrase_index = int(saved["phrase_index"])
	run = saved.get("run",{}).duplicate(true)
	Era.configure(self)
	growth_enabled = bool(saved.get("growth_enabled",false))
	growth_serial = int(saved.get("growth_serial",0))
	gravity_band = saved.get("gravity_band",{}).duplicate(true)
	draft_pause_until = int(saved.get("draft_pause_until",0))
	refresh_cycle = int(saved["refresh_cycle"])
	catalog.assign(saved["catalog"].duplicate(true))
	pending = saved["pending"].duplicate(true)
	silent_until = saved["silent_until"].duplicate(true)
	lifecycle = saved["lifecycle"].duplicate(true)
	last_result = saved["last_result"].duplicate(true)

func fork() -> CityInterventions:
	var copy: CityInterventions = get_script().new(city,rng.seed_hex,rng.snapshot(),run)
	copy.restore(snapshot())
	return copy
