class_name VoiceGroupBudget
extends RefCounted
## Isolated TEC-01 candidate. Production DistrictSynth remains unmerged until measurements decide.

const Synth = preload("res://scripts/audio/district_synth.gd")

var synth: DistrictSynth
var groups: Array = []
var fallback_count := 0
var fallback_reason := ""

func _init(city: Array) -> void:
	synth = Synth.new(city)
	rebuild_groups()

func rebuild_groups() -> void:
	var by_key: Dictionary = {}
	for route_value in synth.routing:
		var route: Dictionary = route_value
		var key := "%s|%d|%s" % [str(route["type"]),int(route["base_midi"]),str(bool(route["anchor"]))]
		if not by_key.has(key):
			by_key[key] = {"key":key,"routes":[]}
		by_key[key]["routes"].append(route)
	groups = by_key.values()

func group_count() -> int:
	return groups.size()

func _eligible(group: Dictionary, state: Dictionary, start: int, rate: int) -> bool:
	var first: Dictionary = group["routes"][0]
	var first_id := str(first["id"])
	var phase := float(state.get(first["phase_key"],0.0))
	var midi := int(state.get(first_id,first["base_midi"]))
	var highpass: Vector2 = state.get(first["highpass_key"],Vector2.ZERO)
	for route_value in group["routes"]:
		var route: Dictionary = route_value
		var id := str(route["id"])
		# Stage changes, ring crossfades, custom rhythm fixtures and fade states
		# are intentionally barriers: their per-entity timing must remain visible.
		if not route["stage"].is_empty() or not route["ring"].is_empty():
			fallback_reason = "stage_or_ring:%s" % id
			return false
		if state.has("_rhythm_fixture_"+id) or synth.gray_enabled or synth.gray_level(start,rate) > 0.0:
			fallback_reason = "fixture_or_gray:%s" % id
			return false
		if synth.emphasized_id == id or synth.silent_until.has(id):
			fallback_reason = "individual_transition:%s" % id
			return false
		if int(state.get(id,route["base_midi"])) != midi:
			fallback_reason = "different_pitch:%s" % id
			return false
		if float(state.get(route["phase_key"],0.0)) != phase:
			fallback_reason = "different_phase:%s" % id
			return false
		if route["type"] == "industrial" and state.get(route["highpass_key"],Vector2.ZERO) != highpass:
			fallback_reason = "different_filter_state:%s" % id
			return false
	return true

func _enabled(id: String) -> bool:
	if bool(synth.muted.get(id,false)):
		return false
	return synth.solo_id.is_empty() or synth.solo_id == id

func _aggregate(group: Dictionary) -> Dictionary:
	var drone_stereo := Vector2.ZERO
	var rhythm_stereo := Vector2.ZERO
	for route_value in group["routes"]:
		var route: Dictionary = route_value
		if not _enabled(str(route["id"])):
			continue
		var weighted: Vector2 = route["stereo"] * float(route["level"])
		drone_stereo += weighted
		if not bool(route["anchor"]):
			rhythm_stereo += weighted
	return {"drone":drone_stereo,"rhythm":rhythm_stereo}

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	fallback_reason = ""
	if not synth.assist_routes(state).is_empty() or synth.guard_enabled or synth.gray_enabled:
		fallback_count += 1
		fallback_reason = "assist_guard_or_gray"
		return synth.render_block(state,start,count,rate)
	for group_value in groups:
		var group: Dictionary = group_value
		if not _eligible(group,state,start,rate):
			fallback_count += 1
			return synth.render_block(state,start,count,rate)
	synth._prepare_envelopes(rate)
	var block := PackedVector2Array()
	block.resize(count)
	var drone_enabled := synth.active_layers.has("drone")
	var rhythm_enabled := synth.active_layers.has("rhythm")
	var levels := PackedFloat64Array()
	levels.resize(count)
	for offset in range(count):
		levels[offset] = synth.rhythm_level(start+offset,rate)
	for group_value in groups:
		var group: Dictionary = group_value
		var first: Dictionary = group["routes"][0]
		var phase := float(state.get(first["phase_key"],0.0))
		var midi := int(state.get(str(first["id"]),first["base_midi"]))
		var increment := synth.frequency(midi)/rate
		var table: PackedFloat32Array = first["table"]
		var size := table.size()
		var aggregate := _aggregate(group)
		var drone_stereo: Vector2 = aggregate["drone"]
		var rhythm_stereo: Vector2 = aggregate["rhythm"]
		var envelope: PackedFloat32Array = synth.envelopes[rate][first["type"]]
		var previous: Vector2 = state.get(first["highpass_key"],Vector2.ZERO)
		var industrial := str(first["type"]) == "industrial"
		for offset in range(count):
			var at := start+offset
			var position := fposmod(phase,1.0)*size
			var index := int(position)
			var wave := lerpf(table[index],table[(index+1)%size],position-index)
			var sample := Vector2.ZERO
			if drone_enabled:
				sample += wave*synth.drone_gain*drone_stereo
			if rhythm_enabled and not bool(first["anchor"]):
				position = fposmod(phase*synth.rhythm_multiplier,1.0)*size
				index = int(position)
				var pulse := lerpf(table[index],table[(index+1)%size],position-index)*envelope[at%envelope.size()]
				if industrial:
					var output := float(synth.highpass_alpha[rate])*(previous.y+pulse-previous.x)
					previous = Vector2(pulse,output)
					pulse = output
				sample += pulse*synth.rhythm_gain*rhythm_stereo*levels[offset]
			block[offset] += sample*synth.gain
			phase = fposmod(phase+increment,1.0)
		for route_value in group["routes"]:
			var route: Dictionary = route_value
			state[route["phase_key"]] = phase
			if industrial:
				state[route["highpass_key"]] = previous
	return block

func _mix_frame(state: Dictionary, at: int, rate: int) -> Vector2:
	return synth._mix_frame(state,at,rate)

func set_mute(id: String, enabled: bool) -> bool:
	return synth.set_mute(id,enabled)

func set_solo(id: String) -> bool:
	return synth.set_solo(id)
