extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")

var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _initialize() -> void:
	var world := World.new("2026101000000071",true,"river_valley")
	world.build_expanded_town()
	var model := Model.new(world)
	var score: Dictionary = model.synth.score_snapshot()
	var theme: Dictionary = score.get("theme",{})
	check(not theme.is_empty(),"expanded city has an authored theme")
	check(str(theme.get("cid","")) == "west-2","primary center community leads the first theme")
	check(str(theme.get("center",{}).get("level","")) == "primary","theme carries its center level")
	check(world.center_rank(str(theme.get("cid",""))) == 0,"music selection follows center hierarchy")
	print("CENTER_MUSIC ",JSON.stringify({"failures":failures,"theme":theme,"center_count":world.centers.size()}))
	quit(0 if failures.is_empty() else 1)
