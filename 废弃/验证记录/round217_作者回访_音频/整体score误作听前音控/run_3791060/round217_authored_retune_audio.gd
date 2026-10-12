extends SceneTree
## One real older author, production card button, and same-source full PCM.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const Work = preload("res://scripts/world/first_authored_work.gd")
const PlayerExpression = preload("res://scripts/world/player_expression.gd")
const Renderer = preload("res://scripts/audio/sample_renderer.gd")
const OUTPUT_DIR := "res://验证记录/round217_作者回访_音频"
const SEED := "2026100900000062"
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}
var demo: ContinuousValleyDemo

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _finish() -> void:
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"One genuine older deep root and a later weave family. Production card button versus same-source formal retune; full float32 stereo PCM, queued/render-ahead/audible labels, pure UI and original listening controls. Dummy only, no GPU, device or human listening claim."}
	var attempt := OUTPUT_DIR+"/run_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(attempt))
	FileAccess.open(attempt+"/contract.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	if failures.is_empty(): FileAccess.open(OUTPUT_DIR+"/contract.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND217_AUTHORED_RETUNE_AUDIO ",checks.size()-failures.size(),"/",checks.size()," ",attempt+"/contract.json")
	if is_instance_valid(demo):
		demo._cancel_preview_playback()
		demo.light_player.stop()
		demo.clock.stop_output()
		demo.model.close_background_settlement()
		demo.queue_free()
		await process_frame
	quit(0 if failures.is_empty() else 1)

func _position(city: ContinuousWorld,cid: String) -> Array:
	for candidate: Dictionary in First.opportunities(city)["seed_candidates"]:
		if str(candidate["community_id"]) == cid: return candidate["position"].duplicate()
	return []

func _render_to(renderer: SampleRenderer,end: int) -> PackedVector2Array:
	var pcm := PackedVector2Array()
	while renderer.transport.rendered_frames < end:
		pcm.append_array(renderer.render(mini(512,end-renderer.transport.rendered_frames)))
	return pcm

func _pitch_text(pitch: int) -> String:
	return demo.note_name(pitch)+str(pitch/12-1)

func _labels() -> Dictionary:
	return {"heard":demo.authored_house_card.heard_label.text,"pending":demo.authored_house_card.pending_label.text,
		"pending_visible":demo.authored_house_card.pending_label.visible,
		"audible_frame":demo.clock.renderer.transport.audible_frame,"rendered_frame":demo.clock.renderer.transport.rendered_frames,
		"audible_pitches":demo.model.audible_pitches().duplicate(true)}

func _labels_are(current: int,pending: int = -1) -> bool:
	var values := _labels()
	var heard := str(values["heard"]).replace(" ","")
	var next := str(values["pending"]).replace(" ","")
	return heard.contains(_pitch_text(current)) and (bool(values["pending_visible"]) and next.contains(_pitch_text(pending)) if pending >= 0 else not bool(values["pending_visible"]) or next.is_empty())

func _present(frame: int) -> void:
	demo.clock.renderer.transport.audible_frame = float(frame)
	demo.shown_world = demo.model.presentation_world(float(frame))
	demo._sync_authored_house_card()

func _hash(pcm: PackedVector2Array) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(pcm.to_byte_array())
	return digest.finish().hex_encode()

func _max_difference(a: PackedVector2Array,b: PackedVector2Array) -> float:
	if a.size() != b.size(): return INF
	var error := 0.0
	for index in range(a.size()): error = maxf(error,maxf(absf(a[index].x-b[index].x),absf(a[index].y-b[index].y)))
	return error

func _run() -> void:
	check(AudioServer.get_driver_name() == "Dummy","dummy_driver_only")
	if not checks["dummy_driver_only"]: await _finish(); return
	root.size = Vector2i(800,600)
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	var city := World.new(SEED,true,"river_valley")
	city.build_first_composition_starter()
	var original_count := city.buildings.size()
	var phrase := int(city.cfg["timing"]["phrase_frames"])
	var first_position := _position(city,"west-1")
	if first_position.is_empty(): check(false,"actual_first_candidate_exists"); await _finish(); return
	var first := city.request(PlayerExpression.operation("deep",first_position),phrase)
	city.settle(phrase)
	var older := Work.state(city,{})
	var second_position := _position(city,"east-2")
	if second_position.is_empty(): check(false,"actual_second_candidate_exists"); await _finish(); return
	var second := city.request(PlayerExpression.operation("weave",second_position),phrase*2)
	city.settle(phrase*2)
	var latest := Work.state(city,{})
	var older_id := str(older.get("root_id",""))
	var newer_id := str(latest.get("root_id",""))
	check(original_count == 24 and bool(first.get("accepted",false)) and bool(second.get("accepted",false)) and not older_id.is_empty() and newer_id != older_id and city.by_id[older_id]["player_expression"] and city.by_id[newer_id]["player_expression"] and older["expression"] == "deep" and latest["expression"] == "weave","real_transactions_keep_two_distinct_authored_families")
	if older_id.is_empty() or newer_id == older_id: await _finish(); return
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	demo.clock.renderer.source = demo.model._mix_frame
	var renderer := demo.clock.renderer
	_render_to(renderer,renderer.transport.rendered_frames+512)
	# Establish real non-default heard controls, rather than assigning synth fields.
	demo.model.submit({"kind":"solo","community":older["community_id"]})
	demo.model.submit({"kind":"focus","community":older["community_id"]})
	demo.model.submit({"kind":"mute","community":latest["community_id"],"enabled":true})
	var controls_end := int(demo.model.sound_events[-1]["sound_frame"])+demo.model.beat_frames*2+1
	_render_to(renderer,controls_end)
	renderer.transport.audible_frame = float(controls_end)
	demo.shown_world = demo.model.presentation_world(float(controls_end))
	var charter := demo.model.submit({"kind":"charter","plan_id":"compact","community_ids":[latest["community_id"]]})
	var independent_pending: Array = demo.model.world.pending_actions.duplicate(true)
	var before_open := demo.model.capture_state()
	var before_phases := renderer.state.duplicate(true)
	var before_score := demo.model.audible_score()
	demo._open_authored_root(older_id)
	demo._sync_authored_house_card()
	check(bool(charter.get("accepted",false)) and demo._compact_authored_card() and demo.selected_id == older_id and demo.context.get("id","") == older_id and demo.model.capture_state() == before_open and renderer.state == before_phases and demo.model.audible_score() == before_score,"opening_older_author_card_keeps_model_phases_pending_and_heard_listening_controls")
	var old_pitch := int(demo.model.audible_pitches().get(older_id,city.by_id[older_id]["current_midi"]))
	var target := demo._note_pitch(52)
	check(old_pitch == 36 and target == 40 and demo.authored_house_card.note_buttons.keys().has(48) and demo.authored_house_card.note_buttons.keys().has(50) and demo.authored_house_card.note_buttons.keys().has(52) and demo.authored_house_card.note_buttons.keys().has(55) and demo.authored_house_card.note_buttons.keys().has(57) and _labels_are(old_pitch),"five_real_note_buttons_use_older_authors_current_c2_register")
	evidence["before"] = _labels()
	var formal := demo.model.freeze()
	var baseline := demo.model.freeze()
	var formal_renderer := Renderer.new(renderer.transport.sample_rate)
	formal_renderer.restore(renderer.snapshot())
	formal_renderer.source = formal._mix_frame
	var baseline_renderer := Renderer.new(renderer.transport.sample_rate)
	baseline_renderer.restore(renderer.snapshot())
	baseline_renderer.source = baseline._mix_frame
	var operation := demo.context.duplicate(true)
	operation["midi"] = target
	operation["expression"] = demo.expression
	var formal_request := formal.submit(operation)
	var world_before := demo.model.world.snapshot()
	demo.authored_house_card.note_buttons[52].emit_signal("pressed")
	demo.light_player.stop()
	demo._sync_authored_house_card()
	var actual_decision: Dictionary = demo.model.decisions[-1]
	var sound_frame := int(formal_request.get("sound_frame",-1))
	check(bool(formal_request.get("accepted",false)) and sound_frame > renderer.transport.rendered_frames and sound_frame % demo.model.beat_frames == 0 and actual_decision["operation"] == operation and int(actual_decision["sound_frame"]) == sound_frame and int(actual_decision["structure_frame"]) == demo.model.next_boundary and demo.model.world.pending_actions.filter(func(item: Dictionary) -> bool: return str(item.get("kind","")) != "retune") == independent_pending,"production_button_submits_same_next_writable_beat_operation_and_keeps_independent_charter")
	check(demo.model.world.buildings == world_before["buildings"] and demo.model.world.families == world_before["families"] and demo.model.world.rng.snapshot() == world_before["rng"] and demo.model.audible_score() == before_score and _labels_are(old_pitch,target),"queued_retune_keeps_heard_pitch_world_family_rng_controls_and_shows_real_pending_note")
	evidence["queued"] = _labels()
	var actual_pcm := _render_to(renderer,sound_frame)
	var formal_pcm := _render_to(formal_renderer,sound_frame)
	var original_pcm := _render_to(baseline_renderer,sound_frame)
	check(actual_pcm == formal_pcm and actual_pcm == original_pcm,"full_prebeat_pcm_matches_both_formal_and_unchanged_source")
	var after_count := 2048
	var actual_after := _render_to(renderer,sound_frame+after_count)
	var formal_after := _render_to(formal_renderer,sound_frame+after_count)
	var original_after := _render_to(baseline_renderer,sound_frame+after_count)
	actual_pcm.append_array(actual_after)
	formal_pcm.append_array(formal_after)
	var audible_before := sound_frame-1
	_present(audible_before)
	var trace_has_future := demo.model.sound_trace.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "retune" and str(event.get("id","")) == older_id and int(event.get("sound_frame",-1)) == sound_frame)
	check(trace_has_future and not demo.model.sound_events.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "retune" and str(event.get("id","")) == older_id) and int(demo.model.audible_pitches().get(older_id,old_pitch)) == old_pitch and _labels_are(old_pitch,target),"render_ahead_consumed_retune_still_shows_old_heard_note_and_future_trace_note")
	evidence["render_ahead_before_heard"] = _labels()
	var before_sync := demo.model.capture_state()
	var phases_before_sync := renderer.state.duplicate(true)
	for index in range(5): demo._sync_authored_house_card()
	check(demo.model.capture_state() == before_sync and renderer.state == phases_before_sync,"repeated_ui_sync_is_read_only_for_complete_world_rng_pending_audio_and_phase")
	_present(sound_frame+512)
	check(int(demo.model.audible_pitches().get(older_id,-1)) == target and int(demo.shown_world.by_id[older_id]["current_midi"]) == old_pitch and _labels_are(target) and demo.model.audible_score() == before_score and demo.model.world.families == world_before["families"] and int(demo.model.world.by_id[newer_id]["current_midi"]) == 60,"audible_beat_reveals_new_note_without_early_world_pitch_or_other_author_listening_changes")
	evidence["after_heard"] = _labels()
	var formal_error := _max_difference(actual_pcm,formal_pcm)
	var changed_error := _max_difference(actual_after,original_after)
	check(actual_pcm.to_byte_array() == formal_pcm.to_byte_array() and actual_after.size() == after_count and changed_error > 0.0000001,"complete_same_source_stereo_pcm_is_formal_exact_and_really_changes_after_retune")
	evidence.merge({"seed":SEED,"older_root":older_id,"later_root":newer_id,"older_family":older["family_id"],"later_family":latest["family_id"],
		"sound_frame":sound_frame,"structure_frame":formal_request.get("frame",-1),"operation":operation,"formal_request":formal_request,
		"sample_rate":renderer.transport.sample_rate,"pcm_frames":actual_pcm.size(),"postbeat_frames":after_count,"actual_float32_sha256":_hash(actual_pcm),"formal_float32_sha256":_hash(formal_pcm),
		"formal_max_abs_error":formal_error,"unchanged_source_postbeat_max_abs_difference":changed_error,"heard_controls_before":before_score,"independent_pending":independent_pending})
	await _finish()
