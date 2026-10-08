class_name AudibleAudioClock
extends Node

const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Values = preload("res://scripts/spec_values.gd")

signal output_started
signal output_stopped

var renderer: SampleRenderer
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var capacity := 0
var output_latency := 0.0
var active := false
var underruns := 0

func _ready() -> void:
	renderer = Renderer.new()
	player = AudioStreamPlayer.new()
	add_child(player)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate_mode = AudioStreamGenerator.MIX_RATE_CUSTOM
	generator.mix_rate = renderer.transport.sample_rate
	generator.buffer_length = float(Values.load_values()["timing"]["buffer_seconds"])
	player.stream = generator
	output_latency = AudioServer.get_output_latency()
	set_process(false)

func start_output(source: Callable, initial_state: Dictionary) -> void:
	stop_output()
	renderer = Renderer.new()
	renderer.source = source
	renderer.state = initial_state.duplicate(true)
	player.play()
	playback = player.get_stream_playback()
	capacity = playback.get_frames_available()
	underruns = 0
	active = true
	_fill_buffer()
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
	if available > 0:
		var block := renderer.render(available)
		if not playback.push_buffer(block):
			push_error("Audio PCM buffer rejected; stop and restart to preserve the timeline")
			stop_output()

func stop_output() -> void:
	active = false
	set_process(false)
	if is_instance_valid(player):
		player.stop()
	playback = null
	output_stopped.emit()

func _exit_tree() -> void:
	stop_output()
	if is_instance_valid(player):
		player.stream = null
