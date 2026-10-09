extends SceneTree
const Contract = preload("res://tests/contract_support.gd")
const Fixture = preload("res://tests/ring_fixture.gd")
const Ring = preload("res://scripts/city/city_ring.gd")
const Values = preload("res://scripts/spec_values.gd")
const Roads = preload("res://scripts/city/city_roads.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const OldSynth = preload("res://tests/废弃/第57轮前合成器.gd")
const Preview = preload("res://scripts/proposals/proposal_preview.gd")
const Presentation = preload("res://scripts/ui/proposal_presentation.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Calibration = preload("res://scripts/audio/loudness_calibration.gd")
const DIR = "res://验证记录/Demo/CITY-005_第57轮/"
var test := Contract.new("CITY-005","ring_round57")
func _initialize() -> void: call_deferred("run_check")
func energy(pcm: PackedVector2Array) -> float:
	var result := 0.0
	for sample in pcm: result += sample.length_squared()
	return result
func save_pcm(name: String,pcm: PackedVector2Array) -> void:
	var file := FileAccess.open(DIR+name+".f32",FileAccess.WRITE)
	file.store_buffer(pcm.to_byte_array())
	file.close()
func run_check() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var values: Dictionary = Values.load_values()
	var unison := Fixture.city(false)
	var mixed := Fixture.city()
	var one := Ring.inspect(unison,{},unison[0],values)
	test.check(one["status"] == "unison" and not one["eligible"],"Same-note mature ring is only a prototype, never named")
	var valid := Ring.inspect(mixed,{},mixed[0],values)
	test.check(valid["eligible"] and valid["edges"].size() == 12 and valid["notes"] == [48,52,48,55,48,57,48,48],"Mixed mature stages pass all 12 edges in exact clockwise note order")
	for kind in ["missing","family","industrial","immature","dissonant","moved","frozen"]:
		var bad: Array = mixed.duplicate(true)
		if kind == "missing": bad.remove_at(2)
		elif kind == "family": bad[2]["anchor_id"] = "other"
		elif kind == "industrial": bad[2]["type"] = "industrial"
		elif kind == "immature": bad[2]["form"] = "胚"
		elif kind == "dissonant": bad[1]["current_midi"] = 50
		elif kind == "moved": bad[2]["footprint"] = [[1,1]]
		else:
			var d: Dictionary = mixed[1].duplicate(true)
			d["district_id"] = "external_industry"
			d["type"] = "industrial"
			d["current_midi"] = 54
			d["footprint"] = [[6,7]]
			bad.append(d)
		test.check(not Ring.inspect(bad,{},bad[0],values)["eligible"],"Rejects "+kind)
	var cells: Array = []
	for offset in values["ring"]["offsets"]: cells.append(Vector2i(8+offset[0],8+offset[1]))
	for index in range(8):
		var pairs := [[cells[index],cells[(index+1)%8]]]
		if index%2 == 1: pairs.append([Vector2i(8,8),cells[index]])
		for pair in pairs:
			var road: Dictionary = {Roads.key(pair[0],pair[1]):{"start":[pair[0].x,pair[0].y],"end":[pair[1].x,pair[1].y],"count":2,"frame":0}}
			test.check(Ring.inspect(mixed,road,mixed[0],values)["eligible"],"Unformed tread does not cut ring "+Roads.key(pair[0],pair[1]))
			road.values()[0]["count"] = 3
			test.check(not Ring.inspect(mixed,road,mixed[0],values)["eligible"],"Each of 12 permanent edges breaks ring "+Roads.key(pair[0],pair[1]))
	var model := Model.new(Session.new(mixed,"0000000000000057"))
	model.session.growth_enabled = true
	model.session.draft_pause_until = 22050*1000 # fixture prevents extra expansion; does not bypass ring settlement.
	var state := model.synth.initial_state()
	var before := model.session.snapshot()
	var preview_session := model.session.fork()
	preview_session.settle(preview_session.transport.phrase_frame(1))
	test.check(model.session.snapshot() == before and Presentation.summary(preview_session.last_result).contains("将形成环形合唱城"),"Forecast uses same recognizer without changing live city/RNG")
	model.render_block(state,model.next_boundary,17,22050)
	test.check(model.session.rings["ring_source"]["count"] == 1 and model.synth.ring_snapshot().is_empty(),"First real boundary counts once but does not enable voices")
	var first_snapshot := model.snapshot()
	var next := model.next_boundary
	model.render_block(state,next,17,22050)
	test.check(model.session.rings["ring_source"]["status"] == "formed" and model.synth.ring_snapshot().size() == 8,"Second actual boundary forms ring and schedules exactly eight voices")
	test.check(model.presentation_session(next-1).rings["ring_source"]["status"] == "candidate" and model.presentation_session(next).rings["ring_source"]["status"] == "formed","Prefill identity remains old until exact audible boundary")
	var restored := Model.new(model.session.fork())
	restored.restore(first_snapshot)
	test.check(restored.session.rings["ring_source"]["count"] == 1,"Snapshot restores actual consecutive count")
	var fork := model.fork()
	var a := model.render_block(state.duplicate(true),next+11025,777,22050)
	var b := fork.render_block(state.duplicate(true),next+11025,777,22050)
	test.check(a == b and model.snapshot() == fork.snapshot(),"Mid-crossfade snapshot/fork preserves phase and starting blend")
	var rings := Fixture.formed(mixed)
	for rate in [22050,44100]:
		var synth := Synth.new(mixed)
		var old := OldSynth.new(mixed)
		var s := synth.initial_state()
		var original := old.initial_state()
		test.check(synth.render_block(s,rate*2,1024,rate) == old.render_block(original,rate*2,1024,rate) and s == original,"Non-ring audio equals preserved round56 source at %d Hz" % rate)
		synth.sync_rings(rings,0)
		var route: Dictionary = synth.ring_snapshot()["ring_0"]
		test.check(synth.ring_level(route,0,rate) == 0.0 and is_equal_approx(synth.ring_level(route,rate,rate),0.5) and synth.ring_level(route,rate*2,rate) == 1.0,"One-bar crossfade at %d Hz" % rate)
		var actual := synth.render_block(s.duplicate(true),rate,701,rate)
		var scalar := PackedVector2Array()
		var scalar_state := s.duplicate(true)
		for at in range(rate,rate+701): scalar.append(synth._mix_frame(scalar_state,at,rate))
		test.check(actual == scalar,"Crossfade scalar/block PCM identity at %d Hz" % rate)
		for index in range(8):
			var envelope: PackedFloat32Array = synth.envelopes[rate]["_ring"][index]
			var onset := roundi(index*rate*0.5)
			var correct := true
			for at in range(envelope.size()):
				if at <= onset or at >= onset+ceili(rate*0.25): correct = correct and envelope[at] == 0.0
				elif at == onset+roundi(rate*0.01): correct = correct and envelope[at] > 0.0
			test.check(correct,"Member %d only starts on beat %d in each eight-beat loop (%d Hz)" % [index,index,rate])
		var ring_state := synth.initial_state()
		var plain_state := old.initial_state()
		var identical_drone := true
		var correct_pitch := true
		for at in range(rate*4,rate*4+400):
			var tracks := synth.render_tracks(ring_state,at,rate)
			var old_tracks := old.render_tracks(plain_state,at,rate)
			for index in range(8):
				var id := "ring_"+str(index)
				identical_drone = identical_drone and tracks["District_"+id+"_Drone"] == old_tracks["District_"+id+"_Drone"] and tracks["District_"+id+"_Ornament"] == old_tracks["District_"+id+"_Ornament"]
				correct_pitch = correct_pitch and ring_state["ring_"+str(index)] == mixed[index+1]["current_midi"]
		test.check(identical_drone and correct_pitch,"Drone/ornament PCM unchanged; member MIDI source preserved at %d Hz" % rate)
		synth.set_solo("ring_1")
		var solo := synth.render_block(synth.initial_state(),rate*4,777,rate)
		synth.set_mute("ring_1",true)
		test.check(energy(solo) > 0.0 and energy(synth.render_block(synth.initial_state(),rate*4,777,rate)) == 0.0,"Solo preserves route, Mute dominates all its layers at %d Hz" % rate)
		synth.sync_rings({},rate*8)
		test.check(synth.ring_level(synth.ring_snapshot()["ring_1"],rate*8,rate) == 1.0 and synth.ring_level(synth.ring_snapshot()["ring_1"],rate*10,rate) == 0.0,"One-bar exit keeps old beat assignment at %d Hz" % rate)
	# Actual retune and road transactions are used for forecast and loss, not fixture-only state mutation.
	var unison_model := Model.new(Session.new(unison,"0000000000000057"))
	unison_model.session.growth_enabled = true
	unison_model.session.draft_pause_until = 22050*1000
	var us := unison_model.synth.initial_state()
	unison_model.render_block(us,unison_model.next_boundary,1,22050)
	var choice: Dictionary = {}
	for proposal in unison_model.session.catalog:
		if proposal["district_id"] == "ring_1" and proposal["verb"] == "retune": choice = {"proposal_id":proposal["proposal_id"],"verb":"retune","target":52}
	var renderer := Renderer.new()
	renderer.source = unison_model._mix_frame
	renderer.state = us.duplicate(true)
	renderer.transport.rendered_frames = unison_model.next_boundary
	var saved := unison_model.snapshot()
	var preview := Preview.build(saved,renderer.snapshot(),choice,unison_model.next_boundary)
	test.check(preview["accepted"] and Presentation.summary(preview["result"]).contains("将形成环形合唱城") and unison_model.snapshot() == saved,"Real retune preview announces formation and emits no live event")
	var request := unison_model.session.request(choice,unison_model.next_boundary,unison_model.next_boundary)
	unison_model.render_block(us,unison_model.next_boundary,1,22050)
	unison_model.render_block(us,unison_model.next_boundary,1,22050)
	test.check(request["accepted"] and unison_model.session.rings["ring_source"]["status"] == "formed","Real C-to-E retune followed by two actual boundaries forms the ring")
	var road_key := Roads.key(Vector2i(8,8),Vector2i(8,7))
	unison_model.session.road_marks[road_key] = {"start":[8,7],"end":[8,8],"count":2,"frame":0}
	unison_model.session.request_tread(Vector2i(8,8),Vector2i(8,7),unison_model.next_boundary,unison_model.next_boundary)
	unison_model.render_block(us,unison_model.next_boundary,1,22050)
	test.check(unison_model.session.rings["ring_source"]["count"] == 0 and Presentation.summary(unison_model.session.last_result).contains("将失去环形合唱城") and Roads.blocked(unison_model.session.road_marks,Vector2i(8,8),Vector2i(8,7)),"Third real tread loses identity, resets count and retains permanent road")
	var sequence_synth := Synth.new(mixed)
	sequence_synth.active_layers.assign(["rhythm"])
	sequence_synth.sync_rings(rings,-44100)
	for index in range(8):
		sequence_synth.set_solo("ring_"+str(index))
		save_pcm("member_"+str(index),sequence_synth.render_block(sequence_synth.initial_state(),88200,88200,22050))
	# An actual allowed member retune can preserve membership while breaking a scored edge.
	var broken := model.fork()
	var break_choice: Dictionary = {}
	for proposal in broken.session.catalog:
		if proposal["district_id"] == "ring_0" and proposal["verb"] == "retune": break_choice = {"proposal_id":proposal["proposal_id"],"verb":"retune","target":55}
	var break_forecast := Preview.forecast(broken.session,break_choice,broken.next_boundary,broken.next_boundary)
	test.check(break_forecast["accepted"] and Presentation.summary(break_forecast["result"]).contains("将失去环形合唱城"),"Allowed C-to-G member retune predicts broken E/G edge")
	broken.session.request(break_choice,broken.next_boundary,broken.next_boundary)
	broken.render_block(state.duplicate(true),broken.next_boundary,1,22050)
	test.check(broken.session.rings["ring_source"]["count"] == 0 and broken.session.city.size() == 9 and broken.session._district("ring_0")["current_midi"] == 55,"Actual member retune resets identity without removing mature houses")
	var center_change := model.fork()
	var center_choice: Dictionary = {}
	for proposal in center_change.session.catalog:
		if proposal["district_id"] == "ring_source" and proposal["verb"] == "retune": center_choice = {"proposal_id":proposal["proposal_id"],"verb":"retune","target":52}
	var center_request := center_change.session.request(center_choice,center_change.next_boundary,center_change.next_boundary)
	center_change.render_block(state.duplicate(true),center_change.next_boundary,1,22050)
	test.check(center_request["accepted"] and center_change.session.rings["ring_source"]["count"] == 0,"Actual center C-to-E retune rejudges all four center edges")
	var split_synth := Synth.new(mixed)
	split_synth.sync_rings(rings,0)
	var whole_state := split_synth.initial_state()
	var split_state := whole_state.duplicate(true)
	var whole := split_synth.render_block(whole_state,22050,777,22050)
	var split := split_synth.render_block(split_state,22050,113,22050)
	split.append_array(split_synth.render_block(split_state,22163,211,22050))
	split.append_array(split_synth.render_block(split_state,22374,453,22050))
	test.check(whole == split and whole_state == split_state,"Arbitrary partition during entry preserves exact PCM and oscillator state")
	var initial: Array = Generator.new().generate("0000000000000057",false)["city"]
	for rate in [22050,44100]:
		var current := Synth.new(initial)
		var prior := OldSynth.new(initial)
		var current_state := current.initial_state()
		var prior_state := prior.initial_state()
		test.check(current.render_block(current_state,rate,1024,rate) == prior.render_block(prior_state,rate,1024,rate) and current_state == prior_state,"All three original-nine types remain byte-identical at %d Hz" % rate)
	for index in range(initial.size()): initial[index]["footprint"] = [[1+(index%3)*6,(index/3)*2]]
	var calibration := Calibration.for_city(initial)
	var full := initial.duplicate(true)
	full.append_array(Fixture.city(true,Vector2i(4,10),"west"))
	full.append_array(Fixture.city(true,Vector2i(12,10),"east"))
	var independent := Fixture.formed(full)
	test.check(independent.size() == 2 and independent["west_source"]["status"] == "formed" and independent["east_source"]["status"] == "formed","Two families independently form without double membership")
	for mode in ["steady27","entry_exit27"]:
		var synth := Synth.new(full)
		synth.guard_enabled = true
		synth.capture_drone = true
		synth.gain = calibration["gain"]
		synth.sync_rings(independent,-44100 if mode == "steady27" else 0)
		var pcm := PackedVector2Array()
		var drone := PackedVector2Array()
		var sound_state := synth.initial_state()
		for at in range(0,22050*16,441):
			if mode == "entry_exit27" and at == 22050*8: synth.sync_rings({},at)
			pcm.append_array(synth.render_block(sound_state,at,441,22050))
			drone.append_array(synth.captured_drone)
		save_pcm(mode,pcm)
		save_pcm(mode+"__drone",drone)
	test.details = {"calibration":calibration,"gain":calibration["gain"],"measurement_rate":22050,"initial_city":initial,"controlled_full_city":full,"ring_states":independent,"notes":valid["notes"],"directory":DIR}
	test.finish(self,"Authoritative geometry/12 edges, real boundary/retune/tread/forecast/snapshot, eight-beat envelopes, drone/ornament invariance, scalar/block identity, fixed-gain two-ring 27 PCM; external pitch/peak/RMS and GPU follow")
