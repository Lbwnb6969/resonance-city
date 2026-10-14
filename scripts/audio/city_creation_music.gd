class_name CityCreationMusic
extends Node
## Original D-major pentatonic morning miniature. PCM is rendered once on a
## worker, then five synchronized loops respond to the town through gain only.
const RATE := 22050
const SECONDS := 24.0
const FRAMES := 529200
const STEMS := ["foundation", "wood", "air", "terrace", "concert"]

var muted := false
var concert_active := false
var audio_report: Dictionary = {}
var _daily_houses: Array[String] = []
var _players: Dictionary = {}
var _targets := {"foundation": -10.0, "wood": -12.0, "air": -17.0, "terrace": -22.0, "concert": -60.0}
var _effects: Array[AudioStreamPlayer] = []
var _edit_streams: Dictionary = {}
var _worker: Thread
var _loading := false
var _concert_venue := ""
var _concert_houses: Array[String] = []
var _concert_loop := 0
var _concert_previous_position := 0.0


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
	_daily_houses.clear()
	for house: Dictionary in houses:
		_daily_houses.append(str(house.id))
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
	_daily_houses.sort()


func set_muted(value: bool) -> void:
	if muted == value:
		return
	muted = value
	if muted:
		for player: AudioStreamPlayer in _players.values():
			player.volume_linear = 0.0
		for effect in _effects:
			effect.stop()
	else:
		# Silence is -INF dB. Resume fading from a finite floor, keeping every
		# player's existing playback position and the concert lifecycle intact.
		for player: AudioStreamPlayer in _players.values():
			player.volume_db = -60.0


func set_concert_active(active: bool) -> void:
	concert_active = active


func set_concert_sources(venue_id: String, house_ids: Array[String]) -> void:
	_concert_venue = venue_id
	_concert_houses.clear()
	for house_id in house_ids:
		if not house_id.is_empty() and house_id != venue_id and not _concert_houses.has(house_id):
			_concert_houses.append(house_id)
	_concert_houses.sort()


func _source_schedule() -> Array[Dictionary]:
	var schedule: Array[Dictionary] = []
	for phrase in range(8):
		schedule.append(_source_for_phrase(phrase))
	return schedule


func _source_for_phrase(phrase: int) -> Dictionary:
	var answer := phrase % 2 == 1 and not _concert_houses.is_empty()
	var source_id := _concert_venue
	if answer:
		# Four answers per loop. Continue through every participating house
		# across subsequent loops without allocating extra audio voices.
		source_id = _concert_houses[(_concert_loop * 4 + int(phrase / 2)) % _concert_houses.size()]
	return {"source_id": source_id, "phrase": phrase, "role": "answer" if answer else "lead", "timbre": "wood" if phrase % 2 == 1 else "piano", "start": phrase * 3.0, "duration": 3.0}


func active_source() -> Dictionary:
	var result := {"source_id": "", "phrase": 0, "role": "lead", "timbre": "piano", "audible": false}
	if not _players.has("concert"):
		return result
	var player: AudioStreamPlayer = _players.concert
	var position := fposmod(player.get_playback_position(), SECONDS)
	var phrase := clampi(int(position / 3.0), 0, 7)
	result = _source_for_phrase(phrase)
	result["audible"] = concert_active and not muted and player.playing and player.volume_db > -30.0 and not String(result.source_id).is_empty()
	return result


func target_gain_db(key: String, during_concert: bool) -> float:
	if key == "concert":
		return -8.0 if during_concert else -60.0
	var gain := float(_targets[key])
	if during_concert:
		if key == "wood":
			gain -= 10.0
		elif key == "air":
			gain -= 7.0
	return gain

