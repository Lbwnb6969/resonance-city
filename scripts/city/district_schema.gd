class_name DistrictSchema
extends RefCounted

const Values = preload("res://scripts/spec_values.gd")

static func create(id: String, type: String, cell: Vector2i) -> Dictionary:
	var values := Values.load_values()
	assert(values["voices"].has(type) and not id.is_empty())
	var voice: Dictionary = values["voices"][type]
	return {"district_id": id, "type": type, "footprint": [[cell.x, cell.y]],
		"shared_boundary_cells": {}, "base_midi": int(voice["base_midi"]),
		"current_midi": int(voice["base_midi"]), "vitality": values["harmony"]["initial_vitality"],
		"layers": {"drone": {"continuous": true}, "rhythm": {"signature": voice["rhythm_signature"]},
			"ornament": {"enabled": false}},
		"state": "normal", "debt_edges": [], "manifest_id": ""}

static func cell(district: Dictionary) -> Vector2i:
	return Vector2i(int(district["footprint"][0][0]), int(district["footprint"][0][1]))
