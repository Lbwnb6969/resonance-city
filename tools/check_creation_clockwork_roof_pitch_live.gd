extends "res://tools/check_creation_modern_roof_details_live.gd"
const ClockFixture=preload("res://tests/test_city_creation_clockwork_roof_pitch.gd")
const ClockGeometry=Pitch.Clockwork
var baseline_clock:=""
func actual_clock_faces(renderer)->Array:
	var points:Array=[];var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
	for body:StaticBody3D in house.find_children("*","StaticBody3D",true,false):
		if not body.get_meta("roof_surface",false):continue
		for shape:CollisionShape3D in body.get_children():
			for point:Vector3 in shape.shape.get_faces():points.append(inverse*shape.global_transform*point)
	return points
func verify_clock(label:String)->void:
	var h:Dictionary=demo.state.houses[0];var plan:=ClockGeometry.for_house(demo.state,h);var points:Array=[]
	for patch:Dictionary in plan.patches:points.append_array(patch.vertices)
	check(same_triangles(actual_clock_faces(demo.town),points),"actual clockwork roof picking equals complete CPU triangles within 0.15mm "+label)
	var apex:Vector3=demo.town.house_roots.h1.get_meta("clockwork_roof_pitch").apex;var world:Vector3=Pitch.Frame.world3(h,apex);var hit:Dictionary=demo._ray_hit(demo.camera.unproject_position(world-Vector3.UP*.03))
	var surface:Array[Vector3]=[];surface.assign(points);check(absf(preload("res://scripts/visual/city_creation_dormer_sites.gd").height(surface,Vector2(apex.x,apex.z))-apex.y)<.001,"clockwork handle anchors a real roof surface rather than space between accessories "+label)
	var vertical:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.08,world-Vector3.UP*.08));check(not vertical.is_empty() and vertical.collider.get_meta("house_id","")=="h1" and absf(Vector3(vertical.position).y-world.y)<.001,"actual independent physics ray confirms the handle point on visible construction "+label)
	check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","actual clockwork apex is reachable by real picking "+label)
func legacy_clock()->void:
	if baseline_clock.is_empty():return
	var h:Dictionary=demo.state.houses[0];var old=load(baseline_clock);var roots:Array=[]
	for ignored in range(2):var node:=Node3D.new();demo.add_child(node);roots.append(node)
	for data:Dictionary in old.prepare(demo.state,h):old.install(demo.town,roots[0],h,data)
	for data:Dictionary in demo.town.Clockwork.prepare(demo.state,h):demo.town.Clockwork.install(demo.town,roots[1],h,data)
	check(roof_signature(roots[0])==roof_signature(roots[1]),"unedited actual clockwork production buffers match previous builder "+str(h.get("architecture","")))
	for node:Node3D in roots:node.queue_free()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-clockwork="):baseline_clock=arg.trim_prefix("--baseline-clockwork=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--bridge-only" in OS.get_cmdline_user_args():await clock_bridge();await modern_report(personal);return
	if "--extras-only" in OS.get_cmdline_user_args():await clock_extra_cases();await modern_report(personal);return
	if "--identity-only" in OS.get_cmdline_user_args():
		for kind:String in ["sawtooth_atrium","clock_turret","iron_conservatory","guild_arcade"]:
			var sample:=ClockFixture.fixture(kind);sample.set_house_roof_pitch("h1",45.);await show(sample,Vector2(-25,-20),"钟表原型名称保持");await settle();quiet();await open_editor();check(demo.spatial_popover.architecture_button.caption==preload("res://scripts/world/city_creation_architecture_choice.gd").label(kind),"actual selected prototype caption retains specific house identity "+kind)
		await modern_report(personal);return
	for kind:String in ClockFixture.KINDS:
		var city:=ClockFixture.fixture(kind);await show(city,Vector2(-25,-20),"钟表时代真实调坡 "+kind);await settle();quiet();await legacy_clock();var original:Dictionary=demo.state.snapshot();var body:=body_physics(demo.town)
		await open_editor();check(control.row.visible and control.slider.editable and control.handle.visible,"clockwork family exposes existing native roof controls "+kind)
		for angle:float in [0.,45.,78.]:
			await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false)
			check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2,18000),"clockwork detached production preview ready "+kind+str(angle))
			if control.current==null:await modern_report(personal);return
			var expected:=construction(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"clockwork preview is author/history pure "+kind+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
			check(demo.state._undo.size()==depth+1 and demo.state.snapshot().schema==39 and demo.state.houses[0].roof_pitch.profile=="clockwork" and demo.state.houses[0].cells==original.houses[0].cells,"one native roof transaction retains real family/body and explicit schema39 "+kind+str(angle))
			check(construction(demo.town)==expected and body_physics(demo.town)==body,"clockwork candidate/published GPU buffers and rest transforms match; walls unchanged "+kind+str(angle));verify_clock(kind+str(angle));await capture((kind if not kind.is_empty() else "mansard")+"_"+str(int(angle)))
			var cold:=State.new();var file:=OUT+"/cold_"+(kind if not kind.is_empty() else "mansard")+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"clockwork actual disk round trip "+kind+str(angle))
			var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
			while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
			check(preview.ready and construction(preview.renderer)==construction(demo.town),"independent cold production renderer matches complete clockwork construction "+kind+str(angle));preview.clear()
			if angle==0.:
				var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema39 edit actually archives older original city "+kind)
			await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one native Undo restores whole previous clockwork author house "+kind+str(angle));await key(KEY_Y,true);await settle();quiet()
		await open_editor();var source:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==source,"Esc retracts unfinished clockwork preview "+kind)
		await open_editor();await ui_click(control.reset);await settle();quiet();check(demo.state.houses==original.houses and not demo.town.house_roots.h1.has_meta("clockwork_roof_pitch"),"original button restores exact older clockwork recipe "+kind)
	await clock_bridge();await clock_details();await clock_extra_cases();await modern_report(personal)
