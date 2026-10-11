extends SceneTree
## Pure contract for the post-route continuation target.
## It accepts only observed first_authored_state and World identities; it never
## submits a planning operation or invents a future building.
const Continuation = preload("res://scripts/world/first_authored_continuation.gd")

const OUTPUT := "res://验证记录/round186_首作续作反馈/first_authored_continuation.json"
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

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _work(route: String,houses: int,reservation: String = "",eligible: bool = false) -> Dictionary:
	var midi: int = int({"deep":36,"weave":60,"warm":48}.get(route,36))
	return {"expression":route,"community_id":"west-1","community_name":"松丘",
		"root_id":"building-00028","family_id":"family-00028","position":[1.0,2.0],"form":"央",
		"current_midi":midi,"base_midi":midi,"theme_eligible":eligible,
		"theme_playing":eligible,"root_in_theme":eligible,"family_houses":houses,
		"next_growth_phrase":9,"reservation_id":reservation,"mature":houses,
		"community_houses":houses+4,"missing_conditions":[] if eligible else ["还需%d栋成熟房屋" % maxi(0,6-houses)],
		"met_conditions":["六栋成熟房屋"] if eligible else [],"civic_support":true}

func _world(work: Dictionary,phrase: int = 2,with_reservation: bool = false) -> WorldStub:
	var world := WorldStub.new()
	var root_id := str(work["root_id"])
	var family_id := str(work["family_id"])
	world.phrase_index = phrase
	world.by_id[root_id] = {"district_id":root_id,"family_id":family_id,"community_id":"west-1","position":[1.0,2.0],"form":"央"}
	world.families[family_id] = {"root":root_id,"expression":str(work["expression"]),"next_growth_phrase":int(work["next_growth_phrase"]),"expression_reservation_id":str(work.get("reservation_id",""))}
	world.events = [{"kind":"birth","district_id":root_id,"frame":100}]
	if with_reservation:
		world.planning_reservations.append({"reservation_id":str(work["reservation_id"]),"position":[3.0,4.0]})
	return world

func _run() -> void:
	var young := _work("deep",4)
	var young_before := young.duplicate(true)
	var young_result: Dictionary = Continuation.state(_world(young,2),young,{})
	check(bool(young_result.get("available",false)) and bool(young_result.get("actual_only",false)),"young_route_exposes_only_observed_continuation")
	check(young_result.get("target_kind","") == "community" and young_result["action"]["id"] == "west-1" and young_result["action_label"] == "沿社区继续组合","young_route_targets_the_real_community_for_more_composition")
	check(young_result["root_id"] == "building-00028" and int(young_result["next_growth_phrase"]) == 9 and bool(young_result["growth_pending"]),"young_route_keeps_real_root_and_growth_schedule")
	check(young == young_before,"continuation_state_does_not_mutate_work")

	var weave := _work("weave",7,"",true)
	var theme_score: Dictionary = {"theme":{"cid":"west-1","source_ids":["building-00028"]}}
	var theme_result: Dictionary = Continuation.state(_world(weave,9),weave,theme_score)
	check(theme_result["target_kind"] == "root" and theme_result["root_id"] == "building-00028" and theme_result["action_label"] == "继续改写首作根屋","eligible_theme_route_targets_the_actual_authored_root")
	check(str(Continuation.text(theme_result)).contains("building-00028") and str(Continuation.text(theme_result)).contains("主题资格已满足"),"theme_text_names_real_root_and_qualification")

	var warm := _work("warm",4,"reservation-00042")
	var reserve_result: Dictionary = Continuation.state(_world(warm,2,true),warm,{})
	check(reserve_result["target_kind"] == "reservation" and reserve_result["reservation_id"] == "reservation-00042" and reserve_result["action_label"] == "继续规划真实留地","reserved_route_targets_the_live_reservation_identity")
	check(str(Continuation.text(reserve_result)).contains("reservation-00042") and str(Continuation.text(reserve_result)).contains("留地仍在"),"reservation_text_exposes_actual_land_identity")

	var focus := _work("warm",6,"",true)
	var other_theme: Dictionary = {"theme":{"cid":"east-2","source_ids":["building-00099"]}}
	var focus_result: Dictionary = Continuation.state(_world(focus,9),focus,other_theme)
	check(focus_result["target_kind"] == "root" and not bool(focus_result["root_in_theme"]) and focus_result["action"]["id"] == "building-00028","eligible_route_without_root_source_keeps_real_root_target")

	var missing_world := WorldStub.new()
	var absent: Dictionary = Continuation.state(missing_world,young,{})
	check(not bool(absent.get("available",true)) and str(absent.get("reason","")).contains("不在当前作品"),"removed_root_has_no_replacement_target")
	var text := Continuation.text(young_result)+"\n"+Continuation.text(theme_result)+"\n"+Continuation.text(reserve_result)
	check(not text.contains("将会") and not text.contains("未来") and not text.contains("预告"),"continuation_copy_contains_no_unscheduled_future_claim")

	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Pure continuation target/text over supplied settled first-authored state and World identities; no operation submission, audio rendering, or human preference claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND186_FIRST_AUTHORED_CONTINUATION "+JSON.stringify({"passed":report["passed"],"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)

