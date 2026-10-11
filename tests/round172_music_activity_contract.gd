extends SceneTree
## Round 172: activity is a read-only projection of real rendered Lead/Reply
## events, queried on the audible sample clock. It neither authors music nor
## changes PCM, random streams, archives or private preview state.
## On/off PCM is exact for identical chunks. Across chunks the existing pad
## optimization has float rounding; collection must preserve that baseline.

const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const RiverResponse = preload("res://scripts/world/river_call_response.gd")
const SEED := "2026100900000062"
const EVIDENCE_PATH := "res://验证记录/round172_真实演奏来源/music_activity_contract.json"
const PROBE_OFFSET := 256
const IDENTITY_FIELDS := ["event_id","source_event_id","source_id","receiver_id","generation","onset","end_frame","pitch","cid"]

var checks: Dictionary = {}
var failures: Array[String] = []
var details: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"details":details,
		"scope":"Natural production-seed rework starter and real Lead/Reply schedule; collection on/off PCM is exact for identical chunks, measured existing cross-chunk float rounding is preserved without claiming cross-chunk byte equality. Offline contract only, no device or human listening claim"}
	DirAccess.make_dir_recursive_absolute(EVIDENCE_PATH.get_base_dir())
	var file := FileAccess.open(EVIDENCE_PATH,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"\t")+"\n")
		file.close()
	else:
		check(false,"contract_evidence_writes")
		report["passed"] = false
	print("ROUND172_MUSIC_ACTIVITY_CONTRACT ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func _model(city: World,enabled: bool,start: int) -> Model:
	var model := Model.new(city.fork())
	model.rendered_until = start
	if enabled: model.enable_music_activity()
	return model

func _schedule(model: Model,answer: bool,start: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	for node: Dictionary in model.synth.musical_nodes.values():
		if not bool(node.get("active",false)) or bool(node.get("answer",false)) != answer: continue
		for event: Dictionary in model.synth.musical_events(node,start,model.phrase_frames,rate):
			if int(event["onset"]) < start or not model.world.by_id.has(str(event.get("source_id",""))): continue
			if answer and not model.world.by_id.has(str(event.get("receiver_id",""))): continue
			var expected := event.duplicate(true)
			expected["end_frame"] = int(event["onset"])+model.synth._event_wave(int(event["pitch"]),str(node["pattern"]["expression"]),rate).size()
			expected["cid"] = str(node["part"]["cid"])
			result.append(expected)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if int(a["onset"]) != int(b["onset"]): return int(a["onset"]) < int(b["onset"])
		return str(a["event_id"]) < str(b["event_id"]))
	return result

func _render_until(model: Model,state: Dictionary,finish: int,chunk: int) -> PackedVector2Array:
	var pcm := PackedVector2Array()
	var rate := int(model.world.cfg["timing"]["sample_rate"])
	while model.rendered_until < finish:
		var at := model.rendered_until
		pcm.append_array(model.render_block(state,at,mini(chunk,finish-at),rate))
	return pcm

func _pcm_difference(a: PackedVector2Array,b: PackedVector2Array,start: int) -> Dictionary:
	var first_frame := -1
	var maximum := 0.0
	for index in range(mini(a.size(),b.size())):
		if a[index] != b[index] and first_frame < 0: first_frame = start+index
		maximum = maxf(maximum,maxf(absf(a[index].x-b[index].x),absf(a[index].y-b[index].y)))
	return {"equal":a == b,"max_abs":maximum,"first_difference_frame":first_frame,"a_frames":a.size(),"b_frames":b.size()}

func _row(rows: Array,event_id: String) -> Dictionary:
	for raw in rows:
		if raw is Dictionary and str(raw.get("event_id","")) == event_id: return raw
	return {}

func _identities(rows: Array) -> Array:
	var result: Array = []
	for raw in rows:
		var entry: Dictionary = {}
		for field in IDENTITY_FIELDS: entry[field] = raw.get(field,null)
		result.append(entry)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["event_id"]) < str(b["event_id"]))
	return result

