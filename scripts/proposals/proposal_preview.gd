class_name ProposalPreview
extends RefCounted
## Builds only from immutable snapshots; safe to run on a worker Thread.

const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Values = preload("res://scripts/spec_values.gd")

static func model_from_snapshot(saved: Dictionary) -> CityAudioModel:
	var state: Dictionary = saved["session"]
	var session: CityInterventions = load("res://scripts/proposals/city_interventions.gd").new(state["city"],state["rng"]["seed_hex"],state["rng"],state.get("run",{}))
	session.restore(state)
	var model := Model.new(session)
	model.restore(saved)
	return model

static func forecast(session: CityInterventions, choice: Dictionary, rendered_frames: int, requested_audio_frame: float) -> Dictionary:
	var copy := session.fork()
	var request := copy.request(choice,rendered_frames,requested_audio_frame)
	if not request["accepted"]: return request
	var boundary := int(request["frame"])
	while copy.next_city_boundary() <= boundary:
		copy.settle(copy.next_city_boundary())
	if copy.last_result.get("choice",{}).get("proposal_id","") != choice.get("proposal_id",""):
		return {"accepted":false,"reason":"该方案在落定前会失效，请更换目标。"}
	return {"accepted":true,"commit_boundary":boundary,"result":copy.last_result.duplicate(true)}

static func build(model_saved: Dictionary, renderer_saved: Dictionary, choice: Dictionary, requested_audio_frame: float, listening: bool = false) -> Dictionary:
	var model := model_from_snapshot(model_saved)
	var output := Renderer.new()
	output.restore(renderer_saved)
	output.source = model._mix_frame
	var request := model.session.request(choice,output.transport.rendered_frames,requested_audio_frame)
	if not bool(request["accepted"]):
		return {"accepted":false,"reason":request["reason"]}
	var boundary := int(request["frame"])
	while output.transport.rendered_frames < boundary:
		output.render(mini(output.transport.sample_rate,boundary-output.transport.rendered_frames))
	var start := output.snapshot()
	if listening:
		model.synth.begin_duck()
		model.synth.emphasized_id = model.session.proposal(choice["proposal_id"])["district_id"]
	var frames := roundi(float(Values.load_values()["timing"]["preview_seconds"]) * output.transport.sample_rate)
	var pcm := output.render(frames)
	return {"accepted":true,"pcm":pcm,"sample_rate":output.transport.sample_rate,
		"commit_boundary":boundary,"start_snapshot":start,"choice":choice.duplicate(true),
		"result":model.session.last_result.duplicate(true),"model_after":model.snapshot(),
		"renderer_after":output.snapshot(),"emphasis":listening}
