class_name CityHarmony
extends RefCounted

const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

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
			if cells.has(neighbor):
				result.append({"a": cells[location], "b": cells[neighbor], "shared_boundary_cells": 1})
	return result
