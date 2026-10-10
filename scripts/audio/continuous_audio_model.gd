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
var presentation_stats := {"prepared":0,"reconstructed":0}
# A display cache may outlive a model: retain only this small session token.
# Different World objects for the same audible phrase share the token.
var presentation_token := RefCounted.new()
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
const SettlementJob = preload("res://scripts/world/world_settlement_job.gd")
# Private worker projection; omitted from DNA and preview state.
var prepared_audio_buildings: Array = []
var prepared_audio_update: Dictionary = {}
var audio_preparation_stats := {"used":0,"fallback":0}
const AudioPreparation = preload("res://scripts/audio/community_audio_preparation.gd")
var prepared_audio_phrase := -1
var settlement_enabled := false
var settlement_job: RefCounted
var retiring_settlements: Array[RefCounted] = []
var settlement_stats := {"started":0,"adopted":0,"discarded":0,"fallbacks":0,"retired":0,
	"max_capture_ms":0.0,"max_worker_ms":0.0,"max_commit_ms":0.0}

func _settlement_version() -> Array:
	return [world.phrase_index,world.action_serial,world.planning_revision,world.mode,world.profile,
		hash(world.pending_actions),hash(world.pending)]

func enable_background_settlement() -> void:
	settlement_enabled = true

func close_background_settlement() -> void:
	settlement_enabled = false
	if settlement_job != null:
		settlement_job.join()
		_retire_settlement_job()
	for job in retiring_settlements: job.join()
	retiring_settlements.clear()

func _retire_settlement_job() -> void:
	settlement_job.retire()
	retiring_settlements.append(settlement_job)
	settlement_job = null

func prepare_settlement(at: int, rate: int) -> void:
	if not settlement_enabled: return
	for i in range(retiring_settlements.size()-1,-1,-1):
		if retiring_settlements[i].completed():
			retiring_settlements[i].join()
			retiring_settlements.remove_at(i)
			settlement_stats["retired"] += 1
	var version := _settlement_version()
	if settlement_job != null:
		if settlement_job.task_id >= 0:
			if not settlement_job.completed(): return
			settlement_job.join()
			settlement_stats["max_worker_ms"] = maxf(settlement_stats["max_worker_ms"],settlement_job.worker_ms)
		if settlement_job.version != version or settlement_job.commit_frame != next_boundary:
			settlement_stats["discarded"] += 1
			_retire_settlement_job()
		else: return
	# Two seconds of preparation do not add queued PCM or change input timing.
	if next_boundary-at > rate*2: return
	var started := Time.get_ticks_usec()
	settlement_job = SettlementJob.new()
	settlement_job.start(world,version,next_boundary)
	settlement_stats["started"] += 1
	settlement_stats["max_capture_ms"] = maxf(settlement_stats["max_capture_ms"],float(Time.get_ticks_usec()-started)/1000.0)

func _settlement_ready(at: int) -> bool:
	return settlement_job != null and settlement_job.commit_frame == at and settlement_job.version == _settlement_version() and (settlement_job.task_id < 0 or settlement_job.completed())

func _commit_settlement(at: int) -> void:
	if _settlement_ready(at):
		settlement_job.join()
		settlement_stats["max_worker_ms"] = maxf(settlement_stats["max_worker_ms"],settlement_job.worker_ms)
		var started := Time.get_ticks_usec()
		settlement_job.adopt(world)
		prepared_audio_buildings = settlement_job.audio_buildings
		prepared_audio_update = settlement_job.audio_preparation
		prepared_audio_phrase = world.phrase_index
		settlement_stats["max_commit_ms"] = maxf(settlement_stats["max_commit_ms"],float(Time.get_ticks_usec()-started)/1000.0)
		settlement_stats["adopted"] += 1
		_retire_settlement_job()
	else:
		prepared_audio_buildings = []
		prepared_audio_update = {}
		prepared_audio_phrase = -1
		world.settle(at)
		if settlement_enabled: settlement_stats["fallbacks"] += 1


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
	if kind in ["solo","mute","focus"]:
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

func cancel_planning() -> void:
	world.pending_actions = world.pending_actions.filter(func(op: Dictionary) -> bool:
		return str(op["kind"]) not in ["reserve","release_reservation"] and not (str(op["kind"]) in ["park","civic"] and op.has("position")))
	world.pending = world.pending_actions[-1].duplicate(true) if not world.pending_actions.is_empty() else {}
	decisions.append({"requested_frame":rendered_until,"operation":{"kind":"cancel_planning"},"sound_frame":-1,"structure_frame":-1})

func _mix_frame(_state: Dictionary, _at: int, _rate: int) -> Vector2:
	return Vector2.ZERO

