extends SceneTree
## P12 result contract: turn one real preview transaction into a readable,
## side-by-side comparison without inventing a route or mutating the source.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Preview = preload("res://scripts/world/expression_preview.gd")
const Compare = preload("res://scripts/world/expression_compare_result.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const OUTPUT := "res://验证记录/round184_首句路线比较/expression_compare_result.json"

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _advance(model: Model,phases: Dictionary,begin: int,end: int) -> void:
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for at in range(begin,end,512): model.render_block(phases,at,mini(512,end-at),rate)

func _run() -> void:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var model := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var opportunities := First.opportunities(city)
	var position: Array = opportunities["seed_candidates"][0]["position"]
	var public_position: Array = opportunities["public_candidates"][0]["position"]
	var phases: Dictionary = {}
	var cursor := model.next_boundary-128
	_advance(model,phases,0,cursor)
	check(bool(model.submit({"kind":"charter","plan_id":"compact","community_ids":["west-1"]})["accepted"]),"same_source_charter_is_accepted")
	check(bool(model.submit({"kind":"civic","position":public_position})["accepted"]),"same_source_public_anchor_is_accepted")
	var root_id := str(city.buildings[0]["district_id"])
	check(bool(model.submit({"kind":"retune","id":root_id,"midi":52})["accepted"]),"same_source_retune_is_accepted")
	check(bool(model.submit({"kind":"focus","community":"west-1"})["accepted"]),"same_source_focus_is_accepted")
	var source_state := model.capture_state()
	var source_phases := phases.duplicate(true)
	var comparison := Preview.build(model,position,phases,cursor)
	var result := Compare.summary(comparison)
	check(result["contract"] == "P12-EXPRESSION-COMPARE-RESULT/v1","comparison_result_has_stable_contract")
	check(bool(result["complete"]) and bool(result["actual_only"]),"comparison_result_contains_three_actual_routes_only")
	check(bool(result["source"]["same_source"]) and result["source"]["key"] == str(comparison["source_key"]) and int(result["source"]["frame"]) == cursor,"comparison_result_keeps_one_source_identity")
	check(int(result["audio"]["sample_rate"]) == rate and int(result["audio"]["duration_frames"]) == rate*4 and is_equal_approx(float(result["audio"]["seconds"]),4.0),"comparison_result_reports_real_rate_and_four_second_window")
	var routes: Dictionary = result["routes"]
	for id: String in PlayerExpression.IDS:
		var route: Dictionary = routes[id]
		check(bool(route["actual"]) and int(route["audio"]["pcm_bytes"]) == rate*4*4 and int(route["audio"]["pcm_frames"]) == rate*4,id+"_reports_full_actual_pcm_window")
		check(int(route["audio"]["max_voices"]) <= 70 and float(route["audio"]["peak"]) > 0.0 and float(route["audio"]["peak"]) < 1.0,id+"_reports_real_voice_and_peak_bounds")
		check(str(route["source"]["community_id"]) == "west-1" and str(route["city"]["expression"]) == id,id+"_keeps_actual_source_and_city_expression")
		check(int(route["rhythm"]["event_count"]) > 0 and float(route["rhythm"]["spacing_seconds"]) > 0.0 and float(route["rhythm"]["tail_seconds"]) > 0.0,id+"_reports_actual_rhythm_events_spacing_and_tail")
	check(int(routes["deep"]["register"]["midi"]) < int(routes["warm"]["register"]["midi"]) and int(routes["warm"]["register"]["midi"]) < int(routes["weave"]["register"]["midi"]),"three_routes_report_distinct_registers")
	check(float(routes["weave"]["rhythm"]["spacing_seconds"]) < float(routes["deep"]["rhythm"]["spacing_seconds"]) and float(routes["deep"]["rhythm"]["spacing_seconds"]) < float(routes["warm"]["rhythm"]["spacing_seconds"]),"three_routes_report_distinct_rhythm_spacing")
	check(int(routes["deep"]["city"]["next_growth_phrase"]) > int(routes["weave"]["city"]["next_growth_phrase"]) and str(routes["weave"]["city"]["building_type"]) == "commercial" and str(routes["warm"]["city"]["building_type"]) == "residential","three_routes_report_actual_growth_type_and_timing_consequences")
	check(int(routes["warm"]["city"]["reservation_count"]) == 1 and int(routes["deep"]["city"]["reservation_count"]) == 0 and int(routes["weave"]["city"]["reservation_count"]) == 0,"keep_land_reports_only_the_actual_warm_reservation")
	for pair: String in ["deep_weave","deep_warm","weave_warm"]:
		check(float(result["pair_pcm_max_abs"][pair]) > 0.005,pair+"_reports_measured_pcm_difference")
	var readable := Compare.text(result)
	check(readable.contains("深流") and readable.contains("织机") and readable.contains("暖庭"),"readable_result_names_all_routes")
	check(readable.split("\n").size() == 3 and not readable.contains("PCM") and readable.contains("低音长响") and readable.contains("高音短促"),"readable_result_exposes_three_plain_sound_choices")
	check(readable.contains("住宅生长") and readable.contains("商业生长") and readable.contains("保留1片空地"),"readable_result_exposes_city_consequences")
	check(Compare.technical_text(result).contains("PCM差异（实际试听）") and Compare.technical_text(result).contains("每"),"technical_details_remain_available_separately")
	check(model.capture_state() == source_state and phases == source_phases,"comparison_result_does_not_mutate_live_source")
	var evidence := {"contract":result["contract"],"passed":failures.is_empty(),"source":result["source"],"audio":result["audio"],"routes":{},"pair_pcm_max_abs":result["pair_pcm_max_abs"],"readable":readable,
		"scope":"Read-only summary over ExpressionPreview's real same-source PCM and branch consequences; no human preference or sound-quality verdict."}
	for id: String in PlayerExpression.IDS:
		var route: Dictionary = routes[id]
		evidence["routes"][id] = {"route_label":route["route_label"],"source":route["source"],"audio":route["audio"],"register":route["register"],"rhythm":{"spacing_seconds":route["rhythm"]["spacing_seconds"],"tail_seconds":route["rhythm"]["tail_seconds"],"event_count":route["rhythm"]["event_count"]},"city":route["city"]}
	var path := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence},"  ")+"\n")
	print("ROUND184_EXPRESSION_COMPARE_RESULT "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures,"readable":readable}))
	quit(0 if failures.is_empty() else 1)
