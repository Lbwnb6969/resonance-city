extends "res://tools/check_creation_three_road_modes_live.gd"

const WEST := Vector2(-33., -28.)
const FRONT := Vector2(0., 1.25)
const UNIT := 1.8

func configure_scene() -> void:
	root.size = Vector2i(1440, 900)
	Engine.max_fps = 60
	demo = Scene.instantiate()
	demo.persistence = false
	demo.collection_directory = OUT + "/works"
	root.add_child(demo)
	await settle()
	isolate_input()

func entry_key(entry: Dictionary) -> String:
	return str(entry.cell_id) + "/" + str(entry.side)

func entry_nodes(id: String) -> Dictionary:
	var result := {}
	for wall: Node3D in demo.town.house_roots[id].find_children("Entrance_*", "Node3D", true, false):
		if wall.has_meta("entrance"):
			result[entry_key(wall.get_meta("entrance"))] = wall
	return result

func doors(city: RefCounted, id: String) -> Array:
	return city.house_entrances(id).filter(func(door): return not door.get("passage", false))

func published(city: RefCounted, id: String) -> bool:
	var entries := entry_nodes(id)
	var plans := doors(city, id)
	if entries.size() != plans.size():
		return false
	return plans.all(func(plan): return entries.has(entry_key(plan)) and entries[entry_key(plan)].get_meta("entrance") == plan)

func appearance(id: String) -> Dictionary:
	var result := {}
	for key: String in entry_nodes(id):
		var wall: Node3D = entry_nodes(id)[key]
		if wall.has_meta("timber_service_entry"):
			result[key] = wall.get_meta("timber_service_entry")
	return result

func fixture() -> RefCounted:
	var city := State.new()
	city.initialize_free()
	var rooms: Array = []
	for i in range(7):
		rooms.append({"x":i,"z":0,"level":0,"kind":"room"})
	check(city.add_house_stroke(WEST, rooms).ok and city.set_house_style("h1", "timber").ok, "author seven-bay timber row")
	var lead := WEST + Vector2(3. * UNIT, 0.)
	var street := [WEST + Vector2(-1., 4.5), WEST + Vector2(13., 4.5)] as Array[Vector2]
	check(city.add_road(street, "cobble", "none").ok, "author the parallel street")
	check(city.add_road([lead + Vector2(0., 4.5), lead + FRONT] as Array[Vector2], "cobble", "none").ok, "actual spur connects the center entrance")
	check(city.add_house(WEST + Vector2(15.5, 0.)).ok and city.set_house_style("h2", "timber").ok, "neighboring detached timber negative control")
	return city

func pictures() -> void:
	demo.ui_layer.hide()
	demo.weather_visual.hide()
	demo.focus = Vector3(-27.7, .78, -26.6)
	demo.yaw = .12
	demo.pitch = .37
	demo.zoom = 18.
	demo._update_camera()
	await capture("street_day")
	demo._set_light_phase(2)
	await capture("street_night")
	demo._set_light_phase(0)
	demo.focus = Vector3(-27.2, .88, -27.)
	demo.zoom = 9.
	demo._update_camera()
	await capture("door_detail")

func panes(id: String) -> Array:
	return demo.town.house_roots[id].get_meta("roof_window_panes", []).filter(func(row): return row.source == "timber_entry")

