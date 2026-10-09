class_name ContinuousAudioModel
extends RefCounted
const World = preload("res://scripts/world/continuous_world.gd")
const Synth = preload("res://scripts/audio/continuous_synth.gd")
const Config = preload("res://scripts/world/world_values.gd")
var world: ContinuousWorld
var synth: ContinuousSynth
var phrase_frames: int
var next_boundary: int
var presentation_history: Array[Dictionary] = []
var presentation_copy: ContinuousWorld
var presentation_copy_frame := -1
var event_cursor := 0
var bed_table := PackedFloat32Array()

func _init(city_world: ContinuousWorld, fixed_gain: float = 1.0) -> void:
	world = city_world
	synth = Synth.new(world.buildings)
	synth.assist_enabled = false
	synth.gain = fixed_gain
	phrase_frames = int(Config.load_values()["timing"]["phrase_frames"])
	next_boundary = (world.phrase_index+1)*phrase_frames
	var value := world.rng.seed_hex.substr(0,8).hex_to_int()
	var filtered := 0.0
	bed_table.resize(4096)
	for i in range(bed_table.size()):
		value = (1664525*value+1013904223)&0xffffffff
		filtered = lerpf(filtered,float(value)/4294967296.0*2.0-1.0,0.08)
		bed_table[i] = filtered

func submit(operation: Dictionary) -> Dictionary:
	return world.request(operation,next_boundary)

func _mix_frame(_state: Dictionary, _at: int, _rate: int) -> Vector2:
	return Vector2.ZERO

func render_block(state: Dictionary, start: int, count: int, rate: int) -> PackedVector2Array:
	var output := PackedVector2Array()
	var at := start
	while at < start+count:
		if at == next_boundary:
			presentation_history.append({"frame":at,"before":world.snapshot()})
			world.settle(at)
			var recent: Array = world.events.slice(event_cursor)
			event_cursor = world.events.size()
			synth.update_city(world.buildings,state,{},recent)
			synth.set_gray(bool(world.lifecycle["gray"]),at)
			next_boundary += phrase_frames
		var amount := mini(start+count-at,next_boundary-at)
		var block := synth.render_block(state,at,amount,rate)
		for i in range(block.size()):
			var frame := at+i
			var breath := 0.004*sin(TAU*130.81*float(frame)/rate) if world.buildings.is_empty() else 0.0
			var stream := float(bed_table[frame%bed_table.size()])*0.007
			block[i] += Vector2.ONE*(breath+stream)
		output.append_array(block)
		at += amount
	return output

func presentation_world(audible_frame: float) -> ContinuousWorld:
	while not presentation_history.is_empty() and int(presentation_history[0]["frame"]) <= audible_frame: presentation_history.pop_front()
	if presentation_history.is_empty():
		presentation_copy = null
		presentation_copy_frame = -1
		return world
	var entry: Dictionary = presentation_history[0]
	if presentation_copy == null or presentation_copy_frame != int(entry["frame"]):
		presentation_copy = World.new(world.rng.seed_hex)
		presentation_copy.restore(entry["before"])
		presentation_copy_frame = int(entry["frame"])
	presentation_copy.pending = world.pending.duplicate(true)
	return presentation_copy

func forecast(operation: Dictionary, state: Dictionary, at: int, duration: int) -> PackedVector2Array:
	var copy: ContinuousWorld = world.fork()
	copy.pending.clear()
	var preview_model: RefCounted = get_script().new(copy,synth.gain)
	preview_model.next_boundary = next_boundary
	preview_model.event_cursor = event_cursor
	preview_model.synth.restore_stages(synth.stage_snapshot())
	preview_model.synth.gray_enabled = synth.gray_enabled
	preview_model.synth.gray_from = synth.gray_from
	preview_model.synth.gray_change_at = synth.gray_change_at
	preview_model.synth.listener_community = synth.listener_community
	preview_model.synth.muted_communities = synth.muted_communities.duplicate(true)
	preview_model.synth.targets = synth.targets.duplicate(true)
	var result: Dictionary = preview_model.submit(operation)
	if not result["accepted"]: return PackedVector2Array()
	var phases := state.duplicate(true)
	var boundary: int = preview_model.next_boundary
	var rate := int(Config.load_values()["timing"]["sample_rate"])
	for begin in range(at,boundary,512):
		preview_model.render_block(phases,begin,mini(512,boundary-begin),rate)
	return preview_model.render_block(phases,boundary,duration,rate)