func _record_presentation(at: int) -> void:
	if not presentation_history.is_empty() and int(presentation_history[-1]["frame"]) == at: return
	if _settlement_ready(at):
		settlement_job.join()
		presentation_history.append({"frame":at,"before":settlement_job.snapshot,
			"pitches":sound_overrides.duplicate(true),"score":synth.score_snapshot(),"view":settlement_job.presentation_view})
		presentation_stats["prepared"] += 1
		return
	presentation_history.append({"frame":at,"before":world.snapshot(),"pitches":sound_overrides.duplicate(true),"score":synth.score_snapshot(),
		"derived":{"fabric":world.fabric_cache.duplicate(true),"edges":world.edge_cache.duplicate(true),
			"service":world.public_service_cache.duplicate(true),"resonance":world.resonance}})

func audio_city() -> Array:
	# Public callers receive independent building data as before.
	return _finish_audio_city(world.buildings.duplicate(true))

func _owned_audio_city() -> Array:
	if prepared_audio_phrase != world.phrase_index: return audio_city()
	return _finish_audio_city(prepared_audio_buildings.duplicate())

func _finish_audio_city(city: Array) -> Array:
	for i in range(city.size()):
		var building: Dictionary = city[i]
		if sound_overrides.has(building["district_id"]):
			city[i] = building.duplicate(true)
			city[i]["current_midi"] = sound_overrides[building["district_id"]]
	city.append_array(AudioPreparation.landmark_records(world.landmarks))
	return city

func _matching_audio_preparation() -> Dictionary:
	if prepared_audio_phrase != world.phrase_index or prepared_audio_update.is_empty(): return {}
	if prepared_audio_update["score_signature"] != [synth.score["pad_gain"],synth.score.get("pad_reference_communities",3.0)]: return {}
	# Retunes after capture keep their exact sound frame. Rebuild on the main
	# thread whenever the audible pitch differs from the prepared structural pitch.
	for building in prepared_audio_buildings:
		var id: String = building["district_id"]
		if sound_overrides.has(id) and int(sound_overrides[id]) != int(building["current_midi"]): return {}
	return prepared_audio_update

func _apply_sound(event: Dictionary) -> void:
	match str(event["kind"]):
		"retune": sound_overrides[event["id"]] = int(event["midi"])
		"solo": synth.listener_community = str(event.get("community",""))
		"focus": synth.focused_community = str(event.get("community",""))
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
			_commit_settlement(at)
			max_settle_ms = maxf(max_settle_ms,float(Time.get_ticks_usec()-settle_us)/1000.0)
			changed = true
			next_boundary += phrase_frames
		if changed:
			var recent: Array = world.events.slice(event_cursor)
			event_cursor = world.events.size()
			# Structural births/upgrades add layers at a phrase boundary. Give the
			# complete bus an 80 ms seam so the new event joins under the old sample
			# instead of sounding like a click, while ordinary retunes keep the
			# shorter pitch glide.
			var structural_change := recent.any(func(event: Dictionary) -> bool:
				return str(event.get("kind","")) in ["birth","upgrade","landmark","park","civic","bridge","era","community_split"])
			var seam_seconds := 0.08 if structural_change else float(world.cfg["score"]["pitch_glide_seconds"])
			transition_total = maxi(1,roundi(seam_seconds*rate))
			transition_remaining = transition_total
			var audio_preparation := _matching_audio_preparation()
			audio_preparation_stats["fallback" if audio_preparation.is_empty() else "used"] += 1
			synth.update_audio_city(_owned_audio_city(),state,{},recent,audio_preparation)
			var era_events: Array = recent.filter(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "era")
			if not era_events.is_empty():
				var era_event: Dictionary = era_events[-1]
				synth.begin_continuous_era_transition(int(era_event.get("frame",at)),int(era_event.get("era",world.era)),rate)
			synth.configure_score(world,sound_overrides)
			synth.set_gray(bool(world.lifecycle["gray"]),at)
		var until := next_boundary
		if not sound_events.is_empty(): until = mini(until,int(sound_events[0]["sound_frame"]))
		var amount := mini(start+count-at,until-at)
		var block := synth.render_block(state,at,amount,rate)
		var bed_gain := float(world.cfg["score"]["bed_gain"])
		var empty_city := world.buildings.is_empty()
		var duck_target := synth.duck_level if synth.ducking else 1.0
		var duck_seconds := float(world.cfg["score"]["pitch_glide_seconds"]) if synth.ducking else float(synth.values["mixing"]["duck_release_seconds"])
		var duck_step := 1.0/(duck_seconds*rate)
		var duck := float(state.get("_score_duck",1.0))
		for i in range(block.size()):
			var frame := at+i
			var breath := 0.004*sin(TAU*130.81*float(frame)/rate) if empty_city else 0.0
			var stream := float(bed_table[frame%bed_table.size()])*bed_gain
			block[i] += Vector2.ONE*(breath+stream)
			duck = move_toward(duck,duck_target,duck_step)
			block[i] *= duck
			if transition_remaining > 0:
				if transition_remaining == transition_total: transition_offset = last_sample-block[i]
				var remaining := float(transition_remaining)/float(transition_total)
				block[i] += transition_offset*remaining*remaining*remaining
				transition_remaining -= 1
			last_sample = block[i]
		state["_score_duck"] = duck
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
		if entry.has("view"):
			presentation_copy = entry["view"]
		else:
			presentation_copy = World.new(world.rng.seed_hex,false)
			var derived: Dictionary = entry.get("derived",{})
			presentation_copy.restore(entry["before"],derived.is_empty())
			if not derived.is_empty():
				presentation_copy.fabric_cache = derived["fabric"].duplicate(true)
				presentation_copy.edge_cache = derived["edges"].duplicate(true)
				presentation_copy.public_service_cache = derived["service"].duplicate(true)
				presentation_copy.resonance = float(derived["resonance"])
			presentation_stats["reconstructed"] += 1
		presentation_copy_frame = int(entry["frame"])
	presentation_copy.pending = world.pending.duplicate(true)
	return presentation_copy

