class_name Audio008ProductionContract
extends SceneTree

const Contract = preload("res://tests/contract_support.gd")
const Fixtures = preload("res://tests/audio008_fixtures.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Before = preload("res://废弃/tests/第60轮前合成器.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const DIR = "res://验证记录/Demo/AUDIO-008_第60轮/"
var test: RefCounted
var comparisons: Array = []
var benchmarks: Array = []

func _initialize() -> void: call_deferred("_run")

func _pair(count: int,staged: bool) -> Array:
	var city := Fixtures.staged_city(count) if staged else Fixtures.static_city(count)
	var old := Before.new(city)
	var current := Synth.new(city)
	current.voice_grouping = true
	for synth in [old,current]:
		if staged:
			synth.guard_enabled = true
			synth.gain = float(Fixtures.source()["calibration"]["gain"])
			synth.sync_rings(Fixtures.source()["ring_states"],-44100)
	return [old,current]

func _compare(label: String,pair: Array,rate: int,start: int,length: int,block_size: int = 512,states: Array = []) -> void:
	if states.is_empty(): states = [pair[0].initial_state(),pair[1].initial_state()]
	var equal := true
	var max_error := 0.0
	var peak := 0.0
	var hits := 0
	for at in range(start,start+length,block_size):
		var count := mini(block_size,start+length-at)
		var a: PackedVector2Array = pair[0].render_block(states[0],at,count,rate)
		var b: PackedVector2Array = pair[1].render_block(states[1],at,count,rate)
		if a.to_byte_array() != b.to_byte_array(): equal = false
		for i in range(count):
			max_error = maxf(max_error,maxf(absf(a[i].x-b[i].x),absf(a[i].y-b[i].y)))
			peak = maxf(peak,maxf(absf(a[i].x),absf(a[i].y)))
		hits += int(pair[1].voice_group_stats.get("shared",0))
	var state_equal := _state_equivalent(states[0],states[1])
	var relative_error := max_error/maxf(peak,0.000000001)
	comparisons.append({"label":label,"rate":rate,"frames":length,"bytes_equal":equal,"max_error":max_error,"relative_error":relative_error,"state_equal":state_equal,"shared_dsp_groups":hits})
	test.check(relative_error <= 0.00002 and state_equal,label+": original-source PCM relative error <=2e-5; per-entity state exact, guard meter tolerance <=2e-5")

func _state_equivalent(a: Dictionary,b: Dictionary) -> bool:
	if a.size() != b.size(): return false
	for key in a:
		if not b.has(key): return false
		if str(key).begins_with("_guard_") and typeof(a[key]) in [TYPE_INT,TYPE_FLOAT]:
			if absf(float(a[key])-float(b[key])) > 0.00002*maxf(1.0,absf(float(a[key]))): return false
		elif a[key] != b[key]: return false
	return true

func _measure(synth: Object,rate: int) -> Dictionary:
	var state: Dictionary = synth.initial_state()
	var elapsed := 0
	var times: Array = []
	for at in range(0,rate,512):
		var count := mini(512,rate-at)
		var begin := Time.get_ticks_usec()
		synth.render_block(state,at,count,rate)
		var usec := Time.get_ticks_usec()-begin
		elapsed += usec
		times.append(float(usec)/1000.0)
	times.sort()
	return {"audio_seconds":1,"cpu_ms":float(elapsed)/1000.0,"cpu_ratio":float(elapsed)/1000000.0,"p95_512_ms":times[mini(times.size()-1,floori(times.size()*0.95))],"max_ms":times[-1]}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	test = Contract.new("AUDIO-008","production_round60")
	for count in [27,64,128,250]:
		var occupied: Dictionary = {}
		for district in Fixtures.staged_city(count): occupied[Fixtures.Schema.cell(district)] = true
		test.check(occupied.size() == count,"%d pressure entities occupy distinct grid cells" % count)
	for rate in [22050,44100]:
		for staged in [false,true]:
			_compare("27 staged=%s" % staged,_pair(27,staged),rate,0,rate/2)
	var ring := _pair(27,true)
	_compare("all eight ring beats and mature event tail",ring,22050,0,352800,257)
	_compare("64 mature events across next ornament cycle",_pair(64,true),22050,85000,20000,997)
	for control in ["mute","solo","mute_solo","all_mute","phase","pitch","filter","gray","narrowband","duck","migration"]:
		var pair := _pair(64,true)
		var states: Array = [pair[0].initial_state(),pair[1].initial_state()]
		var id := str(pair[0].routing[-1]["id"])
		for index in range(2):
			var synth: Object = pair[index]
			if control in ["mute","mute_solo"]: synth.set_mute(id,true)
			if control in ["solo","mute_solo"]: synth.set_solo(id)
			if control == "all_mute":
				for route in synth.routing: synth.set_mute(route["id"],true)
			if control == "phase": states[index]["_phase_"+id] = 0.123456789012345
			if control == "pitch": states[index][id] = 49
			if control == "filter": states[index][synth.routing[2]["highpass_key"]] = Vector2(0.1,0.2)
			if control == "gray": synth.set_gray(true,100)
			if control == "narrowband":
				synth.device_mode = "narrowband"
				states[index][str(synth.routing[0]["id"])] = 49
			if control == "duck":
				synth.begin_duck()
				synth.release_duck(100)
			if control == "migration": synth.silent_until[id] = 1000
		_compare("64 "+control,pair,22050,0,1536,512,states)
		if control == "mute":
			for synth in pair: synth.set_mute(id,false)
			_compare("unmute resumes continuous phase",pair,22050,1536,1536,257,states)
	var transition := _pair(27,true)
	for synth in transition:
		for route in synth.routing:
			if not route["stage"].is_empty():
				route["stage"] = {"form":"腔","previous":"胚","change_frame":500,"rhythm_start":500,"pattern":2}
	_compare("reveal/fade and ring crossfade",transition,22050,0,23000,997)
	var split := _pair(64,true)
	var astate: Dictionary = split[0].initial_state()
	var bstate: Dictionary = split[1].initial_state()
	var x: PackedVector2Array = split[0].render_block(astate,0,2500,22050)
	var pieces := PackedVector2Array()
	for at in range(0,2500,257): pieces.append_array(split[1].render_block(bstate,at,mini(257,2500-at),22050))
	var split_peak := 0.0
	var split_error := 0.0
	for index in range(x.size()):
		split_peak = maxf(split_peak,maxf(absf(x[index].x),absf(x[index].y)))
		split_error = maxf(split_error,maxf(absf(x[index].x-pieces[index].x),absf(x[index].y-pieces[index].y)))
	var split_relative := split_error/maxf(split_peak,0.000000001)
	test.check(split_relative <= 0.00002 and _state_equivalent(astate,bstate),"Different block boundaries preserve PCM <=2e-5 relative and individual phase/filter state")
	comparisons.append({"label":"split_blocks","relative_error":split_relative,"state_equal":_state_equivalent(astate,bstate)})
	for count in [27,64,128,250]:
		var pair := _pair(count,true)
		var old := _measure(pair[0],22050)
		var current := _measure(pair[1],22050)
		benchmarks.append({"entities":count,"before":old,"grouped":current,"groups":pair[1].voice_group_stats.duplicate()})
		print("AUDIO008_PRODUCTION_BENCH "+JSON.stringify(benchmarks[-1]))
	var model := Model.new(Session.new(Fixtures.staged_city(27),"2026100900000001"))
	model.synth.voice_grouping = true
	var restored := model.fork()
	test.check(restored.synth.voice_grouping,"Model snapshot/fork retains grouping opt-in")
	test.check(not Synth.new(Fixtures.static_city(9)).voice_grouping,"Direct/P0 synth defaults to original path")
	test.details = {"comparisons":comparisons,"benchmarks":benchmarks,"baseline":"废弃/tests/第60轮前合成器.gd from 5ed9d2f; actual previous-source PCM","scope":"Production grouped DSP: PCM <=2e-5 relative, exact individual phase/filter; guard accumulation <=2e-5 relative. No era timbre or human proof"}
	test.finish(self,"Production DSP sharing, original-source PCM/state, control splits, event transitions, block boundaries and budget")
