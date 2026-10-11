extends SceneTree
## Round 175 contract: a landed multi-community combo can be continued through
## the real planning guide. The continuation only seeds an editable scope;
## world/audio state changes after the player submits a new choice.

const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
const EVIDENCE_PATH := "res://验证记录/round175_公共经营接续/community_combo_continuation.json"

var checks: Dictionary = {}
var failures: Array[String] = []
var layouts: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: failures.append(label)

func _candidate(world: RefCounted,cid: String) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","")).is_empty() or str(lot.get("community_id","")) != cid: continue
		var site: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if site.is_empty() or not bool(site.get("allowed",false)) or site.has("public_id"): continue
		if not Planning.public_access(world,site).is_empty(): return site
	return {}

func _check_feedback_layout(demo: Control,guide: Control) -> void:
	for window_size in [Vector2i(1440,900),Vector2i(800,600)]:
		root.content_scale_size = window_size
		root.size = window_size
		await process_frame
		await process_frame
		guide.refresh()
		await process_frame
		await process_frame
		var window := Rect2(Vector2.ZERO,Vector2(window_size))
		var panel: Rect2 = guide.get_global_rect()
		var buttons: Array = [guide.next_action_button,guide.next_combo_button,guide.next_replan_button]
		var inside := true
		for button: Button in buttons:
			inside = inside and button.is_visible_in_tree() and window.encloses(button.get_global_rect()) and panel.encloses(button.get_global_rect())
		var label := "%dx%d" % [window_size.x,window_size.y]
		check(window.encloses(panel),"feedback_panel_fits_"+label)
		check(inside,"three_feedback_actions_fit_"+label)
		layouts.append({"window":[window_size.x,window_size.y],"panel_position":[panel.position.x,panel.position.y],
			"panel_size":[panel.size.x,panel.size.y],"all_actions_inside":inside})

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	var ids: Array[String] = []
	for building in demo.model.world.buildings:
		var cid := str(building.get("community_id",""))
		if not cid.is_empty() and not ids.has(cid): ids.append(cid)
		if ids.size() >= 2: break
	check(ids.size() == 2,"fixture_has_two_communities")
	if ids.size() < 2:
		demo.queue_free()
		await process_frame
		quit(1)
		return

	guide.open_tool()
	guide.choose_plan("compact")
	guide.choose_card("infill_pulse")
	guide.scope = ids.duplicate()
	guide.commit_scope()
	var site := _candidate(demo.model.world,ids[0])
	check(not site.is_empty(),"fixture_has_real_public_site")
	if site.is_empty():
		demo.queue_free()
		await process_frame
		quit(1)
		return
	demo.pointer = demo.point(Vector2(float(site["position"][0]),float(site["position"][1])))
	guide.update_candidate(demo.world_at(demo.pointer))
	var key: Array = guide.comparison_identity()
	var preview: Dictionary = PublicPreview.build(demo.model,guide.candidate,demo.clock.renderer.state,demo.model.rendered_until)
	check(guide.accept_comparison(preview,key),"accepts_real_three_branch_preview")
	guide.map_click(Vector2(float(site["position"][0]),float(site["position"][1])),false)
	check(guide.next_action.get("state","") == "queued","public_commit_queues_existing_next_action")
	var boundary := int(demo.model.next_boundary)
	var rate := int(demo.model.world.cfg["timing"]["sample_rate"])
	demo.model.render_block(demo.clock.renderer.state,boundary-1,2,rate)
	demo.shown_world = demo.model.presentation_world(boundary)
	guide.sync()
	check(guide.next_action.get("state","") == "ready","real_boundary_activates_combo_followup")
	var world_before: Dictionary = demo.model.world.snapshot()
	var model_before: Dictionary = demo.model.capture_state()
	check(guide.next_combo_button.visible,"ready_combo_shows_continuation_button")
	check(str(guide.next_combo_button.text).contains("2社区"),"continuation_button_names_combo_scope")
	check(guide._next_action_detail().contains("组合机会"),"feedback_keeps_combo_context")
	await _check_feedback_layout(demo,guide)
	guide.next_combo_button.emit_signal("pressed")
	check(guide.stage == "charter" and guide.opened,"continuation_reopens_normal_planning")
	check(str(guide.scope_source.get("kind","")) == "community_combo","continuation_marks_combo_scope_source")
	ids.sort()
	check(guide.scope_seed == ids and guide.scope == ids,"continuation_preselects_real_communities")
	check(demo.model.world.snapshot() == world_before and demo.model.capture_state() == model_before,"continuation_does_not_change_world_or_audio")

	guide.choose_plan("compact")
	check(guide.stage == "card" and guide.scope == ids,"plan_step_keeps_combo_scope")
	guide.choose_card("infill_pulse")
	check(guide.stage == "scope" and guide.scope == ids,"card_step_keeps_combo_scope")
	var first_building: Dictionary = demo.model.world.buildings[0]
	guide.map_click(Vector2(float(first_building["position"][0]),float(first_building["position"][1])),true)
	check(not guide.scope.has(str(first_building["community_id"])),"scope_remains_editable_after_continuation")
	check(demo.model.world.snapshot() == world_before and demo.model.capture_state() == model_before,"editing_combo_scope_keeps_world_and_audio_until_submit")
	guide.commit_scope()
	check(guide.stage == "anchor" and demo.model.world.pending_actions.any(func(op: Dictionary) -> bool: return str(op.get("kind","")) == "charter" and op.get("community_ids",[]) == guide.scope),"new_scope_submits_through_real_charter_path")
	var next_boundary := int(demo.model.next_boundary)
	demo.model.render_block(demo.clock.renderer.state,next_boundary-1,2,rate)
	var landed: Dictionary = demo.model.world.development_charters.back()
	check(landed.get("community_ids",[]) == guide.scope,"continued_charter_lands_with_edited_scope")
	check(not demo.model.world.snapshot().has("scope_source") and not landed.has("community_combo"),"combo_continuation_stays_out_of_saved_truth")
	guide.stage = "feedback"
	guide.next_action = {"state":"ready","community_combo":{"community_ids":[ids[0]],"count":1}}
	guide.refresh()
	check(not guide.next_combo_button.visible,"single_community_has_no_combo_action")
	guide.next_action["community_combo"] = {"community_ids":[ids[0],"missing-community"],"count":2}
	guide.refresh()
	check(not guide.next_combo_button.visible,"removed_community_does_not_create_invalid_scope")
	guide.next_action = {"state":"ready","partial":true,"choice":"park",
		"community_combo":{"community_ids":ids.duplicate(),"count":2}}
	guide.refresh()
	check(guide.next_combo_button.visible,"partial_multi_community_result_keeps_combo_entry")
	model_before = demo.model.capture_state()
	guide._continue_combo_planning()
	check(guide.stage == "charter" and guide.scope == ids and demo.model.capture_state() == model_before,"partial_combo_seeds_normal_flow_without_replaying_footprint")
	var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"communities":ids.duplicate(),"landed_scope":landed.get("community_ids",[]).duplicate(),"layouts":layouts}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(EVIDENCE_PATH.get_base_dir()))
	var file := FileAccess.open(EVIDENCE_PATH,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report,"  ")+"\n")
		file.close()
	print("ROUND175_COMMUNITY_COMBO_CONTINUATION "+JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
