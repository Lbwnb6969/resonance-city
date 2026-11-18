extends "res://tools/check_creation_shape_palette_live.gd"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();check(city.add_house(Vector2(-25,-20)).ok,"actual ordinary neoclassical house")
	city.set_house_style("h1","classic");city.set_house_era("h1","renaissance");await show(city,Vector2(-25,-20),"新古典真实窗灯");quiet();demo.zoom=8.;demo.pitch=.55;demo.yaw=-.65;demo._update_camera();await settle()
	var house:Node3D=demo.town.house_roots.h1;var panes:Array=house.get_meta("roof_window_panes",[]).filter(func(row):return row.get("source","")=="neoclassical");var rig:Dictionary=demo.town.resonance.rigs.h1;var windows:Array=rig.mesh.get_meta("windows",[]).filter(func(row):return row.get("kind","")=="neoclassical");facts={"author_house":demo.state.houses[0],"neo_nodes":house.find_children("*","Node3D",true,false).filter(func(node):return node.has_meta("neoclassical_glass")).size()}
	var pane_triangles:=0
	for pane:Dictionary in panes:pane_triangles+=pane.faces.size()/3
	var emitted_triangles:=0
	for row:Dictionary in windows:emitted_triangles+=int(row.get("triangles",0))
	check(not panes.is_empty() and not windows.is_empty(),"ordinary neoclassical glass is recorded and emitted")
	check(pane_triangles==emitted_triangles,"neoclassical glass triangle count is preserved exactly")
	facts.merge({"recorded_panes":panes.size(),"emitted_windows":windows.size(),"triangles":emitted_triangles},true)
	var before:Dictionary=demo.state.snapshot();demo._set_light_phase(0);await settle();await capture("neoclassical_phase_0");demo._set_light_phase(2);await settle();await capture("neoclassical_phase_2");check(demo.state.snapshot()==before,"neoclassical window lighting leaves authored city unchanged")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("NEO_WINDOW_GLOW_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
