class_name MixContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if Contract.selected_case("fader") == "signal_protection":
		load("res://tests/signal_protection_contract.gd").run(self)
		return
	if Contract.selected_case("fader") == "beat_assist":
		_assist_contract()
		return
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

func _assist_contract() -> void:
	var test := Contract.new("AUDIO-004","beat_assist")
	var city: Array = [Schema.create("a","residential",Vector2i(8,6)),Schema.create("b","residential",Vector2i(8,7))]
	city[1]["current_midi"] = 49
	var standard := Synth.new(city)
	var off := Synth.new(city)
	off.assist_enabled = false
	var standard_state := standard.initial_state()
	var off_state := off.initial_state()
	var rate := int(standard.values["timing"]["sample_rate"])
	test.check(standard.assist_enabled and standard.device_mode == "standard","Default switch ON but standard mode produces no helpers")
	test.check(standard.render_block(standard_state,0,2048,rate) == off.render_block(off_state,0,2048,rate),"Default output is exactly OFF PCM")
	var narrow := Synth.new(city)
	narrow.device_mode = "narrowband"
	var state := narrow.initial_state()
	var routes := narrow.assist_routes(state)
	test.check(routes.size() == 2,"Adjacent real slow minor second gets exactly one companion per district")
	var delta := narrow.frequency(49)-narrow.frequency(48)
	test.check(absf(delta-7.78) < 0.01,"Original pair difference is 7.78Hz, not high-octave 15.56Hz")
	var phase_difference := delta*0.5/delta
	test.check(absf(narrow.assist_envelope(phase_difference)-1.0/3.0) < 1e-12 and narrow.assist_envelope(delta/delta) == 1.0,"AM half/full original beat period gives the declared depth extrema")
	state["_phase_a"] = 0.173
	state["_phase_b"] = 0.319
	var saved := state.duplicate(true)
	var actual := narrow._assist_tracks(state,100,routes)
	var level := pow(10.0,-6.0/20.0)
	var expected := narrow._wave("residential",0.173*2.0)*narrow.drone_gain*level*(1.0+0.5*cos(TAU*(0.173-0.319)))/1.5
	test.check(actual["District_a_Assist"] == expected*narrow.routing[0]["stereo"],"Actual companion is high-octave source at -6dB with original-phase AM")
	test.check(state == saved,"Derived helper does not consume or reset phase state")
	var muted := Synth.new(city)
	muted.device_mode = "narrowband"
	muted.set_mute("a",true)
	var clean_state := narrow.initial_state()
	var muted_state := muted.initial_state()
	var peer_equal := true
	var muted_zero := true
	for at in range(1024):
		var clean_tracks := narrow.render_tracks(clean_state,at,rate)
		var mute_tracks := muted.render_tracks(muted_state,at,rate)
		peer_equal = peer_equal and clean_tracks["District_b_Assist"] == mute_tracks["District_b_Assist"]
		muted_zero = muted_zero and mute_tracks["District_a_Assist"] == Vector2.ZERO
	test.check(peer_equal and muted_zero and clean_state == muted_state,"Mute zeros own companion while other PCM and phases remain equal")
	muted.set_solo("a")
	test.check(muted.render_tracks(muted_state,1024,rate).values().all(func(value: Vector2) -> bool: return value == Vector2.ZERO),"Mute priority still holds with helper enabled")
	var canonical := Synth.new(city)
	var blocked := Synth.new(city)
	canonical.device_mode = "narrowband"
	blocked.device_mode = "narrowband"
	var canonical_state := canonical.initial_state()
	var block_state := blocked.initial_state()
	var block := blocked.render_block(block_state,0,2048,rate)
	var equal_pcm := true
	for at in range(block.size()):
		equal_pcm = equal_pcm and block[at] == canonical._mix_frame(canonical_state,at,rate)
	test.check(equal_pcm and canonical_state == block_state,"Assisted block path is sample-identical to canonical source")
	city[1]["current_midi"] = 54
	var tritone := Synth.new(city)
	tritone.device_mode = "narrowband"
	test.check(tritone.assist_routes(tritone.initial_state()).is_empty(),"Tritone cannot produce a counterfeit slow AM helper")
	city[1]["current_midi"] = 49
	city[1]["footprint"] = [[8,9]]
	narrow.update_city(city,state)
	test.check(narrow.assist_routes(state).is_empty(),"Relocation immediately removes nonadjacent helper pairs")
	var Session = load("res://scripts/proposals/city_interventions.gd")
	var Model = load("res://scripts/audio/city_audio_model.gd")
	var model = Model.new(Session.new(city,"0000000000000001"))
	model.synth.device_mode = "narrowband"
	model.synth.assist_enabled = false
	var copy = model.fork()
	test.check(copy.snapshot() == model.snapshot(),"Preview fork preserves both switch and manual device mode")
	test.details = {"original_difference_hz":delta,"companion_level_db":-6,"depth":0.5,"standard":"exact OFF PCM","human_speaker":"PENDING"}
	test.finish(self,"Technical helper routing passes; loudness/RMS and human speaker evidence are separate")
