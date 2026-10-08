class_name DistrictSynth
extends RefCounted
## Software buses expose separate district layers before their additive Master sum.

const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")

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

func _init(city: Array) -> void:
	values = Values.load_values()
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
			"table": tables[district["type"]],
			"stereo": Vector2(cos((pan + 1.0) * PI / 4.0), sin((pan + 1.0) * PI / 4.0))})

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

func _voice_layers(route: Dictionary, state: Dictionary, at: int, rate: int) -> Vector2:
	var phase_key: String = route["phase_key"]
	var phase := float(state.get(phase_key, 0.0))
	var midi := int(state.get(route["id"], route["base_midi"]))
	var drone := _table_wave(route["table"], phase) * drone_gain
	var rhythm := _rhythm(route, phase, at, rate, state) if active_layers.has("rhythm") else 0.0
	state[phase_key] = fposmod(phase + frequency(midi) / rate, 1.0)
	if not active_layers.has("drone"):
		drone = 0.0
	if muted.get(route["id"], false) or (not solo_id.is_empty() and solo_id != route["id"]) or at < int(silent_until.get(route["id"], 0)):
		return Vector2.ZERO
	return Vector2(drone, rhythm) * gain

func render_tracks(state: Dictionary, at: int, rate: int) -> Dictionary:
	var tracks: Dictionary = {}
	for route in routing:
		var layers := _voice_layers(route, state, at, rate)
		var id: String = route["id"]
		tracks["District_%s_Drone" % id] = layers.x * route["stereo"]
		tracks["District_%s_Rhythm" % id] = layers.y * route["stereo"]
		tracks["District_%s_Ornament" % id] = Vector2.ZERO
	return tracks

func _mix_frame(state: Dictionary, at: int, rate: int) -> Vector2:
	# Playback bypasses per-sample bus dictionary construction.
	var sample := Vector2.ZERO
	for route in routing:
		var layers := _voice_layers(route, state, at, rate)
		sample += layers.x * route["stereo"]
		sample += layers.y * route["stereo"]
	return sample

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
