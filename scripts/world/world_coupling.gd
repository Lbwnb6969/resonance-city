class_name WorldCoupling
extends RefCounted

const Config = preload("res://scripts/world/world_values.gd")
var space: Dictionary = Config.load_values()["space"]
var harmony: Dictionary = Config.load_values()["harmony"]

static func position_of(entity: Dictionary) -> Vector2:
	var p: Array = entity["position"]
	return Vector2(float(p[0]),float(p[1]))

func distance_weight(gap: float, sigma_multiplier: float = 1.0) -> float:
	if gap > float(space["gap_cutoff"]): return 0.0
	if gap <= 0.0: return float(space["base_coupling"])
	var sigma := float(space["distance_sigma"])*sigma_multiplier
	return float(space["base_coupling"])*exp(-pow(gap/sigma,2.0))

func coefficient(a: Dictionary, b: Dictionary, environment: Dictionary = {}) -> float:
	var gap := position_of(a).distance_to(position_of(b))-float(a["radius"])-float(b["radius"])
	var industrial := float(space["industrial_factor"]) if a["type"] == "industrial" or b["type"] == "industrial" else 1.0
	var sigma_multiplier := 0.9 if str(a.get("placement_tier","")) == "L3" or str(b.get("placement_tier","")) == "L3" else 1.0
	var sigma := maxf(float(environment.get("sigma_a",1.0)),float(environment.get("sigma_b",1.0)))*sigma_multiplier
	return distance_weight(gap,sigma)*float(environment.get("occlusion",1.0))*float(environment.get("terrain_factor",1.0))*industrial

func interval(first: int, second: int) -> Dictionary:
	return harmony["intervals"][str(absi(first-second)%12)]

func resonance(buildings: Array, edges: Array) -> float:
	var by_id: Dictionary = {}
	for building in buildings: by_id[building["district_id"]] = building
	return resonance_from_index(by_id,edges)

func resonance_from_index(by_id: Dictionary, edges: Array) -> float:
	var weighted := 0.0
	var total := 0.0
	for edge in edges:
		var weight := float(edge["coupling"])
		weighted += weight*float(interval(int(by_id[edge["a"]]["current_midi"]),int(by_id[edge["b"]]["current_midi"]))["score"])
		total += weight
	return float(harmony["empty_resonance"]) if total <= 0.0 else 100.0*weighted/total

func vitality(buildings: Array, edges: Array, resonance_value: float, actions: Dictionary = {}, musicality: Dictionary = {}, pair_bonuses: Dictionary = {}) -> Dictionary:
	var by_id: Dictionary = {}
	var deltas: Dictionary = {}
	for building in buildings:
		var id: String = building["district_id"]
		by_id[id] = building
		deltas[id] = float(harmony["base_growth"])-(float(harmony["decay"]) if resonance_value < float(harmony["decay_threshold"]) else 0.0)
	for edge in edges:
		var a: String = edge["a"]
		var b: String = edge["b"]
		var delta := float(interval(int(by_id[a]["current_midi"]),int(by_id[b]["current_midi"]))["vitality_delta"])
		deltas[a] += snappedf(delta*float(musicality.get(a,{}).get("dv_scale",1.0)),0.5)
		deltas[b] += snappedf(delta*float(musicality.get(b,{}).get("dv_scale",1.0)),0.5)
	var result: Dictionary = {}
	for id in by_id:
		var delta := clampf(float(deltas[id])+float(pair_bonuses.get(id,0.0))+float(actions.get(id,0.0)),-float(harmony["net_change_cap"]),float(harmony["net_change_cap"]))
		result[id] = clampf(float(by_id[id]["vitality"])+delta,float(harmony["minimum_vitality"]),float(harmony["maximum_vitality"]))
	return result
