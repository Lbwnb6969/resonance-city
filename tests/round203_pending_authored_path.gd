extends SceneTree
## The next authored seed exposes a spatial link without mutating the city.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const PathLayer = preload("res://scripts/visual/pending_authored_path.gd")
const OUTPUT := "res://验证记录/round203_待播路径/pending_authored_path.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: Control

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)

func _run() -> void:
	demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	var city := World.new("2026101200000203",true,"river_valley")
	city.build_first_composition_starter()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	city.request({"kind":"charter","plan_id":"compact","community_ids":["west-2"],"card_refs":["infill_pulse"]},phrase)
	city.settle(phrase)
	var position: Array = First.opportunities(city)["seed_candidates"][0]["position"]
	var request := city.request(PlayerExpression.operation("warm",position),phrase*2)
	check(bool(request.get("accepted",false)),"real_authored_root_request_is_accepted")
	city.settle(phrase*2)
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.clock.active = true
	demo.set_process(false)
	demo.first_composition_mode = true
	demo.shown_world = city
	var layer: PathLayer = demo.pending_authored_path
	var before := city.snapshot()
	var root_id := str(demo._first_authored_state().get("root_id",""))
	var target := Vector2(float(position[0])+0.9,float(position[1])+0.35)
	demo.pending_expression_choice = {"operation":PlayerExpression.operation("weave",target),"source_model":demo.model}
	layer.sync()
	check(not root_id.is_empty() and layer.line.size() >= 2 and layer.alpha > 0.0 and layer.label.contains("暖庭") and layer.label.contains("织机"),"heard_root_to_pending_expression_draws_path")
	check(city.snapshot() == before,"path_query_does_not_mutate_world")
	demo.pending_expression_choice.clear()
	layer.sync()
	check(layer.line.is_empty() and layer.alpha == 0.0,"withdrawn_pending_expression_clears_path")
	demo.menu.show()
	demo.planning_guide.opened = true
	layer.sync()
	check(layer.line.is_empty(),"planning_or_menu_state_does_not_leave_path_residue")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy production presentation layer over a real authored root and accepted pending seed. Path is read-only, expression-coloured, and clears on withdrawal or planning visibility; no physical audio or human-fun claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND203_PENDING_AUTHORED_PATH ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
