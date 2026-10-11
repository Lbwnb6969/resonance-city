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
	var comparison := {"variants":{
		"deep":{"accepted":true,"pcm":PackedByteArray([1,2,3,4]),"consequences":{"type":"residential","next_growth_phrase":2,"mature":3,"reservation_count":0}},
		"weave":{"accepted":true,"pcm":PackedByteArray([4,3,2,1]),"consequences":{"type":"commercial","next_growth_phrase":1,"mature":4,"reservation_count":0}},
		"warm":{"accepted":true,"pcm":PackedByteArray([8,8,8,8]),"consequences":{"type":"residential","next_growth_phrase":1,"mature":2,"reservation_count":1}}
	}}
	var text := Card.text(comparison,"weave")
	check(text.contains("同一冻结下一句") and text.contains("未提交"),"card_marks_preview_as_uncommitted")
	check(text.contains("深流") and text.contains("织机") and text.contains("留地"),"card_lists_all_three_routes")
	check(text.contains("PCM与织机、留地不同") and text.contains("PCM与深流、留地不同"),"card_reports_actual_pcm_differences")
	check(text.contains("商业") and text.contains("第1句") and text.contains("保留1片真实空地"),"card_reports_real_city_consequences")
	check(text.contains("▶ 织机") and not text.contains("▶ 深流"),"card_marks_current_choice_only")
	var incomplete := {"variants":{"deep":{"accepted":false,"reason":"落点已占用"}}}
	var incomplete_text := Card.text(incomplete,"deep")
	check(incomplete_text.contains("深流") and incomplete_text.contains("未生成实际试听") and incomplete_text.contains("落点已占用"),"card_exposes_missing_actual_branch")
	var empty_text := Card.text({},"")
	check(empty_text.is_empty(),"empty_comparison_stays_hidden")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://验证记录/round184_首作试听比较"))
	var file := FileAccess.open(OUT,FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"text":text},"\t"))
	file.close()
	print("ROUND184_FIRST_EXPRESSION_COMPARISON_UI ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
