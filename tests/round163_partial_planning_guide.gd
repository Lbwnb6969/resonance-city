extends SceneTree
## Fixed partial comparison -> authoritative public reveal -> usable next action.
const World = preload("res://scripts/world/continuous_world.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Neighborhood = preload("res://scripts/world/neighborhood_plan.gd")
const Partial = preload("res://scripts/world/partial_public_conversion.gd")
const Charter = preload("res://scripts/world/development_charter.gd")
const NextAction = preload("res://scripts/world/planning_next_action.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func _find_target(city: World) -> Dictionary:
	for y in range(-36,37):
		for x in range(-36,37):
			var center := Vector2(float(x)*0.25,float(y)*0.25)
			var polygon := Neighborhood.box(center,Vector2(0.42,0.42))
			var candidate := {"polygon":polygon,"position":[center.x,center.y]}
			if Planning.site_reason(city,candidate).is_empty() and not Planning.public_access(city,candidate).is_empty(): return candidate
	return {}

func _payload(site: Dictionary,key: Array,boundary: int,city: World) -> Dictionary:
	var cid := str(site["target_community_id"])
	var variants := {}
	for kind in ["none","park","civic"]:
		variants[kind] = {"accepted":true,"score":{"theme":{}},"theme_events":0,"service":{"served":0},
			"houses":city.buildings.size(),"anchor":{},"newly_served_ids":[],"lost_service_ids":[],
			"opportunity_preview":{"choice":kind,"accepted":true,"source_version":key.slice(1),
				"source_frame":0,"boundary_frame":boundary,"world_version":Charter.version(city),
				"boundary":{"frame":boundary,"world_version":Charter.version(city)},
				"affected_communities":[cid],"communities":[{"community_id":cid,"roles":{
					"theme":{"role":"Lead","qualified":false,"next":"继续安排本片社区的音级","current":"主题待条件"}}}]}}
	return {"source_version":key.slice(1),"source_frame":0,"boundary_frame":boundary,"variants":variants}

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var city := World.new("2026101100000163",true,"river_valley")
	city.build_starter("bright")
	var target := _find_target(city)
	check(not target.is_empty(),"finds_real_road_accessible_target")
	if target.is_empty():
		demo.free()
		quit(1)
		return
	var center := Vector2(float(target["position"][0]),float(target["position"][1]))
	var source := Neighborhood.box(center,Vector2(1.2,1.2))
	var hole := Neighborhood.box(center,Vector2(0.14,0.14))
	var reservation_id := "round163-guide-source"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round163-guide-lot",
		"polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	var site := Partial.preview_footprints(city,reservation_id,"civic",[target["polygon"]],[hole])
	check(bool(site.get("accepted",false)),"courtyard_conversion_is_legal")
	if not bool(site.get("accepted",false)):
		demo.free()
		quit(1)
		return
	demo._start_world({},city)
	demo.clock.stop_output()
	demo.set_process(false)
	var guide = demo.planning_guide
	guide.begin_partial_comparison(site,"park")
	check(guide.stage == "partial_anchor" and guide.opened,"partial_stage_opens_without_charter_scope")
	check(guide.candidate["target_polygons"] == site["target_polygons"] and guide.candidate["hole_polygons"] == [hole],"comparison_keeps_every_authored_ring")
	var key: Array = guide.comparison_identity()
	demo.pointer += Vector2(100,-90)
	guide.update_candidate(Vector2(-100,-100))
	check(guide.comparison_identity() == key and guide.candidate["source_reservation_id"] == reservation_id,"pointer_motion_cannot_replace_fixed_target")
	check(guide.map_click(center,false) and city.pending_actions.is_empty(),"partial_panel_cannot_submit_old_whole_site_action")
	guide.choose_anchor("none")
	check(guide.detail.text.contains("保留来源留地") and city.planning_reservations.size() == 1,"none_branch_keeps_source_reservation")
	guide.choose_anchor("civic")
	var payload := _payload(site,key,int(demo.model.next_boundary),city)
	check(guide.accept_comparison(payload,key),"thread_payload_accepts_fixed_target_identity")
	check(guide.detail.text.contains("Enter 确认这一范围") and guide.detail.text.contains("试听是完整合奏"),"partial_comparison_explains_confirm_and_audio_scope")
	var altered := site.duplicate(true)
	altered["hole_polygons"] = [Neighborhood.box(center,Vector2(0.12,0.12))]
	altered["target_holes"] = altered["hole_polygons"].duplicate(true)
	guide.begin_partial_comparison(altered,"civic")
	check(not guide.accept_comparison(payload,key),"changed_courtyard_rejects_stale_worker_payload")
	guide.begin_partial_comparison(site,"civic")
	key = guide.comparison_identity()
	check(guide.accept_comparison(_payload(site,key,int(demo.model.next_boundary),city),key),"restored_target_accepts_its_own_comparison")
	var operation := site.duplicate(true)
	operation["kind"] = "civic"
	operation["partial"] = true
	operation["position"] = site["target_position"].duplicate()
	var result: Dictionary = demo.model.submit(operation)
	check(bool(result.get("accepted",false)),"exact_courtyard_queues_through_production_model")
	guide.queue_partial_action(operation,result)
	guide.clear_partial_comparison()
	guide.hide_tool()
	check(guide.next_action.get("state","") == "queued" and guide.next_action.get("contract","") == NextAction.CONTRACT,"draft_cleanup_keeps_queued_contract")
	check(guide.next_action.get("choice","") == "civic" and guide.next_action.get("building_id","") == "","partial_queue_selects_real_kind_without_inventing_birth")
	var boundary := int(result.get("frame",-1))
	var event_id := int(result.get("event_id",-1))
	check(not guide._next_action_event_matches({"kind":"civic","partial":true,"frame":boundary,"event_id":event_id,"source_reservation_id":"other","source_revision":site["source_revision"]}),"another_reservation_cannot_activate_followup")
	check(not guide._next_action_event_matches({"kind":"civic","partial":true,"frame":boundary,"event_id":event_id+1,"source_reservation_id":reservation_id,"source_revision":site["source_revision"]}),"another_transaction_cannot_activate_followup")
	check(not guide._next_action_event_matches({"kind":"birth","frame":boundary,"district_id":str(city.buildings[0]["district_id"]),"plan_id":"compact"}),"unrelated_birth_does_not_complete_partial_action")
	city.settle(boundary)
	var landed_event: Dictionary = {}
	for event in city.events:
		if bool(event.get("partial",false)) and int(event.get("event_id",-2)) == event_id: landed_event = event
	check(not landed_event.is_empty() and guide._next_action_event_matches(landed_event),"authoritative_conversion_event_matches_exact_source")
	guide.sync()
	check(guide.next_action.get("state","") == "ready" and guide.next_action.get("public_id","") == landed_event.get("id",""),"landed_public_identity_reopens_followup")
	check(guide.next_action.get("building_id","") == "" and guide.next_reservation_button.visible,"followup_uses_real_public_and_retains_residual_entry")
	var ready: Dictionary = guide.next_action.duplicate(true)
	guide.next_action_button.emit_signal("pressed")
	check(demo.context.get("kind","") == "civic" and demo.context.get("id","") == landed_event.get("id","") and demo.menu.visible,"public_button_opens_real_facility_menu")
	guide.next_action = ready.duplicate(true)
	guide.opened = true
	guide.refresh()
	guide.next_reservation_button.emit_signal("pressed")
	check(demo.context.get("kind","") == "reservation" and ready.get("remaining_reservation_ids",[]).has(demo.context.get("id","")),"residual_button_opens_real_remaining_parcel")
	if not ready.get("served_building_ids",[]).is_empty():
		guide.next_action = ready.duplicate(true)
		guide.opened = true
		guide.refresh()
		guide.next_served_button.emit_signal("pressed")
		check(demo.context.get("kind","") == "retune" and ready["served_building_ids"].has(demo.selected_id),"service_button_selects_only_a_real_served_house")
	else:
		guide.next_action = ready.duplicate(true)
		guide.opened = true
		guide.refresh()
		check(not guide.next_served_button.visible,"zero_service_does_not_show_a_fake_retune_target")
	print("ROUND163_PARTIAL_GUIDE checks=",checks," failures=",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
