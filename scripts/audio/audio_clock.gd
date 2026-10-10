class_name AudibleAudioClock
extends Node

const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Values = preload("res://scripts/spec_values.gd")
# Keep the existing live queue; after a slow settlement, refill the frames
# consumed during rendering before yielding to city presentation.
const LIVE_BUFFER_FLOOR_SECONDS := 0.24

signal output_started
signal output_stopped

var renderer: SampleRenderer
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var capacity := 0
var output_latency := 0.0
var active := false
var underruns := 0
var resume_fade_left := 0
var resume_fade_total := 1

func _ready() -> void:
	renderer = Renderer.new()
	player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = _new_generator()
	output_latency = AudioServer.get_output_latency()
	set_process(false)

func _new_generator() -> AudioStreamGenerator:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate_mode = AudioStreamGenerator.MIX_RATE_CUSTOM
	generator.mix_rate = renderer.transport.sample_rate
	generator.buffer_length = maxf(float(Values.load_values()["timing"]["buffer_seconds"]),LIVE_BUFFER_FLOOR_SECONDS)
	return generator

func start_output(source: Callable, initial_state: Dictionary, saved_renderer: Dictionary = {}) -> void:
	stop_output()
	renderer = Renderer.new()
	if player.stream == null: player.stream = _new_generator()
	renderer.source = source
	renderer.state = initial_state.duplicate(true)
	resume_fade_left = 0
	if not saved_renderer.is_empty():
		renderer.restore(saved_renderer)
		# The saved cursor is the next unrendered sample; no new mixer has the old queued PCM.
		renderer.transport.audible_frame = float(renderer.transport.rendered_frames)
		resume_fade_total = roundi(renderer.transport.sample_rate*0.08)
		resume_fade_left = resume_fade_total
	# Prime while the mixer is locked, so it never consumes an empty new stream.
	AudioServer.lock()
	player.play()
	player.stream_paused = true
	playback = player.get_stream_playback()
	capacity = playback.get_frames_available()
	underruns = 0
	active = true
	_fill_buffer()
	player.stream_paused = false
	AudioServer.unlock()
	set_process(true)
	output_started.emit()

func _process(_delta: float) -> void:
	if active:
		_update_audible()
		_fill_buffer()

func _update_audible() -> void:
	if playback == null:
		return
	var queued := capacity - playback.get_frames_available()
	renderer.transport.update_audible(queued, AudioServer.get_time_since_last_mix(), output_latency)
	underruns = playback.get_skips()

func _fill_buffer() -> void:
	var available := playback.get_frames_available()
	while available > 0:
		var block := renderer.render(available)
		for i in range(mini(block.size(),resume_fade_left)):
			block[i] *= smoothstep(0.0,1.0,1.0-float(resume_fade_left)/resume_fade_total)
			resume_fade_left -= 1
		if not playback.push_buffer(block):
			push_error("Audio PCM buffer rejected; stop and restart to preserve the timeline")
			stop_output()
			return
		available = playback.get_frames_available()

func stop_output() -> void:
	active = false
	set_process(false)
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	playback = null
	output_stopped.emit()

func _exit_tree() -> void:
	stop_output()
	if is_instance_valid(player):
		player.stream = null
