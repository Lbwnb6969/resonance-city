class_name ListeningFixtures
extends RefCounted

const Values = preload("res://scripts/spec_values.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")

static func protocol() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://数据/listening_fixtures.json"))
	assert(data["audio_spec_sha256"] == Values.load_values()["sources"]["spec.audio.md"],"Listening fixtures need regeneration")
	return data

static func city(trial: Dictionary) -> Array:
	var result: Array = []
	for voice in trial["voices"]:
		var district := Schema.create(voice["id"],voice["type"],Vector2i(int(voice["cell"][0]),int(voice["cell"][1])))
		district["current_midi"] = int(voice["midi"])
		result.append(district)
	return result

static func render(trial: Dictionary, device_mode: String) -> Dictionary:
	var values := Values.load_values()
	var layout := city(trial)
	var calibration := Calibration.for_city(layout)
	var synth := Synth.new(layout)
	synth.gain = float(calibration["gain"])
	synth.guard_enabled = true
	synth.assist_enabled = device_mode == "speaker_narrowband"
	synth.device_mode = "narrowband" if synth.assist_enabled else "standard"
	var rate := int(values["timing"]["sample_rate"])
	var count := roundi(float(values["listening"]["duration_seconds"])*rate)
	var pcm := synth.render_block(synth.initial_state(),0,count,rate)
	var fade := roundi(float(values["listening"]["fade_beats"])*60.0/float(values["timing"]["bpm"])*rate)
	for at in range(pcm.size()):
		var envelope := sin(PI*0.5*minf(1.0,float(mini(at,pcm.size()-1-at))/fade))
		pcm[at] *= envelope
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(pcm.to_byte_array())
	return {"pcm":pcm,"pcm_sha256":hash.finish().hex_encode(),"gain":synth.gain,"sample_rate":rate,
		"assist_state":synth.assist_enabled,"device_mode":synth.device_mode,"calibration":calibration}
