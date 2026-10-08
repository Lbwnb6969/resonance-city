class_name MixContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if Contract.selected_case("fader") == "ducking":
		_ducking_contract()
		return
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

func _ducking_contract() -> void:
	var test := Contract.new("AUDIO-003","ducking")
	var city: Array = [Schema.create("a","residential",Vector2i(8,6)),Schema.create("b","commercial",Vector2i(8,7))]
	var clean := Synth.new(city)
	var listened := Synth.new(city)
	listened.begin_duck()
	listened.emphasized_id = "a"
	var before := clean.initial_state()
	var after := listened.initial_state()
	var same_drone := true
	var dry_energy := {"a":0.0,"b":0.0}
	var wet_energy := {"a":0.0,"b":0.0}
	for at in range(4096):
		var original := clean.render_tracks(before,at,22050)
		var changed := listened.render_tracks(after,at,22050)
		for id in ["a","b"]:
			same_drone = same_drone and original["District_"+id+"_Drone"] == changed["District_"+id+"_Drone"]
			dry_energy[id] += original["District_"+id+"_Rhythm"].length_squared()
			wet_energy[id] += changed["District_"+id+"_Rhythm"].length_squared()
	test.check(same_drone,"All drones stay sample-identical under white-list ducking and target emphasis")
	test.check(before == after,"Listener processing does not modify phases or filters")
	test.check(absf(wet_energy["b"]/dry_energy["b"]-pow(listened.duck_level,2)) < 1e-6,"Other rhythm uses exactly the approved -6dB duck")
	test.check(absf(wet_energy["a"]/dry_energy["a"]-pow(listened.duck_level*listened.emphasis_level,2)) < 1e-6,"Selected non-drone has +3dB emphasis on top of duck")
	var rate := int(listened.values["timing"]["sample_rate"])
	var release_frames := roundi(float(listened.values["mixing"]["duck_release_seconds"])*rate)
	listened.release_duck(4096)
	test.check(listened.rhythm_level(4096,rate) == listened.duck_level,"Release begins at the actual audio frame")
	test.check(listened.rhythm_level(4096+release_frames,rate) == 1.0,"Release reaches unity at exactly 300ms")
	test.check(listened.rhythm_level(4096+release_frames-1,rate) < 1.0,"No premature restore on video frame")
	var canonical := Synth.new(city)
	var blocked := Synth.new(city)
	canonical.begin_duck()
	blocked.begin_duck()
	canonical.emphasized_id = "b"
	blocked.emphasized_id = "b"
	var canonical_state := canonical.initial_state()
	var block_state := blocked.initial_state()
	var block := blocked.render_block(block_state,0,1024,rate)
	var same := true
	for at in range(block.size()):
		same = same and block[at] == canonical._mix_frame(canonical_state,at,rate)
	test.check(same and canonical_state == block_state,"Processed block path matches canonical PCM and state")
	test.details = {"drone":"exact PCM unchanged","other_rhythm_ratio":wet_energy["b"]/dry_energy["b"],
		"selected_rhythm_ratio":wet_energy["a"]/dry_energy["a"],"release_frames":release_frames}
	test.finish(self,"White-list and emphasis processing; Environment/UI absent in P0")
