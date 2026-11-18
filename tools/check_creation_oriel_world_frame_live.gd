extends "res://tools/check_creation_shape_palette_live.gd"
func bays()->Array:
	var result:Array=[]
	for n:Node3D in demo.town.house_roots.h1.find_children("OrielProjection","Node3D",true,false):result.append([n.global_position.x,n.global_position.y,n.global_position.z])
	return result
func street_corner()->bool:
	var points:=bays();return points.size()==1 and points[0][0]>-25. and points[0][2]>-20.
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",0,0,1)
	check(city.add_road([Vector2(-29,-17.5),Vector2(-21,-17.5)] as Array[Vector2],"path","none").ok and city.add_road([Vector2(-22.5,-24),Vector2(-22.5,-16)] as Array[Vector2],"path","none").ok,"public street corner fixture")
	check(city.set_house_era("h1","renaissance").ok and city.set_house_architecture("h1","oriel").ok,"actual eligible renaissance corner oriel")
	await show(city,Vector2(-25,-20),"转角凸窗朝向");await settle();quiet();demo.zoom=14.;demo._update_camera()
	check(DisplayServer.get_name()!="headless" and street_corner(),"native unrotated bay faces actual street corner")
	var original:Dictionary=demo.state.houses[0].duplicate(true)
	demo.select_tool(4);demo.selected_house="h1";demo.spatial_popover.open_for_house("h1");await key(KEY_E);await settle();quiet();demo.spatial_popover.close();demo.select_tool(-1)
	check(is_equal_approx(float(demo.state.houses[0].get("yaw",0.)),PI*.5),"native E rotates actual corner house")
	check(street_corner(),"rotated published bay stays on actual east/south street corner")
	facts.rotated_bay=bays();var rotated:Dictionary=demo.state.houses[0].duplicate(true);await capture("correct_street_corner")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses[0]==original and street_corner(),"native Undo restores original house and bay")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses[0]==rotated and street_corner(),"native Redo restores correctly oriented bay")
	demo._after_edit(demo.state.remove_road("r2"),"erase");await settle();quiet()
	check(bays().is_empty(),"removing one actual street withdraws derived corner bay")
	await key(KEY_Z,true);await settle();quiet();check(street_corner(),"native Undo restores street-derived bay at current yaw")
	var cold:=State.new();check(cold.restore(demo.state.snapshot()).ok,"snapshot restores into independent state")
	await show(cold,Vector2(-25,-20),"冷读街口");await settle();quiet();demo.zoom=14.;demo._update_camera()
	check(bays()==facts.rotated_bay and demo.state.houses[0]==rotated,"independent cold renderer publishes same world bay and author house")
	await capture("cold_street_corner");await complete_report(personal)
