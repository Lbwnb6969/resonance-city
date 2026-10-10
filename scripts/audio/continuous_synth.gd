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
var rhythm_nodes: Dictionary = {}
var musical_nodes: Dictionary = {}
static var theme_waves: Dictionary = {}
var theme: Dictionary = {}
var response: Dictionary = {}
var current_world: ContinuousWorld
var pitch_overrides: Dictionary = {}
var population: Dictionary = {}
var last_voice_count := 0
var max_voice_count := 0
# The score/state stays in GDScript; selected wavetable voices share one native block.
var native_enabled := true
var native_mixer: RefCounted = ClassDB.instantiate("CityPadMixer") if ClassDB.class_exists("CityPadMixer") else null

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
		group["target"] = float(score["pad_gain"])*sqrt(float(group["members"].size())/maxf(6.0,float(population[group["cid"]])))*sqrt(float(score.get("pad_reference_communities",3.0))/maxf(float(score.get("pad_reference_communities",3.0)),population.size()))
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
		var members: Array = world.communities[cid]["members"]
		var has_facility := world.public_sites.any(func(site: Dictionary) -> bool:
			return bool(site.get("active",false)) and str(site.get("community_id","")) == cid and str(site.get("kind","")) in ["park","civic"])
		# A public site gives a small community a musical doorway before it has three houses.
		if members.size() >= 3 or (has_facility and not members.is_empty()): candidates.append(cid)
	candidates.sort_custom(func(a: String,b: String) -> bool:
		var ar := current_world.center_rank(a)
		var br := current_world.center_rank(b)
		if ar != br: return ar < br
		var ao := current_world.center_order(a)
		var bo := current_world.center_order(b)
		if ao != bo: return ao < bo
		return a < b)
	rhythms.clear()
	for cid in candidates:
		var chosen: Dictionary = {}
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
			rhythms.append({"cid":cid,"midi":int(overrides.get(chosen["district_id"],chosen["current_midi"])),"stereo":_stereo_for(chosen),"expression":chosen["expression"],"facility":facility_rhythm,"terrain":world.terrain.family,"zone_roles":world.functional_zone_roles(cid),"service_pressure":service_pressure})
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
			rhythms.append({"cid":cid,"midi":int(overrides.get(facility_building["district_id"],facility_building["current_midi"])),"stereo":_stereo_for(facility_building),"expression":facility_building["expression"],"facility":true,"terrain":world.terrain.family,"zone_roles":world.functional_zone_roles(cid),"service_pressure":service_pressure})
			break
	_sync_rhythm_nodes()
	theme.clear()
	response.clear()
	if candidates.is_empty() or (world.phrase_index+1)%int(score["theme_rest_phrases"]) == 0:
		_sync_musical_nodes()
		return
	var selected := candidates[(world.phrase_index/int(score["theme_rotate_phrases"]))%candidates.size()]
	var notes := world.community_theme(selected,overrides)
	var first: Dictionary = world.by_id[world.communities[selected]["members"][0]]
	var has_park := world.public_sites.any(func(site: Dictionary) -> bool: return site["kind"] == "park" and site["active"] and site["community_id"] == selected)
	var has_civic := world.public_sites.any(func(site: Dictionary) -> bool: return site["kind"] == "civic" and site["active"] and site["community_id"] == selected)
	theme = {"cid":selected,"notes":notes,"expression":first["expression"],"park":has_park,"civic":has_civic,"terrain":world.terrain.family,"center":current_world.center_for(selected).duplicate(true),"zone_roles":world.functional_zone_roles(selected),"stereo":_stereo_for(first)}
	if world.bridge:
		for cid in candidates:
			if world.communities[cid]["bank"] == world.communities[selected]["bank"]: continue
			var other_notes := world.community_theme(cid,overrides)
			if float(world.coupling.interval(int(notes[0]),int(other_notes[0]))["score"]) < 0.6: continue
			var other: Dictionary = world.by_id[world.communities[cid]["members"][0]]
			response = {"cid":cid,"notes":other_notes,"stereo":_stereo_for(other),"source":selected}
			break
	_sync_musical_nodes()

func _audibility(cid: String) -> float:
	if muted_communities.get(cid,false): return 0.0
	if listener_community.is_empty() or cid == listener_community: return 1.0
	return float(score["background_gain"])

func _sync_rhythm_nodes() -> void:
	for node in rhythm_nodes.values(): node["active"] = false
	for part in rhythms:
		var key := "%s:%d:%s:%s:%s:%s" % [part["cid"],part["midi"],part["expression"],part.get("terrain","river_valley"),JSON.stringify(part.get("zone_roles",[])),float(part.get("service_pressure",0.0)) >= 0.5]
		if not rhythm_nodes.has(key):
			rhythm_nodes[key] = part.duplicate(true)
			rhythm_nodes[key]["key"] = key
		rhythm_nodes[key]["active"] = true

