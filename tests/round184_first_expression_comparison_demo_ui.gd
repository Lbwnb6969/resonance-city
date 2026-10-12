extends SceneTree
## Production menu layout contract for the real three-route preview card.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const OUT := "res://验证记录/round206_精制河湾/first_expression_comparison_demo_ui.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: ContinuousValleyDemo

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(800,600)
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.size = Vector2(800,600)
	demo.clock.stop_output()
	demo.set_process(false)
	var city := World.new("2026101100000184",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.size = Vector2(800,600)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.first_composition_mode = true
	var cid := str(First.opportunities(city)["community_ids"][0])
	check(demo._begin_first_sound_choice(cid),"sound_choice_opens_at_real_community")
	var before := demo.model.world.snapshot()
	demo.expression_choice = "weave"
	demo.expression_comparison = {"sample_rate":22050,"variants":{
		"deep":{"accepted":true,"pcm":PackedByteArray([1,2,3,4]),"metrics":{"rhythm_profiles":[{"pitch":36,"spacing_frames":44100.0,"tail":1.6}]},"consequences":{"type":"residential","next_growth_phrase":2,"mature":3,"reservation_count":0}},
		"weave":{"accepted":true,"pcm":PackedByteArray([4,3,2,1]),"metrics":{"rhythm_profiles":[{"pitch":72,"spacing_frames":5512.5,"tail":0.12}]},"consequences":{"type":"commercial","next_growth_phrase":1,"mature":4,"reservation_count":0}},
		"warm":{"accepted":true,"pcm":PackedByteArray([8,8,8,8]),"metrics":{"rhythm_profiles":[{"pitch":55,"spacing_frames":88200.0,"tail":2.2}]},"consequences":{"type":"residential","next_growth_phrase":1,"mature":2,"reservation_count":1}}
	}}
	demo.expression_comparison_key = demo._expression_preview_identity()
	demo._update_expression_menu()
	await process_frame
	var bounds := Rect2(Vector2.ZERO,Vector2(800,600))
	check(demo.menu.visible and bounds.encloses(demo.menu.get_global_rect()),"comparison_card_fits_800x600")
	check(not demo.expression_comparison_summary.visible and demo.expression_comparison_summary.text.split("\n").size() == 3 and demo.expression_comparison_summary.text.contains("高音短促，密集织拍") and demo.expression_summary.text.contains("商业") and not demo.expression_summary.text.contains("PCM"),"illustrated_choices_keep_actual_result_without_three_duplicate_rows")
	check(demo.expression_choices.values().all(func(card: Button) -> bool: return card.visible and card.custom_minimum_size.y >= 90.0 and not card.thumbnail_entry.is_empty()),"three_route_cards_show_actual_building_thumbnails")
	check(demo.model.world.snapshot() == before,"comparison_card_does_not_submit_or_mutate_city")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"card":demo.expression_comparison_summary.text,"menu_rect":demo.menu.get_global_rect(),"selected_result":demo.expression_summary.text}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	FileAccess.open(OUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ROUND184_FIRST_EXPRESSION_COMPARISON_DEMO_UI ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
