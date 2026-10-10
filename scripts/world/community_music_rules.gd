extends RefCounted
## One qualification source for score scheduling and selected-community opportunities.
static func status(world: RefCounted,cid: String) -> Dictionary:
	var members: Array = world.communities.get(cid,{}).get("members",[])
	var mature := 0
	var commercial := 0
	var lowest := 127
	var deep := 0
	var deep_mature := 0
	for id in members:
		if not world.by_id.has(id): continue
		var building: Dictionary = world.by_id[id]
		var mature_form := str(building["form"]) in ["群","央","腔"]
		if mature_form: mature += 1
		if str(building["type"]) == "commercial": commercial += 1
		if str(building.get("expression","")) == "deep":
			deep += 1
			if mature_form: deep_mature += 1
		lowest = mini(lowest,int(building["current_midi"]))
	var courts := 0
	for court in world.fabric_cache.get("courtyards",[]):
		if str(court.get("community_id","")) == cid: courts += 1
	var wall: Dictionary = world.fabric_cache.get("community_wall",{}).get(cid,{})
	var formed: bool = members.size() >= 4 and float(wall.get("score",0.0)) >= 0.35 and courts >= 1
	var eligible := formed and mature >= 6
	return {"cid":cid,"members":members.size(),"mature":mature,"courtyards":courts,"street_formed":float(wall.get("score",0.0)) >= 0.35,
		"formed":formed,"theme_eligible":eligible,"commercial":commercial,"lowest":lowest,
		"deep":deep,"deep_mature":deep_mature}

static func facilities(world: RefCounted,cid: String) -> Dictionary:
	var result := {"park":false,"civic":false,"anchor_ids":[],"served":0,"capacity":0}
	for site in world.public_sites:
		if not bool(site.get("active",false)): continue
		var belongs := str(site.get("community_id","")) == cid
		var serves := false
		for id in site.get("served",[]):
			if world.by_id.has(id) and str(world.by_id[id]["community_id"]) == cid:
				serves = true
				result["served"] += 1
		if site["kind"] == "park" and belongs: result["park"] = true
		if site["kind"] == "civic" and serves:
			result["civic"] = true
			result["capacity"] += int(site.get("service_capacity",18))
		if (site["kind"] == "park" and belongs) or (site["kind"] == "civic" and (belongs or serves)):
			result["anchor_ids"].append(str(site.get("anchor_id",site["id"])))
	return result

static func _rhythm_part(score: Dictionary,cid: String) -> Dictionary:
	for part in score.get("rhythms",[]):
		if str(part.get("cid","")) == cid: return part
	return {}

static func _pads_include_low_material(score: Dictionary,cid: String) -> bool:
	# score_snapshot keeps pad keys as "community:type:midi".  Retired keys may
	# remain during their fade, which is still an audible current opportunity.
	for raw in score.get("pads",[]):
		var parts := str(raw).split(":")
		if parts.size() < 3 or str(parts[0]) != cid: continue
		if int(parts[2]) <= 48: return true
	return false

static func _sorted_ids(ids: Dictionary) -> Array:
	var result: Array = ids.keys()
	result.sort()
	return result

static func _role_entry(rule_id: String,role: String,title: String,anchor_ids: Array,met: Array,missing: Array,
		qualified: bool,playing: bool,current: String,next: String,world: RefCounted,extra: Dictionary = {}) -> Dictionary:
	var result := {"rule_id":rule_id,"role":role,"title":title,"anchor_ids":anchor_ids.duplicate(),
		"met_conditions":met.duplicate(),"missing_conditions":missing.duplicate(),
		"affected_role_ids":[role],"world_version":[world.phrase_index,world.action_serial,world.planning_revision],
		"qualified":qualified,"playing":playing,"qualification":{"qualified":qualified,
			"met_conditions":met.duplicate(),"missing_conditions":missing.duplicate()},
		"current":current,"next":next}
	for key in extra: result[key] = extra[key]
	return result

