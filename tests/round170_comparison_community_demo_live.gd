extends SceneTree
## Round 170 real-window evidence: choose two real communities, queue one
## charter/card, build the real three public PCM branches, and use production
## community buttons to inspect the second community without changing music.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const PublicPreview = preload("res://scripts/world/public_planning_preview.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const OUTPUT_DIRECTORY := "res://验证记录/round170_社区机会查看"
const PUBLIC_KINDS := ["none","park","civic"]

var demo: Control
var checks: Dictionary = {}
var failures: Array[String] = []
var selected_scope: Array = []
var viewed_community_id := ""
var viewed_community_name := ""
var pcm_bytes: Dictionary = {}
var source_frame := 0
var source_token_id := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _button_with_text(parent: Node,text: String,contains := false) -> Button:
	for child in parent.get_children():
		if child is Button and ((contains and str(child.text).contains(text)) or (not contains and str(child.text) == text)):
			return child
		var nested := _button_with_text(child,text,contains)
		if nested != null: return nested
	return null

func _public_candidate() -> Dictionary:
	for lot in demo.model.world.lots:
		if not str(lot.get("occupant","" )).is_empty(): continue
		var p := Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var candidate: Dictionary = demo.model.world.planning_candidate(p)
		if candidate.is_empty() or not bool(candidate.get("allowed",false)) or candidate.has("public_id"): continue
		if not Planning.public_access(demo.model.world,candidate).is_empty(): return candidate
	return {}

func _center_for_community(cid: String) -> Vector2:
	for lot in demo.model.world.lots:
		if str(lot.get("community_id","")) != cid: continue
		return Vector2(float(lot["center"][0]),float(lot["center"][1]))
	return Vector2.INF

func _second_real_community(first_cid: String) -> String:
	for center in demo.model.world.centers:
		var cid := str(center.get("community_id",center.get("id","")))
		if cid.is_empty() or cid == first_cid or not demo.model.world.communities.has(cid): continue
		if demo.model.world.buildings.any(func(building: Dictionary) -> bool: return str(building.get("community_id","")) == cid): return cid
	return ""

func _community_record(variant: Dictionary,cid: String) -> Dictionary:
	for raw in variant.get("opportunity_preview",{}).get("communities",[]):
		if raw is Dictionary and str(raw.get("community_id","")) == cid: return raw
	return {}

func _role_text(record: Dictionary,alias: String) -> String:
	return str(record.get("roles",{}).get(alias,{}).get("current","" )).replace("\n","；")

