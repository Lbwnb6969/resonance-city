class_name PreviewAudioOutput
extends AudibleAudioClock

signal audition_finished(skips: int)

var pcm := PackedVector2Array()
var sample_count := 0

func begin(samples: PackedVector2Array) -> void:
	pcm = samples
	sample_count = pcm.size()
	start_output(_sample,{})

func _sample(_state: Dictionary, at: int, _rate: int) -> Vector2:
	return pcm[at] if at < sample_count else Vector2.ZERO

func _process(delta: float) -> void:
	super._process(delta)
	if active and renderer.transport.audible_frame >= sample_count:
		var skips := underruns
		stop_output()
		audition_finished.emit(skips)
