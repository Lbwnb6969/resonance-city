class_name BoundaryDiagnosis
extends RefCounted
const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
var cfg: Dictionary = Values.load_values()["visual_diagnosis"]

func silence_reason(id: String, session: CityInterventions, synth: DistrictSynth, at: float) -> String:
	if not synth.active_layers.has("drone"): return "长音已关闭"
	if synth.gain == 0.0: return "混音静音"
	if bool(synth.muted.get(id,false)): return "Mute隔离"
	if not synth.solo_id.is_empty() and synth.solo_id != id: return "Solo隔离"
	if at < int(session.silent_until.get(id,0)): return "迁移静音"
	return ""

func edges(session: CityInterventions, synth: DistrictSynth, at: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pair in session.harmony.adjacency(session.city):
		var a := session._district(pair["a"])
		var b := session._district(pair["b"])
		var interval := session.harmony.interval(int(a["current_midi"]),int(b["current_midi"]))
		var distance := absi(int(a["current_midi"])-int(b["current_midi"])) % 12
		var difference := absf(synth.frequency(int(a["current_midi"]))-synth.frequency(int(b["current_midi"])))
		var kind: String = interval["relation"]
		var hz := 0.0
		if distance in [1,11] and difference >= float(cfg["slow_min_hz"]) and difference <= float(cfg["slow_max_hz"]):
			kind = "抖"
			hz = clampf(difference/float(cfg["frequency_divisor"]),float(cfg["display_min_hz"]),float(cfg["display_max_hz"]))
		elif distance == 6:
			kind = "刺"
		elif interval["relation"] not in ["协和","共鸣","中性"]:
			kind = "其它张力"
		var reason_a := silence_reason(pair["a"],session,synth,at)
		var reason_b := silence_reason(pair["b"],session,synth,at)
		var reason := reason_a if not reason_a.is_empty() else reason_b
		result.append({"a":pair["a"],"b":pair["b"],"cell_a":Schema.cell(a),"cell_b":Schema.cell(b),
			"midi_a":a["current_midi"],"midi_b":b["current_midi"],"kind":kind,"name":interval["name"],
			"relation":interval["relation"],"score":interval["score"],"beat_hz":difference,"display_hz":hz,
			"audible":reason.is_empty(),"silence_reason":reason})
	return result

func describe(rows: Array[Dictionary], selected: String) -> String:
	var lines := PackedStringArray()
	for edge in rows:
		if edge["a"] != selected and edge["b"] != selected: continue
		var other: String = edge["b"] if edge["a"] == selected else edge["a"]
		var cell: Vector2i = edge["cell_b"] if edge["a"] == selected else edge["cell_a"]
		var midi: int = edge["midi_b"] if edge["a"] == selected else edge["midi_a"]
		var hint := " · 基频差 %.2fHz" % edge["beat_hz"] if edge["kind"] == "抖" else ""
		var silent := " · 当前不可听（%s）" % edge["silence_reason"] if not edge["audible"] else ""
		lines.append("邻居 %s (%d,%d) MIDI%d：%s · %s%s%s" % [other,cell.x,cell.y,midi,edge["name"],edge["kind"],hint,silent])
	return "\n".join(lines) if not lines.is_empty() else "无声学邻接；成路的共享边不参与。"
