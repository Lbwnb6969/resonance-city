extends "res://tools/check_creation_five_tools_live.gd"

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):
			OUT = arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	var started := Time.get_ticks_msec()
	var personal := FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	root.size = Vector2i(800, 540)
	Engine.max_fps = 60
	demo = Scene.instantiate()
	demo.persistence = false
	demo.collection_directory = OUT + "/works"
	root.add_child(demo)
	await ready_ui()
	isolate_input()
	var city := State.new()
	city.initialize_free()
	city.add_house(Vector2(-25, -24))
	await show(city, Vector2(-25, -24), "屋顶详情")
	await ready_ui()
	demo.select_tool(4)
	await inspect_house(Vector2i(800, 540))
	await inspect_house(Vector2i(1440, 900))
	check(personal == FileAccess.get_file_as_bytes(State.DEFAULT_PATH), "personal save bytes match")
	var report := {"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-started)/1000.}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("HOUSE_DETAIL ",JSON.stringify(report))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))


func inspect_house(size: Vector2i) -> void:
	root.size = size
	await ready_ui()
	var suffix := str(size.x)
	var before: Dictionary = demo.state.snapshot()
	await roof("h1")
	var pop: RefCounted = demo.spatial_popover
	var inspector: Node = pop.inspector
	check(pop.target_house_id == "h1", "native roof press selects house " + suffix)
	await ui_click(inspector.appearance_button)
	await ready_ui()
	check(inspector.panel.visible, "native detail button opens appearance " + suffix)
	var sheet: Rect2 = inspector.panel.get_global_rect()
	var heading: Rect2 = pop.ring.heading.get_global_rect()
	facts[suffix] = {"detail":str(sheet),"heading":str(heading)}
	check(root.get_visible_rect().grow(-4.).encloses(sheet), "every panel edge fits " + suffix)
	check(not heading.intersects(sheet), "sheet keeps the house name and details toggle exposed " + suffix)
	check(demo.state.snapshot() == before, "selection and opening details do not write to the city " + suffix)
	await capture("appearance_" + suffix)
	if "--layout-only" in OS.get_cmdline_user_args():
		pop.close()
		return
	await ui_click(inspector.purpose_button)
	await ready_ui()
	check(inspector.roles.panel.visible and not inspector.roles.batch, "single use palette opens " + suffix)
	await ui_click(inspector.roles.buttons.workshop)
	await ready_ui()
	check(demo.state.houses[0].role == "workshop", "purpose choice edits the selected house " + suffix)
	await key(KEY_Z, true)
	await ready_ui()
	check(demo.state.houses == before.houses, "Undo restores the entire house record " + suffix)
	pop.close()
