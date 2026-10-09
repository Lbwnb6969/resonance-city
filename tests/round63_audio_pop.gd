extends SceneTree
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world := World.new()
	world.build_starter("bright")
	var lot: Dictionary = world.lots.filter(func(candidate: Dictionary) -> bool: return candidate["occupant"] == "")[0]
	var model := Model.new(world)
	model.submit({"kind":"seed","position":lot["center"],"midi":50})
	var state: Dictionary = {}
	var boundary: int = model.next_boundary
	var before := PackedVector2Array()
	for start in range(0,boundary,512):
		before = model.render_block(state,start,mini(512,boundary-start),22050)
	var after := model.render_block(state,boundary,22050,22050)
	var birth_jump := (after[0]-before[-1]).length()
	var id: String = world.buildings[0]["district_id"]
	var request: Dictionary = model.submit({"kind":"retune","id":id,"midi":57})
	var event_frame: int = int(request["sound_frame"])
	var to_event := model.render_block(state,model.rendered_until,event_frame-model.rendered_until,22050)
	var retune := model.render_block(state,event_frame,22050,22050)
	var retune_jump := (retune[0]-to_event[-1]).length()
	var dc := Vector2.ZERO
	var energy := 0.0
	var jump := 0.0
	for i in range(after.size()):
		dc += after[i]/float(after.size())
		energy += after[i].length_squared()/float(after.size())
		if i > 0: jump = maxf(jump,(after[i]-after[i-1]).length())
	var result := {"boundary":boundary,"birth_jump":birth_jump,"retune_jump":retune_jump,
		"max_adjacent_delta":jump,"dc":dc,"rms":sqrt(energy),"peak":_peak(after),"voices":model.synth.voice_group_stats,
		"max_settle_ms":model.max_settle_ms,"max_render_ms":model.max_render_ms}
	var passed := birth_jump < 0.000001 and retune_jump < 0.000001 and dc.length() < 0.003 and sqrt(energy) > 0.005 and jump < 0.025 and _peak(after) < 0.9
	var dry_model := model.freeze()
	var dry_state := state.duplicate(true)
	var dry := dry_model.render_block(dry_state,model.rendered_until,512,22050)
	model.synth.ducking = true
	var ducked := model.render_block(state,model.rendered_until,512,22050)
	var duck_start_difference := (dry[0]-ducked[0]).length()
	result["preview_duck_start_difference"] = duck_start_difference
	passed = passed and duck_start_difference < 0.0005
	result["passed"] = passed
	FileAccess.open("res://验证记录/连续河谷/第63轮_声音边界.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("AUDIO_POP ",JSON.stringify(result))
	quit(0 if passed else 1)
func _peak(block: PackedVector2Array) -> float:
	var result := 0.0
	for sample in block: result = maxf(result,sample.length())
	return result