func _sync_musical_nodes() -> void:
	for node in musical_nodes.values(): node["active"] = false
	if theme.is_empty(): return
	_register_musical_node(theme,theme,false)
	if not response.is_empty(): _register_musical_node(response,theme,true)

func _register_musical_node(part: Dictionary, pattern: Dictionary, answer: bool) -> void:
	var key := JSON.stringify([part["cid"],part["notes"],pattern["expression"],pattern["park"],pattern["civic"],pattern.get("terrain","river_valley"),pattern.get("zone_roles",[]),answer])
	if not musical_nodes.has(key):
		musical_nodes[key] = {"key":key,"part":part.duplicate(true),"pattern":pattern.duplicate(true),"answer":answer}
	musical_nodes[key]["active"] = true
	# Warm immutable event waves before the output clock starts.
	for note in part["notes"]:
		var pitch := int(note)+(24 if int(note) < 48 else 12)
		_event_wave(pitch,str(pattern["expression"]),int(values["timing"]["sample_rate"]))
		_event_wave(pitch+12,str(pattern["expression"]),int(values["timing"]["sample_rate"]))

func warm_score() -> void:
	var rate := int(values["timing"]["sample_rate"])
	for expression in ["bright","deep"]:
		for pitch in [60,62,64,67,69,72,74,76,79,81]: _event_wave(pitch,expression,rate)

func _event_wave(pitch: int, expression: String, rate: int) -> PackedFloat32Array:
	var key := "%d:%s:%d" % [pitch,expression,rate]
	if theme_waves.has(key): return theme_waves[key]
	var tail := 0.95 if expression == "deep" else 0.65
	var wave := PackedFloat32Array()
	wave.resize(ceili(tail*rate))
	var hz := frequency(pitch)
	for at in range(wave.size()):
		var seconds := float(at)/rate
		var envelope := minf(1.0,seconds/0.012)*exp(-seconds/(0.35 if expression == "deep" else 0.20))*clampf((tail-seconds)/0.03,0.0,1.0)
		wave[at] = (sin(TAU*hz*seconds)+0.18*sin(TAU*hz*seconds*2.0))/1.18*envelope
	theme_waves[key] = wave
	return wave

