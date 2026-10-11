extends SceneTree
## Production guide contract for a real authored child after growth.
const Guide = preload("res://scripts/ui/first_composition_guide.gd")
const OUTPUT := "res://验证记录/round187_首作成长结果/first_authored_growth_ui.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class WorldStub extends RefCounted:
	var by_id: Dictionary = {}
	var families: Dictionary = {}
	var events: Array = []
	var planning_reservations: Array = []
	var phrase_index := 4
	func snapshot() -> Dictionary: return {"buildings":by_id.keys()}
	func planning_at(_position: Vector2) -> Dictionary: return {}

class PlanningStub extends Control:
	var opened := false
	func open_tool() -> void: opened = true

class TransportStub extends RefCounted:
	var audible_frame := 0.0
	var sample_rate := 22050

class RendererStub extends RefCounted:
	var transport := TransportStub.new()

class ClockStub extends Node:
	var active := true
	var renderer := RendererStub.new()
	var player := AudioStreamPlayer.new()

class ModelStub extends RefCounted:
	func audible_score() -> Dictionary: return {}

class DemoStub extends Control:
	var first_composition_mode := true
	var black := false
	var planning_guide := PlanningStub.new()
	var clock := ClockStub.new()
	var menu := Control.new()
	var model := ModelStub.new()
	var shown_world := WorldStub.new()
	var authored: Dictionary = {}
	var begin_calls := 0
	func _first_authored_state() -> Dictionary: return authored.duplicate(true)
	func _begin_first_authored_continuation() -> bool:
		begin_calls += 1
		return true

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var demo := DemoStub.new()
	root.add_child(demo)
	root.add_child(demo.clock)
	root.add_child(demo.planning_guide)
	root.add_child(demo.menu)
	demo.menu.hide()
	demo.shown_world.by_id["building-00028"] = {"district_id":"building-00028","family_id":"family-00028","community_id":"west-1","position":[1.0,2.0],"form":"央","birth_frame":0}
	demo.shown_world.by_id["building-00029"] = {"district_id":"building-00029","family_id":"family-00028","community_id":"west-1","position":[3.0,4.0],"form":"胚","birth_frame":220,"current_midi":36}
	demo.shown_world.families["family-00028"] = {"root":"building-00028","next_growth_phrase":9,"expression_reservation_id":""}
	demo.shown_world.events = [{"kind":"birth","district_id":"building-00028","frame":0,"phrase":0},{"kind":"birth","district_id":"building-00029","frame":220,"phrase":2}]
	demo.authored = {"root_id":"building-00028","family_id":"family-00028","community_id":"west-1","community_name":"松丘","expression":"deep","theme_eligible":false,"root_heard_retune":false,"family_houses":4,"next_growth_phrase":9,"reservation_id":""}
	var guide := Guide.new()
	demo.add_child(guide)
	guide.setup(demo)
	guide.reset_for_city()
	guide.sync()
	check(guide.visible and guide.action == "continuation" and not guide.disabled and guide.text.contains("定位最近新屋"),"growth_entry_names_the_real_latest_child")
	guide.emit_signal("pressed")
	check(demo.begin_calls == 1 and not guide.visible,"growth_entry_delegates_real_child_focus_without_submit")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy guide entry over an observed authored child; no operation submission, audio or human preference claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND187_FIRST_AUTHORED_GROWTH_UI "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
