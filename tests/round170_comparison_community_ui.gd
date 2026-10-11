extends SceneTree
## Round 170 UI proof: selecting which scoped community to inspect only
## changes opportunity rows and the queued continuation. It never changes the
## captured comparison/audio source, and revealed objects rebind the action.

const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")

var checks: Dictionary = {}
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _candidate(world: RefCounted,cid: String) -> Dictionary:
	for lot in world.lots:
		if not str(lot.get("occupant","" )).is_empty() or str(lot.get("community_id","")) != cid: continue
		var site: Dictionary = world.planning_candidate(Vector2(float(lot["center"][0]),float(lot["center"][1])))
		if site.is_empty() or not bool(site.get("allowed",false)) or site.has("public_id"): continue
		if not Planning.public_access(world,site).is_empty(): return site
	return {}

func _role(role_id: String,title: String,cid: String) -> Dictionary:
	return {"role":role_id,"title":title,"qualified":true,"qualification":{"qualified":true},
		"current":cid+" 当前"+title,"next":cid+" 下一步"+title,"anchor_ids":[cid+"-"+role_id]}

func _record(cid: String) -> Dictionary:
	return {"community_id":cid,"roles":{
		"theme":_role("Lead","社区主题",cid),"bass":_role("Bass","低音表达",cid),
		"commercial":_role("Rhythm","商业律动",cid),"response":_role("Response","跨岸应答",cid)},
		"anchor_ids":[cid+"-public"]}

func _comparison(ids: Array,key: Array,boundary: int,world: RefCounted) -> Dictionary:
	var records: Array = []
	for cid in ids: records.append(_record(str(cid)))
	var variants: Dictionary = {}
	for kind in ["none","park","civic"]:
		var preview := {"choice":kind,"accepted":true,"source_version":key.slice(1),"source_frame":0,
			"boundary_frame":boundary,"world_version":Charter.version(world),
			"boundary":{"frame":boundary,"world_version":Charter.version(world)},
			"affected_communities":ids.duplicate(),"communities":records.duplicate(true)}
		variants[kind] = {"accepted":true,"score":{"theme":{"cid":str(ids[0])}},"theme_events":1,
			"service":{"served":0},"houses":world.buildings.size(),"anchor":{"served":[],"service_capacity":18},
			"newly_served_ids":[],"lost_service_ids":[],"pcm":PackedByteArray([3,17,29,47]),
			"opportunity_preview":preview}
	return {"source_version":key.slice(1),"source_frame":0,"boundary_frame":boundary,"variants":variants}

func _community_button(guide: Control,cid: String) -> Button:
	for child in guide.comparison_community_choices.get_children():
		if child is Button and str(child.get_meta("community_id","")) == cid: return child
	return null

