extends "res://tools/check_creation_bridge_discovery_live.gd"
const Rotated=preload("res://tests/test_city_creation_rotated_road_preview.gd")
func motion(at:Vector2,alt:bool=true)->void:
	var event:=InputEventMouseMotion.new();event.device=92;event.position=screen(at);event.global_position=event.position;event.alt_pressed=alt;root.push_input(event,true);await process_frame
func button(at:Vector2,pressed:bool,index:int=MOUSE_BUTTON_LEFT)->void:
	var event:=InputEventMouseButton.new();event.device=92;event.position=screen(at);event.global_position=event.position;event.pressed=pressed;event.button_index=index;event.alt_pressed=true;root.push_input(event,true);await process_frame
func frontage()->Array:
	var rows:Array=[]
	for face:Dictionary in Rotated.Arcade.for_house(demo.state,demo.state.houses[0]):rows.append(Shape.arcade(demo.state.houses[0],face))
	return rows
func building_shape()->String:
	var rows:Array=[]
	for node:MeshInstance3D in demo.town.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		if node.mesh!=null:
			for surface:int in range(node.mesh.get_surface_count()):rows.append(var_to_bytes(node.mesh.surface_get_arrays(surface)).hex_encode().sha256_text())
	rows.sort();return var_to_bytes(rows).hex_encode().sha256_text()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
	var built:=Rotated.fixture(PI*.5);check(built.ok,"public rotated long building")
	await view(built.city,"Rotated long house",[built.focus.x,1.,built.focus.y],21.)
	var before:Dictionary=demo.state.snapshot();var old_shape:=building_shape();var depth:int=demo.state._undo.size()
	demo.select_tool(2);demo.road_style="promenade";demo.road_size=1;road_tool.set_mode(1)
	demo.select_tool(2);root.grab_focus();await create_timer(.5).timeout
	await motion(built.points[0]);await button(built.points[0],true);await button(built.points[0],false)
	await motion(built.points[1])
	check(await wait_for(func():return ghosts().any(func(r):return r.kind=="arcade"),3500),"actual pointer preview discovers rotated far-end arcade")
	var promised:Array=ghosts().filter(func(r):return r.kind=="arcade").duplicate(true)
	check(not promised.is_empty() and demo.state.snapshot()==before and demo.state._undo.size()==depth,"real preview does not mutate city/history")
	await capture("rotated_end_preview")
	await key(KEY_ESCAPE);check(demo.state.snapshot()==before and building_shape()==old_shape,"Escape cancels real preview and leaves building intact")
	demo.select_tool(2);root.grab_focus();await create_timer(.5).timeout
	await motion(built.points[0]);await button(built.points[0],true);await button(built.points[0],false)
	await motion(built.points[1])
	check(await wait_for(func():return ghosts().any(func(r):return r.kind=="arcade"),3500),"repeated pointer preview returns")
	promised=ghosts().filter(func(r):return r.kind=="arcade").duplicate(true)
	await button(built.points[1],true);await button(built.points[1],false);await settle();quiet();demo.life.set_process(false)
	check(frontage()==promised and demo.state.roads.size()==1 and demo.state._undo.size()==depth+1,"one actual click transaction produces exactly promised arcade")
	var hot:=building_shape();await capture("rotated_end_committed")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.roads.is_empty() and building_shape()==old_shape,"native Undo restores exact original building arrays")
	await key(KEY_Y,true);await settle();quiet();check(frontage()==promised and building_shape()==hot,"native Redo restores precise frontage and arrays")
	var path:=OUT+"/city.json";var cold:=State.new();check(demo.state.save_city(path).ok and cold.load_city(path).ok,"isolated disk roundtrip")
	await view(cold,"Rotated arcade cold",[built.focus.x,1.,built.focus.y],21.)
	check(frontage()==promised and building_shape()==hot,"independent cold construction exactly matches incremental")
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"frontage":promised,"scope":"Actual rotated-building road gesture/ghost/commit/cancel/UndoRedo/cold mesh equality. No music or schema change."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROTATED_ROAD_PREVIEW_LIVE ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures,"seconds":report.seconds}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
