extends RefCounted
## Software buses expose separate district layers before their additive Master sum.

const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

const Roads = preload("res://scripts/city/city_roads.gd")
var road_marks: Dictionary = {}
var values: Dictionary
var districts: Array
var active_layers: Array[String] = ["drone", "rhythm", "ornament"]
var tables: Dictionary = {}
var routing: Array[Dictionary] = []
var gain := 1.0
var solo_id := ""
var muted: Dictionary = {}
var silent_until: Dictionary = {}
var frequencies: Dictionary = {}
var envelopes: Dictionary = {}
var drone_gain: float
var rhythm_gain: float
var rhythm_multiplier: float
var highpass_alpha: Dictionary = {}
var ducking := false
var duck_release_at := -1
var emphasized_id := ""
var duck_level: float
var emphasis_level: float
var assist_enabled := true
var device_mode := "standard"
var assist_neighbors: Dictionary = {}
var guard_enabled := false
var gray_enabled := false
var gray_from := 0.0
var gray_change_at := -1
var gray_alpha: Dictionary = {}
var gray_hold_frames: Dictionary = {}
var _last_raw_layers := Vector2.ZERO

func _init(city: Array, marks: Dictionary = {}) -> void:
	road_marks = marks.duplicate(true)
	values = Values.load_values()
	assist_enabled = bool(values["assist"]["default_enabled"])
	device_mode = str(values["assist"]["default_mode"])
	_rebuild_assist_neighbors(city)
	duck_level = pow(10.0,float(values["mixing"]["duck_db"])/20.0)
	emphasis_level = pow(10.0,float(values["mixing"]["emphasis_db"])/20.0)
	drone_gain = float(values["synthesis"]["drone_gain"])
	rhythm_gain = float(values["synthesis"]["rhythm_gain"])
	rhythm_multiplier = pow(2.0, float(values["synthesis"]["rhythm_octave"]) / 12.0)
	_prepare_envelopes(int(values["timing"]["sample_rate"]))
	districts = city.duplicate(true)
	for midi in values["frequencies"]:
		frequencies[int(midi)] = float(values["frequencies"][midi])
	var size := int(values["synthesis"]["wavetable_size"])
	for type in values["voices"]:
		var partials: Array = values["voices"][type]["partials"]
		var weight := 0.0
		for value in partials:
			weight += float(value)
		var table := PackedFloat32Array()
		table.resize(size)
		for index in range(size):
			var sample := 0.0
			for harmonic in range(partials.size()):
				sample += sin(TAU * index * (harmonic + 1) / size) * float(partials[harmonic])
			table[index] = sample / weight
		tables[type] = table
	for district in districts:
		var id := str(district["district_id"])
		var pan := 0.0
		for region in values["synthesis"]["pan_regions"]:
			if Schema.cell(district).x >= int(region[0]) and Schema.cell(district).x <= int(region[1]):
				pan = float(region[2])
		routing.append({"id": id, "type": district["type"], "base_midi": district["current_midi"],
			"rhythm_steps": PackedInt32Array(values["voices"][district["type"]]["rhythm_steps"]),
			"phase_key": "_phase_" + id, "highpass_key": "_highpass_" + id,
			"table": tables[district["type"]],"level":float(district.get("voice_level",1.0)),"anchor":bool(district.get("is_anchor",false)),
			"stereo": Vector2(cos((pan + 1.0) * PI / 4.0), sin((pan + 1.0) * PI / 4.0))})

func _append_district(district: Dictionary) -> void:
	var id: String = district["district_id"]
	var pan := 0.0
	for region in values["synthesis"]["pan_regions"]:
		if Schema.cell(district).x >= int(region[0]) and Schema.cell(district).x <= int(region[1]):
			pan = float(region[2])
	routing.append({"id":id,"type":district["type"],"base_midi":district["current_midi"],
		"rhythm_steps":PackedInt32Array(values["voices"][district["type"]]["rhythm_steps"]),
		"phase_key":"_phase_"+id,"highpass_key":"_highpass_"+id,
		"table":tables[district["type"]],"level":float(district.get("voice_level",1.0)),"anchor":bool(district.get("is_anchor",false)),
		"stereo":Vector2(cos((pan+1.0)*PI/4.0),sin((pan+1.0)*PI/4.0))})

