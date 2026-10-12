extends SceneTree
## The deliberate no-public-space choice continues from its actual charter,
## including render-ahead, panel recovery and the ordinary-city behavior.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round198_暂不建设/skip_anchor.json"
var checks: Dictionary = {}
var failures: Array[String] = []
var demo: Control

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _city() -> World:
	var city := World.new("2026100900000062",true,"river_valley")
	city.build_first_composition_starter()
	return city

func _prepare(city: World) -> Dictionary:
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	# Simulate only the UI's active-device gate. No PCM is played by this test.
	demo.clock.active = true
	demo.first_composition_mode = true
	demo.planning_guide.reset_for_city()
	return First.opportunities(city)["public_candidates"][0]

func _plan(site: Dictionary) -> void:
	var guide = demo.planning_guide
	guide.open_tool()
	guide.choose_plan("compact")
	guide.choose_card(guide.card_id)
	guide.map_click(Vector2(float(site["position"][0]),float(site["position"][1])),false)
	guide.commit_scope()
	guide.choose_anchor("none")

func _skip(site: Dictionary) -> void:
	demo.planning_guide.map_click(Vector2(float(site["position"][0]),float(site["position"][1])),false)

func _p() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_P
	event.pressed = true
	demo._input(event)

func _run() -> void:
	demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	var city := _city()
	var site := _prepare(city)
	var guide = demo.planning_guide
	_plan(site)
	_skip(site)
	var queued: Dictionary = guide.next_action.duplicate(true)
	var boundary := int(queued.get("expected_boundary_frame",-1))
	check(bool(queued.get("first_composition_anchor",false)) and queued.get("choice","") == "none" and queued.get("state","") == "queued" and not guide.opened,"not_building_queues_sound_after_its_charter")
	check(city.pending_actions.size() == 1 and city.pending_actions[0]["kind"] == "charter" and city.public_sites.all(func(s: Dictionary) -> bool: return not bool(s["active"])) and city.planning_reservations.is_empty() and city.buildings.size() == 24,"skip_submits_no_facility_reservation_or_house")
	check(guide.ready_sound_community().is_empty(),"sound_step_does_not_open_before_audible_charter")
	var wrong_event := {"kind":"charter","id":"charter-other","frame":boundary}
	check(not guide._next_action_event_matches(wrong_event),"different_charter_at_same_boundary_cannot_unlock_sound")
	demo.model.submit({"kind":"retune","id":city.buildings[0]["district_id"],"midi":48})
	guide.sync()
	check(guide.next_action.get("state","") == "queued","independent_retune_keeps_skipped_anchor_followup")
	var old_presentation := city.fork()
	city.settle(boundary)
	demo.shown_world = old_presentation
	guide.sync()
	check(guide.next_action.get("state","") == "queued" and guide.ready_sound_community().is_empty() and not guide.opened,"render_ahead_does_not_unlock_unheard_charter")
	demo.shown_world = city
	guide.sync()
	check(city.buildings.size() == 24 and not city.events.any(func(e: Dictionary) -> bool: return e.get("kind","") == "birth" and int(e.get("frame",-1)) == boundary),"real_boundary_has_no_birth_to_depend_on")
	check(guide.next_action.get("state","") == "ready" and guide.opened and guide.stage == "feedback" and guide.ready_sound_community() == site["community_id"] and guide.detail.text.contains("没有新增公共设施"),"actual_charter_unlocks_selected_community_sound_without_fake_anchor")
	_p()
	demo.first_composition_guide.sync()
	check(not guide.opened and demo.first_composition_guide.visible and demo.first_composition_guide.action == "sound","closed_feedback_keeps_one_light_sound_entry")
	_p()
	check(guide.opened and guide.stage == "feedback" and guide.ready_sound_community() == site["community_id"],"P_recovers_same_sound_step")
	_p()
	demo.first_composition_guide.sync()
	var before := city.snapshot()
	demo.first_composition_guide.emit_signal("pressed")
	check(demo.menu.visible and demo.context.get("community_id","") == site["community_id"] and demo.expression_choice.is_empty() and demo.expression_confirm.disabled and guide.next_action.get("state","") == "consumed" and city.snapshot() == before,"light_entry_opens_three_sounds_without_autoselection_or_submission")
	# The chapter can already be audible when the player declines its anchor.
	city = _city()
	site = _prepare(city)
	_plan(site)
	city.settle(guide.committed_charter_frame)
	demo.shown_world = city
	_skip(site)
	check(guide.next_action.get("state","") == "ready" and guide.ready_sound_community() == site["community_id"] and city.buildings.size() == 24,"declining_after_charter_reveal_continues_immediately")
	# A withdrawn charter supplies no authorization for the continuation.
	city = _city()
	site = _prepare(city)
	_plan(site)
	_skip(site)
	demo.model.cancel_pending()
	guide.sync()
	check(guide.next_action.get("state","") == "expired" and guide.ready_sound_community().is_empty(),"withdrawn_charter_does_not_unlock_sound")
	# Preserve the ordinary no-build contract: its existing growth follow-up.
	city = _city()
	site = _prepare(city)
	demo.first_composition_mode = false
	_plan(site)
	_skip(site)
	check(not bool(guide.next_action.get("first_composition_anchor",false)) and guide.next_action.get("state","") == "queued" and guide.ready_sound_community().is_empty() and city.pending_actions.size() == 1 and city.pending_actions[0]["kind"] == "charter","ordinary_city_keeps_existing_no_build_followup")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy production UI and real World settlements. Presentation is controlled to verify charter reveal, P and light-entry recovery. No physical audio, screenshot or human-fun claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND198_SKIP_ANCHOR "+JSON.stringify(report))
	demo.clock.active = false
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
