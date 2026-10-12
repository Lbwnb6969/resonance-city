extends RefCounted
## Read-only feedback for a real birth boundary.
##
## A birth event alone only names a district id.  This helper joins that id to
## the presented World, the actual family and community, the current pitch,
## and any music activity currently rendered for the same source.  It never
## creates a building, predicts a future lot, or changes the save state.
const EXPRESSIONS := {
	"deep": "深流",
	"weave": "织机",
	"warm": "暖庭",
	"bright": "晴岸",
}
const TYPES := {
	"residential": "住宅",
	"commercial": "商业",
	"industrial": "工业",
}
const NOTE_NAMES := {0: "C", 2: "D", 4: "E", 7: "G", 9: "A"}

static func _note_name(midi: int) -> String:
	return str(NOTE_NAMES.get(posmod(midi, 12), "·"))

static func _activity_for(rows: Array, district_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_row in rows:
		if not raw_row is Dictionary: continue
		var row: Dictionary = raw_row
		var source := str(row.get("source_id", ""))
		var receiver := str(row.get("receiver_id", ""))
		if source != district_id and receiver != district_id: continue
		var generation := int(row.get("generation", 0))
		var role := "Reply" if generation == 1 or receiver == district_id else "Lead"
		result.append({"role": role, "generation": generation, "pitch": int(row.get("pitch", -1)),
			"event_id": str(row.get("event_id", "")), "onset": int(row.get("onset", -1))})
	return result

static func for_birth(world: RefCounted, event: Dictionary, audible_pitches: Dictionary = {}, activity_rows: Array = []) -> Dictionary:
	if world == null or event.is_empty() or str(event.get("kind", "")) != "birth": return {}
	var district_id := str(event.get("district_id", ""))
	if district_id.is_empty() or not world.by_id.has(district_id): return {}
	var building: Dictionary = world.by_id[district_id].duplicate(true)
	var community_id := str(building.get("community_id", ""))
	var community: Dictionary = world.communities.get(community_id, {})
	var family_id := str(building.get("family_id", ""))
	var family: Dictionary = world.families.get(family_id, {})
	var expression := str(building.get("expression", family.get("expression", "")))
	var authored := bool(building.get("player_expression", false)) or bool(family.get("player_expression", false))
	var family_index := 0
	var birth_frame := int(event.get("frame", building.get("birth_frame", -1)))
	for candidate in world.buildings:
		if str(candidate.get("family_id", "")) != family_id: continue
		if int(candidate.get("birth_frame", birth_frame)) <= birth_frame: family_index += 1
	if family_index <= 0: family_index = 1
	var midi := int(audible_pitches.get(district_id, building.get("current_midi", -1)))
	var activity := _activity_for(activity_rows, district_id)
	var roles: Array[String] = []
	for row: Dictionary in activity:
		var role := str(row.get("role", ""))
		if not roles.has(role): roles.append(role)
	return {
		"available": true,
		"district_id": district_id,
		"position": building.get("position", []).duplicate(true),
		"community_id": community_id,
		"community_name": str(community.get("name", community_id if not community_id.is_empty() else "社区")),
		"family_id": family_id,
		"family_index": family_index,
		"expression": expression,
		"expression_label": str(EXPRESSIONS.get(expression, expression if not expression.is_empty() else "声音")),
		"authored": authored,
		"type": str(building.get("type", "residential")),
		"type_label": str(TYPES.get(str(building.get("type", "residential")), "建筑")),
		"form": str(building.get("form", "胚")),
		"midi": midi,
		"note": _note_name(midi) if midi >= 0 else "·",
		"birth_frame": birth_frame,
		"activity": activity,
		"activity_roles": roles,
		"event": event.duplicate(true),
	}

static func text(feedback: Dictionary) -> String:
	if feedback.is_empty() or not bool(feedback.get("available", false)): return ""
	var community := str(feedback.get("community_name", feedback.get("community_id", "社区")))
	var expression := str(feedback.get("expression_label", "声音"))
	var type_label := str(feedback.get("type_label", "建筑"))
	var note := str(feedback.get("note", "·"))
	var activity_suffix := ""
	var roles: Array = feedback.get("activity_roles", [])
	var role_names: Array[String] = []
	for role: String in roles: role_names.append("对岸应答" if role == "Reply" else "主题")
	if not role_names.is_empty(): activity_suffix = " · " + "与".join(role_names) + "已在此处响起"
	if bool(feedback.get("authored", false)):
		return "你的%s第%d栋%s已长成 · %s · %s%s" % [expression, int(feedback.get("family_index", 1)), type_label, community, note, activity_suffix]
	return "%s · 一栋%s已长成 · %s%s" % [community,type_label,note,activity_suffix]

