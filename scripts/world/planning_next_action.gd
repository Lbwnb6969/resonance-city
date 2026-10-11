extends RefCounted
## P11 next-action contract.
##
## Public-planning comparison is deliberately a read-only forecast.  Once a
## player confirms one branch, the UI still needs one concrete continuation so
## the opportunity text does not become a dead end.  This helper converts the
## branch's real opportunity_preview into a small, versioned action record.  It
## does not submit anything and never changes world, random or audio state.

const CONTRACT := "P11-NEXT-ACTION/v1"
const ROLE_ORDER := ["theme", "commercial", "bass", "response"]
const ROLE_LABELS := {
	"theme":"社区主题",
	"commercial":"商业律动",
	"bass":"低音表达",
	"response":"跨岸应答",
}
const ROLE_IDS := {
	"theme":"Lead",
	"commercial":"Rhythm",
	"bass":"Bass",
	"response":"Response",
}

static func _role_map(record: Dictionary) -> Dictionary:
	var result: Dictionary = record.get("roles",{})
	if not result.is_empty(): return result.duplicate(true)
	result = record.get("role_opportunities",{})
	if not result.is_empty():
		var aliases := {"Lead":"theme","Bass":"bass","Rhythm":"commercial","Response":"response"}
		var normalized: Dictionary = {}
		for raw_key in result:
			var alias := str(aliases.get(str(raw_key),str(raw_key).to_lower()))
			normalized[alias] = result[raw_key].duplicate(true)
		return normalized
	for raw in record.get("opportunities",[]):
		if not raw is Dictionary: continue
		var role := str(raw.get("role",""))
		var alias: String = str({"Lead":"theme","Bass":"bass","Rhythm":"commercial","Response":"response"}.get(role,role.to_lower()))
		if not str(alias).is_empty(): result[str(alias)] = raw.duplicate(true)
	return result

static func _as_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array: return result
	for raw in value:
		var item := str(raw)
		if not item.is_empty() and not result.has(item): result.append(item)
	return result

static func _token(preview: Dictionary) -> Dictionary:
	var boundary: Dictionary = preview.get("boundary",{})
	var world_version: Array = preview.get("world_version",[]).duplicate(true)
	var boundary_version: Array = boundary.get("world_version",world_version).duplicate(true)
	return {
		"source":preview.get("source",{}).duplicate(true),
		"source_version":preview.get("source_version",[]).duplicate(true),
		"source_frame":int(preview.get("source_frame",-1)),
		"boundary_frame":int(preview.get("boundary_frame",-1)),
		"world_version":world_version,
		"boundary_world_version":boundary_version,
		"presentation_token":{
			"source_frame":int(preview.get("source_frame",-1)),
			"boundary_frame":int(preview.get("boundary_frame",-1)),
			"source_version":preview.get("source_version",[]).duplicate(true),
			"world_version":world_version.duplicate(true),
			"boundary_world_version":boundary_version.duplicate(true),
		},
	}

static func _record_summary(record: Dictionary) -> Dictionary:
	var roles := _role_map(record)
	var summary := {}
	for alias in ROLE_ORDER:
		if not roles.has(alias): continue
		var role: Dictionary = roles[alias]
		summary[alias] = {
			"role":str(role.get("role",ROLE_IDS[alias])),
			"title":str(role.get("title",ROLE_LABELS[alias])),
			"qualified":bool(role.get("qualified",false)),
			"current":str(role.get("current","")),
			"next":str(role.get("next","")),
			"qualification":role.get("qualification",{}).duplicate(true),
			"affected_role_ids":_as_string_array(role.get("affected_role_ids",[])),
			"anchor_ids":_as_string_array(role.get("anchor_ids",[])),
			"world_version":role.get("world_version",record.get("world_version",[])).duplicate(true),
		}
	return summary

