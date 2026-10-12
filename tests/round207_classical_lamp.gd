extends SceneTree
## Exercise the production draw dispatch without a physical window or audio device.
const Prop = preload("res://scripts/visual/valley_prop.gd")
const OUTPUT := "res://验证记录/round207_古典灯具/lamp_contract.json"
var checks: Dictionary = {}
var failures: Array[String] = []

class LampProbe extends Prop:
	var classical_draws := 0
	var retained_draws := 0
	func _draw_classical_lamp() -> void: classical_draws += 1
	func _draw_retained_lamp() -> void: retained_draws += 1

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_audio_only")
	var lamp := LampProbe.new()
	lamp.kind = "lamp"
	lamp._draw()
	check(lamp.era == 1 and lamp.classical_draws == 1 and lamp.retained_draws == 0,"first_era_production_draw_selects_stone_and_terracotta_oil_lamp")
	for later_era in range(2,5):
		lamp.era = later_era
		lamp._draw()
	check(lamp.classical_draws == 1 and lamp.retained_draws == 3,"all_later_eras_keep_the_original_globe_lamp_branch")
	lamp.era = 1
	lamp.motion = 123.0
	lamp.tone = 17
	lamp._draw()
	check(lamp.classical_draws == 2 and lamp.retained_draws == 3,"returning_to_classical_era_does_not_depend_on_motion_or_tone")
	check(lamp.kind == "lamp" and lamp.active and lamp.reveal == 1.0 and lamp.direction == Vector2.RIGHT and lamp.art_entry.is_empty() and lamp.get_child_count() == 0,"era_draw_dispatch_preserves_transport_and_prop_state_without_a_light_node")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"scope":"Dummy production ValleyProp._draw dispatch with branch probes. First-era lamps use fixed stone/terracotta geometry, eras 2-4 retain the original globe branch, and transport/prop state is untouched. Real-window shape review remains with Root."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND207_CLASSICAL_LAMP ",checks.size()-failures.size(),"/",checks.size()," ",JSON.stringify(failures))
	lamp.free()
	quit(0 if failures.is_empty() else 1)
