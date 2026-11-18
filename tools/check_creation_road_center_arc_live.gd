extends "res://tools/check_creation_playtest_edit_live.gd"
func circle_ok(a:Vector2,c:Vector2)->bool:
	if demo.road_preview.size()<5:return false
	for p:Vector2 in demo.road_preview:
		if absf(p.distance_to(c)-a.distance_to(c))>.00005:return false
	return true
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();road_tool=demo.get_meta("road_tool")
	var city:=State.new();city.initialize_free();var old:Array[Vector2]=[Vector2(-32,-27),Vector2(-28,-27)];city.add_road(old)
	await show(city,Vector2(-23,-20),"圆心曲路");await settle();quiet();demo.zoom=25.;demo.yaw=0.;demo.pitch=1.;demo._update_camera();demo.select_tool(2)
	var a:=Vector2(-26,-24);var c:=Vector2(-26,-20);var end:=Vector2(-20,-20)
	var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size()
	await key(KEY_3);await click_world(a);await motion(c);await process_frame
	check(road_tool.phase=="control" and not road_tool.pressed and demo.state.snapshot()==before,"first native click releases before centre choice without editing")
	check(demo.road_preview.size()<2 and "圆心" in road_tool.guide.hint.text,"radius guide does not paint the centre line as road")
	await click_world(c);await motion(end);await process_frame
	check(road_tool.phase=="end" and not road_tool.pressed and road_tool.control.distance_to(c)<.0001,"second native click fixes actual chosen centre and releases")
	check(circle_ok(a,c) and absf(road_tool.ruler.radius-4.)<.0001 and absf(rad_to_deg(road_tool.ruler.turn)-90.)<.001,"mouse endpoint is projected onto a true fixed-radius quarter-circle")
	check("R 4.00m" in road_tool.guide.hint.text and "90.0°" in road_tool.guide.hint.text and demo.state.snapshot()==before and demo.state._undo.size()==depth,"real radius/sweep shown while preview remains pure")
	await capture("released_circle_preview")
	var promised:Array=demo.road_preview.duplicate();await button(end,true);await button(end,false);await settle();quiet()
	check(demo.state.roads.size()==2 and exact(promised) and demo.state.roads[0]==before.roads[0],"third native click publishes exact promised circle and preserves old road")
	await key(KEY_Z,true);await settle();check(demo.state.roads==before.roads,"one native Undo removes entire circle")
	await key(KEY_Y,true);await settle();check(exact(promised),"one native Redo restores exact circle")
	await capture("committed_circle")
	for cancel_mode:String in ["escape","tool","tab"]:
		demo.select_tool(2);road_tool.set_mode(2);before=demo.state.snapshot();depth=demo.state._undo.size();await click_world(a);await click_world(c);await motion(end)
		if cancel_mode=="escape":await key(KEY_ESCAPE)
		elif cancel_mode=="tool":demo.select_tool(5)
		else:await key(KEY_TAB);check(road_tool.effective==1,"Tab changes in-progress circle to straight mode");await key(KEY_ESCAPE)
		await process_frame;check(not road_tool.active() and demo.state.snapshot()==before and demo.state._undo.size()==depth,"native cancel/switch preserves all existing roads "+cancel_mode)
	# Continue the pointer around the centre after releasing, including a major arc.
	demo.select_tool(2);road_tool.set_mode(2);await click_world(a);await click_world(c)
	for degrees:float in [60.,120.,180.,240.,270.]:await motion(c+(a-c).rotated(deg_to_rad(degrees)));await process_frame
	check(not road_tool.pressed and absf(rad_to_deg(road_tool.ruler.turn)-270.)<.001 and circle_ok(a,c),"released pointer supports continuous major arc beyond 180 degrees")
	await capture("major_arc_preview");await key(KEY_ESCAPE)
	demo.select_tool(2);road_tool.set_mode(1);before=demo.state.snapshot();await click_world(Vector2(-30,-15));await motion(Vector2(-20,-15))
	check(not road_tool.pressed and road_tool.phase=="end" and demo.state.snapshot()==before,"two-click straight preview works after releasing first click")
	promised=demo.road_preview.duplicate();await click_world(Vector2(-20,-15));await settle();quiet();check(demo.state.roads.size()==before.roads.size()+1 and exact(promised),"second native click commits exact straight road")
	var saved:Dictionary=demo.state.snapshot();var cold:=State.new();var file:=OUT+"/roads.json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.roads==saved.roads,"actual saved point lists cold read without reinterpreting old roads")
	# Gallery switch retracts unfinished circle and its guide.
	road_tool.set_mode(2);await click_world(a);await click_world(c);await motion(end)
	var replacement:=State.new();replacement.initialize_free();await show(replacement,Vector2(-23,-20),"换城撤回圆弧");await settle();quiet()
	check(not road_tool.active() and demo.state.roads.is_empty() and not road_tool.guide.root.visible,"changing city retracts unfinished circle and guide")
	await complete_report(personal)
