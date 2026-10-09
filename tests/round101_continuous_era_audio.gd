extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const EraVoice = preload("res://scripts/audio/era_voice.gd")
const Config = preload("res://scripts/world/world_values.gd")

var failures: Array[String] = []
var checks: Dictionary = {}

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	var world := World.new("2026101000000101",true,"river_valley")
	world.build_starter("bright")
	world.phrase_index = 11
	world.era = 1
	var model := Model.new(world)
	var state: Dictionary = {}
	var boundary := model.next_boundary
	var before := model.render_block(state,boundary-1,1,rate)
	var after := model.render_block(state,boundary,512,rate)
	var era_changes := model.synth.era_snapshot()
	check(world.era == 2,"continuous world enters era II at the boundary")
	check(era_changes.size() == world.buildings.size(),"existing buildings receive era transition routes")
	check(model.transition_total == roundi(0.08*rate),"era boundary uses the structural audio seam")
	var seam_jump := (after[0]-before[-1]).length()
	check(seam_jump < 0.000001,"era transition keeps the PCM boundary continuous")
	var old_table := EraVoice.table("residential",1,256)
	var new_table := EraVoice.table("residential",2,256)
	var table_delta := 0.0
	for i in range(old_table.size()): table_delta = maxf(table_delta,absf(old_table[i]-new_table[i]))
	check(table_delta > 0.001,"era II uses a distinct bounded timbre")
	var saved := model.capture_state()
	var restored := Model.from_state(saved)
	check(restored.synth.era_snapshot() == era_changes,"era transition survives City DNA audio restore")
	var free_lot: Dictionary = {}
	for lot in world.lots:
		if str(lot.get("occupant","")).is_empty() and world.placement(Vector2(lot["center"][0],lot["center"][1]))["allowed"]:
			free_lot = lot
			break
	var submitted := model.submit({"kind":"seed","position":free_lot["center"],"midi":48})
	check(bool(submitted.get("accepted",false)),"era II still accepts a normal seed")
	var birth_boundary := model.next_boundary
	model.render_block(state,birth_boundary,1,rate)
	var born := world.buildings.filter(func(building: Dictionary) -> bool: return int(building.get("birth_frame",0)) == birth_boundary)
	check(not born.is_empty() and born.all(func(building: Dictionary) -> bool: return int(building.get("era",0)) == 2),"new buildings inherit the current era")
	print("CONTINUOUS_ERA_AUDIO ",JSON.stringify({"checks":checks,"failures":failures,"seam_jump":seam_jump,"table_delta":table_delta,"era_changes":era_changes.size(),"born":born.size()}))
	quit(0 if failures.is_empty() else 1)
