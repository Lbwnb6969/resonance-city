class_name BlockAudioContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var test := Contract.new("AUDIO-002","block_pcm")
	var city: Array = Generator.new().generate("2026100800000001")["city"]
	var fast := Synth.new(city)
	var reference := Synth.new(city)
	var renderer := Renderer.new()
	renderer.source = fast._mix_frame
	renderer.state = fast.initial_state()
	var original := reference.initial_state()
	var same := true
	for amount in [257,503,1024]:
		var start := renderer.transport.rendered_frames
		var block := renderer.render(amount)
		for offset in range(amount):
			same = same and block[offset] == reference._mix_frame(original,start+offset,renderer.transport.sample_rate)
	test.check(same and renderer.state == original,"Nine-voice batched PCM and phase/filter state exactly equal canonical samples")
	fast.set_mute(city[0]["district_id"],true)
	reference.set_mute(city[0]["district_id"],true)
	fast.set_solo(city[1]["district_id"])
	reference.set_solo(city[1]["district_id"])
	var start := renderer.transport.rendered_frames
	var muted_block := renderer.render(1024)
	same = true
	for offset in range(muted_block.size()):
		same = same and muted_block[offset] == reference._mix_frame(original,start+offset,renderer.transport.sample_rate)
	test.check(same and renderer.state == original,"Mute/solo block path preserves sample values and running hidden voices")
	var session := Session.new(Generator.new().safe_fixture(),"2026100800000001")
	var model := Model.new(session)
	var canonical := Model.new(session.fork())
	var pcm := Renderer.new()
	pcm.source = model._mix_frame
	pcm.state = model.synth.initial_state()
	var phase := canonical.synth.initial_state()
	var boundary := session.transport.phrase_frame(1)
	var choice := {"proposal_id":"p0:0:industrial_0:relocate","target":[0,0]}
	model.session.request(choice,boundary-3,0.5*boundary)
	canonical.session.request(choice,boundary-3,0.5*boundary)
	pcm.transport.rendered_frames = boundary-3
	var seam := pcm.render(17)
	same = true
	for offset in range(seam.size()):
		same = same and seam[offset] == canonical._mix_frame(phase,boundary-3+offset,pcm.transport.sample_rate)
	test.check(same and phase == pcm.state and model.session.snapshot() == canonical.session.snapshot(),"Block straddling phrase commits and migration silence is sample-identical")
	test.check(model.session.city[6]["footprint"] == [[0,0]],"Batched path actually submits moved city")
	test.details = {"canonical":"DistrictSynth._mix_frame and CityAudioModel._mix_frame","comparison":"exact float32 PCM and double phase/filter state"}
	test.finish(self,"Block optimization preserves canonical synthesis, faders and phrase transaction semantics")
