class_name Audio008Supply
extends SceneTree

const Fixtures = preload("res://tests/audio008_fixtures.gd")
const DIR = "res://验证记录/Demo/AUDIO-008_第59轮/"
const RATE = 22050

func _initialize() -> void: call_deferred("_run")

func _supply(count: int,grouped: bool,staged: bool,seconds: int) -> Dictionary:
	var renderer := Fixtures.configured(count,grouped,staged)
	var synth := Fixtures.actual_synth(renderer)
	var clock: Node = root.get_node("AudioClock")
	# Stress monitor only: never claim this attenuation fixes the fixed-gain PCM.
	# Raw float PCM is independently metered; the speaker is attenuated by 30 dB.
	clock.player.volume_db = -30.0
	var duration := RATE*seconds
	var fills: Array = []
	# AudioClock starts and primes under the actual production mixer lock.
	clock.start_output(renderer._mix_frame,synth.initial_state())
	var start := Time.get_ticks_msec()
	var deadline := start+seconds*1000+3000
	var skips := 0
	while clock.active and clock.renderer.transport.audible_frame < duration and Time.get_ticks_msec() < deadline:
		await process_frame
		clock._update_audible()
		skips = maxi(skips,clock.underruns)
	var result := {"entities":count,"candidate":grouped,"staged":staged,"required_audible_frames":duration,
		"audible_frames":clock.renderer.transport.audible_frame,"rendered_frames":clock.renderer.transport.rendered_frames,
		"skips":skips,"wall_ms":Time.get_ticks_msec()-start,"capacity":clock.capacity,"driver":AudioServer.get_driver_name(),
		"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"gain":synth.gain,"monitor_attenuation_db":-30,
		"fallbacks":renderer.fallback_count if grouped else 0}
	result["supply_pass"] = result["driver"] == "WASAPI" and result["audible_frames"] >= duration and skips == 0
	clock.stop_output()
	clock.renderer.source = Callable()
	await process_frame
	await process_frame
	return result

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var results: Array = []
	# Revalidate current production workload, challenge expansion, then measure
	# the deliberately favourable static grouping bound for a full audible phrase.
	results.append(await _supply(27,false,true,16))
	print("AUDIO008_SUPPLY "+JSON.stringify(results[-1]))
	results.append(await _supply(64,false,true,2))
	print("AUDIO008_SUPPLY "+JSON.stringify(results[-1]))
	results.append(await _supply(250,true,false,16))
	print("AUDIO008_SUPPLY "+JSON.stringify(results[-1]))
	var valid := AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless"
	var report := {"status":"MEASURED" if valid else "INVALID_DRIVER","measurements":results,
		"scope":"isolated audio in actual GPU/WASAPI window; AudioClock production priming/refill/audible estimator; not the full main-scene graphics workload or human listening; expansion failures retained"}
	var file := FileAccess.open(DIR+"实际供音.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"	")+"\n")
	file.close()
	print("AUDIO008_SUPPLY_MEASURED driver=%s" % AudioServer.get_driver_name())
	quit(0 if valid else 1)
