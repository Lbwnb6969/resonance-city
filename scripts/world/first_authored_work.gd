extends RefCounted
## Current authorship is a query over surviving families and the caller's
## audible World/score/pitches. It never selects a theme or stores progress.
const MusicRules = preload("res://scripts/world/community_music_rules.gd")

static func state(world: RefCounted,score: Dictionary,pitches: Dictionary = {},preferred_root: String = "") -> Dictionary:
	var root: Dictionary = {}
	var family: Dictionary = {}
	var family_id := ""
	for raw_id in world.families:
		var candidate_family: Dictionary = world.families[raw_id]
		if not bool(candidate_family.get("player_expression",false)): continue
		var candidate: Dictionary = world.by_id.get(str(candidate_family.get("root","")),{})
		if candidate.is_empty() or str(candidate.get("family_id","")) != str(raw_id): continue
		if not preferred_root.is_empty() and str(candidate["district_id"]) != preferred_root: continue
		if not root.is_empty():
			var current_frame := int(root.get("birth_frame",0))
			var candidate_frame := int(candidate.get("birth_frame",0))
			var current_order := str(root["district_id"]).trim_prefix("building-").to_int()
			var candidate_order := str(candidate["district_id"]).trim_prefix("building-").to_int()
			if candidate_frame < current_frame or (candidate_frame == current_frame and candidate_order <= current_order): continue
		root = candidate
		family = candidate_family
		family_id = str(raw_id)
	if root.is_empty(): return {}
	var id := str(root["district_id"])
	var cid := str(root["community_id"])
	# The guide asks for qualification and growth facts every frame. Reusing the
	# same status/facility primitives as the opportunity UI keeps that query
	# cheap; the full opportunity tree also scans river pairs and role entries,
	# which is unnecessary for this small status contract.
	var qualification: Dictionary = MusicRules.status(world,cid)
	var facility: Dictionary = MusicRules.facilities(world,cid)
	var met: Array[String] = []
	var missing: Array[String] = []
	if bool(qualification["street_formed"]): met.append("街墙已成形")
	else: missing.append("继续沿街连片")
	if int(qualification["courtyards"]) > 0: met.append("已有公共内院")
	elif bool(qualification.get("public_anchor",false)): met.append("你建的公共空间已成为主题锚点")
	else: missing.append("围合一处内院")
	if int(qualification["mature"]) >= 6: met.append("六栋成熟房屋")
	else: missing.append("还需%d栋成熟房屋" % maxi(0,6-int(qualification["mature"])))
	var theme: Dictionary = score.get("theme",{})
	var owns_theme := str(theme.get("cid","")) == cid
	var current_midi := int(pitches.get(id,root["current_midi"]))
	var base_midi := int(root.get("base_midi",root["current_midi"]))
	var houses := 0
	for building in world.buildings:
		if str(building.get("family_id","")) == family_id: houses += 1
	var reservation_id := str(family.get("expression_reservation_id",""))
	if not world.planning_reservations.any(func(item: Dictionary) -> bool: return str(item.get("id","")) == reservation_id): reservation_id = ""
	return {"root_id":id,"family_id":family_id,"community_id":cid,"community_name":str(world.communities.get(cid,{}).get("name",cid)),
		"expression":str(family["expression"]),"position":root["position"].duplicate(),"form":str(root["form"]),
		"current_midi":current_midi,"base_midi":base_midi,"retuned":current_midi != base_midi,
		"theme_eligible":bool(qualification["theme_eligible"]),"theme_playing":owns_theme and not bool(score.get("muted_communities",{}).get(cid,false)),
		"root_in_theme":owns_theme and theme.get("source_ids",[]).has(id),"family_houses":houses,
		"next_growth_phrase":int(family.get("next_growth_phrase",-1)),"reservation_id":reservation_id,
		"mature":int(qualification["mature"]),"community_houses":int(qualification["members"]),
		"missing_conditions":missing,"met_conditions":met,
		"civic_support":bool(facility["civic"])}
