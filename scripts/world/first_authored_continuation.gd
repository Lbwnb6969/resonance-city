extends RefCounted
## Read-only continuation contract for the first authored expression.
##
## The production UI may use this result to locate the next real thing the
## player can continue composing.  It deliberately derives every identity
## from the current World and audible score: no next building, reservation or
## theme source is invented, and no continuation state is persisted here.
const EXPRESSIONS := {"deep": "深流", "weave": "织机", "warm": "留地"}

static func _event(world: RefCounted, kind: String, district_id: String) -> Dictionary:
	var latest: Dictionary = {}
	for raw_event in world.events:
		var event: Dictionary = raw_event
		if str(event.get("kind", "")) != kind: continue
		if not district_id.is_empty() and str(event.get("district_id", "")) != district_id: continue
		if latest.is_empty() or int(event.get("frame", -1)) >= int(latest.get("frame", -1)):
			latest = event.duplicate(true)
	return latest

static func _active_reservation(world: RefCounted, reservation_id: String) -> Dictionary:
	if reservation_id.is_empty(): return {}
	for raw_reservation in world.planning_reservations:
		var reservation: Dictionary = raw_reservation
		var id := str(reservation.get("reservation_id", reservation.get("id", "")))
		if id == reservation_id:
			return reservation.duplicate(true)
	return {}

static func state(world: RefCounted, work: Dictionary, score: Dictionary = {}) -> Dictionary:
	## `work` is the already-derived FirstAuthoredWork.state result.  Keeping it
	## as an input means this contract shares the exact latest-root selection and
	## pitch source used by the save/export and player-facing route cards.
	if world == null or work.is_empty(): return {}
	var root_id := str(work.get("root_id", ""))
	var family_id := str(work.get("family_id", ""))
	var root: Dictionary = world.by_id.get(root_id, {})
	var family: Dictionary = world.families.get(family_id, {})
	if root.is_empty() or family.is_empty() or str(root.get("family_id", "")) != family_id:
		return {"available": false, "reason": "首作根房屋已不在当前作品中"}
	var cid := str(root.get("community_id", work.get("community_id", "")))
	var source_ids: Array = score.get("theme", {}).get("source_ids", []).duplicate(true)
	var theme_cid := str(score.get("theme", {}).get("cid", ""))
	var root_in_theme := theme_cid == cid and source_ids.has(root_id)
	var reservation_source_id := str(family.get("expression_reservation_id", ""))
	var reservation := _active_reservation(world, reservation_source_id)
	var active_reservation_id := str(reservation.get("reservation_id", reservation.get("id", "")))
	var current_phrase := int(world.phrase_index)
	var next_growth_phrase := int(family.get("next_growth_phrase", work.get("next_growth_phrase", -1)))
	var growth_pending := next_growth_phrase >= 0 and current_phrase < next_growth_phrase
	var action := {"kind": "", "id": "", "position": [], "community_id": cid, "available": false}
	if not reservation.is_empty():
		action = {"kind": "reservation", "id": active_reservation_id, "position": reservation.get("position", []).duplicate(true), "community_id": cid, "available": true,
			"text": "定位这片真实留地继续规划"}
	elif bool(work.get("theme_eligible", false)) and not root_id.is_empty():
		action = {"kind": "root", "id": root_id, "position": root.get("position", []).duplicate(true), "community_id": cid, "available": true,
			"text": "定位首作根房屋继续改音" if root_in_theme else "定位首作根房屋等待主题轮换"}
	elif growth_pending:
		action = {"kind": "community", "id": cid, "position": [], "community_id": cid, "available": true,
			"text": "沿这片社区等待第%d句真实生长" % next_growth_phrase}
	elif not root_id.is_empty():
		action = {"kind": "root", "id": root_id, "position": root.get("position", []).duplicate(true), "community_id": cid, "available": true,
			"text": "定位首作根房屋查看当前音级"}
	var action_kind := str(action.get("kind", ""))
	var action_label := "等待真实落地"
	match action_kind:
		"reservation": action_label = "继续规划真实留地"
		"root": action_label = "继续改写首作根屋"
		"community": action_label = "沿社区继续组合"
	return {"available": true, "root_id": root_id, "family_id": family_id,
		"community_id": cid, "community_name": str(work.get("community_name", cid)),
		"route": str(work.get("expression", "")),
		"root_position": root.get("position", []).duplicate(true), "root_form": str(root.get("form", "")),
		"current_phrase": current_phrase, "next_growth_phrase": next_growth_phrase, "growth_pending": growth_pending,
		"family_houses": int(work.get("family_houses", 0)), "community_houses": int(work.get("community_houses", 0)),
		"mature": int(work.get("mature", 0)), "theme_eligible": bool(work.get("theme_eligible", false)),
		"theme_community_id": theme_cid, "theme_source_ids": source_ids, "root_in_theme": root_in_theme,
		"reservation_source_id": reservation_source_id, "reservation_active": not reservation.is_empty(),
		"reservation_id": active_reservation_id, "reservation_position": reservation.get("position", []).duplicate(true),
		"birth_event": _event(world, "birth", root_id), "retune_event": _event(world, "retune", root_id),
		"action": action, "target_kind": action_kind, "action_label": action_label,
		"action_id": str(action.get("id", "")), "actual_only": true}

static func text(result: Dictionary) -> String:
	## Player-facing copy over a state() result. Every named identity comes from
	## that result; an unavailable/removed root never receives a replacement.
	if result.is_empty(): return ""
	if not bool(result.get("available", false)): return str(result.get("reason", "暂无首作续作结果"))
	var lines: Array[String] = []
	var route := str(result.get("route", ""))
	lines.append("已落地 · %s · %s" % [str(result.get("community_name", result.get("community_id", "社区"))), str(EXPRESSIONS.get(route, route if not route.is_empty() else "路线"))])
	lines.append("根屋 %s · 家族%d栋 · 社区%d栋 · 成熟%d栋" % [str(result.get("root_id", "")), int(result.get("family_houses", 0)), int(result.get("community_houses", 0)), int(result.get("mature", 0))])
	if bool(result.get("theme_eligible", false)):
		lines.append("主题资格已满足" + (" · 根屋当前在真实主题来源中" if bool(result.get("root_in_theme", false)) else " · 根屋当前不在主题来源中"))
	else:
		lines.append("主题资格未满足 · 社区仍需实际成熟")
	if bool(result.get("reservation_active", false)):
		lines.append("留地仍在 · " + str(result.get("reservation_id", "")))
	else:
		lines.append("当前没有活动留地")
	var next_phrase := int(result.get("next_growth_phrase", -1))
	if next_phrase >= 0: lines.append("已登记的实际成长句 · 第%d句" % next_phrase)
	var action: Dictionary = result.get("action", {})
	if bool(action.get("available", false)):
		lines.append("下一步 · %s · %s" % [str(result.get("action_label", "继续组合")), str(action.get("text", ""))])
	else:
		lines.append("下一步 · 当前没有可定位的真实目标")
	return "\n".join(lines)
