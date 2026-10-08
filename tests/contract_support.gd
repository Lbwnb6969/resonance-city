extends RefCounted
## Contracts collect real checks and persist their outcome before exiting.

var rule_id: String
var case_name: String
var checks: Array[Dictionary] = []
var failures := 0
var details: Dictionary = {}

func _init(id: String, selected_case: String = "all") -> void:
	rule_id = id
	case_name = selected_case

static func selected_case(fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return fallback
	if args.size() == 2 and args[0] == "--case":
		return args[1]
	return "INVALID_ARGUMENTS"

func check(condition: bool, description: String) -> void:
	checks.append({"description": description, "passed": condition})
	if not condition:
		failures += 1
		push_error("%s: %s" % [rule_id, description])

func finish(tree: SceneTree, scope: String = "") -> void:
	var evidence := "res://验证记录/P0/%s_%s.json" % [rule_id, case_name]
	DirAccess.make_dir_recursive_absolute("res://验证记录/P0")
	var result := {
		"rule_id": rule_id, "case": case_name,
		"status": "PASS" if failures == 0 else "FAIL",
		"scope": scope, "checks": checks, "details": details,
		"engine": Engine.get_version_info()["string"],
		"arguments": Array(OS.get_cmdline_args()),
		"exit_code": 0 if failures == 0 else 1,
	}
	var file := FileAccess.open(evidence, FileAccess.WRITE)
	if file == null:
		failures += 1
		push_error("Cannot save contract evidence: " + evidence)
	else:
		file.store_string(JSON.stringify(result, "\t") + "\n")
		file.close()
	print("%s %s checks=%d evidence=%s scope=%s" % [
		rule_id, "PASS" if failures == 0 else "FAIL", checks.size(), evidence, scope])
	tree.quit(0 if failures == 0 else 1)
