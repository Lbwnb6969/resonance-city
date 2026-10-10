class_name Audio008GroupEdges
extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Fixtures = preload("res://tests/audio008_fixtures.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Before = preload("res://废弃/tests/第60轮前合成器.gd")
var test: RefCounted
var results: Array = []
func _initialize() -> void: call_deferred("_run")
func _compare(count: int,guard_stress: bool,frames: int) -> void:
	var city := Fixtures.staged_city(count)
	var old := Before.new(city)
	var current := Synth.new(city)
	current.voice_grouping = true
	for synth in [old,current]:
		synth.guard_enabled = true
		synth.sync_rings(Fixtures.source()["ring_states"],-44100)
		if guard_stress:
			synth.drone_gain *= 0.01
			synth.rhythm_gain *= 6.0
	var astate: Dictionary = old.initial_state()
	var bstate: Dictionary = current.initial_state()
	var error := 0.0
	var peak := 0.0
	for at in range(0,frames,512):
		var amount := mini(512,frames-at)
		var a: PackedVector2Array = old.render_block(astate,at,amount,22050)
		var b: PackedVector2Array = current.render_block(bstate,at,amount,22050)
		for i in range(amount):
			error = maxf(error,maxf(absf(a[i].x-b[i].x),absf(a[i].y-b[i].y)))
			peak = maxf(peak,maxf(absf(a[i].x),absf(a[i].y)))
	var exact_individual := true
	var guard_error := 0.0
	for key in astate:
		if str(key).begins_with("_guard_") and typeof(astate[key]) in [TYPE_INT,TYPE_FLOAT]:
			guard_error = maxf(guard_error,absf(float(astate[key])-float(bstate[key]))/maxf(1.0,absf(float(astate[key]))))
		elif astate[key] != bstate[key]: exact_individual = false
	var relative := error/maxf(peak,0.000000001)
	test.check(relative <= 0.00002 and exact_individual and guard_error <= 0.00002,"%d guard_stress=%s PCM/state tolerance" % [count,guard_stress])
	if guard_stress: test.check(float(bstate.get("_guard_factor",1.0)) > 1.0,"Grouped RMS guard actually activates; not only factor-one equivalence")
	results.append({"entities":count,"guard_stress":guard_stress,"frames":frames,"pcm_relative_error":relative,"guard_relative_error":guard_error,"individual_state_exact":exact_individual,"guard_factor":bstate.get("_guard_factor",1.0)})
func _run() -> void:
	test = Contract.new("AUDIO-008","group_edges_round60")
	_compare(128,false,2048)
	_compare(250,false,2048)
	_compare(64,true,22050)
	test.details = {"results":results,"scope":"128/250 initial event-tail PCM and active compensating guard; legal pressure grids; original-source comparison"}
	test.finish(self,"Expanded grouped PCM and actually triggered guard counterexample")
