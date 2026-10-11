extends SceneTree
## Round 174 contract: a multi-community public preview exposes one ephemeral
## continuation summary and carries it into the existing next-action record.
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")

class TerrainStub extends RefCounted:
	var family := "lake_basin"

class WorldStub extends RefCounted:
	var terrain := TerrainStub.new()
	var communities := {"west":{"name":"西岸"},"east":{"name":"东岸"},"north":{"name":"北岸"}}
	var buildings: Array = []
	var by_id: Dictionary = {}
	var transit_lines: Array = [{"id":"line-combo","community_ids":["west","east"],"route_role":"跨社区接驳"}]

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _role(id: String,qualified := true) -> Dictionary:
	return {"role":id,"title":id,"qualified":qualified,"current":"当前 "+id,
		"next":"下一步 "+id,"qualification":{"qualified":qualified}}

func _preview(world: RefCounted) -> Dictionary:
	var combo := PublicPreview.community_combo(world,["west","east"],{
		"theme":{"cid":"west"},
		"response":{"source":"west","cid":"east","generation":1,"pair_count":2}})
	return {"choice":"park","accepted":true,"source":{"kind":"public_planning_variant"},
		"source_version":[1,2],"source_frame":1200,"boundary_frame":2400,
		"world_version":[4,12,2],"boundary":{"frame":2400,"world_version":[4,12,2]},
		"affected_communities":["west","east"],"anchor_ids":["park-west"],
		"communities":[
			{"community_id":"west","anchor_ids":["park-west"],"roles":{"theme":_role("Lead-west")}},
			{"community_id":"east","anchor_ids":[],"roles":{"response":_role("Response-east",false)}}],
		"community_combo":combo}

func _run() -> void:
	var world := WorldStub.new()
	var preview := _preview(world)
	var combo: Dictionary = preview["community_combo"]
	check(combo["contract"] == "P11-COMMUNITY-COMBO/v1","combo_has_ephemeral_contract")
	check(combo["community_ids"] == ["west","east"] and combo["count"] == 2,"combo_keeps_selected_scope")
	check(combo["audible"]["lead_community"] == "west" and combo["audible"]["reply_community"] == "east","combo_reports_actual_lead_reply")
	check(combo["relations"].any(func(item: Dictionary) -> bool: return item.get("kind","") == "river_response" and bool(item.get("audible",false))),"combo_marks_audible_response_relation")
	check(combo["relations"].any(func(item: Dictionary) -> bool: return item.get("kind","") == "transit" and item.get("line_id","") == "line-combo"),"combo_keeps_existing_transit_connection")
	check(str(combo["message"]).contains("主题") and str(combo["message"]).contains("应答"),"combo_message_explains_next_audible_step")
	var action := NextAction.from_preview(preview,"park","east")
	check(action["community_combo"] == combo,"next_action_carries_combo_without_rewriting_preview")
	check(action["community_id"] == "east" and action["affected_communities"] == ["west","east"],"next_action_keeps_viewed_target_and_full_scope")
	var before := preview.duplicate(true)
	action["community_combo"]["message"] = "changed"
	check(preview == before,"next_action_combo_is_deep_copy")
	var single := PublicPreview.community_combo(world,["west"],{"theme":{"cid":"west"}})
	check(single["mode"] == "single" and single["relations"].is_empty(),"single_scope_has_no_fake_combination")
	print("ROUND174_COMMUNITY_COMBO_CONTRACT "+JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
