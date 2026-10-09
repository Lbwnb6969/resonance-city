extends RefCounted
## Stateless event oscillators plus a saved reveal schedule; never touch RNG or drone phase.
static var waveform_cache: Dictionary = {}

static func waveform(midi: int, rate: int, cfg: Dictionary, prefix: String) -> PackedFloat64Array:
	var key := "%d:%d:%s:%s" % [midi,rate,prefix,JSON.stringify(cfg)]
	if waveform_cache.has(key): return waveform_cache[key]
	var hz := 440.0*pow(2.0,(midi-69.0)/12.0)
	var result := PackedFloat64Array()
	result.resize(ceili(float(cfg[prefix+"_tail"])*rate))
	for at in range(result.size()): result[at] = event_sample(float(at)/rate,hz,cfg,prefix)
	waveform_cache[key] = result
	return result

static func prepare(values: Dictionary, rate: int) -> void:
	# Finite legal pitches are warmed before playback, never on a growth boundary.
	var cfg: Dictionary = values["stage_audio"]
	for midi in values["proposals"]["allowed_pitches"]:
		for offset in cfg["ornament_intervals"]: waveform(int(midi)+int(offset),rate,cfg,"ornament")
		waveform(int(midi)+int(cfg["bell_interval"]),rate,cfg,"bell")

static func applies(d: Dictionary) -> bool:
	return not bool(d.get("is_anchor",false)) and not str(d.get("anchor_id","")).is_empty()

static func initial(d: Dictionary) -> Dictionary:
	if not applies(d): return {}
	var form: String = d.get("form","胚")
	var key := 0
	for byte in str(d["district_id"]).to_utf8_buffer(): key += byte
	return {"form":form,"previous":form,"change_frame":-1,"rhythm_start":-1,"pattern":key}

static func sync(stage: Dictionary, event: Dictionary) -> void:
	if stage.is_empty() or event.get("kind","") != "upgrade": return
	stage["previous"] = stage["form"]
	stage["form"] = event["form"]
	stage["change_frame"] = int(event["frame"])
	if stage["previous"] == "胚": stage["rhythm_start"] = int(event["frame"])

static func form_at(stage: Dictionary, at: int) -> String:
	return str(stage["previous"] if at < int(stage["change_frame"]) else stage["form"])

static func rhythm_level(stage: Dictionary, at: int, rate: int, values: Dictionary) -> float:
	if stage.is_empty(): return 1.0
	if form_at(stage,at) == "胚": return 0.0
	if int(stage["rhythm_start"]) < 0: return 1.0
	var duration := float(values["stage_audio"]["fade_beats"])*60.0*rate/float(values["timing"]["bpm"])
	return sin(PI/2.0*clampf(float(at-int(stage["rhythm_start"]))/duration,0.0,1.0))

static func event_sample(seconds: float, hz: float, cfg: Dictionary, prefix: String) -> float:
	var tail := float(cfg[prefix+"_tail"])
	if seconds < 0.0 or seconds >= tail: return 0.0
	var attack := float(cfg[prefix+"_attack"])
	var envelope := minf(1.0,seconds/attack)*exp(-seconds/float(cfg[prefix+"_decay"]))*clampf((tail-seconds)/attack,0.0,1.0)
	var partials: Array = cfg["event_partials"]
	return envelope*(sin(TAU*hz*seconds)*float(partials[0])+sin(2.0*TAU*hz*seconds)*float(partials[1]))/(float(partials[0])+float(partials[1]))*float(cfg[prefix+"_gain"])

static func event_info(stage: Dictionary, midi: int, at: int, rate: int, values: Dictionary, bell: bool) -> Dictionary:
	var cfg: Dictionary = values["stage_audio"]
	var bars := int(values["timing"]["bars_per_phrase"]) if bell else int(cfg["ornament_bars"])
	var period := roundi(60.0*rate/float(values["timing"]["bpm"])*int(values["timing"]["beats_per_bar"])*bars)
	var cycle := floori(float(at)/period)
	var onset := cycle*period
	var form := form_at(stage,onset)
	if (bell and form != "腔") or (not bell and form not in ["央","腔"]): return {}
	var offset := int(cfg["bell_interval"]) if bell else int(cfg["ornament_intervals"][posmod(int(stage["pattern"])+cycle,3)])
	return {"onset":onset,"midi":midi+offset,"prefix":"bell" if bell else "ornament"}

static func sample(stage: Dictionary, midi: int, at: int, rate: int, values: Dictionary) -> float:
	if stage.is_empty(): return 0.0
	var result := 0.0
	for bell in [false,true]:
		var info := event_info(stage,midi,at,rate,values,bell)
		if info.is_empty(): continue
		var wave := waveform(int(info["midi"]),rate,values["stage_audio"],info["prefix"])
		var elapsed := at-int(info["onset"])
		if elapsed >= 0 and elapsed < wave.size(): result += wave[elapsed]
	return result

static func block(stage: Dictionary, midi: int, start: int, count: int, rate: int, values: Dictionary) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	if stage.is_empty(): return result
	# Only event tails cost DSP; ordinary buffer fills allocate no event array.
	for bell in [false,true]:
		var cfg: Dictionary = values["stage_audio"]
		var bars := int(values["timing"]["bars_per_phrase"]) if bell else int(cfg["ornament_bars"])
		var period := roundi(60.0*rate/float(values["timing"]["bpm"])*int(values["timing"]["beats_per_bar"])*bars)
		var onset := floori(float(start)/period)*period
		while onset < start+count:
			var info := event_info(stage,midi,onset,rate,values,bell)
			if not info.is_empty():
				var end := mini(start+count,onset+ceili(float(cfg[str(info["prefix"])+"_tail"])*rate))
				var begin := maxi(start,onset)
				if begin < end:
					if result.is_empty(): result.resize(count)
					var wave := waveform(int(info["midi"]),rate,cfg,info["prefix"])
					for at in range(begin,end): result[at-start] += wave[at-onset]
			onset += period
	return result
