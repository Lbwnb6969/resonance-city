extends "res://tools/check_creation_shape_palette_live.gd"
const Fixture=preload("res://tools/fixtures/city_creation_layered_window_fixture.gd")

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var fixture:=Fixture.build("renaissance",.4,true,1,false);check(fixture.ok,"actual ordinary recessed townhouse fixture")
	await show(fixture.city,Vector2(-28,-20),"深窗真实玻璃窗灯");quiet();demo.zoom=8.;demo.pitch=.55;demo.yaw=-.65;demo._update_camera();await settle()
	var house:Node3D=demo.town.house_roots.h1
	var panes:Array=house.get_meta("roof_window_panes",[]).filter(func(row):return row.get("source","")=="layered")
	var rig:Dictionary=demo.town.resonance.rigs.h1
	var windows:Array=rig.mesh.get_meta("windows",[]).filter(func(row):return row.get("kind","")=="layered")
	var pane_triangles:=0
	for pane:Dictionary in panes:pane_triangles+=pane.faces.size()/3
	var emitted_triangles:=0
	for row:Dictionary in windows:emitted_triangles+=int(row.get("triangles",0))
	facts={"recorded_panes":panes.size(),"emitted_windows":windows.size(),"recorded_triangles":pane_triangles,"emitted_triangles":emitted_triangles}
	check(not panes.is_empty() and not windows.is_empty(),"layered actual glass is recorded and emitted")
	check(panes.size()==windows.size() and pane_triangles==emitted_triangles,"layered glass pane count and triangle count are preserved exactly")
	var before:Dictionary=demo.state.snapshot();demo._set_light_phase(0);await settle();await capture("layered_window_phase_0");demo._set_light_phase(2);await settle();await capture("layered_window_phase_2")
	check(demo.state.snapshot()==before,"layered window lighting leaves authored city unchanged")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("LAYERED_WINDOW_GLOW_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
