extends RefCounted
const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Injector = preload("res://tests/rebellion_fixture.gd")
const Values = preload("res://scripts/spec_values.gd")
static func run(tree: SceneTree) -> void:
	var test := Contract.new("CITY-003","rebellion_fixture")
	var settings: Dictionary = Values.load_values()["rebellion_fixture"]
	var deviations: Array[float] = [-float(settings["maximum_deviation"]),-float(settings["minimum_deviation"]),float(settings["minimum_deviation"]),float(settings["maximum_deviation"])]
	var details: Array = []
	for rate in [int(Values.load_values()["timing"]["sample_rate"]),44100]:
		for deviation in deviations:
			var city: Array = [Schema.create("home","residential",Vector2i(5,8)),Schema.create("other","commercial",Vector2i(9,8))]
			var synth := Synth.new(city)
			var renderer := Renderer.new(rate)
			renderer.source = synth._mix_frame
			renderer.state = synth.initial_state()
			# Give the oscillator a real pre-injection phase, shared by every control.
			renderer.render(31)
			var boundary: int = renderer.transport.phrase_frame(1)
			var saved := renderer.snapshot()
			test.check(not Injector.inject(synth,renderer,"home",0.0,boundary) and not Injector.inject(synth,renderer,"missing",deviation,boundary) and not Injector.inject(synth,renderer,"home",deviation,boundary-1) and saved == renderer.snapshot(),"Invalid fixture injection is rejected without state mutation")
			renderer.transport.rendered_frames = boundary
			var phase_before: float = renderer.state["_phase_home"]
			test.check(Injector.inject(synth,renderer,"home",deviation,boundary) and renderer.state["home"] == city[0]["current_midi"]+int(settings["pitch_offset"]) and renderer.state["_phase_home"] == phase_before,"Explicit +1 pitch and shifted rhythm start without oscillator reset")
			var plain: Dictionary = renderer.state.duplicate(true)
			plain.erase("_rhythm_fixture_home")
			var shifted: Dictionary = renderer.state.duplicate(true)
			var drone_same := true
			var other_same := true
			for offset in range(511):
				var a: Dictionary = synth.render_tracks(shifted,boundary+offset,rate)
				var b: Dictionary = synth.render_tracks(plain,boundary+offset,rate)
				drone_same = drone_same and a["District_home_Drone"] == b["District_home_Drone"]
				other_same = other_same and a["District_other_Drone"] == b["District_other_Drone"] and a["District_other_Rhythm"] == b["District_other_Rhythm"]
			test.check(drone_same and other_same,"Rate drift leaves same-pitch drone and all unrelated tracks sample-identical")
			# Compare a complete actual rhythm phrase fragment with drift and without.
			synth.solo_id = "home"
			synth.active_layers = ["rhythm"]
			var count: int = renderer.transport.bar_frame(2)
			var a: PackedVector2Array = synth.render_block(renderer.state.duplicate(true),boundary,count,rate)
			var unshifted: Dictionary = renderer.state.duplicate(true)
			unshifted.erase("_rhythm_fixture_home")
			var b: PackedVector2Array = synth.render_block(unshifted,boundary,count,rate)
			var difference := 0.0
			var energy := 0.0
			for index in range(count):
				difference += (a[index]-b[index]).length_squared()
				energy += a[index].length_squared()
			test.check(difference > 0.0 and energy > 0.0,"Actual shifted rhythm differs over two bars and remains audible")
			synth.solo_id = ""
			synth.active_layers = ["drone","rhythm","ornament"]
			var scalar: Dictionary = renderer.state.duplicate(true)
			var blocked: Dictionary = renderer.state.duplicate(true)
			var block: PackedVector2Array = synth.render_block(blocked,boundary,257,rate)
			var equal := true
			for offset in range(block.size()): equal = equal and block[offset] == synth._mix_frame(scalar,boundary+offset,rate)
			test.check(equal and blocked == scalar,"Drifting fixture block and scalar PCM/state match exactly")
			var fork := Renderer.new(rate)
			fork.source = synth._mix_frame
			fork.restore(renderer.snapshot())
			test.check(renderer.render(127) == fork.render(127) and renderer.snapshot() == fork.snapshot(),"PCM snapshot resumes exact drifting rhythm and pitch phase")
			var restore_at: int = renderer.transport.phrase_frame(2)
			renderer.transport.rendered_frames = restore_at
			phase_before = renderer.state["_phase_home"]
			test.check(Injector.restore(renderer,"home",restore_at) and renderer.state["home"] == city[0]["current_midi"] and not renderer.state.has("_rhythm_fixture_home") and renderer.state["_phase_home"] == phase_before,"Explicit legal-boundary restoration removes drift and restores pitch without phase reset")
			var normal := Synth.new(city)
			var restored: Dictionary = renderer.state.duplicate(true)
			var reference: Dictionary = renderer.state.duplicate(true)
			test.check(synth.render_block(restored,restore_at,257,rate) == normal.render_block(reference,restore_at,257,rate) and restored == reference,"Returned rhythm and drone are exact ordinary paths at the same live phase")
			details.append({"sample_rate":rate,"deviation":deviation,"speed":1.0+deviation,"rhythm_difference_energy":difference,"rhythm_energy":energy,"boundary":boundary,"restore_at":restore_at})
	var baseline = load("res://废弃/tests/第53轮前混音基线.gd")
	var normal_city: Array = [Schema.create("home","residential",Vector2i(3,8)),Schema.create("shop","commercial",Vector2i(8,8)),Schema.create("factory","industrial",Vector2i(13,8))]
	var current := Synth.new(normal_city)
	var prior: RefCounted = baseline.new(normal_city)
	current.guard_enabled = true
	prior.guard_enabled = true
	var a_state: Dictionary = current.initial_state()
	var b_state: Dictionary = prior.initial_state()
	var rate: int = Values.load_values()["timing"]["sample_rate"]
	test.check(current.render_block(a_state,0,rate,rate) == prior.render_block(b_state,0,rate,rate) and a_state == b_state,"Ordinary three-type PCM and guard state remain byte-identical to pre-change source")
	test.details = {"fixtures":details,"automated_rebellion":false,"capture_enclosure":false,"actual_pcm_source":"DistrictSynth production scalar/block paths with explicit test state","drone_comparison":"same shifted pitch with drift on/off; +1 pitch itself intentionally changes frequency"}
	test.finish(tree,"P0 explicit injection/restore only; +1 semitone, +/-5 and +/-12% rhythm-envelope drift, unchanged same-pitch drone/unrelated tracks, scalar/block/snapshot equality; excludes automatic trigger, enclosure/capture gameplay, human listening and main-scene feature activation")