static func _target_for_record(record: Dictionary, fallback_anchor_ids: Array = []) -> Dictionary:
	var summary := _record_summary(record)
	var selected_role := ""
	var selected: Dictionary = {}
	for alias in ROLE_ORDER:
		if not summary.has(alias): continue
		if bool(summary[alias].get("qualified",false)):
			selected_role = alias
			selected = summary[alias]
			break
	if selected_role.is_empty():
		for alias in ROLE_ORDER:
			if summary.has(alias):
				selected_role = alias
				selected = summary[alias]
				break
	var anchor_ids := _as_string_array(fallback_anchor_ids)
	for raw in record.get("anchor_ids",[]):
		var anchor := str(raw)
		if not anchor.is_empty() and not anchor_ids.has(anchor): anchor_ids.append(anchor)
	var adjustable_ids: Array[String] = []
	for alias in ["bass","commercial"]:
		if not summary.has(alias): continue
		for raw in summary[alias].get("anchor_ids",[]):
			var id := str(raw)
			if not id.is_empty() and not adjustable_ids.has(id): adjustable_ids.append(id)
	return {
		"community_id":str(record.get("community_id","")),
		"roles":summary,
		"role":selected_role,
		"role_id":str(selected.get("role",ROLE_IDS.get(selected_role,""))),
		"qualification":selected.get("qualification",{}).duplicate(true) if not selected.is_empty() else {},
		"anchor_id":str(anchor_ids[0]) if not anchor_ids.is_empty() else "",
		"anchor_ids":anchor_ids,
		"adjustable_ids":adjustable_ids,
	}

static func community_target(action: Dictionary, community_id: String) -> Dictionary:
	var targets: Variant = action.get("community_targets",{})
	if targets is Dictionary and targets.has(community_id) and targets[community_id] is Dictionary:
		return targets[community_id].duplicate(true)
	if str(action.get("community_id","")) == community_id and action.get("target",{}) is Dictionary:
		return action["target"].duplicate(true)
	return {}

static func _fallback_record(preview: Dictionary) -> Dictionary:
	var records: Array = preview.get("communities",[])
	if records.is_empty(): return {}
	return records[0].duplicate(true)

static func _community_combo(preview: Dictionary) -> Dictionary:
	var raw: Variant = preview.get("community_combo",{})
	return raw.duplicate(true) if raw is Dictionary else {}

