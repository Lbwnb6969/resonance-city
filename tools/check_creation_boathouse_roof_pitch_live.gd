extends "res://tools/check_creation_renaissance_roof_pitch_live.gd"
const BoatFixture=preload("res://tests/test_city_creation_boathouse.gd")
const BoatPlan=preload("res://scripts/world/city_creation_boathouse_plan.gd")
var pending_isolated:=true
func preview_ready(angle:float)->bool:
	if control.pending!=null and control.pending.renderer!=null:
		for body:CollisionObject3D in control.pending.renderer.find_children("*","CollisionObject3D",true,false):pending_isolated=pending_isolated and body.collision_layer==0 and body.collision_mask==0
	return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2
func boat_focus()->void:
	demo.focus=Vector3(-28,1.,-18.7);demo.zoom=10.;demo.pitch=.7;demo.yaw=.48;demo._update_camera()
func verify_boat(label:String)->void:
	var h:Dictionary=demo.state.houses[0];var points:Array=[]
	for patch:Dictionary in Pitch.patches(demo.state,h):
		if patch.surface=="roof":points.append_array(patch.vertices)
	check(same_triangles(actual_clock_faces(demo.town),points),"main and slip roof actual picking triangles match CPU "+label)
	var dock:Node3D=demo.town.house_roots.h1.find_child("CreekBoathouseDock",true,false);var plan:=BoatPlan.find(demo.state,"h1");var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state
	check(dock!=null and not plan.is_empty(),"actual dock remains derived "+label)
	if dock==null:return
	for x:float in [-.8,.8]:
		var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(dock.to_global(Vector3(x,.4,1.)),dock.to_global(Vector3(x,-.12,1.))))
		check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","real narrow pier collider remains "+str(x)+label)
	var gap:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(dock.to_global(Vector3(.48,.2,1.2)),dock.to_global(Vector3(.48,-.35,1.2))))
	check(gap.is_empty(),"central slot remains real water "+label)
	var boat:Node3D=dock.find_child("MooredWoodenSkiff",true,false)
	check(absf(boat.global_position.y-float(demo.state.Terrain.WATER_LEVEL))<.00001,"boat stays at true water datum "+label)
	var y:=Pitch.Boathouse.ridge(h);var x:=.16;var expected:=1.64+(y-1.64)*(1.-x/1.08)
	var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(dock.to_global(Vector3(x,expected+.08,1.)),dock.to_global(Vector3(x,expected-.08,1.))))
	check(not hit.is_empty() and hit.collider.get_meta("roof_surface",false) and hit.collider.get_meta("cell_id","")==plan.cell_id and absf(hit.position.y-dock.to_global(Vector3(x,expected,1.)).y)<.001,"true pitched canopy hit marked as roof and retains original room "+label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--boat-bridge-only" in OS.get_cmdline_user_args():await boat_bridge();await modern_report(personal);return
	if "--steep-only" in OS.get_cmdline_user_args():
		var sample:=BoatFixture.fixture();sample.set_house_roof_pitch("h1",78.);await show(sample,Vector2(-28,-19),"陡船坞诊断");await steep_clicks();await modern_report(personal);return
	var city:=BoatFixture.fixture();await show(city,Vector2(-28,-19),"船坞连续调坡");boat_focus();await settle();quiet();var original:Dictionary=demo.state.snapshot();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var original_gpu:=appearance(demo.town);var walls:=body_physics(demo.town)
	await open_editor();var anchor:=preload("res://scripts/visual/city_creation_boathouse.gd").anchor(demo.town.house_roots.h1);var world:=Pitch.Frame.world3(demo.state.houses[0],anchor);var anchor_hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.05,world-Vector3.UP*.05));check(not anchor_hit.is_empty() and anchor_hit.collider.get_meta("house_id","")=="h1","original main roof handle anchor lies on actual roof")
	for angle:float in [0.,45.,78.]:
		await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();check(control.slider.editable and control.handle.visible,"native existing roof controls available "+str(angle));await drag_slider(angle,false)
		check(await wait_for(func():return preview_ready(angle),18000),"detached full boathouse preview completes "+str(angle))
		if control.current==null:await modern_report(personal);return
		var expected:=appearance(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"held preview preserves author data and history "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
		check(demo.state.snapshot().schema==41 and demo.state.houses[0].roof_pitch=={"version":6,"profile":"boathouse","degrees":angle} and demo.state._undo.size()==depth+1,"one native schema41 transaction "+str(angle));check(appearance(demo.town)==expected and body_physics(demo.town)==walls,"preview and publication GPU/materials match and original walls stay "+str(angle));verify_boat(str(angle));await capture("boathouse_"+str(int(angle)))
		if angle==0.:
			var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema41 edit really archives exact original city")
		var cold:=State.new();var file:=OUT+"/cold_"+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"actual schema41 disk cold read "+str(angle));var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
		while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
		check(preview.ready and appearance(preview.renderer)==appearance(demo.town),"independent cold production GPU and materials match "+str(angle));preview.clear();await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native one-step Undo "+str(angle));await key(KEY_Y,true);await settle();quiet()
	await steep_clicks()
	await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before,"Esc cancels held slip/main roof preview")
	await open_editor();await ui_click(control.reset);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(demo.state.houses==original.houses and appearance(demo.town)==original_gpu,"original button restores exact original author data GPU and materials")
	city=BoatFixture.fixture();city.set_house_roof_pitch("h1",45.);await show(city,Vector2(-28,-19),"船坞收水退出");boat_focus();await settle();quiet();before=demo.state.snapshot();demo._after_edit(demo.state.remove_water_at(Vector2(-28,-17.7)),"water");await settle();quiet();check(BoatPlan.find(demo.state,"h1").is_empty() and demo.town.house_roots.h1.find_child("CreekBoathouseDock",true,false)==null and demo.state.houses==before.houses,"real fill-water withdraws derived dock only and retains authored pitch");await key(KEY_Z,true);await settle();quiet();verify_boat("water Undo")
	demo._after_edit(demo.state.set_house_colors("h1",Color("99b3c2"),Color("db946d")),"colors");await settle();quiet();var hot:=appearance(demo.town);var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
	while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
	check(preview.ready and appearance(preview.renderer)==hot,"actual hot chosen colors equal independent cold GPU and materials");preview.clear()
	root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"controls reachable at 1024");await drag_slider(78.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-28,-20),"船坞预演撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"changing city withdraws obsolete main and canopy preview")
	check(pending_isolated,"unfinished detached geometry never publishes active collisions")
	facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;await modern_report(personal)