static func opportunity(world: RefCounted,cid: String,score: Dictionary) -> Dictionary:
	var state := status(world,cid)
	var facility := facilities(world,cid)
	var met: Array[String] = []
	var missing: Array[String] = []
	if bool(state["street_formed"]): met.append("街墙已成形")
	else: missing.append("继续沿街连片")
	if int(state["courtyards"]) > 0: met.append("已有公共内院")
	else: missing.append("围合一处内院")
	if int(state["mature"]) >= 6: met.append("六栋成熟房屋")
	else: missing.append("还需%d栋成熟房屋" % maxi(0,6-int(state["mature"])))
	var theme: Dictionary = score.get("theme",{})
	var response: Dictionary = score.get("response",{})
	var playing := str(theme.get("cid","")) == cid
	var answering := str(response.get("cid","")) == cid
	var pulse: bool = score.get("rhythms",[]).any(func(part: Dictionary)->bool:return str(part.get("cid","")) == cid)
	var current: Array[String] = []
	if playing: current.append("正在唱主题")
	if answering: current.append("正在跨岸应答")
	if pulse: current.append("正在演奏节奏")
	if current.is_empty(): current.append("当前以长音融入合奏")
	var muted := bool(score.get("muted_communities",{}).get(cid,false))
	if muted: current = ["社区已静音 · M恢复"]
	elif str(score.get("listener_community","")) == cid: current.append("独听中")
	var next := ""
	if not state["theme_eligible"]:
		next = "主题机会 · "+"，".join(missing)
	elif playing:
		next = "改一栋的音，听这片社区怎样改写主题"
	elif (world.phrase_index+1)%int(world.cfg["score"]["theme_rest_phrases"]) == 0:
		next = "本句全城旋律留白；主题资格保留"
	else:
		next = "主题已就绪 · F聚焦或Tab独听，下一拍接入唯一主题槽"
	var river_pairs: Array = preload("res://scripts/world/river_call_response.gd").pairs(world)
	var pair_count := 0
	var paired_ids: Dictionary = {}
	for pair in river_pairs:
		for id in [pair["a"],pair["b"]]:
			if str(world.by_id[id]["community_id"]) == cid:
				pair_count += 1
				paired_ids[id] = true
	if pair_count > 0:
		next += "\n跨河对唱 · %d栋参与%d组协和；来源主题会延迟两拍回答，不改变活力；不必建桥" % [paired_ids.size(),pair_count]
		if not answering: next += "\n对唱等待来源主题与唯一应答槽"
	elif world.terrain.family not in ["lake_basin","coastal_plain"]:
		next += "\n对唱机会 · 两岸直线距离小于8、音程协和至少0.85；不必建桥"
	var roles: Array = []
	var role_status: Dictionary = {}
	var theme_opportunity := _role_entry("P11-COMMUNITY-THEME","Lead","社区主题",facility["anchor_ids"],met,missing,
		bool(state["theme_eligible"]),playing," · ".join(current),next,world,{"community_id":cid,"river_pairs":pair_count})
	roles.append(theme_opportunity)
	role_status["Lead"] = theme_opportunity.duplicate(true)

	# Bass is deliberately an expression opportunity, not a new audio route. It
	# is qualified by data already present on buildings and can be heard through
	# the existing pad/theme/rhythm scheduling.
	var low_pitch := int(state["lowest"]) <= 48
	var deep_material := int(state.get("deep",0)) > 0
	var bass_qualified := low_pitch or deep_material
	var bass_playing := _pads_include_low_material(score,cid)
	var theme_deep := playing and str(theme.get("expression","")) == "deep"
	var rhythm_part := _rhythm_part(score,cid)
	if theme_deep or (not rhythm_part.is_empty() and str(rhythm_part.get("expression","")) == "deep"): bass_playing = true
	var bass_met: Array = []
	var bass_missing: Array = []
	var bass_anchor_ids: Array = []
	for member_id in world.communities.get(cid,{}).get("members",[]):
		var member_key := str(member_id)
		if not world.by_id.has(member_key): continue
		var member: Dictionary = world.by_id[member_key]
		if int(member.get("current_midi",127)) <= 48 or str(member.get("expression","")) == "deep": bass_anchor_ids.append(member_key)
	if low_pitch: bass_met.append("已有低音音级")
	if deep_material: bass_met.append("已有深色表达素材")
	if bass_met.is_empty(): bass_missing.append("调出更低音级或选择深色表达")
	var bass_current := "正在使用低音/深色表达素材" if bass_playing else ("已有低音素材，等待现有声部安排" if bass_qualified else "当前没有低音音级或深色表达")
	var bass_next := "低音素材已在当前合奏中；继续调整位置或音级听取与主题的关系" if bass_playing else ("低音素材可用；它会与现有 Pad/主题竞争，不新增专用声部" if bass_qualified else "低音机会 · 选择低音音级或深色表达，再听它与当前合奏的关系")
	var bass_opportunity := _role_entry("P11-BASS-EXPRESSION","Bass","低音表达",bass_anchor_ids,bass_met,bass_missing,bass_qualified,bass_playing,bass_current,bass_next,world,
		{"community_id":cid,"source":"status.lowest/status.deep","affected_role_ids":["Bass","Pad"]})
	bass_opportunity["affected_role_ids"] = ["Bass","Pad"]
	roles.append(bass_opportunity)
	role_status["Bass"] = bass_opportunity.duplicate(true)

	# Rhythm qualification follows the exact source used by ContinuousSynth:
	# real commercial members (or a public facility fallback) and the currently
	# selected finite rhythm slots. No extra slot or permanent guarantee is made.
	var rhythm_playing := not rhythm_part.is_empty() and not bool(rhythm_part.get("facility",false))
	var facility_rhythm := not rhythm_part.is_empty() and bool(rhythm_part.get("facility",false))
	var zone_roles: Array[String] = world.functional_zone_roles(cid)
	var commercial_ready := int(state["commercial"]) > 0 or zone_roles.has("market")
	var rhythm_qualified := commercial_ready or facility_rhythm or not rhythm_part.is_empty()
	var rhythm_met: Array = []
	var rhythm_missing: Array = []
	var rhythm_anchor_ids: Array = []
	for member_id in world.communities.get(cid,{}).get("members",[]):
		var member_key := str(member_id)
		if world.by_id.has(member_key) and str(world.by_id[member_key].get("type","")) == "commercial": rhythm_anchor_ids.append(member_key)
	if facility_rhythm: rhythm_anchor_ids.append_array(facility["anchor_ids"])
	if int(state["commercial"]) > 0: rhythm_met.append("已有%d栋商业建筑" % int(state["commercial"]))
	if zone_roles.has("market"): rhythm_met.append("商贸核心已形成")
	if facility_rhythm: rhythm_met.append("公共空间提供节奏入口")
	if not rhythm_part.is_empty() and int(state["commercial"]) == 0 and not facility_rhythm: rhythm_met.append("现有合奏已排入节奏槽")
	if rhythm_met.is_empty(): rhythm_missing.append("沿真实道路形成商业或公共节奏入口")
	var rhythm_limit := int(world.cfg.get("score",{}).get("rhythm_slot_limit",2))
	var rhythm_competing := bool(rhythm_part.is_empty() and score.get("rhythms",[]).size() >= rhythm_limit)
	if rhythm_competing: rhythm_missing.append("节奏槽已有其他社区使用")
	var rhythm_current := "正在演奏商业律动" if rhythm_playing else ("公共空间正在占用节奏入口" if facility_rhythm else ("已有商业素材，当前等待节奏槽" if rhythm_qualified else "当前以长音融入合奏"))
	var rhythm_next := "商业律动已入有限节奏槽；邻近社区仍可竞争" if rhythm_playing else ("节奏槽已有其他社区使用；改变商业密度或聚焦后再听" if rhythm_competing else ("商业/公共节奏素材已就绪，下一拍参与槽位竞争" if rhythm_qualified else "节奏机会 · 沿真实道路形成商业建筑或公共入口，再听短促脉冲"))
	var rhythm_opportunity := _role_entry("P11-COMMERCIAL-RHYTHM","Rhythm","商业律动",rhythm_anchor_ids,rhythm_met,rhythm_missing,rhythm_qualified,rhythm_playing,rhythm_current,rhythm_next,world,
		{"community_id":cid,"slot_limit":rhythm_limit,"slot_competing":rhythm_competing,"facility":facility_rhythm,"zone_roles":zone_roles})
	rhythm_opportunity["affected_role_ids"] = ["Rhythm","Pad"]
	roles.append(rhythm_opportunity)
	role_status["Rhythm"] = rhythm_opportunity.duplicate(true)

	var response_qualified := pair_count > 0
	var response_playing := answering
	var response_met: Array = []
	var response_missing: Array = []
	if pair_count > 0:
		response_met.append("%d组跨岸协和配对" % pair_count)
		response_met.append("%d栋有真实应答关系" % paired_ids.size())
	else:
		if world.terrain.family in ["lake_basin","coastal_plain"]: response_missing.append("当前地形没有河流对岸应答")
		else: response_missing.append("两岸直线距离小于8且音程协和至少0.85")
	var response_current := "正在跨岸应答" if response_playing else ("已有跨岸配对，等待来源主题" if response_qualified else "当前没有跨岸应答")
	var response_next := "来源主题已延迟两拍回答；继续调整两岸位置或音级可更换接收者" if response_playing else ("跨岸配对已就绪；需要来源主题与唯一应答槽" if response_qualified else "应答机会 · 调整两岸位置或音级形成真实协和配对")
	var response_opportunity := _role_entry("P11-RIVER-RESPONSE","Response","跨岸应答",_sorted_ids(paired_ids),response_met,response_missing,response_qualified,response_playing,response_current,response_next,world,
		{"community_id":cid,"river_pairs":pair_count,"river_members":paired_ids.size(),"receiver_community":str(response.get("cid","")),"source_community":str(response.get("source",""))})
	response_opportunity["affected_role_ids"] = ["Response","Lead"]
	roles.append(response_opportunity)
	role_status["Response"] = response_opportunity.duplicate(true)

	return {"rule_id":"P11-COMMUNITY-THEME","anchor_ids":facility["anchor_ids"],"community_id":cid,
		"met_conditions":met,"missing_conditions":missing,"affected_role_ids":["Lead","Rhythm","Response"],
		"world_version":[world.phrase_index,world.action_serial,world.planning_revision],
		"river_pairs":pair_count,"river_members":paired_ids.size(),
		"qualified":bool(state["theme_eligible"]),"playing":playing,"answering":answering,"pulse":pulse,
		"current": " · ".join(current),"next":next,"status":state,"facility":facility,
		"opportunities":roles,"role_opportunities":role_status}
