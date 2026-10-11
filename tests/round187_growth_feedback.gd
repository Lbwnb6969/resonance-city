extends SceneTree
## Pure contract for concrete feedback after a real birth boundary.
## It joins only observed World/building/music identities and never submits.
const GrowthFeedback = preload("res://scripts/world/growth_feedback.gd")
const OUTPUT := "res://验证记录/round187_真实生长反馈/growth_feedback.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class WorldStub extends RefCounted:
	var by_id: Dictionary = {}
	var communities: Dictionary = {}
	var families: Dictionary = {}
	var buildings: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _world() -> WorldStub:
	var world := WorldStub.new()
	world.communities["west-1"] = {"name":"松丘"}
	world.families["family-authored"] = {"expression":"deep", "player_expression":true, "root":"building-00028"}
	world.families["family-normal"] = {"expression":"bright"}
	var root := {"district_id":"building-00028", "position":[1.0,2.0], "community_id":"west-1", "family_id":"family-authored", "expression":"deep", "player_expression":true, "type":"residential", "current_midi":36, "birth_frame":100, "form":"央"}
	var child := {"district_id":"building-00029", "position":[3.0,4.0], "community_id":"west-1", "family_id":"family-authored", "expression":"deep", "player_expression":true, "type":"residential", "current_midi":36, "birth_frame":200, "form":"胚"}
	var normal := {"district_id":"building-00030", "position":[5.0,6.0], "community_id":"west-1", "family_id":"family-normal", "expression":"bright", "type":"commercial", "current_midi":52, "birth_frame":300, "form":"胚"}
	world.buildings = [root, child, normal]
	for building: Dictionary in world.buildings: world.by_id[building["district_id"]] = building
	return world

func _run() -> void:
	var world := _world()
	var authored_event := {"kind":"birth", "district_id":"building-00029", "frame":200}
	var authored_rows := [{"source_id":"building-00029", "receiver_id":"building-00028", "generation":0, "pitch":36, "event_id":"sound-29", "onset":200}]
	var authored := GrowthFeedback.for_birth(world,authored_event,{"building-00029":36},authored_rows)
	check(bool(authored.get("available",false)) and bool(authored.get("authored",false)),"authored_birth_is_marked_from_real_family")
	check(authored.get("district_id","") == "building-00029" and authored.get("position",[]) == [3.0,4.0] and authored.get("family_index",0) == 2,"authored_feedback_keeps_real_building_and_family_order")
	check(authored.get("community_name","") == "松丘" and authored.get("type_label","") == "住宅" and authored.get("note","") == "C","authored_feedback_exposes_real_community_type_and_pitch")
	check(authored.get("activity_roles",[]) == ["Lead"] and GrowthFeedback.text(authored).contains("你的深流第2栋住宅已长成") and GrowthFeedback.text(authored).contains("松丘") and not GrowthFeedback.text(authored).contains("building-") and GrowthFeedback.text(authored).contains("主题已在此处响起"),"authored_text_names_route_community_source_and_actual_activity")

	var normal_event := {"kind":"birth", "district_id":"building-00030", "frame":300}
	var normal := GrowthFeedback.for_birth(world,normal_event,{"building-00030":52},[{"source_id":"other","receiver_id":"building-00030","generation":1,"pitch":55}])
	var normal_text := GrowthFeedback.text(normal)
	check(not bool(normal.get("authored",true)) and normal.get("type_label","") == "商业" and normal.get("expression_label","") == "晴岸","ordinary_birth_does_not_claim_player_authorship")
	check(normal_text.contains("松丘") and normal_text.contains("商业") and normal_text.contains("对岸应答已在此处响起") and not normal_text.contains("你的"),"ordinary_text_exposes_real_community_type_and_reply_without_authorship")

	var unchanged: Dictionary = world.by_id["building-00029"].duplicate(true)
	GrowthFeedback.for_birth(world,authored_event,{"building-00029":36},authored_rows)
	check(world.by_id["building-00029"] == unchanged,"feedback_query_does_not_mutate_world")
	check(GrowthFeedback.for_birth(world,{"kind":"birth","district_id":"missing","frame":400}).is_empty(),"missing_birth_identity_has_no_invented_feedback")
	check(not GrowthFeedback.text(GrowthFeedback.for_birth(world,normal_event,{"building-00030":52},[])).contains("响起"),"text_does_not_claim_unobserved_activity")

	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Read-only concrete birth feedback over supplied World/building/family/community and rendered activity identities."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND187_GROWTH_FEEDBACK "+JSON.stringify({"passed":report["passed"],"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

