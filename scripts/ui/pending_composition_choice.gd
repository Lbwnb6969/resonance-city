extends RefCounted
## A confirmed first-composition choice waits for the device, not render-ahead.
## This query owns no state and never submits, settles, or advances presentation.
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Fabric = preload("res://scripts/world/fabric_relations.gd")

static func state(demo) -> Dictionary:
	if not bool(demo.first_composition_mode) or demo.model == null: return {}
	var transport = demo.clock.renderer.transport
	var frame := float(transport.audible_frame)
	var choice := _expression(demo,frame)
	if choice.is_empty(): choice = _public(demo,frame)
	if choice.is_empty(): return {}
	var boundary := int(choice["boundary_frame"])
	var phrase_frames := int(demo.model.phrase_frames)
	var beat_frames := int(demo.model.beat_frames)
	var rate := float(transport.sample_rate)
	choice["progress"] = clampf((frame-float(boundary-phrase_frames))/float(phrase_frames),0.0,1.0)
	choice["time_to_boundary"] = (float(boundary)-frame)/rate
	choice["beats_to_boundary"] = (float(boundary)-frame)/float(beat_frames)
	choice["beat_progress"] = fposmod(frame,float(beat_frames))/float(beat_frames)
	var cid := str(choice["community_id"])
	choice["community"] = str(demo.model.world.communities.get(cid,{}).get("name",cid))
	return choice

static func _expression(demo,frame: float) -> Dictionary:
	var layer = demo.expression_audition_layer
	var accepted: Dictionary = demo.get("pending_expression_choice")
	var boundary := -1
	var event_id := -1
	var expression := ""
	var position := Vector2.ZERO
	var cid := ""
	if not accepted.is_empty() and accepted.get("source_model") == demo.model:
		# Formal confirmation does not require its preview worker to have returned.
		# The owner retains only the accepted transaction's runtime identity.
		var operation: Dictionary = accepted["operation"]
		boundary = int(accepted["boundary_frame"])
		event_id = int(accepted["event_id"])
		expression = str(operation["expression"])
		position = _position(operation["position"])
	elif layer.source_model == demo.model and not layer.queued.is_empty():
		boundary = int(layer.queued_boundary)
		event_id = int(layer.queued_event)
		var birth: Dictionary = layer.queued["birth"]
		var building: Dictionary = birth["building"]
		var family: Dictionary = birth["family"]
		expression = str(building.get("expression",family.get("expression","")))
		position = _position(building["position"])
		cid = str(building["community_id"])
	else: return {}
	if boundary < 0 or frame >= float(boundary) or _rejected(demo.model.world,event_id,boundary): return {}
	var confirmed := false
	for op: Dictionary in demo.model.world.pending_actions:
		if str(op.get("kind","")) == "seed" and bool(op.get("player_expression",false)) and int(op.get("event_id",-1)) == event_id and int(op.get("frame",-1)) == boundary and str(op.get("expression","")) == expression and _position(op["position"]) == position:
			confirmed = true
			cid = Fabric.community_for_position(demo.model.world,position)
			break
	if not confirmed:
		# The renderer can have adopted the birth while its PCM is still queued.
		# Match real authorship, time and land, rather than a predicted next_id.
		for root: Dictionary in demo.model.world.buildings:
			if bool(root.get("player_expression",false)) and bool(root.get("family_anchor",false)) and int(root.get("birth_frame",-1)) == boundary and str(root.get("expression","")) == expression and _position(root["position"]) == position:
				confirmed = true
				cid = str(root["community_id"])
				break
	if not confirmed: return {}
	return {"kind":expression,"choice":expression,"label":str(PlayerExpression.definition(expression)["label"]),
		"community_id":cid,"boundary_frame":boundary,"event_id":event_id,"position":position}

static func _public(demo,frame: float) -> Dictionary:
	var action: Dictionary = demo.planning_guide.next_action
	if not bool(action.get("first_composition_anchor",false)) or str(action.get("state","")) not in ["queued","ready"]: return {}
	var kind := str(action.get("choice",""))
	if kind not in ["none","park","civic","reserve"]: return {}
	var boundary := int(action.get("expected_boundary_frame",-1))
	if boundary < 0 or frame >= float(boundary): return {}
	var event_id := int(action.get("event_id",-1))
	var cid := str(action.get("community_id",""))
	var world = demo.model.world
	if _rejected(world,event_id,boundary): return {}
	var record := _public_record(world,action,boundary)
	if record.is_empty(): return {}
	var position := _position(record["position"]) if record.has("position") else _community_position(world,cid)
	return {"kind":kind,"choice":kind,"label":str({"none":"暂不建设","park":"公园","civic":"文化馆","reserve":"留地"}[kind]),
		"community_id":cid,"boundary_frame":boundary,"event_id":event_id,"position":position}

static func _public_record(world,action: Dictionary,boundary: int) -> Dictionary:
	var kind := str(action["choice"])
	for op: Dictionary in world.pending_actions:
		if int(op.get("frame",-1)) != boundary: continue
		if kind == "none":
			if str(op.get("kind","")) == "charter" and "charter-%05d" % int(op.get("event_id",-1)) == str(action.get("charter_id","")) and op.get("community_ids",[]).has(str(action["community_id"])): return op
		elif str(op.get("kind","")) == kind and int(op.get("event_id",-2)) == int(action.get("event_id",-1)): return op
	if kind == "none":
		for charter: Dictionary in world.development_charters:
			if str(charter["charter_id"]) == str(action.get("charter_id","")) and int(charter["committed_phrase"])*int(world.cfg["timing"]["phrase_frames"]) == boundary and charter["community_ids"].has(str(action["community_id"])): return charter
	elif kind == "reserve":
		for reservation: Dictionary in world.planning_reservations:
			if str(reservation.get("reservation_id",reservation.get("id",""))) == str(action.get("public_id","")) and int(reservation.get("created_phrase",-1))*int(world.cfg["timing"]["phrase_frames"]) == boundary: return reservation
	else:
		for site: Dictionary in world.public_sites:
			if str(site["id"]) == str(action.get("public_id","")) and bool(site.get("active",false)) and str(site["kind"]) == kind and int(site.get("frame",-1)) == boundary: return site
	return {}

static func _rejected(world,event_id: int,boundary: int) -> bool:
	if event_id < 0: return false
	for event: Dictionary in world.events:
		if str(event.get("kind","")) == "planning_rejected" and int(event.get("event_id",-2)) == event_id and int(event.get("frame",-1)) == boundary: return true
	return false

static func _community_position(world,cid: String) -> Vector2:
	var ids: Array = world.communities.get(cid,{}).get("members",[])
	var center := Vector2.ZERO
	for id in ids: center += _position(world.by_id[str(id)]["position"])
	return center/float(ids.size()) if not ids.is_empty() else Vector2.ZERO

static func _position(raw: Array) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1]))
