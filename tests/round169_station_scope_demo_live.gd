extends SceneTree
## Round 169 real-window evidence for station → P → charter/card → scope.
## Real authored routes settle directly to keep this rendered interaction check
## short. It verifies production controls and drawing, not wall-clock listening.

const DemoScene = preload("res://scenes/continuous_valley.tscn")
const TransitPlanning = preload("res://scripts/world/transit_planning.gd")
const OUTPUT_DIRECTORY := "res://验证记录/round169_站点社区规划"

var demo: Control
var checks: Dictionary = {}
var failures: Array[String] = []
var station_id := ""
var station_scope: Array = []
var edited_scope: Array = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok:
		failures.append(label)
		push_error(label)

func _road_candidates() -> Array[Vector2]:
	var result: Array[Vector2] = []
	var seen: Array[String] = []
	for road in demo.shown_world.roads:
		if bool(road.get("bridge",false)): continue
		var path: PackedVector2Array = road.get("path",PackedVector2Array())
		if path.size() < 2: continue
		var stop := TransitPlanning.stop_preview(demo.model.world,path[path.size()/2])
		if not bool(stop.get("accepted",false)): continue
		var id := str(stop.get("id",""))
		if id.is_empty() or seen.has(id): continue
		seen.append(id)
		result.append(Vector2(float(stop["position"][0]),float(stop["position"][1])))
	return result

func _find_route(candidates: Array[Vector2]) -> Array:
	for i in range(candidates.size()):
		for j in range(i+1,candidates.size()):
			for k in range(j+1,candidates.size()):
				var route := [candidates[i],candidates[j],candidates[k]]
				if bool(TransitPlanning.preview(demo.model.world,route).get("accepted",false)): return route
	return []

func _find_second_route(anchor: Vector2,candidates: Array[Vector2]) -> Array:
	for i in range(candidates.size()):
		if candidates[i].distance_to(anchor) <= 0.18: continue
		for j in range(i+1,candidates.size()):
			if candidates[j].distance_to(anchor) <= 0.18: continue
			var route := [anchor,candidates[i],candidates[j]]
			if bool(TransitPlanning.preview(demo.model.world,route).get("accepted",false)): return route
	return []

func _append_route(route: Array) -> void:
	for position in route: demo._append_transit_stop(position)

func _settle_pending() -> bool:
	for operation in demo.model.world.pending_actions:
		if str(operation.get("kind","")) != "transit_line": continue
		demo.model.world.settle(int(operation.get("frame",-1)))
		demo.shown_world = demo.model.world
		return true
	return false

func _station_with_catchment(route: Array) -> Dictionary:
	for position in route:
		var station: Dictionary = demo._transit_station_at(position)
		if not station.get("record",{}).get("community_ids",[]).is_empty(): return station
	return {}

func _button_with_text(parent: Node,text: String,contains := false) -> Button:
	for child in parent.get_children():
		if child is Button and ((contains and str(child.text).contains(text)) or (not contains and str(child.text) == text)):
			return child
		var nested := _button_with_text(child,text,contains)
		if nested != null: return nested
	return null