func frequency(midi: int) -> float:
	if frequencies.has(midi):
		return float(frequencies[midi])
	frequencies[midi] = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
	return float(frequencies[midi])

func initial_state() -> Dictionary:
	var state: Dictionary = {}
	for district in districts:
		state[str(district["district_id"])] = int(district["current_midi"])
	return state

func _wave(type: String, phase: float) -> float:
	return _table_wave(tables[type], phase)

func _table_wave(table: PackedFloat32Array, phase: float) -> float:
	var position := fposmod(phase, 1.0) * table.size()
	var index := int(position)
	return lerpf(table[index], table[(index + 1) % table.size()], position - index)

func _prepare_envelopes(rate: int) -> void:
	if envelopes.has(rate):
		return
	var settings: Dictionary = values["synthesis"]
	var step_frames := 60.0 * rate / float(values["timing"]["bpm"]) / 4.0
	var bar_frames := roundi(step_frames * 16)
	var tail := float(settings["rhythm_tail_seconds"])
	var attack := float(settings["rhythm_attack_seconds"])
	var decay := float(settings["rhythm_decay_seconds"])
	var by_type: Dictionary = {}
	for type in values["voices"]:
		var steps := PackedInt32Array(values["voices"][type]["rhythm_steps"])
		var envelope := PackedFloat32Array()
		envelope.resize(bar_frames)
		for at in range(bar_frames):
			var current_step := int(floor(at / step_frames))
			var sum := 0.0
			for back in range(int(ceil(tail * rate / step_frames)) + 1):
				var step := current_step - back
				if not steps.has(posmod(step, 16)):
					continue
				var seconds := float(at - roundi(step * step_frames)) / rate
				if seconds < 0.0 or seconds > tail:
					continue
				sum += minf(1.0, seconds / attack) * exp(-seconds / decay) * clampf((tail - seconds) / attack, 0.0, 1.0)
			envelope[at] = sum
		by_type[type] = envelope
	envelopes[rate] = by_type
	gray_alpha[rate] = 1.0-exp(-TAU*float(values["gray_audio"]["lowpass_hz"])/rate)
	gray_hold_frames[rate] = maxi(1,roundi(rate/float(values["gray_audio"]["hold_rate"])))
	var rc := 1.0 / (TAU * float(settings["industrial_highpass_hz"]))
	highpass_alpha[rate] = rc / (rc + 1.0 / rate)

func _rhythm(route: Dictionary, phase: float, at: int, rate: int, state: Dictionary) -> float:
	_prepare_envelopes(rate)
	var envelope: PackedFloat32Array = envelopes[rate][route["type"]]
	var pulse := _table_wave(route["table"], phase * rhythm_multiplier) * envelope[at % envelope.size()]
	if route["type"] == "industrial":
		var key: String = route["highpass_key"]
		var previous: Vector2 = state.get(key, Vector2.ZERO)
		var output := float(highpass_alpha[rate]) * (previous.y + pulse - previous.x)
		state[key] = Vector2(pulse, output)
		pulse = output
	return pulse * rhythm_gain

func gray_level(at: int, rate: int) -> float:
	if gray_change_at < 0:
		return 0.0
	var duration := float(values["gray_audio"]["transition_bars"])*float(values["timing"]["beats_per_bar"])*60.0*rate/float(values["timing"]["bpm"])
	return lerpf(gray_from,1.0 if gray_enabled else 0.0,clampf(float(at-gray_change_at)/duration,0.0,1.0))

func set_gray(enabled: bool, at: int) -> void:
	if gray_enabled == enabled:
		return
	gray_from = gray_level(at,int(values["timing"]["sample_rate"]))
	gray_enabled = enabled
	gray_change_at = at

