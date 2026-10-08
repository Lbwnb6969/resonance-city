class_name UIContractTest
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Presenter = preload("res://scripts/ui/proposal_presentation.gd")
const Values = preload("res://scripts/spec_values.gd")

func _initialize() -> void:
	call_deferred("_run")

func fixture() -> Array:
	return [Schema.create("home","residential",Vector2i(2,6)),
		Schema.create("factory","industrial",Vector2i(3,6)),
		Schema.create("shop","commercial",Vector2i(4,6))]

func _run() -> void:
	var test := Contract.new("UI-002",Contract.selected_case("proposal_cost"))
	test.check(test.case_name == "proposal_cost","Supported case: proposal_cost")
	var city := Session.new(fixture(),"2026100800000001")
	var period := city.transport.phrase_frame(1)
	city.request({"proposal_id":"p0:0:factory:retune","target":55},period-1,0.5*period)
	var result := city.settle(period)
	var text := Presenter.describe(result)
	var epsilon: float = Values.load_values()["city"]["comparison_tolerance"]
	test.check(absf(float(text["before_r"])-15.0) <= epsilon and absf(float(text["after_r"])-75.0) <= epsilon,"Displayed R reflects both actual neighbor edges")
	test.check(text["old_edges"]["factory / home"]["name"] == "三全音","Existing industrial/home relation is a tritone")
	test.check(text["new_edges"]["factory / home"]["name"] == "纯五 / 纯四","Retuned relation reflects the actual fifth")
	test.check(text["changes"].size() == 2 and text["text"].contains("改造 -10 活力"),"Cost and both interval changes are visible together")
	test.check(text["text"].contains("factory：50.0 → 46.0"),"Negative net vitality is not hidden")
	var migration := Session.new(fixture(),"2026100800000001")
	migration.request({"proposal_id":"p0:0:factory:relocate","target":[12,12]},period-1,0.5*period)
	var moved := Presenter.describe(migration.settle(period))
	test.check(moved["new_edges"].is_empty() and moved["changes"].size() == 2,"All lost original neighbor relations displayed")
	test.check(moved["text"].contains("静音 1 乐句（16 秒）") and moved["text"].contains("原邻居"),"One-phrase silence and lost relationships are explicit")
	var scene: PackedScene = load("res://scenes/p0_main.tscn")
	var main: Control = scene.instantiate()
	main.start_audio_on_ready = false
	root.add_child(main)
	await process_frame
	main.set_black_screen(true)
	test.check(not main.panel.visible,"Black screen hides every operation control; cursor requires a display driver")
	main.set_black_screen(false)
	test.check(main.panel.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Return restores minimal operation controls")
	main.queue_free()
	await process_frame
	test.details = {"retune_before_r":text["before_r"],"retune_after_r":text["after_r"],"text":text["text"],
		"migration_text":moved["text"],"human_black_screen":"PENDING"}
	test.finish(self,"Actual preview presenter plus real main-scene black-screen toggles; no full P1 HUD")
