extends "res://tools/check_creation_shape_palette_live.gd"
const Fixture=preload("res://tests/test_city_creation_clockwork_rotation.gd")
func roof_arrays(id:String)->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in demo.town.house_roots[id].find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var material:=mesh.get_active_material(i)
			if material is ShaderMaterial and material.get_shader_parameter("surface_kind")==3:result.append(hash(mesh.mesh.surface_get_arrays(i)))
	result.sort()
	return result
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var solo:=Fixture.fixture();solo.remove_house("h1");await show(solo,Vector2(-23.2,-20),"独立屋面");await settle();quiet()
	var isolated:Array=roof_arrays("h2");check(not isolated.is_empty(),"actual isolated mansard GPU buffers")
	var city:=Fixture.fixture();await show(city,Vector2(-23.2,-20),"两栋接檐");await settle();quiet();demo.zoom=12.;demo._update_camera()
	var joined:Array=roof_arrays("h2");var before:Array=demo.state.houses.duplicate(true)
	check(DisplayServer.get_name()!="headless" and joined!=isolated,"native touching buildings really share roof envelope");await capture("joined")
	demo.select_tool(4);demo.selected_house="h1";demo.spatial_popover.open_for_house("h1");await key(KEY_E);await settle();quiet();demo.spatial_popover.close();demo.select_tool(-1)
	check(is_equal_approx(float(demo.state.houses[0].get("yaw",0.)),PI*.5),"native E rotates long house away")
	check(roof_arrays("h2")==isolated,"published neighbour withdraws detached roof join")
	var rotated:Array=demo.state.houses.duplicate(true);await capture("detached")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before and roof_arrays("h2")==joined,"native Undo restores exact touching roofs")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses==rotated and roof_arrays("h2")==isolated,"native Redo restores independent eave")
	var saved:Dictionary=demo.state.snapshot();var cold:=State.new();check(cold.restore(saved).ok,"independent state restores rotated city")
	await show(cold,Vector2(-23.2,-20),"冷读旋转屋面");await settle();quiet();demo.zoom=12.;demo._update_camera()
	check(demo.state.houses==rotated and roof_arrays("h2")==isolated,"cold renderer agrees with incremental independent eave");await capture("cold")
	var original_long:Array=roof_arrays("h1")
	var made:Dictionary=demo.state.add_house(Vector2(-25,-23.6));check(made.ok,"public new house touches rotated long-house end")
	if made.ok:
		demo.state.set_house_era(str(made.house_id),"clockwork");demo._after_edit(made,"house");await settle();quiet()
		check(roof_arrays("h1")!=original_long,"new neighbour refreshes rotated existing roof")
		var joined_long:Array=roof_arrays("h1");var joined_new:Array=roof_arrays(str(made.house_id));await capture("new_rotated_end_join")
		var reloaded:=State.new();check(reloaded.restore(demo.state.snapshot()).ok,"new rotated join restores independently")
		await show(reloaded,Vector2(-23.2,-20),"冷读旋转接檐");await settle();quiet()
		check(roof_arrays("h1")==joined_long and roof_arrays(str(made.house_id))==joined_new,"new join incremental and cold GPU buffers match")
		demo._after_edit(demo.state.remove_house(str(made.house_id)),"erase");await settle();quiet()
		check(roof_arrays("h1")==original_long,"removing real neighbour restores original rotated eave")
	await complete_report(personal)