func clock_bridge()->void:
	var city:=ClockFixture.fixture("guild_arcade");city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-30,-20),Vector2(-21.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-25,-20),"钟表屋面与九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot()
	check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real modern nine-metre cloud bridge clears actual flat clockwork roof")
	await open_editor();await drag_slider(78.,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and control.prepared>77.,18000),"clockwork roof preview prepares affected modern bridge roots")
	if control.current==null:return
	check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure clockwork roof preview retracts obstructed real modern bridge");await capture("clockwork_bridge_preview");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet()
	check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"published clockwork roof blocks bridge while retaining nine-metre author choice");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores actual clockwork roof and cloud bridge")
func clock_details()->void:
	var city:=ClockFixture.fixture("recessed_townhouse");city.add_cell("h1",1,0,0);city.add_cell("h1",1,0,1);city.set_house_dormer("h1","gable_light");city.set_house_chimney("h1","brick_twin_pots");city.set_house_architecture_variant("h1","timber_verge","gable_trim");var choice:Dictionary=city.houses[0].architecture_variant.duplicate(true)
	for angle:float in [0.,15.,78.,0.]:
		city.set_house_roof_pitch("h1",angle);await show(city,Vector2(-25,-20),"钟表深窗真实细部");await settle();quiet();verify_clock("details"+str(angle))
		var shared:Dictionary=ClockGeometry.for_house(demo.state,demo.state.houses[0]).details
		for item:Dictionary in shared.details:check(demo.town.house_roots.h1.get_meta(item.slot,{}).get("active",false)==item.active,"actual clockwork detail metadata agrees with CPU shared site "+str(item.slot)+str(angle))
		check(demo.state.houses[0].architecture_variant==choice,"clockwork detail author recipes survive every slope "+str(angle));await capture("clockwork_details_"+str(int(angle)))
func clock_extra_cases()->void:
	for kind:String in ClockFixture.KINDS:
		var city:=ClockFixture.fixture(kind);city.houses[0].base_y=1.25;city.rotate_house("h1",.35);city.set_house_roof_pitch("h1",78.);await show(city,Vector2(-25,-20),"旋转抬基陡钟表屋顶 "+kind);await settle();quiet();demo.spatial_popover.close();demo.select_tool(0);demo.focus=Vector3(-25,5.,-20);demo.zoom=30.;demo._update_camera();await process_frame
		verify_clock("rotated_raised_"+kind);var apex:Vector3=demo.town.house_roots.h1.get_meta("clockwork_roof_pitch").apex;var at:Vector2=demo.camera.unproject_position(Pitch.Frame.world3(demo.state.houses[0],apex-Vector3.UP*.03));var hit:Dictionary=demo._ray_hit(at);var before:Dictionary=demo.state.snapshot();var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(-25,-20))
		check(root.get_visible_rect().has_point(at) and resolved.has("cell") and resolved.cell.level==2 and resolved.valid,"actual rotated/raised steep roof hit adds above instead of side terrace "+kind)
		await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==2,"native steep clockwork roof click creates exactly one true upper room "+kind);await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one native Undo restores complete rotated clockwork house "+kind)
		if kind=="clock_turret":await capture("whole_steep_clock_tower")
	var city:=ClockFixture.fixture("");city.add_house(Vector2(-23.2,-20));city.set_house_era("h2","clockwork");city.add_cell("h2",0,0,1);city.set_house_roof_pitch("h1",45.);city.set_house_roof_pitch("h2",45.);await show(city,Vector2(-24.1,-20),"钟表接檐随调坡刷新");await settle();quiet();await open_editor();var original:Dictionary=demo.state.snapshot();await drag_slider(15.,false)
	check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-15.)<.2,18000),"adjoining clockwork roof preview completes")
	check(control.current!=null and control.current.ids.has("h2") and demo.state.snapshot()==original,"actual detached clockwork preview refreshes neighbour roof without author mutation")
	if control.current!=null:
		var expected:=construction(control.current.renderer,"h2");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(construction(demo.town,"h2")==expected,"changed neighbouring actual roof publishes identical candidate geometry");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==original.houses,"one native Undo restores original equal neighbouring roof recipes")
	root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"clockwork native roof controls stay reachable at 1024 width")
	await drag_slider(78.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-25,-20),"钟表屋面过期预演撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"changing city retracts unfinished clockwork roof and neighbour preview")
