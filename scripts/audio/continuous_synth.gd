class_name ContinuousSynth
extends "res://scripts/audio/district_synth.gd"
## Community score: persistent pad phases, two pulse slots, one rotating authored theme.
const WorldConfig = preload("res://scripts/world/world_values.gd")
var score: Dictionary = WorldConfig.load_values()["score"]
var targets: Dictionary = {}
var listener_community := ""
var muted_communities: Dictionary = {}
var pad_groups: Dictionary = {}
var rhythms: Array[Dictionary] = []
var theme: Dictionary = {}
var response: Dictionary = {}
var current_world: ContinuousWorld
var pitch_overrides: Dictionary = {}
var population: Dictionary = {}
var last_voice_count := 0
var max_voice_count := 0

func _pan_for(district: Dictionary) -> float:
	var p: Array = district["position"]
	var config: Dictionary = WorldConfig.load_values()["space"]
	return clampf((float(p[0])-float(p[1]))/float(config["pan_divisor"]),-float(config["pan_limit"]),float(config["pan_limit"]))

func _rebuild_assist_neighbors(city: Array) -> void:
	assist_neighbors.clear()
	for district in city: assist_neighbors[district["district_id"]] = []

func update_city(city: Array, state: Dictionary, marks: Dictionary = {}, events: Array = []) -> void:
	super(city,state,marks,events.filter(func(event: Dictionary) -> bool: return event.has("district_id")))
	population.clear()
	for district in city:
		var cid: String = district["community_id"]
		population[cid] = int(population.get(cid,0))+1
	for group in pad_groups.values(): group["active"] = false
	for district in city:
		var id: String = district["district_id"]
		var midi := int(district["current_midi"])
		var cid: String = district["community_id"]
		var key := "%s:%s:%d" % [cid,district["type"],midi]
		if not pad_groups.has(key):
			pad_groups[key] = {"key":key,"cid":cid,"midi":midi,"type":district["type"],"phase":float(state.get("_phase_"+id,0.0)),
				"members":[],"pan_sum":0.0,"active":false,"level":0.0,"expression":district.get("expression","bright")}
		var group: Dictionary = pad_groups[key]
		if not group["active"]:
			group["members"] = []
			group["pan_sum"] = 0.0
		group["active"] = true
		group["members"].append(id)
		group["pan_sum"] += _pan_for(district)
		targets[id] = float(district["voice_level"])
	for group in pad_groups.values():
		if not group["active"]: continue
		var pan: float = float(group["pan_sum"])/group["members"].size()
		group["stereo"] = Vector2(cos((pan+1.0)*PI/4.0),sin((pan+1.0)*PI/4.0))
		group["target"] = float(score["pad_gain"])*sqrt(float(group["members"].size())/maxf(6.0,float(population[group["cid"]])))
	# Retiring nodes count during their two-beat fade.
	while pad_groups.size() > int(score["pad_group_limit"])*2:
		var quiet := ""
		var quiet_level := INF
		for key in pad_groups:
			var group: Dictionary = pad_groups[key]
			if not group["active"] and float(group["level"]) < quiet_level:
				quiet = key
				quiet_level = group["level"]
		if quiet.is_empty(): break
		pad_groups.erase(quiet)

func configure_score(world: ContinuousWorld, overrides: Dictionary = {}) -> void:
	current_world = world
	pitch_overrides = overrides.duplicate(true)
	var candidates: Array[String] = []
	for cid in world.communities:
		if world.communities[cid]["members"].size() >= 3: candidates.append(cid)
	candidates.sort()
	rhythms.clear()
	for cid in candidates:
		var chosen: Dictionary = {}
		for id in world.communities[cid]["members"]:
			var b: Dictionary = world.by_id[id]
			if b["type"] == "commercial" or (b["expression"] == "bright" and b["form"] != "胚"):
				chosen = b
				break
		if not chosen.is_empty():
			rhythms.append({"cid":cid,"midi":int(overrides.get(chosen["district_id"],chosen["current_midi"])),"stereo":_stereo_for(chosen),"expression":chosen["expression"]})
		if rhythms.size() >= int(score["rhythm_slot_limit"]): break
	theme.clear()
	response.clear()
	if candidates.is_empty() or (world.phrase_index+1)%int(score["theme_rest_phrases"]) == 0: return
	var selected := candidates[(world.phrase_index/int(score["theme_rotate_phrases"]))%candidates.size()]
	var notes := world.community_theme(selected,overrides)
	var first: Dictionary = world.by_id[world.communities[selected]["members"][0]]
	var has_park := world.public_sites.any(func(site: Dictionary) -> bool: return site["kind"] == "park" and site["active"] and site["community_id"] == selected)
	var has_civic := world.public_sites.any(func(site: Dictionary) -> bool: return site["kind"] == "civic" and site["active"] and site["community_id"] == selected)
	theme = {"cid":selected,"notes":notes,"expression":first["expression"],"park":has_park,"civic":has_civic,"stereo":_stereo_for(first)}
	if world.bridge:
		for cid in candidates:
			if world.communities[cid]["bank"] == world.communities[selected]["bank"]: continue
			var other_notes := world.community_theme(cid,overrides)
			if float(world.coupling.interval(int(notes[0]),int(other_notes[0]))["score"]) < 0.6: continue
			var other: Dictionary = world.by_id[world.communities[cid]["members"][0]]
			response = {"cid":cid,"notes":other_notes,"stereo":_stereo_for(other),"source":selected}
			break

func _audibility(cid: String) -> float:
	if muted_communities.get(cid,false): return 0.0
	if listener_community.is_empty() or cid == listener_community: return 1.0
	return float(score["background_gain"])

