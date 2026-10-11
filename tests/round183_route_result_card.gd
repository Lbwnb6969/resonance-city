extends SceneTree
## Minimal contract for the first authored route result card.
## It accepts only supplied real state; no route is invented when absent.
const Card = preload("res://scripts/ui/first_authored_route_result.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _work(route: String,midi: int,houses: int,reservation: String = "") -> Dictionary:
	return {"expression":route,"community_id":"west-1","community_name":"松丘",
		"root_id":"building-00028","family_id":"family-00028","position":[1.0,2.0],"form":"央",
		"current_midi":midi,"base_midi":PlayerPitch(route),"theme_eligible":houses >= 6,
		"theme_playing":houses >= 6,"root_in_theme":houses >= 6,"family_houses":houses,
		"next_growth_phrase":9,"reservation_id":reservation,"mature":houses,
		"community_houses":houses+4,"missing_conditions":[] if houses >= 6 else ["还需%d栋成熟房屋" % (6-houses)],
		"met_conditions":["六栋成熟房屋"] if houses >= 6 else [],"civic_support":true}

func PlayerPitch(route: String) -> int:
	return {"deep":36,"weave":60,"warm":48}.get(route,36)

func _run() -> void:
	var deep := _work("deep",36,4)
	var weave := _work("weave",64,7)
	var warm := _work("warm",52,6,"reservation-00042")
	var weave_score := {"rhythms":[{"cid":"west-1","midi":64,"source_id":"building-00028","expression":"weave"}],
		"theme":{"cid":"west-1","source_ids":["building-00028"]},"response":{"cid":"west-1"}}
	var mixed_score := {"rhythms":[{"cid":"west-1","midi":36,"source_id":"building-00041","expression":"deep","player_expression":false}]}
	var warm_score := {"theme":{"cid":"west-1","source_ids":["building-00028"]}}
	var before := weave.duplicate(true)
	var card := Card.summary(weave,weave_score)
	check(bool(card["available"]) and card["route"] == "weave","settled_route_is_available")
	check(card["register"]["current_label"] == "E4" and card["register"]["base_label"] == "C4" and card["register"]["changed"],"retuned_register_uses_actual_current_and_birth_pitch")
	check(card["rhythm"]["active"] and card["rhythm"]["pitch_label"] == "E5" and is_equal_approx(float(card["rhythm"]["spacing_beats"]),0.5),"actual_rhythm_reports_real_slot_pitch_spacing_and_tail")
	var mixed_card := Card.summary(weave,mixed_score)
	check(mixed_card["rhythm"]["source_expression"] == "deep" and str(mixed_card["rhythm"]["text"]).contains("每4.00拍"),"mixed_slot_reports_explicit_actual_route")
	check(str(card["theme"]["next"]).contains("改一个音"),"theme_next_step_points_to_actual_root_rewrite")
	check(weave == before,"summary_does_not_mutate_supplied_work")
	var warm_card := Card.summary(warm,warm_score)
	check(bool(warm_card["reserve"]["active"]) and warm_card["reserve"]["id"] == "reservation-00042" and str(warm_card["reserve"]["text"]).contains("真实空地"),"warm_reports_only_the_live_reservation_identity")
	check(Card.summary(deep)["rhythm"]["active"] == false and Card.summary(deep)["rhythm"]["pitch_label"] == "C2","missing_score_does_not_invent_an_active_rhythm")
	var comparison := Card.compare({"deep":deep,"weave":weave,"warm":warm},{"weave":weave_score,"warm":warm_score})
	check(comparison["complete"] and comparison["available"] == ["deep","weave","warm"] and comparison["missing"].is_empty(),"three_supplied_routes_compare_without_invented_results")
	var partial := Card.compare({"weave":weave},{"weave":weave_score})
	check(not partial["complete"] and partial["missing"] == ["deep","warm"] and partial["routes"].has("weave"),"comparison_keeps_absent_routes_explicitly_missing")
	check(str(Card.comparison_text(partial)).contains("未提供实际结果：深流、留地"),"comparison_text_exposes_missing_actual_routes")
	var unknown := Card.summary({"expression":"future"})
	check(not unknown["available"] and str(unknown["reason"]).contains("未知路线"),"unknown_route_is_refused_without_fallback_claim")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Pure player-facing result formatting over supplied first_authored_state dictionaries; no World mutation, audio rendering, or human preference claim."}
	var path := "res://验证记录/round183_首作路线结果/route_result_card.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND183_ROUTE_RESULT_CARD "+JSON.stringify({"passed":report["passed"],"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
