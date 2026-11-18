extends "res://tools/check_creation_shape_palette_live.gd"
func camera_view()->Dictionary:
	return {"focus":demo.focus,"yaw":demo.yaw,"pitch":demo.pitch,"zoom":demo.zoom}
func open_card(id:String)->void:
	var panel=demo.gallery.panel
	panel.scroll.ensure_control_visible(panel.open_buttons[id]);await process_frame;await process_frame
	await ui_click(panel.open_buttons[id]);await settle();quiet();demo.life.set_process(false)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var target:=State.new();target.initialize_free();check(target.add_house(Vector2(-33,-25)).ok,"public target city")
	await show(target,Vector2(-33,-25),"目标河湾");await settle();quiet();demo.zoom=24.;demo.yaw=.63;demo.pitch=.72;demo._update_camera()
	var target_view:=camera_view();var target_houses:Array=demo.state.houses.duplicate(true)
	await key(KEY_O,true);demo.gallery.panel.title_input.text="目标河湾";await ui_click(demo.gallery.panel.save_button);await settle()
	var id:String=demo.gallery.last_saved_id;check(not id.is_empty() and demo.gallery.library.read(id).ok,"native save creates immutable target card")
	await key(KEY_ESCAPE)
	var source:=State.new();source.initialize_free();check(source.add_house(Vector2(-22,-18)).ok,"public different source city")
	await show(source,Vector2(-24,-18),"漫步原城");await settle();quiet();demo.zoom=16.;demo.yaw=-.3;demo.pitch=.9;demo._update_camera()
	var source_view:=camera_view();var source_houses:Array=demo.state.houses.duplicate(true);var depth:int=demo.state._undo.size()
	await key(KEY_V);check(DisplayServer.get_name()!="headless" and demo.camera_rig.strolling and demo.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"native V enters source street view")
	var walking_view:=camera_view()
	await demo.gallery._open_chosen({"ok":false,"message":"无效作品"})
	check(demo.camera_rig.strolling and camera_view()==walking_view and demo.state.houses==source_houses,"failed open preserves original street view and city")
	await key(KEY_O,true);check(demo.gallery.panel.visible,"native Ctrl O opens collection while strolling")
	await ui_click(demo.gallery.panel.close_button)
	check(demo.camera_rig.strolling and camera_view()==walking_view,"closing collection resumes same street camera")
	await key(KEY_O,true);await open_card(id)
	check(demo.gallery.last_opened_id==id and demo.state.houses==target_houses,"native target card replaces source world")
	check(not demo.camera_rig.strolling and demo.camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"opened work returns to actual creative overview")
	check(camera_view()==target_view,"opened camera uses target saved overview")
	var checkpoint:Dictionary=demo.gallery.library.read(demo.gallery.last_auto_id)
	check(checkpoint.ok and checkpoint.world.houses==source_houses and checkpoint.view.focus==[source_view.focus.x,source_view.focus.y,source_view.focus.z] and is_equal_approx(float(checkpoint.view.zoom),source_view.zoom),"switch checkpoint preserves source city and its original overview")
	await capture("opened_target")
	await key(KEY_V);check(demo.camera_rig.strolling and demo.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"first V in target starts its own street view")
	await key(KEY_V);check(not demo.camera_rig.strolling and camera_view()==target_view,"second V restores target view without previous-city camera leak")
	check(demo.state.houses==target_houses and demo.state._undo.size()==depth,"camera navigation leaves target author history unchanged")
	var point:=Vector2(-30,-27);await motion(point);await button(point,true);await button(point,false);await settle();quiet()
	check(demo.state.houses.size()==target_houses.size()+1 and demo.state.houses[0]==target_houses[0],"real pointer builds one new house in reopened creative view")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==target_houses,"native Undo removes new house while retaining opened work")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses.size()==target_houses.size()+1,"native Redo restores post-switch house")
	facts.seconds=(Time.get_ticks_msec()-began)/1000.;facts.source_view=str(source_view);facts.target_view=str(target_view)
	await complete_report(personal)
