extends SceneTree
## Round 175: authored park/civic sites, actual rendered music rows and
## their map marks at a physical output cursor. The live world is never
## settled, rendered or moved forward by this script.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const OUTPUT_DIRECTORY := "res://验证记录/round175_公共空间真实窗口"
const CAPTURE_ALPHA := 0.10
const COMMUNITY_ID := "west-1"

var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var screenshots: Dictionary = {}
var observations: Dictionary = {}
var operations: Dictionary = {}
var authored_sites: Dictionary = {}
var observed_events: Dictionary = {}
var output_window: Dictionary = {}
var start_frame := 0.0
var start_skips := 0
var setup_only := false
var wait_boundaries := false

func _initialize() -> void:
	setup_only = "--setup-only" in OS.get_cmdline_user_args()
	wait_boundaries = not setup_only or "--wait-boundaries" in OS.get_cmdline_user_args()
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	demo._input(event)

func _button_with_text(parent: Node,text: String,contains := false) -> Button:
	for child in parent.get_children():
		if child is Button and ((contains and str(child.text).contains(text)) or (not contains and str(child.text) == text)):
			return child
		var nested := _button_with_text(child,text,contains)
		if nested != null: return nested
	return null

func _plain(value: Variant) -> Variant:
	if value is Vector2: return [value.x,value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for field in value: result[str(field)] = _plain(value[field])
		return result
	if value is Array:
		var result: Array = []
		for entry in value: result.append(_plain(entry))
		return result
	return value

func _marks() -> Array:
	return demo.public_space_activity_layer.get("marks")

func _actual_rows(frame: float) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append_array(demo.model.audible_music_activity(frame))
	rows.append_array(demo.model.audible_public_activity(frame))
	return rows

func _snapshot() -> Dictionary:
	var af := float(demo.public_space_activity_layer.get("audible_frame"))
	return {"audible_frame":af,"device_frame":demo.clock.renderer.transport.audible_frame,
		"rendered_frame":demo.model.rendered_until,"actual_rows":_actual_rows(af),
		"marks":_plain(_marks()),"layer_visible":demo.public_space_activity_layer.visible,
		"phrase":demo.shown_world.phrase_index,"public_sites":_plain(demo.shown_world.public_sites),
		"underruns":demo.clock.underruns}

func _site(site_id: String) -> Dictionary:
	for site in demo.shown_world.public_sites:
		if str(site.get("id","")) == site_id and bool(site.get("active",false)): return site
	return {}

func _marks_match_actual() -> bool:
	var af := float(demo.public_space_activity_layer.get("audible_frame"))
	if af > float(demo.clock.renderer.transport.audible_frame): return false
	var actual: Dictionary = {}
	for row in _actual_rows(af): actual[str(row["event_id"])] = row
	for mark: Dictionary in _marks():
		var event_id := str(mark.get("event_id",""))
		if not actual.has(event_id): return false
		var row: Dictionary = actual[event_id]
		var site_id := str(mark.get("site_id",""))
		var site := _site(site_id)
		var index: int = row.get("public_site_ids",[]).find(site_id)
		if site.is_empty() or index < 0: return false
		if index >= row.get("public_site_kinds",[]).size(): return false
		if str(mark["site_kind"]) != str(site["kind"]) or str(mark["site_kind"]) != str(row["public_site_kinds"][index]): return false
		if int(site.get("frame",0)) > af: return false
		if int(mark["pitch"]) != int(row["pitch"]) or int(mark["onset"]) != int(row["onset"]): return false
		if af < int(row["onset"]) or af >= int(row["end_frame"]): return false
		if af < int(row["render_start"]) or af >= int(row["render_end"]): return false
		if af-float(row["onset"]) >= float(demo.clock.renderer.transport.sample_rate)*0.55: return false
		var position: Array = site["position"]
		var expected := demo.point(Vector2(float(position[0]),float(position[1])))
		if (mark["position"] as Vector2).distance_to(expected) > 0.01: return false
	return true

func _candidate(excluded: Array = []) -> Dictionary:
	for lot in demo.model.world.lots:
		if not str(lot.get("occupant","" )).is_empty() or str(lot.get("community_id","")) != COMMUNITY_ID: continue
		var at := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var near_previous := false
		for previous: Vector2 in excluded:
			if at.distance_to(previous) < 0.01: near_previous = true
		if near_previous: continue
		var candidate: Dictionary = demo.model.world.planning_candidate(at)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(demo.model.world,candidate).is_empty(): return candidate
	return {}

func _queue_public(kind: String,candidate: Dictionary) -> Dictionary:
	if demo.planning_guide.opened: _key(KEY_P)
	_key(KEY_P)
	var guide = demo.planning_guide
	var plan_button := _button_with_text(guide.cards,"蓝绿文化网络",true)
	check(guide.opened and guide.stage == "charter" and plan_button != null and plan_button.is_visible_in_tree(),kind+"_production_p_opens_charter_choice")
	if plan_button == null: return {}
	plan_button.emit_signal("pressed")
	var card_button: Button = guide.card_choices.get_child(0) if guide.card_choices.get_child_count() > 0 else null
	check(card_button != null and card_button.is_visible_in_tree(),kind+"_production_plan_offers_real_change_card")
	if card_button == null: return {}
	card_button.emit_signal("pressed")
	var at := Vector2(float(candidate["position"][0]),float(candidate["position"][1]))
	guide.map_click(at,false)
	check(guide.stage == "scope" and guide.scope == [COMMUNITY_ID],kind+"_scope_click_selects_real_theme_community")
	guide.confirm.emit_signal("pressed")
	check(guide.stage == "anchor" and demo.model.world.pending_actions.any(func(op: Dictionary)->bool:return str(op.get("kind","")) == "charter" and op.get("community_ids",[]).has(COMMUNITY_ID)),kind+"_scope_confirmation_queues_real_charter")
	var anchor_button := _button_with_text(guide.actions,"公园 · 留白" if kind == "park" else "文化馆 · 主题")
	check(anchor_button != null and anchor_button.is_visible_in_tree(),kind+"_production_public_choice_button_is_available")
	if anchor_button == null: return {}
	anchor_button.emit_signal("pressed")
	var before: int = demo.model.decisions.size()
	guide.map_click(at,false)
	var decision: Dictionary = demo.model.decisions.back() if demo.model.decisions.size() > before else {}
	check(demo.model.decisions.size() == before+1 and str(decision.get("operation",{}).get("kind","")) == kind and not guide.opened,kind+"_map_click_submits_one_real_facility_choice")
	return decision

func _find_authored_site(kind: String,boundary: int) -> void:
	var operation: Dictionary = operations[kind].get("operation",{})
	var raw_position: Array = operation.get("position",[])
	if raw_position.size() != 2: return
	var expected := Vector2(float(raw_position[0]),float(raw_position[1]))
	for site in demo.shown_world.public_sites:
		if not bool(site.get("active",false)) or str(site.get("kind","")) != kind or int(site.get("frame",-1)) != boundary: continue
		var position: Array = site.get("position",[])
		if position.size() == 2 and Vector2(float(position[0]),float(position[1])).distance_to(expected) < 0.01:
			authored_sites[kind] = site.duplicate(true)
			break

func _capture(name: String) -> void:
	# Capture only; PNG compression/file I/O waits until physical output stops.
	if not setup_only:
		var image: Image = demo.get_viewport().get_texture().get_image()
		check(image != null and image.get_width() >= 800 and image.get_height() >= 600,name+"_window_draws")
		if image != null: screenshots[name] = image
	observations[name] = _snapshot()

func _wait_for_authored_activity(kind: String,boundary: int) -> void:
	var rate: int = demo.clock.renderer.transport.sample_rate
	var wait_seconds := maxf(1.0,(float(boundary)-float(demo.clock.renderer.transport.audible_frame))/rate)+8.0
	var deadline := Time.get_ticks_msec()+roundi(wait_seconds*1000.0)
	var all_marks_actual := true
	var queued_before_audible := false
	var future_site_leaked := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if not setup_only: await RenderingServer.frame_post_draw
		var af := float(demo.public_space_activity_layer.get("audible_frame"))
		all_marks_actual = all_marks_actual and _marks_match_actual()
		if af < boundary:
			if demo.model.rendered_until > boundary:
				if not queued_before_audible: observations[kind+"_rendered_but_not_audible"] = _snapshot()
				queued_before_audible = true
			for mark: Dictionary in _marks():
				var site := _site(str(mark.get("site_id","")))
				if int(site.get("frame",0)) >= boundary: future_site_leaked = true
			continue
		_find_authored_site(kind,boundary)
		if not authored_sites.has(kind): continue
		if demo.planning_guide.opened and demo.planning_guide.stage == "feedback":
			_key(KEY_P)
			continue
		var wanted_id := str(authored_sites[kind]["id"])
		var theme_mark: Dictionary = {}
		for mark: Dictionary in _marks():
			if str(mark.get("site_id","")) != wanted_id or float(mark.get("alpha",0.0)) < CAPTURE_ALPHA: continue
			if not str(mark["event_id"]).begins_with("public:"): theme_mark = mark.duplicate(true)
		if not theme_mark.is_empty() and not observed_events.has(kind+":theme"):
			observed_events[kind+":theme"] = _plain(theme_mark)
			_capture("public_"+kind+"_theme_live")
		if observed_events.has(kind+":theme"): break
	check(all_marks_actual,kind+"_every_observed_public_mark_matches_actual_audible_pcm_site_and_position")
	check(queued_before_audible and not future_site_leaked,kind+"_rendered_public_future_waits_for_device_audible_boundary")
	check(authored_sites.has(kind),kind+"_next_phrase_builds_authored_public_site")
	check(observed_events.has(kind+":theme"),kind+"_actual_theme_row_projects_clear_mark_at_authored_site")

func _finish() -> void:
	if is_instance_valid(demo):
		var end_frame := float(demo.clock.renderer.transport.audible_frame)
		output_window = {"audible_before":start_frame,"audible_after":end_frame,"advanced_frames":end_frame-start_frame,
			"sample_rate":demo.clock.renderer.transport.sample_rate,"underruns_before":start_skips,"underruns_after":demo.clock.underruns}
		if not setup_only:
			var crossed_boundaries := not operations.is_empty()
			var planned_boundaries: Dictionary = {}
			for kind in operations:
				var boundary := int(operations[kind].get("structure_frame",-1))
				planned_boundaries[kind] = boundary
				crossed_boundaries = crossed_boundaries and start_frame < boundary and end_frame >= boundary and authored_sites.has(kind)
			output_window["planned_boundaries"] = planned_boundaries
			check(crossed_boundaries and end_frame-start_frame >= float(demo.clock.renderer.transport.sample_rate)*0.75,"physical_device_crosses_submitted_public_boundaries_with_real_progress")
			check(demo.clock.underruns == start_skips,"physical_public_planning_adds_no_underruns")
		demo.clock.stop_output()
		demo.light_player.stop()
		demo.preview_player.stop()
		await process_frame
		await process_frame
		if not setup_only: check(not demo.public_space_activity_layer.visible and _marks().is_empty(),"stopped_production_output_clears_public_activity")
	var screenshot_paths: Dictionary = {}
	if not setup_only:
		DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
		for name in screenshots:
			var path := OUTPUT_DIRECTORY+"/"+str(name)+".png"
			check(screenshots[name].save_png(path) == OK,str(name)+"_screenshot_saved")
			screenshot_paths[name] = path
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"operations":operations,
		"authored_sites":_plain(authored_sites),"observed_events":observed_events,"observations":observations,
		"output_window":output_window,"screenshots":screenshot_paths,"setup_only":setup_only,"wait_boundaries":wait_boundaries,
		"display_backend":DisplayServer.get_name(),"audio_driver":AudioServer.get_driver_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()["string"],
		"scope":"Production callbacks and optional Dummy boundary sequence only; no physical output/window evidence is written" if setup_only else "Production default city/P/charter/card/scope/public choice callbacks; physical park then civic settlements, actual Lead/Reply rows, authored P/C map marks, black listening and output stop. Existing rhythm qualification stays authoritative; no invented facility rhythm, manual live render/settle, saved work, human listening or long-term balance claim"}
	if not setup_only:
		var file := FileAccess.open(OUTPUT_DIRECTORY+"/public_space_demo_live.json",FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(evidence,"\t")+"\n")
			file.close()
		else: check(false,"live_json_saved")
	print("ROUND175_PUBLIC_SPACE_DEMO_"+("SETUP " if setup_only else "LIVE "),JSON.stringify(evidence))
	if is_instance_valid(demo): demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	start_frame = float(demo.clock.renderer.transport.audible_frame)
	start_skips = demo.clock.underruns
	if not setup_only: check(DisplayServer.get_name() != "headless" and AudioServer.get_driver_name() == "WASAPI","real_window_uses_physical_wasapi")
	check(demo.clock.active and demo.model.world.phrase_index == 2 and demo.model.world.rng.seed_hex == "2026100900000062" and demo.model.world.terrain.family == "river_valley","production_mature_default_city_is_playing")
	check(is_instance_valid(demo.public_space_activity_layer) and demo.model.music_activity != null and demo.model.public_activity != null,"production_enables_actual_music_and_public_activity_before_rendering")
	check(demo.model.decisions.is_empty() and demo.model.world.pending_actions.is_empty(),"opening_does_not_fabricate_player_choices")
	_key(KEY_P)
	var rework: Button = demo.planning_guide.get("theme_rework_button") as Button
	check(rework != null and rework.is_visible_in_tree() and not rework.disabled,"production_p_exposes_real_theme_source")
	if rework == null or rework.disabled:
		await _finish()
		return
	rework.emit_signal("pressed")
	var focus_button := _button_with_text(demo.menu,"聚焦")
	check(focus_button != null and demo.context.get("kind","") == "retune" and str(demo.shown_world.by_id.get(demo.selected_id,{}).get("community_id","")) == COMMUNITY_ID,"actual_theme_source_offers_production_focus_control")
	if focus_button == null:
		await _finish()
		return
	focus_button.emit_signal("pressed")
	_key(KEY_H)
	var park_candidate := _candidate()
	check(not park_candidate.is_empty(),"selected_real_community_has_legal_park_space")
	if park_candidate.is_empty():
		await _finish()
		return
	operations["park"] = _queue_public("park",park_candidate)
	var park_position := Vector2(float(park_candidate["position"][0]),float(park_candidate["position"][1]))
	var park_boundary := int(operations["park"].get("structure_frame",-1))
	check(park_boundary == demo.model.next_boundary and demo.model.world.pending_actions.filter(func(op: Dictionary)->bool:return str(op.get("kind","")) in ["park","civic"]).size() == 1 and demo.shown_world.phrase_index == 2,"park_choice_remains_pending_without_early_city_mutation")
	observations["queued_park_choice"] = _snapshot()
	if wait_boundaries and park_boundary >= 0:
		await _wait_for_authored_activity("park",park_boundary)
	var civic_candidate := _candidate([park_position])
	check(not civic_candidate.is_empty(),"same_real_community_has_actual_legal_civic_space_after_growth")
	if civic_candidate.is_empty():
		await _finish()
		return
	operations["civic"] = _queue_public("civic",civic_candidate)
	var civic_boundary := int(operations["civic"].get("structure_frame",-1))
	check(civic_boundary == demo.model.next_boundary and demo.model.world.pending_actions.filter(func(op: Dictionary)->bool:return str(op.get("kind","")) in ["park","civic"]).size() == 1,"civic_choice_remains_one_pending_public_intent")
	observations["queued_civic_choice"] = _snapshot()
	if not wait_boundaries or civic_boundary < 0:
		await _finish()
		return
	check(civic_boundary == park_boundary+demo.model.phrase_frames and authored_sites.has("park"),"civic_replanning_follows_the_really_built_park_in_the_next_phrase")
	await _wait_for_authored_activity("civic",civic_boundary)
	check(demo.model.synth.last_voice_count <= int(demo.model.synth.score.get("render_voice_limit",70)),"public_mark_feedback_keeps_existing_voice_budget")
	var before_black := float(demo.clock.renderer.transport.audible_frame)
	_key(KEY_B)
	await process_frame
	await process_frame
	check(demo.black and not demo.public_space_activity_layer.visible and _marks().is_empty(),"production_black_listening_hides_public_marks")
	await create_timer(0.2).timeout
	check(demo.clock.active and float(demo.clock.renderer.transport.audible_frame)-before_black >= float(demo.clock.renderer.transport.sample_rate)*0.1,"black_listening_keeps_physical_public_audio_running")
	_key(KEY_B)
	await process_frame
	await process_frame
	check(not demo.black and demo.public_space_activity_layer.visible and _marks_match_actual(),"production_b_restores_only_current_actual_public_marks")
	await _finish()
