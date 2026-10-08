class_name CityHarmony
extends RefCounted

const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

const Roads = preload("res://scripts/city/city_roads.gd")
var road_marks: Dictionary = {}
var settings: Dictionary
var space: Dictionary

func _init() -> void:
	var values := Values.load_values()
	settings = values["harmony"]
	space = values["city"]

func interval(first_midi: int, second_midi: int) -> Dictionary:
	return settings["intervals"][str(absi(first_midi - second_midi) % 12)].duplicate(true)

func boundary_weight(cells: int, industrial: bool) -> float:
	var weight := minf(float(settings["weight_base"]) + float(settings["weight_increment"]) * (cells - 1), float(settings["weight_cap"]))
	return weight * float(settings["industrial_weight"]) if industrial else weight

func graph_error(city: Array, edges: Array) -> String:
	var ids: Dictionary = {}
	for district in city:
		var id := str(district["district_id"])
		if ids.has(id):
			return "duplicate district"
		ids[id] = district
	var pairs: Dictionary = {}
	for edge in edges:
		var a := str(edge["a"])
		var b := str(edge["b"])
		if a == b or not ids.has(a) or not ids.has(b) or int(edge["shared_boundary_cells"]) <= 0:
			return "invalid edge"
		var pair := [a, b]
		pair.sort()
		var key := JSON.stringify(pair)
		if pairs.has(key):
			return "duplicate undirected edge"
		pairs[key] = true
	return ""

func resonance(city: Array, edges: Array) -> float:
	assert(graph_error(city, edges).is_empty())
	if edges.is_empty():
		return float(space["empty_resonance"])
	var ids: Dictionary = {}
	for district in city:
		ids[str(district["district_id"])] = district
	var weighted_score := 0.0
	var total_weight := 0.0
	for edge in edges:
		var a: Dictionary = ids[str(edge["a"])]
		var b: Dictionary = ids[str(edge["b"])]
		var weight := boundary_weight(int(edge["shared_boundary_cells"]), a["type"] == "industrial" or b["type"] == "industrial")
		weighted_score += weight * float(interval(int(a["current_midi"]), int(b["current_midi"]))["score"])
		total_weight += weight
	return float(settings["resonance_scale"]) * weighted_score / total_weight

func adjacency(city: Array) -> Array[Dictionary]:
	var cells: Dictionary = {}
	var result: Array[Dictionary] = []
	for district in city:
		var location := Schema.cell(district)
		assert(not cells.has(location), "Overlapping districts")
		assert(location.x >= 0 and location.y >= 0 and location.x < int(space["width"]) and location.y < int(space["height"]))
		cells[location] = district["district_id"]
	# Only right/down: count each shared edge exactly once.
	for location in cells:
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = location + direction
			if cells.has(neighbor) and not Roads.blocked(road_marks,location,neighbor):
				result.append({"a": cells[location], "b": cells[neighbor], "shared_boundary_cells": 1})
	return result

func vitality(city: Array, edges: Array, current_resonance: float, intervention_deltas: Dictionary = {}) -> Dictionary:
	assert(graph_error(city, edges).is_empty())
	var by_id: Dictionary = {}
	var deltas: Dictionary = {}
	for district in city:
		var id := str(district["district_id"])
		by_id[id] = district
		deltas[id] = float(settings["base_growth"]) - (float(settings["decay"]) if current_resonance < float(settings["decay_threshold"]) else 0.0)
	for edge in edges:
		var a := str(edge["a"])
		var b := str(edge["b"])
		var delta := float(interval(int(by_id[a]["current_midi"]), int(by_id[b]["current_midi"]))["vitality_delta"])
		deltas[a] += delta
		deltas[b] += delta
	var result: Dictionary = {}
	for id in by_id:
		var delta := float(deltas[id]) + float(intervention_deltas.get(id, 0.0))
		delta = clampf(delta, -float(settings["net_change_cap"]), float(settings["net_change_cap"]))
		result[id] = clampf(float(by_id[id]["vitality"]) + delta, float(settings["minimum_vitality"]), float(settings["maximum_vitality"]))
	return result

func lifecycle(previous: Dictionary, current_resonance: float) -> Dictionary:
	var result := previous.duplicate(true)
	if bool(result["ended"]):
		return result
	if current_resonance < float(settings["gray_entry"]):
		result["gray"] = true
	elif current_resonance > float(settings["gray_exit"]):
		result["gray"] = false
	result["low_phrases"] = int(result["low_phrases"]) + 1 if current_resonance < float(settings["gray_entry"]) else 0
	result["ended"] = int(result["low_phrases"]) >= int(settings["collapse_phrases"])
	return result