func _musical_block(node: Dictionary, start: int, count: int, rate: int) -> PackedFloat32Array:
	var output := PackedFloat32Array()
	output.resize(count)
	var pattern: Dictionary = node["pattern"]
	var part: Dictionary = node["part"]
	var beat := roundi(rate*0.5)
	var period := beat*32
	var delay := beat*2 if node["answer"] else 0
	var steps: Array = [0,8,16,24] if pattern["expression"] == "deep" else [0,3,6,10,16,19,22,27]
	var terrain := str(pattern.get("terrain","river_valley"))
	if terrain == "lake_basin": steps = [0,6,12,20] if pattern["expression"] == "deep" else [0,2,7,13,20,25]
	elif terrain == "forest_ridge": steps = [0,10,20] if pattern["expression"] == "deep" else [0,5,14,23]
	elif terrain == "coastal_plain": steps = [0,5,13,21] if pattern["expression"] == "deep" else [0,3,9,15,22,28]
	elif terrain == "highland_pass": steps = [0,6,14,22] if pattern["expression"] == "deep" else [0,4,11,18,26]
	var zone_roles: Array = pattern.get("zone_roles",[])
	if zone_roles.has("workshop"): steps = [0,6,12,18,24,30] if pattern["expression"] != "deep" else [0,8,16,24]
	elif zone_roles.has("choir"): steps = [0,8,16,24] if pattern["expression"] == "deep" else [0,4,12,20,28]
	elif zone_roles.has("market") and pattern["expression"] != "deep": steps = [0,2,5,9,16,18,22,27]
	elif zone_roles.has("garden"): steps = steps.slice(0,maxi(2,steps.size()-2))
	elif zone_roles.has("pulse_dense"): steps = [0,2,4,8,10,12,16,18,20,24,26,28]
	elif zone_roles.has("pulse"): steps = [0,4,8,12,16,20,24,28]
	if pattern["park"]: steps = steps.slice(0,maxi(2,steps.size()-2))
	var first_cycle := floori(float(start-delay)/period)-1
	var last_cycle := floori(float(start+count-delay)/period)
	for cycle in range(first_cycle,last_cycle+1):
		for index in range(steps.size()):
			var onset := cycle*period+int(steps[index])*beat+delay
			var notes: Array = part["notes"]
			var pitch := int(notes[index%notes.size()])
			pitch += 24 if pitch < 48 else 12
			if index%4 == 3: pitch += 12
			var wave := _event_wave(pitch,pattern["expression"],rate)
			var begin := maxi(start,onset)
			var finish := mini(start+count,onset+wave.size())
			for at in range(begin,finish): output[at-start] += wave[at-onset]
	return output

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
	var native_keys: Array[String] = []
	var native_tables: Array = []
	var native_controls := PackedFloat64Array()
	# Reserve slots for the environment and musical overlays before rendering pads.
	# Large cities can have more valid community/type/pitch groups than the 70-voice
	# budget; rotate the stable group set instead of asserting or producing a spike.
	var pad_budget := maxi(0,int(score["render_voice_limit"])-1-rhythm_nodes.size()-musical_nodes.size())
	var pad_candidates: Array[String] = []
	for key in pad_groups:
		var group: Dictionary = pad_groups[key]
		var level := float(state.get("_pad_level_"+key,group["level"]))
		if bool(group["active"]) or level > 0.00001: pad_candidates.append(str(key))
	pad_candidates.sort_custom(func(a: String,b: String) -> bool:
		var ga: Dictionary = pad_groups[a]
		var gb: Dictionary = pad_groups[b]
		if bool(ga["active"]) != bool(gb["active"]): return bool(ga["active"])
		var la := float(state.get("_pad_level_"+a,ga["level"]))
		var lb := float(state.get("_pad_level_"+b,gb["level"]))
		if not is_equal_approx(la,lb): return la > lb
		return a < b)
	var render_keys: Dictionary = {}
	for index in range(mini(pad_budget,pad_candidates.size())): render_keys[pad_candidates[index]] = true
	for key in pad_groups:
		var group: Dictionary = pad_groups[key]
		var target := float(group.get("target",0.0))*_audibility(group["cid"]) if group["active"] else 0.0
		var level := float(state.get("_pad_level_"+key,group["level"]))
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
		var spacing: int = beat*4 if rhythm["expression"] == "deep" else beat
		var service_pressure := float(rhythm.get("service_pressure",0.0))
		if service_pressure >= 0.5:
			spacing = beat*2 if rhythm["expression"] == "deep" else beat/2
		var hz := frequency(int(rhythm["midi"])+12)
		var phase_shift := 0 if cid.begins_with("west") else beat/2
		for i in range(count):
			level = move_toward(level,target,1.0/fade_frames)
			var elapsed := posmod(start+i-phase_shift,spacing)
			var seconds := float(elapsed)/rate
			if seconds >= 0.24: continue
			var envelope := minf(1.0,seconds/0.006)*exp(-seconds/0.075)*clampf((0.24-seconds)/0.01,0.0,1.0)
			output[i] += sin(TAU*hz*seconds)*envelope*float(score["rhythm_gain"])*level*gain*rhythm["stereo"]
		state[level_key] = level
		if not rhythm["active"] and level < 0.00001: retiring_rhythms.append(rhythm["key"])
	for key in retiring_rhythms: rhythm_nodes.erase(key)
	if duck_release_at >= 0 and start >= duck_release_at: ducking = false
	var theme_count := 0
	var response_count := 0
	var retiring_musical: Array = []
	for node in musical_nodes.values():
		var part: Dictionary = node["part"]
		var pattern: Dictionary = node["pattern"]
		var key: String = node["key"]
		var level := float(state.get("_theme_level_"+key,0.0))
		var target := _audibility(part["cid"]) if node["active"] else 0.0
		if level > 0.00001 or target > 0.0:
			if node["answer"]: response_count += 1
			else: theme_count += 1
		var wave := _musical_block(node,start,count,rate)
		var amplitude := float(score["response_gain"] if node["answer"] else score["theme_gain"])*gain
		if not node["answer"] and pattern["civic"]: amplitude *= 1.15
		var stereo: Vector2 = part["stereo"]
		for i in range(count):
			level = move_toward(level,target,1.0/fade_frames)
			output[i] += wave[i]*level*amplitude*stereo
		state["_theme_level_"+key] = level
		if not node["active"] and level < 0.00001: retiring_musical.append(key)
	for key in retiring_musical: musical_nodes.erase(key)
	last_voice_count = active_count+pulse_count+theme_count+response_count+1
	max_voice_count = maxi(max_voice_count,last_voice_count)
	assert(last_voice_count <= int(score["render_voice_limit"]))
	voice_group_stats = {"entities":districts.size(),"pad_nodes":active_count,"rhythm_nodes":pulse_count,"theme_nodes":theme_count,"response_nodes":response_count,"environment_nodes":1,"render_voices":last_voice_count,"max_render_voices":max_voice_count,"voice_budget":int(score["render_voice_limit"]),"budget_shed":maxi(0,pad_candidates.size()-mini(pad_budget,pad_candidates.size()))}
	return output

func score_snapshot() -> Dictionary:
	return {"theme":theme.duplicate(true),"response":response.duplicate(true),"rhythms":rhythms.duplicate(true),"pads":pad_groups.keys(),"voices":voice_group_stats.duplicate(true)}
