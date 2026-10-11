extends SceneTree
const Guide = preload("res://scripts/ui/first_composition_guide.gd")
const OUTPUT := "res://验证记录/round182_首作接续/first_authored_guide.json"
var checks: Dictionary = {}
var failures: Array[String] = []

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

class WorldStub extends RefCounted:
	var development_charters: Array = []
	var planning_reservations: Array = []
	var public_sites: Array = []
	var pending_actions: Array = []

class ModelStub extends RefCounted:
	var world := WorldStub.new()

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
	func _begin_first_authored_theme() -> bool:
		begin_calls += 1
		return true

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _state(root_id: String = "building-00001", eligible: bool = false, heard: bool = false) -> Dictionary:
	return {"root_id":root_id,"community_id":"west-1","community_name":"松丘","expression":"deep",
		"theme_eligible":eligible,"theme_playing":true,"root_in_theme":true,"root_heard_retune":heard,
		"retuned":heard,"family_houses":6,"next_growth_phrase":4,"reservation_id":""}

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
	demo.clock.renderer.transport.audible_frame = 10.0*demo.clock.renderer.transport.sample_rate
	guide.sync()
	check(guide.visible and guide.action == "planning" and guide.text == "写第一段 · 选择发展章程","first_overture_keeps_single_planning_invitation")
	guide.emit_signal("pressed")
	check(demo.planning_guide.opened and guide.entered and not guide.visible,"planning_invitation_enters_existing_guide_once")
	demo.planning_guide.opened = false
	demo.authored = _state("building-00001",false,false)
	guide.sync()
	check(guide.visible and guide.action == "growth" and guide.disabled and guide.text.contains("你种下的深流在生长"),"author_root_shows_one_disabled_growth_status_before_theme_eligibility")
	demo.authored = _state("building-00001",true,false)
	guide.sync()
	check(guide.visible and not guide.disabled and guide.action == "theme" and guide.text == "松丘 · 改写你种下的深流","eligible_theme_offers_authored_root_entry")
	guide.emit_signal("pressed")
	check(demo.begin_calls == 1 and not guide.visible,"theme_entry_calls_root_focus_without_selecting_or_submitting")
	guide.sync()
	check(guide.visible,"theme_entry_remains_until_actual_root_is_heard")
	demo.authored = _state("building-00001",true,true)
	guide.sync()
	check(not guide.visible and guide.heard_root == "building-00001","actual_audible_retune_stops_repeated_theme_invitation")
	demo.authored = _state("building-00002",true,false)
	guide.sync()
	check(guide.visible and guide.authored_state["root_id"] == "building-00002","restored_or_new_author_root_can_receive_its_own_entry")
	demo.menu.visible = true
	guide.sync()
	check(not guide.visible,"menu_hides_light_entry")
	demo.menu.hide()
	demo.clock.active = false
	guide.sync()
	check(not guide.visible,"paused_clock_hides_light_entry")
	demo.clock.active = true
	demo.authored = {}
	demo.shown_world.development_charters.append({"charter_id":"charter-1"})
	guide.entered = false
	guide.sync()
	check(not guide.visible,"existing_work_does_not_reinvite_first_overture")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy UI only; root state and audible retune are supplied by production Demo APIs; no device or listening claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("ROUND182_FIRST_AUTHORED_GUIDE "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