func _gray_rhythm(input: float, id: String, at: int, rate: int, state: Dictionary) -> float:
	var blend := gray_level(at,rate)
	if not gray_enabled and blend == 0.0:
		return input
	var key := "_gray_"+id
	var previous: Vector3 = state.get(key,Vector3.ZERO)
	var alpha := float(gray_alpha[rate])
	previous.x += alpha*(input-previous.x)
	previous.y += alpha*(previous.x-previous.y)
	if at%int(gray_hold_frames[rate]) == 0:
		previous.z = previous.y
	state[key] = previous
	return lerpf(input,previous.z,blend*float(values["gray_audio"]["wet"]))

func _voice_layers(route: Dictionary, state: Dictionary, at: int, rate: int) -> Vector2:
	var phase_key: String = route["phase_key"]
	var phase := float(state.get(phase_key, 0.0))
	var midi := int(state.get(route["id"], route["base_midi"]))
	var drone := _table_wave(route["table"], phase) * drone_gain*float(route["level"])
	var rhythm := _rhythm(route, phase, at, rate, state) if active_layers.has("rhythm") and not route["anchor"] else 0.0
	rhythm *= float(route["level"])
	if active_layers.has("rhythm") and (gray_enabled or gray_level(at,rate) > 0.0):
		rhythm = _gray_rhythm(rhythm,route["id"],at,rate,state)
	if guard_enabled:
		_last_raw_layers = Vector2(drone if active_layers.has("drone") else 0.0,rhythm)*gain
	rhythm *= rhythm_level(at,rate)*(emphasis_level if emphasized_id == route["id"] else 1.0)
	state[phase_key] = fposmod(phase + frequency(midi) / rate, 1.0)
	if not active_layers.has("drone"):
		drone = 0.0
	if muted.get(route["id"], false) or (not solo_id.is_empty() and solo_id != route["id"]) or at < int(silent_until.get(route["id"], 0)):
		return Vector2.ZERO
	return Vector2(drone, rhythm) * gain

func render_tracks(state: Dictionary, at: int, rate: int) -> Dictionary:
	var routes := assist_routes(state)
	var helpers := _assist_tracks(state,at,routes)
	var raw_drone := Vector2.ZERO
	var raw_other := Vector2.ZERO
	var raw_helpers := _assist_sum(_assist_tracks(state,at,routes,true)) if guard_enabled else Vector2.ZERO
	var factor := float(state.get("_guard_factor",1.0)) if guard_enabled else 1.0
	var tracks: Dictionary = {}
	for route in routing:
		var layers := _voice_layers(route,state,at,rate)
		var id: String = route["id"]
		tracks["District_%s_Drone" % id] = layers.x*route["stereo"]*factor
		tracks["District_%s_Rhythm" % id] = layers.y*route["stereo"]
		tracks["District_%s_Ornament" % id] = Vector2.ZERO
		if guard_enabled:
			raw_drone += _last_raw_layers.x*route["stereo"]
			raw_other += _last_raw_layers.y*route["stereo"]
	tracks.merge(helpers)
	if guard_enabled:
		raw_other += raw_helpers
		_guard_step(state,raw_drone,raw_other,rate)
	return tracks

func _mix_frame(state: Dictionary, at: int, rate: int) -> Vector2:
	var routes := assist_routes(state)
	var helpers := _assist_sum(_assist_tracks(state,at,routes)) if not routes.is_empty() else Vector2.ZERO
	var raw_drone := Vector2.ZERO
	var raw_other := Vector2.ZERO
	var raw_helpers := _assist_sum(_assist_tracks(state,at,routes,true)) if guard_enabled else Vector2.ZERO
	var controlled_drone := Vector2.ZERO
	var sample := Vector2.ZERO
	for route in routing:
		var layers := _voice_layers(route,state,at,rate)
		sample += layers.x*route["stereo"]
		sample += layers.y*route["stereo"]
		if guard_enabled:
			raw_drone += _last_raw_layers.x*route["stereo"]
			raw_other += _last_raw_layers.y*route["stereo"]
			controlled_drone += layers.x*route["stereo"]
	if not routes.is_empty():
		sample += helpers
	if guard_enabled:
		raw_other += raw_helpers
		var factor := float(state.get("_guard_factor",1.0))
		if factor != 1.0:
			sample += controlled_drone*(factor-1.0)
		_guard_step(state,raw_drone,raw_other,rate)
	return sample

