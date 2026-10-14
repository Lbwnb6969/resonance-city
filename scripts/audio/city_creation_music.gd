class_name CityCreationMusic
extends Node
## Original D-major pentatonic morning miniature. PCM is rendered once on a
## worker, then four synchronized loops respond to the town through gain only.
const RATE := 22050
const SECONDS := 24.0
const FRAMES := 529200
const STEMS := ["foundation", "wood", "air", "terrace"]

var muted := false
var audio_report: Dictionary = {}
var _players: Dictionary = {}
var _targets := {"foundation": -10.0, "wood": -12.0, "air": -17.0, "terrace": -22.0}
var _effects: Array[AudioStreamPlayer] = []
var _edit_streams: Dictionary = {}
var _worker: Thread
var _loading := false


func setup(state: RefCounted) -> void:
	update_city(state)
	if _worker != null:
		return
	for key in STEMS:
		var player := AudioStreamPlayer.new()
		player.name = "Morning_" + key
		player.volume_db = -60.0
		add_child(player)
		_players[key] = player
	for i in range(4):
		var effect := AudioStreamPlayer.new()
		effect.volume_db = -10.0
		add_child(effect)
		_effects.append(effect)
	_worker = Thread.new()
	_loading = true
	_worker.start(_render_bank)


func update_city(state: RefCounted) -> void:
	var rooms := 0
	var upper := 0
	var terraces := 0
	var houses: Array = state.get("houses")
	for house: Dictionary in houses:
		for cell: Dictionary in house.cells:
			if cell.kind == "terrace":
				terraces += 1
			else:
				rooms += 1
				if int(cell.level) > 0:
					upper += 1
	# Even the starting six houses have the full musical phrase. Building adds
	# gentle color rather than requiring construction to unlock sound.
	_targets.foundation = -10.0
	_targets.wood = lerpf(-14.0, -10.0, clampf(float(rooms) / 30.0, 0.0, 1.0))
	_targets.air = lerpf(-21.0, -13.0, clampf(float(upper) / 10.0, 0.0, 1.0))
	_targets.terrace = lerpf(-26.0, -15.0, clampf(float(terraces) / 8.0, 0.0, 1.0))


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		for effect in _effects:
			effect.stop()


func play_edit(kind: String) -> void:
	if muted or not _edit_streams.has(kind):
		return
	var selected: AudioStreamPlayer = _effects[0]
	for effect in _effects:
		if not effect.playing:
			selected = effect
			break
	selected.stream = _edit_streams[kind]
	selected.play()


func _process(delta: float) -> void:
	if _loading and not _worker.is_alive():
		var bank: Dictionary = _worker.wait_to_finish()
		_loading = false
		audio_report = bank.report
		_edit_streams = bank.edits
		# These play commands run in one frame before the next audio mix. All
		# streams have exactly the same length and sample rate.
		for key in STEMS:
			_players[key].stream = bank.streams[key]
			_players[key].play()
	for key in _players:
		var target := -60.0 if muted else float(_targets[key])
		_players[key].volume_db = lerpf(_players[key].volume_db, target, 1.0 - exp(-delta * 2.8))


func _exit_tree() -> void:
	if _loading:
		_worker.wait_to_finish()
		_loading = false


func _render_bank() -> Dictionary:
	var streams: Dictionary = {}
	var report := {"rate": RATE, "frames": FRAMES, "seconds": SECONDS, "peaks": {}, "seam_steps": {}}
	var chords := [[50, 57, 62], [47, 54, 59], [45, 52, 57], [50, 57, 64], [50, 57, 62], [47, 54, 62], [45, 52, 59], [50, 57, 64]]
	var bass := [38, 35, 33, 38, 38, 35, 33, 38]
	var melody := [74, 69, 66, 71, 69, 64, 66, 69, 74, 76, 71, 69, 66, 64, 69, 66]
	for key in STEMS:
		var samples := PackedFloat32Array()
		samples.resize(FRAMES)
		match key:
			"foundation":
				for bar in range(8):
					for note in chords[bar]:
						_add_note(samples, bar * 3.0, 3.8, int(note), 0.027, "pad", true)
					_add_note(samples, bar * 3.0 + 0.05, 2.8, bass[bar], 0.075, "bass", true)
			"wood":
				for i in range(melody.size()):
					_add_note(samples, i * 1.5 + 0.12, 1.4, melody[i] - 12, 0.105 if i % 2 == 0 else 0.073, "wood", true)
			"air":
				for i in range(8):
					_add_note(samples, i * 3.0 + 0.75, 2.05, melody[i * 2], 0.064, "air", true)
			"terrace":
				for i in range(4):
					_add_note(samples, i * 6.0 + 2.25, 2.6, [81, 78, 83, 78][i], 0.054, "bell", true)
		var peak := 0.0
		for sample in samples:
			peak = maxf(peak, absf(sample))
		report.peaks[key] = peak
		report.seam_steps[key] = absf(samples[0] - samples[FRAMES - 1])
		streams[key] = _pcm_stream(samples, true)
	var edits: Dictionary = {}
	var edit_notes := {"room": [62, 69], "terrace": [74, 81], "road": [57, 62, 66], "erase": [66, 62], "history": [69, 64]}
	for kind in edit_notes:
		var samples := PackedFloat32Array()
		samples.resize(int(RATE * 0.8))
		var notes: Array = edit_notes[kind]
		for i in range(notes.size()):
			_add_note(samples, i * 0.065, 0.58, notes[i], 0.09, "wood" if kind == "road" else "bell", false)
		edits[kind] = _pcm_stream(samples, false)
	return {"streams": streams, "edits": edits, "report": report}


func _add_note(samples: PackedFloat32Array, start: float, duration: float, midi: int, gain: float, timbre: String, wrap: bool) -> void:
	var frequency := 440.0 * pow(2.0, float(midi - 69) / 12.0)
	var phase_step := TAU * frequency / RATE
	var count := int(duration * RATE)
	var start_frame := int(start * RATE)
	var decay := exp(-1.0 / (RATE * (0.6 if timbre == "bell" else 0.34)))
	var tail := 1.0
	for i in range(count):
		var index := start_frame + i
		if wrap:
			index %= samples.size()
		elif index >= samples.size():
			break
		var t := float(i) / RATE
		var phase := phase_step * i
		var tone := sin(phase)
		var envelope := 0.0
		match timbre:
			"pad":
				envelope = sin(PI * t / duration)
				envelope *= envelope
				tone += 0.10 * sin(phase * 2.0)
			"bass":
				envelope = minf(t / 0.12, 1.0) * minf((duration - t) / 0.5, 1.0)
				tone += 0.14 * sin(phase * 2.0)
			"air":
				envelope = minf(t / 0.35, 1.0) * minf((duration - t) / 0.65, 1.0)
				tone = sin(phase + 0.025 * sin(TAU * 4.6 * t)) + 0.07 * sin(phase * 2.0)
			"wood":
				envelope = minf(t / 0.008, 1.0) * tail * minf((duration - t) / 0.12, 1.0)
				tone += 0.24 * sin(phase * 2.0) + 0.08 * sin(phase * 3.0)
			"bell":
				envelope = minf(t / 0.012, 1.0) * tail * minf((duration - t) / 0.2, 1.0)
				tone += 0.18 * sin(phase * 3.0)
		samples[index] += tone * envelope * gain
		tail *= decay


func _pcm_stream(samples: PackedFloat32Array, looped: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
