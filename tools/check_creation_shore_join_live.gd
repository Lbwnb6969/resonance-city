extends "res://tools/check_creation_three_road_modes_live.gd"

const Terrain = preload("res://scripts/world/city_creation_terrain.gd")
const POND := Vector2(-25.,-20.)
const RIVER_Z := -9.

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="): OUT = arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var began := Time.get_ticks_msec()
	var personal := FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	DirAccess.make_dir_recursive_absolute(OUT+"/works")
	root.size = Vector2i(1280,800)
	Engine.max_fps = 60
	demo = Scene.instantiate()
	demo.persistence = false
	demo.start_empty = true
	demo.collection_directory = OUT+"/works"
	root.add_child(demo)
	await settle()
	isolate_input()
	var city := State.new()
	var old := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--old-work="): old = arg.trim_prefix("--old-work=")
	if old.is_empty():
		city.initialize_free()
		check(city.add_water([POND] as Array[Vector2],2.,"pond").ok,"create the original round pond")
	else:
		check(city.load_city(old).ok,"open the unchanged pre-edit work")
	await show(city,POND,"水岸接缝")
	quiet()
	demo.ui_layer.hide()
	demo.weather_visual.hide()
	demo.town.wildlife.hide()
	demo.town.lilypads.hide()
	var original: Dictionary = demo.state.snapshot()
	var geometry := geometry_hash()
	var river := Vector2(State.river_x(RIVER_Z),RIVER_Z)
	var sections := {}
	for index: int in range(48):
		var axis := Vector2.from_angle(TAU*index/48.)
		var crossing := flood_limit(POND,axis,1.2)
		sections.get_or_add("pond",[]).append([index,crossing,demo.state.water_clearance(POND+axis*crossing)])
	for index: int in range(21):
		var z := RIVER_Z+(index-10)*.25
		var center := Vector2(State.river_x(z),z)
		var bank := flood_limit(center,Vector2.RIGHT,2.6)
		sections.get_or_add("bend",[]).append([z,bank,demo.state.water_clearance(center+Vector2.RIGHT*bank)])
	facts.sections = sections
	facts.geometry = geometry
	check(sections.pond.all(func(row): return row[2]<-.015) and sections.bend.all(func(row): return row[2]<-.015),"both visible intersections lie inside authored wet bounds")
	var flat := ShaderMaterial.new()
	flat.shader = Shader.new()
	flat.shader.code = "shader_type spatial; render_mode unshaded; void fragment(){ ALBEDO=vec3(0.9,0.15,0.75); }"
	for subject: Array in [["pond",POND,4.],["bend",river,7.]]:
		demo.focus = Vector3(subject[1].x,-.02,subject[1].y)
		demo.yaw = -.65
		demo.pitch = .55
		demo.zoom = 9.
		demo._update_camera()
		demo.camera.size = subject[2]
		demo._set_light_phase(0)
		await settle()
		await capture(subject[0]+"_day")
		if "--mask" in OS.get_cmdline_user_args():
			for node: MeshInstance3D in demo.town.water_components.values(): node.material_override = flat
			await capture(subject[0]+"_intersection")
			for node: MeshInstance3D in demo.town.water_components.values(): node.material_override = demo.town.water_material
		demo._set_light_phase(2)
		await settle()
		await capture(subject[0]+"_night")
	check(demo.state.snapshot()==original and geometry_hash()==geometry,"viewing preserves authored fields and both production meshes")
	check(demo.state.save_city(OUT+"/works/shore.json").ok,"save the isolated reference work")
	if "--edit" in OS.get_cmdline_user_args(): await verify_edit(original,geometry)
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal continue save is byte-identical")
	var report := {"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SHORE_JOIN ",JSON.stringify({"checks":checks,"failures":failures,"seconds":report.seconds}))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))

func geometry_hash() -> String:
	var hashes: Array[int] = []
	for branch: Node in [demo.town.water_layer,demo.town.terrain_surface]:
		for mesh: MeshInstance3D in branch.find_children("*","MeshInstance3D",true,false):
			hashes.append(hash(mesh.mesh.surface_get_arrays(0)))
	hashes.sort()
	return var_to_bytes(hashes).hex_encode().sha256_text()

func flood_limit(center: Vector2, axis: Vector2, end: float) -> float:
	var wet := 0.
	for iteration: int in range(16):
		var test := (wet+end)*.5
		if demo.state.ground_height(center+axis*test)<Terrain.WATER_LEVEL: wet = test
		else: end = test
	return wet

func verify_edit(original: Dictionary, geometry: String) -> void:
	demo.ui_layer.show()
	demo._set_light_phase(0)
	demo.focus = Vector3(POND.x,-.02,POND.y)
	demo.yaw = -.65
	demo.zoom = 12.
	demo._update_camera()
	demo.select_tool(6)
	await settle()
	await ui_click(demo.tactile_dock.button_for("WaterMode",0))
	await settle()
	check(demo.water_kind=="pond","water dock selects the pond")
	await click_world(POND+Vector2(5.,-1.))
	await settle()
	check(demo.state.waters.size()==original.waters.size()+1 and geometry_hash()!=geometry,"native pond click publishes water and terrain")
	var painted: Array = demo.state.waters.duplicate(true)
	var painted_geometry := geometry_hash()
	await key(KEY_Z,true)
	await settle()
	check(demo.state.waters==original.waters and geometry_hash()==geometry,"native Undo restores exact earlier meshes and stroke")
	await key(KEY_Y,true)
	await settle()
	check(demo.state.waters==painted and geometry_hash()==painted_geometry,"native Redo restores the complete pond")
	check(demo.state.save_city(OUT+"/works/painted.json").ok,"save the new work to the isolated directory")
	var cold := State.new()
	check(cold.load_city(OUT+"/works/painted.json").ok,"independent cold load")
	await show(cold,POND,"再开水岸")
	check(demo.state.waters==painted and geometry_hash()==painted_geometry,"cold publication reproduces both meshes and authored strokes")
