extends "res://tools/check_creation_rotated_road_preview_live.gd"
const FixtureClear=preload("res://tests/test_city_creation_rotated_street_clearance.gd")
const OldClear=preload("res://tests/fixtures/regression_baselines/rotated_clearance_baseline.gd")
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var built:=FixtureClear.fixture(.6,3.5);check(built.ok,"public rotated house and avenue")
	await view(built.city,"街具与旋转屋",[built.focus.x,.7,built.focus.y],20.);quiet();demo.ui_layer.hide();demo.weather_visual.hide()
	var road:Dictionary=demo.state.roads[0];var parent:Node3D=demo.town.road_roots[road.id];var actual:Node3D=parent.get_node("PromenadeDetails")
	var records:Array=actual.get_meta("records");var old:=OldClear.new();var old_records:Array=old.prepare(demo.town,road)
	check(records.size()>old_records.size(),"real installed avenue restores missing clear furniture")
	var saved:Dictionary=demo.state.snapshot();var backup:=Node3D.new();parent.add_child(backup);old.install(demo.town,backup,old_records)
	for phase:int in [0,2]:
		demo._set_light_phase(phase)
		for stage:String in ["before","after"]:
			actual.visible=stage=="after";backup.visible=stage=="before"
			for i:int in range(20):await process_frame
			await capture(stage+"_"+str(phase))
	backup.queue_free();actual.show();demo.ui_layer.show()
	check(demo.state.snapshot()==saved,"view comparison leaves authored city unchanged")
	var original:Array=records.duplicate(true);demo._after_edit(demo.state.rotate_house("h1",0.),"room",true,"h1");await settle();quiet()
	await key(KEY_Z,true);await settle();quiet()
	check(demo.town.road_roots[road.id].get_node("PromenadeDetails").get_meta("records")==original,"native Undo publishes identical rotated street records")
	var path:=OUT+"/city.json";var cold:=State.new();check(demo.state.save_city(path).ok and cold.load_city(path).ok,"isolated save and cold load")
	await view(cold,"街具冷读",[built.focus.x,.7,built.focus.y],20.);quiet()
	check(demo.town.road_roots[road.id].get_node("PromenadeDetails").get_meta("records")==original,"cold renderer reproduces exact street records")
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"old_records":old_records.size(),"new_records":records.size()}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROTATED_STREET_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