func check_model(city: RefCounted, x: int) -> void:
	var entries := entry_nodes("h1")
	var secondary := appearance("h1")
	var windows := panes("h1")
	var principal := doors(city, "h1").filter(func(entry): return entry.active)
	check(principal.size() == 1 and principal[0].cell_x == x, "the connected door belongs to bay " + str(x))
	if principal.size() != 1: return
	var main: Node3D = entries[entry_key(principal[0])]
	check(main.has_meta("residential_entry_gable") and main.has_meta("door_lamp") and not main.has_meta("timber_service_entry"),
		"canopy and lamp identify the real connected entry")
	check(secondary.size() == 6 and appearance("h2").is_empty(), "only six secondary doors of the row carry sidelights")
	check(doors(city, "h1").all(func(entry):
		if entry.active: return not secondary.has(entry_key(entry))
		var spec: Dictionary = secondary.get(entry_key(entry), {})
		return not spec.is_empty() and signf(spec.window_x) == signf(x - int(entry.cell_x))),
		"the casements face inward toward the connected primary")
	check(windows.size() == 6 and windows.all(func(pane):
		return secondary.has(entry_key(pane)) and pane.faces.size() == 12),
		"each casement contributes exact front and back glass triangles")
	var glow: Node = demo.town.house_roots.h1.find_child("ResonanceVisualRig", true, false)
	check(glow != null and glow.get_meta("lanterns", 0) == 1, "only the modeled primary lantern keeps a door glow")
	check(published(city, "h1") and published(city, "h2"), "all real door approach records remain exact")

func verify_edits(city: RefCounted, before: Dictionary) -> void:
	await check_picking(city)
	check_model(city, 3)
	var original := appearance("h1")
	var original_panes := panes("h1")
	var spur: Dictionary = city.roads[1]
	var removal: Dictionary = city.remove_road(spur.id)
	check(removal.ok, "remove the real spur")
	demo._after_edit(removal, "road")
	await settle()
	check(doors(city, "h1").all(func(entry): return not entry.active) and appearance("h1").size() == 6,
		"removal keeps real entrances and derives the fallback primary")
	var new_entry := WEST + Vector2(5. * UNIT, 0.)
	var built: Dictionary = city.add_road([new_entry + Vector2(0.,4.5), new_entry + FRONT] as Array[Vector2], "cobble", "none")
	check(built.ok, "connect the new primary through the same real street")
	demo._after_edit(built, "road")
	await settle()
	check_model(city, 5)
	await capture("moved_primary")
	await key(KEY_Z, true)
	await settle()
	await key(KEY_Z, true)
	await settle()
	check(city.houses == before.houses and city.roads == before.roads and appearance("h1") == original and panes("h1") == original_panes,
		"native Undo restores exact approaches and sidelight geometry")
	var file := OUT + "/city.json"
	var cold := State.new()
	check(city.save_city(file).ok and cold.load_city(file).ok, "isolated disk round trip")
	await show(cold, WEST + Vector2(5.4, 1.), "木构连屋冷读")
	check(appearance("h1") == original and panes("h1") == original_panes and published(demo.state, "h1"),
		"independent cold publish reproduces the same entrance geometry")

func check_picking(city: RefCounted) -> void:
	await physics_frame
	for entry: Dictionary in doors(city, "h1"):
		var along := Vector3(entry.outward.x,0.,entry.outward.y)
		var at := Vector3(entry.wall_at.x, float(city.houses[0].base_y) + .85, entry.wall_at.y)
		var ray := PhysicsRayQueryParameters3D.create(at + along * .65, at - along * .32)
		var hit: Dictionary = demo.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider.get_meta("house_id", "") == "h1" and hit.collider.get_meta("cell_id", "") == entry.cell_id,
			"front picking selects original room " + str(entry.cell_id))

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			OUT = arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var began := Time.get_ticks_msec()
	var personal := FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	DirAccess.make_dir_recursive_absolute(OUT)
	await configure_scene()
	var city := fixture()
	await show(city, WEST + Vector2(5.4, 1.), "木构连屋立面")
	quiet()
	city = demo.state
	var before: Dictionary = city.snapshot()
	var plans := doors(city, "h1")
	check(plans.size() == 7 and plans.filter(func(door): return door.active).size() == 1, "seven actual door approaches with one connected")
	check(published(city, "h1") and published(city, "h2"), "visible entries exactly follow published approach records")
	await pictures()
	check(demo.state.snapshot() == before, "viewing the facade does not author the city")
	if not "--baseline" in OS.get_cmdline_user_args():
		await verify_edits(city, before)
	check(personal == FileAccess.get_file_as_bytes(State.DEFAULT_PATH), "personal save stays byte-identical")
	var result := {"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(OUT + "/report.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("TIMBER_ROW ", JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(int(not result.ok))
