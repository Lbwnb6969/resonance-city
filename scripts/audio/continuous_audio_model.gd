class_name ContinuousAudioModel
extends RefCounted
const World = preload("res://scripts/world/continuous_world.gd")
const Synth = preload("res://scripts/audio/continuous_synth.gd")
const Config = preload("res://scripts/world/world_values.gd")
var world: ContinuousWorld
var synth: ContinuousSynth
var phrase_frames: int
var beat_frames: int
var next_boundary: int
var rendered_until := 0
var presentation_history: Array[Dictionary] = []
var presentation_copy: ContinuousWorld
var presentation_copy_frame := -1
var event_cursor := 0
var sound_events: Array[Dictionary] = []
var sound_overrides: Dictionary = {}
var sound_trace: Array[Dictionary] = []
var last_sample := Vector2.ZERO
var transition_from := Vector2.ZERO
var transition_remaining := 0
var transition_total := 0
var bed_table := PackedFloat32Array()

func _init(city_world: ContinuousWorld, fixed_gain: float = 1.0) -> void:
	world = city_world
	synth = Synth.new(world.buildings)
	synth.assist_enabled = false
	synth.gain = fixed_gain
	phrase_frames = int(Config.load_values()["timing"]["phrase_frames"])
	beat_frames = phrase_frames/32
	next_boundary = (world.phrase_index+1)*phrase_frames
	event_cursor = world.events.size()
	synth.update_city(world.buildings,{}, {},[])
	synth.configure_score(world)
	var value := world.rng.seed_hex.substr(0,8).hex_to_int()
	var filtered := 0.0
	bed_table.resize(4096)
	for i in range(bed_table.size()):
		value = (1664525*value+1013904223)&0xffffffff
		filtered = lerpf(filtered,float(value)/4294967296.0*2.0-1.0,0.08)
		bed_table[i] = filtered

func submit(operation: Dictionary) -> Dictionary:
	var kind := str(operation.get("kind",""))
	var beat := next_boundary if rendered_until == 0 else (rendered_until/beat_frames+1)*beat_frames
	if kind in ["solo","mute"]:
		var event := operation.duplicate(true)
		event["sound_frame"] = beat
		sound_events.append(event)
		_sort_sound_events()
		return {"accepted":true,"frame":beat,"sound_frame":beat}
	var result := world.request(operation,next_boundary)
	if result["accepted"] and kind == "retune":
		var event := operation.duplicate(true)
		event["sound_frame"] = beat
		event["event_id"] = result["event_id"]
		sound_events = sound_events.filter(func(old: Dictionary) -> bool: return old.get("id","") != event["id"] or old["kind"] != "retune")
		sound_events.append(event)
		_sort_sound_events()
		result["sound_frame"] = beat
	return result

func _sort_sound_events() -> void:
	sound_events.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a["sound_frame"] != b["sound_frame"]: return a["sound_frame"] < b["sound_frame"]
		return str(a.get("id","")) < str(b.get("id","")))

func cancel_pending() -> void:
	world.pending_actions = world.pending_actions.filter(func(op: Dictionary) -> bool:
		return op["kind"] == "retune" and sound_overrides.has(op["id"]))
	sound_events.clear()
	world.pending = world.pending_actions[-1].duplicate(true) if not world.pending_actions.is_empty() else {}

func _mix_frame(_state: Dictionary, _at: int, _rate: int) -> Vector2:
	return Vector2.ZERO

func _record_presentation(at: int) -> void:
	if not presentation_history.is_empty() and int(presentation_history[-1]["frame"]) == at: return
	presentation_history.append({"frame":at,"before":world.snapshot(),"pitches":sound_overrides.duplicate(true)})

func audio_city() -> Array:
	var city := world.buildings.duplicate(true)
	for building in city:
		if sound_overrides.has(building["district_id"]): building["current_midi"] = sound_overrides[building["district_id"]]
	return city

