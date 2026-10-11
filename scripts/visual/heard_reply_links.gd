extends RefCounted
## Only a currently heard Reply may connect to a previously heard exact Lead.
## This short presentation history is separate from render-ahead schedules.
const Coupling = preload("res://scripts/world/world_coupling.gd")
const SHOW_SECONDS := 0.55
const HISTORY_SECONDS := 3.0
var heard_leads: Dictionary = {}
var last_frame := -1.0

func clear() -> void:
	heard_leads.clear()
	last_frame = -1.0

func _heard(row: Dictionary,frame: float) -> bool:
	return float(row["strength"]) > 0.000001 and int(row["onset"]) <= frame \
		and int(row["end_frame"]) > frame and int(row["render_start"]) <= frame \
		and int(row["render_end"]) > frame

func observe(rows: Array[Dictionary],world: RefCounted,frame: float,rate: float) -> Array[Dictionary]:
	if frame < last_frame: clear()
	last_frame = frame
	for id in heard_leads.keys():
		if int(heard_leads[id]["onset"]) < frame-rate*HISTORY_SECONDS: heard_leads.erase(id)
	for row in rows:
		if int(row["generation"]) != 0 or not _heard(row,frame): continue
		if not world.by_id.has(str(row["source_id"])): continue
		heard_leads[str(row["event_id"])] = row.duplicate()
	var result: Array[Dictionary] = []
	for row in rows:
		if int(row["generation"]) != 1 or not _heard(row,frame): continue
		var age := (frame-float(row["onset"]))/rate
		if age < 0.0 or age >= SHOW_SECONDS: continue
		var source_event := str(row["source_event_id"])
		if source_event.is_empty() or not heard_leads.has(source_event): continue
		var lead: Dictionary = heard_leads[source_event]
		if str(lead["source_id"]) != str(row["source_id"]) or int(lead["onset"]) != int(row["source_onset"]): continue
		if int(row["onset"]) <= int(lead["onset"]): continue
		var source: Dictionary = world.by_id.get(str(row["source_id"]),{})
		var receiver: Dictionary = world.by_id.get(str(row["receiver_id"]),{})
		if source.is_empty() or receiver.is_empty(): continue
		var from := Coupling.position_of(source)
		var to := Coupling.position_of(receiver)
		# A historical event relationship is insufficient after a move across
		# the river. Both endpoints must still be real houses on opposite banks.
		if signf(from.x-world.terrain.river_x(from.y))*signf(to.x-world.terrain.river_x(to.y)) >= 0.0: continue
		result.append({"event_id":str(row["event_id"]),"source_event_id":source_event,
			"source_id":str(row["source_id"]),"receiver_id":str(row["receiver_id"]),
			"source_onset":int(row["source_onset"]),"onset":int(row["onset"]),
			"generation":1,"from":from,"to":to,"age":age,"strength":float(row["strength"]),
			"authored":bool(source.get("player_expression",false)) and bool(receiver.get("player_expression",false))})
	return result
