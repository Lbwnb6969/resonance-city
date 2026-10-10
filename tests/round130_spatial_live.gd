extends SceneTree
const DemoScene = preload("res://scenes/continuous_valley.tscn")
var checks: Dictionary = {}
var demo: Control
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> void:
	checks[label] = ok
	if not ok: push_error(label)
func _click(p: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = demo.point(p)
	demo._gui_input(event)
func _advance() -> int:
	var at: int = demo.model.next_boundary
	demo.model.enable_background_settlement()
	demo.model.prepare_settlement(at-22050,22050)
	while not demo.model.settlement_job.completed(): await process_frame
	demo.model.prepare_settlement(at-22050,22050)
	demo.clock.renderer.transport.rendered_frames = at
	demo.clock.renderer.render(512)
	demo.clock.renderer.transport.audible_frame = at-1
	demo.shown_world = demo.model.presentation_world(at-1)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	await RenderingServer.frame_post_draw
	return at
func _reveal(at: int) -> void:
	demo.clock.renderer.transport.audible_frame = at+22050
	demo.shown_world = demo.model.presentation_world(at+22050)
	demo._sync_buildings()
	demo.scenery.sync(demo)
	await RenderingServer.frame_post_draw

func _run() -> void:
	demo = DemoScene.instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	demo.set_process_input(false)
	# Empty charter cities open the planning guide for new players. This legacy
	# spatial-menu contract exercises the direct map menu, so close the transient
	# guide explicitly before clicking the candidate.
	demo.planning_guide.hide_tool()
	var p := Vector2.ZERO
	var found := false
	for lot in demo.model.world.lots:
		p = Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site: Dictionary = demo.model.world.planning_candidate(p)
		if site.is_empty() or not bool(site["allowed"]) or site.has("public_id"): continue
		if demo.model.world.SpatialPlanning.public_access(demo.model.world,site).is_empty(): continue
		found = true
		break
	_check(found,"selectable_public_location")
	_click(p)
	_check(demo.menu.visible and not demo.planning_buttons["reserve"].disabled and not demo.planning_buttons["civic"].disabled,"click_opens_position_choices")
	await RenderingServer.frame_post_draw
	_check(Rect2(Vector2.ZERO,demo.size).encloses(demo.menu.get_global_rect()),"menu_fits_window")
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/第130轮_选址菜单.png")
	demo.planning_buttons["reserve"].emit_signal("pressed")
	_check(demo.model.world.pending_actions.any(func(op:Dictionary)->bool:return op["kind"] == "reserve"),"button_queues_exact_selected_space")
	var at := await _advance()
	_check(demo.shown_world.planning_reservations.is_empty(),"reservation_hidden_until_heard")
	await _reveal(at)
	_check(demo.shown_world.planning_reservations.size() == 1,"reservation_revealed")
	_click(p)
	_check(demo.context["kind"] == "reservation" and not demo.planning_buttons["release_reservation"].disabled,"reservation_has_release")
	demo.planning_buttons["civic"].emit_signal("pressed")
	at = await _advance()
	_check(demo.shown_world.planning_reservations.size() == 1 and demo.shown_world.public_at(p).is_empty(),"conversion_keeps_old_view")
	await _reveal(at)
	var facility: Dictionary = demo.shown_world.public_at(p)
	_check(not facility.is_empty() and facility["kind"] == "civic" and demo.shown_world.planning_reservations.is_empty(),"facility_built_at_player_position")
	_check(not facility.is_empty() and demo.scenery.props.has(facility["id"]) and demo.scenery.props[facility["id"]].visible,"new_civic_has_visible_model")
	_check(not facility.is_empty() and facility.get("covered",[]).size()>0 and facility.get("served",[]).size()>0,"player_civic_serves_real_buildings")
	_click(p)
	_check(not demo.planning_buttons["civic"].disabled and demo.planning_buttons["reserve"].disabled,"built_facility_can_expand")
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/第130轮_自选文化馆.png")
	var vehicles := {}
	for key in demo.scenery.props:
		if demo.scenery.props[key].has_meta("traveler"): vehicles[key] = demo.scenery.props[key].get_meta("traveler")
	var park_point := Vector2.ZERO
	found = false
	for lot in demo.model.world.lots:
		park_point = Vector2(float(lot["center"][0]),float(lot["center"][1]))
		var site: Dictionary = demo.model.world.planning_candidate(park_point)
		if site.is_empty() or not bool(site["allowed"]) or site.has("public_id"): continue
		if demo.model.world.SpatialPlanning.public_access(demo.model.world,site).is_empty(): continue
		found = true
		break
	_check(found,"another_player_site_available")
	_click(park_point)
	demo.planning_buttons["park"].emit_signal("pressed")
	at = await _advance()
	await _reveal(at)
	var park: Dictionary = demo.shown_world.public_at(park_point)
	var trees_inside := not park.is_empty()
	for key in demo.scenery.public_prop_keys.get(park.get("id",""),[]):
		trees_inside = trees_inside and Geometry2D.is_point_in_polygon(demo.scenery.props[key].get_meta("world_position"),park["polygon"])
	_check(not park.is_empty() and park["kind"] == "park" and trees_inside,"player_park_trees_stay_inside")
	var same_travelers := true
	for key in vehicles: same_travelers = same_travelers and demo.scenery.props[key].get_meta("traveler") == vehicles[key]
	_check(same_travelers,"adding_sites_preserves_traffic_state")
	demo.menu.hide()
	demo.pointer_inside = false
	demo.queue_redraw()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://验证记录/连续河谷/第130轮_自选公园.png")
	var result := {"passed":checks.values().all(func(ok:bool)->bool:return ok),"checks":checks,"civic":facility,"park":park,"background":demo.model.settlement_stats}
	FileAccess.open("res://验证记录/连续河谷/第130轮_空间交互.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("SPATIAL_LIVE ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if result["passed"] else 1)
