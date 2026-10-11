extends RefCounted
## Runtime-only envelopes of Lead/Response events actually mixed into PCM.
## Adjacent render chunks share one segment until a listening/gain ramp changes.

const MAX_SEGMENTS := 512
const WINDOW_SECONDS := 4.0
const MIN_STRENGTH := 0.000001
var segments: Array[Dictionary] = []
var tails: Dictionary = {}
var rendered_until := 0
var window_start := 0

static func _ramp(initial: float,target: float,step: float,samples: int) -> float:
	return move_toward(initial,target,step*maxi(0,samples))

func capture(rows: Array[Dictionary],start: int,count: int,rate: int,duck: float,duck_target: float,duck_step: float) -> void:
	rendered_until = maxi(rendered_until,start+count)
	for row in rows:
		if maxf(float(row["level_from"]),float(row["target"])) <= 0.0 or float(row["amplitude"]) <= 0.0 or float(row["stereo_gain"]) <= 0.0: continue
		row["duck_from"] = duck
		row["duck_target"] = duck_target
		row["duck_step"] = duck_step
		var key := str(row["node_key"])+":"+str(row["event_id"])
		var previous: Dictionary = tails.get(key,{})
		var merge := not previous.is_empty() and int(previous["render_end"]) == int(row["render_start"])
		for field in ["target","fade_step","amplitude","stereo_gain","expression","rate","duck_target","duck_step","public_site_ids","public_site_kinds"]:
			if merge and previous[field] != row[field]: merge = false
		if merge:
			var distance := int(row["level_frame"])-int(previous["level_frame"])
			merge = absf(_ramp(float(previous["level_from"]),float(previous["target"]),float(previous["fade_step"]),distance)-float(row["level_from"])) < 0.000000001 \
				and absf(_ramp(float(previous["duck_from"]),float(previous["duck_target"]),float(previous["duck_step"]),distance)-duck) < 0.000000001
		if merge:
			previous["render_end"] = row["render_end"]
		else:
			segments.append(row)
			tails[key] = row
	# Bound both history duration and storage even for unusual render chunking.
	var cutoff := rendered_until-roundi(rate*WINDOW_SECONDS)
	window_start = maxi(0,cutoff)
	var retained: Array[Dictionary] = []
	for segment in segments:
		if int(segment["render_end"]) > cutoff: retained.append(segment)
	if retained.size() > MAX_SEGMENTS: retained = retained.slice(retained.size()-MAX_SEGMENTS)
	if retained.size() != segments.size():
		segments = retained
		tails.clear()
		for segment in segments: tails[str(segment["node_key"])+":"+str(segment["event_id"])] = segment

func audible(audible_frame: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var frame := floori(audible_frame)
	if frame < window_start or frame >= rendered_until: return result
	var events: Dictionary = {}
	for segment in segments:
		if frame < int(segment["render_start"]) or frame >= int(segment["render_end"]): continue
		var seconds := float(frame-int(segment["onset"]))/float(segment["rate"])
		var tail := 0.95 if str(segment["expression"]) == "deep" else 0.65
		var envelope := minf(1.0,seconds/0.012)*exp(-seconds/(0.35 if str(segment["expression"]) == "deep" else 0.20))*clampf((tail-seconds)/0.03,0.0,1.0)
		var distance := frame-int(segment["level_frame"])+1
		var level := _ramp(float(segment["level_from"]),float(segment["target"]),float(segment["fade_step"]),distance)
		var duck := _ramp(float(segment["duck_from"]),float(segment["duck_target"]),float(segment["duck_step"]),distance)
		var strength := envelope*level*float(segment["amplitude"])*float(segment["stereo_gain"])*duck
		if strength <= MIN_STRENGTH: continue
		var id := str(segment["event_id"])
		if events.has(id):
			events[id]["strength"] = float(events[id]["strength"])+strength
			events[id]["render_start"] = mini(int(events[id]["render_start"]),int(segment["render_start"]))
			events[id]["render_end"] = maxi(int(events[id]["render_end"]),int(segment["render_end"]))
			# A lifecycle can span a runtime-only public-site refresh. Preserve every
			# authored site represented by the audible event while keeping one event row.
			var site_ids: Array = segment.get("public_site_ids",[])
			var site_kinds: Array = segment.get("public_site_kinds",[])
			for index in range(site_ids.size()):
				if site_ids[index] in events[id]["public_site_ids"]: continue
				events[id]["public_site_ids"].append(site_ids[index])
				events[id]["public_site_kinds"].append(site_kinds[index])
		else:
			var event: Dictionary = {}
			for field in ["event_id","source_event_id","source_id","receiver_id","generation","source_onset","onset","end_frame","pitch","cid","render_start","render_end"]: event[field] = segment[field]
			for field in ["public_site_ids","public_site_kinds"]: event[field] = segment.get(field,[]).duplicate()
			event["strength"] = strength
			events[id] = event
	for event in events.values(): result.append(event)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if int(a["onset"]) != int(b["onset"]): return int(a["onset"]) < int(b["onset"])
		return str(a["event_id"]) < str(b["event_id"]))
	return result
