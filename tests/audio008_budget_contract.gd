class_name Audio008BudgetContract
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Fixtures = preload("res://tests/audio008_fixtures.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Grouped = preload("res://scripts/audio/voice_group_budget.gd")
const DIR = "res://验证记录/Demo/AUDIO-008_第59轮/"
const RATE = 22050
# Reordered float32 additive sums are not byte-identical; declare a relative
# error bound independently of entity count and always record the actual error.
const RELATIVE_ERROR = 0.00002

func _initialize() -> void: call_deferred("_run")

func _measure(renderer: Object, start: int, frames: int) -> Dictionary:
	var state := Fixtures.actual_synth(renderer).initial_state()
	var times := PackedFloat64Array()
	var elapsed := 0
	var at := start
	while at < start+frames:
		var count := mini(512,start+frames-at)
		var begin := Time.get_ticks_usec()
		renderer.render_block(state,at,count,RATE)
		var usec := Time.get_ticks_usec()-begin
		elapsed += usec
		times.append(float(usec))
		at += count
	times.sort()
	return {"frames":frames,"audio_seconds":float(frames)/RATE,"render_cpu_ms":float(elapsed)/1000.0,
		"cpu_to_audio_ratio":float(elapsed)*RATE/(1000000.0*frames),"buffer_512_p95_ms":times[mini(times.size()-1,floori(times.size()*0.95))]/1000.0,"buffer_512_max_ms":times[-1]/1000.0}

func _compare(a: Object,b: Object,start: int,count: int,astate: Dictionary = {},bstate: Dictionary = {}) -> Dictionary:
	if astate.is_empty(): astate = Fixtures.actual_synth(a).initial_state()
	if bstate.is_empty(): bstate = Fixtures.actual_synth(b).initial_state()
	var x: PackedVector2Array = a.render_block(astate,start,count,RATE)
	var y: PackedVector2Array = b.render_block(bstate,start,count,RATE)
	var peak := 0.0
	var error := 0.0
	for i in range(count):
		peak = maxf(peak,maxf(absf(x[i].x),absf(x[i].y)))
		error = maxf(error,maxf(absf(x[i].x-y[i].x),absf(x[i].y-y[i].y)))
	return {"max_absolute_error":error,"relative_error":error/maxf(0.000000001,peak),"state_equal":astate == bstate,"bytes_equal":x.to_byte_array() == y.to_byte_array()}

func _coherent(count: int) -> float:
	var city := Fixtures.static_city(count)
	for district in city:
		district["type"] = "residential"
		# All are centred to remove stereo panning as a confound, unique logical cells.
		district["footprint"] = [[8,8]]
	var synth := Synth.new(city)
	synth.active_layers = ["drone"]
	var pcm := synth.render_block(synth.initial_state(),101,512,RATE)
	var peak := 0.0
	for sample in pcm: peak = maxf(peak,absf(sample.x))
	return peak

func _export_mix(count: int,same_pitch: bool) -> Dictionary:
	var renderer := Fixtures.configured(count,false,true,same_pitch)
	var synth := Fixtures.actual_synth(renderer)
	synth.capture_drone = true
	var state := synth.initial_state()
	var name := "staged_%d_%s" % [count,"coherent" if same_pitch else "palette"]
	var mix := FileAccess.open(DIR+name+".f32",FileAccess.WRITE)
	var drone := FileAccess.open(DIR+name+"__drone.f32",FileAccess.WRITE)
	for at in range(0,RATE*16,512):
		var pcm: PackedVector2Array = renderer.render_block(state,at,mini(512,RATE*16-at),RATE)
		mix.store_buffer(pcm.to_byte_array())
		drone.store_buffer(synth.captured_drone.to_byte_array())
	mix.close()
	drone.close()
	return {"name":name,"entities":count,"gain":synth.gain,"guard_factor":state.get("_guard_factor",1.0),"ring_routes":synth.ring_snapshot().size(),"stage_routes":synth.stage_snapshot().size(),"frames":RATE*16,"fixture":"original nine plus explicit mature/ring stress extension; no gain recalibration"}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var test := Contract.new("AUDIO-008","budget_round59")
	var benchmark: Array = []
	for count in [27,64,128,250]:
		for staged in [false,true]:
			var baseline := Fixtures.configured(count,false,staged)
			var candidate := Fixtures.configured(count,true,staged)
			var entry := {"entities":count,"fixture":"staged_ring_guard" if staged else "static_three_group_upper_bound",
				"unmerged":_measure(baseline,0,RATE/2),"candidate":_measure(candidate,0,RATE/2)}
			var comparison := _compare(Fixtures.configured(count,false,staged),Fixtures.configured(count,true,staged),0,2048)
			entry["comparison"] = comparison
			entry["fallbacks"] = candidate.fallback_count
			entry["fallback_reason"] = candidate.fallback_reason
			test.check(float(comparison["relative_error"]) <= RELATIVE_ERROR and comparison["state_equal"],"%d %s: PCM relative error <=2e-5 and state exactly retained" % [count,entry["fixture"]])
			if staged: test.check(comparison["bytes_equal"] and candidate.fallback_count > 0,"%d staged/ring/guard fixture is exact per-entity fallback" % count)
			benchmark.append(entry)
			print("AUDIO008_MEASURE entities=%d staged=%s" % [count,staged])
	var controls: Dictionary = {}
	for mode in ["mute","solo","mute_solo","all_mute","unmute_continuous","phase_split","pitch_split","filter_split"]:
		var city := Fixtures.static_city(32)
		var a := Synth.new(city)
		var b := Grouped.new(city)
		var astate := a.initial_state()
		var bstate := b.synth.initial_state()
		var id := str(city[7]["district_id"])
		if mode in ["mute","mute_solo","unmute_continuous"]:
			a.set_mute(id,true)
			b.set_mute(id,true)
		if mode in ["solo","mute_solo"]:
			a.set_solo(id)
			b.set_solo(id)
		if mode in ["all_mute","unmute_continuous"]:
			for district in city:
				a.set_mute(district["district_id"],true)
				b.set_mute(district["district_id"],true)
		if mode == "phase_split":
			astate["_phase_"+id] = 0.00000001
			bstate["_phase_"+id] = 0.00000001
		if mode == "pitch_split":
			astate[id] = 50
			bstate[id] = 50
		if mode == "filter_split":
			astate["_highpass_static_2"] = Vector2(0.125,0.01)
			bstate["_highpass_static_2"] = Vector2(0.125,0.01)
		var start := 0
		if mode == "unmute_continuous":
			a.render_block(astate,0,4096,RATE)
			b.render_block(bstate,0,4096,RATE)
			for district in city:
				a.set_mute(district["district_id"],false)
				b.set_mute(district["district_id"],false)
			start = 4096
		var comparison := _compare(a,b,start,4096,astate,bstate)
		controls[mode] = comparison
		test.check(float(comparison["relative_error"]) <= RELATIVE_ERROR and comparison["state_equal"],"Independent control/state: "+mode)
	var ring_compare := _compare(Fixtures.configured(27,false,true),Fixtures.configured(27,true,true),RATE*4,RATE*4)
	test.check(ring_compare["bytes_equal"] and ring_compare["state_equal"],"All eight ring beat slots, mature events and guard are exact under fallback")
	var one := _coherent(1)
	var coherent: Array = []
	for count in [4,16,64,128]:
		var ratio := _coherent(count)/one
		coherent.append({"entities":count,"amplitude_ratio":ratio,"sqrt_estimate":sqrt(float(count))})
		test.check(absf(ratio-count)/count < 0.00001,"Coherent counterexample grows as k, not sqrt(k): "+str(count))
	var mixes: Array = []
	for count in [27,64,128,250]:
		mixes.append(_export_mix(count,false))
		print("AUDIO008_PCM entities=%d complete=16s" % count)
	mixes.append(_export_mix(250,true))
	test.details = {"rate":RATE,"relative_pcm_error_limit":RELATIVE_ERROR,"benchmarks":benchmark,"controls":controls,"ring":ring_compare,"coherent":coherent,"mixes":mixes,
		"reference_sha256":FileAccess.get_sha256(Fixtures.SOURCE),"display":DisplayServer.get_name(),"driver":AudioServer.get_driver_name(),
		"production_merge":"not enabled; candidate is only a static identical-timbre/pitch upper bound; actual staged/ring/guard city falls back","growth_limit":27,
		"measurement_status":"offline measurement valid; realtime and peak/RMS verdicts are separate"}
	test.finish(self,"Fresh CPU baseline and isolated candidate; exact control/state barriers; coherent signal counterexample; original-nine fixed gain, 16s staged/ring/guard PCM at 27/64/128/250. No human or future-era-timbre claim.")
