extends RefCounted
## Read-only result card for a settled first-expression family.
##
## The caller supplies the dictionary returned by Demo._first_authored_state().
## This helper never advances World, chooses a route, or fills in an absent
## route.  A score is optional; when present it contributes only observed slot,
## theme, and response state from that score snapshot.
const PlayerExpression = preload("res://scripts/world/player_expression.gd")

const NOTE_NAMES := {0:"C",2:"D",4:"E",7:"G",9:"A"}
const EXPRESSIONS := {"deep":"深流","weave":"织机","warm":"留地"}

static func note_label(midi: int) -> String:
	var name := str(NOTE_NAMES.get(posmod(midi,12),"音"))
	return "%s%d" % [name, floori(float(midi) / 12.0) - 1]

static func _expression_definition(expression: String) -> Dictionary:
	return PlayerExpression.definition(expression)

static func _rhythm_result(work: Dictionary,score: Dictionary,definition: Dictionary) -> Dictionary:
	var cid := str(work.get("community_id",""))
	var expression := str(work.get("expression",""))
	var actual: Dictionary = {}
	for part: Dictionary in score.get("rhythms",[]):
		if str(part.get("cid","")) == cid:
			actual = part
			break
	var active := not actual.is_empty()
	var midi := int(actual.get("midi",work.get("current_midi",definition.get("midi",0))))
	# A community can retain an older rhythm source while the newest authored
	# family is waiting for its next slot. When score exposes that real source,
	# describe its own pattern instead of attributing it to the selected root.
	var source_expression := expression if not bool(actual.get("player_expression",false)) else str(actual.get("expression",expression))
	var source_definition := PlayerExpression.definition(source_expression)
	if source_definition.is_empty(): source_definition = definition
	var offset := int(source_definition.get("rhythm_offset",0))
	var spacing := float(source_definition.get("rhythm_beats",0.0))
	var tail := float(source_definition.get("rhythm_tail",0.0))
	var result := {"active":active,"midi":midi,"pitch":midi+offset,
		"pitch_label":note_label(midi+offset),"spacing_beats":spacing,
		"tail_seconds":tail,"offset":offset,"source_id":str(actual.get("source_id","")),
		"source_expression":source_expression,"source_route_label":str(EXPRESSIONS.get(source_expression,source_expression))}
	if active:
		result["text"] = "%s · 每%.2f拍 · 尾音%.2f秒" % [note_label(midi+offset),spacing,tail]
	else:
		result["text"] = "当前未进入节奏槽 · 形式为%s每%.2f拍" % [note_label(midi+offset),spacing]
	return result

static func _theme_result(work: Dictionary,score: Dictionary) -> Dictionary:
	var eligible := bool(work.get("theme_eligible",false))
	var playing := bool(work.get("theme_playing",false))
	var root_in_theme := bool(work.get("root_in_theme",false))
	var missing: Array = work.get("missing_conditions",[]).duplicate(true)
	var next := ""
	if not eligible:
		next = "主题还未具备 · " + ("、".join(missing) if not missing.is_empty() else "继续让这片社区成熟")
	elif root_in_theme:
		next = "根房屋正在主题来源中 · 改一个音，下一拍听主题改写"
	elif playing:
		next = "社区主题正在演奏 · 根房屋尚未成为当前来源"
	else:
		next = "主题资格已满足 · 等待真实主题槽轮换，或聚焦这片社区再听"
	var theme: Dictionary = score.get("theme",{})
	var response: Dictionary = score.get("response",{})
	return {"eligible":eligible,"playing":playing,"root_in_theme":root_in_theme,
		"source_ids":theme.get("source_ids",[]).duplicate(true),
		"response_community":str(response.get("cid","")),
		"response_playing":str(response.get("cid","")) == str(work.get("community_id","")),
		"next":next}

