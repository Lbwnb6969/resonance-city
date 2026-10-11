extends SceneTree
## Round 171: exercise the real default entry, planning shortcut and note
## controls with physical output. Never advance the live model by hand.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Archive = preload("res://scripts/world/city_archive.gd")
const MusicRules = preload("res://scripts/world/community_music_rules.gd")
const OUTPUT_DIRECTORY := "res://验证记录/round171_可听改编开局"
const LIVE_SECONDS := 1.2

var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var entries: Dictionary = {}
var clock_window: Dictionary = {}
var edit: Dictionary = {}
var saved_resume: Dictionary = {}
var screenshots: Dictionary = {}
var isolated_directory := ""
var isolated_save_path := ""

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(code: Key,control := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.ctrl_pressed = control
	demo._input(event)

func _button_with_text(parent: Node,text: String) -> Button:
	for child in parent.get_children():
		if child is Button and str(child.text) == text: return child
		var nested := _button_with_text(child,text)
		if nested != null: return nested
	return null

func _entry() -> Dictionary:
	return {"phrase":demo.model.world.phrase_index,"buildings":demo.model.world.buildings.size(),
		"rendered_frame":demo.clock.renderer.transport.rendered_frames,
		"audible_frame":demo.clock.renderer.transport.audible_frame,
		"model_frame":demo.model.rendered_until,"next_boundary":demo.model.next_boundary,
		"expression":demo.expression,"starter":demo.starter,
		"guide_open":demo.planning_guide.opened,"underruns":demo.clock.underruns}

func _new_entry_is_aligned(phrase_index: int) -> bool:
	var start := phrase_index*demo.model.phrase_frames
	return demo.clock.active and demo.clock.playback != null \
		and demo.model.world.phrase_index == phrase_index \
		and demo.model.next_boundary == start+demo.model.phrase_frames \
		and demo.clock.renderer.transport.rendered_frames == demo.model.rendered_until \
		and demo.clock.renderer.transport.rendered_frames >= start \
		and demo.clock.renderer.transport.rendered_frames < start+demo.model.phrase_frames \
		and demo.clock.renderer.transport.audible_frame >= float(start)

func _open_real_relocation_draft() -> bool:
	for site in demo.shown_world.public_sites:
		if not bool(site.get("active",false)): continue
		demo.context = {"kind":str(site["kind"]),"id":str(site["id"])}
		demo._verb("relocate_public")
		return demo.relocation_mode and demo.relocation_site_id == str(site["id"])
	return false

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = demo.get_viewport().get_texture().get_image()
	check(image != null and image.get_width() >= 800 and image.get_height() >= 600,name+"_window_draws")
	if image != null: screenshots[name] = image

func _menu_fits() -> bool:
	var rect := demo.menu.get_global_rect()
	return rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= demo.size.x and rect.end.y <= demo.size.y

func _finish() -> void:
	# PNG encoding happens after physical playback so evidence I/O cannot starve
	# the generator. Only this test's isolated checkpoint is removed.
	if is_instance_valid(demo):
		demo.clock.stop_output()
		demo.light_player.stop()
		demo.preview_player.stop()
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	var screenshot_paths: Dictionary = {}
	for name in screenshots:
		var path := OUTPUT_DIRECTORY+"/"+str(name)+".png"
		check(screenshots[name].save_png(path) == OK,str(name)+"_screenshot_saved")
		screenshot_paths[name] = path
	if not isolated_save_path.is_empty(): DirAccess.remove_absolute(isolated_save_path)
	if not isolated_directory.is_empty(): DirAccess.remove_absolute(isolated_directory)
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"entries":entries,"clock_window":clock_window,"edit":edit,"saved_resume":saved_resume,
		"screenshots":screenshot_paths,"display_backend":DisplayServer.get_name(),
		"audio_driver":AudioServer.get_driver_name(),"adapter":RenderingServer.get_video_adapter_name(),
		"engine":Engine.get_version_info()["string"],
		"scope":"Production default ready/P/theme shortcut/note button/R/V/N/Ctrl-S/F9; 1.2 seconds physical output and real next-beat edit. No hand settlement, full public comparison, human listening or long-term balance claim"}
	var file := FileAccess.open(OUTPUT_DIRECTORY+"/rework_demo_live.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(evidence,"\t")+"\n")
		file.close()
	else:
		check(false,"live_json_saved")
		evidence["passed"] = false
	print("ROUND171_REWORK_DEMO_LIVE ",JSON.stringify(evidence))
	if is_instance_valid(demo): demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	isolated_directory = "user://round171_rework_demo_live_%d" % Time.get_ticks_usec()
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	demo.archive_directory = isolated_directory
	root.add_child(demo)
	await process_frame
	await process_frame
	check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","real_window_and_physical_wasapi")
	entries["default"] = _entry()
	check(_new_entry_is_aligned(2) and demo.clock.renderer.transport.rendered_frames >= 705600,"default_ready_output_starts_at_absolute_phrase_two")
	check(not demo.planning_guide.opened and not demo.planning_guide.visible,"default_small_city_keeps_house_clicks_available")
	check(demo.model.world.rng.seed_hex == "2026100900000062" and demo.model.world.terrain.family == "river_valley","default_uses_production_seed_and_terrain")
	var opening_score: Dictionary = demo.model.audible_score()
	var theme: Dictionary = opening_score.get("theme",{})
	var theme_cid := str(theme.get("cid",""))
	var sources: Array = theme.get("source_ids",[])
	check(not theme_cid.is_empty() and bool(MusicRules.status(demo.shown_world,theme_cid).get("theme_eligible",false)) and not sources.is_empty(),"default_theme_is_already_really_mature")
	check(demo.model.decisions.is_empty() and demo.model.world.pending_actions.is_empty(),"default_opening_has_no_fabricated_player_decisions")
	await _capture("rework_opening_live")

	_key(KEY_P)
	await process_frame
	var guide = demo.planning_guide
	var rework_button: Button = guide.get("theme_rework_button") as Button
	check(guide.opened and rework_button != null and rework_button.is_visible_in_tree() and not rework_button.disabled,"production_p_opens_real_theme_rework_button")
	await _capture("rework_planning_entry_live")
	if rework_button == null or rework_button.disabled or sources.is_empty():
		await _finish()
		return
	var decision_count := demo.model.decisions.size()
	rework_button.emit_signal("pressed")
	var source_id := str(demo.selected_id)
	check(sources.has(source_id) and demo.shown_world.by_id.has(source_id) and demo.context.get("kind","") == "retune" and demo.context.get("id","") == source_id and demo.menu.visible,"theme_shortcut_opens_existing_real_source_note_menu")
	check(demo.model.decisions.size() == decision_count and demo.model.synth.focused_community.is_empty() and demo.model.world.pending_actions.is_empty(),"theme_shortcut_only_locates_without_choosing_music")
	if not demo.shown_world.by_id.has(source_id):
		await _finish()
		return
	await _capture("rework_note_menu_live")
	check(demo.menu.get_global_rect().position.x >= 0 and demo.menu.get_global_rect().position.y >= 0 and demo.menu.get_global_rect().end.x <= demo.size.x and demo.menu.get_global_rect().end.y <= demo.size.y,"real_source_note_menu_fits_window")
	var old_pitch := int(demo.shown_world.by_id[source_id]["current_midi"])
	var choice := 52
	var new_pitch := choice-12 if demo.low_octave.button_pressed else choice
	if new_pitch == old_pitch:
		choice = 55
		new_pitch = choice-12 if demo.low_octave.button_pressed else choice
	var note_button := _button_with_text(demo.menu,"暖和 · E" if choice == 52 else "开阔 · G")
	check(note_button != null and note_button.is_visible_in_tree(),"existing_production_pitch_button_is_available")
	if note_button == null:
		await _finish()
		return
	var requested_frame := demo.model.rendered_until
	note_button.emit_signal("pressed")
	var retune: Dictionary = {}
	if demo.model.decisions.size() > decision_count: retune = demo.model.decisions.back()
	var sound_frame := int(retune.get("sound_frame",-1))
	var expected_beat := (requested_frame/demo.model.beat_frames+1)*demo.model.beat_frames
	check(demo.model.decisions.size() == decision_count+1 and retune.get("operation",{}).get("kind","") == "retune" and retune.get("operation",{}).get("id","") == source_id and int(retune.get("operation",{}).get("midi",-1)) == new_pitch,"note_button_submits_one_real_source_retune")
	check(sound_frame == expected_beat and sound_frame < demo.model.next_boundary and int(retune.get("structure_frame",-1)) == demo.model.next_boundary,"first_edit_uses_existing_next_beat_then_next_phrase_contract")
	check(not demo.model.sound_overrides.has(source_id) and int(demo.model.world.by_id[source_id]["current_midi"]) == old_pitch,"pitch_does_not_apply_synchronously_on_click")
	var audible_before := float(demo.clock.renderer.transport.audible_frame)
	var skips_before := demo.clock.underruns
	var started := Time.get_ticks_msec()
	await create_timer(LIVE_SECONDS).timeout
	var audible_after := float(demo.clock.renderer.transport.audible_frame)
	var rate := demo.clock.renderer.transport.sample_rate
	clock_window = {"seconds":LIVE_SECONDS,"wall_ms":Time.get_ticks_msec()-started,"sample_rate":rate,
		"audible_before":audible_before,"audible_after":audible_after,
		"advanced_frames":audible_after-audible_before,"underruns_before":skips_before,"underruns_after":demo.clock.underruns}
	check(demo.clock.active and demo.clock.playback != null and audible_after-audible_before >= float(rate)*0.75,"physical_device_clock_advances_over_short_live_window")
	check(demo.clock.underruns == skips_before,"short_live_playback_adds_no_underruns")
	check(audible_after >= sound_frame and int(demo.model.audible_pitches().get(source_id,-1)) == new_pitch and demo.model.sound_trace.any(func(event: Dictionary) -> bool: return str(event.get("kind","")) == "retune" and str(event.get("id","")) == source_id and int(event.get("sound_frame",-1)) == sound_frame),"real_next_beat_event_reaches_audible_presentation")
	var after_theme: Dictionary = demo.model.audible_score().get("theme",{})
	var source_index: int = after_theme.get("source_ids",[]).find(source_id)
	check(source_index >= 0 and source_index < after_theme.get("notes",[]).size() and int(after_theme["notes"][source_index]) == new_pitch,"audible_theme_keeps_real_source_with_player_pitch")
	check(demo.model.world.phrase_index == 2 and int(demo.model.world.by_id[source_id]["current_midi"]) == old_pitch and demo.model.world.pending_actions.any(func(operation: Dictionary) -> bool: return str(operation.get("kind","")) == "retune" and str(operation.get("id","")) == source_id),"city_edit_stays_pending_until_next_real_phrase")
	edit = {"community_id":theme_cid,"source_id":source_id,"old_pitch":old_pitch,"new_pitch":new_pitch,
		"requested_frame":requested_frame,"sound_frame":sound_frame,"structure_frame":demo.model.next_boundary}

	_key(KEY_S,true)
	var saved: Dictionary = Archive.latest(isolated_directory)
	check(bool(saved.get("ok",false)),"production_ctrl_s_writes_isolated_checkpoint")
	if bool(saved.get("ok",false)):
		isolated_save_path = str(saved["path"])
		var city: Dictionary = saved["city"]
		var saved_frame := int(city["renderer"]["transport"]["rendered_frames"])
		check(_open_real_relocation_draft(),"real_public_facility_opens_unsubmitted_relocation_draft")
		_key(KEY_F9)
		entries["loaded"] = _entry()
		check(demo.model.world.snapshot() == city["model"]["world"] and demo.model.decisions == city["model"]["decisions"],"production_f9_restores_exact_saved_world_without_extra_warmup")
		check(not demo.relocation_mode and demo.relocation_site_id.is_empty() and demo.context.is_empty(),"load_clears_old_city_relocation_draft_and_context")
		check(demo.model.world.phrase_index == 2 and demo.model.next_boundary == int(city["model"]["next_boundary"]) and demo.clock.renderer.transport.audible_frame >= saved_frame and demo.clock.renderer.transport.rendered_frames >= saved_frame and demo.clock.renderer.transport.rendered_frames < saved_frame+rate,"loaded_audio_continues_saved_cursor_instead_of_restarting")
		check(int(demo.model.audible_pitches().get(source_id,-1)) == new_pitch and demo.model.world.pending_actions == city["model"]["world"].get("pending_actions",[]),"loaded_city_keeps_audible_tuning_and_real_pending_growth")
		saved_resume = {"saved_rendered_frame":saved_frame,"loaded_rendered_frame":demo.clock.renderer.transport.rendered_frames,"saved_phrase":city["model"]["world"]["phrase_index"],"loaded_phrase":demo.model.world.phrase_index}
		check(_open_real_relocation_draft(),"restored_public_facility_opens_real_relocation_draft")
		_key(KEY_N)
		entries["empty"] = _entry()
		check(_new_entry_is_aligned(0) and demo.model.world.buildings.is_empty() and not demo.starter and demo.planning_guide.opened,"production_n_keeps_empty_world_at_frame_zero_with_planning_entry")
		check(not demo.relocation_mode and demo.relocation_site_id.is_empty() and demo.context.is_empty(),"new_city_clears_old_city_relocation_draft_and_context")

	_key(KEY_R)
	entries["bright_reset"] = _entry()
	check(_new_entry_is_aligned(2) and demo.expression == "bright" and demo.starter and not demo.planning_guide.opened and demo.model.decisions.is_empty(),"production_r_restarts_mature_bright_at_absolute_phrase_two")
	_key(KEY_V)
	entries["deep_reset"] = _entry()
	check(_new_entry_is_aligned(2) and demo.expression == "deep" and demo.starter and not demo.planning_guide.opened and demo.model.decisions.is_empty(),"production_v_restarts_mature_deep_at_absolute_phrase_two")
	var deep_theme: Dictionary = demo.model.audible_theme()
	check(not deep_theme.is_empty() and deep_theme.get("expression","") == "deep" and bool(MusicRules.status(demo.shown_world,str(deep_theme.get("cid",""))).get("theme_eligible",false)),"deep_reset_keeps_real_mature_theme_and_authored_low_expression")
	check(demo.clock.underruns == 0,"new_entry_output_is_primed_without_skips")
	_key(KEY_P)
	demo.planning_guide.theme_rework_button.emit_signal("pressed")
	demo.clock.stop_output()
	await process_frame
	await process_frame
	var scroll: ScrollContainer = demo.menu.get_meta("scroll")
	check(_menu_fits() and not scroll.get_v_scroll_bar().visible,"compact_house_menu_needs_no_vertical_scroll")
	for section: String in ["details","public","city"]:
		var toggle: Button = demo.menu.get_meta(section+"_toggle")
		toggle.button_pressed = true
		await process_frame
		await process_frame
		check(_menu_fits(),section+"_expanded_menu_stays_inside_window")
	check(scroll.get_v_scroll_bar().visible,"expanded_tools_use_bounded_vertical_scroll")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	await process_frame
	var terrain_button := _button_with_text(demo.menu,"切换地形族 · Y")
	check(terrain_button != null and demo.menu.get_global_rect().encloses(terrain_button.get_global_rect()),"scroll_reaches_last_preserved_city_command")
	await _capture("rework_expanded_tools_live")
	root.content_scale_size = Vector2i(800,600)
	root.size = Vector2i(800,600)
	await process_frame
	await process_frame
	demo._show_context_menu()
	await process_frame
	await process_frame
	check(demo.size.x <= 800 and demo.size.y <= 600 and _menu_fits(),"small_window_keeps_house_note_menu_inside_bounds")
	var small_note := _button_with_text(demo.menu,"暖和 · E")
	check(small_note != null and demo.menu.get_global_rect().encloses(small_note.get_global_rect()),"small_window_keeps_primary_note_button_visible")
	await _capture("rework_small_window_live")
	await _finish()