func _theme_sample(at: int, rate: int, answer: bool = false) -> Vector2:
	if theme.is_empty() or (answer and response.is_empty()): return Vector2.ZERO
	var beat := roundi(60.0*rate/120.0)
	var phrase := beat*32
	var elapsed := posmod(at-(beat*2 if answer else 0),phrase)
	var steps: Array = [0,8,16,24] if theme["expression"] == "deep" else [0,3,6,10,16,19,22,27]
	if theme["park"]: steps = steps.slice(0,steps.size()-2)
	var note_index := -1
	var onset := 0
	for i in range(steps.size()):
		if elapsed >= int(steps[i])*beat:
			note_index = i
			onset = int(steps[i])*beat
	if note_index < 0: return Vector2.ZERO
	var seconds := float(elapsed-onset)/rate
	var tail := 0.95 if theme["expression"] == "deep" else 0.65
	if seconds >= tail: return Vector2.ZERO
	var part: Dictionary = response if answer else theme
	var notes: Array = part["notes"]
	var pitch := int(notes[note_index%notes.size()])
	pitch += 24 if pitch < 48 else 12
	if note_index%4 == 3: pitch += 12
	var hz := frequency(pitch)
	var envelope := minf(1.0,seconds/0.012)*exp(-seconds/(0.35 if theme["expression"] == "deep" else 0.20))*clampf((tail-seconds)/0.03,0.0,1.0)
	var sample := (sin(TAU*hz*seconds)+0.18*sin(TAU*hz*seconds*2.0))/1.18
	var level := float(score["response_gain"] if answer else score["theme_gain"])
	if not answer and theme["civic"]: level *= 1.15
	var duck := duck_level if ducking else 1.0
	return sample*envelope*level*gain*_audibility(part["cid"])*part["stereo"]*duck

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	if current_world == null and pad_groups.is_empty():
		return super.render_block(state,start,count,rate)
	var output := PackedVector2Array()
	output.resize(count)
	if capture_drone:
		captured_drone.resize(count)
		captured_drone.fill(Vector2.ZERO)
	var fade_frames := float(score["control_fade_beats"])*60.0*rate/120.0
	var retired: Array = []
	var active_count := 0
	for key in pad_groups:
		var group: Dictionary = pad_groups[key]
		var target := float(group.get("target",0.0))*_audibility(group["cid"]) if group["active"] else 0.0
		var level := float(state.get("_pad_level_"+key,group["level"]))
		var phase := float(state.get("_pad_phase_"+key,group["phase"]))
		var hz := frequency(int(group["midi"]))
		var stereo: Vector2 = group.get("stereo",Vector2.ONE*sqrt(0.5))
		var table: PackedFloat32Array = tables[group["type"]]
		if level > 0.00001 or target > 0.0: active_count += 1
		# Linear amplitude ramps with continuous oscillator phase; no replayed PCM.
		var step := float(score["pad_gain"])/fade_frames
		for i in range(count):
			level = move_toward(level,target,step)
			var sample := _table_wave(table,phase)*level*gain*stereo
			output[i] += sample
			if capture_drone: captured_drone[i] += sample
			phase = fposmod(phase+hz/rate,1.0)
		state["_pad_level_"+key] = level
		state["_pad_phase_"+key] = phase
		group["level"] = level
		if group["active"]:
			for id in group["members"]: state["_phase_"+id] = phase
		elif level <= 0.00001: retired.append(key)
	for key in retired: pad_groups.erase(key)
	for rhythm in rhythms:
		var cid: String = rhythm["cid"]
		var level_key := "_pulse_level_"+cid
		var level := float(state.get(level_key,0.0))
		var target := _audibility(cid)
		var beat := roundi(rate*0.5)
		var spacing := beat*4 if rhythm["expression"] == "deep" else beat
		var hz := frequency(int(rhythm["midi"])+12)
		var phase_shift := 0 if cid.begins_with("west") else beat/2
		for i in range(count):
			level = move_toward(level,target,1.0/fade_frames)
			var elapsed := posmod(start+i-phase_shift,spacing)
			var seconds := float(elapsed)/rate
			if seconds >= 0.24: continue
			var envelope := minf(1.0,seconds/0.006)*exp(-seconds/0.075)*clampf((0.24-seconds)/0.01,0.0,1.0)
			output[i] += sin(TAU*hz*seconds)*envelope*float(score["rhythm_gain"])*level*gain*rhythm["stereo"]*(duck_level if ducking else 1.0)
		state[level_key] = level
	if duck_release_at >= 0 and start >= duck_release_at: ducking = false
	for i in range(count):
		output[i] += _theme_sample(start+i,rate)+_theme_sample(start+i,rate,true)
	last_voice_count = active_count+rhythms.size()+(0 if theme.is_empty() else 1)+(0 if response.is_empty() else 1)+1
	max_voice_count = maxi(max_voice_count,last_voice_count)
	assert(last_voice_count <= int(score["render_voice_limit"]))
	voice_group_stats = {"entities":districts.size(),"pad_nodes":active_count,"rhythm_nodes":rhythms.size(),"theme_nodes":0 if theme.is_empty() else 1,"response_nodes":0 if response.is_empty() else 1,"environment_nodes":1,"render_voices":last_voice_count,"max_render_voices":max_voice_count}
	return output

func score_snapshot() -> Dictionary:
	return {"theme":theme.duplicate(true),"response":response.duplicate(true),"rhythms":rhythms.duplicate(true),"pads":pad_groups.keys(),"voices":voice_group_stats.duplicate(true)}