func daily_source() -> Dictionary:
	var result := {"source_id":"","role":"daily","audible":false,"timbre":"wood"}
	if _daily_houses.is_empty() or not _players.has("wood"): return result
	var player: AudioStreamPlayer = _players.wood
	var phrase := clampi(int(player.get_playback_position()/3.0),0,7)
	result.source_id = _daily_houses[(_concert_loop*8+phrase)%_daily_houses.size()]
	result["phrase"] = phrase
	result.audible = not concert_active and not muted and player.playing and player.volume_db > -30.0
	return result


func music_report() -> Dictionary:
	var result := audio_report.duplicate(true)
	result["loading"] = _loading
	result["muted"] = muted
	result["concert_active"] = concert_active
	result["players"] = _players.size()
	result["gains_db"] = {}
	result["positions"] = {}
	result["source_schedule"] = _source_schedule()
	result["source_loop"] = _concert_loop
	result["active_source"] = active_source()
	result["daily_source"] = daily_source()
	result["daily_houses"] = _daily_houses.duplicate()
	for key in _players:
		result.gains_db[key] = _players[key].volume_db if not muted else -80.0
		result.positions[key] = _players[key].get_playback_position()
	return result


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
	if _players.has("concert") and _players.concert.playing:
		var position: float = _players.concert.get_playback_position()
		if position + 0.1 < _concert_previous_position:
			_concert_loop += 1
		_concert_previous_position = position
	for key in _players:
		if muted:
			_players[key].volume_linear = 0.0
			continue
		var target := target_gain_db(key, concert_active)
		_players[key].volume_db = lerpf(_players[key].volume_db, target, 1.0 - exp(-delta * 2.8))


func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players.values():
		player.stop()
		player.stream = null
	for effect: AudioStreamPlayer in _effects:
		effect.stop()
		effect.stream = null
	if _loading:
		_worker.wait_to_finish()
		_loading = false


