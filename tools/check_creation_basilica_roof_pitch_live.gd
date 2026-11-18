extends "res://tools/check_creation_renaissance_roof_pitch_live.gd"
const Plan=preload("res://scripts/world/city_creation_ancient_extension_plan.gd")
const Brush=preload("res://scripts/world/city_creation_build_brush.gd")
var pending_isolated:=true
const BasilicaFixture=preload("res://tests/test_city_creation_basilica_roof_pitch.gd")
static func fixture(width:int=2,depth:int=3,floors:int=1)->RefCounted:return BasilicaFixture.fixture(width,depth,floors)
func preview_ready(angle:float)->bool:
	if control.pending!=null and control.pending.renderer!=null:
		for body:CollisionObject3D in control.pending.renderer.find_children("*","CollisionObject3D",true,false):pending_isolated=pending_isolated and body.collision_layer==0 and body.collision_mask==0
	return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2
func basilica_focus()->void:
	var p:=Plan.rectangle(demo.state.houses[0]);var center:=Pitch.Frame.point(demo.state.houses[0],p.center);demo.focus=Vector3(center.x,2.,center.y);demo.zoom=17.;demo.pitch=.7;demo.yaw=.55;demo._update_camera()
func physical_faces(renderer)->Array:
	var faces:Array=[];var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
	for body:StaticBody3D in house.find_children("*","StaticBody3D",true,false):
		if not str(body.name).begins_with("BasilicaRoofPick") and not str(body.name).begins_with("BasilicaUpperWallPick"):continue
		for shape:CollisionShape3D in body.get_children():
			for p:Vector3 in shape.shape.get_faces():faces.append(inverse*shape.global_transform*p)
	return faces
func lower_physics(renderer)->Array:
	var result:Array=[];var mass:Node3D=renderer.house_roots.h1.find_child("RomanBasilicaMassing",true,false)
	for body:Node in mass.get_children():
		if not body is StaticBody3D:continue
		for shape:CollisionShape3D in body.get_children():result.append(hash([shape.shape.get_faces(),shape.transform,body.transform]))
	result.sort();return result
