extends SceneTree
## A viewed public-preview community becomes the confirmation's primary
## continuation without changing the branch, shared source, or full scope.

const NextAction = preload("res://scripts/world/planning_next_action.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _role(id: String,ready: bool,anchors: Array = []) -> Dictionary:
	return {"role":id,"title":id,"qualified":ready,"current":"当前 "+id,
		"next":"下一步 "+id,"qualification":{"qualified":ready,"missing_conditions":[] if ready else ["继续形成 "+id]},
		"affected_role_ids":[id],"anchor_ids":anchors,"world_version":[4,12,2]}

func _preview() -> Dictionary:
	return {"source":{"kind":"public_planning_variant","site_id":"shared-source","community_id":"west-1","choice":"park"},
		"choice":"park","accepted":true,"source_version":[4,12,2,"shared-source"],"source_frame":1200,
		"boundary_frame":2400,"world_version":[4,12,2],"boundary":{"frame":2400,"world_version":[4,12,2]},
		"affected_communities":["west-1","east-2"],"anchor_ids":["west-park","east-civic"],
		"communities":[
			{"community_id":"west-1","world_version":[4,12,2],"anchor_ids":["west-park"],
				"roles":{"theme":_role("Lead-west",true),"commercial":_role("Rhythm-west",false,["market-west"]),
					"bass":_role("Bass-west",true,["bass-west"]),"response":_role("Response-west",false)}},
			{"community_id":"east-2","world_version":[4,12,2],"anchor_ids":["east-civic"],
				"roles":{"theme":_role("Lead-east",false),"commercial":_role("Rhythm-east",true,["market-east"]),
					"bass":_role("Bass-east",false,["bass-east"]),"response":_role("Response-east",false)}}]}

func _run() -> void:
	var preview := _preview()
	var comparison := {"source_version":preview["source_version"].duplicate(true),"source_frame":1200,"boundary_frame":2400,
		"variants":{"park":{"accepted":true,"opportunity_preview":preview}}}
	var original := comparison.duplicate(true)
	var baseline := NextAction.from_comparison(comparison,"park")
	var selected := NextAction.from_comparison(comparison,"park","east-2")
	check(baseline["community_id"] == "west-1" and baseline["operation"] == {"kind":"focus","community":"west-1"},"default_keeps_first_community")
	check(selected["contract"] == NextAction.CONTRACT and selected["choice"] == "park","selection_keeps_contract_and_choice")
	check(selected["community_id"] == "east-2" and selected["target"]["community_id"] == "east-2","second_community_becomes_primary_target")
	check(selected["operation"] == {"kind":"focus","community":"east-2"} and selected["action_kind"] == "focus_community","second_community_has_executable_focus")
	check(selected["target"]["role"] == "commercial" and selected["target"]["role_id"] == "Rhythm-east","selected_target_uses_own_qualified_role")
	check(selected["roles"] == baseline["community_targets"]["east-2"]["roles"],"selected_target_keeps_own_role_rows")
	check(selected["qualification"] == {"qualified":true,"missing_conditions":[]},"selected_target_keeps_own_role_qualification")
	check(selected["status"] == "waiting" and baseline["status"] == "ready","headline_status_still_follows_selected_theme")
	check(selected["reason"] == "下一步 Rhythm-east" and selected["label"].contains("east-2"),"selected_reason_and_label_follow_second_community")
	check(selected["target"]["anchor_id"] == "east-civic" and selected["target"]["anchor_ids"] == ["east-civic"],"selected_target_uses_own_anchor_without_aggregate_leak")
	check(selected["target"]["adjustable_ids"] == ["bass-east","market-east"],"selected_target_keeps_own_adjustable_buildings")
	check(selected["affected_communities"] == baseline["affected_communities"] and selected["target"]["community_ids"] == baseline["target"]["community_ids"],"selection_preserves_full_affected_scope")
	check(selected["community_targets"] == baseline["community_targets"],"selection_preserves_all_independent_targets")
	check(selected["token"] == baseline["token"] and selected["presentation_token"] == baseline["presentation_token"],"selection_preserves_source_and_presentation_tokens")
	check(selected["token"]["source"] == preview["source"] and selected["token"]["source"]["community_id"] == "west-1","selected_target_does_not_rewrite_source_owner")
	check(selected["source_frame"] == baseline["source_frame"] and selected["boundary_frame"] == baseline["boundary_frame"] and selected["world_version"] == baseline["world_version"],"selection_preserves_frames_and_world_version")
	check(NextAction.from_comparison(comparison,"park","missing-community") == baseline,"invalid_community_falls_back_to_original_first_record")
	check(NextAction.from_comparison(comparison,"park","") == baseline,"empty_selection_keeps_existing_behavior")
	check(NextAction.from_preview(preview,"park","east-2") == selected,"preview_entry_supports_the_same_optional_selection")
	check(NextAction.from_preview(preview,"","east-2") == selected,"preview_selection_keeps_inferred_choice")
	check(comparison == original,"building_selected_action_leaves_input_unchanged")

	var no_anchor := preview.duplicate(true)
	no_anchor["communities"][1]["anchor_ids"] = []
	var no_anchor_action := NextAction.from_preview(no_anchor,"park","east-2")
	check(no_anchor_action["target"]["anchor_id"] == "" and no_anchor_action["target"]["anchor_ids"].is_empty(),"selected_community_without_anchor_does_not_borrow_another_anchor")
	selected["roles"]["commercial"]["qualification"]["missing_conditions"].append("private-output")
	selected["community_targets"]["east-2"]["anchor_ids"].append("private-anchor")
	selected["token"]["source"]["community_id"] = "private-source"
	selected["affected_communities"].append("private-community")
	check(comparison == original,"editing_selected_output_keeps_input_isolated")
	check(baseline == NextAction.from_comparison(comparison,"park"),"editing_selected_output_keeps_other_actions_isolated")

	print("ROUND170_COMPARISON_COMMUNITY_CONTRACT ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
