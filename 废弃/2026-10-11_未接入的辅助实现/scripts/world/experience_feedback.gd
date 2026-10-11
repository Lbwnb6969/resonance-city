extends RefCounted
## Read-only schema for human playtest observations.
##
## The contract keeps observed game truth separate from a player's answer. It
## only copies identities supplied by an existing growth/audio query; it never
## predicts a building, fills a missing sound role, or mutates the World.

const SCHEMA := "resonance_human_feedback_v1"
const KINDS := [
	"HUMAN-EXPRESSION",
	"HUMAN-AUTHOR",
	"HUMAN-DIFF",
	"HUMAN-CANDIDATE",
	"HUMAN-NOTASK",
	"HUMAN-FABRIC",
	"HUMAN-TIER",
]

# These are the stable identity fields needed to explain a real birth or
# audible source. Unknown fields are deliberately omitted from `truth()` so a
# temporary UI label cannot become an evidence claim.
const OBSERVED_FIELDS := [
	"available", "district_id", "position", "community_id", "community_name",
	"family_id", "family_index", "expression", "expression_label", "authored",
	"type", "type_label", "form", "midi", "note", "birth_frame",
	"activity_roles", "event",
]

static func template(kind: String = "HUMAN-AUTHOR") -> Dictionary:
	return {
		"schema": SCHEMA,
		"kind": kind,
		"tester_id": "",
		"trial_id": "",
		"seed": "",
		"layout_id": "",
		"device": "",
		"assist_state": "",
		"truth": {"available": false},
		"answer": {},
		"correct": null,
		"notes": "",
		"evidence": {"screenshot": "", "audio": ""},
	}

static func truth(observed: Dictionary) -> Dictionary:
	## Copy only observed keys. `duplicate(true)` prevents later edits from
	## changing the world/query object that supplied the evidence.
	var result: Dictionary = {}
	for key: String in OBSERVED_FIELDS:
		if observed.has(key): result[key] = observed[key].duplicate(true) if observed[key] is Array or observed[key] is Dictionary else observed[key]
	if not result.has("available"): result["available"] = false
	return result

static func make_record(kind: String, metadata: Dictionary, observed: Dictionary, answer: Dictionary = {}, correct = null, notes: String = "", evidence: Dictionary = {}) -> Dictionary:
	var record := template(kind)
	for key: String in ["tester_id", "trial_id", "seed", "layout_id", "device", "assist_state"]:
		if metadata.has(key): record[key] = metadata[key]
	record["truth"] = truth(observed)
	record["answer"] = answer.duplicate(true)
	record["correct"] = correct
	record["notes"] = notes
	var captured := {"screenshot": "", "audio": ""}
	for key: String in captured:
		if evidence.has(key): captured[key] = evidence[key]
	record["evidence"] = captured
	return record

static func validate(record: Dictionary) -> Dictionary:
	var failures: Array[String] = []
	if str(record.get("schema", "")) != SCHEMA: failures.append("schema")
	if not KINDS.has(str(record.get("kind", ""))): failures.append("kind")
	for key: String in ["tester_id", "trial_id", "seed", "layout_id", "device", "assist_state"]:
		if str(record.get(key, "")).strip_edges().is_empty(): failures.append(key)
	if not record.get("truth", null) is Dictionary: failures.append("truth")
	if not record.get("answer", null) is Dictionary: failures.append("answer")
	var correct = record.get("correct", null)
	if not (correct == null or correct is bool): failures.append("correct")
	if not record.get("evidence", null) is Dictionary: failures.append("evidence")
	var truth_data: Dictionary = record.get("truth", {})
	if bool(truth_data.get("available", false)):
		for key: String in ["district_id", "community_id", "family_id"]:
			if str(truth_data.get(key, "")).strip_edges().is_empty(): failures.append("truth." + key)
		if not truth_data.has("position") or not truth_data["position"] is Array or truth_data["position"].size() != 2: failures.append("truth.position")
	return {"ok": failures.is_empty(), "failures": failures}
