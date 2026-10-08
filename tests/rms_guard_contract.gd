class_name RmsGuardContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

func _initialize() -> void:
	call_deferred("_run")

func _pressure(city: Array) -> DistrictSynth:
	var synth := Synth.new(city)
	synth.guard_enabled = true
	synth.drone_gain = 0.003
	synth.rhythm_gain = 0.2
	return synth

func _run() -> void:
	var test := Contract.new("AUDIO-004","rms_guard")
	var city: Array = [Schema.create("a","residential",Vector2i(8,6)),Schema.create("b","commercial",Vector2i(8,7))]
	var synth := _pressure(city)
	var rate := int(synth.values["timing"]["sample_rate"])
	var state := synth.initial_state()
	var drone_energy := 0.0
	var total_energy := 0.0
	var full_drone := 0.0
	var full_total := 0.0
	for at in range(rate*8):
		var tracks := synth.render_tracks(state,at,rate)
		var drone: Vector2 = tracks["District_a_Drone"]+tracks["District_b_Drone"]
		var total := Vector2.ZERO
		for sample in tracks.values():
			total += sample
		full_drone += drone.length_squared()
		full_total += total.length_squared()
		if at >= rate:
			drone_energy += drone.length_squared()
			total_energy += total.length_squared()
	var ratio := sqrt(drone_energy/total_energy)
	var full_ratio := sqrt(full_drone/full_total)
	test.check(float(state["_guard_factor"]) > 1.0,"Actual insufficient-drone input triggers automatic boost")
	test.check(ratio >= float(synth.values["rms_guard"]["minimum_ratio"]),"Measured steady output retains at least 25% drone RMS")
	test.check(full_ratio >= float(synth.values["rms_guard"]["minimum_ratio"]),"Full eight-second output also meets minimum after reactive warm-up")
	var ordinary := Synth.new(city)
	var guarded := Synth.new(city)
	guarded.guard_enabled = true
	var dry_state := ordinary.initial_state()
	var guarded_state := guarded.initial_state()
	var dry := ordinary.render_block(dry_state,0,rate,rate)
	var safe := guarded.render_block(guarded_state,0,rate,rate)
	test.check(dry == safe and guarded_state["_guard_factor"] == 1.0,"Sufficient production input stays exactly original PCM with no boost")
	var baseline := _pressure(city)
	var faders := _pressure(city)
	faders.set_mute("a",true)
	var baseline_state := baseline.initial_state()
	var controlled_state := faders.initial_state()
	var same_peer := true
	var zero_target := true
	for at in range(rate):
		var expected := baseline.render_tracks(baseline_state,at,rate)
		var actual := faders.render_tracks(controlled_state,at,rate)
		same_peer = same_peer and actual["District_b_Drone"] == expected["District_b_Drone"] and actual["District_b_Rhythm"] == expected["District_b_Rhythm"]
		zero_target = zero_target and actual["District_a_Drone"] == Vector2.ZERO and actual["District_a_Rhythm"] == Vector2.ZERO
	test.check(same_peer and zero_target,"Even under compensation, mute cannot change peer PCM or revive own layers")
	test.check(baseline_state == controlled_state,"Mute does not alter compensation reference, phase or filters")
	faders.set_mute("b",true)
	var all_zero := true
	for at in range(rate,rate+4096):
		all_zero = all_zero and faders.render_tracks(controlled_state,at,rate).values().all(func(value: Vector2) -> bool: return value == Vector2.ZERO)
	test.check(all_zero,"All-muted output remains strict zero instead of automatic drone revival")
	city[1]["current_midi"] = 49
	var canonical := _pressure(city)
	var blocked := _pressure(city)
	canonical.device_mode = "narrowband"
	blocked.device_mode = "narrowband"
	var canonical_state := canonical.initial_state()
	var block_state := blocked.initial_state()
	var same := true
	var at := 0
	for count in [128,4096,8820,113,2205,5000]:
		var block := blocked.render_block(block_state,at,count,rate)
		for offset in range(count):
			same = same and block[offset] == canonical._mix_frame(canonical_state,at+offset,rate)
		at += count
	test.check(same and canonical_state == block_state,"Variable blocks across RMS windows preserve exact canonical PCM and complete state")
	var listened := _pressure(city)
	var reference := _pressure(city)
	listened.begin_duck()
	listened.emphasized_id = "a"
	var listened_state := listened.initial_state()
	var reference_state := reference.initial_state()
	reference.render_block(reference_state,0,rate,rate)
	listened.render_block(listened_state,0,rate,rate)
	test.check(reference_state == listened_state,"Ducking/emphasis cannot change dry compensation statistics or oscillators")
	var model := Model.new(Session.new(city,"0000000000000001"))
	model.synth.guard_enabled = true
	var renderer := Renderer.new()
	renderer.source = model._mix_frame
	renderer.state = model.synth.initial_state()
	renderer.render(10000)
	var model_copy := model.fork()
	var restored := Renderer.new()
	restored.source = model_copy._mix_frame
	restored.restore(renderer.snapshot())
	test.check(model_copy.synth.guard_enabled and restored.render(5000) == renderer.render(5000),"Preview fork and renderer snapshot preserve in-progress RMS statistics")
	var absent := _pressure(city)
	absent.active_layers.assign(["rhythm"])
	var absent_state := absent.initial_state()
	absent.render_block(absent_state,0,rate,rate)
	test.check(absent_state["_guard_unavailable"] and absent_state["_guard_factor"] == 1.0,"No drone reports unavailable rather than inventing a signal")
	test.details = {"steady_ratio":ratio,"full_eight_second_ratio":full_ratio,"boost_factor":state["_guard_factor"],"window_frames":roundi(float(synth.values["rms_guard"]["window_seconds"])*rate),"gain":synth.gain,"human":"PENDING"}
	test.finish(self,"Reactive RMS guard plus exact controls/state; explicit pressure input does not alter production gains")
