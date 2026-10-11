extends SceneTree
## Pure contract for reporting a real authored-family child after settlement.
## Current buildings and birth history must agree; stale removed events cannot
## turn into a predicted target.
const Continuation = preload("res://scripts/world/first_authored_continuation.gd")

const OUTPUT := "res://验证记录/round187_首作成长结果/first_authored_growth_result.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class WorldStub extends RefCounted:
	var by_id: Dictionary = {}
	var families: Dictionary = {}
	var events: Array = []
	var planning_reservations: Array = []
	var phrase_index := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _work(route: String = "deep", reservation: String = "") -> Dictionary:
	return {"expression":route,"community_id":"west-1","community_name":"松丘",
		"root_id":"building-00028","family_id":"family-00028","position":[1.0,2.0],"form":"央",
		"current_midi":36,"base_midi":36,"theme_eligible":false,"theme_playing":false,
		"root_in_theme":false,"family_houses":4,"next_growth_phrase":9,"reservation_id":reservation,
		"mature":4,"community_houses":8,"missing_conditions":["还需2栋成熟房屋"],"met_conditions":[],"civic_support":true}

func _world(work: Dictionary, with_child: bool = true, with_reservation: bool = false) -> WorldStub:
	var world := WorldStub.new()
	world.phrase_index = 4
	var root_id := str(work["root_id"])
	var family_id := str(work["family_id"])
	world.by_id[root_id] = {"district_id":root_id,"family_id":family_id,"community_id":"west-1",
		"position":[1.0,2.0],"form":"央","birth_frame":0,"current_midi":36,"expression":str(work["expression"])}
	world.families[family_id] = {"root":root_id,"expression":str(work["expression"]),"next_growth_phrase":9,
		"expression_reservation_id":str(work.get("reservation_id",""))}
	world.events = [{"kind":"birth","district_id":root_id,"frame":0,"phrase":0}]
	if with_child:
		world.by_id["building-00029"] = {"district_id":"building-00029","family_id":family_id,"community_id":"west-2",
			"position":[3.5,4.5],"form":"胚","birth_frame":220,"current_midi":36,"expression":str(work["expression"]),"type":"residential"}
		world.events.append({"kind":"birth","district_id":"building-00029","frame":220,"phrase":2,"form":"胚"})
	if with_reservation:
		world.planning_reservations.append({"reservation_id":str(work["reservation_id"]),"position":[6.0,7.0]})
	return world

func _run() -> void:
	var work := _work()
	var world := _world(work)
	var result: Dictionary = Continuation.state(world,work,{})
	var child: Dictionary = result.get("latest_child",{})
	check(bool(result.get("latest_child_observed",false)) and str(result.get("latest_child_id","")) == "building-00029","settled_family_child_is_reported_as_latest_observed_result")
	check(str(child.get("community_id","")) == "west-2" and child.get("position",[]) == [3.5,4.5],"child_result_keeps_real_community_and_position")
	check(int(child.get("phrase",-1)) == 2 and int(child.get("frame",-1)) == 220,"child_result_keeps_actual_birth_phrase_and_frame")
	check(str(child.get("voice_source","")) == "building-00029" and str(child.get("expression","")) == "deep" and int(child.get("current_midi",-1)) == 36,"child_result_names_actual_voice_source_and_pitch")
	check(str(result.get("target_kind","")) == "child" and str(result.get("action",{}).get("id","")) == "building-00029" and str(result.get("action_label","")) == "定位最近新屋","continuation_targets_the_latest_real_child")
	check(Continuation.text(result).contains("最近实际生长") and Continuation.text(result).contains("第2句") and Continuation.text(result).contains("building-00029"),"growth_text_exposes_observed_child_without_future_wording")

	# A second actual birth wins by event frame even when history is not ordered.
	world.by_id["building-00030"] = {"district_id":"building-00030","family_id":str(work["family_id"]),"community_id":"west-1",
		"position":[4.0,5.0],"birth_frame":330,"current_midi":36,"expression":"deep"}
	world.events.push_front({"kind":"birth","district_id":"building-00030","frame":330,"phrase":3})
	var latest: Dictionary = Continuation.state(world,work,{}).get("latest_child",{})
	check(str(latest.get("id","")) == "building-00030" and int(latest.get("phrase",-1)) == 3,"latest_child_selection_uses_actual_birth_order")

	var warm := _work("warm","reservation-00042")
	var reserved_world := _world(warm,true,true)
	var reserved: Dictionary = Continuation.state(reserved_world,warm,{})
	check(str(reserved.get("target_kind","")) == "reservation" and bool(reserved.get("reservation_active",false)),"reservation_remains_primary_action_alongside_observed_child")
	check(str(reserved.get("latest_child",{}).get("id","")) == "building-00029","reservation_result_still_reports_real_child")

	# Removing the child from the current world leaves only stale history; the
	# continuation must not expose that historical ID as a target.
	world.by_id.erase("building-00029")
	world.by_id.erase("building-00030")
	var removed: Dictionary = Continuation.state(world,work,{})
	check(not bool(removed.get("latest_child_observed",true)) and str(removed.get("latest_child_id","")) == "","removed_child_event_has_no_current_growth_target")
	check(not Continuation.text(removed).contains("building-00029") and not Continuation.text(removed).contains("building-00030"),"removed_child_is_absent_from_player_copy")

	var no_child: Dictionary = Continuation.state(_world(work,false),work,{})
	check(not bool(no_child.get("latest_child_observed",true)) and no_child.get("latest_child",{}).is_empty(),"without_birth_no_child_result_is_invented")

	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Observed first-authored family child identity, birth phrase, position and voice source; reservation priority and removed-child boundary; no operation submission or human listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND187_FIRST_AUTHORED_GROWTH_RESULT "+JSON.stringify({"passed":report["passed"],"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

