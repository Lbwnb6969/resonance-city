extends "res://tools/check_creation_neoclassical_window_glow_live.gd"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",0,0,1);city.add_road([Vector2(-29,-17.5),Vector2(-21,-17.5)] as Array[Vector2],"path","none");city.add_road([Vector2(-22.5,-24),Vector2(-22.5,-16)] as Array[Vector2],"path","none");city.set_house_era("h1","renaissance");city.set_house_architecture("h1","oriel");await show(city,Vector2(-25.,-20.),"转角凸窗真实玻璃窗灯");quiet();demo.focus=Vector3(-25.,1.,-20.);demo.zoom=8.;demo.pitch=.58;demo.yaw=-.65;demo._update_camera();await settle()
	var house:Node3D=demo.town.house_roots.h1
	var panes:Array=house.get_meta("roof_window_panes",[]).filter(func(row):return row.get("source","")=="corner_oriel")
	var rig:Dictionary=demo.town.resonance.rigs.h1
	var windows:Array=rig.mesh.get_meta("windows",[]).filter(func(row):return row.get("kind","")=="corner_oriel")
	var pane_triangles:=0
	for pane:Dictionary in panes:pane_triangles+=pane.faces.size()/3
	var emitted_triangles:=0
	for row:Dictionary in windows:emitted_triangles+=int(row.get("triangles",0))
	facts={"recorded_panes":panes.size(),"emitted_windows":windows.size(),"recorded_triangles":pane_triangles,"emitted_triangles":emitted_triangles,"oriel_nodes":house.find_children("FacetedBayGlazing","MeshInstance3D",true,false).size()}
	check(not panes.is_empty() and not windows.is_empty(),"corner oriel actual glazing is recorded and emitted")
	check(pane_triangles==emitted_triangles,"corner oriel recorded and emitted triangle counts match")
	var before:Dictionary=demo.state.snapshot();demo._set_light_phase(0);await settle();await capture("corner_oriel_phase_0");demo._set_light_phase(2);await settle();await capture("corner_oriel_phase_2")
	check(demo.state.snapshot()==before,"corner oriel window lighting leaves authored city unchanged")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("CORNER_ORIEL_WINDOW_GLOW_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
