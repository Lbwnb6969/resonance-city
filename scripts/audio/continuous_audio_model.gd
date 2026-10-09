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
var decisions: Array[Dictionary] = []
var sound_events: Array[Dictionary] = []
var sound_overrides: Dictionary = {}
var sound_trace: Array[Dictionary] = []
var last_sample := Vector2.ZERO
var transition_offset := Vector2.ZERO
var transition_remaining := 0
var transition_total := 0
var max_render_ms := 0.0
var max_settle_ms := 0.0
var bed_table := PackedFloat32Array()

func _init(city_world: ContinuousWorld, fixed_gain: float = 1.0) -> void:
	world = city_world
	synth = Synth.new(world.buildings)
	synth.score = world.cfg["score"]
	synth.warm_score()
	synth.assist_enabled = false
	synth.gain = fixed_gain
	phrase_frames = int(world.cfg["timing"]["phrase_frames"])
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
	var seam := float(bed_table[-1])
	for i in range(64): bed_table[i] = lerpf(seam,bed_table[i],smoothstep(0.0,1.0,float(i)/63.0))

func submit(operation: Dictionary) -> Dictionary:
	var kind := str(operation.get("kind",""))
	var beat := next_boundary if rendered_until == 0 else (rendered_until/beat_frames+1)*beat_frames
	if kind in ["solo","mute"]:
		var event := operation.duplicate(true)
		event["sound_frame"] = beat
		sound_events.append(event)
		_sort_sound_events()
		decisions.append({"requested_frame":rendered_until,"operation":operation.duplicate(true),"sound_frame":beat,"structure_frame":-1})
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
	if result["accepted"]: decisions.append({"requested_frame":rendered_until,"operation":operation.duplicate(true),"sound_frame":result.get("sound_frame",-1),"structure_frame":result["frame"]})
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
	for landmark in world.landmarks:
		var motif: Array = landmark.get("motif",[])
		var midi := int(motif[0].get("midi",48)) if not motif.is_empty() else 48
		city.append({"district_id":str(landmark["id"]),"position":landmark["position"],"radius":float(landmark["radius"]),
			"current_midi":midi,"base_midi":midi,"type":"residential","vitality":100.0,
			"community_id":"landmark:"+str(landmark["id"]),"family_id":"landmark:"+str(landmark["id"]),
			"expression":"bright","family_anchor":true,"is_anchor":true,"era":int(landmark.get("era",1)),
			"form":"央","form_count":0,"birth_frame":int(landmark.get("frame",0)),"voice_level":float(landmark.get("voice_level",0.34)),
			"landmark":true})
	return city

func _apply_sound(event: Dictionary) -> void:
	match str(event["kind"]):
		"retune": sound_overrides[event["id"]] = int(event["midi"])
		"solo": synth.listener_community = str(event.get("community",""))
		"mute": synth.muted_communities[event["community"]] = bool(event["enabled"])
	sound_trace.append(event.duplicate(true))
	if sound_trace.size() > 64: sound_trace.pop_front()

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	var started_us := Time.get_ticks_usec()
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
			var settle_us := Time.get_ticks_usec()
			world.settle(at)
			max_settle_ms = maxf(max_settle_ms,float(Time.get_ticks_usec()-settle_us)/1000.0)
			changed = true
			next_boundary += phrase_frames
		if changed:
			# Remove the residual step for 40 ms. Musical layers continue their own two-beat fades.
			transition_total = maxi(1,roundi(float(world.cfg["score"]["pitch_glide_seconds"])*rate))
			transition_remaining = transition_total
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
			block[i] += Vector2.ONE*(breath+stream)
			var duck_target := synth.duck_level if synth.ducking else 1.0
			var duck_seconds := float(world.cfg["score"]["pitch_glide_seconds"]) if synth.ducking else float(synth.values["mixing"]["duck_release_seconds"])
			var duck := move_toward(float(state.get("_score_duck",1.0)),duck_target,1.0/(duck_seconds*rate))
			state["_score_duck"] = duck
			block[i] *= duck
			if transition_remaining > 0:
				if transition_remaining == transition_total: transition_offset = last_sample-block[i]
				var remaining := float(transition_remaining)/float(transition_total)
				block[i] += transition_offset*remaining*remaining*remaining
				transition_remaining -= 1
			last_sample = block[i]
		output.append_array(block)
		at += amount
	rendered_until = maxi(rendered_until,start+count)
	max_render_ms = maxf(max_render_ms,float(Time.get_ticks_usec()-started_us)/1000.0)
	return output

