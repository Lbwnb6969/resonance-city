class_name CityAudioModel
extends RefCounted

const Session = preload("res://scripts/proposals/city_interventions.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")

var session: CityInterventions
var synth: DistrictSynth
var next_boundary: int

func _init(city_session: CityInterventions) -> void:
	session = city_session
	synth = Synth.new(session.city)
	next_boundary = session.transport.phrase_frame(session.phrase_index+1)

func _mix_frame(state: Dictionary, at: int, rate: int) -> Vector2:
	if at == next_boundary:
		session.settle(at)
		synth.update_city(session.city,state)
		synth.silent_until = session.silent_until.duplicate(true)
		next_boundary = session.transport.phrase_frame(session.phrase_index+1)
	return synth._mix_frame(state,at,rate)

func snapshot() -> Dictionary:
	return {"session":session.snapshot(),"next_boundary":next_boundary,
		"active_layers":synth.active_layers.duplicate(),"gain":synth.gain,
		"solo_id":synth.solo_id,"muted":synth.muted.duplicate(true),
		"silent_until":synth.silent_until.duplicate(true)}

func restore(saved: Dictionary) -> void:
	session.restore(saved["session"])
	next_boundary = int(saved["next_boundary"])
	synth.active_layers.assign(saved["active_layers"])
	synth.gain = float(saved["gain"])
	synth.solo_id = saved["solo_id"]
	synth.muted = saved["muted"].duplicate(true)
	synth.silent_until = saved["silent_until"].duplicate(true)

func fork() -> CityAudioModel:
	var copy := CityAudioModel.new(session.fork())
	copy.restore(snapshot())
	return copy
