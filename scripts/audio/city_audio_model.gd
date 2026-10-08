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

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var at := start
	while at < start+count:
		if at == next_boundary:
			session.settle(at)
			synth.update_city(session.city,state)
			synth.silent_until = session.silent_until.duplicate(true)
			next_boundary = session.transport.phrase_frame(session.phrase_index+1)
		var amount := mini(start+count-at,next_boundary-at)
		result.append_array(synth.render_block(state,at,amount,rate))
		at += amount
	return result

func snapshot() -> Dictionary:
	return {"session":session.snapshot(),"next_boundary":next_boundary,
		"active_layers":synth.active_layers.duplicate(),"gain":synth.gain,
		"solo_id":synth.solo_id,"muted":synth.muted.duplicate(true),
		"silent_until":synth.silent_until.duplicate(true),"ducking":synth.ducking,
		"duck_release_at":synth.duck_release_at,"emphasized_id":synth.emphasized_id}

func restore(saved: Dictionary) -> void:
	session.restore(saved["session"])
	next_boundary = int(saved["next_boundary"])
	synth.active_layers.assign(saved["active_layers"])
	synth.gain = float(saved["gain"])
	synth.solo_id = saved["solo_id"]
	synth.muted = saved["muted"].duplicate(true)
	synth.silent_until = saved["silent_until"].duplicate(true)
	synth.ducking = bool(saved["ducking"])
	synth.duck_release_at = int(saved["duck_release_at"])
	synth.emphasized_id = saved["emphasized_id"]

func fork() -> CityAudioModel:
	var copy := CityAudioModel.new(session.fork())
	copy.restore(snapshot())
	return copy
