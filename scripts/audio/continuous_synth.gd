class_name ContinuousSynth
extends "res://scripts/audio/district_synth.gd"
## Community score: persistent pad phases, two pulse slots, one rotating authored theme.
const WorldConfig = preload("res://scripts/world/world_values.gd")
var score: Dictionary = WorldConfig.load_values()["score"]
var targets: Dictionary = {}
var listener_community := ""
var focused_community := ""
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const RiverResponse = preload("res://scripts/world/river_call_response.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
var muted_communities: Dictionary = {}
var response_enabled := true
var pad_groups: Dictionary = {}
var rhythms: Array[Dictionary] = []
var rhythm_nodes: Dictionary = {}
var musical_nodes: Dictionary = {}
static var theme_waves: Dictionary = {}
static var theme_wave_mutex := Mutex.new()
var theme: Dictionary = {}
var response: Dictionary = {}
var current_world: ContinuousWorld
var pitch_overrides: Dictionary = {}
var population: Dictionary = {}
var last_voice_count := 0
var max_voice_count := 0
# Derived selection cache; never part of score, phase or DNA state.
var pad_priority_input: Array[String] = []
var pad_priority_values: Dictionary = {}
var pad_priority_sorted: Array[String] = []
var pad_priority_sorts := 0
# The score/state stays in GDScript; selected wavetable voices share one native block.
var native_enabled := true
var native_mixer: RefCounted = ClassDB.instantiate("CityPadMixer") if ClassDB.class_exists("CityPadMixer") else null
# Opt-in render telemetry. These fields are absent from saved/frozen synth state.
var capture_music_activity := false
var captured_music_segments: Array[Dictionary] = []
var captured_public_segments: Array[Dictionary] = []

func begin_continuous_era_transition(frame: int,target_era: int,rate: int) -> void:
	var duration := maxi(1,roundi(4.0*60.0*float(rate)/120.0))
	for route in routing:
		if bool(route.get("landmark",false)): continue
		if route.has("era_change"): route["table"] = route["era_table"]
		route["era_change"] = {"frame":frame,"duration":duration,"era":target_era}
		route["era_table"] = EraVoice.table(str(route["type"]),target_era,int(values["synthesis"]["wavetable_size"]))
		route["tone"] = target_era

func _pan_for(district: Dictionary) -> float:
	var p: Array = district["position"]
	var config: Dictionary = WorldConfig.load_values()["space"]
	return clampf((float(p[0])-float(p[1]))/float(config["pan_divisor"]),-float(config["pan_limit"]),float(config["pan_limit"]))

func _response_stereo(world: ContinuousWorld, part: Dictionary, fallback: Vector2) -> Vector2:
	# A response is rendered from the receiving buildings' position.  RiverResponse
	# deliberately stays in the world layer, so attach the audio-only stereo route
	# here after the source/receiver relation has been selected.
	var receivers: Array = part.get("receiver_ids",[])
	for receiver_id in receivers:
		var id := str(receiver_id)
		if id.is_empty() or not world.by_id.has(id): continue
		return _stereo_for(world.by_id[id])
	return fallback

func _rebuild_assist_neighbors(city: Array) -> void:
	assist_neighbors.clear()
	for district in city: assist_neighbors[district["district_id"]] = []

func update_city(city: Array, state: Dictionary, marks: Dictionary = {}, events: Array = []) -> void:
	super(city,state,marks,events.filter(func(event: Dictionary) -> bool: return event.has("district_id")))
	_update_pad_groups(city,state)

# The model supplies a private projection; avoid copying that projection twice.
func update_audio_city(city: Array, state: Dictionary, marks: Dictionary = {}, events: Array = [], preparation: Dictionary = {}) -> void:
	_update_city_data(city,state,marks,events.filter(func(event: Dictionary) -> bool: return event.has("district_id")),preparation)
	if preparation.is_empty(): _update_pad_groups(city,state)
	else: _apply_prepared_pad_groups(preparation,state)

func _apply_prepared_pad_groups(preparation: Dictionary, state: Dictionary) -> void:
	population = preparation["population"].duplicate()
	targets.merge(preparation["targets"],true)
	for group in pad_groups.values(): group["active"] = false
	for key in preparation["groups"]:
		var ready: Dictionary = preparation["groups"][key]
		if not pad_groups.has(key):
			var first: String = ready["members"][0]
			pad_groups[key] = {"key":key,"cid":ready["cid"],"midi":ready["midi"],"type":ready["type"],
				"phase":float(state.get("_phase_"+first,0.0)),"level":0.0,"expression":ready["expression"]}
		var group: Dictionary = pad_groups[key]
		group["active"] = true
		group["members"] = ready["members"].duplicate()
		group["pan_sum"] = ready["pan_sum"]
		group["stereo"] = ready["stereo"]
		group["target"] = ready["target"]
	_retire_quiet_pad_groups()

func _update_pad_groups(city: Array, state: Dictionary) -> void:
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
		group["target"] = float(score["pad_gain"])*sqrt(float(group["members"].size())/maxf(6.0,float(population[group["cid"]])))*sqrt(float(score.get("pad_reference_communities",3.0))/maxf(float(score.get("pad_reference_communities",3.0)),population.size()))
	_retire_quiet_pad_groups()

func _retire_quiet_pad_groups() -> void:
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

func configure_score(world: ContinuousWorld, overrides: Dictionary = {}, at: int = -1) -> void:
	if at < 0: at = world.phrase_index*int(world.cfg["timing"]["phrase_frames"])
	current_world = world
	pitch_overrides = overrides.duplicate(true)
	var candidates: Array[String] = []
	for cid in world.communities:
		var members: Array = world.communities[cid]["members"]
		var has_facility := world.public_sites.any(func(site: Dictionary) -> bool:
			return bool(site.get("active",false)) and str(site.get("community_id","")) == cid and str(site.get("kind","")) in ["park","civic"])
		# A public site gives a small community a musical doorway before it has three houses.
		if members.size() >= 3 or (has_facility and not members.is_empty()): candidates.append(cid)
	# Resolve each priority once instead of scanning centers inside every comparison.
	var priorities: Dictionary = {}
	# center_rank/order use the first matching center, including inactive records.
	# Build that same lookup once; repeated community scans dominate large scores.
	for index in range(world.centers.size()):
		var center: Dictionary = world.centers[index]
		var cid := str(center["community_id"])
		if not priorities.has(cid):
			priorities[cid] = [{"primary":0,"secondary":1,"terrace":2}.get(str(center["level"]),3),index]
	for cid in candidates:
		if not priorities.has(cid): priorities[cid] = [3,999]
	var authored_roots: Dictionary = {}
	for cid in candidates: authored_roots[cid] = _player_expression_root(world,cid)
	candidates.sort_custom(func(a: String,b: String) -> bool:
		# A newly authored family gets the existing rhythm doorway immediately.
		# It must not lose its weave to an older default commercial building.
		var ap: bool = not authored_roots[a].is_empty()
		var bp: bool = not authored_roots[b].is_empty()
		if ap != bp: return ap
		if ap and bp:
			var af := int(authored_roots[a].get("birth_frame",0))
			var bf := int(authored_roots[b].get("birth_frame",0))
			if af != bf: return af > bf
		var ar: int = priorities[a][0]
		var br: int = priorities[b][0]
		if ar != br: return ar < br
		var ao: int = priorities[a][1]
		var bo: int = priorities[b][1]
		if ao != bo: return ao < bo
		return a < b)
	rhythms.clear()
	for cid in candidates:
		var chosen: Dictionary = authored_roots[cid]
		var player_authored := not chosen.is_empty()
		if chosen.is_empty():
			for id in world.communities[cid]["members"]:
				var b: Dictionary = world.by_id[id]
				if b["type"] == "commercial" or (b["expression"] == "bright" and b["form"] != "胚"):
					chosen = b
					break
		var facility_rhythm := false
		if chosen.is_empty() and not world.communities[cid]["members"].is_empty():
			for site in world.public_sites:
				if bool(site.get("active",false)) and str(site.get("community_id","")) == cid and str(site.get("kind","")) in ["park","civic"]:
					chosen = world.by_id[world.communities[cid]["members"][0]]
					facility_rhythm = true
					break
		if not chosen.is_empty():
			var service_pressure := float(world.community_public_service(cid).get("pressure",0.0))
			rhythms.append({"cid":cid,"midi":int(overrides.get(chosen["district_id"],chosen["current_midi"])),"stereo":_stereo_for(chosen),"expression":chosen["expression"],"player_expression":player_authored,"source_id":str(chosen["district_id"]),"facility":facility_rhythm,"zone_roles":world.functional_zone_roles(cid),"service_pressure":service_pressure})
		if rhythms.size() >= int(score["rhythm_slot_limit"]): break
	# Keep one public place audible even when the two ordinary rhythm slots are full.
	# This makes a park or civic room a compositional invitation, not only a visual tag.
	var facility_rhythm_present := rhythms.any(func(part: Dictionary) -> bool: return bool(part.get("facility",false)))
	if not facility_rhythm_present:
		for cid in candidates:
			var has_facility := world.public_sites.any(func(site: Dictionary) -> bool:
				return bool(site.get("active",false)) and str(site.get("community_id","")) == cid and str(site.get("kind","")) in ["park","civic"])
			if not has_facility or world.communities[cid]["members"].is_empty(): continue
			var already_present := rhythms.any(func(part: Dictionary) -> bool: return str(part.get("cid","")) == cid)
			if already_present: continue
			var facility_building: Dictionary = world.by_id[world.communities[cid]["members"][0]]
			if rhythms.size() >= int(score["rhythm_slot_limit"]): rhythms.pop_back()
			var service_pressure := float(world.community_public_service(cid).get("pressure",0.0))
			rhythms.append({"cid":cid,"midi":int(overrides.get(facility_building["district_id"],facility_building["current_midi"])),"stereo":_stereo_for(facility_building),"expression":facility_building["expression"],"facility":true,"zone_roles":world.functional_zone_roles(cid),"service_pressure":service_pressure})
			break
	_sync_rhythm_nodes()
	theme.clear()
	response.clear()
	var theme_candidates: Array[String] = []
	for cid in candidates:
		if bool(MusicRules.status(world,cid)["theme_eligible"]): theme_candidates.append(cid)
	if theme_candidates.is_empty() or (world.phrase_index+1)%int(score["theme_rest_phrases"]) == 0:
		_sync_musical_nodes(at)
		return
	var selected := theme_candidates[(world.phrase_index/int(score["theme_rotate_phrases"]))%theme_candidates.size()]
	if theme_candidates.has(focused_community): selected = focused_community
	if theme_candidates.has(listener_community): selected = listener_community
	var notes := world.community_theme(selected,overrides)
	var first: Dictionary = world.by_id[world.communities[selected]["members"][0]]
	var author := _player_expression_root(world,selected)
	var facility := MusicRules.facilities(world,selected)
	var has_park := bool(facility["park"])
	var has_civic := bool(facility["civic"])
	theme = {"cid":selected,"notes":notes,"expression":world.community_expression(selected),"player_expression":not author.is_empty(),"park":has_park,"civic":has_civic,"center":current_world.center_for(selected).duplicate(true),"zone_roles":world.functional_zone_roles(selected),"stereo":_stereo_for(first)}
	theme["source_ids"] = world.community_theme_sources(selected)
	if not author.is_empty():
		# Keep every actual resident note, opening this authored motif with the
		# real root rather than waiting for its late geometric position.
		var author_index: int = theme["source_ids"].find(str(author["district_id"]))
		if author_index > 0:
			theme["source_ids"].push_front(theme["source_ids"].pop_at(author_index))
			theme["notes"].push_front(theme["notes"].pop_at(author_index))
	# The river supplies a spatial opportunity; the player still authors the
	# pitches and placement. One response is derived from the lead schedule.
	if response_enabled:
		response = RiverResponse.reply(world,theme,RiverResponse.pairs(world,pitch_overrides),pitch_overrides)
		if not response.is_empty():
			response["stereo"] = _response_stereo(world,response,theme.get("stereo",Vector2.ONE/sqrt(2.0)))
	_sync_musical_nodes(at)

func _player_expression_root(world: ContinuousWorld,cid: String) -> Dictionary:
	var chosen: Dictionary = {}
	var newest := -1
	for id in world.communities[cid]["members"]:
		var building: Dictionary = world.by_id[id]
		var family: Dictionary = world.families.get(str(building.get("family_id","")),{})
		if not bool(family.get("player_expression",false)) or str(family.get("root","")) != str(id): continue
		var created := int(building.get("birth_frame",0))
		if created > newest or (created == newest and str(id) > str(chosen.get("district_id",""))):
			chosen = building
			newest = created
	return chosen

func rhythm_profile(part: Dictionary,rate: int) -> Dictionary:
	var beat := roundi(rate*0.5)
	if bool(part.get("player_expression",false)):
		var voice := PlayerExpression.definition(str(part["expression"]))
		return {"spacing_frames":float(voice["rhythm_beats"])*beat,"pitch":int(part["midi"])+int(voice["rhythm_offset"]),
			"tail":float(voice["rhythm_tail"]),"attack":float(voice["rhythm_attack"]),"decay":float(voice["rhythm_decay"])}
	var spacing: int = beat*4 if part["expression"] == "deep" else beat
	if float(part.get("service_pressure",0.0)) >= 0.5: spacing = beat*2 if part["expression"] == "deep" else beat/2
	return {"spacing_frames":spacing,"pitch":int(part["midi"])+12,"tail":0.24,"attack":0.006,"decay":0.075}

func rhythm_events(part: Dictionary,start: int,count: int,rate: int) -> Array[Dictionary]:
	var profile := rhythm_profile(part,rate)
	var spacing := float(profile["spacing_frames"])
	var shift := 0 if str(part["cid"]).begins_with("west") else roundi(rate*0.5)/2
	var duration := ceili(float(profile["tail"])*rate)
	var events: Array[Dictionary] = []
	for cycle in range(floori(float(start-shift-duration)/spacing)+1,ceili(float(start+count-shift)/spacing)):
		var onset := roundi(cycle*spacing)+shift
		if onset >= start+count or onset+duration <= start: continue
		events.append({"onset":onset,"pitch":profile["pitch"],"duration_frames":duration,"source_id":str(part.get("source_id",""))})
	return events

func _audibility(cid: String) -> float:
	if muted_communities.get(cid,false): return 0.0
	if listener_community.is_empty() or cid == listener_community: return 1.0
	return float(score["background_gain"])

func _sync_rhythm_nodes() -> void:
	for node in rhythm_nodes.values(): node["active"] = false
	for part in rhythms:
		var key := "%s:%d:%s:%s:%s" % [part["cid"],part["midi"],part["expression"],JSON.stringify(part.get("zone_roles",[])),float(part.get("service_pressure",0.0)) >= 0.5]
		if bool(part.get("player_expression",false)): key += ":player"
		if not rhythm_nodes.has(key):
			rhythm_nodes[key] = part.duplicate(true)
			rhythm_nodes[key]["key"] = key
		else:
			# The facility flag and runtime presentation metadata can change while the
			# rhythmic lifecycle remains continuous; refresh the current definition.
			rhythm_nodes[key].merge(part.duplicate(true),true)
		rhythm_nodes[key]["active"] = true

func _sync_musical_nodes(at: int) -> void:
	var previous: Array[Dictionary] = []
	for node in musical_nodes.values():
		if bool(node["active"]):
			previous.append(node)
			node["retired_at"] = at
		node["active"] = false
	if theme.is_empty(): return
	var lead := _register_musical_node(theme,theme,false,at,previous)
	if not response.is_empty(): _register_musical_node(response,theme,true,at,previous,int(lead.get("source_origin",lead["born_at"])))

func _musical_signature(part: Dictionary, pattern: Dictionary, answer: bool,source_origin: int = -1) -> String:
	# Replies must carry the exact source pitch as well as the receiving pitch.
	var identity := [part["cid"],part["notes"],part.get("source_ids",[]),part.get("receiver_ids",[]),
		part["stereo"],pattern["cid"],pattern["notes"],pattern.get("source_ids",[]),
		pattern["expression"],pattern["park"],pattern["civic"],pattern.get("zone_roles",[]),bool(pattern.get("player_expression",false)),answer]
	if answer and bool(pattern.get("player_expression",false)): identity.append(source_origin)
	return JSON.stringify(identity)

func _register_musical_node(part: Dictionary, pattern: Dictionary, answer: bool, at: int, previous: Array[Dictionary] = [],source_origin: int = -1) -> Dictionary:
	var signature := _musical_signature(part,pattern,answer,source_origin)
	var key := ""
	var predecessor := ""
	for old in previous:
		if bool(old["answer"]) != answer: continue
		if _musical_signature(old["part"],old["pattern"],answer,int(old.get("source_origin",-1))) == signature:
			key = str(old["key"])
			# Keep the audible lifecycle and phase, while refreshing runtime-only
			# presentation metadata such as the current public-site identity.
			musical_nodes[key]["part"] = part.duplicate(true)
			musical_nodes[key]["pattern"] = pattern.duplicate(true)
			break
		if str(old["part"]["cid"]) == str(part["cid"]) and str(old["pattern"]["cid"]) == str(pattern["cid"]) \
			and str(old["pattern"]["expression"]) == str(pattern["expression"]):
			predecessor = str(old["key"])
	if key.is_empty():
		# A retired incarnation still owns its old tails and delayed replies.
		# Returning to its notes starts a distinct lifetime, never overwrites it.
		key = signature
		var incarnation := 0
		while musical_nodes.has(key):
			incarnation += 1
			key = signature+"@%d:%d" % [at,incarnation]
		musical_nodes[key] = {"key":key,"part":part.duplicate(true),"pattern":pattern.duplicate(true),"answer":answer,"born_at":at}
		if bool(pattern.get("player_expression",false)): musical_nodes[key]["source_origin"] = source_origin if answer else at
		if not predecessor.is_empty(): musical_nodes[key]["handoff_from"] = predecessor
	musical_nodes[key].erase("retired_at")
	musical_nodes[key]["active"] = true
	# Warm immutable event waves before the output clock starts.
	for note in part["notes"]:
		if int(note) < 0: continue
		var pitch := _theme_pitch(int(note),0,pattern)
		_event_wave(pitch,str(pattern["expression"]),int(values["timing"]["sample_rate"]),bool(pattern.get("player_expression",false)))
		_event_wave(pitch+12,str(pattern["expression"]),int(values["timing"]["sample_rate"]),bool(pattern.get("player_expression",false)))
	return musical_nodes[key]

func warm_score() -> void:
	var rate := int(values["timing"]["sample_rate"])
	for expression in ["bright","deep"]:
		for pitch in [60,62,64,67,69,72,74,76,79,81]: _event_wave(pitch,expression,rate)

func _event_wave(pitch: int, expression: String, rate: int,player_authored: bool = false) -> PackedFloat32Array:
	var key := "%d:%s:%d:%s" % [pitch,expression,rate,player_authored]
	# The preview worker and live renderer share immutable wave tables. Protect
	# dictionary access, but compute a missing table outside the audio lock.
	theme_wave_mutex.lock()
	var cached: PackedFloat32Array = theme_waves.get(key,PackedFloat32Array())
	theme_wave_mutex.unlock()
	if not cached.is_empty(): return cached
	var tail := 0.95 if expression == "deep" else 0.65
	var attack := 0.012
	var decay := 0.35 if expression == "deep" else 0.20
	if player_authored:
		var voice := PlayerExpression.definition(expression)
		tail = float(voice["theme_tail"])
		attack = float(voice["theme_attack"])
		decay = float(voice["theme_decay"])
	var wave := PackedFloat32Array()
	wave.resize(ceili(tail*rate))
	var hz := frequency(pitch)
	for at in range(wave.size()):
		var seconds := float(at)/rate
		var envelope := minf(1.0,seconds/attack)*exp(-seconds/decay)*clampf((tail-seconds)/0.03,0.0,1.0)
		# A long warm chord occupies the same Lead slot and shares its envelope.
		var tone := (sin(TAU*hz*seconds)+0.18*sin(TAU*hz*seconds*2.0))/1.18
		if player_authored and expression == "warm": tone = (sin(TAU*hz*seconds)+0.32*sin(TAU*hz*pow(2.0,7.0/12.0)*seconds))/1.32
		wave[at] = tone*envelope
	theme_wave_mutex.lock()
	theme_waves[key] = wave
	theme_wave_mutex.unlock()
	return wave

func musical_steps(pattern: Dictionary) -> Array:
	if bool(pattern.get("player_expression",false)):
		var steps: Array = PlayerExpression.definition(str(pattern["expression"]))["theme_steps"].duplicate()
		if bool(pattern["park"]): steps = steps.slice(0,maxi(2,steps.size()-1))
		return steps
	var steps: Array = [0,8,16,24] if pattern["expression"] == "deep" else [0,3,6,10,16,19,22,27]
	var zone_roles: Array = pattern.get("zone_roles",[])
	if zone_roles.has("workshop"): steps = [0,6,12,18,24,30] if pattern["expression"] != "deep" else [0,8,16,24]
	elif zone_roles.has("choir"): steps = [0,8,16,24] if pattern["expression"] == "deep" else [0,4,12,20,28]
	elif zone_roles.has("market") and pattern["expression"] != "deep": steps = [0,2,5,9,16,18,22,27]
	elif zone_roles.has("garden"): steps = steps.slice(0,maxi(2,steps.size()-2))
	elif zone_roles.has("pulse_dense"): steps = [0,2,4,8,10,12,16,18,20,24,26,28]
	elif zone_roles.has("pulse"): steps = [0,4,8,12,16,20,24,28]
	if pattern["park"]: steps = steps.slice(0,maxi(2,steps.size()-2))
	return steps

func _theme_pitch(pitch: int,index: int,pattern: Dictionary) -> int:
	if bool(pattern.get("player_expression",false)):
		return posmod(pitch,12)+int(PlayerExpression.definition(str(pattern["expression"]))["theme_octave"])
	pitch += 24 if pitch < 48 else 12
	if index%4 == 3: pitch += 12
	return pitch

func musical_events(node: Dictionary, start: int, count: int, rate: int) -> Array[Dictionary]:
	# The only producers are original Lead events. Replies are derived once
	# from that schedule, never from another response or from a render block.
	var result: Array[Dictionary] = []
	var pattern: Dictionary = node["pattern"]
	var part: Dictionary = node["part"]
	var beat := roundi(rate*0.5)
	var period := beat*32
	var delay := beat*2 if node["answer"] else 0
	var steps := musical_steps(pattern)
	var first_cycle := floori(float(start-delay)/period)-1
	var last_cycle := floori(float(start+count-delay)/period)
	var notes: Array = part["notes"]
	var first_slot := 0
	if bool(pattern.get("player_expression",false)):
		var origin := int(node.get("source_origin",node.get("born_at",0)))
		var origin_cycle := floori(float(origin)/period)
		first_slot = (origin_cycle+1)*steps.size()
		for slot in range(steps.size()):
			if origin_cycle*period+int(steps[slot])*beat >= origin:
				first_slot = origin_cycle*steps.size()+slot
				break
	for cycle in range(first_cycle,last_cycle+1):
		for index in range(steps.size()):
			var source_onset := cycle*period+int(steps[index])*beat
			if source_onset < int(node.get("born_at",0)) or source_onset >= int(node.get("retired_at",9223372036854775807)): continue
			var note_index := posmod(cycle*steps.size()+index-first_slot,notes.size())
			var pitch := int(notes[note_index])
			if pitch < 0: continue
			var source_ids: Array = pattern.get("source_ids",[])
			var source_id := str(source_ids[note_index]) if note_index < source_ids.size() else ""
			var source_pitch := int(pattern["notes"][note_index])
			var source_event := "%s:%d:%d:%s:%d" % [pattern["cid"],source_onset,index,source_id,source_pitch]
			var receiver_ids: Array = part.get("receiver_ids",[])
			var receiver_id := str(receiver_ids[note_index]) if note_index < receiver_ids.size() else ""
			pitch = _theme_pitch(pitch,index,pattern)
			var onset := source_onset+delay
			var tail := ceili((0.95 if pattern["expression"] == "deep" else 0.65)*rate)
			if bool(pattern.get("player_expression",false)): tail = ceili(float(PlayerExpression.definition(str(pattern["expression"]))["theme_tail"])*rate)
			if onset >= start+count or onset+tail <= start: continue
			result.append({"event_id":("reply:"+source_event+":"+receiver_id) if node["answer"] else source_event,
				"source_event_id":source_event,"source_id":source_id,"receiver_id":receiver_id,
				"generation":1 if node["answer"] else 0,"source_onset":source_onset,"onset":onset,"pitch":pitch,"duration_frames":tail})
	return result

func _musical_block(node: Dictionary, start: int, count: int, rate: int, contribution: Dictionary = {}) -> PackedFloat32Array:
	var output := PackedFloat32Array()
	output.resize(count)
	for event in musical_events(node,start,count,rate):
		var onset := int(event["onset"])
		var wave := _event_wave(int(event["pitch"]),node["pattern"]["expression"],rate,bool(node["pattern"].get("player_expression",false)))
		var begin := maxi(start,onset)
		var finish := mini(start+count,onset+wave.size())
		if not contribution.is_empty() and finish > begin:
			var segment := event.duplicate()
			segment.merge(contribution)
			segment["end_frame"] = onset+wave.size()
			segment["render_start"] = begin
			segment["render_end"] = finish
			segment["expression"] = str(node["pattern"]["expression"])
			segment["envelope_tail"] = 0.95 if segment["expression"] == "deep" else 0.65
			segment["envelope_attack"] = 0.012
			segment["envelope_decay"] = 0.35 if segment["expression"] == "deep" else 0.20
			if bool(node["pattern"].get("player_expression",false)):
				var voice := PlayerExpression.definition(segment["expression"])
				segment["envelope_tail"] = voice["theme_tail"]
				segment["envelope_attack"] = voice["theme_attack"]
				segment["envelope_decay"] = voice["theme_decay"]
			segment["node_key"] = str(node["key"])
			segment["cid"] = str(node["part"]["cid"])
			# Public-space identity is an ephemeral projection of the current world
			# at render time.  It intentionally never enters theme/musical-node save
			# data, while the activity row still points at the real site that shaped
			# this audible theme.
			var public_site_ids: Array[String] = []
			var public_site_kinds: Array[String] = []
			var public_cid := str(node["pattern"].get("cid",node["part"]["cid"]))
			if current_world != null:
				for site in current_world.public_sites:
					if not bool(site.get("active",false)): continue
					var public_kind := str(site.get("kind",""))
					if public_kind not in ["park","civic"]: continue
					var belongs := str(site.get("community_id","")) == public_cid
					var serves: bool = public_kind == "civic" and site.get("served",[]).any(func(id: Variant) -> bool:
						return current_world.by_id.has(str(id)) and str(current_world.by_id[str(id)].get("community_id","")) == public_cid)
					if not belongs and not serves: continue
					public_site_ids.append(str(site.get("id","")))
					public_site_kinds.append(public_kind)
			segment["public_site_ids"] = public_site_ids
			segment["public_site_kinds"] = public_site_kinds
			segment["rate"] = rate
			captured_music_segments.append(segment)
		for at in range(begin,finish): output[at-start] += wave[at-onset]
	return output

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	if capture_music_activity: captured_music_segments.clear()
	if capture_music_activity: captured_public_segments.clear()
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
	var native_keys: Array[String] = []
	var native_tables: Array = []
	var native_controls := PackedFloat64Array()
	# Reserve slots for the environment and musical overlays before rendering pads.
	# Large cities can have more valid community/type/pitch groups than the 70-voice
	# budget; rotate the stable group set instead of asserting or producing a spike.
	var pad_budget := maxi(0,int(score["render_voice_limit"])-1-rhythm_nodes.size()-musical_nodes.size())
	var pad_candidates: Array[String] = []
	# Evaluate each priority once per block; sorting must not repeatedly rebuild
	# state keys and resolve group dictionaries. Preserve the comparator and order.
	var priorities: Dictionary = {}
	for key in pad_groups:
		var group: Dictionary = pad_groups[key]
		var level := float(state.get("_pad_level_"+key,group["level"]))
		var active := bool(group["active"])
		priorities[key] = [active,level]
		if active or level > 0.00001: pad_candidates.append(str(key))
	if pad_candidates == pad_priority_input and priorities == pad_priority_values:
		pad_candidates = pad_priority_sorted
	else:
		pad_priority_input = pad_candidates.duplicate()
		pad_priority_values = priorities
		pad_candidates.sort_custom(func(a: String,b: String) -> bool:
			var pa: Array = priorities[a]
			var pb: Array = priorities[b]
			if pa[0] != pb[0]: return pa[0]
			var la: float = pa[1]
			var lb: float = pb[1]
			if not is_equal_approx(la,lb): return la > lb
			return a < b)
		pad_priority_sorted = pad_candidates.duplicate()
		pad_priority_sorts += 1
	var render_keys: Dictionary = {}
	for index in range(mini(pad_budget,pad_candidates.size())): render_keys[pad_candidates[index]] = true
	for key in pad_groups:
		var group: Dictionary = pad_groups[key]
		var target := float(group.get("target",0.0))*_audibility(group["cid"]) if group["active"] else 0.0
		var level: float = priorities[key][1]
		var phase := float(state.get("_pad_phase_"+key,group["phase"]))
		var hz := frequency(int(group["midi"]))
		var target_stereo: Vector2 = group.get("stereo",Vector2.ONE*sqrt(0.5))
		var stereo: Vector2 = state.get("_pad_stereo_"+key,target_stereo)
		var table: PackedFloat32Array = tables[group["type"]]
		var selected := render_keys.has(key)
		if selected and (level > 0.00001 or target > 0.0): active_count += 1
		# Linear amplitude ramps with continuous oscillator phase; no replayed PCM.
		var step := float(score["pad_gain"])/fade_frames
		if selected and native_enabled and native_mixer != null:
			native_keys.append(key)
			native_tables.append(table)
			native_controls.append_array(PackedFloat64Array([phase,level,target,hz/rate,stereo.x,stereo.y,target_stereo.x,target_stereo.y,step,1.0/(float(score["pitch_glide_seconds"])*rate),gain]))
			continue
		if not selected:
			# Virtual groups retain oscillator time without a per-sample render loop.
			level = move_toward(level,0.0,step*count)
			phase = fposmod(phase+hz*count/rate,1.0)
		else:
			var stereo_step := 1.0/(float(score["pitch_glide_seconds"])*rate)
			var phase_step := hz/rate
			var table_size := table.size()
			var stationary := level == target and stereo == stereo.lerp(target_stereo,stereo_step)
			if stationary:
				var amplitude := level*gain*stereo
				for i in range(count):
					var position := phase*table_size
					var index := int(position)
					var sample := lerpf(table[index],table[(index+1)%table_size],position-index)*amplitude
					output[i] += sample
					if capture_drone: captured_drone[i] += sample
					phase = fposmod(phase+phase_step,1.0)
			else:
				for i in range(count):
					level = move_toward(level,target,step)
					stereo = stereo.lerp(target_stereo,stereo_step)
					var position := phase*table_size
					var index := int(position)
					var sample := lerpf(table[index],table[(index+1)%table_size],position-index)*level*gain*stereo
					output[i] += sample
					if capture_drone: captured_drone[i] += sample
					phase = fposmod(phase+phase_step,1.0)
		state["_pad_stereo_"+key] = stereo
		state["_pad_level_"+key] = level
		state["_pad_phase_"+key] = phase
		group["level"] = level
		if group["active"]:
			for id in group["members"]: state["_phase_"+id] = phase
		elif level <= 0.00001: retired.append(key)
	if not native_keys.is_empty():
		var mixed: Array = native_mixer.call("render_pads",output,native_tables,native_controls)
		output = mixed[0]
		native_controls = mixed[1]
		if capture_drone: captured_drone = output.duplicate()
		for voice in range(native_keys.size()):
			var key: String = native_keys[voice]
			var group: Dictionary = pad_groups[key]
			var phase := native_controls[voice*11]
			var level := native_controls[voice*11+1]
			state["_pad_phase_"+key] = phase
			state["_pad_level_"+key] = level
			state["_pad_stereo_"+key] = Vector2(native_controls[voice*11+4],native_controls[voice*11+5])
			group["level"] = level
			if group["active"]:
				for id in group["members"]: state["_phase_"+id] = phase
			elif level <= 0.00001: retired.append(key)
	for key in retired: pad_groups.erase(key)
	var retiring_rhythms: Array = []
	var pulse_count := 0
	for rhythm in rhythm_nodes.values():
		var cid: String = rhythm["cid"]
		var level_key := "_pulse_level_"+str(rhythm["key"])
		var level := float(state.get(level_key,0.0))
		var target := _audibility(cid) if rhythm["active"] else 0.0
		if level > 0.00001 or target > 0.0: pulse_count += 1
		var beat := roundi(rate*0.5)
		var profile := rhythm_profile(rhythm,rate)
		var spacing := float(profile["spacing_frames"])
		var whole_spacing := roundi(spacing)
		var fractional := not is_equal_approx(spacing,float(whole_spacing))
		var hz := frequency(int(profile["pitch"]))
		var phase_shift := 0 if cid.begins_with("west") else beat/2
		var rhythm_stereo: Vector2 = rhythm["stereo"]
		var captured_pulses: Dictionary = {}
		var pulse_frames := roundi(float(profile["tail"])*rate)
		for i in range(count):
			var elapsed := posmod(start+i-phase_shift,whole_spacing)
			if fractional:
				# Half-beats at 22050 Hz alternate 5512/5513 frames. Rounding each
				# absolute onset preserves bar alignment instead of drifting forever.
				var cycle := floori(float(start+i-phase_shift)/spacing)
				elapsed = start+i-phase_shift-roundi(cycle*spacing)
			if capture_music_activity and bool(rhythm.get("facility",false)) and elapsed < pulse_frames:
				var pulse_onset := start+i-elapsed
				var pulse_id := "public:%s:%d" % [str(rhythm["key"]),pulse_onset]
				if not captured_pulses.has(pulse_id):
					captured_pulses[pulse_id] = true
					var public_site_ids: Array[String] = []
					var public_site_kinds: Array[String] = []
					if current_world != null:
						for site in current_world.public_sites:
							if not bool(site.get("active",false)) or str(site.get("community_id","")) != cid: continue
							var public_kind := str(site.get("kind",""))
							if public_kind not in ["park","civic"]: continue
							public_site_ids.append(str(site.get("id","")))
							public_site_kinds.append(public_kind)
					if not public_site_ids.is_empty():
						captured_public_segments.append({"event_id":pulse_id,"onset":pulse_onset,
							"render_start":start+i,"render_end":start+count,"level_frame":start+i,
							"level_from":level,"target":target,"fade_step":1.0/fade_frames,
							"amplitude":float(score["rhythm_gain"])*gain,"stereo_gain":rhythm_stereo.length(),
							"midi":int(profile["pitch"]),"rate":rate,"expression":str(rhythm["expression"]),"public_site_ids":public_site_ids,
							"public_site_kinds":public_site_kinds,"rhythm":true})
			level = move_toward(level,target,1.0/fade_frames)
			var seconds := float(elapsed)/rate
			if seconds >= float(profile["tail"]): continue
			var envelope := minf(1.0,seconds/float(profile["attack"]))*exp(-seconds/float(profile["decay"]))*clampf((float(profile["tail"])-seconds)/0.01,0.0,1.0)
			output[i] += sin(TAU*hz*seconds)*envelope*float(score["rhythm_gain"])*level*gain*rhythm["stereo"]
		state[level_key] = level
		if not rhythm["active"] and level < 0.00001: retiring_rhythms.append(rhythm["key"])
	for key in retiring_rhythms: rhythm_nodes.erase(key)
	if duck_release_at >= 0 and start >= duck_release_at: ducking = false
	var theme_count := 0
	var response_count := 0
	var retiring_musical: Array = []
	# Resolve every handoff from the block-start state before any old node writes
	# its block-end fade. This keeps the transition independent of chunk size.
	var handoffs: Dictionary = {}
	for node in musical_nodes.values():
		if node.has("handoff_from"):
			handoffs[node["key"]] = float(state.get("_theme_level_"+str(node["handoff_from"]),0.0))
			node.erase("handoff_from")
	for key in handoffs: state["_theme_level_"+str(key)] = handoffs[key]
	for node in musical_nodes.values():
		var part: Dictionary = node["part"]
		var pattern: Dictionary = node["pattern"]
		var key: String = node["key"]
		var level := float(state.get("_theme_level_"+key,0.0))
		var pending_answer := bool(node["answer"]) and start < int(node.get("retired_at",-1))+roundi(rate*1.0)
		var target := _audibility(part["cid"]) if node["active"] or pending_answer else 0.0
		if bool(node["answer"]): target = minf(target,_audibility(str(part.get("source",""))))
		if level > 0.00001 or target > 0.0:
			if node["answer"]: response_count += 1
			else: theme_count += 1
		var amplitude := float(score["response_gain"] if node["answer"] else score["theme_gain"])*gain
		if not node["answer"] and pattern["civic"]: amplitude *= 1.15
		var stereo: Vector2 = part["stereo"]
		var contribution: Dictionary = {}
		if capture_music_activity:
			contribution = {"level_frame":start,"level_from":level,"target":target,"fade_step":1.0/fade_frames,
				"amplitude":absf(amplitude),"stereo_gain":stereo.length()}
		var wave := _musical_block(node,start,count,rate,contribution)
		for i in range(count):
			level = move_toward(level,target,1.0/fade_frames)
			output[i] += wave[i]*level*amplitude*stereo
		state["_theme_level_"+key] = level
		if not node["active"] and level < 0.00001: retiring_musical.append(key)
	for key in retiring_musical:
		musical_nodes.erase(key)
		state.erase("_theme_level_"+str(key))
	last_voice_count = active_count+pulse_count+theme_count+response_count+1
	max_voice_count = maxi(max_voice_count,last_voice_count)
	assert(last_voice_count <= int(score["render_voice_limit"]))
	voice_group_stats = {"entities":districts.size(),"pad_nodes":active_count,"rhythm_nodes":pulse_count,"theme_nodes":theme_count,"response_nodes":response_count,"environment_nodes":1,"render_voices":last_voice_count,"max_render_voices":max_voice_count,"voice_budget":int(score["render_voice_limit"]),"budget_shed":maxi(0,pad_candidates.size()-mini(pad_budget,pad_candidates.size()))}
	return output

func score_snapshot() -> Dictionary:
	return {"theme":theme.duplicate(true),"response":response.duplicate(true),"response_enabled":response_enabled,"rhythms":rhythms.duplicate(true),"pads":pad_groups.keys(),"voices":voice_group_stats.duplicate(true),
		"focused_community":focused_community,"listener_community":listener_community,"muted_communities":muted_communities.duplicate(true)}
