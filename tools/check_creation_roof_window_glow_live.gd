extends "res://tools/check_creation_dormer_slots_live.gd"

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()
	demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input()
	var city:RefCounted=Dormers.fixture();city.set_house_architecture_variant("h1","timber_shutters");await show(city,Vector2(-27.2,-20),"屋顶真实窗灯");quiet();focus_roof();await settle()
	for key:String in ["gable_light","shed_light"]:
		await native_dormer(key);focus_roof();await settle()
		await physical_detail()
		var house: Node3D = demo.town.house_roots.h1
		var rig: Dictionary = demo.town.resonance.rigs.h1
		var panes: Array = house.get_meta("roof_window_panes", []).filter(func(row): return row.get("source", "") == "dormer")
		var windows: Array = rig.mesh.get_meta("windows", []).filter(func(row): return row.get("source", "") == "roof" and row.get("kind", "") == "dormer")
		var pane_triangles:=0
		for pane:Dictionary in panes:pane_triangles+=pane.faces.size()/3
		var emitted_triangles:=0
		for row:Dictionary in windows:emitted_triangles+=int(row.get("triangles",0))
		check(panes.size()==1 and windows.size()==1,"actual "+key+" glass is recorded and emitted to the night rig")
		check(pane_triangles==emitted_triangles,"actual "+key+" roof-glass triangle count is preserved exactly")
		facts[key]={"recorded_panes":panes.size(),"emitted_windows":windows.size(),"triangles":emitted_triangles,"kinds":windows.map(func(row):return row.kind)}
		var before_response:Dictionary=demo.state.snapshot()
		demo.town.resonance.update({"audible":true,"lead_id":"h1","beat_pulse":1.})
		demo._set_light_phase(0);await settle();await capture(key+"_phase_0")
		demo._set_light_phase(2);await settle();await capture(key+"_phase_2")
		check(demo.state.snapshot()==before_response,"roof-window response leaves authored city unchanged for "+key)
	await native_dormer("");focus_roof();await settle()
	var automatic_root:Node3D=demo.town.house_roots.h1;var automatic_panes:Array=automatic_root.get_meta("roof_window_panes",[]);var automatic_windows:Array=demo.town.resonance.rigs.h1.mesh.get_meta("windows",[]).filter(func(row):return row.get("kind","")=="terracotta_skylight")
	check(not automatic_panes.is_empty() and not automatic_windows.is_empty(),"automatic terracotta skylight reuses its actual pane for the night rig")
	check(automatic_panes.any(func(row):return row.get("source","")=="terracotta_skylight") and automatic_windows.any(func(row):return row.get("kind","")=="terracotta_skylight"),"automatic skylight source identity remains explicit")
	check(personal==(FileAccess.get_file_as_bytes(State.DEFAULT_PATH) if FileAccess.file_exists(State.DEFAULT_PATH) else PackedByteArray()),"personal save remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"rendering":DisplayServer.get_name(),"persistence":demo.persistence};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROOF_WINDOW_GLOW_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