func steep_clicks()->void:
	for target:String in ["main","canopy"]:
		demo.spatial_popover.close();demo.select_tool(0);boat_focus();demo.zoom=17.;demo._update_camera();await settle();quiet()
		var h:Dictionary=demo.state.houses[0];var local:=preload("res://scripts/visual/city_creation_boathouse.gd").anchor(demo.town.house_roots.h1);var at:=Pitch.Frame.world3(h,local)
		if target=="canopy":
			var dock:Node3D=demo.town.house_roots.h1.find_child("CreekBoathouseDock",true,false);var y:=Pitch.Boathouse.ridge(h);at=dock.to_global(Vector3(.12,1.64+(y-1.64)*(1.-.12/1.08),1.))
		var screen_at:Vector2=demo.camera.unproject_position(at);var hit:Dictionary=demo._ray_hit(screen_at);var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(at.x,at.z));facts["steep_"+target]={"at":at,"screen":screen_at,"hit":str(hit),"meta":hit.collider.get_meta_list() if not hit.is_empty() else [],"resolved":resolved};check(not hit.is_empty() and preload("res://scripts/ui/city_creation_unified_build.gd")._roof_hit(hit,hit.collider) and resolved.has("cell") and resolved.cell.level==1 and resolved.cell.kind=="room" and resolved.valid,"actual steep "+target+" hit resolves original shore room upper floor")
		var before:Dictionary=demo.state.snapshot();await pointer(screen_at);await send(screen_at,true);await send(screen_at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==1 and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"native steep "+target+" roof click adds real upper room retaining author slope");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native steep "+target+" add-floor Undo restores exact dock source")

func boat_bridge()->void:
	var city:=State.new();city.initialize_free();city.add_water([Vector2(-29,-17.7),Vector2(-27,-17.7)] as Array[Vector2],2.4,"pond");BoatFixture.Brush.select(city,"pastoral",BoatPlan.ID);city.add_house(Vector2(-28,-20));city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:
		var h:Dictionary=city.houses[city._house_index(id)];h.origin[1]=-17.9;h.base_y=.2;city.set_house_era(id,"modern_eco");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-28,-19),"船棚真实九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot();check(not BoatPlan.find(demo.state,"h1").is_empty() and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real nine-metre bridge clears low canopy over water slot");await open_editor();await drag_slider(78.,false);check(await wait_for(func():return preview_ready(78.),18000),"canopy pitch preview prepares affected modern bridge roots")
	if control.current==null:return
	check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure canopy preview retracts obstructed real bridge without State writes");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(not BoatPlan.find(demo.state,"h1").is_empty() and demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"actual tall canopy retracts bridge while retaining author span choice");await capture("canopy_blocks_nine_metre_bridge");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores flat canopy and actual nine-metre bridge")
