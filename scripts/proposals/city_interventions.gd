class_name CityInterventions
extends RefCounted
## Pure city transaction used by playback and preview forks.

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
var refresh_cycle := 0
var catalog: Array[Dictionary] = []
var pending: Dictionary = {}
var silent_until: Dictionary = {}
var lifecycle := {"gray":false, "low_phrases":0, "ended":false}
var last_result: Dictionary = {}

func _init(initial_city: Array, seed: String, random_state: Dictionary = {}) -> void:
	city = initial_city.duplicate(true)
	rng = RandomStreams.new(seed)
	if not random_state.is_empty():
		rng.restore(random_state)
	settings = Values.load_values()["proposals"]
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
	var space: Dictionary = Values.load_values()["city"]
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

func _legal(choice: Dictionary) -> bool:
	var item := proposal(str(choice.get("proposal_id","")))
	if item.is_empty() or _district(item["district_id"]).is_empty():
		return false
	var target: Variant = choice.get("target")
	if item["verb"] == "retune":
		return target is int and item["allowed_pitches"].has(target) and _pitches(item["district_id"]).has(target)
	return target is Array and target.size() == 2 and item["targets"].has(target) and _empty_cells().has(target)

func is_on_grid(requested_audio_frame: float) -> bool:
	var period := transport.phrase_frame(1)
	var nearest := roundi(requested_audio_frame / period) * period
	var window := float(transport.timing["beat_assist_window_ms"]) * transport.sample_rate / 1000.0
	return absf(requested_audio_frame - nearest) <= window

func request(choice: Dictionary, rendered_frames: int, audible_frame: float) -> Dictionary:
	if bool(lifecycle["ended"]) or not _legal(choice):
		return {"accepted":false,"reason":"Proposal is unavailable or target is no longer legal"}
	transport.rendered_frames = maxi(rendered_frames, transport.phrase_frame(phrase_index+1))
	var at := transport.next_phrase_frame()
	pending = choice.duplicate(true)
	pending["frame"] = at
	pending["requested_audio_frame"] = audible_frame
	pending["on_grid"] = is_on_grid(audible_frame)
	return {"accepted":true,"frame":at,"requested_audio_frame":audible_frame}

func cancel_pending() -> void:
	pending.clear()

func settle(at: int) -> Dictionary:
	assert(at == transport.phrase_frame(phrase_index+1), "Only settle the next complete phrase")
	phrase_index += 1
	if bool(lifecycle["ended"]):
		last_result = {"frame":at,"ended":true,"choice":{}}
		return last_result.duplicate(true)
	var before := city.duplicate(true)
	var old_edges := harmony.adjacency(before)
	for id in silent_until.keys():
		if at >= int(silent_until[id]):
			silent_until.erase(id)
	var applied: Dictionary = {}
	var costs: Dictionary = {}
	if not pending.is_empty() and int(pending["frame"]) == at:
		if _legal(pending):
			applied = pending.duplicate(true)
			var item := proposal(applied["proposal_id"])
			var district := _district(item["district_id"])
			applied["verb"] = item["verb"]
			applied["district_id"] = item["district_id"]
			if item["verb"] == "retune":
				district["current_midi"] = int(applied["target"])
				costs[item["district_id"]] = float(settings["retune_cost"])
			else:
				district["footprint"] = [applied["target"].duplicate()]
				silent_until[item["district_id"]] = transport.phrase_frame(phrase_index + int(settings["relocate_silent_phrases"]))
			if bool(applied["on_grid"]):
				costs[item["district_id"]] = float(costs.get(item["district_id"],0.0)) + float(settings["landing_bonus"])
		pending.clear()
	var edges := harmony.adjacency(city)
	var resonance := harmony.resonance(city,edges)
	var next_v := harmony.vitality(city,edges,resonance,costs)
	for district in city:
		district["vitality"] = next_v[district["district_id"]]
	lifecycle = harmony.lifecycle(lifecycle,resonance)
	var refresh_frames := roundi(float(settings["refresh_seconds"]) * transport.sample_rate)
	if at % refresh_frames == 0:
		refresh_cycle = at / refresh_frames
		_refresh_catalog()
	last_result = {"frame":at,"choice":applied,"before":before,"after":city.duplicate(true),
		"before_edges":old_edges,"after_edges":edges,"before_r":harmony.resonance(before,old_edges),
		"after_r":resonance,"intervention_deltas":costs.duplicate(true),"silent_until":silent_until.duplicate(true)}
	return last_result.duplicate(true)

func snapshot() -> Dictionary:
	return {"city":city.duplicate(true),"rng":rng.snapshot(),"phrase_index":phrase_index,
		"refresh_cycle":refresh_cycle,"catalog":catalog.duplicate(true),"pending":pending.duplicate(true),
		"silent_until":silent_until.duplicate(true),"lifecycle":lifecycle.duplicate(true),"last_result":last_result.duplicate(true)}

func restore(saved: Dictionary) -> void:
	city = saved["city"].duplicate(true)
	rng.restore(saved["rng"])
	phrase_index = int(saved["phrase_index"])
	refresh_cycle = int(saved["refresh_cycle"])
	catalog.assign(saved["catalog"].duplicate(true))
	pending = saved["pending"].duplicate(true)
	silent_until = saved["silent_until"].duplicate(true)
	lifecycle = saved["lifecycle"].duplicate(true)
	last_result = saved["last_result"].duplicate(true)

func fork() -> CityInterventions:
	var copy := CityInterventions.new(city,rng.seed_hex,rng.snapshot())
	copy.restore(snapshot())
	return copy
