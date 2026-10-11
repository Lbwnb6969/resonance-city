extends RefCounted
## Three real next-phrase transactions use one city, phase, boundary and gain.
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const CONTRACT := "P12-EXPRESSION-COMPARE/v1"
const SECONDS := 4

static func source_key(source: ContinuousAudioModel,position: Variant,state: Dictionary,at: int) -> String:
	var p: Array = [position.x,position.y] if position is Vector2 else position.duplicate()
	return str(hash([source.capture_state(),p,state,at]))

static func _birth(world: ContinuousWorld,operation: Dictionary,boundary: int) -> Dictionary:
	for family in world.families.values():
		if not bool(family.get("player_expression",false)) or str(family.get("expression","")) != str(operation["expression"]): continue
		var root: Dictionary = world.by_id.get(str(family.get("root","")),{})
		if int(root.get("birth_frame",-1)) == boundary and root.get("position",[]) == operation["position"]:
			return {"building":root.duplicate(true),"family":family.duplicate(true)}
	return {}

static func _metrics(model: ContinuousAudioModel,begin: int,count: int,rate: int,cid: String) -> Dictionary:
	var pulses: Array[Dictionary] = []
	var leads: Array[Dictionary] = []
	var profiles: Array[Dictionary] = []
	for part in model.synth.rhythms:
		if str(part["cid"]) != cid: continue
		profiles.append(model.synth.rhythm_profile(part,rate))
		pulses.append_array(model.synth.rhythm_events(part,begin,count,rate))
	for node in model.synth.musical_nodes.values():
		if not bool(node.get("active",false)) or str(node["part"]["cid"]) != cid: continue
		leads.append_array(model.synth.musical_events(node,begin,count,rate))
	return {"rhythm_profiles":profiles,"pulse_events":pulses,"musical_events":leads}

static func build(source: ContinuousAudioModel,position: Variant,state: Dictionary,at: int) -> Dictionary:
	var rate := int(source.world.cfg["timing"]["sample_rate"])
	var boundary := source.next_boundary
	var p: Array = [position.x,position.y] if position is Vector2 else position.duplicate()
	var result := {"contract":CONTRACT,"source_frame":at,"boundary_frame":boundary,"sample_rate":rate,
		"gain":source.synth.gain,"seconds":SECONDS,"duration_frames":rate*SECONDS,"source_key":source_key(source,p,state,at),"position":p,"variants":{}}
	for choice: String in PlayerExpression.IDS:
		var operation := PlayerExpression.operation(choice,p)
		var branch := source.freeze()
		var phases := state.duplicate(true)
		branch.rendered_until = at
		# World.request owns replacement semantics. Independent charter, anchor,
		# retune and reservation intent remain identical to formal submission.
		var request := branch.submit(operation)
		var variant := {"accepted":false,"reason":str(request.get("reason","")),"operation":operation,"pcm":PackedByteArray(),
			"score":{},"opportunities":[],"birth":{},"consequences":{},"metrics":{},"peak":0.0,"max_voices":0}
		result["variants"][choice] = variant
		if not bool(request.get("accepted",false)): continue
		for begin in range(at,boundary,512): branch.render_block(phases,begin,mini(512,boundary-begin),rate)
		var samples := branch.render_block(phases,boundary,rate*SECONDS,rate)
		var birth := _birth(branch.world,operation,boundary)
		if birth.is_empty():
			variant["reason"] = "同句规划占用了这块地，请重新选落点"
			continue
		var cid := str(birth["building"]["community_id"])
		var status := Rules.status(branch.world,cid)
		var children := 0
		for building in branch.world.buildings:
			if str(building.get("family_id","")) == str(birth["building"]["family_id"]): children += 1
		variant["accepted"] = true
		variant["reason"] = ""
		variant["pcm"] = Renderer.pcm16(samples)
		variant["birth"] = birth
		variant["score"] = branch.synth.score_snapshot()
		variant["opportunities"] = [Rules.opportunity(branch.world,cid,variant["score"])]
		variant["consequences"] = {"community_id":cid,"type":birth["building"]["type"],"expression":branch.world.community_expression(cid),
			"next_growth_phrase":int(birth["family"].get("next_growth_phrase",-1)),"family_buildings":children,
			"city_buildings":branch.world.buildings.size(),"mature":status["mature"],"theme_eligible":status["theme_eligible"],"reservations":[],"reservation_count":0}
		var reservation_id := str(birth["family"].get("expression_reservation_id",""))
		for reservation in branch.world.planning_reservations:
			if not reservation_id.is_empty() and str(reservation.get("id","")) == reservation_id:
				variant["consequences"]["reservations"].append(reservation.duplicate(true))
		variant["consequences"]["reservation_count"] = variant["consequences"]["reservations"].size()
		variant["metrics"] = _metrics(branch,boundary,rate*SECONDS,rate,cid)
		variant["max_voices"] = branch.synth.max_voice_count
		for sample in samples: variant["peak"] = maxf(float(variant["peak"]),maxf(absf(sample.x),absf(sample.y)))
	return result
