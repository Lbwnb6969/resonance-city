extends SceneTree
## Minimal production window probe: first composition -> warm author/reserve -> next entry.
const DemoScene = preload("res://scenes/continuous_valley.tscn")
const First = preload("res://scripts/world/first_composition.gd")
const OUT := "res://验证记录/round194_真实试玩探针/warm_live"
var demo: ContinuousValleyDemo
var checks: Dictionary = {}
var failures: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label); push_error(label)

func _key(code: Key,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	demo._input(event)

func _click(at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = demo.point(at)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	demo._gui_input(event)

func _until(frame: int) -> bool:
	var rate := demo.clock.renderer.transport.sample_rate
	var deadline := Time.get_ticks_msec()+roundi(maxf(0.0,(frame-demo.clock.renderer.transport.audible_frame)/float(rate))*1000.0)+8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.clock.renderer.transport.audible_frame >= frame: return true
	return false

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	demo.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT)+"/"+name+".png")

func _preview_ready() -> bool:
	var deadline := Time.get_ticks_msec()+10000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if demo.preview_started and not demo.expression_comparison.is_empty(): return true
	return false

func _heard_root(root_id: String) -> bool:
	var deadline := Time.get_ticks_msec()+24000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(demo._first_authored_state(root_id).get("root_heard_retune",false)): return true
	return false

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1440,900))
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	var rate := demo.clock.renderer.transport.sample_rate
	check(AudioServer.get_driver_name() == "WASAPI" and DisplayServer.get_name() != "headless","real_window_and_wasapi")
	check(demo.first_composition_mode and demo.shown_world.buildings.size() == 24,"unsettled_24_house_opening")
	await _until(10*rate+rate/10)
	check(demo.first_composition_guide.visible,"opening_invites_planning_after_overture")
	demo.first_composition_guide.emit_signal("pressed")
	var guide := demo.planning_guide
	guide.cards.get_child(0).emit_signal("pressed")
	guide.card_choices.get_child(0).emit_signal("pressed")
	var site: Dictionary = First.opportunities(demo.shown_world)["public_candidates"][0]
	_click(Vector2(float(site["position"][0]),float(site["position"][1])))
	guide.confirm.emit_signal("pressed")
	check(guide.stage == "anchor","charter_reaches_anchor_choice")
	guide.actions.get_child(3).emit_signal("pressed")
	_click(Vector2(float(site["position"][0]),float(site["position"][1])))
	var public_request: Dictionary = guide.next_action.duplicate(true)
	check(public_request.get("state","") == "queued","public_anchor_queued")
	check(await _until(int(public_request["expected_boundary_frame"])+rate/10),"public_anchor_reaches_real_boundary")
	check(guide.next_action.get("state","") == "ready","ready_sound_choice")
	guide.next_action_button.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty(),"sound_menu_starts_without_default")
	demo.expression_choices["warm"].emit_signal("pressed")
	demo.expression_listen.emit_signal("pressed")
	check(await _preview_ready(),"warm_has_actual_pcm_preview")
	await _capture("warm_expression_card")
	var comparison: Dictionary = demo.expression_comparison.duplicate(true)
	var warm_variant: Dictionary = comparison.get("variants",{}).get("warm",{})
	check(bool(warm_variant.get("accepted",false)),"warm_preview_accepted")
	check(int(warm_variant.get("consequences",{}).get("reservation_count",0)) > 0,"warm_preview_exposes_reservation")
	evidence["warm_summary"] = demo.expression_comparison_summary.text
	evidence["warm_reservations"] = warm_variant.get("consequences",{}).get("reservations",[])
	demo.expression_confirm.emit_signal("pressed")
	var warm_boundary := demo.model.next_boundary
	check(await _until(warm_boundary+rate/5),"warm_author_reaches_real_boundary")
	var author_state: Dictionary = demo._first_authored_state()
	var root_id := str(author_state.get("root_id",""))
	check(not root_id.is_empty(),"warm_root_is_real_authored_house")
	check(not demo.shown_world.planning_reservations.is_empty(),"warm_root_has_real_reservation")
	evidence["root_id"] = root_id
	evidence["houses_after_warm"] = demo.shown_world.buildings.size()
	evidence["reservations_after_warm"] = demo.shown_world.planning_reservations.duplicate(true)
	_key(KEY_P)
	if not demo._first_authored_state(root_id).is_empty() and demo._first_authored_state(root_id).get("theme_eligible",false):
		demo._begin_authored_theme(root_id)
		demo._choose_note(52)
		demo._verb("focus")
		check(await _heard_root(root_id),"warm_retune_is_heard")
	else:
		check(false,"warm_theme_reaches_editable_state")
	demo.first_composition_guide.sync()
	evidence["next_entry_action"] = demo.first_composition_guide.action
	evidence["next_entry_text"] = demo.first_composition_guide.text
	check(demo.first_composition_guide.action in ["continuation","compose"],"warm_after_retune_offers_next_entry")
	demo.first_composition_guide.emit_signal("pressed")
	await process_frame
	await _capture("warm_next_entry")
	evidence["planning_stage_after_entry"] = guide.stage
	check(guide.opened and guide.stage in ["charter","feedback","continuation"],"next_entry_opens_planning_or_reservation_followup")
	await _finish()

func _finish() -> void:
	demo._stop_preview()
	demo.clock.stop_output()
	demo.model.close_background_settlement()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	evidence["underruns"] = demo.clock.underruns
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,
		"scope":"Production UI, Windows/WASAPI physical frames and screenshots; no human fun/listening verdict."}
	FileAccess.open(ProjectSettings.globalize_path(OUT)+"/live.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND194_WARM_LIVE ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
