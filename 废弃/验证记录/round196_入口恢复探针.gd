extends SceneTree
const Guide = preload("res://scripts/ui/first_composition_guide.gd")

class PlanningStub extends Control:
	var opened := false
	var open_calls := 0
	func open_tool() -> void:
		opened = true
		open_calls += 1

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
	func _first_authored_state() -> Dictionary: return {}

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var demo := DemoStub.new()
	root.add_child(demo)
	demo.add_child(demo.planning_guide)
	demo.add_child(demo.clock)
	demo.clock.add_child(demo.clock.player)
	demo.add_child(demo.menu)
	demo.menu.hide()
	var entry := Guide.new()
	demo.add_child(entry)
	entry.setup(demo)
	entry.reset_for_city()
	demo.clock.renderer.transport.audible_frame = 5.0 * demo.clock.renderer.transport.sample_rate
	entry.sync()
	var initial_visible := entry.visible
	entry.emit_signal("pressed")
	var first_open := demo.planning_guide.opened
	demo.planning_guide.opened = false
	entry.sync()
	var resumed_visible := entry.visible and entry.text == "继续塑造第一段"
	entry.emit_signal("pressed")
	var second_open := demo.planning_guide.opened and demo.planning_guide.open_calls == 2
	var unchanged := demo.model.world.pending_actions.is_empty() and demo.shown_world.development_charters.is_empty() and demo.shown_world.planning_reservations.is_empty() and demo.shown_world.public_sites.is_empty()
	var passed := initial_visible and first_open and resumed_visible and second_open and unchanged
	print("ROUND196_FIRST_ENTRY_RESUME ", JSON.stringify({"passed":passed,"initial_visible":initial_visible,"first_open":first_open,"resumed_visible":resumed_visible,"second_open":second_open,"world_unchanged":unchanged,"scope":"Dummy UI open, close, sync and reopen; no physical audio or window"}))
	demo.free()
	await process_frame
	quit(0 if passed else 1)
