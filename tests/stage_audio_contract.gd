extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const OldSynth = preload("res://tests/废弃/第56轮前合成器.gd")
const Stage = preload("res://scripts/audio/growth_voice.gd")
const Values = preload("res://scripts/spec_values.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const DIR = "res://验证记录/Demo/A13_U15_第56轮/"
var test := Contract.new("AUDIO-006","stage_round56")
func _initialize() -> void: call_deferred("run_check")
func energy(pcm: PackedVector2Array) -> float:
	var sum := 0.0
	for value in pcm: sum += value.length_squared()
	return sum
func save_pcm(name: String, pcm: PackedVector2Array) -> void:
	var file := FileAccess.open(DIR+name+".f32",FileAccess.WRITE)
	file.store_buffer(pcm.to_byte_array())
	file.close()
func run_check() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var values: Dictionary = Values.load_values()
	var generated := Generator.new().generate("0000000000000056",false)
	var city: Array = generated["city"]
	var calibration := Calibration.for_city(city)
	var gain := float(calibration["gain"])
	for rate in [22050,44100]:
		var fresh := Synth.new(city)
		var old := OldSynth.new(city)
		fresh.guard_enabled = true
		old.guard_enabled = true
		fresh.gain = gain
		old.gain = gain
		var state := fresh.initial_state()
		var prior := old.initial_state()
		var expected := old.render_block(prior,rate*4,roundi(rate*0.42),rate)
		var actual := fresh.render_block(state,rate*4,roundi(rate*0.42),rate)
		test.check(actual == expected and state == prior,"Original nine routes exact PCM/state against preserved source at %d Hz" % rate)
	var spectra: Dictionary = {}
	for form in ["胚","群","央","腔"]:
		var d: Dictionary = city[0].duplicate(true)
		d["district_id"] = "stage_fixture"
		d["type"] = "residential"
		d["current_midi"] = 48
		d["anchor_id"] = "source"
		d["voice_level"] = 0.2
		d["form"] = form
		var synth := Synth.new([d])
		synth.assist_enabled = false
		synth.gain = gain
		var state := synth.initial_state()
		var tracks := {"Drone":PackedVector2Array(),"Rhythm":PackedVector2Array(),"Ornament":PackedVector2Array()}
		for at in range(22050):
			var frame := synth.render_tracks(state,at,22050)
			for layer in tracks: tracks[layer].append(frame["District_stage_fixture_"+layer])
		for layer in tracks: save_pcm(form+"_"+layer,tracks[layer])
		spectra[form] = {"drone":energy(tracks["Drone"]),"rhythm":energy(tracks["Rhythm"]),"ornament":energy(tracks["Ornament"])}
		test.check(energy(tracks["Rhythm"]) == 0.0 if form == "胚" else energy(tracks["Rhythm"]) > 0.0,"%s actual rhythm layer" % form)
		test.check(energy(tracks["Ornament"]) == 0.0 if form in ["胚","群"] else energy(tracks["Ornament"]) > 0.0,"%s actual event layer" % form)
		if form == "胚":
			var drone_only := Synth.new([d])
			drone_only.active_layers.assign(["drone"])
			drone_only.gain = gain
			test.check(synth.render_block(synth.initial_state(),0,512,22050) == drone_only.render_block(drone_only.initial_state(),0,512,22050),"Embryo equals drone-only PCM")
		var block_state := synth.initial_state()
		var scalar_state := synth.initial_state()
		var actual := synth.render_block(block_state,0,777,22050)
		var scalar := PackedVector2Array()
		for at in range(777): scalar.append(synth._mix_frame(scalar_state,at,22050))
		test.check(actual == scalar and block_state == scalar_state,"%s scalar/block PCM and state agree" % form)
		synth.set_mute("stage_fixture",true)
		test.check(energy(synth.render_block(synth.initial_state(),0,512,22050)) == 0.0,"%s mute covers all layers" % form)
		synth.set_mute("stage_fixture",false)
		synth.silent_until["stage_fixture"] = 512
		test.check(energy(synth.render_block(synth.initial_state(),0,512,22050)) == 0.0,"%s relocation silence covers all layers" % form)
	var d: Dictionary = city[0].duplicate(true)
	d["district_id"] = "reveal"
	d["anchor_id"] = "source"
	d["form"] = "胚"
	d["voice_level"] = 0.2
	var synth := Synth.new([d])
	var state := synth.initial_state()
	d["form"] = "群"
	var reveal := 22050*16+11025
	synth.update_city([d],state,{},[{"district_id":"reveal","kind":"upgrade","frame":reveal,"form":"群"}])
	var stage: Dictionary = synth.routing[0]["stage"]
	test.check(Stage.rhythm_level(stage,reveal-1,22050,values) == 0.0 and Stage.rhythm_level(stage,reveal,22050,values) == 0.0,"Prefill upgrade remains silent through reveal onset")
	test.check(is_equal_approx(Stage.rhythm_level(stage,reveal+11025,22050,values),sqrt(0.5)) and Stage.rhythm_level(stage,reveal+22050,22050,values) == 1.0,"Two-beat equal-power fade")
	var model := Model.new(Session.new([d],generated["seed"]))
	model.synth.restore_stages(synth.stage_snapshot())
	model.next_boundary = 22050*32
	var saved := model.snapshot()
	var restored := model.fork()
	test.check(model.render_block(state.duplicate(true),reveal+5512,321,22050) == restored.render_block(state.duplicate(true),reveal+5512,321,22050) and restored.snapshot() == saved,"Snapshot/fork restores in-flight reveal and fade without phase reset")
	for rate in [22050,44100]:
		var a: Dictionary = Stage.initial(d)
		a["form"] = "腔"
		a["previous"] = "群"
		a["change_frame"] = rate*16+roundi(rate*0.5)
		test.check(Stage.event_info(a,48,rate*16,rate,values,true).is_empty() and Stage.event_info(a,48,rate*32,rate,values,true)["midi"] == 72,"Bell waits for next true phrase and uses current+24 at %d" % rate)
		test.check(Stage.event_info(a,48,rate*16,rate,values,false).is_empty() and not Stage.event_info(a,48,rate*20,rate,values,false).is_empty(),"Mature ornament skips pre-reveal cycle at %d" % rate)
		var pcm := Stage.block(a,48,rate*32-17,117,rate,values)
		var equal := true
		for index in range(117): equal = equal and pcm[index] == Stage.sample(a,48,rate*32-17+index,rate,values)
		test.check(equal,"Absolute event oscillator block/scalar identity across phrase at %d" % rate)
	d["is_anchor"] = true
	var anchor := Synth.new([d])
	var anchor_only := Synth.new([d])
	anchor_only.active_layers.assign(["drone"])
	test.check(anchor.render_block(anchor.initial_state(),0,777,22050) == anchor_only.render_block(anchor_only.initial_state(),0,777,22050),"Source anchor stays drone-only")
	# Full budget from the actual release and growth transaction; then measure all-mature stress too.
	var natural := Model.new(Session.new(city,generated["seed"],generated["rng"]))
	natural.session.growth_enabled = true
	var empty := natural.session._empty_cells()
	empty.sort_custom(func(a: Array,b: Array) -> bool: return Vector2(a[0]-8,a[1]-8).length_squared() < Vector2(b[0]-8,b[1]-8).length_squared())
	for cell in empty:
		var safe := true
		for initial in city:
			if initial["type"] == "industrial": safe = safe and absi(cell[0]-initial["footprint"][0][0])+absi(cell[1]-initial["footprint"][0][1]) > 5
		if safe:
			natural.session.request_release(48,Vector2i(cell[0],cell[1]),0,0)
			break
	var ns := natural.synth.initial_state()
	for phrase in range(36):
		var at := natural.next_boundary
		natural.render_block(ns,at,17,22050)
		natural.presentation_session(at+11042)
		if natural.session.city.size() == 27: break
	test.check(natural.session.city.size() == 27 and not natural.growth_history.is_empty(),"Actual release/growth reaches 27 and records real upgrade facts")
	var count_stages: Dictionary = {}
	for entity in natural.session.city:
		var form: String = entity.get("form","胚")
		count_stages[form] = int(count_stages.get(form,0))+1
	for label in ["natural27","mature27"]:
		var grown: Array = natural.session.city.duplicate(true)
		if label == "mature27":
			for entity in grown:
				if Stage.applies(entity): entity["form"] = "腔"
		var mixed := Synth.new(grown)
		mixed.guard_enabled = true
		mixed.capture_drone = true
		mixed.gain = gain
		var ms := mixed.initial_state()
		var output := PackedVector2Array()
		var drone := PackedVector2Array()
		for at in range(0,22050*16,441):
			output.append_array(mixed.render_block(ms,at,441,22050))
			drone.append_array(mixed.captured_drone)
		save_pcm(label,output)
		save_pcm(label+"__drone",drone)
		print("STAGE_MIX ",label," samples=",output.size())
	test.details = {"rate":22050,"gain":gain,"initial_calibration":calibration,"stage_energy":spectra,"natural_stages":count_stages,"growth_history":natural.growth_history,"directory":DIR,"stress_scope":"mature27 forces grown voices to chamber for conservative event density; not a natural city or human listening"}
	test.finish(self,"Legacy exact PCM, stage layers and reveal schedule, deterministic event tails, controls, fork and natural+all-mature fixed-gain 27 PCM; external true-peak/window-RMS measurement follows")