func _guard_step(state: Dictionary, drone: Vector2, other: Vector2, rate: int) -> void:
	var count := int(state.get("_guard_count",0))+1
	var d := float(state.get("_guard_D",0.0))+drone.length_squared()
	var n := float(state.get("_guard_N",0.0))+other.length_squared()
	var c := float(state.get("_guard_C",0.0))+drone.dot(other)
	var window := roundi(float(values["rms_guard"]["window_seconds"])*rate)
	if count < window:
		state["_guard_count"] = count
		state["_guard_D"] = d
		state["_guard_N"] = n
		state["_guard_C"] = c
		return
	var ratio := float(values["rms_guard"]["target_ratio"])
	var r2 := ratio*ratio
	var required := 1.0
	if d > 0.0:
		required = maxf(1.0,(r2*c+sqrt(maxf(0.0,r2*r2*c*c+r2*(1.0-r2)*d*n)))/((1.0-r2)*d))
	state["_guard_factor"] = maxf(float(state.get("_guard_factor",1.0)),required)
	state["_guard_count"] = 0
	state["_guard_D"] = 0.0
	state["_guard_N"] = 0.0
	state["_guard_C"] = 0.0
	state["_guard_last_uncompensated_ratio"] = sqrt(d/(d+2.0*c+n)) if d+2.0*c+n > 0.0 else 0.0
	state["_guard_unavailable"] = d == 0.0


func _rebuild_assist_neighbors(city: Array) -> void:
	assist_neighbors.clear()
	for district in city:
		var id: String = district["district_id"]
		var neighbors: Array[String] = []
		for other in city:
			if (Schema.cell(district)-Schema.cell(other)).length_squared() == 1 and not Roads.blocked(road_marks,Schema.cell(district),Schema.cell(other)):
				neighbors.append(str(other["district_id"]))
		neighbors.sort()
		assist_neighbors[id] = neighbors