func verify_basilica(label:String)->void:
	var h:Dictionary=demo.state.houses[0];var data:=Pitch.Basilica.for_house(demo.state,h);var points:Array=[];var families:Dictionary={}
	for patch:Dictionary in data.patches:points.append_array(patch.vertices);families[patch.part]=true
	check(same_triangles(physical_faces(demo.town),points),"complete three roofs clerestory and end-wall actual collision equals CPU "+label)
	check(families.has("BasilicaNaveTileRoof") and families.has("BasilicaAisleTileRoof") and families.has("BasilicaApseTileRoof") and data.upper-data.aisle_top>=.3299,"all three roof families and real clerestory clearance remain "+label)
	var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var clear:=true
	for entry:Dictionary in demo.state.house_entrances("h1"):
		var wall:=Vector3(entry.wall_at.x,float(h.get("base_y",0.))+.65,entry.wall_at.y);var normal:=Vector3(entry.outward.x,0,entry.outward.y);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(wall+normal*.4,wall-normal*.2));clear=clear and hit.is_empty()
	check(clear,"all original real entrance arches remain open "+label)
	var p:=Plan.rectangle(h);var radius:float=data.apse_radius;var mass:Node3D=demo.town.house_roots.h1.find_child("RomanBasilicaMassing",true,false);var z:float=-p.depth*.5+radius-radius*.25;var interior:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(mass.to_global(Vector3(-radius*.25,.65,z)),mass.to_global(Vector3(radius*.25,.65,z))));check(interior.is_empty(),"actual semicircular apse keeps hollow interior "+label)
	var world:=Pitch.Frame.world3(h,demo.town.house_roots.h1.get_meta("basilica_roof_pitch").apex);var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.06,world-Vector3.UP*.06));facts["anchor_"+label]={"world":world,"hit":str(hit),"meta":hit.collider.get_meta_list() if not hit.is_empty() else []};check(not hit.is_empty() and hit.collider.get_meta("roof_surface",false) and absf(hit.position.y-world.y)<.001,"handle anchors actual basilican roof "+label)
	verify_seams(mass,p,data,label)
	var panes:Array=demo.town.house_roots.h1.get_meta("civic_windows",[]);check(not panes.is_empty() and panes.all(func(w):return w.size.x>0. and w.size.y>0.),"derived glow panes follow real positive clerestory glass "+label)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec()
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--basilica-bridge-only" in OS.get_cmdline_user_args():await basilica_bridge();await modern_report(personal);return
	await show(fixture(),Vector2(-26,-20),"罗马巴西利卡连续调坡");basilica_focus();await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var original:Dictionary=demo.state.snapshot();var old_gpu:=appearance(demo.town);var walls:=lower_physics(demo.town);var colonnade:Dictionary={}
	await open_editor();check(control.slider.editable and control.handle.visible,"native original basilica controls remain reachable");var world:=Pitch.Frame.world3(demo.state.houses[0],demo.town.house_roots.h1.get_meta("basilica_original_anchor"));var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.05,world-Vector3.UP*.05));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","original handle is on true old basilican tile roof")
	for angle:float in [0.,45.,78.]:
		await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false);check(await wait_for(func():return preview_ready(angle),18000),"full detached basilican roof preview ready "+str(angle))
		if control.current==null:await modern_report(personal);return
		var expected:=appearance(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"held roof preview keeps author and history pure "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
		check(demo.state.snapshot().schema==44 and demo.state.houses[0].roof_pitch=={"version":9,"profile":"roman_basilica","degrees":angle} and demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==original.houses[0].cells,"one native schema44 transaction retains all rooms "+str(angle));
		if angle==0.:walls=lower_physics(demo.town)
		check(appearance(demo.town)==expected and lower_physics(demo.town)==walls,"candidate and published GPU materials match and fixed lower body stays "+str(angle));verify_basilica(str(angle));await capture("basilica_"+str(int(angle)))
		if angle==0.:
			var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema44 edit archives exact original city")
		var cold:=State.new();var file:=OUT+"/cold_"+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"schema44 atomic disk cold read "+str(angle));var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
		while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
		check(preview.ready and appearance(preview.renderer)==appearance(demo.town),"independent cold GPU materials match "+str(angle));preview.clear();await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"native Undo restores exact prior basilican roof "+str(angle));await key(KEY_Y,true);await settle();quiet()
	await roof_click();await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before,"Esc cancels basilican roof preview");await open_editor();await ui_click(control.reset);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(demo.state.houses==original.houses and appearance(demo.town)==old_gpu,"original button restores exact basilican GPU materials and author data")
	await extras();root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"existing controls fit 1024 viewport");await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-28,-20),"殿堂过期预演撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"city change withdraws stale roof and picking");check(pending_isolated,"pending basilican geometry never publishes collisions");facts.elapsed_seconds=(Time.get_ticks_msec()-began)/1000.;await modern_report(personal)
func roof_click()->void:
	demo.spatial_popover.close();demo.select_tool(0);basilica_focus();await settle();quiet();var h:Dictionary=demo.state.houses[0];var at:=Vector2.ZERO;var hit:Dictionary={}
	for patch:Dictionary in Pitch.Basilica.for_house(demo.state,h).patches:
		if not patch.roof_skin:continue
		for i in range(0,patch.vertices.size(),3):
			var p:=Pitch.Frame.world3(h,(patch.vertices[i]+patch.vertices[i+1]+patch.vertices[i+2])/3.);var pixel:Vector2=demo.camera.unproject_position(p);var sample:Dictionary=demo._ray_hit(pixel)
			if root.get_visible_rect().has_point(pixel) and not sample.is_empty() and sample.collider.get_meta("roof_surface",false):at=pixel;hit=sample;break
		if not hit.is_empty():break
	var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(-26,-20));check(not hit.is_empty() and resolved.has("cell") and resolved.cell.level==1 and resolved.cell.kind=="room" and resolved.valid,"steep tile resolves original highest room upper floor");var before:Dictionary=demo.state.snapshot();await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==1 and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"native steep basilican roof click adds real upper room and retains pitch");await open_editor();check(not control.slider.editable and "完整矩形" in control.label.text and not demo.town.house_roots.h1.has_meta("basilica_roof_pitch"),"partial upper room uses honest fallback and explanation");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and demo.town.house_roots.h1.has_meta("basilica_roof_pitch"),"native Undo restores complete pitched hall")
