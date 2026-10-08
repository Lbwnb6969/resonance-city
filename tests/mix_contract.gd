class_name MixContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test := Contract.new("UI-001", Contract.selected_case("fader"))
	test.check(test.case_name == "fader", "Supported case: fader")
	var city: Array = [Schema.create("a","residential",Vector2i(2,6)), Schema.create("b","residential",Vector2i(8,6)), Schema.create("c","industrial",Vector2i(13,6))]
	var baseline := Synth.new(city)
	var faders := Synth.new(city)
	var clean := baseline.initial_state()
	var controlled := faders.initial_state()
	var saved_city := city.duplicate(true)
	test.check(faders.set_mute("a",true), "Mute targets a specific district")
	var same_others := true
	var zero_muted := true
	for at in range(2048):
		var expected := baseline.render_tracks(clean,at,22050)
		var actual := faders.render_tracks(controlled,at,22050)
		for key in expected:
			if key.begins_with("District_a_"):
				zero_muted = zero_muted and actual[key] == Vector2.ZERO
			else:
				same_others = same_others and actual[key] == expected[key]
	test.check(zero_muted, "Muted district all layers have exact zero output")
	test.check(same_others, "Other districts including same-type peer remain PCM-identical")
	test.check(clean == controlled, "Muted voices keep identical oscillator/filter progression")
	test.check(faders.set_solo("a"), "Single solo accepted")
	var solo_muted := faders.render_tracks(controlled,2048,22050)
	test.check(solo_muted.values().all(func(value: Vector2) -> bool: return value == Vector2.ZERO), "Mute takes priority over solo without compensation")
	faders.set_mute("a",false)
	var solo := faders.render_tracks(controlled,2049,22050)
	test.check(solo["District_a_Drone"] != Vector2.ZERO, "Unmuted solo target is audible")
	test.check(solo["District_b_Drone"] == Vector2.ZERO and solo["District_c_Drone"] == Vector2.ZERO, "Solo isolates exactly one district")
	test.check(faders.set_solo("b") and faders.solo_id == "b", "Second solo replaces the previous single solo")
	test.check(not faders.set_solo("unknown") and faders.solo_id == "b", "Invalid solo cannot change current selection")
	faders.set_solo("")
	# Compare after unmute against a continuously running dry state at the same frame.
	baseline.render_tracks(clean,2048,22050)
	baseline.render_tracks(clean,2049,22050)
	var expected := baseline.render_tracks(clean,2050,22050)
	var restored := faders.render_tracks(controlled,2050,22050)
	test.check(restored == expected, "Unmute restores exact continuous phase, not a restarted note")
	test.check(city == saved_city, "Faders never change city R/V/state inputs")
	var dry := Synth.new(city)
	var fast := Synth.new(city)
	var dry_state := dry.initial_state()
	var fast_state := fast.initial_state()
	var equivalent := true
	for at in range(512):
		var sum := Vector2.ZERO
		for value in dry.render_tracks(dry_state,at,22050).values():
			sum += value
		equivalent = equivalent and sum == fast._mix_frame(fast_state,at,22050)
	test.check(equivalent, "Playback fast path exactly equals separate bus sum")
	test.details = {"mute_energy":0,"other_tracks":"sample-for-sample equal","phase":"continuous","solo":"single; mute priority"}
	test.finish(self, "Per-district layers isolated with exact PCM and state preservation; no automatic compensation")
