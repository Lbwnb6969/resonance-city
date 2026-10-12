extends SceneTree
## Only the false-value mute map regression; the 10 UI checks remain separate.
const Panel = preload("res://scripts/ui/community_workbench.gd")
const World = preload("res://scripts/world/continuous_world.gd")
const OUTPUT := "res://验证记录/round214_社区工作台/false_mute_contract.json"

class HeardModel extends RefCounted:
	var score := {"listener_community":"","focused_community":"","muted_communities":{"west-2":false}}
	func audible_pitches() -> Dictionary: return {}
	func audible_score() -> Dictionary: return score

class Fixture extends Control:
	var shown_world: RefCounted
	var black := false
	var clock := {"renderer":{"transport":{"audible_frame":0}}}
	var model := HeardModel.new()

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var fixture := Fixture.new()
	fixture.size = Vector2(800,600)
	fixture.shown_world = World.new("2026100900000062",true,"river_valley")
	fixture.shown_world.build_first_composition_starter()
	root.add_child(fixture)
	var panel := Panel.new()
	panel.setup(fixture)
	fixture.add_child(panel)
	var before: Dictionary = fixture.shown_world.snapshot()
	panel.open_community("west-2")
	var disabled: Array[bool] = [panel.all_city_button.disabled]
	fixture.model.score["muted_communities"]["west-1"] = true
	panel.sync()
	disabled.append(panel.all_city_button.disabled)
	fixture.model.score["muted_communities"]["west-1"] = false
	fixture.model.score["listener_community"] = "east-2"
	panel.sync()
	disabled.append(panel.all_city_button.disabled)
	fixture.model.score["listener_community"] = ""
	fixture.model.score["focused_community"] = "west-2"
	panel.sync()
	disabled.append(panel.all_city_button.disabled)
	var passed: bool = AudioServer.get_driver_name() == "Dummy" and disabled == [true,false,false,false] and fixture.shown_world.snapshot() == before
	var report := {"passed":passed,"checks":{"false_mute_values_do_not_enable_full_city_but_true_mute_solo_or_focus_do":passed},"disabled_sequence":disabled,"scope":"One Dummy UI mute-value regression over real starter; no production Demo, GPU, audio device or repeat of original 10 checks."}
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND214_FALSE_MUTE ","1/1" if passed else "0/1")
	quit(0 if passed else 1)
