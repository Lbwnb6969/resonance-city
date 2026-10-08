class_name HarmonyContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Harmony = preload("res://scripts/city/harmony.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test := Contract.new("HARM-001", Contract.selected_case("resonance"))
	test.check(test.case_name == "resonance", "Supported case: resonance")
	var harmony := Harmony.new()
	var home := Schema.create("a", "residential", Vector2i(0, 0))
	var other := Schema.create("b", "residential", Vector2i(1, 0))
	var shop := Schema.create("b", "commercial", Vector2i(1, 0))
	var industry := Schema.create("b", "industrial", Vector2i(1, 0))
	var edge: Array = [{"a": "a", "b": "b", "shared_boundary_cells": 1}]
	test.check(harmony.resonance([home, other], edge) == 100, "H3 unison R=100 exactly")
	test.check(harmony.resonance([home, shop], edge) == 85, "H3 major third R=85 exactly")
	test.check(harmony.resonance([home, industry], edge) == 0, "H3 tritone R=0 exactly")
	test.check(harmony.resonance([home], []) == 100, "Approved empty-edge R=100")
	test.check(harmony.boundary_weight(1, false) == 1, "Single shared cell weight=1")
	test.check(harmony.boundary_weight(3, false) == 1.3, "Shared cell aggregation")
	test.check(harmony.boundary_weight(100, true) == 2.6, "Weight capped before industrial multiplier")
	var industrial_peer := industry.duplicate(true)
	industrial_peer["district_id"] = "a"
	test.check(harmony.resonance([industrial_peer, industry], edge) == 100, "Two industrial endpoints multiply weight once")
	test.check(harmony.boundary_weight(1, true) == 1.3, "Industrial coefficient once")
	var center := home.duplicate(true)
	var same := other.duplicate(true)
	var third := other.duplicate(true)
	third["district_id"] = "c"
	var fourth := other.duplicate(true)
	fourth["district_id"] = "d"
	test.check(harmony.resonance([center, same, third, fourth], [
		{"a":"a","b":"b","shared_boundary_cells":1}, {"a":"a","b":"c","shared_boundary_cells":1},
		{"a":"a","b":"d","shared_boundary_cells":1}]) == 100, "H3 three unison edges R=100")
	var extra := shop.duplicate(true)
	extra["district_id"] = "c"
	var mixed: Array = [edge[0], {"a":"a","b":"c","shared_boundary_cells":3}]
	var actual := harmony.resonance([home, industry, extra], mixed)
	test.check(absf(actual - 42.5) <= float(harmony.space["comparison_tolerance"]), "Industrial/shared-cell mixed graph has R=42.5")
	test.check(harmony.resonance([home, industry, extra], mixed) == actual, "R has no history or extra deductions")
	var reversed: Array = [edge[0], {"a":"b","b":"a","shared_boundary_cells":1}]
	test.check(harmony.graph_error([home, shop], reversed) == "duplicate undirected edge", "Reverse duplicate rejected")
	var diagonal := Schema.create("d", "residential", Vector2i(1, 1))
	var neighbors := harmony.adjacency([home, shop, diagonal])
	test.check(neighbors.size() == 2, "Four-way adjacency excludes diagonal")
	test.check(harmony.adjacency([home, diagonal]).is_empty(), "Diagonal-only city has no edge")
	test.check(harmony.interval(48, 60)["score"] == 1, "Octave is unison pitch class")
	test.check(harmony.interval(48, 53)["score"] == 0.9, "Perfect fourth remains reachable")
	test.details = {"mixed_graph_resonance": actual, "deterministic_fixture_tolerance": 0,
		"multiedge_tolerance": harmony.space["comparison_tolerance"]}
	test.finish(self, "Pure R, direct graph fixtures, weights and P0 single-cell four-way adjacency")
