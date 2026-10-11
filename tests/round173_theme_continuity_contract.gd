extends SceneTree
## Natural mature starter, production next-beat retunes, and actual PCM nodes.
## This proves renderer continuity/identity; it does not claim human listening.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Archive = preload("res://scripts/world/city_archive.gd")
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const RiverResponse = preload("res://scripts/world/river_call_response.gd")
const SEED := "2026100900000062"
const PROBE := 256
const EVIDENCE_PATH := "res://验证记录/round173_改音自然衔接/theme_continuity_contract.json"

var checks: Dictionary = {}
var failures: Array[String] = []
var details: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"details":details,
		"scope":"Production-seed mature starter and actual authored source/receiver events. No fabricated qualification; PCM/state continuation and next-beat envelopes only. Boundary-only natural-settlement checks do not claim uninterrupted long-duration PCM or human listening."}
	DirAccess.make_dir_recursive_absolute(EVIDENCE_PATH.get_base_dir())
	var file := FileAccess.open(EVIDENCE_PATH,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"\t")+"\n")
		file.close()
	else: check(false,"evidence_writes")
	print("ROUND173_THEME_CONTINUITY_CONTRACT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func _render_until(model: Model,state: Dictionary,finish: int,chunk: int = 1024) -> PackedVector2Array:
	var pcm := PackedVector2Array()
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	while model.rendered_until < finish:
		var at := model.rendered_until
		pcm.append_array(model.render_block(state,at,mini(chunk,finish-at),rate))
	return pcm

func _node(model: Model,answer: bool) -> Dictionary:
	for node: Dictionary in model.synth.musical_nodes.values():
		if bool(node.get("active",false)) and bool(node.get("answer",false)) == answer: return node
	return {}

func _level(state: Dictionary,node: Dictionary) -> float:
	return float(state.get("_theme_level_"+str(node.get("key","")),0.0))

func _schedule(model: Model,answer: bool,start: int) -> Array[Dictionary]:
	var node := _node(model,answer)
	if node.is_empty(): return []
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	return model.synth.musical_events(node,start,model.phrase_frames,rate)

func _event(events: Array,source_id: String,onset: int) -> Dictionary:
	for raw: Dictionary in events:
		if str(raw.get("source_id","")) == source_id and int(raw.get("onset",-1)) == onset: return raw
	return {}

func _row(rows: Array,event_id: String) -> Dictionary:
	for raw: Dictionary in rows:
		if str(raw.get("event_id","")) == event_id: return raw
	return {}

func _same_event(a: Dictionary,b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty(): return false
	for key in ["event_id","source_event_id","source_id","receiver_id","generation","source_onset","onset","pitch"]:
		if a.get(key,null) != b.get(key,null): return false
	return true

func _max_difference(a: PackedVector2Array,b: PackedVector2Array) -> float:
	if a.size() != b.size(): return INF
	var maximum := 0.0
	for index in range(a.size()):
		maximum = maxf(maximum,maxf(absf(a[index].x-b[index].x),absf(a[index].y-b[index].y)))
	return maximum

func _new_pitch(model: Model,source_id: String) -> int:
	var source_ids: Array = model.synth.theme.get("source_ids",[])
	var index := source_ids.find(source_id)
	if index < 0: return -1
	var original := int(model.synth.theme["notes"][index])
	for pitch in [55,52,50,57,48]:
		if pitch == original: continue
		var overrides := model.sound_overrides.duplicate(true)
		overrides[source_id] = pitch
		var theme := model.synth.theme.duplicate(true)
		theme["notes"][index] = pitch
		var reply := RiverResponse.reply(model.world,theme,RiverResponse.pairs(model.world,overrides),overrides)
		var receivers: Array = reply.get("receiver_ids",[])
		if str(reply.get("cid","")) == str(model.synth.response.get("cid","")) and index < receivers.size() and not str(receivers[index]).is_empty(): return pitch
	return -1

func _test_partial_control(base: Model,base_state: Dictionary,source: Dictionary,reply: Dictionary,new_pitch: int,kind: String) -> void:
	var model := base.freeze()
	model.enable_music_activity()
	var state := base_state.duplicate(true)
	var onset := int(source["onset"])
	var lead_cid := str(model.synth.theme["cid"])
	var listening_cid := ""
	for cid in model.world.communities:
		if str(cid) != lead_cid and not bool(MusicRules.status(model.world,str(cid))["theme_eligible"]):
			listening_cid = str(cid)
			break
	var operation := {"kind":"mute","community":lead_cid,"enabled":true} if kind == "mute" else {"kind":"solo","community":listening_cid}
	var control := model.submit(operation)
	check(bool(control.get("accepted",false)) and int(control.get("sound_frame",-1)) == onset and (kind == "mute" or not listening_cid.is_empty()),kind+"_uses_real_next_beat_control_without_changing_theme_community")
	var cut := onset+model.beat_frames
	_render_until(model,state,cut-1)
	var retune := model.submit({"kind":"retune","id":source["source_id"],"midi":new_pitch})
	var previous := _node(model,false).duplicate(true)
	var before := _level(state,previous)
	_render_until(model,state,cut)
	var handoff_level := _level(state,previous)
	var comparison := model.freeze()
	var comparison_state := state.duplicate(true)
	var first := _render_until(model,state,cut+1)
	var active := _node(model,false)
	var fade_step := 1.0/(float(model.synth.score["control_fade_beats"])*model.beat_frames)
	var target := 0.0 if kind == "mute" else float(model.synth.score["background_gain"])
	var expected := move_toward(handoff_level,target,fade_step)
	check(bool(retune.get("accepted",false)) and int(retune.get("sound_frame",-1)) == cut and before > target+0.05 and before < 0.95 and str(active.get("part",{}).get("cid","")) == lead_cid and absf(_level(state,active)-expected) < 0.0000001,kind+"_retune_inherits_actual_partial_fade_instead_of_resetting_or_unmuting")
	first.append_array(_render_until(model,state,cut+PROBE+1))
	var one_block := _render_until(comparison,comparison_state,cut+PROBE+1,PROBE+1)
	var chunk_error := _max_difference(first,one_block)
	check(chunk_error <= 0.00000004 and absf(_level(state,_node(model,false))-_level(comparison_state,_node(comparison,false))) < 0.0000001,kind+"_handoff_reads_block_start_level_independent_of_chunk_length")
	var reply_probe := int(reply["onset"])+PROBE
	_render_until(model,state,reply_probe+1)
	var row := _row(model.audible_music_activity(reply_probe),str(reply["event_id"]))
	var reply_strength := float(row.get("strength",0.0))
	check((row.is_empty() or reply_strength < 0.95) if kind == "mute" else _same_event(row,reply) and reply_strength > 0.000001 and reply_strength < 0.95,kind+"_retune_keeps_real_source_control_on_delayed_old_reply")
	check(absf(_level(state,_node(model,false))-target) < 0.0000001,kind+"_retuned_theme_reaches_original_control_target")
	var node_levels: Array = []
	for candidate: Dictionary in model.synth.musical_nodes.values(): node_levels.append({"key":candidate.get("key",""),"active":candidate.get("active",false),"answer":candidate.get("answer",false),"level":_level(state,candidate),"born":candidate.get("born_at",-1),"retired":candidate.get("retired_at",-1)})
	details[kind] = {"control":control,"retune":retune,"active_key":active.get("key",""),"level_before":before,"handoff_level":handoff_level,"level_after":_level(state,active),"first_expected":expected,"chunk_max_abs":chunk_error,"reply_row":row,"listener":listening_cid,"voice_max":model.synth.max_voice_count,"node_levels":node_levels}

func _test_response_off_on(base: Model,base_state: Dictionary,source: Dictionary,reply: Dictionary) -> void:
	var model := base.freeze()
	model.enable_music_activity()
	var state := base_state.duplicate(true)
	var source_probe := int(source["onset"])+PROBE
	_render_until(model,state,source_probe+1)
	var old := _node(model,true).duplicate(true)
	var off := model.submit({"kind":"response","enabled":false})
	var off_frame := int(off.get("sound_frame",-1))
	_render_until(model,state,off_frame+1)
	var on := model.submit({"kind":"response","enabled":true})
	var on_frame := int(on.get("sound_frame",-1))
	_render_until(model,state,on_frame+1)
	var active := _node(model,true)
	var fade_step := 1.0/(float(model.synth.score["control_fade_beats"])*model.beat_frames)
	check(bool(off.get("accepted",false)) and bool(on.get("accepted",false)) and off_frame == int(source["onset"])+model.beat_frames and on_frame == int(reply["onset"]),"quick_response_off_on_uses_real_beats_at_old_answer_onset")
	check(not active.is_empty() and int(active.get("born_at",-1)) == on_frame and str(active.get("key","")) != str(old.get("key","")) and absf(_level(state,active)-fade_step) < 0.0000001,"quick_response_on_starts_a_new_cold_lifecycle_without_retired_level")
	var probe := int(reply["onset"])+PROBE
	_render_until(model,state,probe+1)
	var rows: Array = model.audible_music_activity(probe)
	var old_row := _row(rows,str(reply["event_id"]))
	check(_same_event(old_row,reply) and rows.filter(func(row: Dictionary) -> bool: return str(row.get("event_id","")) == str(reply["event_id"])).size() == 1,"quick_response_on_preserves_exactly_one_old_already_authored_reply")
	check(model.synth.musical_events(active,on_frame,PROBE+1,int(model.world.cfg["timing"]["sample_rate"])).all(func(event: Dictionary) -> bool: return int(event["source_onset"]) >= on_frame),"new_response_lifecycle_never_replays_pre_on_sources")
	details["response_off_on"] = {"off":off,"on":on,"old_key":old.get("key",""),"new_key":active.get("key",""),"old_reply":old_row,"cold_step":fade_step}

func _test_natural_rest(base: Model,base_state: Dictionary) -> void:
	var model := base.freeze()
	var state := base_state.duplicate(true)
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	# Boundary-only stepping invokes actual World settlement; no buildings/forms
	# or qualification are edited. Full continuous PCM is tested above.
	while model.world.phrase_index < 5:
		var boundary := model.next_boundary
		model.render_block(state,boundary-1,2,rate)
	var before := _node(model,false).duplicate(true)
	var level_before := _level(state,before)
	var rest := model.next_boundary
	model.render_block(state,rest-1,2,rate)
	check(model.world.phrase_index == 6 and model.synth.theme.is_empty() and _node(model,false).is_empty() and not before.is_empty() and int(model.synth.musical_nodes.get(before.get("key",""),{}).get("retired_at",-1)) == rest,"natural_seventh_phrase_rest_retires_real_theme_at_absolute_boundary")
	var fade_frames := roundi(float(model.synth.score["control_fade_beats"])*model.beat_frames)
	var quiet_frame := rest+fade_frames+model.beat_frames*3
	_render_until(model,state,quiet_frame)
	var residual_levels: Array[float] = []
	var all_quiet := true
	for node: Dictionary in model.synth.musical_nodes.values():
		var residual := _level(state,node)
		residual_levels.append(residual)
		if bool(node.get("active",false)) or residual > 0.0001: all_quiet = false
	check(all_quiet and model.audible_music_activity(quiet_frame).is_empty(),"natural_rest_reaches_real_silence_boundary_after_delayed_reply_fades")
	var returning := model.next_boundary
	model.render_block(state,returning-1,2,rate)
	var active := _node(model,false)
	var fade_step := 1.0/fade_frames
	check(model.world.phrase_index == 7 and not active.is_empty() and int(active.get("born_at",-1)) == returning and absf(_level(state,active)-fade_step) < 0.0000001,"theme_return_after_natural_rest_is_cold_not_a_retired_level_handoff")
	details["natural_rest"] = {"rest_frame":rest,"quiet_frame":quiet_frame,"return_frame":returning,"previous_level":level_before,"residual_levels":residual_levels,"activity_at_quiet":model.audible_music_activity(quiet_frame),"return_level":_level(state,active),"return_community":model.synth.theme.get("cid","")}

func _run() -> void:
	var city := World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var model := Model.new(city.fork())
	var start := city.phrase_index*model.phrase_frames
	model.rendered_until = start
	model.enable_music_activity()
	var state: Dictionary = {}
	var leads := _schedule(model,false,start)
	var replies := _schedule(model,true,start)
	var source: Dictionary = {}
	var reply: Dictionary = {}
	var fade_frames := roundi(float(model.synth.score["control_fade_beats"])*model.beat_frames)
	for candidate: Dictionary in replies:
		var paired := _event(leads,str(candidate["source_id"]),int(candidate["source_onset"]))
		if not paired.is_empty() and int(paired["onset"]) >= start+fade_frames+model.beat_frames and int(candidate["onset"])+model.beat_frames+PROBE < model.next_boundary:
			source = paired
			reply = candidate
			break
	check(city.phrase_index == 2 and bool(MusicRules.status(city,str(model.synth.theme.get("cid","")))["theme_eligible"]) and not source.is_empty() and not reply.is_empty(),"natural_rework_starter_supplies_mature_theme_and_real_paired_test_window")
	if source.is_empty() or reply.is_empty():
		_finish()
		return
	var new_pitch := _new_pitch(model,str(source["source_id"]))
	check(new_pitch >= 0 and new_pitch != int(city.by_id[str(source["source_id"])]["current_midi"]),"different_allowed_note_keeps_actual_receiving_community_available")
	if new_pitch < 0:
		_finish()
		return
	var onset := int(source["onset"])
	var submit_at := onset-model.beat_frames+1
	_render_until(model,state,submit_at)
	var base := model.freeze()
	var base_state := state.duplicate(true)
	var original_world := model.world.snapshot()
	var original_rng := model.world.rng.snapshot().duplicate(true)
	var reference := model.freeze()
	reference.enable_music_activity()
	var reference_state := state.duplicate(true)
	var retune := model.submit({"kind":"retune","id":source["source_id"],"midi":new_pitch})
	check(bool(retune.get("accepted",false)) and int(retune.get("sound_frame",-1)) == onset and int(retune.get("frame",-1)) == model.next_boundary,"single_source_retune_uses_next_writable_beat_and_keeps_structure_pending")
	_render_until(model,state,onset)
	var old_lead := _node(model,false).duplicate(true)
	var old_answer := _node(model,true).duplicate(true)
	var lead_before := _level(state,old_lead)
	var answer_before := _level(state,old_answer)
	check(model.sound_overrides.is_empty() and model.world.by_id[source["source_id"]]["current_midi"] == city.by_id[source["source_id"]]["current_midi"] and lead_before > 0.99 and answer_before > 0.99,"retune_does_not_rewrite_prefetched_music_or_structural_pitch")
	var pending_frozen := model.freeze()
	var pending_restored := Model.from_state(Archive._json_value(model.capture_state()))
	var frozen_state := state.duplicate(true)
	var restored_state := state.duplicate(true)
	var prefix := _render_until(model,state,onset+1)
	var new_lead := _node(model,false)
	var new_answer := _node(model,true)
	check(str(new_lead.get("key","")) != str(old_lead.get("key","")) and int(new_lead.get("born_at",-1)) == onset and int(model.synth.musical_nodes.get(old_lead.get("key",""),{}).get("retired_at",-1)) == onset and absf(_level(state,new_lead)-lead_before) < 0.0000001,"same_community_retune_keeps_warm_lead_level_and_absolute_lifecycles")
	check(str(new_answer.get("key","")) != str(old_answer.get("key","")) and int(new_answer.get("born_at",-1)) == onset and absf(_level(state,new_answer)-answer_before) < 0.0000001,"same_receiving_and_source_communities_keep_warm_reply_level_with_new_source_identity")
	var probe := onset+PROBE
	prefix.append_array(_render_until(model,state,probe+1))
	var frozen_pcm := _render_until(pending_frozen,frozen_state,probe+1,PROBE+1)
	var restored_pcm := _render_until(pending_restored,restored_state,probe+1,PROBE+1)
	var partition_error := _max_difference(prefix,frozen_pcm)
	check(partition_error <= 0.00000004 and absf(_level(state,_node(model,false))-_level(frozen_state,_node(pending_frozen,false))) < 0.0000001,"same_onset_handoff_uses_block_start_level_not_old_nodes_block_end")
	check(frozen_pcm == restored_pcm and frozen_state == restored_state,"pending_handoff_freeze_and_json_restore_continue_with_identical_pcm_and_phase")
	_render_until(reference,reference_state,probe+1)
	var rendered_source := _event(model.audible_music_activity(probe),str(source["source_id"]),onset)
	var old_reference := _row(reference.audible_music_activity(probe),str(source["event_id"]))
	var strength_ratio := float(rendered_source.get("strength",0.0))/maxf(float(old_reference.get("strength",0.0)),0.000000001)
	var new_source := _event(_schedule(model,false,onset),str(source["source_id"]),onset)
	check(not new_source.is_empty() and not rendered_source.is_empty() and int(rendered_source["pitch"]) == int(new_source["pitch"]) and str(rendered_source["event_id"]) == str(new_source["event_id"]) and str(rendered_source["source_id"]) == str(source["source_id"]) and int(rendered_source["generation"]) == 0 and absf(strength_ratio-1.0) < 0.000001,"same_onset_real_source_plays_new_note_at_existing_level_instead_of_two_beat_reentry")
	check(model.audible_music_activity(probe).filter(func(row: Dictionary) -> bool: return int(row.get("generation",-1)) == 0 and int(row.get("onset",-1)) == onset).size() == 1 and _row(model.audible_music_activity(probe),str(source["event_id"])).is_empty(),"same_onset_retune_never_duplicates_or_replays_old_source_pitch")
	var new_reply := _event(_schedule(model,true,onset),str(source["source_id"]),int(reply["onset"]))
	check(not new_reply.is_empty() and str(new_reply["source_event_id"]) == str(rendered_source["event_id"]) and int(new_reply["onset"])-int(rendered_source["onset"]) == model.beat_frames*2,"new_reply_identity_refers_to_real_new_lead_pitch_and_exact_two_beat_delay")
	# A -> B -> A before B's answer. The retired A incarnation must not be
	# resurrected or erase B's still-sounding tail and delayed answer.
	var back := model.submit({"kind":"retune","id":source["source_id"],"midi":city.by_id[source["source_id"]]["current_midi"]})
	var back_frame := int(back.get("sound_frame",-1))
	_render_until(model,state,back_frame+1)
	var back_node := _node(model,false).duplicate(true)
	check(bool(back.get("accepted",false)) and back_frame == onset+model.beat_frames and int(back_node.get("born_at",-1)) == back_frame and str(back_node.get("key","")) != str(old_lead.get("key","")) and absf(_level(state,back_node)-1.0) < 0.0000001,"quick_a_b_a_creates_fresh_a_lifecycle_from_current_b_level")
	var tail_probe := back_frame+PROBE
	_render_until(model,state,tail_probe+1)
	var old_tail := _row(model.audible_music_activity(tail_probe),str(rendered_source["event_id"]))
	check(_same_event(old_tail,rendered_source) and float(old_tail.get("strength",0.0)) > 0.000001 and model.audible_music_activity(tail_probe).filter(func(row: Dictionary) -> bool: return int(row.get("generation",-1)) == 0 and int(row.get("onset",-1)) == onset).size() == 1,"quick_a_b_a_preserves_exactly_one_original_b_tail_without_backdated_a_note")
	var saved := model.capture_state()
	var continuation := model.freeze()
	var continuation_state := state.duplicate(true)
	var restored := Model.from_state(Archive._json_value(saved))
	var restored_phases := state.duplicate(true)
	var before_preview := model.capture_state()
	var phase_before_preview := state.duplicate(true)
	var preview_op := {"kind":"retune","id":source["source_id"],"midi":new_pitch}
	var preview := model.forecast(preview_op,state,model.rendered_until,2205)
	var preview_formal := model.freeze()
	var preview_phases := state.duplicate(true)
	preview_formal.cancel_pending()
	var preview_result := preview_formal.submit(preview_op)
	_render_until(preview_formal,preview_phases,int(preview_result.get("sound_frame",-1)),512)
	var formal_preview := preview_formal.render_block(preview_phases,preview_formal.rendered_until,2205,int(city.cfg["timing"]["sample_rate"]))
	check(preview == formal_preview and preview.size() == 2205 and model.capture_state() == before_preview and state == phase_before_preview and model.world.rng.snapshot() == original_rng,"private_retune_forecast_matches_formal_frozen_continuation_without_live_mutation")
	var answer_probe := int(reply["onset"])+PROBE
	var formal_pcm := _render_until(model,state,answer_probe+1)
	var copied_pcm := _render_until(continuation,continuation_state,answer_probe+1)
	var archive_pcm := _render_until(restored,restored_phases,answer_probe+1)
	check(formal_pcm == copied_pcm and formal_pcm == archive_pcm and state == continuation_state and state == restored_phases,"active_and_retiring_lifecycles_restore_exact_continuation_pcm_and_phases")
	var retained_reply := _row(model.audible_music_activity(answer_probe),str(new_reply.get("event_id","")))
	check(_same_event(retained_reply,new_reply) and int(retained_reply.get("generation",-1)) == 1 and str(retained_reply.get("source_event_id","")) == str(rendered_source["event_id"]) and model.audible_music_activity(answer_probe).filter(func(row: Dictionary) -> bool: return str(row.get("event_id","")) == str(new_reply.get("event_id",""))).size() == 1,"quick_a_b_a_keeps_exactly_one_b_reply_after_original_two_beats")
	check(model.world.rng.snapshot() == original_rng and model.world.buildings == original_world["buildings"] and model.world.phrase_index == 2 and model.synth.max_voice_count <= int(model.synth.score["render_voice_limit"]),"retunes_preserve_world_growth_rng_and_existing_render_voice_budget")
	details.merge({"seed":SEED,"start":start,"source":source,"old_reply":reply,"new_pitch":new_pitch,"retune":retune,"retuned_source":rendered_source,"new_reply":new_reply,"strength_ratio":strength_ratio,"partition_max_abs":partition_error,"back":back,"retained_tail":old_tail,"retained_reply":retained_reply,"max_render_voices":model.synth.max_voice_count})
	_test_partial_control(base,base_state,source,reply,new_pitch,"mute")
	_test_partial_control(base,base_state,source,reply,new_pitch,"solo")
	_test_response_off_on(base,base_state,source,reply)
	_test_natural_rest(base,base_state)
	_finish()