static func summary(work: Dictionary,score: Dictionary = {}) -> Dictionary:
	if work.is_empty(): return {}
	var expression := str(work.get("expression",""))
	var definition := _expression_definition(expression)
	if definition.is_empty():
		return {"available":false,"reason":"未知路线 · 没有可显示的实际结果"}
	var current_midi := int(work.get("current_midi",definition.get("midi",0)))
	var base_midi := int(work.get("base_midi",definition.get("midi",current_midi)))
	var reservation_id := str(work.get("reservation_id",""))
	var rhythm := _rhythm_result(work,score,definition)
	var theme := _theme_result(work,score)
	var family_houses := int(work.get("family_houses",0))
	var mature := int(work.get("mature",0))
	var community_houses := int(work.get("community_houses",0))
	var reserve := {"active":not reservation_id.is_empty(),"id":reservation_id,
		"text":"仍保留一片真实空地 · 可继续规划" if not reservation_id.is_empty() else "当前没有活动留地 · 后续可另作规划"}
	var growth := {"family_houses":family_houses,"mature":mature,
		"community_houses":community_houses,"next_growth_phrase":int(work.get("next_growth_phrase",-1)),
		"civic_support":bool(work.get("civic_support",false))}
	var route_label := str(EXPRESSIONS.get(expression,expression))
	var register := {"current":current_midi,"base":base_midi,
		"current_label":note_label(current_midi),"base_label":note_label(base_midi),
		"changed":current_midi != base_midi,
		"text":note_label(current_midi)+(" · 出生"+note_label(base_midi)+"后已改音" if current_midi != base_midi else " · 保持出生音级")}
	return {"available":true,"route":expression,"route_label":route_label,
		"community_id":str(work.get("community_id","")),"community_name":str(work.get("community_name","")),
		"root_id":str(work.get("root_id","")),"form":str(work.get("form","")),
		"growth":growth,"family_houses":family_houses,"mature":mature,
		"community_houses":community_houses,"register":register,"rhythm":rhythm,
		"reserve":reserve,"theme":theme,"met_conditions":work.get("met_conditions",[]).duplicate(true),
		"missing_conditions":work.get("missing_conditions",[]).duplicate(true),
		"civic_support":bool(work.get("civic_support",false)),
		"position":work.get("position",[]).duplicate(true),
		"actual":true}

static func current(demo: Object) -> Dictionary:
	## Compact production adapter. The Demo remains the source of truth; this
	## helper only asks for its current authored state and audible score.
	if demo == null or not demo.has_method("_first_authored_state"): return {}
	var work: Dictionary = demo.call("_first_authored_state")
	if work.is_empty(): return {}
	var score: Dictionary = {}
	if demo.get("model") != null and demo.model.has_method("audible_score"):
		score = demo.model.audible_score()
	return summary(work,score)

static func text(card: Dictionary) -> String:
	if card.is_empty(): return ""
	if not bool(card.get("available",false)): return str(card.get("reason","暂无首作结果"))
	var growth: Dictionary = card.get("growth",{})
	var lines: Array[String] = []
	lines.append("%s · %s" % [str(card.get("community_name","这片街坊")),str(card.get("route_label","路线"))])
	lines.append("家族%d栋 · 社区%d栋 · 成熟%d栋" % [int(growth.get("family_houses",0)),int(growth.get("community_houses",0)),int(growth.get("mature",0))])
	var next_phrase := int(growth.get("next_growth_phrase",-1))
	lines.append("下一句生长 · "+("第%d句" % next_phrase if next_phrase >= 0 else "等待实际生长安排")+ (" · 文化馆已提供支撑" if bool(growth.get("civic_support",false)) else " · 尚无公共支撑"))
	var rhythm: Dictionary = card.get("rhythm",{})
	var rhythm_text := str(rhythm.get("text",""))
	if bool(rhythm.get("active",false)) and str(rhythm.get("source_expression",card.get("route",""))) != str(card.get("route","")):
		rhythm_text += " · 当前槽位来自"+str(rhythm.get("source_route_label","另一条路线"))
	lines.append("音域 %s · %s" % [str(card.get("register",{}).get("text","")),rhythm_text])
	lines.append(str(card.get("reserve",{}).get("text","")))
	lines.append("主题下一步 · "+str(card.get("theme",{}).get("next","")))
	return "\n".join(lines)

static func compare(states: Dictionary, scores: Dictionary = {}) -> Dictionary:
	var routes: Dictionary = {}
	var available: Array[String] = []
	var missing: Array[String] = []
	for id in PlayerExpression.IDS:
		if not states.has(id) or not (states[id] is Dictionary) or states[id].is_empty():
			missing.append(id)
			continue
		var score: Dictionary = scores.get(id,{}) if scores.get(id,{}) is Dictionary else {}
		var card := summary(states[id],score)
		if not bool(card.get("available",false)):
			missing.append(id)
			continue
		routes[id] = card
		available.append(id)
	return {"routes":routes,"available":available,"missing":missing,
		"complete":missing.is_empty() and available.size() == PlayerExpression.IDS.size(),
		"actual_only":true}

static func comparison_text(comparison: Dictionary) -> String:
	if comparison.is_empty(): return ""
	var lines: Array[String] = []
	for id in PlayerExpression.IDS:
		if not comparison.get("routes",{}).has(id): continue
		var card: Dictionary = comparison["routes"][id]
		lines.append("%s · 家族%d栋 · %s · %s" % [str(card.get("route_label",id)),int(card.get("family_houses",0)),str(card.get("register",{}).get("current_label","")),str(card.get("reserve",{}).get("text",""))])
	if not comparison.get("missing",[]).is_empty():
		var labels: Array[String] = []
		for id in comparison["missing"]: labels.append(str(EXPRESSIONS.get(str(id),id)))
		lines.append("未提供实际结果："+"、".join(labels))
	return "\n".join(lines)
