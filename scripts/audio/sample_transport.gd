class_name SampleTransport
extends RefCounted
## rendered_frames always points at the first unwritten PCM sample.

const Values = preload("res://scripts/spec_values.gd")

var sample_rate: int
var timing: Dictionary
var rendered_frames := 0
var audible_frame := 0.0
var pending: Array[Dictionary] = []
var accepted_events: Array[Dictionary] = []
var approved_proposals: Dictionary = {}

func _init(rate: int = 0) -> void:
	timing = Values.load_values()["timing"]
	sample_rate = int(timing["sample_rate"]) if rate == 0 else rate
	assert(sample_rate > 0)

func beat_frame(index: int) -> int:
	return roundi(float(index) * 60.0 * sample_rate / float(timing["bpm"]))

func bar_frame(index: int) -> int:
	return beat_frame(index * int(timing["beats_per_bar"]))

func phrase_frame(index: int) -> int:
	return bar_frame(index * int(timing["bars_per_phrase"]))

func next_phrase_frame() -> int:
	var phrase_duration := 60.0 * sample_rate * int(timing["beats_per_bar"]) * int(timing["bars_per_phrase"]) / float(timing["bpm"])
	var index := int(floor(float(rendered_frames) / phrase_duration))
	while phrase_frame(index) < rendered_frames:
		index += 1
	return phrase_frame(index)

func update_audible(queued_frames: int, since_mix: float, output_latency: float) -> float:
	var estimate := float(rendered_frames - queued_frames) + (since_mix - output_latency) * sample_rate
	audible_frame = maxf(audible_frame, clampf(estimate, 0.0, float(rendered_frames)))
	return audible_frame

func approve_proposal(id: String, district_id: String, type: String, pitches: Array) -> void:
	approved_proposals[id] = {"district_id": district_id, "type": type, "pitches": pitches.duplicate()}

func allows_pitch(event: Dictionary) -> bool:
	var voices: Dictionary = Values.load_values()["voices"]
	var type := str(event.get("type", ""))
	if not voices.has(type) or not event.has("midi"):
		return false
	var base := int(voices[type]["base_midi"])
	var midi := int(event["midi"])
	match str(event.get("kind", "")):
		"initial":
			return midi == base
		"rebellion_fixture":
			return midi == base + 1
		"retune":
			var proposal: Dictionary = approved_proposals.get(str(event.get("proposal_id", "")), {})
			return not proposal.is_empty() and proposal["district_id"] == event.get("district_id") and proposal["type"] == type and proposal["pitches"].has(midi)
	return false

func queue_pitch(event: Dictionary) -> Dictionary:
	if not allows_pitch(event) or str(event.get("district_id", "")).is_empty():
		return {"accepted": false, "reason": "pitch not authorized"}
	var accepted := event.duplicate(true)
	accepted["frame"] = next_phrase_frame()
	accepted["requested_at"] = audible_frame
	pending.append(accepted)
	accepted_events.append(accepted.duplicate(true))
	return {"accepted": true, "frame": accepted["frame"], "requested_at": audible_frame}

func take_events(at: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	while not pending.is_empty() and int(pending[0]["frame"]) == at:
		result.append(pending.pop_front())
	return result

func snapshot() -> Dictionary:
	return {"rendered_frames": rendered_frames, "audible_frame": audible_frame,
		"pending": pending.duplicate(true), "accepted_events": accepted_events.duplicate(true),
		"approved_proposals": approved_proposals.duplicate(true)}

func restore(saved: Dictionary) -> void:
	rendered_frames = int(saved["rendered_frames"])
	audible_frame = float(saved["audible_frame"])
	pending.assign(saved["pending"].duplicate(true))
	accepted_events.assign(saved["accepted_events"].duplicate(true))
	approved_proposals = saved["approved_proposals"].duplicate(true)
