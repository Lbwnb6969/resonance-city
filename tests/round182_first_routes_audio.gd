extends SceneTree
## Same actual planning chain, natural settlement, complete score and restorable phase state.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const First = preload("res://scripts/world/first_composition.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const PlanningCard = preload("res://scripts/world/planning_card.gd")
const Rules = preload("res://scripts/world/community_music_rules.gd")
const OUTPUT := "res://验证记录/round182_首作持续路线/"
const SEED := "2026100900000062"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_root_followup" if OS.get_cmdline_user_args().has("--root-followup") else "_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _renderer(model: Model,snapshot: Dictionary = {}) -> Renderer:
	var renderer := Renderer.new(int(model.world.cfg["timing"]["sample_rate"]))
	renderer.source = model.render_block
	if not snapshot.is_empty(): renderer.restore(snapshot)
	return renderer

func _root(model: Model,choice: String) -> Dictionary:
	for family: Dictionary in model.world.families.values():
		if bool(family.get("player_expression",false)) and str(family.get("expression","")) == choice:
			return model.world.by_id.get(str(family["root"]),{})
	return {}

func _part(model: Model,root_id: String) -> Dictionary:
	for part: Dictionary in model.synth.rhythms:
		if str(part.get("source_id","")) == root_id: return part
	return {}

func _phrase(model: Model) -> Dictionary:
	var score := model.synth.score_snapshot()
	return {"phrase":model.world.phrase_index,"buildings":model.world.buildings.size(),
		"status":Rules.status(model.world,"west-1"),"community_expression":model.world.community_expression("west-1"),
		"theme":score.get("theme",{}),"response":score.get("response",{}),"rhythms":score.get("rhythms",[]),
		"reservations":model.world.planning_reservations.duplicate(true)}

func _advance(model: Model,renderer: Renderer,end: int,history: Array) -> void:
	while renderer.transport.rendered_frames < end:
		var before := model.world.phrase_index
		renderer.render(mini(512,end-renderer.transport.rendered_frames))
		if before != model.world.phrase_index: history.append(_phrase(model))
	# Offline playback has no queue. Discard only already audible presentation history.
	renderer.transport.audible_frame = renderer.transport.rendered_frames
	model.presentation_world(renderer.transport.audible_frame)

func _render_phrase(model: Model,renderer: Renderer,count: int) -> Dictionary:
	model.enable_music_activity()
	var block := PackedVector2Array()
	var events: Dictionary = {}
	var root_rows: Array = []
	var root_id := str(_root(model,model.world.community_expression("west-1")).get("district_id",""))
	while block.size() < count:
		var start := renderer.transport.rendered_frames
		var amount := mini(512,count-block.size())
		block.append_array(renderer.render(amount))
		for row: Dictionary in model.synth.captured_music_segments:
			if maxf(float(row["level_from"]),float(row["target"])) <= 0.0 or float(row["amplitude"]) <= 0.0: continue
			var key := str(row["event_id"])
			if not events.has(key):
				var event: Dictionary = {}
				for field in ["event_id","source_event_id","source_id","receiver_id","generation","source_onset","onset","pitch","cid","expression","envelope_tail"]: event[field] = row[field]
				events[key] = event
		var probe := start+amount-1
		for row: Dictionary in model.audible_music_activity(probe):
			if str(row["source_id"]) == root_id and not root_rows.any(func(old: Dictionary) -> bool: return old["event_id"] == row["event_id"]): root_rows.append(row)
	var peak := 0.0
	var energy := 0.0
	for sample in block:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		energy += sample.length_squared()
	renderer.transport.audible_frame = renderer.transport.rendered_frames
	model.presentation_world(renderer.transport.audible_frame)
	return {"pcm":Renderer.pcm16(block),"peak":peak,"rms":sqrt(energy/float(block.size()*2)),"events":events.values(),"root_activity":root_rows}

func _difference(a: PackedByteArray,b: PackedByteArray) -> float:
	var maximum := 0.0
	for offset in range(0,mini(a.size(),b.size()),2): maximum = maxf(maximum,absf(float(a.decode_s16(offset)-b.decode_s16(offset))/32767.0))
	return maximum

