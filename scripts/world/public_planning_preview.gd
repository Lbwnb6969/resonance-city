extends RefCounted
## Ephemeral P11 comparison. Every branch starts from one private model and PCM state.
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const River = preload("res://scripts/world/river_call_response.gd")

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

## Aggregate the selected scope into one small, ephemeral continuation hint.
## Each relation is derived from an already scheduled role or an existing
## world relation; this never creates an extra voice, facility, or save field.
static func community_combo(world: RefCounted,community_ids: Array,score: Dictionary) -> Dictionary:
	var ids: Array[String] = []
	for raw in community_ids:
		var cid := str(raw)
		if not cid.is_empty() and world.communities.has(cid) and not ids.has(cid): ids.append(cid)
	var combo := {"contract":"P11-COMMUNITY-COMBO/v1","community_ids":ids.duplicate(),
		"count":ids.size(),"mode":"single" if ids.size() < 2 else "multi",
		"relations":[],"audible":{},"next":"","message":""}
	if ids.size() < 2:
		combo["next"] = "单社区规划 · 下一句沿当前主题条件继续"
		combo["message"] = combo["next"]
		return combo
	var id_set: Dictionary = {}
	for cid in ids: id_set[cid] = true
	var theme: Dictionary = score.get("theme",{})
	var response: Dictionary = score.get("response",{})
	var theme_cid := str(theme.get("cid",""))
	var response_source := str(response.get("source",""))
	var response_cid := str(response.get("cid",""))
	if id_set.has(theme_cid): combo["audible"]["lead_community"] = theme_cid
	if id_set.has(response_source) and id_set.has(response_cid) and response_source != response_cid:
		combo["audible"]["reply_source"] = response_source
		combo["audible"]["reply_community"] = response_cid
		combo["audible"]["reply_generation"] = int(response.get("generation",0))
		combo["relations"].append({"kind":"river_response","source":response_source,
			"receiver":response_cid,"pair_count":int(response.get("pair_count",0)),"audible":true})
	# River pairs are a real spatial opportunity even before the unique response
	# slot is scheduled. Keep only pairs whose two owning communities are in the
	# player's selected scope and collapse them to deterministic community pairs.
	var pair_keys: Dictionary = {}
	for pair in River.pairs(world):
		var a_id := str(pair.get("a",""))
		var b_id := str(pair.get("b",""))
		if not world.by_id.has(a_id) or not world.by_id.has(b_id): continue
		var a_cid := str(world.by_id[a_id].get("community_id",""))
		var b_cid := str(world.by_id[b_id].get("community_id",""))
		if a_cid == b_cid or not id_set.has(a_cid) or not id_set.has(b_cid): continue
		var pair_key := a_cid+"|"+b_cid if a_cid < b_cid else b_cid+"|"+a_cid
		if pair_keys.has(pair_key):
			pair_keys[pair_key]["pair_count"] = int(pair_keys[pair_key]["pair_count"])+1
			pair_keys[pair_key]["best_score"] = maxf(float(pair_keys[pair_key]["best_score"]),float(pair.get("score",0.0)))
			continue
		pair_keys[pair_key] = {"kind":"river_opportunity","communities":[a_cid,b_cid],
			"pair_count":1,"best_score":float(pair.get("score",0.0)),"audible":false}
	for pair_key in pair_keys:
		var relation: Dictionary = pair_keys[pair_key]
		var already_audible := false
		for existing in combo["relations"]:
			if existing.get("kind","") != "river_response": continue
			var source := str(existing.get("source",""))
			var receiver := str(existing.get("receiver",""))
			if relation["communities"].has(source) and relation["communities"].has(receiver):
				already_audible = true
				relation["audible"] = true
				break
		if not already_audible: combo["relations"].append(relation)
	# Existing authored/derived transit lines provide another real cross-
	# community connection. It remains a planning relation until actual audio
	# role qualification says otherwise.
	for line in world.transit_lines:
		var line_ids: Array[String] = []
		for raw in line.get("community_ids",line.get("line_community_ids",[])):
			var cid := str(raw)
			if id_set.has(cid) and not line_ids.has(cid): line_ids.append(cid)
		if line_ids.size() < 2: continue
		combo["relations"].append({"kind":"transit","communities":line_ids,
			"line_id":str(line.get("id","")),"route_role":str(line.get("route_role","社区往返线")),"audible":false})
	var audible: Dictionary = combo["audible"]
	if audible.has("reply_source"):
		combo["next"] = "%s主题 → %s应答，下一句沿真实两拍延迟继续听" % [str(world.communities[audible["reply_source"]].get("name",audible["reply_source"])),str(world.communities[audible["reply_community"]].get("name",audible["reply_community"]))]
	elif audible.has("lead_community"):
		var lead_name := str(world.communities[theme_cid].get("name",theme_cid))
		combo["next"] = "%s在下一句保留主题；其他所选社区继续竞争已有声部" % lead_name
	elif not combo["relations"].is_empty():
		combo["next"] = "所选社区已有真实连接条件；下一句先听现有声部，再决定是否继续组合"
	else:
		combo["next"] = "已保留%d个社区的同一规划范围；下一句各自竞争已有声部，不自动新增声部" % ids.size()
	combo["message"] = combo["next"]
	return combo

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
			"community_name":str(world.communities[cid].get("name",cid)),
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
	var combo_summary := community_combo(world,community_ids,score)
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
		"community_combo":combo_summary,
		"rules":["P11-COMMUNITY-THEME","P11-BASS-EXPRESSION","P11-COMMERCIAL-RHYTHM","P11-RIVER-RESPONSE"],
	}

static func identity(model: ContinuousAudioModel,site: Dictionary) -> Array:
	return [Charter.version(model.world),model.next_boundary,site.get("source_site_id",""),site.get("polygon",PackedVector2Array()),site.get("footprint_components",[]),
		bool(site.get("partial",false)),site.get("source_reservation_id",site.get("reservation_id","")),site.get("source_revision",""),
		bool(site.get("reuse",false)),site.get("public_id",""),
		site.get("target_polygons",[]),site.get("target_polygon",PackedVector2Array()),site.get("hole_polygons",[]),site.get("target_holes",[]),
		site.get("position",[]),site.get("target_position",[]),site.get("community_id",""),site.get("planning_scope",[]),
		hash(model.world.pending_actions),hash(model.sound_events),hash(model.sound_overrides),
		model.synth.focused_community,model.synth.listener_community,model.synth.response_enabled,hash(model.synth.muted_communities),model.synth.gain,hash(model.synth.score)].duplicate(true)

static func _operation(site: Dictionary,kind: String) -> Dictionary:
	if bool(site.get("reuse",false)):
		return {"kind":kind,"reuse":true,"id":str(site["public_id"]),
			"position":site["position"].duplicate(),"source_revision":str(site["source_revision"])}
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
	if bool(site.get("reuse",false)): common.cancel_public_reuse(str(site["public_id"]))
	else: common.cancel_planning()
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
		elif bool(site.get("reuse",false)):
			for existing in branch.world.public_sites:
				if str(existing.get("id","")) == str(site["public_id"]):
					anchor = existing.duplicate(true)
					break
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
