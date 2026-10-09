class_name CityAudioModel
extends RefCounted

const Session = preload("res://scripts/proposals/city_interventions.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")

var session: CityInterventions
var synth: DistrictSynth
var next_boundary: int
# Pre-render commits wait here until playback reaches their frame.
var presentation_history: Array[Dictionary] = []
var growth_history: Array[Dictionary] = []
var ring_history: Array[Dictionary] = []
var presentation_copy: CityInterventions
var presentation_copy_frame := -1

func _init(city_session: CityInterventions) -> void:
	session = city_session
	synth = Synth.new(session.city,session.road_marks)
	synth.set_gray(bool(session.lifecycle["gray"]),session.transport.phrase_frame(session.phrase_index))
	next_boundary = session.next_city_boundary()

func _mix_frame(state: Dictionary, at: int, rate: int) -> Vector2:
	if at == next_boundary:
		_settle_for_render(state,at)
	return synth._mix_frame(state,at,rate)

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var at := start
	while at < start+count:
		if at == next_boundary:
			_settle_for_render(state,at)
		var amount := mini(start+count-at,next_boundary-at)
		result.append_array(synth.render_block(state,at,amount,rate))
		at += amount
	return result

func _settle_for_render(state: Dictionary, at: int) -> void:
	presentation_history.append({"frame":at,"before":session.snapshot()})
	session.settle(at)
	var events: Array = session.last_result.get("growth_events",[])
	synth.update_city(session.city,state,session.road_marks,events)
	if session.last_result.get("era_event","") == "departure": synth.begin_era_transition(session.run["transition"],session.transport)
	synth.sync_rings(session.rings,at)
	for event in session.last_result.get("ring_events",[]):
		ring_history.append({"event":event.duplicate(true),"district":session._district(str(event["district_id"])).duplicate(true),"anchor_midi":session._district(str(event["district_id"]))["current_midi"],"stage_voice":false})
	for event in events:
		if event.get("kind","") != "upgrade": continue
		var district: Dictionary = session._district(str(event["district_id"]))
		var anchor: Dictionary = session._district(str(district.get("anchor_id","")))
		growth_history.append({"event":event.duplicate(true),"district":district.duplicate(true),
			"anchor_midi":int(anchor.get("current_midi",district["current_midi"])),"stage_voice":Synth.Stage.applies(district)})
	synth.set_gray(bool(session.lifecycle["gray"]),at)
	synth.silent_until = session.silent_until.duplicate(true)
	next_boundary = session.next_city_boundary()

func presentation_session(audible_frame: float) -> CityInterventions:
	while not presentation_history.is_empty() and int(presentation_history[0]["frame"]) <= audible_frame:
		presentation_history.pop_front()
	if presentation_history.is_empty():
		presentation_copy = null
		presentation_copy_frame = -1
		return session
	var entry: Dictionary = presentation_history[0]
	if presentation_copy == null or presentation_copy_frame != int(entry["frame"]):
		presentation_copy = load("res://scripts/proposals/city_interventions.gd").new(entry["before"]["city"],session.rng.seed_hex,{},entry["before"].get("run",{}))
		presentation_copy.restore(entry["before"])
		presentation_copy_frame = int(entry["frame"])
	# A newly submitted next intervention is intentionally visible as a preview.
	var prior: Dictionary = entry["before"]["pending"]
	presentation_copy.pending = (session.pending if not session.pending.is_empty() else (prior if int(prior.get("frame",-1)) == int(entry["frame"]) else {})).duplicate(true)
	return presentation_copy

func snapshot() -> Dictionary:
	return {"session":session.snapshot(),"next_boundary":next_boundary,
		"presentation_history":presentation_history.duplicate(true),
		"growth_history":growth_history.duplicate(true),"ring_history":ring_history.duplicate(true),"ring_routes":synth.ring_snapshot(),"stage_routes":synth.stage_snapshot(),"era_routes":synth.era_snapshot(),"era_score":synth.era_score.duplicate(true),
		"active_layers":synth.active_layers.duplicate(),"gain":synth.gain,"voice_grouping":synth.voice_grouping,
		"solo_id":synth.solo_id,"muted":synth.muted.duplicate(true),
		"silent_until":synth.silent_until.duplicate(true),"ducking":synth.ducking,
		"duck_release_at":synth.duck_release_at,"emphasized_id":synth.emphasized_id,
		"assist_enabled":synth.assist_enabled,"device_mode":synth.device_mode,"guard_enabled":synth.guard_enabled,
		"gray_enabled":synth.gray_enabled,"gray_from":synth.gray_from,"gray_change_at":synth.gray_change_at}

func restore(saved: Dictionary) -> void:
	session.restore(saved["session"])
	presentation_history.assign(saved.get("presentation_history",[]).duplicate(true))
	growth_history.assign(saved.get("growth_history",[]).duplicate(true))
	ring_history.assign(saved.get("ring_history",[]).duplicate(true))
	synth = Synth.new(session.city,session.road_marks)
	synth.restore_stages(saved.get("stage_routes",{}))
	synth.restore_rings(saved.get("ring_routes",{}))
	synth.restore_eras(saved.get("era_routes",{}))
	synth.era_score = saved.get("era_score",{}).duplicate(true)
	presentation_copy = null
	presentation_copy_frame = -1
	next_boundary = int(saved["next_boundary"])
	synth.active_layers.assign(saved["active_layers"])
	synth.gain = float(saved["gain"])
	synth.voice_grouping = bool(saved.get("voice_grouping",false))
	synth.solo_id = saved["solo_id"]
	synth.muted = saved["muted"].duplicate(true)
	synth.silent_until = saved["silent_until"].duplicate(true)
	synth.ducking = bool(saved["ducking"])
	synth.duck_release_at = int(saved["duck_release_at"])
	synth.emphasized_id = saved["emphasized_id"]
	synth.guard_enabled = bool(saved["guard_enabled"])
	synth.gray_enabled = bool(saved["gray_enabled"])
	synth.gray_from = float(saved["gray_from"])
	synth.gray_change_at = int(saved["gray_change_at"])
	synth.assist_enabled = bool(saved["assist_enabled"])
	synth.device_mode = str(saved["device_mode"])
	synth.road_marks = session.road_marks.duplicate(true)
	synth._rebuild_assist_neighbors(session.city)

func fork() -> CityAudioModel:
	var copy := CityAudioModel.new(session.fork())
	copy.restore(snapshot())
	return copy
