extends RefCounted
## Runtime-only envelopes for rhythm pulses owned by a public facility.
## This is separate from Lead/Reply activity so existing house mark contracts
## keep their exact identity set.

const MAX_SEGMENTS := 512
const WINDOW_SECONDS := 4.0
const PULSE_SECONDS := 0.24
const MIN_STRENGTH := 0.000001
var segments: Array[Dictionary] = []
var rendered_until := 0
var window_start := 0

func capture(rows: Array[Dictionary],start: int,count: int,rate: int,duck: float,duck_target: float,duck_step: float) -> void:
	rendered_until = maxi(rendered_until,start+count)
	for row in rows:
		if int(row.get("render_start",start)) >= int(row.get("render_end",start)): continue
		var copy := row.duplicate(true)
		copy["duck_from"] = duck
		copy["duck_target"] = duck_target
		copy["duck_step"] = duck_step
		segments.append(copy)
	var cutoff := rendered_until-roundi(rate*WINDOW_SECONDS)
	window_start = maxi(0,cutoff)
	var retained: Array[Dictionary] = []
	for segment in segments:
		if int(segment.get("render_end",0)) > cutoff: retained.append(segment)
	if retained.size() > MAX_SEGMENTS: retained = retained.slice(retained.size()-MAX_SEGMENTS)
	segments = retained

func audible(audible_frame: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var frame := floori(audible_frame)
	if frame < window_start or frame >= rendered_until: return result
	var events: Dictionary = {}
	for segment in segments:
		if frame < int(segment.get("render_start",0)) or frame >= int(segment.get("render_end",0)): continue
		var seconds := float(frame-int(segment["onset"]))/float(segment["rate"])
		if seconds < 0.0 or seconds >= PULSE_SECONDS: continue
		var elapsed := frame-int(segment["level_frame"])+1
		var level := move_toward(float(segment["level_from"]),float(segment["target"]),float(segment["fade_step"])*elapsed)
		var duck := move_toward(float(segment["duck_from"]),float(segment["duck_target"]),float(segment["duck_step"])*elapsed)
		var envelope := minf(1.0,seconds/0.006)*exp(-seconds/0.075)*clampf((PULSE_SECONDS-seconds)/0.01,0.0,1.0)
		var strength := envelope*level*float(segment["amplitude"])*float(segment["stereo_gain"])*duck
		if strength <= MIN_STRENGTH: continue
		var id := str(segment["event_id"])
		if events.has(id):
			events[id]["strength"] = float(events[id]["strength"])+strength
			events[id]["render_start"] = mini(int(events[id]["render_start"]),int(segment["render_start"]))
			events[id]["render_end"] = maxi(int(events[id]["render_end"]),int(segment["render_end"]))
			var site_ids: Array = segment.get("public_site_ids",[])
			var site_kinds: Array = segment.get("public_site_kinds",[])
			for index in range(site_ids.size()):
				if site_ids[index] in events[id]["public_site_ids"]: continue
				events[id]["public_site_ids"].append(site_ids[index])
				events[id]["public_site_kinds"].append(site_kinds[index])
		else:
			var event := {"event_id":id,"onset":int(segment["onset"]),"end_frame":int(segment["onset"])+roundi(PULSE_SECONDS*float(segment["rate"])),
				"render_start":int(segment["render_start"]),"render_end":int(segment["render_end"]),"pitch":int(segment["midi"]),
				"public_site_ids":segment.get("public_site_ids",[]).duplicate(true),"public_site_kinds":segment.get("public_site_kinds",[]).duplicate(true),
				"strength":strength,"rhythm":true}
			events[id] = event
	for event in events.values(): result.append(event)
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return int(a["onset"]) < int(b["onset"]))
	return result
