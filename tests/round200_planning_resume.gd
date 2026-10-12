extends SceneTree
## Resume the existing UI choice after a real chapter submit, without another submit.
const World = preload("res://scripts/world/continuous_world.gd")
const First = preload("res://scripts/world/first_composition.gd")
const OUTPUT := "res://验证记录/round200_首玩接续/planning_resume.json"
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
	guide.choose_anchor("civic")

func _key(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
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
	var entry = demo.first_composition_guide
	_plan(site)
	var charter_id: String = guide.committed_charter_id
	var boundary: int = guide.committed_charter_frame
	var chosen_scope: Array = guide.scope.duplicate()
	var before := city.snapshot()
	_key(KEY_P)
	entry.sync()
	check(not guide.opened and guide.unfinished_public_choice() and guide.committed_charter_id == charter_id and guide.committed_charter_frame == boundary and guide.scope == chosen_scope,"P_close_preserves_existing_chapter_and_public_choice")
	check(entry.visible and entry.action == "public" and not entry.disabled,"one_light_entry_returns_to_unfinished_public_step")
	entry.emit_signal("pressed")
	check(guide.opened and guide.stage == "anchor" and guide.anchor_kind == "civic" and guide.scope == chosen_scope and city.snapshot() == before,"light_entry_resumes_same_anchor_without_chapter_resubmit")
	_key(KEY_ESCAPE)
	check(not guide.opened and guide.unfinished_public_choice(),"Escape_close_preserves_unfinished_anchor")
	_key(KEY_P)
	check(guide.opened and guide.stage == "anchor" and guide.committed_charter_id == charter_id and city.pending_actions.size() == 1,"P_resumes_same_anchor_with_one_pending_chapter")
	# Rendering may settle the same chapter before its audible presentation advances.
	var old_presentation := city.fork()
	city.settle(boundary)
	demo.shown_world = old_presentation
	_key(KEY_P)
	entry.sync()
	check(guide.unfinished_public_choice() and entry.action == "public" and entry.visible,"render_ahead_retains_ui_choice_without_sound_unlock")
	check(guide.ready_sound_community().is_empty(),"unfinished_public_choice_does_not_unlock_sound")
	demo.shown_world = city
	_key(KEY_P)
	check(guide.opened and guide.stage == "anchor" and guide.committed_charter_id == charter_id and guide.scope == chosen_scope and city.development_charters.size() == 1,"same_settled_chapter_still_resumes_anchor")
	guide.choose_anchor("none")
	guide.map_click(Vector2(float(site["position"][0]),float(site["position"][1])),false)
	guide.sync()
	check(not guide.unfinished_public_choice() and not guide.composition_anchor_draft and guide.ready_sound_community() == site["community_id"],"completed_public_choice_clears_draft_and_uses_real_sound_handoff")
	_key(KEY_P)
	entry.sync()
	check(entry.action == "sound" and entry.visible,"completed_choice_exposes_sound_entry_instead_of_stale_public_entry")
	entry.emit_signal("pressed")
	check(demo.menu.visible and demo.expression_choice.is_empty() and guide.next_action.get("state","") == "consumed","resume_chain_reaches_unselected_actual_sound_choices")
	_key(KEY_ESCAPE)
	_key(KEY_P)
	check(guide.stage == "charter" and not guide.unfinished_public_choice() and guide.committed_charter_id.is_empty(),"consumed_choice_never_reopens_finished_anchor")
	# A canceled chapter is not authority for this UI draft.
	city = _city()
	site = _prepare(city)
	_plan(site)
	_key(KEY_P)
	demo.model.cancel_pending()
	entry.sync()
	check(not guide.unfinished_public_choice() and entry.action == "planning","withdrawn_chapter_discards_public_resume_authority")
	_key(KEY_P)
	check(guide.stage == "charter" and guide.scope.is_empty() and guide.committed_charter_id.is_empty(),"P_after_withdrawal_starts_new_unselected_planning")
	# World normalizes multi-community scopes; UI input order cannot erase the draft.
	city = _city()
	site = _prepare(city)
	_plan(site)
	demo.model.cancel_pending()
	guide.scope = First.opportunities(city)["community_ids"].duplicate()
	guide.scope.reverse()
	guide.commit_scope()
	city.settle(guide.committed_charter_frame)
	guide.hide_tool()
	check(guide.unfinished_public_choice(),"normalized_multi_community_scope_retains_same_draft")
	# Older ordinary-city planning keeps its existing open/close behavior.
	city = _city()
	site = _prepare(city)
	demo.first_composition_mode = false
	_plan(site)
	guide.hide_tool()
	guide.open_tool()
	check(guide.stage == "charter" and not guide.unfinished_public_choice() and guide.committed_charter_id.is_empty(),"ordinary_city_keeps_existing_transient_planning_behavior")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Dummy production UI plus real World pending and settled charters. Controlled presentation proves P, Escape and light-entry resume with no World resubmit; no physical audio or human-fun claim."}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	FileAccess.open(OUTPUT,FileAccess.WRITE).store_string(JSON.stringify(report,"\t")+"\n")
	print("ROUND200_PLANNING_RESUME "+JSON.stringify(report))
	demo.clock.active = false
	demo._stop_preview()
	demo.free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
