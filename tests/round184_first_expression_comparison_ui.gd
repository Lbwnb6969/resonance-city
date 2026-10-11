extends SceneTree
## Minimal contract for the first-expression three-route comparison card.
const Card = preload("res://scripts/ui/first_expression_comparison_card.gd")
const OUT := "res://验证记录/round184_首作试听比较/first_expression_comparison_ui.json"
var checks: Dictionary = {}
var failures: Array[String] = []

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var comparison := {"sample_rate":22050,"variants":{
		"deep":{"accepted":true,"pcm":PackedByteArray([1,2,3,4]),"metrics":{"rhythm_profiles":[{"pitch":36,"spacing_frames":44100.0,"tail":1.6}]},"consequences":{"type":"residential","next_growth_phrase":2,"mature":3,"reservation_count":0}},
		"weave":{"accepted":true,"pcm":PackedByteArray([4,3,2,1]),"metrics":{"rhythm_profiles":[{"pitch":72,"spacing_frames":5512.5,"tail":0.12}]},"consequences":{"type":"commercial","next_growth_phrase":1,"mature":4,"reservation_count":0}},
		"warm":{"accepted":true,"pcm":PackedByteArray([8,8,8,8]),"metrics":{"rhythm_profiles":[{"pitch":55,"spacing_frames":88200.0,"tail":2.2}]},"consequences":{"type":"residential","next_growth_phrase":1,"mature":2,"reservation_count":1}}
	}}
	var text := Card.text(comparison,"weave")
	check(text.split("\n").size() == 3,"card_keeps_three_short_route_rows")
	check(text.contains("深流") and text.contains("织机") and text.contains("留地"),"card_lists_all_three_routes")
	check(not text.contains("PCM") and not text.contains("秒") and not text.contains("第1句"),"card_omits_engine_measurements")
	check(text.contains("住宅生长") and text.contains("商业生长") and text.contains("保留1片空地"),"card_reports_real_city_consequences")
	check(text.contains("低音长响，慢慢铺底") and text.contains("高音短促，密集织拍") and text.contains("中音长响，留出空隙"),"card_reports_sound_character_from_actual_profile")
	check(text.contains("▶ 织机") and not text.contains("▶ 深流"),"card_marks_current_choice_only")
	var incomplete := {"variants":{"deep":{"accepted":false,"reason":"落点已占用"}}}
	var incomplete_text := Card.text(incomplete,"deep")
	check(incomplete_text.contains("深流") and incomplete_text.contains("未生成试听") and incomplete_text.contains("落点已占用"),"card_exposes_missing_actual_branch")
	var no_samples := {"variants":{"deep":{"accepted":true,"consequences":{"type":"residential"}}}}
	check(Card.text(no_samples).contains("深流 · 未生成试听") and not Card.text(no_samples).contains("住宅生长"),"accepted_request_without_generated_audio_has_no_actual_result")
	var empty_text := Card.text({},"")
	check(empty_text.is_empty(),"empty_comparison_stays_hidden")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://验证记录/round184_首作试听比较"))
	var file := FileAccess.open(OUT,FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"text":text},"\t"))
	file.close()
	print("ROUND184_FIRST_EXPRESSION_COMPARISON_UI ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