func presentation_world(audible_frame: float) -> ContinuousWorld:
	while not presentation_history.is_empty() and int(presentation_history[0]["frame"]) <= audible_frame: presentation_history.pop_front()
	if presentation_history.is_empty():
		presentation_copy = null
		presentation_copy_frame = -1
		return world
	var entry: Dictionary = presentation_history[0]
	if presentation_copy == null or presentation_copy_frame != int(entry["frame"]):
		presentation_copy = World.new(world.rng.seed_hex,false)
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
	copy.last_sample = last_sample
	copy.transition_offset = transition_offset
	copy.transition_remaining = transition_remaining
	copy.transition_total = transition_total
	copy.sound_events.assign(sound_events.duplicate(true))
	copy.sound_trace.assign(sound_trace.duplicate(true))
	copy.sound_overrides = sound_overrides.duplicate(true)
	copy.decisions.assign(decisions.duplicate(true))
	copy.synth.listener_community = synth.listener_community
	copy.synth.muted_communities = synth.muted_communities.duplicate(true)
	copy.synth.pad_groups = synth.pad_groups.duplicate(true)
	copy.synth.rhythm_nodes = synth.rhythm_nodes.duplicate(true)
	copy.synth.musical_nodes = synth.musical_nodes.duplicate(true)
	copy.synth.update_city(copy.audio_city(),{}, {},[])
	copy.synth.configure_score(copy.world,copy.sound_overrides)
	return copy

const SAVED_SYNTH_FIELDS = ["pad_groups","population","rhythm_nodes","musical_nodes","theme","response","rhythms",
	"listener_community","muted_communities","gray_enabled","gray_from","gray_change_at","ducking","duck_release_at","last_voice_count","max_voice_count","voice_group_stats"]

static func _hydrate_stereo(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = value.duplicate(true)
		for key in result:
			if str(key) == "stereo" and result[key] is Array and result[key].size() >= 2:
				result[key] = Vector2(float(result[key][0]),float(result[key][1]))
			else:
				result[key] = _hydrate_stereo(result[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item in value: result_array.append(_hydrate_stereo(item))
		return result_array
	return value

func capture_state() -> Dictionary:
	var mix: Dictionary = {}
	for field in SAVED_SYNTH_FIELDS: mix[field] = synth.get(field)
	return {"world":world.snapshot(),"gain":synth.gain,"next_boundary":next_boundary,"rendered_until":rendered_until,
		"event_cursor":event_cursor,"sound_events":sound_events.duplicate(true),"sound_trace":sound_trace.duplicate(true),"sound_overrides":sound_overrides.duplicate(true),
		"decisions":decisions.duplicate(true),"presentation_history":presentation_history.duplicate(true),
		"last_sample":last_sample,"transition_offset":transition_offset,"transition_remaining":transition_remaining,
		"transition_total":transition_total,"mix":mix.duplicate(true)}

static func from_state(saved: Dictionary) -> ContinuousAudioModel:
	var city := World.new(saved["world"]["seed_hex"],false)
	city.restore(saved["world"])
	var copy := ContinuousAudioModel.new(city,float(saved["gain"]))
	copy.next_boundary = int(saved["next_boundary"])
	copy.rendered_until = int(saved["rendered_until"])
	copy.event_cursor = int(saved["event_cursor"])
	copy.sound_events.assign(saved["sound_events"].duplicate(true))
	copy.sound_trace.assign(saved.get("sound_trace",[]).duplicate(true))
	copy.sound_overrides = saved["sound_overrides"].duplicate(true)
	copy.decisions.assign(saved["decisions"].duplicate(true))
	copy.presentation_history.assign(saved["presentation_history"].duplicate(true))
	var saved_last_sample: Variant = saved.get("last_sample",Vector2.ZERO)
	var saved_transition_offset: Variant = saved.get("transition_offset",Vector2.ZERO)
	copy.last_sample = saved_last_sample if saved_last_sample is Vector2 else Vector2(float(saved_last_sample[0]),float(saved_last_sample[1]))
	copy.transition_offset = saved_transition_offset if saved_transition_offset is Vector2 else Vector2(float(saved_transition_offset[0]),float(saved_transition_offset[1]))
	copy.transition_remaining = int(saved["transition_remaining"])
	copy.transition_total = int(saved["transition_total"])
	for field in SAVED_SYNTH_FIELDS: copy.synth.set(field,saved["mix"][field])
	copy.synth.pad_groups = _hydrate_stereo(copy.synth.pad_groups)
	copy.synth.rhythm_nodes = _hydrate_stereo(copy.synth.rhythm_nodes)
	copy.synth.musical_nodes = _hydrate_stereo(copy.synth.musical_nodes)
	copy.synth.theme = _hydrate_stereo(copy.synth.theme)
	copy.synth.response = _hydrate_stereo(copy.synth.response)
	for index in range(copy.synth.rhythms.size()): copy.synth.rhythms[index] = _hydrate_stereo(copy.synth.rhythms[index])
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
