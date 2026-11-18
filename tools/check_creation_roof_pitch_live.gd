extends "res://tools/check_creation_playtest_edit_live.gd"
const Pitch=preload("res://scripts/world/city_creation_roof_pitch.gd")
var control:Node
func send(at:Vector2,down:bool)->void:
	var event:=InputEventMouseButton.new();event.device=92;event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event);await process_frame
func pointer(at:Vector2,relative:Vector2=Vector2.ZERO)->void:
	var event:=InputEventMouseMotion.new();event.device=92;event.position=at;event.global_position=at;event.relative=relative;root.push_input(event);await process_frame
func open_editor()->void:
	demo.select_tool(4);demo.spatial_popover.open_for_house("h1");await settle();quiet();await ui_click(demo.spatial_popover.inspector.appearance_button);await settle()
func drag_slider(angle:float,release:bool=true)->void:
	var rect:Rect2=control.slider.get_global_rect();var start:=Vector2(rect.position.x+8.+(rect.size.x-16.)*control.slider.value/78.,rect.get_center().y)
	await pointer(start);await send(start,true)
	var end:=Vector2(rect.position.x+8.+(rect.size.x-16.)*angle/78.,rect.get_center().y)
	for i in range(1,6):await pointer(start.lerp(end,float(i)/5.),(end-start)/5.)
	if release:await send(end,false)
func meshes(renderer)->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in renderer.house_roots.h1.find_children("*","MeshInstance3D",true,false):result.append([mesh.mesh.get_faces(),mesh.transform,mesh.material_override])
	return result
func roof_faces(renderer)->PackedVector3Array:
	var result:=PackedVector3Array()
	for body:StaticBody3D in renderer.house_roots.h1.find_children("RoofPitchPick*","StaticBody3D",true,false):
		for shape:CollisionShape3D in body.get_children():result.append_array(shape.shape.get_faces())
	return result
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();control=demo.get_meta("roof_pitch_control")
	if "--bridge-only" in OS.get_cmdline_user_args():await bridge_case();await complete_report(personal);return
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",1,0,0);city.add_house(Vector2(-19,-20))
	await show(city,Vector2(-24.5,-20),"真实屋顶调坡");await settle();quiet();demo.zoom=13.;demo.yaw=.5;demo.pitch=.8;demo._update_camera();await open_editor()
	check(control.row.is_visible_in_tree() and control.handle.is_visible_in_tree() and root.get_visible_rect().encloses(control.handle.get_global_rect()),"native appearance sheet exposes slider and roof-space drag handle")
	var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(65.,false)
	check(await wait_for(func():return control.current!=null and control.current.ready,12000),"held native slider builds actual detached production preview")
	check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"continuous preview does not write any author data or history")
	await capture("pure_preview");await key(KEY_ESCAPE);await process_frame
	check(control.current==null and demo.state.snapshot()==before and demo.town.house_roots.h1.visible,"Escape retracts preview and restores exact original house")
	# Release capture after Escape, then reopen the same existing-house editor.
	await send(control.slider.get_global_rect().get_center(),false);await open_editor()
	for angle:float in [0.,15.,45.,78.]:
		before=demo.state.snapshot();depth=demo.state._undo.size();await drag_slider(angle)
		check(await wait_for(func():return not control.dragging and not control.committing,18000),"released native slider commits once "+str(angle));await settle();quiet()
		var house:Dictionary=demo.state.houses[0]
		check(house.has("roof_pitch") and absf(float(house.roof_pitch.degrees)-angle)<2. and demo.state._undo.size()==depth+1 and demo.state.houses[1]==before.houses[1],"actual one-step author transaction and unchanged neighbour "+str(angle))
		check(not roof_faces(demo.town).is_empty() and demo.town.house_roots.h1.get_meta("roof_pitch",{}).get("degrees")==house.get("roof_pitch",{}).get("degrees"),"actual pitched mesh has matching real picking geometry "+str(angle))
		await physics_frame;var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-25.7,14,-20.4),Vector3(-25.7,.5,-20.4),1))
		var source_faces:Array[Vector3]=[];source_faces.assign(roof_faces(demo.town));var expected:float=preload("res://scripts/visual/city_creation_terracotta_skylights.gd").surface_height(source_faces,Vector2(-25.7,-20.4))
		check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and absf(Vector3(hit.position).y-expected)<.10,"actual physics ray hits true changed roof height above walls "+str(angle))
		await capture("roof_"+str(angle));var actual:PackedVector3Array=roof_faces(demo.town)
		await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native Undo restores complete previous author house "+str(angle))
		await key(KEY_Y,true);await settle();quiet();check(roof_faces(demo.town)==actual,"native Redo restores identical real roof collision faces "+str(angle))
		await open_editor()
		if angle==78.:check(root.get_visible_rect().encloses(control.handle.get_global_rect()),"steep roof handle stays reachable when ridge leaves the viewport")
	check(control.backup.get("ok",false),"first format upgrade saved original city through existing collection workflow")
	var saved:Dictionary=demo.state.snapshot();var cold:=State.new();var file:=OUT+"/roof.json";var published:PackedVector3Array=roof_faces(demo.town)
	facts.backup=control.backup.duplicate(true)
	check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==saved.houses,"disk cold read retains roof recipe and all original author fields")
	await show(cold,Vector2(-24.5,-20),"屋顶冷读");await settle();quiet();check(roof_faces(demo.town)==published,"cold publication reproduces identical actual pitched mesh/collision")
	await open_editor();var at:Vector2=control.handle.get_global_rect().get_center();before=demo.state.snapshot();await pointer(at);await send(at,true)
	for i in range(1,5):await pointer(at+Vector2(0,10.*i),Vector2(0,10))
	check(control.dragging and control.desired<70. and demo.state.snapshot()==before,"roof-space native handle changes continuous preview while keeping State pure")
	await key(KEY_ESCAPE);await send(at+Vector2(0,40),false);check(demo.state.snapshot()==before,"cancel roof-space gesture preserves authored roof")
	await open_editor();at=control.handle.get_global_rect().get_center();depth=demo.state._undo.size();await pointer(at);await send(at,true)
	for i in range(1,5):await pointer(at+Vector2(0,5.*i),Vector2(0,5))
	await send(at+Vector2(0,20),false);await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet()
	check(demo.state._undo.size()==depth+1 and float(demo.state.houses[0].roof_pitch.degrees)<78. and float(demo.state.houses[0].roof_pitch.degrees)>60.,"released roof-space handle commits real continuous angle in one Undo step")
	await open_editor();await ui_click(control.reset);await settle();quiet();check(not demo.state.houses[0].has("roof_pitch"),"original roof button restores legacy recipe through real transaction")
	root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"roof controls remain reachable at 1024 width");await capture("roof_editor_1024")
	await drag_slider(45.,false);await wait_for(func():return control.current!=null and control.current.ready,12000)
	var replacement:=State.new();replacement.initialize_free();await show(replacement,Vector2(-25,-20),"换城撤回屋顶");await settle();quiet();check(not control.dragging and control.current==null and demo.state.houses.is_empty(),"changing city retracts unfinished roof preview")
	for variant:String in ["timber_row","stone_upper","raised_rotated","renaissance","concave","street_details","recessed"]:
		var sample:=State.new();sample.initialize_free();sample.add_house(Vector2(-25,-20));sample.add_cell("h1",1,0,0)
		if variant=="timber_row":sample.set_house_style("h1","timber")
		elif variant=="stone_upper":sample.set_house_style("h1","stone");sample.add_cell("h1",0,0,1)
		elif variant=="raised_rotated":sample.houses[0].base_y=1.;sample.rotate_house("h1",.35)
		elif variant=="renaissance":sample.set_house_era("h1","renaissance");sample.houses[0].erase("architecture")
		elif variant=="street_details":
			check(sample.set_house_architecture("h1","townhouse").ok and sample.set_house_chimney("h1","brick_twin_pots").ok and sample.set_house_dormer("h1","gable_light").ok and sample.set_house_architecture_variant("h1","timber_verge","gable_trim").ok,"actual street roof accepts original independent detail choices")
		elif variant=="recessed":sample.set_house_architecture("h1","recessed_townhouse")
		else:sample.add_cell("h1",0,1,0)
		check(sample.set_house_roof_pitch("h1",60.).ok,"actual ordinary roof case authoring "+variant)
		await show(sample,Vector2(-24.5,-20),variant);await settle();quiet();var faces:PackedVector3Array=roof_faces(demo.town);var actual_top:=-INF;var expected_top:=-INF
		for p:Vector3 in faces:actual_top=maxf(actual_top,p.y)
		for patch:Dictionary in demo.town.building_context.roof_patches("h1"):
			if patch.surface=="roof":
				for p:Vector3 in patch.vertices:expected_top=maxf(expected_top,p.y)
		check(not faces.is_empty() and absf(actual_top-expected_top)<.0001,"actual rendered/picked roof matches shared CPU roof in "+variant);await capture("case_"+variant)
		if variant=="street_details":
			var detail:Dictionary=demo.state.houses[0].architecture_variant.duplicate(true)
			check(not demo.town.house_roots.h1.get_meta("chimney_detail",{}).get("active",true) and demo.state.houses[0].architecture_variant==detail,"steep street roof keeps authored chimney choice dormant instead of stretching it")
			var changed:Dictionary=demo.state.set_house_roof_pitch("h1",15.);demo._after_edit(changed,"room",true,"h1");await settle();quiet()
			check(demo.town.house_roots.h1.get_meta("chimney_detail",{}).get("active",false) and demo.state.houses[0].architecture_variant==detail,"lowered roof reuses original chimney choice on actual new roof surface")
	await bridge_case()
	await complete_report(personal)

