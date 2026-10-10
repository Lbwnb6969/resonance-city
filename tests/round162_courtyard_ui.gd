extends SceneTree
## Production UI path: outer ring -> courtyard -> phrase boundary -> usable inner reservation.
const World = preload("res://scripts/world/continuous_world.gd")
const Model = preload("res://scripts/audio/continuous_audio_model.gd")
const Planning = preload("res://scripts/world/city_spatial_planning.gd")
const Neighborhood = preload("res://scripts/world/neighborhood_plan.gd")
const PartialPublic = preload("res://scripts/world/partial_public_conversion.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func key(demo: Control,code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	demo._input(event)
func capture(demo: Control,label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture") or DisplayServer.get_name() == "headless": return
	demo._sync_buildings()
	demo.scenery.sync(demo)
	demo.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://验证记录/round162_内院公共空间"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var path := directory+"/"+label+".png"
	check(root.get_texture().get_image().save_png(path) == OK,"captures_"+label)

func _run() -> void:
	var demo = load("res://scenes/continuous_valley.tscn").instantiate()
	demo.session_persistence = false
	root.add_child(demo)
	await process_frame
	await process_frame
	demo.clock.stop_output()
	demo.set_process(false)
	var city := World.new("2026101100000162",true,"river_valley")
	city.build_starter("bright")
	var outer := PackedVector2Array()
	var center := Vector2.ZERO
	for y in range(-36,37):
		for x in range(-36,37):
			var candidate_center := Vector2(float(x)*0.25,float(y)*0.25)
			var polygon := Neighborhood.box(candidate_center,Vector2(0.8,0.8))
			var candidate := {"polygon":polygon,"position":[candidate_center.x,candidate_center.y]}
			if Planning.site_reason(city,candidate).is_empty() and not Planning.public_access(city,candidate).is_empty():
				outer = polygon
				center = candidate_center
				break
		if not outer.is_empty(): break
	check(not outer.is_empty(),"finds_real_road_accessible_courtyard_site")
	if outer.is_empty():
		demo.queue_free()
		quit(1)
		return
	var source := Neighborhood.box(center,Vector2(1.2,1.2))
	var hole := Neighborhood.box(center,Vector2(0.3,0.3))
	var reservation_id := "round162-ui-source"
	city.planning_reservations.append({"id":reservation_id,"reservation_id":reservation_id,"source_site_id":"round162-ui-lot","polygon":source,"position":[center.x,center.y],"created_phrase":city.phrase_index})
	city._refresh_parcel_index()
	demo._start_world({},city)
	demo.planning_guide.hide_tool()
	demo.view_zoom = 1.9
	demo.zoom_target = 1.9
	demo.pan = demo.size*0.5-demo.point(center)+demo.pan
	demo.pan_target = demo.pan
	demo.pointer = demo.point(center+Vector2(0.6,0.6))
	demo.pointer_inside = true
	demo.context = {"kind":"reservation","id":reservation_id,"position":[center.x,center.y]}
	demo._verb("free_courtyard_park")
	check(demo.partial_courtyard_mode and not demo.partial_hole_drawing,"menu_enters_outer_ring_drawing")
	check(demo.planning_buttons.has("free_courtyard_park") and demo.planning_buttons.has("free_courtyard_civic"),"both_courtyard_facilities_exposed")
	for p in outer: demo._append_partial_polygon_point(p)
	key(demo,KEY_TAB)
	check(demo.partial_hole_drawing and demo.partial_polygon_components.size() == 1,"tab_keeps_outer_and_enters_inner_drawing")
	key(demo,KEY_ENTER)
	check(city.pending_actions.is_empty() and demo.notice.contains("至少一处内院"),"outer_alone_preserves_draft")
	for p in hole: demo._append_partial_polygon_point(p)
	var preview: Dictionary = demo._partial_preview_for_draw()
	check(bool(preview.get("accepted",false)),"courtyard_preview_is_legal")
	check(Planning.footprint_holes(preview).size() == 1,"preview_keeps_inner_ring")
	var fill: Array[PackedVector2Array] = demo._partial_preview_fill_polygons(preview)
	var fill_area := 0.0
	for piece in fill:
		fill_area += Planning.polygon_area(piece)
		check(PartialPublic._intersection_area(piece,hole) < 0.00001,"visible_fill_leaves_inner_area_empty")
	check(is_equal_approx(fill_area,Planning.polygon_area(outer)-Planning.polygon_area(hole)),"visible_fill_matches_occupied_area")
	await capture(demo,"courtyard_preview")
	key(demo,KEY_ENTER)
	check(city.pending_actions.size() == 1 and city.pending_actions[0].get("hole_polygons",[]).size() == 1,"enter_queues_outer_and_hole_together")
	check(not demo.partial_polygon_mode and demo.partial_polygon_holes.is_empty(),"submission_clears_entire_draft")
	var boundary: int = demo.model.next_boundary
	demo.model.render_block({},boundary-1,2,int(city.cfg["timing"]["sample_rate"]))
	check(city.public_at(center).is_empty(),"settled_inner_ring_is_not_public_occupancy")
	check(not city.planning_at(center).is_empty(),"settled_inner_ring_remains_plannable")
	demo.clock.renderer.transport.audible_frame = float(boundary+int(city.cfg["timing"]["sample_rate"]))
	await capture(demo,"courtyard_settled")
	demo.context = {"kind":"reservation","id":city.planning_at(center).get("reservation_id","")}
	demo._verb("free_courtyard_civic")
	demo._append_partial_polygon_point(center)
	key(demo,KEY_ESCAPE)
	check(not demo.partial_courtyard_mode and not demo.partial_hole_drawing and demo.partial_polygon_holes.is_empty(),"escape_clears_courtyard_state")
	await process_frame
	check(demo.menu.get_combined_minimum_size().x < demo.size.x,"public_menu_fits_viewport_width")
	print("ROUND162_COURTYARD_UI checks=",checks," failures=",JSON.stringify(failures))
	demo.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