static func _action_from_preview(preview: Dictionary, variant: Dictionary, choice: String, community_id: String = "") -> Dictionary:
	var token := _token(preview)
	var combo := _community_combo(preview)
	var accepted := bool(variant.get("accepted",preview.get("accepted",true)))
	var records: Array = preview.get("communities",[])
	var affected := _as_string_array(preview.get("affected_communities",[]))
	if affected.is_empty():
		for raw in records:
			if raw is Dictionary:
				var cid := str(raw.get("community_id",""))
				if not cid.is_empty() and not affected.has(cid): affected.append(cid)
	var record := _fallback_record(preview)
	var has_selected_community := false
	if not community_id.is_empty():
		for raw in records:
			if raw is Dictionary and str(raw.get("community_id","")) == community_id:
				record = raw.duplicate(true)
				has_selected_community = true
				break
	var community_targets: Dictionary = {}
	for raw in records:
		if not raw is Dictionary: continue
		var raw_cid := str(raw.get("community_id",""))
		if raw_cid.is_empty(): continue
		# The preview-level anchor list is an aggregate.  Do not copy it into
		# every community target or a birth on the second community could point
		# at the first community's public site.
		community_targets[raw_cid] = _target_for_record(raw,[])
	var cid := str(record.get("community_id",affected[0] if not affected.is_empty() else ""))
	var summary := _record_summary(record)
	var selected_role := ""
	var selected: Dictionary = {}
	for alias in ROLE_ORDER:
		if not summary.has(alias): continue
		if bool(summary[alias].get("qualified",false)):
			selected_role = alias
			selected = summary[alias]
			break
	if selected_role.is_empty():
		for alias in ROLE_ORDER:
			if summary.has(alias):
				selected_role = alias
				selected = summary[alias]
				break
	# A viewed community owns its role/anchor target.  The preview-level list
	# is an aggregate across communities and cannot be a selected target's
	# fallback.  Calls without a valid selection keep the original primary
	# record behavior for existing consumers and older comparison payloads.
	var primary_target := _target_for_record(record,[] if has_selected_community else preview.get("anchor_ids",[]))
	if not cid.is_empty() and not community_targets.has(cid): community_targets[cid] = primary_target.duplicate(true)
	var action_kind := "replan"
	# The headline state follows the community theme qualification.  Bass,
	# rhythm and response can still provide a useful focus target while the main
	# theme is waiting, but they must not make the planning opportunity appear
	# fully ready before the community has formed its lead.
	var theme_ready := bool(summary.get("theme",{}).get("qualified",false))
	var status := "replan"
	var operation := {}
	var label := "重新规划这一处公共落点"
	var reason := str(variant.get("reason",preview.get("reason","")))
	if accepted and not record.is_empty():
		status = "ready" if theme_ready else "waiting"
		action_kind = "focus_community"
		operation = {"kind":"focus","community":cid}
		label = "聚焦 %s · %s" % [cid,ROLE_LABELS.get(selected_role,"社区机会")] if not selected_role.is_empty() else "聚焦 %s" % cid
		if reason.is_empty():
			reason = str(selected.get("next","")) if not selected.is_empty() else "先听受影响社区的下一拍，再决定是否调整"
	elif not accepted and reason.is_empty():
		reason = "该落点没有在当前边界提交，回到规划工具重新选择"
	var target := {
		"community_id":cid,
		"community_ids":affected,
		"anchor_id":primary_target.get("anchor_id",""),
		"anchor_ids":primary_target.get("anchor_ids",[]),
		"adjustable_ids":primary_target.get("adjustable_ids",[]),
		"role":selected_role,
		"role_id":str(selected.get("role",ROLE_IDS.get(selected_role,""))),
	}
	return {
		"contract":CONTRACT,
		"choice":choice,
		"status":status,
		"action_kind":action_kind,
		"operation":operation,
		"label":label,
		"reason":reason,
		"target":target,
		"community_id":cid,
		"affected_communities":affected,
		"roles":summary,
		"community_targets":community_targets,
		"community_combo":combo,
		"qualification":selected.get("qualification",{}).duplicate(true) if not selected.is_empty() else {},
		"world_version":token["world_version"].duplicate(true),
		"source_frame":token["source_frame"],
		"boundary_frame":token["boundary_frame"],
		"token":token,
		"presentation_token":token["presentation_token"].duplicate(true),
	}

static func from_preview(preview: Dictionary, choice: String = "", community_id: String = "") -> Dictionary:
	var variant := {"accepted":bool(preview.get("accepted",true)),"reason":str(preview.get("reason",""))}
	var selected_choice := choice if not choice.is_empty() else str(preview.get("choice",""))
	return _action_from_preview(preview,variant,selected_choice,community_id)

static func from_comparison(comparison: Dictionary, choice: String, community_id: String = "") -> Dictionary:
	var variants: Dictionary = comparison.get("variants",{})
	var variant: Dictionary = variants.get(choice,{})
	if variant.is_empty():
		return _action_from_preview({"choice":choice,"accepted":false,"reason":"找不到该规划分支","source_version":comparison.get("source_version",[]),"source_frame":comparison.get("source_frame",-1),"boundary_frame":comparison.get("boundary_frame",-1),"world_version":[]},variant,choice,community_id)
	var preview: Dictionary = variant.get("opportunity_preview",{})
	if preview.is_empty():
		preview = {"choice":choice,"accepted":variant.get("accepted",false),"reason":variant.get("reason",""),
			"source_version":comparison.get("source_version",[]),"source_frame":comparison.get("source_frame",-1),
			"boundary_frame":comparison.get("boundary_frame",-1),"world_version":[],"communities":variant.get("opportunities",[]),
			"affected_communities":[],"anchor_ids":[],"community_combo":variant.get("community_combo",{})}
	return _action_from_preview(preview,variant,choice,community_id)

static func is_current(action: Dictionary, world_version: Array, audible_frame: int = -1) -> bool:
	if action.get("contract","") != CONTRACT: return false
	var token: Dictionary = action.get("token",{})
	if token.is_empty() or world_version.is_empty() or not token.has("world_version"): return false
	if token.get("world_version",[]) != world_version: return false
	if audible_frame >= 0 and int(token.get("boundary_frame",-1)) >= 0 and audible_frame > int(token["boundary_frame"]): return false
	return true

