class_name CityContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if Contract.selected_case("layers") == "rebellion_fixture":
		var fixture = load("res://tests/rebellion_fixture_checks.gd")
		fixture.run(self)
		return
	if Contract.selected_case("layers") == "initial_r":
		var checks = load("res://tests/generation_checks.gd")
		quit(0 if checks.city(self) == 0 else 1)
		return
	var test := Contract.new("CITY-001", Contract.selected_case("layers"))
	test.check(test.case_name == "layers", "Supported case: layers")
	var city: Array = [Schema.create("home", "residential", Vector2i(2, 8)),
		Schema.create("shop", "commercial", Vector2i(8, 8)), Schema.create("factory", "industrial", Vector2i(13, 8))]
	var expected := [48, 52, 54]
	for index in range(city.size()):
		var district: Dictionary = city[index]
		test.check(district["base_midi"] == expected[index] and district["current_midi"] == expected[index], "Initial MIDI " + str(expected[index]))
		test.check(district["layers"].has_all(["drone", "rhythm", "ornament"]), "All three layer interfaces")
		test.check(district["layers"]["drone"]["continuous"], "Drone is continuous")
		test.check(not district["layers"]["ornament"]["enabled"], "P0 ornament interface does not add random content")
	var synth := Synth.new(city)
	var state := synth.initial_state()
	var rate := 22050
	var energy: Dictionary = {}
	var quarter_energy: Dictionary = {}
	for at in range(rate * 2):
		var tracks := synth.render_tracks(state, at, rate)
		for key in tracks:
			var value: Vector2 = tracks[key]
			energy[key] = float(energy.get(key, 0.0)) + value.length_squared()
			if key.ends_with("_Drone"):
				var bucket := "%s_%d" % [key, int(at / (rate / 2))]
				quarter_energy[bucket] = float(quarter_energy.get(bucket, 0.0)) + value.length_squared()
	for district in city:
		var id := str(district["district_id"])
		test.check(float(energy["District_%s_Drone" % id]) > 0, "Drone is non-silent: " + id)
		test.check(float(energy["District_%s_Rhythm" % id]) > 0, "Rhythm is non-silent: " + id)
		test.check(float(energy["District_%s_Ornament" % id]) == 0, "Ornament remains an untriggered interface: " + id)
		for beat in range(4):
			test.check(float(quarter_energy["District_%s_Drone_%d" % [id, beat]]) > 0, "Drone continues for every beat: " + id)
		test.check(synth.routing[city.find(district)]["stereo"].x > 0 and synth.routing[city.find(district)]["stereo"].y > 0, "Both channels overlap: " + id)
	var phase_before := float(state["_phase_factory"])
	state["factory"] = 55
	synth._mix_frame(state, rate * 2, rate)
	test.check(is_equal_approx(float(state["_phase_factory"]), fposmod(phase_before + 196.0 / rate, 1.0)), "Industrial retune preserves ongoing oscillator phase")
	test.check(city[2]["type"] == "industrial", "Retune does not change industrial identity")
	test.check(synth.frequency(54) == 185.0, "Industrial fundamental remains 185 Hz")
	test.details = {"track_energy": energy, "drone_beat_energy": quarter_energy, "types": expected,
		"timbre_identity_human": "PENDING"}
	test.finish(self, "Three-layer schema, initial pitches, sustained drones and separate software buses; human timbre recognition pending")
