extends RefCounted
const Contract = preload("res://tests/contract_support.gd")
const Synth = preload("res://scripts/audio/district_synth.gd")
const Generator = preload("res://scripts/city/city_generator.gd")
const Schema = preload("res://scripts/city/district_schema.gd")
const Session = preload("res://scripts/proposals/city_interventions.gd")
const Model = preload("res://scripts/audio/city_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")

static func run(tree: SceneTree) -> void:
	var test := Contract.new("AUDIO-005","signal_protection")
	var city: Array = Generator.new().generate("2026100800000001")["city"]
	var normal := Synth.new(city)
	normal.guard_enabled = true
	var before := FileAccess.get_file_as_bytes("res://验证记录/P0/声音褪色/normal_before.f32")
	var golden := normal.render_block(normal.initial_state(),0,44100,22050).to_byte_array()
	test.check(before.size() == 352800 and before == golden,"Normal nine-voice guarded PCM exactly equals captured pre-change float32 baseline")
	var voices: Array = [Schema.create("home","residential",Vector2i(8,6)),Schema.create("shop","commercial",Vector2i(9,6)),Schema.create("factory","industrial",Vector2i(10,6))]
	voices[1]["current_midi"] = 49
	var dry := Synth.new(voices)
	var wet := Synth.new(voices)
	dry.device_mode = "narrowband"
	wet.device_mode = "narrowband"
	wet.set_gray(true,0)
	test.check(wet.gray_level(0,22050) == 0.0 and wet.gray_level(22050,22050) == 0.5 and wet.gray_level(44100,22050) == 1.0,"Gray transition follows one audio-clock bar exactly")
	var dry_state := dry.initial_state()
	var wet_state := wet.initial_state()
	var protected := true
	var altered := false
	for at in range(8192):
		var a := dry.render_tracks(dry_state,at,22050)
		var b := wet.render_tracks(wet_state,at,22050)
		for key in a:
			if key.ends_with("_Drone") or key.ends_with("_Assist"):
				protected = protected and a[key] == b[key]
			elif key.ends_with("_Rhythm"):
				altered = altered or a[key] != b[key]
	test.check(protected,"Fixed-pitch drone and all narrowband helpers are sample-identical during gray entry")
	test.check(altered,"Gray processing changes real rhythm PCM")
	var phases := true
	for route in wet.routing:
		phases = phases and wet_state[route["phase_key"]] == dry_state[route["phase_key"]]
	test.check(phases,"Gray processing does not change any oscillator phase or pitch")
	var fast := Synth.new(voices)
	var slow := Synth.new(voices)
	fast.set_gray(true,0)
	slow.set_gray(true,0)
	fast.guard_enabled = true
	slow.guard_enabled = true
	fast.device_mode = "narrowband"
	slow.device_mode = "narrowband"
	var fs := fast.initial_state()
	var ss := slow.initial_state()
	var position := 0
	var exact := true
	for amount in [257,503,1024,44100]:
		var block := fast.render_block(fs,position,amount,22050)
		for offset in range(amount):
			exact = exact and block[offset] == slow._mix_frame(ss,position+offset,22050)
		position += amount
	test.check(exact and fs == ss,"Entry and steady gray across irregular blocks match canonical PCM and float32 filters exactly")
	fast.set_gray(false,position)
	slow.set_gray(false,position)
	var exit_pcm := fast.render_block(fs,position,44107,22050)
	exact = true
	for offset in range(exit_pcm.size()):
		exact = exact and exit_pcm[offset] == slow._mix_frame(ss,position+offset,22050)
	test.check(exact and fs == ss and fast.gray_level(position+44100,22050) == 0.0,"Exit through bypass seam preserves block/canonical PCM and filter state")
	position += exit_pcm.size()
	var restored := Synth.new(voices)
	restored.device_mode = "narrowband"
	restored.guard_enabled = true
	var resumed := fs.duplicate(true)
	test.check(fast.render_block(fs,position,1024,22050) == restored.render_block(resumed,position,1024,22050),"After gray exit normal synthesis is restored at continuous current phase")
	var reverse := Synth.new(voices)
	reverse.set_gray(true,0)
	reverse.set_gray(false,22050)
	test.check(reverse.gray_level(22050,22050) == 0.5 and reverse.gray_level(44100,22050) == 0.25 and reverse.gray_level(66150,22050) == 0.0,"Interrupted transition reverses continuously from current proportion")
	var muted := Synth.new(voices)
	var audible := Synth.new(voices)
	muted.set_gray(true,0)
	audible.set_gray(true,0)
	muted.guard_enabled = true
	audible.guard_enabled = true
	muted.drone_gain = 0.003
	audible.drone_gain = 0.003
	muted.rhythm_gain = 0.2
	audible.rhythm_gain = 0.2
	muted.set_mute("home",true)
	var ms := muted.initial_state()
	var aus := audible.initial_state()
	var isolated := true
	for at in range(9216):
		var a := audible.render_tracks(aus,at,22050)
		var b := muted.render_tracks(ms,at,22050)
		for key in a:
			isolated = isolated and (b[key] == Vector2.ZERO if key.begins_with("District_home_") else b[key] == a[key])
	test.check(isolated and ms == aus,"Mute zeroes target only while gray filters, guard and phase keep running identically")
	test.check(float(ms.get("_guard_factor",1.0)) > 1.0,"Gray mute isolation is exercised under actual nontrivial RMS compensation")
	for voice in voices:
		muted.set_mute(voice["district_id"],true)
	test.check(muted.render_block(ms,9216,1024,22050).count(Vector2.ZERO) == 1024,"All-muted gray remains exact zero with protection enabled")
	var low_city: Array = voices.duplicate(true)
	for index in range(low_city.size()):
		low_city[index]["current_midi"] = 48+index%2
	var session := Session.new(low_city,"2026100800000001")
	var model := Model.new(session)
	var boundary := session.transport.phrase_frame(1)
	model._mix_frame(model.synth.initial_state(),boundary,22050)
	test.check(session.lifecycle["gray"] and model.synth.gray_enabled and model.synth.gray_change_at == boundary,"Real low-R phrase transaction activates gray sound exactly on boundary")
	var renderer := Renderer.new()
	renderer.source = model._mix_frame
	renderer.state = model.synth.initial_state()
	renderer.transport.rendered_frames = boundary
	renderer.render(173)
	var saved := renderer.snapshot()
	var forked := model.fork()
	var copy := Renderer.new()
	copy.source = forked._mix_frame
	copy.restore(saved)
	test.check(copy.render(2503) == renderer.render(2503) and copy.state == renderer.state and forked.snapshot() == model.snapshot(),"Preview fork restores gray target, fade origin and every per-voice filter sample exactly")
	for voice in session.city:
		voice["current_midi"] = 48
	var next := model.next_boundary
	model._mix_frame(renderer.state,next,22050)
	test.check(not session.lifecycle["gray"] and not model.synth.gray_enabled and model.synth.gray_change_at == next,"Real recovered-R phrase transaction reverses gray sound on boundary")
	var probe := Synth.new([voices[2]])
	probe.active_layers.assign(["rhythm"])
	var pstate := probe.initial_state()
	var normal_pcm := probe.render_block(pstate,0,88200,22050)
	var faded := Synth.new([voices[2]])
	faded.active_layers.assign(["rhythm"])
	faded.set_gray(true,0)
	var faded_pcm := faded.render_block(faded.initial_state(),0,88200,22050)
	for item in [["normal_rhythm",normal_pcm],["gray_rhythm",faded_pcm]]:
		var file := FileAccess.open("res://验证记录/P0/声音褪色/"+item[0]+".f32",FileAccess.WRITE)
		file.store_buffer(item[1].to_byte_array())
		file.close()
	test.details = {"baseline_bytes":golden.size(),"transition_frames":44100,"lowpass_hz":wet.values["gray_audio"]["lowpass_hz"],"hold_frames":wet.gray_hold_frames[22050],"wet":wet.values["gray_audio"]["wet"],"subjective_acceptance":"PENDING human aesthetic and diagnostic listening","event_feedback":"not triggered in P0"}
	test.finish(tree,"Technical gray-layer protection only; subjective beauty and diagnostic masking require humans")
