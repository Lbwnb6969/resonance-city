extends RefCounted
## Ephemeral P11 comparison. Every branch starts from one private model and PCM state.
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Charter = preload("res://scripts/world/development_charter.gd")

static func _append_community_id(ids: Array[String], raw: Variant) -> void:
	var cid := str(raw)
	if cid.is_empty() or ids.has(cid): return
	ids.append(cid)

static func _affected_communities(world: RefCounted,site: Dictionary,anchor: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	_append_community_id(ids,site.get("community_id",""))
	_append_community_id(ids,anchor.get("community_id",""))
	for cid in anchor.get("target_community_ids",[]): _append_community_id(ids,cid)
	# The normal guide carries its current editable scope into this private
	# comparison. Partial footprints keep their actual owner/service scope;
	# neither path expands from an unrelated historical charter.
	if not bool(site.get("partial",false)):
		for raw_cid in site.get("planning_scope",[]): _append_community_id(ids,raw_cid)
	for raw_id in anchor.get("served",[]):
		var id := str(raw_id)
		if world.by_id.has(id): _append_community_id(ids,world.by_id[id].get("community_id",""))
	# The owner is first so a preview always has a stable primary record. The
	# remaining service recipients are sorted because coverage order is a
	# derived cache, not a player-authored ordering.
	var tail: Array[String] = ids.slice(1)
	tail.sort()
	var result: Array[String] = []
	for cid in ids.slice(0,1): result.append(cid)
	result.append_array(tail)
	return result

static func _role_aliases(opportunity: Dictionary) -> Dictionary:
	var aliases := {"Lead":"theme","Bass":"bass","Rhythm":"commercial","Response":"response"}
	var roles: Dictionary = {}
	for raw in opportunity.get("opportunities",[]):
		if not raw is Dictionary: continue
		var role := str(raw.get("role",""))
		if role.is_empty(): continue
		var alias := str(aliases.get(role,role.to_lower()))
		roles[alias] = raw.duplicate(true)
	# Keep the role map authoritative if a future rule adds an entry without
	# adding it to the display list.
	for raw_role in opportunity.get("role_opportunities",{}):
		var role_entry: Dictionary = opportunity["role_opportunities"][raw_role]
		var alias := str(aliases.get(str(raw_role),str(raw_role).to_lower()))
		roles[alias] = role_entry.duplicate(true)
	return roles

static func _schedule_facts(cid: String,score: Dictionary,roles: Dictionary) -> Dictionary:
	var theme: Dictionary = score.get("theme",{})
	var response: Dictionary = score.get("response",{})
	var rhythm_part: Dictionary = {}
	for raw in score.get("rhythms",[]):
		if str(raw.get("cid","")) == cid:
			rhythm_part = raw.duplicate(true)
			break
	var theme_scheduled := str(theme.get("cid","")) == cid
	var response_scheduled := str(response.get("cid","")) == cid
	var facility_rhythm := not rhythm_part.is_empty() and bool(rhythm_part.get("facility",false))
	var commercial_rhythm := not rhythm_part.is_empty() and not facility_rhythm
	var facts := {
		"theme":theme_scheduled,
		"rhythm_slot_assigned":not rhythm_part.is_empty(),
		"commercial_rhythm":commercial_rhythm,
		"facility_rhythm":facility_rhythm,
		"response":response_scheduled,
		"response_source":str(response.get("source","")),
		"response_generation":int(response.get("generation",0)),
		"rhythm_part":rhythm_part,
		"consistency":{
			"theme":bool(roles.get("theme",{}).get("playing",false)) == theme_scheduled,
			"commercial":bool(roles.get("commercial",{}).get("playing",false)) == commercial_rhythm,
			"response":bool(roles.get("response",{}).get("playing",false)) == response_scheduled,
		}
	}
	return facts

static func _opportunity_preview(world: RefCounted,site: Dictionary,choice: String,source_version: Array,
		source_frame: int,boundary_frame: int,score: Dictionary,anchor: Dictionary,community_ids: Array) -> Dictionary:
	var world_version: Array = Charter.version(world)
	var records: Array = []
	var all_anchor_ids: Array[String] = []
	var all_affected_roles: Array[String] = []
	for cid in community_ids:
		if not world.communities.has(cid): continue
		var canonical: Dictionary = Rules.opportunity(world,cid,score)
		var roles := _role_aliases(canonical)
		var qualification := {}
		var current := {}
		var next := {}
		var role_qualifications := {}
		var anchor_ids: Array[String] = []
		var affected_roles: Array[String] = []
		for alias in ["theme","bass","commercial","response"]:
			var entry: Dictionary = roles.get(alias,{})
			if entry.is_empty(): continue
			qualification[alias] = bool(entry.get("qualified",false))
			current[alias] = str(entry.get("current",""))
			next[alias] = str(entry.get("next",""))
			role_qualifications[alias] = entry.get("qualification",{}).duplicate(true)
			for raw_id in entry.get("anchor_ids",[]):
				var anchor_id := str(raw_id)
				if not anchor_id.is_empty() and not anchor_ids.has(anchor_id): anchor_ids.append(anchor_id)
			for raw_role in entry.get("affected_role_ids",[]):
				var role_id := str(raw_role)
				if not role_id.is_empty() and not affected_roles.has(role_id): affected_roles.append(role_id)
				if not role_id.is_empty() and not all_affected_roles.has(role_id): all_affected_roles.append(role_id)
		for anchor_id in anchor_ids:
			if not all_anchor_ids.has(anchor_id): all_anchor_ids.append(anchor_id)
		var schedule := _schedule_facts(cid,score,roles)
		var record := {
			"community_id":cid,
			"source":{
				"kind":"public_planning_variant",
				"site_id":str(site.get("source_site_id","")),
				"community_id":str(site.get("community_id","")),
				"choice":choice,
				"frame":source_frame,
			},
			"source_site_id":str(site.get("source_site_id","")),
			"choice":choice,
			"source_frame":source_frame,
			"boundary_frame":boundary_frame,
			"world_version":world_version.duplicate(true),
			"anchor_ids":anchor_ids,
			"affected_role_ids":affected_roles,
			"qualification":qualification,
			"role_qualifications":role_qualifications,
			"current":current,
			"next":next,
			"roles":roles,
			"role_opportunities":roles.duplicate(true),
			"schedule":schedule,
			"met_conditions":canonical.get("met_conditions",[]).duplicate(),
			"missing_conditions":canonical.get("missing_conditions",[]).duplicate(),
			"status":canonical.get("status",{}).duplicate(true),
			"facility":canonical.get("facility",{}).duplicate(true),
		}
		records.append(record)
	return {
		"source":{
			"kind":"public_planning_variant",
			"site_id":str(site.get("source_site_id","")),
			"community_id":str(site.get("community_id","")),
			"choice":choice,
			"frame":source_frame,
		},
		"source_site_id":str(site.get("source_site_id","")),
		"choice":choice,
		"source_version":source_version.duplicate(true),
		"source_frame":source_frame,
		"boundary_frame":boundary_frame,
		"world_version":world_version,
		"boundary":{"frame":boundary_frame,"world_version":world_version.duplicate(true)},
		"affected_communities":community_ids.duplicate(),
		"communities":records,
		"anchor_ids":all_anchor_ids,
		"affected_role_ids":all_affected_roles,
		"rules":["P11-COMMUNITY-THEME","P11-BASS-EXPRESSION","P11-COMMERCIAL-RHYTHM","P11-RIVER-RESPONSE"],
	}

static func identity(model: ContinuousAudioModel,site: Dictionary) -> Array:
	return [Charter.version(model.world),model.next_boundary,site.get("source_site_id",""),site.get("polygon",PackedVector2Array()),site.get("footprint_components",[]),
		bool(site.get("partial",false)),site.get("source_reservation_id",site.get("reservation_id","")),site.get("source_revision",""),
		site.get("target_polygons",[]),site.get("target_polygon",PackedVector2Array()),site.get("hole_polygons",[]),site.get("target_holes",[]),
		site.get("position",[]),site.get("target_position",[]),site.get("community_id",""),site.get("planning_scope",[]),
		hash(model.world.pending_actions),hash(model.sound_events),hash(model.sound_overrides),
		model.synth.focused_community,model.synth.listener_community,model.synth.response_enabled,hash(model.synth.muted_communities),model.synth.gain,hash(model.synth.score)].duplicate(true)

static func _operation(site: Dictionary,kind: String) -> Dictionary:
	if not bool(site.get("partial",false)): return {"kind":kind,"position":site["position"].duplicate()}
	# The painted target is one authored decision shared by both facility
	# choices. Passing only its position would select the entire source parcel.
	var operation := {"kind":kind,"partial":true}
	for key in ["source_reservation_id","reservation_id","source_revision","source_site_id","community_id",
			"position","target_position","target_polygon","target_polygons","footprint_components","hole_polygons","target_holes"]:
		if not site.has(key): continue
		var value: Variant = site[key]
		if value is Array or value is Dictionary: operation[key] = value.duplicate(true)
		elif value is PackedVector2Array: operation[key] = value.duplicate()
		else: operation[key] = value
	return operation

static func _committed_anchor(world: RefCounted,site: Dictionary,kind: String,event_id: int,boundary: int) -> Dictionary:
	var anchor_id := ""
	for event in world.events:
		if str(event.get("kind","")) != kind or int(event.get("frame",-1)) != boundary: continue
		if bool(site.get("partial",false)):
			if int(event.get("event_id",-1)) != event_id: continue
		elif str(event.get("source_site_id","")) != str(site.get("source_site_id","")): continue
		anchor_id = str(event.get("id",""))
		break
	for public_site in world.public_sites:
		if str(public_site.get("id","")) == anchor_id and str(public_site.get("kind","")) == kind and bool(public_site.get("active",false)):
			return public_site.duplicate(true)
	return {}

static func build(source: ContinuousAudioModel,site: Dictionary,state: Dictionary,at: int) -> Dictionary:
	var rate: int = source.world.cfg["timing"]["sample_rate"]
	var boundary := source.next_boundary
	var result := {"source_version":identity(source,site),"source_frame":at,"boundary_frame":boundary,"sample_rate":rate,
		"gain":source.synth.gain,"seconds":3,"source_site_id":site["source_site_id"],"variants":{}}
	# P10 has one replaceable public-planning slot. Remove that slot in every
	# branch, retaining the charter, all seed/retune intent and sound controls.
	var common := source.freeze()
	common.cancel_planning()
	for kind: String in ["none","park","civic"]:
		var branch := common.freeze()
		var phases := state.duplicate(true)
		var request := {"accepted":true}
		if kind != "none": request = branch.submit(_operation(site,kind))
		if not bool(request["accepted"]):
			result["variants"][kind] = {"accepted":false,"reason":request["reason"],"pcm":PackedByteArray()}
			continue
		for begin in range(at,boundary,1024): branch.render_block(phases,begin,mini(1024,boundary-begin),rate)
		var pcm := branch.render_block(phases,boundary,rate*3,rate)
		var accepted := true
		if kind != "none":
			accepted = not branch.world.events.any(func(e:Dictionary)->bool:
				return e.get("kind","") == "planning_rejected" and int(e.get("event_id",-1)) == int(request["event_id"]))
		var anchor: Dictionary = {}
		if kind != "none": anchor = _committed_anchor(branch.world,site,kind,int(request["event_id"]),boundary)
		accepted = accepted and (kind == "none" or not anchor.is_empty())
		var score := branch.synth.score_snapshot()
		var theme: Dictionary = score["theme"]
		var served: Array = []
		for public_site in branch.world.public_sites:
			if public_site.get("active",false) and public_site.get("kind","") == "civic":
				for id in public_site.get("served",[]):
					if not served.has(id): served.append(id)
		var opportunities: Array = []
		var cids: Array[String] = _affected_communities(branch.world,site,anchor)
		for cid in cids: opportunities.append(Rules.opportunity(branch.world,cid,score))
		var opportunity_preview := _opportunity_preview(branch.world,site,kind,result["source_version"],at,boundary,score,anchor,cids)
		var births: Array = branch.world.events.filter(func(e:Dictionary)->bool:
			return e.get("kind","") == "birth" and int(e.get("frame",-1)) == boundary).map(func(e:Dictionary)->Variant:return e["district_id"])
		var peak := 0.0
		for sample in pcm: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		opportunity_preview["accepted"] = accepted
		opportunity_preview["reason"] = "" if accepted else "同句规划冲突，落定时未提交"
		result["variants"][kind] = {"accepted":accepted,"reason":"" if accepted else "同句规划冲突，落定时未提交",
			"pcm":Renderer.pcm16(pcm) if accepted else PackedByteArray(),"anchor":anchor,"opportunities":opportunities,
			"opportunity_preview":opportunity_preview,
			"score":score,"theme_events":0 if theme.is_empty() else branch.synth.musical_steps(theme).size(),
			"service":branch.world.public_service_summary(),"served_ids":served,"birth_ids":births,
			"houses":branch.world.buildings.size(),"peak":peak,"max_voices":branch.synth.max_voice_count}
	var original: Dictionary = result["variants"]["none"]
	for kind in result["variants"]:
		var variant: Dictionary = result["variants"][kind]
		if not variant["accepted"]: continue
		var newly: Array = variant["served_ids"].filter(func(id:Variant)->bool:return not original["served_ids"].has(id))
		var lost: Array = original["served_ids"].filter(func(id:Variant)->bool:return not variant["served_ids"].has(id))
		variant["newly_served_ids"] = newly
		variant["lost_service_ids"] = lost
	return result
