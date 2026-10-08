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

func _init(city: Array) -> void:
	values = Values.load_values()
	districts = city.duplicate(true)
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
			"stereo": Vector2(cos((pan + 1.0) * PI / 4.0), sin((pan + 1.0) * PI / 4.0))})

func frequency(midi: int) -> float:
	if values["frequencies"].has(str(midi)):
		return float(values["frequencies"][str(midi)])
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

func initial_state() -> Dictionary:
	var state: Dictionary = {}
	for district in districts:
		state[str(district["district_id"])] = int(district["current_midi"])
	return state

func _wave(type: String, phase: float) -> float:
	var table: PackedFloat32Array = tables[type]
	var position := fposmod(phase, 1.0) * table.size()
	var index := int(position)
	return lerpf(table[index], table[(index + 1) % table.size()], position - index)

func _rhythm(route: Dictionary, phase: float, at: int, rate: int, state: Dictionary) -> float:
	var settings: Dictionary = values["synthesis"]
	var step_frames := 60.0 * rate / float(values["timing"]["bpm"]) / 4.0
	var current_step := int(floor(at / step_frames))
	var tail := float(settings["rhythm_tail_seconds"])
	var pulse := 0.0
	for back in range(int(ceil(tail * rate / step_frames)) + 1):
		var step := current_step - back
		if step < 0 or not route["rhythm_steps"].has(step % 16):
			continue
		var seconds := float(at - roundi(step * step_frames)) / rate
		if seconds < 0.0 or seconds > tail:
			continue
		var attack := float(settings["rhythm_attack_seconds"])
		var envelope := minf(1.0, seconds / attack) * exp(-seconds / float(settings["rhythm_decay_seconds"]))
		envelope *= clampf((tail - seconds) / attack, 0.0, 1.0)
		pulse += _wave(route["type"], phase * pow(2.0, float(settings["rhythm_octave"]) / 12.0)) * envelope
	if route["type"] == "industrial":
		var key := "_highpass_" + str(route["id"])
		var previous: Vector2 = state.get(key, Vector2.ZERO)
		var rc := 1.0 / (TAU * float(settings["industrial_highpass_hz"]))
		var alpha := rc / (rc + 1.0 / rate)
		var output := alpha * (previous.y + pulse - previous.x)
		state[key] = Vector2(pulse, output)
		pulse = output
	return pulse * float(settings["rhythm_gain"])

func render_tracks(state: Dictionary, at: int, rate: int) -> Dictionary:
	var tracks: Dictionary = {}
	for route in routing:
		var id: String = route["id"]
		var type: String = route["type"]
		var phase_key := "_phase_" + id
		var phase := float(state.get(phase_key, 0.0))
		var midi := int(state.get(id, route["base_midi"]))
		var drone := _wave(type, phase) * float(values["synthesis"]["drone_gain"])
		var rhythm := _rhythm(route, phase, at, rate, state) if active_layers.has("rhythm") else 0.0
		tracks["District_%s_Drone" % id] = drone * route["stereo"] * gain if active_layers.has("drone") else Vector2.ZERO
		tracks["District_%s_Rhythm" % id] = rhythm * route["stereo"] * gain
		tracks["District_%s_Ornament" % id] = Vector2.ZERO
		state[phase_key] = fposmod(phase + frequency(midi) / rate, 1.0)
	return tracks

func _mix_frame(state: Dictionary, at: int, rate: int) -> Vector2:
	var sample := Vector2.ZERO
	for track in render_tracks(state, at, rate).values():
		sample += track
	return sample
