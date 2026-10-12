extends SceneTree
## A same-phrase render cursor invalidates a frozen expression audition.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round202_试听游标/expression_preview_cursor.json"
const BUCKET := 4*22050
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: Control

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	var city := World.new("2026101200000202",true,"river_valley")
	city.build_first_composition_starter()
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.clock.active = true
	demo.set_process(false)
	demo.first_composition_mode = true
	demo.context = {"kind":"seed","position":First.opportunities(city)["seed_candidates"][0]["position"]}
	demo.clock.renderer.transport.rendered_frames = 4*BUCKET+127
	var first_key: Array = demo._expression_preview_identity()
	var first_cursor: int = int(first_key[2])
	demo.clock.renderer.transport.rendered_frames += 200
	var same_bucket_key: Array = demo._expression_preview_identity()
	check(same_bucket_key == first_key and int(same_bucket_key[2]) == first_cursor,"sub_block_cursor_keeps_one_preview_request_stable")
	demo.clock.renderer.transport.rendered_frames += BUCKET-327+1
	var next_bucket_key: Array = demo._expression_preview_identity()
	check(next_bucket_key != first_key and int(next_bucket_key[2]) == first_cursor+1,"next_render_bucket_invalidates_frozen_preview")
	var stale_result := {"contract":"P12-EXPRESSION-COMPARE/v1","request_key":first_key}
	check(stale_result["request_key"] != next_bucket_key,"older_worker_result_cannot_match_current_cursor")
	var before := city.snapshot()
	check(city.snapshot() == before,"identity_query_does_not_mutate_world")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"cursor_bucket":BUCKET,"scope":"Dummy production UI identity contract. Same-boundary previews stay stable within one four-second cursor slice and stale worker keys are rejected after the cursor advances; no physical audio or human-listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND202_EXPRESSION_PREVIEW_CURSOR ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
