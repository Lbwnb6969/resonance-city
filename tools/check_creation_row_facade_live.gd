extends "res://tools/check_creation_three_road_modes_live.gd"

const Shell = preload("res://scripts/visual/city_creation_recessed_facade.gd")

func run() -> void:
	var old_work := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="): OUT = arg.trim_prefix("--out-dir=")
		if arg.begins_with("--old-work="): old_work = arg.trim_prefix("--old-work=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var started := Time.get_ticks_msec()
	var personal := FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var city := State.new()
	city.initialize_free()
	if old_work.is_empty():
		check(city.add_house(Vector2(-31.6,-28)).ok and city.add_house(Vector2(-29.8,-28)).ok,"author independently owned adjoining houses")
		check(city.add_house_stroke(Vector2(-28,-28),[
			{"x":0,"z":0,"level":0,"kind":"room"},{"x":1,"z":0,"level":0,"kind":"room"},
			{"x":1,"z":-1,"level":0,"kind":"terrace"}]).ok,"author end house and terrace")
		check(city.add_house(Vector2(-21,-28)).ok,"author detached control")
		for id: String in ["h1","h2","h3","h4"]: check(city.set_house_style(id,"timber").ok,"choose timber " + id)
		var road: Array[Vector2] = [Vector2(-33,-25.5),Vector2(-20,-25.5)]
		check(city.add_road(road,"cobble","none").ok,"author the shared street")
	else:
		check(city.load_city(old_work).ok,"load the work saved before the facade change")
	DirAccess.make_dir_recursive_absolute(OUT + "/works")
	root.size = Vector2i(1440,900)
	Engine.max_fps = 60
	demo = Scene.instantiate()
	demo.persistence = false
	demo.collection_directory = OUT + "/works"
	root.add_child(demo)
	await settle()
	isolate_input()
	await show(city,Vector2(-29,-28),"住宅连屋")
	quiet()
	demo.ui_layer.hide()
	demo.weather_visual.hide()
	demo.yaw = PI + .44
	demo.pitch = .32
	demo.zoom = 13.
	demo.focus = Vector3(-29.3,1.0,-28.2)
	demo._update_camera()
	var authored: Dictionary = demo.state.snapshot()
	await capture("row_day")
	demo._set_light_phase(2)
	await capture("row_night")
	demo._set_light_phase(0)
	demo.focus = Vector3(-31.7,1.0,-28.)
	demo.yaw = PI + 1.02
	demo.zoom = 6.5
	demo._update_camera()
	await capture("gable_detail")
	demo.yaw = PI + .44
	demo.focus = Vector3(-29.3,1.0,-28.2)
	demo.zoom = 13.
	demo._update_camera()
	check(demo.state.snapshot() == authored,"observation leaves authored work untouched")
	check(demo.state.save_city(OUT + "/works/row.json").ok,"save only to isolated work directory")
	if not "--baseline" in OS.get_cmdline_user_args(): await verify_row(authored)
	check(personal == FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal continue save remains byte-identical")
	var report := {"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-started)/1000.}
	FileAccess.open(OUT + "/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ROW_FACADE ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))

func row_walls(id: String) -> Array:
	return demo.town.house_roots[id].find_children("*","Node3D",true,false).filter(func(node):
		return node.has_meta("recessed_facade") and node.get_meta("recessed_facade").has("row_profile"))

func facade_evidence() -> Dictionary:
	var result := {}
	for id: String in ["h1","h2","h3","h4"]:
		var house_root: Node3D = demo.town.house_roots[id]
		result[id] = [row_walls(id).map(func(wall): return [wall.transform,wall.get_meta("recessed_facade"),shutters(wall).map(func(leaf): return leaf.transform)]),
			house_root.get_meta("roof_window_panes",[]).filter(func(pane): return pane.source == "timber_row")]
	return result

func shutters(wall: Node3D) -> Array:
	return wall.find_children("RowGableShutter*","Node3D",false,false)

func click_point(point: Vector3) -> void:
	var screen_position: Vector2 = demo.camera.unproject_position(point)
	var motion_event := InputEventMouseMotion.new()
	motion_event.device = 92
	motion_event.position = screen_position
	root.push_input(motion_event)
	await process_frame
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.device = 92
		event.position = screen_position
		event.global_position = screen_position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame
	await settle()

func wall_intersects(faces: Array[Vector3], point: Vector2) -> bool:
	var outside := Vector3(point.x,point.y,.25)
	var inside := Vector3(point.x,point.y,-.1)
	for index in range(0,faces.size(),3):
		if Geometry3D.segment_intersects_triangle(outside,inside,faces[index],faces[index+1],faces[index+2]) != null: return true
	return false

func verify_row(authored: Dictionary) -> void:
	var initial := facade_evidence()
	var kinds := {}
	var pick := Vector3.INF
	var end_pick := Vector3.INF
	var glow_exact := true
	var apertures_clear := true
	var shutters_clear := true
	var observations := []
	for id: String in ["h1","h2","h3"]:
		var house_root: Node3D = demo.town.house_roots[id]
		var windows: Array = demo.town.resonance.rigs[id].mesh.get_meta("windows")
		var attic: Array = house_root.get_meta("attic_windows",[])
		for wall: Node3D in row_walls(id):
			var plan: Dictionary = wall.get_meta("recessed_facade")
			kinds[plan.row_profile] = int(kinds.get(plan.row_profile,0)) + 1
			var spec: Dictionary = wall.get_meta("layered_window")
			var side := Vector2i(roundi(wall.basis.z.x),roundi(wall.basis.z.z))
			var panes: Array = initial[id][1].filter(func(pane): return pane.cell_id == spec.cell_id and pane.side == side)
			var glow: Array = windows.filter(func(window): return window.get("cell_id", "") == spec.cell_id and window.get("side",Vector2i.ZERO) == side and not attic.has(window))
			var observation := {"house":id,"cell":spec.cell_id,"side":str(side),"wanted":plan.holes.size(),"panes":panes.size(),"glow_kinds":glow.map(func(window): return window.get("kind","legacy")),"fits":[]}
			observations.append(observation)
			glow_exact = glow_exact and glow.size() == plan.holes.size() and panes.size() == plan.holes.size() and glow.all(func(window): return window.get("kind") == "timber_row")
			var shell_faces := Shell.faces(plan)
			var leaves := shutters(wall)
			shutters_clear = shutters_clear and leaves.size() == (2 if plan.row_profile == "gable_end" else 0)
			if plan.row_profile == "gable_end":
				for leaf: Node3D in leaves:
					var side_sign := signf(leaf.position.x)
					var outside_edge := leaf.transform * Vector3(side_sign*.17,0.,0.)
					shutters_clear = shutters_clear and absf(leaf.position.x)>plan.holes[0].radius and outside_edge.z>leaf.position.z and absf(outside_edge.x)<plan.width*.5
			for hole: Dictionary in plan.holes:
				apertures_clear = apertures_clear and not wall_intersects(shell_faces,Vector2(hole.x,(hole.bottom+hole.spring)*.5)) and wall_intersects(shell_faces,Vector2(hole.x+.037,1.58))
			for pane: Dictionary in panes:
				var fit: Array = plan.holes.filter(func(hole): return pane.faces.size() == 12 and Array(pane.faces).all(func(point):
					var local := wall.to_local(house_root.to_global(point))
					return absf(absf(local.x-hole.x)-hole.radius)<.001 and minf(absf(local.y-hole.bottom),absf(local.y-hole.spring))<.001 and local.z<0.))
				observation.fits.append({"vertices":pane.faces.size(),"matches":fit.size(),"first":str(wall.to_local(house_root.to_global(pane.faces[0])))})
				glow_exact = glow_exact and fit.size() == 1
			if id == "h2" and side == Vector2i.UP:
				var hole: Dictionary = plan.holes[0]
				pick = wall.to_global(Vector3(hole.x,(hole.bottom+hole.spring)*.5,.08))
			if id == "h1" and plan.row_profile == "gable_end":
				var end_hole: Dictionary = plan.holes[0]
				end_pick = wall.to_global(Vector3(end_hole.x,(end_hole.bottom+end_hole.spring)*.5,.08))
	check(kinds.has("gable_end") and kinds.has("inner_row") and kinds.has("row_end") and kinds.has("courtyard"),"real neighborhood yields all four row profiles")
	check(apertures_clear and not kinds.is_empty(),"shell has clear apertures and solid wall above")
	check(shutters_clear and kinds.has("gable_end"),"only exposed gable ends have two outward-turned shutters outside their apertures")
	check(glow_exact and not kinds.is_empty(),"published glow triangles match each aperture without legacy floating quads")
	check(initial.h4 == [[],[]],"detached timber control stays on the old recipe")
	check(pick != Vector3.INF and end_pick != Vector3.INF,"locate the middle and end windows")
	if pick == Vector3.INF or end_pick == Vector3.INF: return
	demo.ui_layer.show()
	demo.select_tool(4)
	await click_point(end_pick)
	check(demo.spatial_popover.target_house_id == "h1","actual glazed end still selects its original house after installing shutters")
	demo.spatial_popover.close()
	await click_point(pick)
	check(demo.spatial_popover.target_house_id == "h2" and demo.state.snapshot() == authored,"actual window click selects its own house without editing")
	await capture("middle_house_selected")
	demo.spatial_popover.close()
	demo.select_tool(0)
	demo.house_module_mode = true
	await click_point(pick)
	check(demo.state.houses[1].cells.size() == 2 and facade_evidence() != initial,"actual build click grows the middle house from the glazed wall")
	await capture("middle_house_extended")
	await key(KEY_Z,true)
	await settle()
	check(demo.state.houses == authored.houses and facade_evidence() == initial,"Ctrl+Z restores exact windows and adjoining house records")
	await key(KEY_Y,true)
	await settle()
	check(demo.state.houses[1].cells.size() == 2 and facade_evidence() != initial,"Ctrl+Y restores the facade change")
	await key(KEY_Z,true)
	await settle()
	var cold := State.new()
	check(cold.load_city(OUT + "/works/row.json").ok,"read the isolated work into a fresh state")
	await show(cold,Vector2(-29,-28),"住宅连屋冷读")
	check(demo.state.houses == authored.houses and facade_evidence() == initial,"cold publication reproduces the exact house records, apertures and pane triangles")
	facts["profiles"] = kinds
	facts["pane_geometry"] = observations
