extends RefCounted
## Ephemeral P11 comparison. Every branch starts from one private model and PCM state.
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
static func identity(model: ContinuousAudioModel,site: Dictionary) -> Array:
	return [Charter.version(model.world),model.next_boundary,site.get("source_site_id",""),site.get("polygon",PackedVector2Array()),
		hash(model.world.pending_actions),hash(model.sound_events),hash(model.sound_overrides),
		model.synth.focused_community,model.synth.listener_community,hash(model.synth.muted_communities),model.synth.gain,hash(model.synth.score)]

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
		if kind != "none": request = branch.submit({"kind":kind,"position":site["position"].duplicate()})
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
		for public_site in branch.world.public_sites:
			if str(public_site.get("source_site_id","")) == str(site["source_site_id"]) and public_site.get("kind","") == kind and public_site.get("active",false):
				anchor = public_site.duplicate(true)
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
		var cids: Array = [str(site["community_id"])]
		for id in anchor.get("served",[]):
			var cid := str(branch.world.by_id[id]["community_id"])
			if not cids.has(cid): cids.append(cid)
		for cid in cids: opportunities.append(Rules.opportunity(branch.world,cid,score))
		var births: Array = branch.world.events.filter(func(e:Dictionary)->bool:
			return e.get("kind","") == "birth" and int(e.get("frame",-1)) == boundary).map(func(e:Dictionary)->Variant:return e["district_id"])
		var peak := 0.0
		for sample in pcm: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		result["variants"][kind] = {"accepted":accepted,"reason":"" if accepted else "同句规划冲突，落定时未提交",
			"pcm":Renderer.pcm16(pcm) if accepted else PackedByteArray(),"anchor":anchor,"opportunities":opportunities,
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