func _render_bank() -> Dictionary:
	var streams: Dictionary = {}
	var report := {"rate": RATE, "frames": FRAMES, "seconds": SECONDS, "stem_count": STEMS.size(), "peaks": {}, "seam_steps": {}, "pcm_bytes": FRAMES * 2 * STEMS.size(), "synthesis": "original_procedural_miniature"}
	var chords := [[50, 57, 62], [47, 54, 59], [45, 52, 57], [50, 57, 64], [50, 57, 62], [47, 54, 62], [45, 52, 59], [50, 57, 64]]
	var bass := [38, 35, 33, 38, 38, 35, 33, 38]
	var melody := [74, 69, 66, 71, 69, 64, 66, 69, 74, 76, 71, 69, 66, 64, 69, 66]
	var day_mix := PackedFloat32Array()
	var concert_mix := PackedFloat32Array()
	day_mix.resize(FRAMES)
	concert_mix.resize(FRAMES)
	var maximum_gains := {"foundation": -10.0, "wood": -10.0, "air": -13.0, "terrace": -15.0, "concert": -60.0}
	var absolute_bound := 0.0
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
			"concert":
				# An original call-and-response phrase. The low chord plucks give
				# residents a small shared pulse without turning town music into
				# a rhythm-game backing track. All tails wrap through the loop.
				var lead := [69, 74, 76, 74, 71, 69, 66, 69, 71, 74, 69, 66, 64, 66, 69, 74]
				for i in range(lead.size()):
					var timbre := "piano" if int(i / 2) % 2 == 0 else "wood"
					_add_note(samples, i * 1.5 + 0.18, 1.65, lead[i], 0.105 if i % 4 == 0 else 0.081, timbre, true)
				for bar in range(8):
					for n in range(3):
						_add_note(samples, bar * 3.0 + 0.10 + n * 0.07, 1.30, chords[bar][n], 0.033, "pluck", true)
					_add_note(samples, bar * 3.0 + 1.60, 0.95, chords[bar][1] + 12, 0.026, "pluck", true)
					_add_pulse(samples, bar * 3.0 + 0.02, 0.065, false)
					_add_pulse(samples, bar * 3.0 + 1.52, 0.022, true)
		var peak := 0.0
		for sample in samples:
			peak = maxf(peak, absf(sample))
		report.peaks[key] = peak
		report.seam_steps[key] = absf(samples[0] - samples[FRAMES - 1])
		var day_gain := db_to_linear(float(maximum_gains[key]))
		var concert_db := float(maximum_gains[key])
		if key == "wood":
			concert_db -= 10.0
		elif key == "air":
			concert_db -= 7.0
		elif key == "concert":
			concert_db = -8.0
		var concert_gain := db_to_linear(concert_db)
		absolute_bound += peak * maxf(day_gain, concert_gain)
		for i in range(FRAMES):
			day_mix[i] += samples[i] * day_gain
			concert_mix[i] += samples[i] * concert_gain
		streams[key] = _pcm_stream(samples, true)
	var day_peak := 0.0
	var concert_peak := 0.0
	for i in range(FRAMES):
		day_peak = maxf(day_peak, absf(day_mix[i]))
		concert_peak = maxf(concert_peak, absf(concert_mix[i]))
	report["mix_peaks"] = {"daily_max_city": day_peak, "concert_max_city": concert_peak, "absolute_transition_bound": absolute_bound}
	report["mix_seam_steps"] = {"daily_max_city": absf(day_mix[0] - day_mix[FRAMES - 1]), "concert_max_city": absf(concert_mix[0] - concert_mix[FRAMES - 1])}
	var edits: Dictionary = {}
	report["effect_peaks"] = {}
	var effect_peak := 0.0
	var edit_notes := {"room": [62, 69], "terrace": [74, 81], "road": [57, 62, 66], "erase": [66, 62], "history": [69, 64], "concert": [62, 66, 69]}
	for kind in edit_notes:
		var samples := PackedFloat32Array()
		samples.resize(int(RATE * 0.8))
		var notes: Array = edit_notes[kind]
		for i in range(notes.size()):
			_add_note(samples, i * 0.065, 0.58, notes[i], 0.09, "wood" if kind == "road" else "bell", false)
		var peak := 0.0
		for sample in samples:
			peak = maxf(peak, absf(sample))
		report.effect_peaks[kind] = peak
		effect_peak = maxf(effect_peak, peak)
		edits[kind] = _pcm_stream(samples, false)
	report.mix_peaks["absolute_with_four_edit_voices"] = absolute_bound + effect_peak * db_to_linear(-10.0) * 4.0
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
			"piano":
				envelope = minf(t / 0.009, 1.0) * exp(-t * 2.0) * minf((duration - t) / 0.22, 1.0)
				tone += 0.32 * sin(phase * 2.0) * exp(-t * 3.0) + 0.13 * sin(phase * 3.0) * exp(-t * 5.0)
			"pluck":
				envelope = minf(t / 0.004, 1.0) * exp(-t * 4.0) * minf((duration - t) / 0.15, 1.0)
				tone += 0.30 * sin(phase * 2.0) + 0.12 * sin(phase * 3.0) + 0.05 * sin(phase * 5.0)
		samples[index] += tone * envelope * gain
		tail *= decay


func _add_pulse(samples: PackedFloat32Array, start: float, gain: float, light: bool) -> void:
	var duration := 0.18 if light else 0.40
	var start_frame := int(start * RATE)
	for i in range(int(duration * RATE)):
		var t := float(i) / RATE
		var envelope := minf(t / 0.004, 1.0) * exp(-t * (28.0 if light else 13.0)) * minf((duration - t) / 0.025, 1.0)
		var phase := TAU * (145.0 * t if light else 54.0 * t + 16.0 * (1.0 - exp(-t * 24.0)) / 24.0)
		var tone := sin(phase) + (0.24 * sin(phase * 3.17) if light else 0.08 * sin(phase * 2.0))
		samples[(start_frame + i) % samples.size()] += tone * envelope * gain


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
