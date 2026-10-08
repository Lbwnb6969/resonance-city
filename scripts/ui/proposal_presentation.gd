class_name ProposalPresentation
extends RefCounted

const Harmony = preload("res://scripts/city/harmony.gd")
const Values = preload("res://scripts/spec_values.gd")

static func edge_map(city: Array, edges: Array) -> Dictionary:
	var ids: Dictionary = {}
	for district in city:
		ids[district["district_id"]] = district
	var result: Dictionary = {}
	var harmony := Harmony.new()
	for edge in edges:
		var pair := [str(edge["a"]),str(edge["b"])]
		pair.sort()
		var a: Dictionary = ids[pair[0]]
		var b: Dictionary = ids[pair[1]]
		result[" / ".join(pair)] = harmony.interval(int(a["current_midi"]),int(b["current_midi"]))
	return result

static func describe(result: Dictionary) -> Dictionary:
	var old := edge_map(result["before"],result["before_edges"])
	var next := edge_map(result["after"],result["after_edges"])
	var changed: Array[String] = []
	for key in old:
		if not next.has(key):
			changed.append("失去邻接 %s：%s（每方活力 %+.1f）" % [key,old[key]["name"],old[key]["vitality_delta"]])
		elif old[key] != next[key]:
			changed.append("音程变化 %s：%s → %s（每方活力 %+.1f → %+.1f）" % [key,old[key]["name"],next[key]["name"],old[key]["vitality_delta"],next[key]["vitality_delta"]])
	for key in next:
		if not old.has(key):
			changed.append("新增邻接 %s：%s（每方活力 %+.1f）" % [key,next[key]["name"],next[key]["vitality_delta"]])
	var vitality: Array[String] = []
	var old_by_id: Dictionary = {}
	for d in result["before"]:
		old_by_id[d["district_id"]] = d
	for after in result["after"]:
		var before: Dictionary = old_by_id.get(after["district_id"],{})
		vitality.append("%s：新生 %.1f" % [after["district_id"],after["vitality"]] if before.is_empty() else "%s：%.1f → %.1f" % [after["district_id"],before["vitality"],after["vitality"]])
	var choice: Dictionary = result["choice"]
	var values := Values.load_values()
	var params: Dictionary = values["proposals"]
	var phrase_seconds := 60.0 / float(values["timing"]["bpm"]) * int(values["timing"]["beats_per_bar"]) * int(values["timing"]["bars_per_phrase"])
	var cost := "改造 %+.0f 活力" % params["retune_cost"] if choice.get("verb") == "retune" else "该街区静音 %d 乐句（%.0f 秒）；原邻居失去相应关系" % [params["relocate_silent_phrases"],phrase_seconds*int(params["relocate_silent_phrases"])]
	if choice.get("verb") == "release":
		cost = "共鸣点占1格；下一乐句参与和声并吸引生长"
	if choice.get("verb") == "tread":
		cost = "足迹 %d/%d；无固定R/V扣除" % [choice["tread_count"],values["tread"]["threshold"]]
		if choice["formed"]: cost += "；成路后本局不可撤销，切断该边邻接；家族断连%d栋" % choice["disconnected"].size()
	if choice.get("on_grid",false) and choice.get("verb") not in ["release","draft","tread"]:
		cost += "；含可选卡拍 %+.0f" % params["landing_bonus"]
	var text := "预期 R：%.2f → %.2f\n代价：%s\n下个乐句活力：%s\n%s" % [
		result["before_r"],result["after_r"],cost,"；".join(vitality),
		"\n".join(changed) if not changed.is_empty() else "邻接不变"]
	return {"text":text,"cost":cost,"before_r":result["before_r"],"after_r":result["after_r"],
		"old_edges":old,"new_edges":next,"changes":changed,"vitality":vitality,"choice":choice.duplicate(true)}


static func summary(result: Dictionary) -> String:
	var full := describe(result)
	var id: String = result["choice"].get("district_id","")
	var before_v := 0.0
	var after_v := 0.0
	for d in result["before"]:
		if d["district_id"] == id: before_v = float(d["vitality"])
	for d in result["after"]:
		if d["district_id"] == id: after_v = float(d["vitality"])
	var lost := 0
	var added := 0
	var changed := 0
	for key in full["old_edges"]:
		if not full["new_edges"].has(key): lost += 1
		elif full["old_edges"][key] != full["new_edges"][key]: changed += 1
	for key in full["new_edges"]:
		if not full["old_edges"].has(key): added += 1
	if result["choice"].get("verb","") == "tread":
		return "预期谐振度：%.2f → %.2f\n%s\n失去%d条邻接；其他活力变化见下方明细。" % [result["before_r"],result["after_r"],full["cost"],lost]
	return "预期谐振度：%.2f → %.2f\n所选活力：%.1f → %.1f\n代价：%s\n邻接新增%d / 失去%d / 音程改变%d；明细见下方。" % [result["before_r"],result["after_r"],before_v,after_v,full["cost"],added,lost,changed]
