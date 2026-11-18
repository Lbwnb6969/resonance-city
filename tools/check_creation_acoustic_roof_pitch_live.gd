extends "res://tools/check_creation_renaissance_roof_pitch_live.gd"
const ShellFixture=preload("res://tests/test_city_creation_acoustic_shell.gd")
const ShellPlan=preload("res://scripts/world/city_creation_acoustic_shell.gd")
var pending_isolated:=true
func preview_ready(angle:float)->bool:
	if control.pending!=null and control.pending.renderer!=null:
		for body:CollisionObject3D in control.pending.renderer.find_children("*","CollisionObject3D",true,false):pending_isolated=pending_isolated and body.collision_layer==0 and body.collision_mask==0
	return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2
func shell_focus()->void:
	demo.focus=Vector3(-27.1,2.,-19.1);demo.zoom=17.;demo.pitch=.7;demo.yaw=.55;demo._update_camera()
func physical_faces(renderer)->Array:
	var faces:Array=[];var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
	for body:StaticBody3D in house.find_children("*","StaticBody3D",true,false):
		if not str(body.name).begins_with("AcousticRoofPick") and not str(body.name).begins_with("AcousticReflectorPick"):continue
		for shape:CollisionShape3D in body.get_children():
			for p:Vector3 in shape.shape.get_faces():faces.append(inverse*shape.global_transform*p)
	return faces
func verify_shell(label:String)->void:
	var h:Dictionary=demo.state.houses[0];var data:=Pitch.Acoustic.for_house(demo.state,h);var points:Array=[]
	for patch:Dictionary in data.patches:points.append_array(patch.vertices)
	check(same_triangles(physical_faces(demo.town),points),"complete real skin ribs sides rear collision equals CPU "+label)
	var stage:Node3D=demo.town.house_roots.h1.find_child("TimberAcousticHall",true,false);var plan:Dictionary=demo.town.house_roots.h1.get_meta("acoustic_shell");var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var clear:=0
	for x:float in [-.6,0.,.6]:
		for y:float in [.55,1.1]:
			var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(stage.to_global(Vector3(x,y,float(plan.depth)*.5+.15)),stage.to_global(Vector3(x,y,float(plan.depth)*.5-.35))));clear+=int(hit.is_empty())
	check(clear==6,"all six mouth rays retain actual open stage "+label)
	var floor:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(stage.to_global(Vector3(.3,.5,float(plan.depth)*.25)),stage.to_global(Vector3(.3,.05,float(plan.depth)*.25))));check(not floor.is_empty() and floor.collider.get_meta("house_id","")=="h1","stage remains solid original-house floor "+label)
	var half:float=float(plan.width)*.5-.04;var side:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(stage.to_global(Vector3(half+.15,.55,0.)),stage.to_global(Vector3(half-.15,.55,0.))));check(not side.is_empty() and side.collider.get_meta("house_id","")=="h1" and not side.collider.get_meta("roof_surface",false),"actual side reflector remains a wall and never a roof hit "+label)
	var apex:Vector3=demo.town.house_roots.h1.get_meta("acoustic_roof_pitch").apex;var world:=Pitch.Frame.world3(h,apex);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.06,world-Vector3.UP*.06));check(not hit.is_empty() and hit.collider.get_meta("roof_surface",false) and absf(hit.position.y-world.y)<.001,"handle anchor hits real pitched skin "+label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--shell-bridge-only" in OS.get_cmdline_user_args():await shell_bridge();await modern_report(personal);return
	var city:=ShellFixture.fixture();await show(city,Vector2(-27,-19),"木壳声学亭连续调坡");shell_focus();await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var original:Dictionary=demo.state.snapshot();var old_gpu:=appearance(demo.town);var walls:=body_physics(demo.town)
	await open_editor();check(control.slider.editable and control.handle.visible,"existing native controls expose original curved shell");var anchor:Vector3=demo.town.house_roots.h1.get_meta("acoustic_original_anchor");var world:=Pitch.Frame.world3(demo.state.houses[0],anchor);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.05,world-Vector3.UP*.05));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","original handle point is on actual original shell")
	for angle:float in [0.,45.,78.]:
		await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false);check(await wait_for(func():return preview_ready(angle),18000),"detached curved timber preview ready "+str(angle))
		if control.current==null:await modern_report(personal);return
		var expected:=appearance(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"held shell preview preserves author and history "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
		check(demo.state.snapshot().schema==42 and demo.state.houses[0].roof_pitch=={"version":7,"profile":"acoustic_shell","degrees":angle} and demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==original.houses[0].cells,"native one-step schema42 retains every room "+str(angle));check(appearance(demo.town)==expected and body_physics(demo.town)==walls,"candidate and published GPU materials match and fixed base collision stays "+str(angle));verify_shell(str(angle));await capture("acoustic_"+str(int(angle)))
		if angle==0.:
			var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema42 edit really archives untouched original")
		var cold:=State.new();var file:=OUT+"/cold_"+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"schema42 actual atomic disk cold read "+str(angle));var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
		while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
		check(preview.ready and appearance(preview.renderer)==appearance(demo.town),"independent cold renderer GPU and materials equal "+str(angle));preview.clear();await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native single Undo restores exact prior shell "+str(angle));await key(KEY_Y,true);await settle();quiet()
	await roof_click();await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before,"Escape cancels shell preview");await open_editor();await ui_click(control.reset);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(demo.state.houses==original.houses and appearance(demo.town)==old_gpu,"original button restores exact original curve author GPU and materials")
	await extra_shapes();root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"controls fit 1024 viewport");await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-28,-20),"木壳预演过期撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"changing city retracts obsolete shell and all skin collisions");check(pending_isolated,"pending shell geometry never publishes live collisions");facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;await modern_report(personal)
