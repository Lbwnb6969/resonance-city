extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Config = preload("res://scripts/world/world_values.gd")

var failures: Array[String] = []
var evidence: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := World.new("2026101000000098",true,"river_valley")
	world.build_starter("bright")
	var model := Model.new(world)
	var state: Dictionary = {}
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	var phrase := model.phrase_frames
	var previous := Vector2.ZERO
	var max_boundary_jump := 0.0
	var max_adjacent_delta := 0.0
	var max_structural_seam := 0
	var upgrade_boundaries := 0
	for phrase_index in range(1,7):
		var boundary := phrase_index*phrase
		var before := model.render_block(state,boundary-512,512,rate)
		var after := model.render_block(state,boundary,2048,rate)
		var boundary_jump := (after[0]-before[-1]).length()
		var seam_total := model.transition_total
		var local_max := 0.0
		for i in range(1,after.size()):
			local_max = maxf(local_max,(after[i]-after[i-1]).length())
		var upgrades := world.events.filter(func(event: Dictionary) -> bool:
			return int(event.get("frame",-1)) == boundary and str(event.get("kind","")) == "upgrade")
		if not upgrades.is_empty():
			upgrade_boundaries += 1
			max_structural_seam = maxi(max_structural_seam,seam_total)
		max_boundary_jump = maxf(max_boundary_jump,boundary_jump)
		max_adjacent_delta = maxf(max_adjacent_delta,local_max)
		evidence.append({"phrase":phrase_index,"boundary_jump":boundary_jump,"local_max":local_max,"seam_total":seam_total,"upgrades":upgrades.size()})
	var passed := upgrade_boundaries > 0 and max_boundary_jump < 0.000001 and max_adjacent_delta < 0.025 and max_structural_seam >= roundi(0.08*rate)
	print("GROWTH_AUDIO_POP ",JSON.stringify({"passed":passed,"upgrade_boundaries":upgrade_boundaries,"max_boundary_jump":max_boundary_jump,"max_adjacent_delta":max_adjacent_delta,"max_structural_seam":max_structural_seam,"evidence":evidence}))
	quit(0 if passed else 1)