func _click_world(position: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.position = demo.point(position)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	demo._gui_input(click)

func _center_for_community(cid: String) -> Vector2:
	for center in demo.model.world.centers:
		if str(center.get("community_id",center.get("id",""))) != cid: continue
		var raw: Variant = center.get("position",[])
		return raw if raw is Vector2 else Vector2(float(raw[0]),float(raw[1]))
	return Vector2.INF

func _capture_and_finish() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	var screenshot := OUTPUT_DIRECTORY+"/station_scope_live.png"
	var image: Image = demo.get_viewport().get_texture().get_image()
	check(image != null and image.get_width() >= 800 and image.get_height() >= 600,"window_renders_city_and_scope_panel")
	if image != null:
		check(image.save_png(screenshot) == OK,"scope_screenshot_saved")
	var evidence := {"passed":failures.is_empty(),"checks":checks,"failures":failures,
		"station_id":station_id,"station_scope":station_scope,"edited_scope":edited_scope,
		"stage":str(demo.planning_guide.stage),"display_backend":DisplayServer.get_name(),
		"adapter":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()["string"],
		"screenshot":screenshot,"scope":"Production Demo control callbacks, direct real-world phrase settlement, rendered scope panel; no human or long listening claim"}
	FileAccess.open(OUTPUT_DIRECTORY+"/station_scope_live.json",FileAccess.WRITE).store_string(JSON.stringify(evidence,"\t")+"\n")
	print("ROUND169_STATION_SCOPE_DEMO_LIVE ",JSON.stringify(evidence))
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
	# Preserve the directly-settled authoritative world during render frames;
	# presentation/audio progression is covered separately by backend tests.
	demo.set_process(false)
	check(DisplayServer.get_name() != "headless","real_window_backend")

	var candidates := _road_candidates()
	var first_route: Array = _find_route(candidates)
	check(first_route.size() == 3,"finds_first_authored_route")
	if first_route.size() != 3:
		await _capture_and_finish()
		return
	demo._verb("plan_transit")
	_append_route(first_route)
	demo._submit_transit_route()
	check(_settle_pending(),"first_line_settles")
	var first_station := _station_with_catchment(first_route)
	check(not first_station.is_empty(),"first_line_has_real_station_catchment")
	if first_station.is_empty():
		await _capture_and_finish()
		return
	var anchor: Vector2 = first_station["position"]
	var second_route: Array = _find_second_route(anchor,candidates)
	check(second_route.size() == 3,"finds_second_route_through_catchment_station")
	if second_route.size() != 3:
		await _capture_and_finish()
		return
	demo._verb("plan_transit")
	_append_route(second_route)
	demo._submit_transit_route()
	check(_settle_pending(),"second_line_settles")
	var station: Dictionary = demo._transit_station_at(anchor)
	station_id = str(station.get("id",""))
	station_scope = station.get("record",{}).get("community_ids",[]).duplicate()
	check(station.get("line_ids",[]).size() >= 2,"station_is_shared_by_two_authored_lines")
	check(not station_scope.is_empty(),"shared_station_has_authoritative_community_scope")
	demo._sync_buildings()
	demo.scenery.sync(demo)
	if demo.has_method("_sync_map_labels"): demo._sync_map_labels()
	demo.queue_redraw()

	_click_world(anchor)
	await process_frame
	check(demo.menu.visible,"station_click_opens_context_menu")
	check(str(demo.context.get("kind","")) == "transit_station","station_click_sets_transit_context")
	check(demo.menu_info.text.contains("P规划社区") and demo.menu_info.text.contains("覆盖范围"),"station_menu_explains_planning_followup")
	var planning_button := _button_with_text(demo.menu,"规划社区 · P")
	check(planning_button != null and not planning_button.disabled,"station_has_production_planning_button")
	if planning_button == null:
		await _capture_and_finish()
		return
	planning_button.emit_signal("pressed")
	check(demo.planning_guide.opened and demo.planning_guide.stage == "charter","menu_planning_button_triggers_normal_guide")
	check(demo.planning_guide.scope_seed == station_scope,"menu_planning_button_preserves_station_catchment")
	# P on the open station menu must carry the same context as its button.
	demo.planning_guide.hide_tool()
	_click_world(anchor)
	var planning_key := InputEventKey.new()
	planning_key.keycode = KEY_P
	planning_key.pressed = true
	demo._input(planning_key)
	check(demo.planning_guide.opened and demo.planning_guide.stage == "charter","station_menu_p_key_opens_normal_guide")
	check(demo.planning_guide.scope_seed == station_scope,"station_menu_p_key_preserves_same_catchment")

	var charter_button := _button_with_text(demo.planning_guide.cards,"走廊连接",true)
	check(charter_button != null,"guide_has_production_corridor_charter_button")
	if charter_button == null:
		await _capture_and_finish()
		return
	charter_button.emit_signal("pressed")
	check(demo.planning_guide.stage == "card","charter_button_enters_change_card_stage")
	var card_id: String = str(demo.planning_guide.card_id)
	var card_button: Button = demo.planning_guide.card_choices.get_child(0) if demo.planning_guide.card_choices.get_child_count() > 0 else null
	check(card_button != null,"guide_has_production_variation_card_button")
	if card_button == null:
		await _capture_and_finish()
		return
	card_button.emit_signal("pressed")
	check(demo.planning_guide.stage == "scope","change_card_button_opens_editable_scope")
	check(demo.planning_guide.scope == station_scope,"scope_prefills_actual_station_catchment")
	check(demo.planning_guide.confirm.visible and not demo.planning_guide.confirm.disabled,"prefilled_scope_enables_original_confirm_button")
	check(demo.planning_guide.detail.text.contains("Shift点击继续多选"),"scope_panel_explains_editing_and_multiselect")

	var alternate_ids: Array[String] = []
	for center in demo.model.world.centers:
		var cid := str(center.get("community_id",center.get("id","")))
		if cid.is_empty() or alternate_ids.has(cid) or station_scope.has(cid): continue
		alternate_ids.append(cid)
		if alternate_ids.size() >= 2: break
	check(alternate_ids.size() >= 2,"fixture_has_two_editable_alternative_communities")
	if alternate_ids.size() >= 2:
		demo.planning_guide.map_click(_center_for_community(alternate_ids[0]),false)
		check(demo.planning_guide.scope == [alternate_ids[0]],"ordinary_map_click_replaces_station_seed")
		demo.planning_guide.map_click(_center_for_community(alternate_ids[1]),true)
		check(demo.planning_guide.scope.has(alternate_ids[0]) and demo.planning_guide.scope.has(alternate_ids[1]),"shift_map_click_adds_second_community")
		edited_scope = demo.planning_guide.scope.duplicate()
	# Return to the real station suggestion for the screenshot. This exercises
	# the same production card callback rather than assigning a visual-only scope.
	card_button.emit_signal("pressed")
	check(demo.planning_guide.scope == station_scope,"card_callback_restores_station_seed_for_capture")
	check(demo.planning_guide.card_id == card_id,"scope_editing_keeps_selected_card")
	demo.planning_guide.sync()
	demo.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(not demo.planning_guide.scope_polygons.is_empty(),"prefilled_scope_has_visible_real_map_polygons")
	await _capture_and_finish()