func _matches(row: Dictionary,event: Dictionary) -> bool:
	if row.is_empty() or float(row.get("strength",0.0)) <= 0.000001: return false
	for field in IDENTITY_FIELDS:
		if row.get(field,null) != event.get(field,null): return false
	return true

func _real_rows(rows: Array,city: World,frame: int) -> bool:
	for row: Dictionary in rows:
		for field in IDENTITY_FIELDS:
			if not row.has(field): return false
		if not row.has("strength") or not row.has("render_start") or not row.has("render_end"): return false
		if not city.by_id.has(str(row["source_id"])) or int(row["generation"]) not in [0,1]: return false
		if int(row["generation"]) == 1 and not city.by_id.has(str(row["receiver_id"])): return false
		if int(row["onset"]) > frame or int(row["end_frame"]) <= frame or int(row["render_start"]) > frame or int(row["render_end"]) <= frame or float(row["strength"]) <= 0.000001: return false
	return true

func _run() -> void:
	var city := World.new(SEED,true,"river_valley")
	city.build_rework_starter("bright")
	var start := city.phrase_index*int(city.cfg["timing"]["phrase_frames"])
	var original_rng := city.rng.snapshot().duplicate(true)
	var enabled := _model(city,false,start)
	var disabled := _model(city,false,start)
	var split := _model(city,true,start)
	var disabled_split := _model(city,false,start)
	var untouched := enabled.capture_state()
	enabled.enable_music_activity()
	check(enabled.capture_state() == untouched and enabled.world.rng.snapshot() == original_rng,"enabling_activity_adds_no_runtime_schema_music_decision_or_random_draw")
	var leads := _schedule(enabled,false,start)
	var replies := _schedule(enabled,true,start)
	check(city.phrase_index == 2 and not leads.is_empty() and not replies.is_empty(),"natural_rework_starter_has_real_theme_and_paired_response_events")
	if leads.is_empty() or replies.is_empty():
		_finish()
		return
	var lead: Dictionary = leads[0]
	var first_probe := int(lead["onset"])+PROBE_OFFSET
	var fade_frames := roundi(float(enabled.synth.score["control_fade_beats"])*enabled.beat_frames)
	var control_frame := (first_probe/enabled.beat_frames+1)*enabled.beat_frames
	var reply: Dictionary = {}
	for event: Dictionary in replies:
		if int(event["source_onset"]) >= control_frame+fade_frames and int(event["onset"])+PROBE_OFFSET < enabled.next_boundary:
			reply = event
			break
	check(not reply.is_empty(),"real_paired_event_exists_after_control_fade_within_current_phrase")
	if reply.is_empty():
		details["reply_schedule"] = replies
		_finish()
		return
	var source: Dictionary = _row(leads,str(reply["source_event_id"]))
	var pairs := RiverResponse.pairs(city)
	check(not source.is_empty() and int(reply["generation"]) == 1 and int(reply["onset"])-int(source["onset"]) == enabled.beat_frames*2 and pairs.any(func(pair: Dictionary) -> bool:
		return (str(pair["a"]) == str(reply["source_id"]) and str(pair["b"]) == str(reply["receiver_id"])) or (str(pair["b"]) == str(reply["source_id"]) and str(pair["a"]) == str(reply["receiver_id"]))
	),"response_identity_and_two_beat_delay_come_from_real_cross_bank_pair")
	if source.is_empty():
		_finish()
		return
	var source_probe := int(source["onset"])+PROBE_OFFSET
	var reply_probe := int(reply["onset"])+PROBE_OFFSET
	var state: Dictionary = {}
	var disabled_state: Dictionary = {}
	var split_state: Dictionary = {}
	var disabled_split_state: Dictionary = {}
	var pcm := _render_until(enabled,state,first_probe+1,1024)
	var disabled_pcm := _render_until(disabled,disabled_state,first_probe+1,1024)
	var split_pcm := _render_until(split,split_state,first_probe+1,777)
	var disabled_split_pcm := _render_until(disabled_split,disabled_split_state,first_probe+1,777)
	var first_rows: Array = enabled.audible_music_activity(first_probe)
	check(enabled.audible_music_activity(int(lead["onset"])-1).is_empty() and enabled.audible_music_activity(first_probe+1).is_empty(),"rendered_activity_never_precedes_onset_or_reports_unrendered_future_sample")
	check(_matches(_row(first_rows,str(lead["event_id"])),lead) and _real_rows(first_rows,city,first_probe),"lead_activity_is_actual_rendered_source_pitch_and_wave_duration")
	check(_identities(first_rows) == _identities(split.audible_music_activity(first_probe)),"first_note_identity_is_independent_of_render_chunk_partition")
	var captured := enabled.capture_state()
	var phase_copy := state.duplicate(true)
	var rows_copy := first_rows.duplicate(true)
	if not first_rows.is_empty(): first_rows[0]["source_id"] = "external-query-edit"
	check(enabled.audible_music_activity(first_probe) == rows_copy and enabled.capture_state() == captured and state == phase_copy and enabled.world.rng.snapshot() == original_rng,"activity_queries_are_read_only_and_return_independent_rows")
	check(captured == disabled.capture_state() and disabled.audible_music_activity(first_probe).is_empty(),"enabled_and_disabled_capture_the_same_existing_save_state")
	var frozen := enabled.freeze()
	var restored := Model.from_state(captured)
	check(frozen.audible_music_activity(first_probe).is_empty() and restored.audible_music_activity(first_probe).is_empty(),"freeze_and_restore_do_not_inherit_old_activity_or_capture_switch")
	frozen.enable_music_activity()
	restored.enable_music_activity()
	check(frozen.audible_music_activity(first_probe).is_empty() and restored.audible_music_activity(first_probe).is_empty(),"reenabling_private_or_restored_model_cannot_reveal_unrendered_old_activity")

	# Controls are genuine next-beat submissions. Solo keeps the receiving bank
	# at the actual background gain; mute must remove it after the actual fade.
	var muted := _model(city,true,start)
	var solo := _model(city,true,start)
	var muted_state: Dictionary = {}
	var solo_state: Dictionary = {}
	_render_until(muted,muted_state,first_probe+1,1024)
	_render_until(solo,solo_state,first_probe+1,1024)
	var source_cid := str(city.by_id[str(source["source_id"])]["community_id"])
	var receiver_cid := str(city.by_id[str(reply["receiver_id"])]["community_id"])
	var mute_result := muted.submit({"kind":"mute","community":receiver_cid,"enabled":true})
	var solo_result := solo.submit({"kind":"solo","community":source_cid})
	check(bool(mute_result.get("accepted",false)) and bool(solo_result.get("accepted",false)) and int(mute_result.get("sound_frame",-1)) == control_frame and int(solo_result.get("sound_frame",-1)) == control_frame,"mute_and_solo_activity_changes_use_production_next_beat_controls")
	pcm.append_array(_render_until(enabled,state,source_probe+1,1024))
	disabled_pcm.append_array(_render_until(disabled,disabled_state,source_probe+1,1024))
	split_pcm.append_array(_render_until(split,split_state,source_probe+1,777))
	disabled_split_pcm.append_array(_render_until(disabled_split,disabled_split_state,source_probe+1,777))
	_render_until(muted,muted_state,source_probe+1,1024)
	_render_until(solo,solo_state,source_probe+1,1024)
	check(_matches(_row(enabled.audible_music_activity(source_probe),str(source["event_id"])),source) and _matches(_row(muted.audible_music_activity(source_probe),str(source["event_id"])),source) and _matches(_row(solo.audible_music_activity(source_probe),str(source["event_id"])),source),"receiver_controls_keep_the_real_source_theme_activity")
	pcm.append_array(_render_until(enabled,state,reply_probe+1,1024))
	disabled_pcm.append_array(_render_until(disabled,disabled_state,reply_probe+1,1024))
	split_pcm.append_array(_render_until(split,split_state,reply_probe+1,777))
	disabled_split_pcm.append_array(_render_until(disabled_split,disabled_split_state,reply_probe+1,777))
	_render_until(muted,muted_state,reply_probe+1,1024)
	_render_until(solo,solo_state,reply_probe+1,1024)
	var reply_rows: Array = enabled.audible_music_activity(reply_probe)
	var real_reply := _row(reply_rows,str(reply["event_id"]))
	var quiet_reply := _row(solo.audible_music_activity(reply_probe),str(reply["event_id"]))
	check(_row(enabled.audible_music_activity(int(reply["onset"])-1),str(reply["event_id"])).is_empty(),"prefetched_reply_activity_does_not_run_ahead_of_its_delayed_onset")
	check(_matches(real_reply,reply) and _real_rows(reply_rows,city,reply_probe),"audible_reply_activity_keeps_real_source_receiver_pitch_and_one_generation")
	check(_row(muted.audible_music_activity(reply_probe),str(reply["event_id"])).is_empty() and not muted.audible_music_activity(reply_probe).any(func(row: Dictionary) -> bool: return str(row.get("cid","")) == receiver_cid),"muted_receiving_bank_has_no_false_activity_after_fade")
	var background_gain := float(enabled.synth.score["background_gain"])
	var strength_ratio := float(quiet_reply.get("strength",0.0))/maxf(float(real_reply.get("strength",0.0)),0.000000001)
	check(_matches(quiet_reply,reply) and absf(strength_ratio-background_gain) < 0.00001,"solo_preserves_only_the_actual_reduced_background_reply_strength")
	check(pcm == disabled_pcm and state == disabled_state,"enabling_activity_collection_keeps_pcm_and_all_render_phases_exact")
	var enabled_identities := _identities(reply_rows)
	var split_identities := _identities(split.audible_music_activity(reply_probe))
	check(enabled_identities == split_identities,"different_chunk_partition_keeps_activity_identity")
	check(split_pcm == disabled_split_pcm and split_state == disabled_split_state,"enabled_vs_disabled_collection_keeps_exact_pcm_for_777_chunks")
	var enabled_chunk_difference := _pcm_difference(pcm,split_pcm,start)
	var disabled_chunk_difference := _pcm_difference(disabled_pcm,disabled_split_pcm,start)
	check(enabled_chunk_difference == disabled_chunk_difference and state == split_state and disabled_state == disabled_split_state,"activity_collection_preserves_existing_chunk_rounding_and_exact_phases")
	check(enabled.world.snapshot() == city.snapshot() and enabled.world.rng.snapshot() == original_rng and enabled.capture_state() == disabled.capture_state(),"activity_render_window_preserves_world_rng_and_existing_archive_schema")
	var window_start := maxi(0,enabled.rendered_until-roundi(float(city.cfg["timing"]["sample_rate"])*4.0))
	check(enabled.music_activity.segments.size() <= 512 and enabled.music_activity.window_start == window_start and enabled.audible_music_activity(window_start-1).is_empty(),"runtime_activity_is_bounded_to_four_seconds_and_512_segments")
	details = {"seed":SEED,"phrase":city.phrase_index,"start_frame":start,"sample_rate":city.cfg["timing"]["sample_rate"],
		"rendered_frames":pcm.size(),"first_lead":lead,"paired_lead":source,"paired_reply":reply,
		"control_frame":control_frame,"fade_frames":fade_frames,"source_probe":source_probe,"reply_probe":reply_probe,
		"source_community":source_cid,"receiver_community":receiver_cid,"solo_strength_ratio":strength_ratio,"background_gain":background_gain,
		"enabled_chunk_pcm_difference":enabled_chunk_difference,
		"disabled_chunk_pcm_difference":disabled_chunk_difference,
		"collection_1024_pcm_difference":_pcm_difference(pcm,disabled_pcm,start),
		"collection_777_pcm_difference":_pcm_difference(split_pcm,disabled_split_pcm,start),
		"enabled_chunk_activity_identity":enabled_identities,"split_chunk_activity_identity":split_identities,
		"native_mixer_enabled":[enabled.synth.native_enabled,disabled.synth.native_enabled,split.synth.native_enabled,disabled_split.synth.native_enabled],
		"native_mixer_available":[enabled.synth.native_mixer != null,disabled.synth.native_mixer != null,split.synth.native_mixer != null,disabled_split.synth.native_mixer != null],
		"chunk_render_phases_equal":state == split_state,"disabled_chunk_render_phases_equal":disabled_state == disabled_split_state}
	_finish()