func _pcm_bytes(comparison: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for kind in ["none","park","civic"]:
		result[kind] = comparison.get("variants",{}).get(kind,{}).get("pcm",PackedByteArray()).duplicate()
	return result

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	var primary := str(demo.model.world.buildings[0]["community_id"])
	var secondary := ""
	var primary_building_id := str(demo.model.world.buildings[0]["district_id"])
	for building in demo.model.world.buildings:
		var cid := str(building.get("community_id",""))
		if cid != primary:
			secondary = cid
			break
	var site: Dictionary = _candidate(demo.model.world,primary)
	check(not site.is_empty() and not secondary.is_empty(),"fixture_has_real_public_site_and_two_existing_communities")
	if site.is_empty() or secondary.is_empty():
		demo.queue_free()
		await process_frame
		quit(1)
		return

	guide.open_tool()
	guide.plan_id = "compact"
	guide.card_id = "infill_pulse"
	guide.stage = "anchor"
	guide.anchor_kind = "park"
	guide.scope = [primary,secondary]
	demo.pointer = demo.point(Vector2(float(site["position"][0]),float(site["position"][1])))
	guide.update_candidate(demo.world_at(demo.pointer))
	var key: Array = guide.comparison_identity()
	var payload: Dictionary = _comparison([primary,secondary],key,int(demo.model.next_boundary),demo.model.world)
	var world_before: Dictionary = demo.model.world.snapshot()
	var model_before: Dictionary = demo.model.capture_state()
	check(not key.is_empty() and guide.accept_comparison(payload,key),"accepts_comparison_through_captured_identity")
	check(guide.comparison_community_choices.visible,"multi_community_comparison_shows_choices")
	check(guide.comparison_community_choices.get_children().filter(func(child: Node) -> bool: return child is Button).size() == 2,"multi_community_comparison_has_one_choice_per_id")
	check(guide.comparison_community_id == primary,"comparison_defaults_to_first_available_community")
	var identity_before: Array = guide.comparison_identity()
	var comparison_before: Dictionary = guide.comparison.duplicate(true)
	var pcm_before: Dictionary = _pcm_bytes(guide.comparison)
	var secondary_button: Button = _community_button(guide,secondary)
	check(secondary_button != null,"community_choice_uses_stable_community_id")
	if secondary_button != null: secondary_button.emit_signal("pressed")
	check(guide.comparison_community_id == secondary,"button_selects_secondary_community")
	var text: String = guide.detail.text
	check(text.contains(secondary+" 当前低音表达") and not text.contains(primary+" 当前低音表达"),"opportunity_rows_follow_the_viewed_community")
	var uncovered: Dictionary = guide.comparison["variants"]["none"].duplicate(true)
	uncovered["opportunity_preview"]["communities"] = [_record(primary)]
	check(guide._comparison_opportunity_items(uncovered).is_empty(),"branch_without_viewed_community_does_not_borrow_another_community_roles")
	check(guide.comparison == comparison_before and _pcm_bytes(guide.comparison) == pcm_before,"community_view_does_not_mutate_comparison_or_pcm")
	check(guide.comparison_identity() == identity_before and guide.comparison_key == key,"community_view_keeps_captured_comparison_identity")
	check(demo.model.world.snapshot() == world_before and demo.model.capture_state() == model_before,"community_view_does_not_mutate_world_or_audio_model")
	guide.choose_comparison_community("missing-community")
	check(guide.comparison_community_id == secondary and guide.detail.text == text,"invalid_community_choice_is_ignored")

	guide.choose_anchor("civic")
	check(guide.comparison_community_id == secondary,"public_branch_change_preserves_available_community")
	check(_pcm_bytes(guide.comparison) == pcm_before and guide.comparison_identity() == identity_before,"public_branch_change_keeps_same_captured_audio_source")
	guide._queue_next_action({})
	check(guide.next_action.get("contract","") == NextAction.CONTRACT and guide.next_action.get("state","") == "queued","queue_retains_existing_next_action_contract")
	check(guide.next_action.get("community_id","") == secondary and guide.next_action.get("operation",{}).get("community","") == secondary,"queue_targets_the_viewed_community")
	check(guide.next_action.get("affected_communities",[]).has(primary) and guide.next_action.get("affected_communities",[]).has(secondary),"queue_keeps_all_affected_communities")
	check(str(guide.next_action.get("roles",{}).get("bass",{}).get("current","")).begins_with(secondary),"queued_opportunity_uses_viewed_community_roles")
	var event := {"kind":"birth","district_id":primary_building_id,"plan_id":"compact", "frame":int(guide.next_action.get("expected_boundary_frame",-1))}
	check(guide._next_action_event_matches(event),"revealed_object_in_another_affected_community_still_matches")
	guide._activate_next_action(event)
	check(guide.next_action.get("building_id","") == primary_building_id and guide.next_action.get("community_id","") == primary,"revealed_object_rebinds_continuation_to_actual_community")
	check(str(guide.next_action.get("roles",{}).get("bass",{}).get("current","")).begins_with(primary),"revealed_object_rebinds_roles_to_its_community")

	guide.opened = true
	guide.stage = "anchor"
	guide.anchor_kind = "park"
	guide.scope = [primary]
	guide.update_candidate(demo.world_at(demo.pointer))
	key = guide.comparison_identity()
	check(guide.accept_comparison(_comparison([primary],key,int(demo.model.next_boundary),demo.model.world),key),"single_community_comparison_still_accepts")
	check(not guide.comparison_community_choices.visible,"single_community_comparison_has_no_extra_choice_row")
	check(guide.comparison_community_id == primary,"single_community_comparison_uses_its_only_available_id")
	check(guide.detail.text.contains(primary+" 当前低音表达"),"single_community_opportunity_rows_keep_existing_content")
	guide.hide_tool()
	check(guide.comparison_community_id.is_empty() and not guide.comparison_community_choices.visible,"closing_comparison_clears_the_transient_community_view")

	print("ROUND170_COMPARISON_COMMUNITY_UI ",JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures}))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
