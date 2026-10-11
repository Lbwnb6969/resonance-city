extends SceneTree
## Round 188: human feedback keeps observed growth truth and player answers
## separate. This is a recorder/schema contract, not a human-experience claim.
const Feedback = preload("res://scripts/world/experience_feedback.gd")
const OUTPUT := "res://验证记录/round188_首作反馈/experience_feedback_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	var observed := {
		"available": true, "district_id": "building-00029", "position": [3.0, 4.0],
		"community_id": "west-1", "community_name": "松丘", "family_id": "family-authored",
		"family_index": 2, "expression": "deep", "expression_label": "深流", "authored": true,
		"type": "residential", "type_label": "住宅", "form": "胚", "midi": 36, "note": "C",
		"birth_frame": 220, "activity_roles": ["Lead"],
		"event": {"kind": "birth", "district_id": "building-00029", "phrase": 2},
		"future_building_id": "must-not-leak",
	}
	var metadata := {"tester_id": "tester-01", "trial_id": "author-01", "seed": "2026101100000187",
		"layout_id": "river-west-1", "device": "headphones", "assist_state": "default"}
	var answer := {"recognized_source": true, "stated_cause": "我调高了根屋，后来同一社区跟着长出回应", "continue": true}
	var record := Feedback.make_record("HUMAN-AUTHOR", metadata, observed, answer, true,
		"玩家能指出社区、音源和城市成长之间的因果。", {"screenshot": "author.png", "audio": "author.wav"})
	var valid := Feedback.validate(record)
	check(bool(valid.get("ok", false)), "complete_observation_record_is_valid")
	check(record.get("truth", {}).get("district_id", "") == "building-00029" and record.get("truth", {}).get("position", []) == [3.0, 4.0], "observed_identity_and_position_are_preserved")
	check(not record.get("truth", {}).has("future_building_id"), "future_identity_is_not_copied_into_truth")
	check(record.get("answer", {}).get("stated_cause", "").contains("社区") and record.get("correct", null) == true, "player_answer_and_reviewer_result_are_kept_separate")
	# Deep-copy boundary: mutating the source query after recording cannot rewrite
	# the evidence that will be reviewed later.
	observed["position"][0] = 99.0
	observed["activity_roles"].append("Reply")
	check(record.get("truth", {}).get("position", []) == [3.0, 4.0] and record.get("truth", {}).get("activity_roles", []) == ["Lead"], "record_does_not_alias_live_query_arrays")
	var incomplete := Feedback.template("HUMAN-AUTHOR")
	var invalid := Feedback.validate(incomplete)
	check(not bool(invalid.get("ok", true)) and invalid.get("failures", []).has("tester_id") and invalid.get("failures", []).has("device"), "empty_template_requires_trial_metadata")
	var malformed := record.duplicate(true)
	malformed["kind"] = "INVENTED"
	malformed["correct"] = "yes"
	check(not bool(Feedback.validate(malformed).get("ok", true)), "unknown_kind_and_non_boolean_review_are_rejected")
	var ordinary := Feedback.make_record("HUMAN-DIFF", metadata, {"available": true, "district_id": "building-00030", "position": [5.0, 6.0], "community_id": "east-1", "family_id": "family-other"}, {"heard_difference": "片段B更有拍子"})
	check(bool(Feedback.validate(ordinary).get("ok", false)) and not bool(ordinary.get("truth", {}).get("authored", false)), "non_authored_observation_stays_neutral")
	var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures,
		"scope": "Human playtest record schema: observed growth/audio identity, separate player answer, review result and evidence paths; no World mutation or human acceptance claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT, FileAccess.WRITE).store_string(JSON.stringify(report, "  ") + "\n")
	print("ROUND188_EXPERIENCE_FEEDBACK_CONTRACT " + JSON.stringify({"passed": report["passed"], "checks": checks.size(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)
