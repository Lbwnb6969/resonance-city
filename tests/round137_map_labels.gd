extends SceneTree
var checks: Dictionary = {}
func _initialize() -> void: call_deferred("_run")
func _valid_labels(layer: Node2D,demo: ContinuousValleyDemo) -> bool:
	var viewport := Rect2(Vector2(24,100),demo.size-Vector2(48,200))
	var bounds: Array[Rect2] = []
	for label in layer.labels:
		if not viewport.encloses(label["bounds"]): return false
		for other in bounds:
			if other.intersects(label["bounds"]): return false
		bounds.append(label["bounds"])
		var anchor: Dictionary = layer.anchors.filter(func(a: Dictionary) -> bool: return a["id"] == label["id"])[0]
		var origin := Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan
		if label["position"].distance_to(origin+anchor["position"]*demo.view_zoom+Vector2(-16,29)) > 0.001: return false
	return true
func _run() -> void:
	var demo: ContinuousValleyDemo = preload("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	demo.clock.stop_output()
	demo.set_process(false)
	demo._start_world({},ContinuousWorld.regional_sample())
	demo.pointer_inside = false
	var layer: Node2D = demo.community_label_layer
	var original := demo.model.world.snapshot()
	await RenderingServer.frame_post_draw
	checks["regional_names_decluttered"] = layer.anchors.size() == demo.overlay_communities.size() and not layer.labels.is_empty() and layer.labels.size() < layer.anchors.size()
	checks["regional_labels_fit_and_do_not_overlap"] = _valid_labels(layer,demo)
	var old_draws: int = layer.draw_count
	var old_layouts: int = layer.layout_updates
	var old_geometry: int = layer.geometry_updates
	for i in range(12):
		demo._sync_buildings()
		demo.queue_redraw()
		await RenderingServer.frame_post_draw
	checks["live_hud_does_not_redraw_stationary_names"] = layer.draw_count == old_draws and layer.layout_updates == old_layouts and layer.geometry_updates == old_geometry
	var projected: Array = layer.anchors.duplicate(true)
	demo.pan += Vector2(90,-60)
	demo._sync_buildings()
	await RenderingServer.frame_post_draw
	checks["pan_reuses_world_anchors"] = layer.geometry_updates == old_geometry and layer.anchors == projected and layer.layout_updates == old_layouts+1
	checks["pan_labels_fit_and_do_not_overlap"] = _valid_labels(layer,demo)
	# A community suppressed by density must be readable when explicitly selected.
	var visible_ids: Array = layer.labels.map(func(a: Dictionary) -> String: return a["id"])
	var target := ""
	var viewport := Rect2(Vector2(24,100),demo.size-Vector2(48,200))
	for anchor in layer.anchors:
		var at: Vector2 = Vector2(demo.size.x*0.5,demo.size.y*0.52)+demo.pan+anchor["position"]*demo.view_zoom+Vector2(-16,29)
		var bounds := Rect2(at-Vector2(0,ThemeDB.fallback_font.get_ascent(12)),anchor["size"]).grow(4)
		if not anchor["id"] in visible_ids and viewport.encloses(bounds):
			target = anchor["id"]
			break
	checks["selection_case_exercises_density_suppression"] = not target.is_empty()
	if not target.is_empty():
		demo.selected_id = demo.shown_world.communities[target]["members"][0]
		demo._sync_map_labels()
		checks["selected_community_has_priority"] = layer.labels.any(func(a: Dictionary) -> bool: return a["id"] == target)
	demo.view_zoom = 1.1
	demo._sync_buildings()
	checks["close_view_hides_map_names"] = not layer.visible
	demo.view_zoom = 0.88
	demo._sync_buildings()
	checks["zoom_layout_preserves_projection"] = layer.visible and layer.geometry_updates == old_geometry and _valid_labels(layer,demo)
	demo.black = true
	demo._sync_buildings()
	checks["black_listening_hides_labels"] = not layer.visible
	demo.black = false
	demo.pan = Vector2(50000,50000)
	demo._sync_buildings()
	checks["offscreen_names_culled"] = layer.labels.is_empty()
	checks["camera_and_selection_preserve_world"] = demo.model.world.snapshot() == original
	demo._home_city()
	demo.pan = demo.pan_target
	demo.view_zoom = demo.zoom_target
	demo.model.world.settle(demo.model.next_boundary)
	demo._sync_buildings()
	checks["growth_invalidates_centroids"] = layer.geometry_updates == old_geometry+1 and _valid_labels(layer,demo)
	var growth_labels: Array = layer.anchors.duplicate(true)
	demo.shown_world = demo.model.world.fork()
	demo._sync_buildings()
	checks["same_phrase_view_rebind_retains_anchors"] = layer.geometry_updates == old_geometry+1 and layer.anchors == growth_labels
	var result := {"passed":checks.values().all(func(v: bool) -> bool: return v),"checks":checks,"anchors":layer.anchors.size(),"visible_labels":layer.labels.size(),"geometry_updates":layer.geometry_updates,"layout_updates":layer.layout_updates,"draws":layer.draw_count}
	FileAccess.open("res://验证记录/连续河谷/第137轮_地图标签合同.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("MAP_LABELS ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(0 if result["passed"] else 1)
