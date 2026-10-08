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
	for index in range(result["after"].size()):
		var before: Dictionary = result["before"][index]
		var after: Dictionary = result["after"][index]
		vitality.append("%s：%.1f → %.1f" % [after["district_id"],before["vitality"],after["vitality"]])
	var choice: Dictionary = result["choice"]
	var values := Values.load_values()
	var params: Dictionary = values["proposals"]
	var phrase_seconds := 60.0 / float(values["timing"]["bpm"]) * int(values["timing"]["beats_per_bar"]) * int(values["timing"]["bars_per_phrase"])
	var cost := "改造 %+.0f 活力" % params["retune_cost"] if choice.get("verb") == "retune" else "该街区静音 %d 乐句（%.0f 秒）；原邻居失去相应关系" % [params["relocate_silent_phrases"],phrase_seconds*int(params["relocate_silent_phrases"])]
	if choice.get("on_grid",false):
		cost += "；含可选卡拍 %+.0f" % params["landing_bonus"]
	var text := "预期 R：%.2f → %.2f\n代价：%s\n下个乐句活力：%s\n%s" % [
		result["before_r"],result["after_r"],cost,"；".join(vitality),
		"\n".join(changed) if not changed.is_empty() else "邻接不变"]
	return {"text":text,"before_r":result["before_r"],"after_r":result["after_r"],
		"old_edges":old,"new_edges":next,"changes":changed,"vitality":vitality,"choice":choice.duplicate(true)}