func _digest(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(bytes)
	return digest.finish().hex_encode()

func _wav(pcm: PackedByteArray,rate: int,path: String) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = pcm
	check(wav.save_to_wav(path) == OK,path.get_file()+"_actual_full_score_export")

func _root_followup() -> void:
	# A focused follow-up to the measured omission: the sparse note cycle did
	# not play the deep/weave author root within phrase8. Keep all production
	# rotation, growth and note order while waiting for its next actual onset.
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT+"first_routes_audio.json"))
	checks = report["checks"]
	failures.assign(report["failures"])
	evidence = report["evidence"]
	var rate := int(evidence["sample_rate"])
	for choice: String in ["deep","weave"]:
		var branch: Dictionary = evidence["branches"][choice]
		var checkpoint := Archive.read(str(branch["checkpoint"]["path"]))
		var snapshot: Dictionary = checkpoint["city"]
		var baseline := Model.from_state(snapshot["model"])
		var edited := Model.from_state(snapshot["model"])
		var old_renderer := _renderer(baseline,snapshot["renderer"])
		var new_renderer := _renderer(edited,snapshot["renderer"])
		baseline.enable_music_activity()
		edited.enable_music_activity()
		var request := edited.submit(branch["retune"]["operation"])
		var root_id := str(branch["root"]["district_id"])
		var old_row: Dictionary = {}
		var new_row: Dictionary = {}
		var old_samples := PackedVector2Array()
		var new_samples := PackedVector2Array()
		var excerpt_frame := -1
		while old_renderer.transport.rendered_frames < int(evidence["comparison_frame"])+baseline.phrase_frames*4:
			var start := old_renderer.transport.rendered_frames
			var old_block := old_renderer.render(512)
			var new_block := new_renderer.render(512)
			for row: Dictionary in baseline.audible_music_activity(start+511):
				if str(row["source_id"]) == root_id and int(row["generation"]) == 0:
					old_row = row
					break
			if old_row.is_empty(): continue
			for row: Dictionary in edited.audible_music_activity(start+511):
				if str(row["source_id"]) == root_id and int(row["generation"]) == 0 and int(row["onset"]) == int(old_row["onset"]):
					new_row = row
					break
			excerpt_frame = start
			old_samples.append_array(old_block)
			new_samples.append_array(new_block)
			while old_samples.size() < rate*2:
				var amount := mini(512,rate*2-old_samples.size())
				old_samples.append_array(old_renderer.render(amount))
				new_samples.append_array(new_renderer.render(amount))
			break
		check(not old_row.is_empty() and not new_row.is_empty() and int(new_row["pitch"]) == int(old_row["pitch"])+4 and old_row["source_id"] == new_row["source_id"] and old_row["public_site_ids"] == new_row["public_site_ids"],choice+"_next_natural_author_root_lead_actually_changes_pitch_and_keeps_its_real_map_source")
		var old_pcm := Renderer.pcm16(old_samples)
		var new_pcm := Renderer.pcm16(new_samples)
		check(not old_pcm.is_empty() and _difference(old_pcm,new_pcm) > 0.005,choice+"_next_actual_author_lead_excerpt_has_measured_formal_full_score_pcm_change")
		if not old_pcm.is_empty():
			_wav(old_pcm,rate,OUTPUT+choice+"_root_next_lead_before.wav")
			_wav(new_pcm,rate,OUTPUT+choice+"_root_next_lead_after.wav")
		branch["retune"]["next_natural_root_lead"] = {"request":request,"excerpt_frame":excerpt_frame,"excerpt_seconds":2.0,"old_activity":old_row,"new_activity":new_row,"pcm_max_abs":_difference(old_pcm,new_pcm),"actual_phrase":baseline.world.phrase_index}
		print("ROUND182 next root "+choice+" "+JSON.stringify(branch["retune"]["next_natural_root_lead"]))
	_finish()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var city := World.new(SEED,true,"river_valley")
	city.build_first_composition_starter()
	var gain := float(JSON.parse_string(FileAccess.get_file_as_string("res://数据/valley_score_calibration.json"))["gain"])
	var source := Model.new(city,gain)
	var rate := int(city.cfg["timing"]["sample_rate"])
	var renderer := _renderer(source)
	var cards := PlanningCard.choices(city,"compact")
	var card := "infill_pulse" if cards.has("infill_pulse") else cards[0]
	var public_position: Array = []
	for candidate: Dictionary in First.opportunities(city)["public_candidates"]:
		if str(candidate["community_id"]) == "west-1": public_position = candidate["position"].duplicate()
	check(city.buildings.size() == 24 and city.phrase_index == 0 and city.buildings.all(func(house: Dictionary) -> bool: return str(house["form"]) == "胚"),"fresh_same_seed_starts_with_twenty_four_real_embryonic_houses")
	var charter_op := {"kind":"charter","plan_id":"compact","community_ids":["west-1"],"card_refs":[card]}
	var civic_op := {"kind":"civic","position":public_position}
	var charter := source.submit(charter_op)
	var civic := source.submit(civic_op)
	check(bool(charter["accepted"]) and bool(civic["accepted"]) and not public_position.is_empty(),"real_same_compact_variation_card_and_west_one_cultural_anchor_are_accepted")
	var common_history: Array = []
	var source_frame := source.phrase_frames*2-128
	_advance(source,renderer,source_frame,common_history)
	var position: Array = []
	for candidate: Dictionary in First.opportunities(city)["seed_candidates"]:
		if str(candidate["community_id"]) == "west-1": position = candidate["position"].duplicate()
	check(city.phrase_index == 1 and bool(Rules.facilities(city,"west-1")["civic"]) and not position.is_empty() and bool(city.placement(Vector2(position[0],position[1]))["allowed"]),"sound_choice_uses_same_actual_legal_position_after_first_phrase_growth_and_anchor")
	if position.is_empty():
		_finish()
		return
	var shared := {"model":source.capture_state(),"renderer":renderer.snapshot(),"view":{"first_composition_mode":true}}
	var target := source.phrase_frames*8
	var duration := source.phrase_frames
	var outputs: Dictionary = {}
	var branches: Dictionary = {}
	for choice: String in PlayerExpression.IDS:
		print("ROUND182 route "+choice+" natural continuation")
		var model := Model.from_state(shared["model"])
		var render := _renderer(model,shared["renderer"])
		var operation := PlayerExpression.operation(choice,position)
		var request := model.submit(operation)
		check(bool(request["accepted"]) and int(request["frame"]) == source.phrase_frames*2,choice+"_same_position_expression_is_a_normal_second_phrase_transaction")
		var history := common_history.duplicate(true)
		_advance(model,render,target,history)
		var root := _root(model,choice)
		var root_id := str(root.get("district_id",""))
		check(not root.is_empty() and root["position"] == position and str(root["expression"]) == choice and bool(root["player_expression"]),choice+"_authored_root_and_saved_expression_survive_eight_phrase_continuation")
		if root.is_empty(): continue
		var snapshot := {"model":model.capture_state(),"renderer":render.snapshot(),"view":{"first_composition_mode":true,"selected_id":root_id}}
		var directory := ProjectSettings.globalize_path(OUTPUT+choice+"_state")
		var saved := Archive.save(snapshot,"Round182 technical route checkpoint; not a player save",directory)
		check(bool(saved["ok"]),choice+"_production_archive_writes_model_and_renderer_phases_only_to_evidence_directory")
		var loaded: Dictionary = Archive.read(str(saved["path"])) if bool(saved["ok"]) else {"ok":false}
		check(bool(loaded["ok"]) and loaded["city"]["model"] == snapshot["model"] and loaded["city"]["renderer"] == snapshot["renderer"],choice+"_production_archive_reads_exact_model_and_phase_state")
		var formal := _render_phrase(model,render,duration)
		var restored := Model.from_state(loaded["city"]["model"])
		var restored_renderer := _renderer(restored,loaded["city"]["renderer"])
		var replay := _render_phrase(restored,restored_renderer,duration)
		check(formal["pcm"] == replay["pcm"] and render.state == restored_renderer.state and model.world.snapshot() == restored.world.snapshot(),choice+"_disk_checkpoint_replays_the_complete_sixteen_second_score_byte_identically")
		var part := _part(model,root_id)
		var profile := model.synth.rhythm_profile(part,rate) if not part.is_empty() else {}
		check(not part.is_empty() and bool(part.get("player_expression",false)) and str(part["expression"]) == choice and int(profile["pitch"]) == int(root["current_midi"])+int(PlayerExpression.definition(choice)["rhythm_offset"]),choice+"_persistent_author_root_still_occupies_an_actual_existing_rhythm_slot")
		check(history.any(func(phrase: Dictionary) -> bool: return str(phrase["theme"].get("expression","")) == choice and bool(phrase["theme"].get("player_expression",false)) and str(phrase["theme"].get("cid","")) == "west-1") and int(Rules.status(model.world,"west-1")["mature"]) >= 6,choice+"_natural_mature_houses_form_the_actual_authored_lead_during_normal_theme_rotation")
		var family: Dictionary = model.world.families[str(root["family_id"])]
		var reservations: Array = model.world.planning_reservations.filter(func(item: Dictionary) -> bool: return str(item["id"]) == str(family.get("expression_reservation_id","")))
		check(reservations.size() == (1 if choice == "warm" else 0),choice+"_real_reserved_empty_land_persists_only_for_warm")
		check(formal["peak"] > 0.0 and formal["peak"] < 1.0 and model.synth.gain == gain and model.synth.max_voice_count <= 70 and int(model.synth.score["render_voice_limit"]) == 70,choice+"_continued_full_score_preserves_real_gain_headroom_and_voice_budget")
		_wav(formal["pcm"],rate,OUTPUT+choice+"_phrase8.wav")
		var edited := Model.from_state(snapshot["model"])
		var edited_renderer := _renderer(edited,snapshot["renderer"])
		var new_midi := int(root["current_midi"])+4
		var retune_op := {"kind":"retune","id":root_id,"midi":new_midi}
		var retune := edited.submit(retune_op)
		check(bool(retune["accepted"]) and int(retune["sound_frame"]) == target+model.beat_frames,choice+"_single_author_root_plus_four_retune_is_accepted_on_the_first_writable_beat")
		var changed := _render_phrase(edited,edited_renderer,duration)
		var old_notes := model.world.community_theme("west-1",model.sound_overrides)
		var new_notes := edited.world.community_theme("west-1",edited.sound_overrides)
		var source_ids := model.world.community_theme_sources("west-1")
		var index := source_ids.find(root_id)
		var new_part := _part(edited,root_id)
		var new_profile := edited.synth.rhythm_profile(new_part,rate) if not new_part.is_empty() else {}
		check(index >= 0 and old_notes[index] == root["current_midi"] and new_notes[index] == new_midi and old_notes != new_notes and edited.sound_overrides[root_id] == new_midi and root["position"] == _root(edited,choice)["position"],choice+"_one_retune_changes_the_real_source_theme_note_at_the_same_house_position")
		check(not new_profile.is_empty() and int(new_profile["pitch"]) == int(profile["pitch"])+4 and _difference(formal["pcm"],changed["pcm"]) > 0.005,choice+"_author_root_retune_changes_actual_rhythm_pitch_and_complete_score_pcm")
		_wav(changed["pcm"],rate,OUTPUT+choice+"_root_plus4_phrase8.wav")
		outputs[choice] = formal["pcm"]
		branches[choice] = {"operation":operation,"request":request,"checkpoint":saved,"start_frame":target,"end_frame":target+duration,
			"phrase_history":history,"phrase8":_phrase(model),"root":root,"family":family,"rhythm_profile":profile,
			"rhythm_events":model.synth.rhythm_events(part,target,duration,rate),"actual_musical_events":formal["events"],"actual_root_activity":formal["root_activity"],
			"peak":formal["peak"],"rms":formal["rms"],"max_voices":model.synth.max_voice_count,"wav":OUTPUT+choice+"_phrase8.wav","pcm_sha256":_digest(formal["pcm"]),
			"restored_pcm_max_abs":_difference(formal["pcm"],replay["pcm"]),"actual_reservations":reservations,
			"retune":{"operation":retune_op,"request":retune,"old_source_notes":old_notes,"new_source_notes":new_notes,"source_ids":source_ids,"root_note_index":index,
				"old_rhythm_profile":profile,"new_rhythm_profile":new_profile,"actual_events":changed["events"],"actual_root_activity":changed["root_activity"],
				"pcm_max_abs":_difference(formal["pcm"],changed["pcm"]),"wav":OUTPUT+choice+"_root_plus4_phrase8.wav"}}
		print("ROUND182 route "+choice+" complete "+JSON.stringify({"houses":model.world.buildings.size(),"root":root_id,"profile":profile,"peak":formal["peak"],"retune_pcm_max_abs":branches[choice]["retune"]["pcm_max_abs"]}))
	var differences: Dictionary = {}
	for pair in [["deep","weave"],["deep","warm"],["weave","warm"]]:
		if not outputs.has(pair[0]) or not outputs.has(pair[1]): continue
		var value := _difference(outputs[pair[0]],outputs[pair[1]])
		differences[pair[0]+"_"+pair[1]] = value
		check(value > 0.005,pair[0]+"_"+pair[1]+"_continued_complete_scores_still_differ_in_real_pcm")
	check(source.capture_state() == shared["model"] and renderer.snapshot() == shared["renderer"],"three_normal_route_continuations_leave_the_common_source_and_phases_unchanged")
	evidence = {"seed":SEED,"sample_rate":rate,"gain":gain,"charter_operation":charter_op,"drawn_cards":cards,"civic_operation":civic_op,
		"shared_source_frame":source_frame,"seed_position":position,"comparison_frame":target,"duration_frames":duration,"seconds":float(duration)/rate,
		"branches":branches,"pair_pcm_max_abs":differences,
		"interpretation":"Only real formal full-score PCM, natural settlement, runtime event sources and recoverable technical checkpoints. Normal rotation/rests are preserved. No human listening, preference, route balance or fun verdict is claimed."}
	_finish()

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence}
	FileAccess.open(OUTPUT+"first_routes_audio.json",FileAccess.WRITE).store_string(JSON.stringify(Archive._json_value(report),"  ")+"\n")
	print("ROUND182_FIRST_ROUTES_AUDIO "+JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
