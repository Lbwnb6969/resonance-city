class_name LoudnessCalibration
extends RefCounted
## Initial BS.1770 stereo calibration. Mathematical filter/gating references: spec.audio A9.

const Values = preload("res://scripts/spec_values.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")

static func integrated(pcm: PackedVector2Array, rate: int) -> Dictionary:
	var settings: Dictionary = Values.load_values()["loudness"]
	var shelf: Array = settings["shelf"]
	var hp: Array = settings["highpass"]
	var prefix := PackedFloat64Array()
	prefix.resize(pcm.size()+1)
	for channel in range(2):
		var s1 := 0.0
		var s2 := 0.0
		var h1 := 0.0
		var h2 := 0.0
		var accumulated := 0.0
		for at in range(pcm.size()):
			var x := float(pcm[at].x if channel == 0 else pcm[at].y)
			var y := float(shelf[0])*x+s1
			s1 = float(shelf[1])*x-float(shelf[3])*y+s2
			s2 = float(shelf[2])*x-float(shelf[4])*y
			var z := float(hp[0])*y+h1
			h1 = float(hp[1])*y-float(hp[3])*z+h2
			h2 = float(hp[2])*y-float(hp[4])*z
			accumulated += z*z
			prefix[at+1] += accumulated
	var block := roundi(float(settings["block_seconds"])*rate)
	var step := roundi(block*(1.0-float(settings["overlap"])))
	var energies := PackedFloat64Array()
	var absolute_sum := 0.0
	var absolute_count := 0
	var offset := float(settings["offset"])
	var absolute_gate := float(settings["absolute_gate_lufs"])
	for start in range(0,pcm.size()-block+1,step):
		var energy := (prefix[start+block]-prefix[start])/block
		energies.append(energy)
		if energy > 0.0 and offset+10.0*log(energy)/log(10.0) >= absolute_gate:
			absolute_sum += energy
			absolute_count += 1
	if absolute_count == 0:
		return {"lufs":-INF,"blocks":energies.size(),"gated_blocks":0}
	var relative := offset+10.0*log(absolute_sum/absolute_count)/log(10.0)+float(settings["relative_gate_lu"])
	var final_sum := 0.0
	var final_count := 0
	for energy in energies:
		var loudness := offset+10.0*log(energy)/log(10.0) if energy > 0.0 else -INF
		if loudness > relative and loudness > absolute_gate:
			final_sum += energy
			final_count += 1
	return {"lufs":offset+10.0*log(final_sum/final_count)/log(10.0) if final_count > 0 else -INF,
		"blocks":energies.size(),"gated_blocks":final_count,"relative_gate":relative}

static func for_city(city: Array) -> Dictionary:
	var values := Values.load_values()
	var rate := int(values["timing"]["sample_rate"])
	var seconds := float(values["loudness"]["duration_seconds"])
	var source := Synth.new(city)
	source.assist_enabled = false
	var started := Time.get_ticks_usec()
	var pcm := source.render_block(source.initial_state(),0,roundi(seconds*rate),rate)
	var measured := integrated(pcm,rate)
	var target := float(values["mixing"]["target_lufs"])
	return {"initial_lufs":measured["lufs"],"target_lufs":target,
		"gain":pow(10.0,(target-float(measured["lufs"]))/20.0),
		"duration_seconds":seconds,"sample_rate":rate,"blocks":measured["blocks"],
		"calibration_ms":float(Time.get_ticks_usec()-started)/1000.0}
