extends "res://tools/check_creation_shape_palette_live.gd"
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20))
	await show(city,Vector2(-25,-20),"新屋形状切换");await settle();quiet();demo.zoom=26.;demo._update_camera()
	check(DisplayServer.get_name()!="headless","actual native OpenGL shape selection")
	for choice:Array in [["modern_eco","chalet"],["clockwork","clock_turret"]]:
		var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size()
		await open_palette();await ui_click(palette().eras.pastoral);await process_frame;await card("style/round_tower")
		check(Brush.current(demo.state).appearance.style=="round_tower","native first chooses round tower "+choice[1])
		await ui_click(palette().eras[choice[0]]);await process_frame;await card("prototype/"+choice[1])
		check(palette().cards["prototype/"+choice[1]].active and Brush.current(demo.state).appearance.style=="classic","native explicit card replaces round shape "+choice[1])
		check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"shape browsing leaves city/history unchanged "+choice[1])
		var at:=Vector2(-29,-26);await motion(at)
		check(demo.candidate.has("new_house") and demo.candidate.get("valid",false),"valid native placement preview "+choice[1])
		await button(at,true);await button(at,false);await settle();quiet();demo.life.set_process(false)
		var h:Dictionary=demo.state.houses[-1];var built:Node3D=demo.town.house_roots[h.id]
		check(demo.state.houses.size()==2 and demo.state.houses[0]==before.houses[0] and h.get("architecture")==choice[1],"native placement preserves existing house and selects prototype "+choice[1])
		check(not built.has_meta("round_tower") and not built.find_children("*","MeshInstance3D",true,false).is_empty(),"published geometry is not round tower "+choice[1])
		check(not built.get_meta("modern_roofs",[]).is_empty() if choice[0]=="modern_eco" else not built.get_meta("clockwork_prototypes",[]).is_empty(),"published era-specific roof geometry "+choice[1])
		await capture(choice[1]);var cold:=State.new()
		check(cold.restore(demo.state.snapshot()).ok and cold.houses==demo.state.houses,"cold restore preserves new shape "+choice[1])
		await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one native Undo removes selected shape "+choice[1])
		await key(KEY_Y,true);await settle();quiet();check(demo.state.houses[-1]==h and not demo.town.house_roots[h.id].has_meta("round_tower"),"native Redo restores correct geometry "+choice[1])
		await key(KEY_Z,true);await settle();quiet()
	await complete_report(personal)
