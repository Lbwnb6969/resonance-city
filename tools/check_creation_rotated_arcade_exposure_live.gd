extends "res://tools/check_creation_rotated_road_preview_live.gd"
const FixtureExposure=preload("res://tests/test_city_creation_rotated_arcade_exposure.gd")
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1280,800);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var built:=FixtureExposure.fixture(.6,2.6);check(built.ok,"public rotated neighboring houses")
	await view(built.city,"旋转邻屋",[built.focus.x,1.,built.focus.y],12.);quiet()
	var source:Dictionary=demo.state.snapshot();var plan:Array=FixtureExposure.Plan.for_house(demo.state,demo.state.houses[0]);var old:bool=FixtureExposure.old_blocked(demo.state);var hot:=building_shape()
	check(old and plan.size()==4,"exposed gap gains one actual facade")
	demo.ui_layer.hide();demo._set_light_phase(0);await capture("day");demo._set_light_phase(2);await capture("night");demo.ui_layer.show()
	check(demo.state.snapshot()==source,"view does not edit city")
	var removed:Dictionary=demo.state.remove_house("h2");demo._after_edit(removed,"house",true);await settle();quiet();await key(KEY_Z,true);await settle();quiet()
	check(FixtureExposure.Plan.for_house(demo.state,demo.state.houses[0])==plan and building_shape()==hot,"native Undo restores identical facade and GPU arrays")
	var path:=OUT+"/city.json";var cold:=State.new();check(demo.state.save_city(path).ok and cold.load_city(path).ok,"isolated save and cold load")
	await view(cold,"旋转邻屋冷读",[built.focus.x,1.,built.focus.y],12.);quiet();check(FixtureExposure.Plan.for_house(demo.state,demo.state.houses[0])==plan and building_shape()==hot,"cold result equals incremental")
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("ROTATED_ARCADE_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
