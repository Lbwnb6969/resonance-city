extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Config = preload("res://scripts/world/world_values.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := World.new("2026101000000116",true,"river_valley")
	world.build_expanded_town()
	var model := Model.new(world)
	var state: Dictionary = {}
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	var phrase := model.phrase_frames
	var max_boundary_jump := 0.0
	var max_adjacent_delta := 0.0
	var max_peak := 0.0
	var max_render_voices := 0
	var max_budget_shed := 0
	var birth_count := 0
	for phrase_index in range(1,5):
		var boundary := phrase_index*phrase
		var before := model.render_block(state,boundary-1024,1024,rate)
		var after := model.render_block(state,boundary,4096,rate)
		max_boundary_jump = maxf(max_boundary_jump,(after[0]-before[-1]).length())
		for i in range(1,after.size()):
			max_adjacent_delta = maxf(max_adjacent_delta,(after[i]-after[i-1]).length())
		for sample in after: max_peak = maxf(max_peak,sample.length())
		max_render_voices = maxi(max_render_voices,int(model.synth.voice_group_stats.get("render_voices",0)))
		max_budget_shed = maxi(max_budget_shed,int(model.synth.voice_group_stats.get("budget_shed",0)))
		var births := world.events.filter(func(event: Dictionary) -> bool:
			return int(event.get("frame",-1)) == boundary and str(event.get("kind","")) == "birth")
		birth_count += births.size()
	_check(birth_count > 0,"expanded town produces birth events")
	_check(max_boundary_jump < 0.000001,"birth boundary is sample continuous")
	_check(max_adjacent_delta < 0.025,"birth seam has no audible step")
	_check(max_peak < 0.95,"birth seam stays below output peak")
	_check(max_render_voices <= 70,"expanded city stays within the 70 voice budget")
	_check(max_budget_shed > 0,"expanded city exercises voice rotation instead of over-budget rendering")
	print("AUDIO_BIRTH_POP ",JSON.stringify({"passed":failures.is_empty(),"births":birth_count,"max_boundary_jump":max_boundary_jump,"max_adjacent_delta":max_adjacent_delta,"max_peak":max_peak,"max_render_voices":max_render_voices,"max_budget_shed":max_budget_shed,"transition_total":model.transition_total,"failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)