func assist_routes(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not assist_enabled or device_mode != "narrowband" or not active_layers.has("drone"):
		return result
	var settings: Dictionary = values["assist"]
	for route in routing:
		var id: String = route["id"]
		var midi := int(state.get(id,route["base_midi"]))
		for neighbor in assist_neighbors[id]:
			var other := int(state[neighbor])
			var distance := absi(midi-other)%12
			var difference := absf(frequency(midi)-frequency(other))
			if (distance == 1 or distance == 11) and difference >= float(settings["minimum_difference_hz"]) and difference <= float(settings["maximum_difference_hz"]):
				result.append({"route":route,"neighbor":neighbor})
				break
	return result

func assist_envelope(phase_difference: float) -> float:
	var depth := float(values["assist"]["depth"])
	return (1.0+depth*cos(TAU*phase_difference))/(1.0+depth)

func _assist_tracks(state: Dictionary, at: int, routes: Array[Dictionary], ignore_faders: bool = false) -> Dictionary:
	var tracks: Dictionary = {}
	var multiplier := float(values["assist"]["octave_multiplier"])
	var level := pow(10.0,float(values["assist"]["level_db"])/20.0)
	for item in routes:
		var route: Dictionary = item["route"]
		var id: String = route["id"]
		var phase := float(state.get(route["phase_key"],0.0))
		var other_phase := float(state.get("_phase_"+str(item["neighbor"]),0.0))
		var sample := _table_wave(route["table"],phase*multiplier)*drone_gain*float(route["level"])*level*assist_envelope(phase-other_phase)*gain
		if not ignore_faders and (muted.get(id,false) or (not solo_id.is_empty() and solo_id != id) or at < int(silent_until.get(id,0))):
			sample = 0.0
		tracks["District_"+id+"_Assist"] = sample*route["stereo"]
	return tracks

func _assist_sum(tracks: Dictionary) -> Vector2:
	var result := Vector2.ZERO
	for sample in tracks.values():
		result += sample
	return result

func _assist_block(state: Dictionary, start: int, count: int, rate: int, routes: Array[Dictionary], ignore_faders: bool = false) -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(count)
	var multiplier := float(values["assist"]["octave_multiplier"])
	var level := pow(10.0,float(values["assist"]["level_db"])/20.0)
	var depth := float(values["assist"]["depth"])
	for item in routes:
		var route: Dictionary = item["route"]
		var id: String = route["id"]
		var neighbor: String = item["neighbor"]
		var phase := float(state.get(route["phase_key"],0.0))
		var other := float(state.get("_phase_"+neighbor,0.0))
		var increment := frequency(int(state.get(id,route["base_midi"])))/rate
		var other_increment := frequency(int(state[neighbor]))/rate
		var table: PackedFloat32Array = route["table"]
		var size := table.size()
		var stereo: Vector2 = route["stereo"]
		var disabled := not ignore_faders and (bool(muted.get(id,false)) or (not solo_id.is_empty() and solo_id != id))
		var silence_end := 0 if ignore_faders else int(silent_until.get(id,0))
		for offset in range(count):
			var position := fposmod(phase*multiplier,1.0)*size
			var index := int(position)
			var wave := lerpf(table[index],table[(index+1)%size],position-index)
			var envelope := (1.0+depth*cos(TAU*(phase-other)))/(1.0+depth)
			var sample := wave*drone_gain*float(route["level"])*level*envelope*gain
			if disabled or start+offset < silence_end:
				sample = 0.0
			result[offset] += sample*stereo
			phase = fposmod(phase+increment,1.0)
			other = fposmod(other+other_increment,1.0)
	return result

func begin_duck() -> void:
	ducking = true
	duck_release_at = -1

func release_duck(at: int) -> void:
	if ducking:
		ducking = false
		duck_release_at = at

func rhythm_level(at: int, rate: int) -> float:
	if ducking:
		return duck_level
	if duck_release_at < 0:
		return 1.0
	var duration := float(values["mixing"]["duck_release_seconds"])*rate
	return lerpf(duck_level,1.0,clampf(float(at-duck_release_at)/duration,0.0,1.0))

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	_prepare_envelopes(rate)
	var helpers := PackedVector2Array()
	var raw_helpers := PackedVector2Array()
	var routes := assist_routes(state)
	if not routes.is_empty():
		helpers = _assist_block(state,start,count,rate,routes)
		if guard_enabled:
			raw_helpers = _assist_block(state,start,count,rate,routes,true)
	var block := PackedVector2Array()
	block.resize(count)
	var raw_drone := PackedVector2Array()
	var raw_other := PackedVector2Array()
	var controlled_drone := PackedVector2Array()
	if guard_enabled:
		raw_drone.resize(count)
		raw_other.resize(count)
		controlled_drone.resize(count)
	var drone_enabled := active_layers.has("drone")
	var rhythm_enabled := active_layers.has("rhythm")
	var gray_active := rhythm_enabled and (gray_enabled or gray_level(start,rate) > 0.0)
	var gray_levels := PackedFloat64Array()
	var lowpass_alpha := float(gray_alpha[rate])
	var hold_frames := int(gray_hold_frames[rate])
	if gray_active:
		gray_levels.resize(count)
		for offset in range(count):
			gray_levels[offset] = gray_level(start+offset,rate)*float(values["gray_audio"]["wet"])
	var levels := PackedFloat64Array()
	levels.resize(count)
	for offset in range(count):
		levels[offset] = rhythm_level(start+offset,rate)
	for route in routing:
		var id: String = route["id"]
		var phase_key: String = route["phase_key"]
		var phase := float(state.get(phase_key,0.0))
		var increment := frequency(int(state.get(id,route["base_midi"]))) / rate
		var table: PackedFloat32Array = route["table"]
		var size := table.size()
		var stereo: Vector2 = route["stereo"]
		var envelope: PackedFloat32Array = envelopes[rate][route["type"]]
		var envelope_count := envelope.size()
		var industrial: bool = route["type"] == "industrial"
		var previous: Vector2 = state.get(route["highpass_key"],Vector2.ZERO)
		var alpha := float(highpass_alpha[rate])
		var gray_key := "_gray_"+id
		var gray_previous: Vector3 = state.get(gray_key,Vector3.ZERO)
		var disabled := bool(muted.get(id,false)) or (not solo_id.is_empty() and solo_id != id)
		var silence_end := int(silent_until.get(id,0))
		var emphasis := emphasis_level if emphasized_id == id else 1.0
		var voice_level := float(route["level"])
		var is_anchor := bool(route["anchor"])
		for offset in range(count):
			var at := start+offset
			var position := fposmod(phase,1.0)*size
			var index := int(position)
			var drone := lerpf(table[index],table[(index+1)%size],position-index)*drone_gain*voice_level if drone_enabled else 0.0
			var rhythm := 0.0
			if rhythm_enabled and not is_anchor:
				position = fposmod(phase*rhythm_multiplier,1.0)*size
				index = int(position)
				var pulse := lerpf(table[index],table[(index+1)%size],position-index)*envelope[at%envelope_count]
				if industrial:
					var output := alpha*(previous.y+pulse-previous.x)
					previous = Vector2(pulse,output)
					pulse = output
				rhythm = pulse*rhythm_gain*voice_level
				if gray_active and (gray_enabled or gray_levels[offset] > 0.0):
					gray_previous.x += lowpass_alpha*(rhythm-gray_previous.x)
					gray_previous.y += lowpass_alpha*(gray_previous.x-gray_previous.y)
					if at%hold_frames == 0:
						gray_previous.z = gray_previous.y
					rhythm = lerpf(rhythm,gray_previous.z,gray_levels[offset])
			if guard_enabled:
				var dry_layers := Vector2(drone,rhythm)*gain
				raw_drone[offset] += dry_layers.x*stereo
				raw_other[offset] += dry_layers.y*stereo
			rhythm *= levels[offset]*emphasis
			phase = fposmod(phase+increment,1.0)
			if not disabled and at >= silence_end:
				var layers := Vector2(drone,rhythm)*gain
				block[offset] += layers.x*stereo
				block[offset] += layers.y*stereo
				if guard_enabled:
					controlled_drone[offset] += layers.x*stereo
		state[phase_key] = phase
		if gray_active:
			state[gray_key] = gray_previous
		if industrial and rhythm_enabled:
			state[route["highpass_key"]] = previous
	if not helpers.is_empty():
		for offset in range(count):
			block[offset] += helpers[offset]
	if guard_enabled:
		if not raw_helpers.is_empty():
			for offset in range(count):
				raw_other[offset] += raw_helpers[offset]
		for offset in range(count):
			var factor := float(state.get("_guard_factor",1.0))
			if factor != 1.0:
				block[offset] += controlled_drone[offset]*(factor-1.0)
			_guard_step(state,raw_drone[offset],raw_other[offset],rate)
	return block

func update_city(city: Array, state: Dictionary, marks: Dictionary = {}) -> void:
	road_marks = marks.duplicate(true)
	districts = city.duplicate(true)
	_rebuild_assist_neighbors(city)
	for district in city:
		var id: String = district["district_id"]
		state[id] = int(district["current_midi"])
		if not routing.any(func(route: Dictionary) -> bool: return route["id"] == id):
			_append_district(district)
		for route in routing:
			if route["id"] != id:
				continue
			var pan := 0.0
			for region in values["synthesis"]["pan_regions"]:
				if Schema.cell(district).x >= int(region[0]) and Schema.cell(district).x <= int(region[1]):
					pan = float(region[2])
			route["stereo"] = Vector2(cos((pan+1.0)*PI/4.0),sin((pan+1.0)*PI/4.0))

func set_solo(id: String) -> bool:
	if not id.is_empty() and not routing.any(func(route: Dictionary) -> bool: return route["id"] == id):
		return false
	solo_id = id
	return true

func set_mute(id: String, enabled: bool) -> bool:
	if not routing.any(func(route: Dictionary) -> bool: return route["id"] == id):
		return false
	muted[id] = enabled
	return true