func bridge_case()->void:
	var bridges:=State.new();bridges.initialize_free();bridges.add_house(Vector2(-25,-20));bridges.add_house(Vector2(-30,-20));bridges.add_house(Vector2(-21.5,-20))
	for id:String in ["h2","h3"]:bridges.set_house_era(id,"modern_eco");bridges.add_cell(id,0,0,1);bridges.add_cell(id,0,0,2)
	bridges.set_house_skybridge_span("h3",true);await show(bridges,Vector2(-25,-20),"调坡预演真实桥廊净空");await settle();quiet();await open_editor()
	check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real existing cloud bridge clears original low roof")
	var before:Dictionary=demo.state.snapshot();await drag_slider(78.,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and float(control.current.renderer.state.houses[0].get("roof_pitch",{}).get("degrees",0.))>77.,18000),"steep roof preview completes affected neighbour roots")
	facts.bridge_preview={"ids":control.current.ids.duplicate() if control.current!=null else [],"metadata":control.current.renderer.house_roots.h2.get_meta("skybridges",[]) if control.current!=null and control.current.renderer.house_roots.has("h2") else [],"source_same":demo.state.snapshot()==before,"preview_plans":preload("res://scripts/world/city_creation_skybridge_plan.gd").for_house(control.current.renderer.state,control.current.renderer.state.houses[1]) if control.current!=null else []}
	check(control.current!=null and control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure pitched preview retracts bridge that actual new roof blocks")
	await capture("bridge_clearance_preview");await key(KEY_ESCAPE);await send(control.slider.get_global_rect().get_center(),false);check(demo.state.snapshot()==before and demo.town.house_roots.h2.visible,"cancel restores original bridge and whole city")