func roof_click()->void:
	demo.spatial_popover.close();demo.select_tool(0);shell_focus();await settle();quiet();var h:Dictionary=demo.state.houses[0];var world:=Pitch.Frame.world3(h,demo.town.house_roots.h1.get_meta("acoustic_roof_pitch").apex);var at:Vector2=demo.camera.unproject_position(world);var hit:Dictionary=demo._ray_hit(at)
	for patch:Dictionary in Pitch.Acoustic.for_house(demo.state,h).patches:
		if not patch.roof_skin:continue
		for i in range(0,patch.vertices.size(),3):
			var p:Vector3=Pitch.Frame.world3(h,(patch.vertices[i]+patch.vertices[i+1]+patch.vertices[i+2])/3.);var pixel:Vector2=demo.camera.unproject_position(p);var sample:Dictionary=demo._ray_hit(pixel)
			if root.get_visible_rect().has_point(pixel) and not sample.is_empty() and sample.collider.get_meta("roof_surface",false):at=pixel;hit=sample;world=p;break
		if not hit.is_empty() and hit.collider.get_meta("roof_surface",false):break
	var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(world.x,world.z));check(not hit.is_empty() and hit.collider.get_meta("roof_surface",false) and resolved.has("cell") and resolved.cell.level==1 and resolved.cell.kind=="room" and resolved.valid,"steep real skin click means original upper room");var before:Dictionary=demo.state.snapshot();await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==1 and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"native steep shell click creates real upper room preserving slope");check(not ShellPlan.active(demo.state,demo.state.houses[0]) and not demo.town.house_roots.h1.has_meta("acoustic_roof_pitch"),"irregular added room uses honest original fallback");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and demo.town.house_roots.h1.has_meta("acoustic_roof_pitch"),"native Undo restores complete pitched shell")
func extra_shapes()->void:
	for size:Vector3i in [Vector3i(1,1,1),Vector3i(3,2,2)]:
		var city:=ShellFixture.fixture(size.x,size.y,size.z);city.set_house_roof_pitch("h1",45.);city.houses[0].base_y=1.;city.rotate_house("h1",.35);await show(city,Vector2(-27,-19),"旋转抬基多格木壳");shell_focus();await settle();quiet();verify_shell(str(size));await capture("acoustic_size_"+str(size.x));await open_editor();check(control.slider.editable and control.handle.visible,"rotated raised multi-cell shell keeps native controls "+str(size))
	demo._after_edit(demo.state.set_house_colors("h1",Color("99b3c2"),Color("db946d")),"colors");await settle();quiet();var hot:=appearance(demo.town);var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
	while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
	check(preview.ready and appearance(preview.renderer)==hot,"hot timber colors equal independent cold GPU materials");preview.clear()
func shell_bridge()->void:
	var city:=ShellFixture.fixture(1,1,1);city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-28,-20),"木壳与真实九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot();check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real nine-metre bridge clears original-height flat shell");await open_editor();await drag_slider(78.,false);check(await wait_for(func():return preview_ready(78.),18000),"shell preview prepares affected bridge roots")
	if control.current==null:return
	check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure curved shell preview retracts obstructed real bridge");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"published curved skin retracts bridge while preserving span author choice");await capture("shell_blocks_nine_metre_bridge");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores flat shell and actual cloud bridge")
