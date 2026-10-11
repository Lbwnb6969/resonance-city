extends RefCounted
## Both decisions share the captured city, phases and upcoming phrase.
const Rework = preload("res://scripts/world/transit_line_rework.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const CONTRACT := "P12-TRANSIT-REWORK-COMPARE/v1"

static func _line(world: RefCounted,line_id: String) -> Dictionary:
	for line in world.transit_lines:
		if str(line.get("id","")) == line_id: return line
	return {}

static func _add_communities(ids: Array[String],coverage: Dictionary) -> void:
	for raw_id in coverage.get("community_ids",[]):
		var cid := str(raw_id)
		if not cid.is_empty() and not ids.has(cid): ids.append(cid)

static func _rejected(reason: String) -> Dictionary:
	return {"accepted":false,"reason":reason,"pcm":PackedByteArray(),"coverage":{},"opportunities":[],"score":{}}

static func _pcm_difference(a: PackedByteArray,b: PackedByteArray) -> float:
	var difference := 0.0
	for offset in range(0,mini(a.size(),b.size()),2):
		difference = maxf(difference,absf(float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0))
	return difference

static func build(source: ContinuousAudioModel,operation: Dictionary,state: Dictionary,at: int) -> Dictionary:
	var rate := int(source.world.cfg["timing"]["sample_rate"])
	var boundary := source.next_boundary
	var line_id := str(operation.get("edit_id",""))
	var keep := {"kind":"transit_line","keep":true,"edit_id":line_id,
		"source_revision":str(operation.get("source_revision","")),"source_topology":str(operation.get("source_topology",""))}
	var result := {"contract":CONTRACT,"source_frame":at,"boundary_frame":boundary,"sample_rate":rate,
		"gain":source.synth.gain,"seconds":3,"line_id":line_id,"source_revision":keep["source_revision"],
		"source_topology":keep["source_topology"],"variants":{},"pcm_changed":false,"max_pcm_abs_diff":0.0}
	var affected: Array[String] = []
	var branch_worlds: Dictionary = {}
	_add_communities(affected,_line(source.world,line_id).get("coverage",{}))
	var draft := Rework.preview(source.world,operation)
	if bool(draft.get("accepted",false)):
		_add_communities(affected,draft.get("old_coverage",{}))
		_add_communities(affected,draft.get("new_coverage",{}))
	for choice: String in ["keep","edit"]:
		var branch := source.freeze()
		var phases := state.duplicate(true)
		# Remove only this line's earlier edit in both branches. All independent
		# pending decisions and real, uncommitted passenger observations survive.
		var request := branch.submit(keep)
		if bool(request.get("accepted",false)) and choice == "edit": request = branch.submit(operation)
		if not bool(request.get("accepted",false)):
			result["variants"][choice] = _rejected(str(request.get("reason","线路来源已变化，请重新选择")))
			continue
		for begin in range(at,boundary,512): branch.render_block(phases,begin,mini(512,boundary-begin),rate)
		var samples := branch.render_block(phases,boundary,rate*3,rate)
		var line := _line(branch.world,line_id)
		var accepted := not line.is_empty()
		var reason := "" if accepted else "下一句没有这条线路，请重新选择"
		if choice == "edit":
			var committed := branch.world.events.any(func(event: Dictionary) -> bool:
				return str(event.get("kind","")) == "transit_line" and bool(event.get("edit",false)) and str(event.get("id","")) == line_id and int(event.get("event_id",-1)) == int(request.get("event_id",-2)) and int(event.get("frame",-1)) == boundary)
			accepted = accepted and committed
			if not committed: reason = "同句规划冲突，改站未落定"
		if not accepted:
			result["variants"][choice] = _rejected(reason)
			continue
		# Route derivation precedes passenger commitment in this settlement.
		# Re-read current demand and roles after that commitment, using the real
		# route but excluding its older, derived music-feedback cache.
		var coverage_source := line.duplicate(true)
		coverage_source.erase("music_feedback")
		var coverage: Dictionary = branch.world.transit_line_coverage_summary(coverage_source)
		_add_communities(affected,coverage)
		var peak := 0.0
		for sample in samples: peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		result["variants"][choice] = {"accepted":true,"reason":"","pcm":Renderer.pcm16(samples),
			"coverage":coverage,"line":line.duplicate(true),"revision":int(line.get("edit_revision",0)),
			"score":branch.synth.score_snapshot(),"opportunities":[],"community_ids":[],
			"music_feedback":branch.world.transit_music_feedback(line_id),"peak":peak,"max_voices":branch.synth.max_voice_count}
		branch_worlds[choice] = branch.world
	affected.sort()
	for choice: String in result["variants"]:
		var variant: Dictionary = result["variants"][choice]
		if not bool(variant.get("accepted",false)): continue
		var world: RefCounted = branch_worlds[choice]
		for cid in affected:
			if world.communities.has(cid):
				variant["community_ids"].append(cid)
				variant["opportunities"].append(Rules.opportunity(world,cid,variant["score"]))
	var original: Dictionary = result["variants"]["keep"]
	var edited: Dictionary = result["variants"]["edit"]
	if bool(original["accepted"]) and bool(edited["accepted"]):
		result["pcm_changed"] = original["pcm"] != edited["pcm"]
		result["max_pcm_abs_diff"] = _pcm_difference(original["pcm"],edited["pcm"])
	return result
