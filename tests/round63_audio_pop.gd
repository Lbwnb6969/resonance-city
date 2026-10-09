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
	model.submit({"kind":"seed","position":lot["center"],"midi":48})
	var state: Dictionary = {}
	var boundary: int = model.next_boundary
	var before := model.render_block(state,boundary-2048,2048,22050)
	var after := model.render_block(state,boundary,2048,22050)
	var jump := 0.0
	for i in range(1,after.size()): jump = maxf(jump,(after[i]-after[i-1]).length())
	jump = maxf(jump,(after[0]-before[-1]).length())
	var id: String = world.buildings[0]["district_id"]
	var request: Dictionary = model.submit({"kind":"retune","id":id,"midi":55})
	var event_frame: int = int(request["sound_frame"])
	var to_event := model.render_block(state,model.rendered_until,event_frame-model.rendered_until,22050)
	var retune := model.render_block(state,event_frame,2048,22050)
	var retune_jump := (retune[0]-to_event[-1]).length()
	var result := {"boundary":boundary,"before":before[-1],"after":after[0],"jump":jump,"retune_jump":retune_jump,"peak_before":_peak(before),"peak_after":_peak(after)}
	print("AUDIO_POP ",JSON.stringify(result))
	quit(0 if jump < 0.002 and retune_jump < 0.002 else 1)
func _peak(block: PackedVector2Array) -> float:
	var result := 0.0
	for sample in block: result = maxf(result,sample.length())
	return result