func audible_score() -> Dictionary:
	return synth.score_snapshot() if presentation_history.is_empty() else presentation_history[0].get("score",{}).duplicate(true)

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
	copy.synth.focused_community = synth.focused_community
	copy.synth.muted_communities = synth.muted_communities.duplicate(true)
	copy.synth.pad_groups = synth.pad_groups.duplicate(true)
	copy.synth.rhythm_nodes = synth.rhythm_nodes.duplicate(true)
	copy.synth.musical_nodes = synth.musical_nodes.duplicate(true)
	copy.synth.update_audio_city(copy.audio_city(),{}, {},[])
	copy.synth.configure_score(copy.world,copy.sound_overrides)
	copy.synth.restore_eras(synth.era_snapshot())
	return copy

const SAVED_SYNTH_FIELDS = ["pad_groups","population","rhythm_nodes","musical_nodes","theme","response","rhythms",
	"listener_community","focused_community","muted_communities","gray_enabled","gray_from","gray_change_at","ducking","duck_release_at","last_voice_count","max_voice_count","voice_group_stats"]

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
	# Strip runtime objects/caches before copying serializable history. The old
	# input snapshot remains immutable even when the display view gains flow.
	var history: Array[Dictionary] = []
	for entry in presentation_history:
		var saved_entry := entry.duplicate()
		saved_entry.erase("derived")
		saved_entry.erase("view")
		history.append(saved_entry.duplicate(true))
	var mix: Dictionary = {}
	for field in SAVED_SYNTH_FIELDS: mix[field] = synth.get(field)
	return {"world":world.snapshot(),"gain":synth.gain,"next_boundary":next_boundary,"rendered_until":rendered_until,
		"event_cursor":event_cursor,"sound_events":sound_events.duplicate(true),"sound_trace":sound_trace.duplicate(true),"sound_overrides":sound_overrides.duplicate(true),
		"decisions":decisions.duplicate(true),"presentation_history":history,
		"last_sample":last_sample,"transition_offset":transition_offset,"transition_remaining":transition_remaining,
		"transition_total":transition_total,"era_changes":synth.era_snapshot(),"mix":mix.duplicate(true)}

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
	for field in SAVED_SYNTH_FIELDS: copy.synth.set(field,saved["mix"].get(field,copy.synth.get(field)))
	copy.synth.restore_eras(saved.get("era_changes",{}))
	copy.synth.pad_groups = _hydrate_stereo(copy.synth.pad_groups)
	copy.synth.rhythm_nodes = _hydrate_stereo(copy.synth.rhythm_nodes)
	copy.synth.musical_nodes = _hydrate_stereo(copy.synth.musical_nodes)
	copy.synth.theme = _hydrate_stereo(copy.synth.theme)
	copy.synth.response = _hydrate_stereo(copy.synth.response)
	for index in range(copy.synth.rhythms.size()): copy.synth.rhythms[index] = _hydrate_stereo(copy.synth.rhythms[index])
	return copy

func forecast(operation: Dictionary, state: Dictionary, at: int, duration: int) -> PackedVector2Array:
	var preview_model := freeze()
	# Facility comparisons include the queued charter and other structural intent.
	if str(operation.get("kind","")) not in ["park","civic"]: preview_model.cancel_pending()
	preview_model.rendered_until = at
	var result := preview_model.submit(operation)
	if not result["accepted"]: return PackedVector2Array()
	var phases := state.duplicate(true)
	var boundary := int(result.get("sound_frame",preview_model.next_boundary))
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	for begin in range(at,boundary,512):
		preview_model.render_block(phases,begin,mini(512,boundary-begin),rate)
	return preview_model.render_block(phases,boundary,duration,rate)