func extras()->void:
	for size:Vector3i in [Vector3i(1,1,1),Vector3i(2,3,2)]:
		var city:=fixture(size.x,size.y,size.z);city.set_house_roof_pitch("h1",45.);city.houses[0].base_y=1.;city.rotate_house("h1",.35);await show(city,Vector2(-27,-19),"旋转抬基多格殿堂");basilica_focus();await settle();quiet();verify_basilica(str(size));await capture("basilica_size_"+str(size.x));await open_editor();check(control.slider.editable and control.handle.visible,"rotated raised multi-cell hall keeps controls "+str(size))
	demo._after_edit(demo.state.set_house_colors("h1",Color("99b3c2"),Color("db946d")),"colors");await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);var hot:=appearance(demo.town);var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
	while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
	check(preview.ready and appearance(preview.renderer)==hot,"hot custom tile colors equal independent cold GPU materials");preview.clear()
func basilica_bridge()->void:
	var city:=fixture(1,1,1);city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.set_house_architecture(id,"chalet");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-28,-20),"殿堂与真实九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot();check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"real cloud bridge clears flat basilican roof");await open_editor();await drag_slider(78.,false);check(await wait_for(func():return preview_ready(78.),18000),"basilican preview prepares affected bridge roots")
	if control.current==null:return
	check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure basilican preview retracts actual obstructed bridge");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"published basilican roof retracts bridge preserving span choice");await capture("basilica_blocks_cloud_bridge");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores flat basilican roof and actual bridge")

func verify_seams(mass:Node3D,p:Dictionary,data:Dictionary,label:String)->void:
	var space:PhysicsDirectSpaceState3D=demo.get_world_3d().direct_space_state;var half:float=p.width*.5;var nave:float=p.width*.23;var depth:float=p.depth*.5;var height:float=p.height;var radius:float=data.apse_radius;var apse_z:float=-depth+radius;var slope:float=.25*float(data.gain)/(half+.10-nave);var rays:Array=[]
	if float(data.clerestory_top)-float(data.upper)>.0001:
		var y:float=(float(data.clerestory_top)+float(data.upper))*.5;rays.append(["clerestory",Vector3(nave-.04,y,0.17),Vector3(nave+.04,y,0.17)])
	var y:float=height+(.06+.10*slope)*.5;var z:float=(apse_z+depth)*.5;rays.append(["aisle_wall",Vector3(half+.04,y,z),Vector3(half-.08,y,z)])
	var x:float=(nave+half)*.5;y=height+(.06+(half+.10-x)*slope)*.5;rays.append(["aisle_front",Vector3(x,y,depth+.04),Vector3(x,y,depth-.04)])
	var angle:=PI*.5+.02;var normal:=Vector2(cos(angle),-sin(angle));y=height+(.04+.07/(radius+.07)*.26*float(data.gain))*.5;var outside:Vector2=Vector2(0,apse_z)+normal*(radius+.02);var inside:Vector2=Vector2(0,apse_z)+normal*(radius-.02);rays.append(["apse_wall",Vector3(outside.x,y,outside.y),Vector3(inside.x,y,inside.y)])
	var hits:Dictionary={};var good:=true
	for row:Array in rays:
		var hit:Dictionary=space.intersect_ray(PhysicsRayQueryParameters3D.create(mass.to_global(row[1]),mass.to_global(row[2])));var blocked:bool=not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and not hit.collider.get_meta("roof_surface",false);hits[row[0]]=blocked;good=good and blocked
	facts["seams_"+label]=hits;check(good,"actual under-roof Jolt rays meet closed clerestory aisle and apse wall bands "+label)