func _capture_and_finish() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	var screenshot := OUTPUT_DIRECTORY+"/comparison_community_live.png"
	var image: Image = demo.get_viewport().get_texture().get_image()
	check(image != null and image.get_width() >= 800 and image.get_height() >= 600,"window_renders_city_and_comparison_panel")
	if image != null: check(image.save_png(screenshot) == OK,"comparison_community_screenshot_saved")
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"planning_scope":selected_scope,"viewed_community_id":viewed_community_id,"viewed_community_name":viewed_community_name,
		"source_frame":source_frame,"source_token_id":source_token_id,"pcm_bytes":pcm_bytes,
		"stage":str(demo.planning_guide.stage),"display_backend":DisplayServer.get_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()["string"],
		"screenshot":screenshot,"scope":"Production two-community planning/inspection callbacks, real PublicPreview model/PCM branches; no playback, human listening or long-term balance claim"}
	FileAccess.open(OUTPUT_DIRECTORY+"/comparison_community_live.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND170_COMPARISON_COMMUNITY_DEMO_LIVE ",JSON.stringify(evidence))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	demo.model.close_background_settlement()
	check(DisplayServer.get_name() != "headless","real_window_backend")
	var candidate := _public_candidate()
	check(not candidate.is_empty(),"starter_has_legal_road_accessible_public_candidate")
	if candidate.is_empty():
		await _capture_and_finish()
		return
	var first_cid := str(candidate.get("community_id",""))
	var second_cid := _second_real_community(first_cid)
	check(not first_cid.is_empty() and not second_cid.is_empty(),"fixture_has_two_real_starter_communities")
	var first_center := _center_for_community(first_cid)
	var second_center := _center_for_community(second_cid)
	check(first_center != Vector2.INF and second_center != Vector2.INF,"fixture_has_real_community_map_positions")
	if second_cid.is_empty() or first_center == Vector2.INF or second_center == Vector2.INF:
		await _capture_and_finish()
		return

	var guide = demo.planning_guide
	guide.open_tool()
	var charter_button := _button_with_text(guide.cards,"走廊连接",true)
	check(charter_button != null,"guide_has_production_charter_button")
	if charter_button == null:
		await _capture_and_finish()
		return
	charter_button.emit_signal("pressed")
	var card_button: Button = guide.card_choices.get_child(0) if guide.card_choices.get_child_count() > 0 else null
	check(card_button != null,"guide_has_production_change_card_button")
	if card_button == null:
		await _capture_and_finish()
		return
	card_button.emit_signal("pressed")
	check(guide.stage == "scope","production_card_enters_editable_scope")
	guide.map_click(first_center,false)
	guide.map_click(second_center,true)
	selected_scope = guide.scope.duplicate()
	check(selected_scope.size() >= 2 and selected_scope.has(first_cid) and selected_scope.has(second_cid),"ordinary_scope_clicks_select_two_real_communities")
	guide.confirm.emit_signal("pressed")
	check(guide.stage == "anchor","production_confirm_queues_charter_and_enters_anchor")
	var charter_pending: Dictionary = {}
	for operation in demo.model.world.pending_actions:
		if str(operation.get("kind","")) == "charter": charter_pending = operation
	check(not charter_pending.is_empty() and charter_pending.get("community_ids",[]).size() >= 2,"submitted_charter_keeps_two_community_scope")
	check(charter_pending.get("card_refs",[]).has(str(guide.card_id)),"submitted_charter_keeps_chosen_variation_card")

	# Match the production pointer/candidate identity. Only the captured private
	# models reach the next boundary; the live source retains its pending choice.
	var position := Vector2(float(candidate["position"][0]),float(candidate["position"][1]))
	demo.pointer = demo.point(position)
	demo.pointer_inside = true
	guide.update_candidate(position)
	check(bool(guide.candidate.get("allowed",false)) and not Planning.public_access(demo.model.world,guide.candidate).is_empty(),"guide_keeps_real_road_accessible_candidate")
	check(guide.candidate.get("planning_scope",[]) == selected_scope,"candidate_keeps_complete_current_scope")
	var rate := int(demo.model.world.cfg["timing"]["sample_rate"])
	var phases: Dictionary = {}
	var cursor := int(demo.model.world.phrase_index)*int(demo.model.phrase_frames)
	var boundary := int(demo.model.next_boundary)
	while cursor < boundary-128:
		var amount := mini(1024,boundary-128-cursor)
		demo.model.render_block(phases,cursor,amount,rate)
		cursor += amount
	source_frame = int(demo.model.rendered_until)
	source_token_id = demo.model.presentation_token.get_instance_id()
	var request_key: Array = guide.comparison_identity()
	var source_token = demo.model.presentation_token
	var scope_before: Array = guide.scope.duplicate()
	var candidate_before: Dictionary = guide.candidate.duplicate(true)
	var comparison: Dictionary = PublicPreview.build(demo.model.freeze(),candidate_before,phases,source_frame)
	check(comparison.get("source_version",[]) == request_key.slice(1),"real_comparison_uses_production_source_identity")
	var pcm_before: Dictionary = {}
	for kind: String in PUBLIC_KINDS:
		var variant: Dictionary = comparison.get("variants",{}).get(kind,{})
		check(bool(variant.get("accepted",false)),kind+"_real_public_branch_accepted")
		var pcm: PackedByteArray = variant.get("pcm",PackedByteArray())
		pcm_before[kind] = pcm.duplicate()
		pcm_bytes[kind] = pcm.size()
		check(pcm.size() == rate*3*4,kind+"_branch_contains_three_seconds_pcm")
		check(not _community_record(variant,first_cid).is_empty() and not _community_record(variant,second_cid).is_empty(),kind+"_branch_exposes_both_real_communities")
	check(guide.accept_comparison(comparison,request_key),"guide_accepts_real_model_and_pcm_comparison")
	check(guide.comparison_community_choices is HFlowContainer,"production_community_choices_use_flow_layout")
	var second_button: Button
	for child in guide.comparison_community_choices.get_children():
		if child is Button and str(child.get_meta("community_id","")) == second_cid:
			second_button = child
			break
	check(second_button != null,"production_comparison_has_second_community_button")
	if second_button == null:
		await _capture_and_finish()
		return
	second_button.emit_signal("pressed")
	viewed_community_id = str(guide.comparison_community_id)
	viewed_community_name = str(demo.model.world.communities.get(second_cid,{}).get("name",second_cid))
	check(viewed_community_id == second_cid,"community_button_callback_selects_second_community")
	check(guide.detail.text.contains(viewed_community_name),"comparison_detail_names_viewed_second_community")
	check(guide.detail.text.contains("低音表达") and guide.detail.text.contains("商业律动") and guide.detail.text.contains("跨岸应答"),"viewed_community_detail_explains_role_conditions")
	var selected_record := _community_record(guide.comparison["variants"]["park"],second_cid)
	for alias: String in ["bass","commercial","response"]:
		var current := _role_text(selected_record,alias)
		check(not current.is_empty() and guide.detail.text.contains(current),alias+"_detail_uses_viewed_community_snapshot_condition")
	check(guide.scope == scope_before and guide.candidate == candidate_before,"inspection_keeps_planning_scope_and_public_candidate")
	check(guide.comparison_identity() == request_key and guide.comparison_key == request_key,"inspection_keeps_comparison_request_identity")
	check(demo.model.presentation_token == source_token and demo.model.presentation_token.get_instance_id() == source_token_id,"inspection_keeps_audio_source_token")
	for kind: String in PUBLIC_KINDS:
		check(guide.comparison["variants"][kind]["pcm"] == pcm_before[kind],kind+"_community_inspection_keeps_original_pcm")
	check(not demo.preview_player.playing,"real_three_branch_pcm_is_not_played_during_window_audit")
	guide.sync()
	demo.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(guide.visible and guide.comparison_community_choices.visible,"selected_community_controls_render_in_open_comparison")
	check(guide.get_global_rect().end.y < demo.size.y,"comparison_panel_keeps_controls_inside_window")
	await _capture_and_finish()
