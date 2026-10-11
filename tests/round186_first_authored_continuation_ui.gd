extends SceneTree
## UI contract for the actionable post-route continuation entry.
const Guide = preload("res://scripts/ui/first_composition_guide.gd")
const OUTPUT := "res://验证记录/round186_首作续作反馈/first_authored_continuation_ui.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class WorldStub extends RefCounted:
	var by_id: Dictionary = {}
	var families: Dictionary = {}
	var events: Array = []
	var planning_reservations: Array = []
	var phrase_index := 2
	func snapshot() -> Dictionary: return {"root":by_id.keys(),"reservations":planning_reservations.duplicate(true)}
	func planning_at(_position: Vector2) -> Dictionary:
		return planning_reservations[0].duplicate(true) if not planning_reservations.is_empty() else {}

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
	var world := RefCounted.new()
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

func _state(reservation_id: String = "") -> Dictionary:
	return {"root_id":"building-00028","family_id":"family-00028","community_id":"west-1","community_name":"松丘",
		"expression":"deep","theme_eligible":false,"root_heard_retune":true,"retuned":true,"family_houses":4,
		"next_growth_phrase":9,"reservation_id":reservation_id,"mature":4,"community_houses":8}

func _world(reservation_id: String = "") -> WorldStub:
	var world := WorldStub.new()
	world.by_id["building-00028"] = {"district_id":"building-00028","family_id":"family-00028","community_id":"west-1","position":[1.0,2.0],"form":"央"}
	world.families["family-00028"] = {"root":"building-00028","next_growth_phrase":9,"expression_reservation_id":reservation_id}
	if not reservation_id.is_empty(): world.planning_reservations.append({"reservation_id":reservation_id,"position":[3.0,4.0]})
	return world

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var demo := DemoStub.new()
	root.add_child(demo)
	root.add_child(demo.clock)
	root.add_child(demo.planning_guide)
	root.add_child(demo.menu)
	demo.menu.hide()
	var guide := Guide.new()
	demo.add_child(guide)
	guide.setup(demo)
	guide.reset_for_city()
	demo.authored = _state()
	demo.shown_world = _world()
	guide.sync()
	check(guide.visible and guide.action == "continuation" and not guide.disabled and guide.text.contains("沿社区继续组合"),"heard_root_keeps_real_community_continuation_entry_before_theme")
	guide.emit_signal("pressed")
	check(demo.begin_calls == 1 and not guide.visible,"house_continuation_entry_delegates_real_target_without_submit")
	demo.begin_calls = 0
	demo.authored = _state("reservation-00042")
	demo.shown_world = _world("reservation-00042")
	guide.sync()
	check(guide.visible and guide.action == "continuation" and guide.text.contains("定位真实留地") and guide.tooltip_text.contains("留地"),"warm_route_continuation_entry_names_live_reservation")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy UI entry over derived live root/reservation target; no operation submission, audio or human preference claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND186_FIRST_AUTHORED_CONTINUATION_UI "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
