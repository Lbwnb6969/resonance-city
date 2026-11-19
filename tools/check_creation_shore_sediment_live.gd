extends "res://tools/check_creation_shore_join_live.gd"

const OLD_CITY := "res://数据/地貌河湾样例.json"
const OLD_POND := Vector2(12.,7.8)

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="): OUT = arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var began := Time.get_ticks_msec()
	var personal := FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var source := FileAccess.get_file_as_bytes(OLD_CITY)
	var old: Dictionary = JSON.parse_string(source.get_string_from_utf8())
	var city := State.new()
	check(old.schema==2 and city.restore(old).ok,"restore the original schema 2 sculpted city")
	DirAccess.make_dir_recursive_absolute(OUT+"/works")
	root.size = Vector2i(1440,900)
	Engine.max_fps = 60
	demo = Scene.instantiate()
	demo.persistence = false
	demo.start_empty = true
	demo.collection_directory = OUT+"/works"
	root.add_child(demo)
	await settle()
	isolate_input()
	await show(city,OLD_POND,"旧池浅沙")
	quiet()
	demo.ui_layer.hide()
	demo.weather_visual.hide()
	demo.town.wildlife.hide()
	demo.town.clear_preview()
	for material: Material in demo.town.foliage._materials.values():
		if material is ShaderMaterial: material.set_shader_parameter("wind_time_override",0.)
	for part: String in ["grass","lawn"]:
		demo.town.meadow.materials[part].set_shader_parameter("meadow_time_override",0.)
	var author: Dictionary = demo.state.snapshot()
	var geometry := geometry_hash()
	var materials: Array[ShaderMaterial] = [demo.town.ground_material,demo.town.water_material]
	for part: String in ["grass","lawn"]: materials.append(demo.town.meadow.materials[part])
	if demo.town.path_edge.material!=null: materials.append(demo.town.path_edge.material)
	check(materials.all(func(material): return material!=null and material.get_shader_parameter("bank_sand_enabled") and material.get_shader_parameter("bank_sand")==materials[0].get_shader_parameter("bank_sand")),"active shore materials share the production sand")
	for view: Array in [["overhead",Vector3(12.4,.2,8.8),8.,1.35,.62],["street",Vector3(12.4,.2,8.8),13.,.78,.62],["river",Vector3(5.,-.1,-16.),11.,.35,-.3]]:
		demo.focus = view[1]
		demo.zoom = view[2]
		demo.pitch = view[3]
		demo.yaw = view[4]
		demo._update_camera()
		demo._set_light_phase(0)
		await settle()
		await capture(view[0]+"_day")
		if view[0]=="overhead":
			demo.sun.shadow_enabled = false
			await settle()
			await capture("overhead_no_shadows")
			demo.sun.shadow_enabled = true
			for material: ShaderMaterial in materials: material.set_shader_parameter("bank_sand_enabled",false)
			await settle()
			await capture("overhead_no_sand")
			for material: ShaderMaterial in materials: material.set_shader_parameter("bank_sand_enabled",true)
		demo._set_light_phase(2)
		await settle()
		await capture(view[0]+"_night")
	check(demo.state.snapshot()==author and geometry_hash()==geometry,"sand and lighting probes do not edit the city or published meshes")
	facts.geometry = geometry
	facts.original_sha256 = FileAccess.get_sha256(OLD_CITY)
	facts.authored_sha256 = JSON.stringify(author,"",true,true).sha256_text()
	if "--verify-use" in OS.get_cmdline_user_args(): await verify_fresh_bank()
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and source==FileAccess.get_file_as_bytes(OLD_CITY),"personal save and original sample bytes unchanged")
	var report := {"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SHORE_SEDIMENT ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))

func verify_fresh_bank() -> void:
	var city := State.new()
	city.initialize_free()
	check(city.add_water([POND] as Array[Vector2],2.,"pond").ok,"author the reference pond")
	check(city.add_road([POND+Vector2(-3.,1.75),POND+Vector2(3.,1.75)] as Array[Vector2],"path","none").ok,"author an ordinary close-bank path")
	await show(city,POND,"水边小径")
	quiet()
	demo.ui_layer.hide()
	demo.town.wildlife.hide()
	demo._set_light_phase(0)
	var road: Node3D = demo.town.road_roots.get("r1")
	var edge := road.get_node_or_null("SoftRoadEdge") as MeshInstance3D if road!=null else null
	var material := edge.material_override as ShaderMaterial if edge!=null else null
	check(material!=null and material.get_shader_parameter("bank_sand_enabled") and material.get_shader_parameter("bank_sand")==demo.town.ground_material.get_shader_parameter("bank_sand"),"native road feather takes the same sand texture")
	demo.focus = Vector3(POND.x,-.02,POND.y)
	demo.yaw = -.65
	demo.pitch = .72
	demo.zoom = 9.
	demo._update_camera()
	await settle()
	await capture("path_beside_pond")
	await verify_edit(demo.state.snapshot(),geometry_hash())