func _apply_sound(event: Dictionary) -> void:
	match str(event["kind"]):
		"retune": sound_overrides[event["id"]] = int(event["midi"])
		"solo": synth.listener_community = str(event.get("community",""))
		"mute": synth.muted_communities[event["community"]] = bool(event["enabled"])
	sound_trace.append(event.duplicate(true))
	if sound_trace.size() > 64: sound_trace.pop_front()

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	var output := PackedVector2Array()
	var at := start
	rendered_until = maxi(rendered_until,start)
	while at < start+count:
		var changed := false
		while not sound_events.is_empty() and int(sound_events[0]["sound_frame"]) <= at:
			_record_presentation(at)
			_apply_sound(sound_events.pop_front())
			changed = true
		if at == next_boundary:
			_record_presentation(at)
			world.settle(at)
			changed = true
			next_boundary += phrase_frames
		if changed:
			# Any structural or pitch change gets a sample-accurate equal-power handoff.
			# The previous PCM sample is the anchor; no newly born oscillator may start at a discontinuity.
			transition_from = last_sample
			transition_total = maxi(1,roundi(float(world.cfg["score"]["control_fade_beats"])*60.0*rate/float(world.cfg["timing"]["bpm"])))
			transition_remaining = maxi(transition_remaining,transition_total)
			var recent: Array = world.events.slice(event_cursor)
			event_cursor = world.events.size()
			synth.update_city(audio_city(),state,{},recent)
			synth.configure_score(world,sound_overrides)
			synth.set_gray(bool(world.lifecycle["gray"]),at)
		var until := next_boundary
		if not sound_events.is_empty(): until = mini(until,int(sound_events[0]["sound_frame"]))
		var amount := mini(start+count-at,until-at)
		var block := synth.render_block(state,at,amount,rate)
		var bed_gain := float(world.cfg["score"]["bed_gain"])
		for i in range(block.size()):
			var frame := at+i
			var breath := 0.004*sin(TAU*130.81*float(frame)/rate) if world.buildings.is_empty() else 0.0
			var stream := float(bed_table[frame%bed_table.size()])*bed_gain
			block[i] += Vector2.ONE*(breath+stream)*(synth.duck_level if synth.ducking else 1.0)
			if transition_remaining > 0:
				var progress := 1.0-float(transition_remaining)/float(transition_total)
				block[i] = transition_from.lerp(block[i],smoothstep(0.0,1.0,progress))
				transition_remaining -= 1
			last_sample = block[i]
		output.append_array(block)
		at += amount
	rendered_until = maxi(rendered_until,start+count)
	return output

func presentation_world(audible_frame: float) -> ContinuousWorld:
	while not presentation_history.is_empty() and int(presentation_history[0]["frame"]) <= audible_frame: presentation_history.pop_front()
	if presentation_history.is_empty():
		presentation_copy = null
		presentation_copy_frame = -1
		return world
	var entry: Dictionary = presentation_history[0]
	if presentation_copy == null or presentation_copy_frame != int(entry["frame"]):
		presentation_copy = World.new(world.rng.seed_hex)
		presentation_copy.restore(entry["before"])
		presentation_copy_frame = int(entry["frame"])
	presentation_copy.pending = world.pending.duplicate(true)
	return presentation_copy

func audible_pitches() -> Dictionary:
	return sound_overrides if presentation_history.is_empty() else presentation_history[0]["pitches"]

func freeze() -> ContinuousAudioModel:
	var copy: ContinuousAudioModel = get_script().new(world.fork(),synth.gain)
	copy.next_boundary = next_boundary
	copy.rendered_until = rendered_until
	copy.event_cursor = event_cursor
	copy.sound_events.assign(sound_events.duplicate(true))
	copy.sound_overrides = sound_overrides.duplicate(true)
	copy.synth.listener_community = synth.listener_community
	copy.synth.muted_communities = synth.muted_communities.duplicate(true)
	copy.synth.pad_groups = synth.pad_groups.duplicate(true)
	copy.synth.update_city(copy.audio_city(),{}, {},[])
	copy.synth.configure_score(copy.world,copy.sound_overrides)
	return copy

func forecast(operation: Dictionary, state: Dictionary, at: int, duration: int) -> PackedVector2Array:
	var preview_model := freeze()
	preview_model.cancel_pending()
	preview_model.rendered_until = at
	var result := preview_model.submit(operation)
	if not result["accepted"]: return PackedVector2Array()
	var phases := state.duplicate(true)
	var boundary := int(result.get("sound_frame",preview_model.next_boundary))
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	for begin in range(at,boundary,512):
		preview_model.render_block(phases,begin,mini(512,boundary-begin),rate)
	return preview_model.render_block(phases,boundary,duration,rate)
