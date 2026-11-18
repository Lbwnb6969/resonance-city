extends "res://tools/check_creation_roof_pitch_live.gd"
const RoundFixture=preload("res://tests/test_city_creation_round_roof_pitch.gd")
func roof_faces(renderer)->PackedVector3Array:
	var result:=PackedVector3Array()
	for shape:CollisionShape3D in renderer.house_roots.h1.find_children("RoundTowerRoofPick","CollisionShape3D",true,false):
		var cell:Node3D=shape.get_parent().get_parent()
		for p:Vector3 in shape.shape.get_faces():result.append(cell.transform*shape.transform*p)
	return result
func body_faces(renderer)->Array:
	var result:Array=[]
	for shape:CollisionShape3D in renderer.house_roots.h1.find_children("RoundTowerBodyPick","CollisionShape3D",true,false):result.append([shape.shape.points,shape.transform,shape.get_parent().get_parent().transform])
	return result
func gpu(renderer)->Array:
	var rows:Array=[]
	var root:Node3D=renderer.house_roots.h1
	for mesh:MeshInstance3D in renderer.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
		var at:Node=mesh.get_parent();var rest:Transform3D=mesh.transform
		while at!=root:
			var transform:Transform3D=at.transform
			if at.name=="ResonanceVisualPivot":transform.basis=Basis.IDENTITY
			rest=transform*rest;at=at.get_parent()
		for i in range(mesh.mesh.get_surface_count()):rows.append(hash([mesh.mesh.surface_get_arrays(i),rest]))
	rows.sort();return rows
func gpu_details(renderer)->Array:
	var rows:Array=[]
	for mesh:MeshInstance3D in renderer.house_roots.h1.find_children("*","MeshInstance3D",true,false):
		var parts:Array=[]
		for i in range(mesh.mesh.get_surface_count()):
			var values:Array=[]
			for value:Variant in mesh.mesh.surface_get_arrays(i):values.append(hash(value))
			parts.append(values)
		rows.append({"path":str(renderer.house_roots.h1.get_path_to(mesh)),"local":str(mesh.transform),"global":str(mesh.global_transform),"arrays":parts})
	return rows
func latest_preview()->bool:
	return control.current!=null and control.current.ready and control.pending==null and absf(float(control.current.renderer.state.houses[0].get("roof_pitch",{}).get("degrees",-1.))-control.desired)<.0001
func release_slider()->void:
	var rect:Rect2=control.slider.get_global_rect();await send(Vector2(rect.position.x+8.+(rect.size.x-16.)*control.desired/78.,rect.get_center().y),false)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();control=demo.get_meta("roof_pitch_control")
	var city:RefCounted=RoundFixture.fixture();city.set_house_role("h1","bakery");await show(city,Vector2(-25,-20),"圆塔连续调坡");await settle();quiet();demo.zoom=18.;demo.focus.y=2.5;demo._update_camera();await open_editor()
	check(control.slider.editable and control.handle.is_visible_in_tree() and demo.town.house_roots.h1.has_meta("round_tower"),"existing native appearance entry exposes actual round roof controls")
	var original_body:=body_faces(demo.town);var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(60.,false)
	check(await wait_for(latest_preview,15000),"held slider shows latest real round roof production preview")
	check(demo.state.snapshot()==before and demo.state._undo.size()==depth and body_faces(control.current.renderer)==original_body,"held round preview preserves whole original city and cylindrical body")
	await capture("round_pure_preview");await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before,"Escape cancels round preview without any history write")
	for angle:float in ([0.] if "--probe" in OS.get_cmdline_user_args() else [0.,15.,45.,78.]):
		if angle==45.:root.size=Vector2i(1024,768);await settle()
		await open_editor();before=demo.state.snapshot();depth=demo.state._undo.size();await drag_slider(angle,false)
		check(await wait_for(latest_preview,15000),"latest preview ready for round angle "+str(angle))
		var expected:PackedVector3Array=roof_faces(control.current.renderer);var preview_gpu:=gpu(control.current.renderer);var detail_before:=gpu_details(control.current.renderer)
		check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"round slider remains pure until release "+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,20000);await settle();quiet()
		var h:Dictionary=demo.state.houses[0];var metadata:Dictionary=demo.town.house_roots.h1.get_meta("round_tower",{})
		check(h.has("roof_pitch") and absf(float(h.roof_pitch.degrees)-angle)<2. and demo.state._undo.size()==depth+1 and demo.state.houses[1]==before.houses[1],"round release commits one real edit preserving other house "+str(angle))
		await wait_for(func():return not demo.town.touch.active.has("h1"),1500)
		check(body_faces(demo.town)==original_body and roof_faces(demo.town)==expected and gpu(demo.town)==preview_gpu,"round preview and publication have identical body, roof collision and actual construction GPU buffers "+str(angle))
		facts[str(angle)]={"body":body_faces(demo.town)==original_body,"roof":roof_faces(demo.town)==expected,"gpu":gpu(demo.town)==preview_gpu,"before_gpu":preview_gpu,"after_gpu":gpu(demo.town)}
		if "--probe" in OS.get_cmdline_user_args():FileAccess.open(OUT+"/gpu_details.json",FileAccess.WRITE).store_string(JSON.stringify({"before":detail_before,"after":gpu_details(demo.town),"tree":demo.town.house_roots.h1.get_tree_string_pretty()},"\t"))
		check(absf(float(metadata.roof_top_y)-float(metadata.eave_y)-Pitch.Round.Roof.height(h))<.0001 and metadata.radius==.9,"actual round apex follows pitch without changing cylindrical wall "+str(angle))
		var at:=Vector2(-24.55,-19.9);var faces:Array[Vector3]=[];faces.assign(roof_faces(demo.town));var roof_y:float=preload("res://scripts/visual/city_creation_terracotta_skylights.gd").surface_height(faces,at)
		await physics_frame;var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x,14,at.y),Vector3(at.x,.5,at.y),1))
		check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and absf(Vector3(hit.position).y-roof_y)<.015,"actual physics hits true round roof height including flat cap "+str(angle))
		var crown:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-25,14,-19.995),Vector3(-25,.5,-19.995),1))
		check(not crown.is_empty() and crown.collider.get_meta("house_id","")=="h1" and absf(Vector3(crown.position).y-float(metadata.roof_top_y)-.30)<.015,"wind-vane picking follows actual moving apex "+str(angle))
		var outlets:Array=demo.town.house_roots.h1.get_meta("chimneys",[]);var chimney:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-24.57,14,-20.3),Vector3(-24.57,.5,-20.3),1))
		check(not outlets.is_empty() and not chimney.is_empty() and chimney.collider.get_meta("house_id","")=="h1" and absf(Vector3(chimney.position).y-Vector3(outlets[0]).y+.025)<.015,"bakery chimney picking follows real roof siting "+str(angle))
		await capture("round_"+str(angle));var published:PackedVector3Array=roof_faces(demo.town);await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one native Undo restores exact original round author records "+str(angle));await key(KEY_Y,true);await settle();quiet();check(roof_faces(demo.town)==published,"native Redo restores exact real round roof "+str(angle))
		await open_editor();check(root.get_visible_rect().encloses(control.handle.get_global_rect()) and root.get_visible_rect().encloses(control.slider.get_global_rect()),"round handle and slider reachable after changing viewport "+str(angle))
	if "--probe" in OS.get_cmdline_user_args():await complete_report(personal);return
	check(control.backup.get("ok",false),"first schema36 round edit retains original city through actual collection backup")
	var file:=OUT+"/round.json";var cold:=State.new();var hot_gpu:=gpu(demo.town);var hot:PackedVector3Array=roof_faces(demo.town);check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"real disk cold read keeps entire pitched round city")
	await show(cold,Vector2(-25,-20),"圆塔冷读");await settle();quiet();check(gpu(demo.town)==hot_gpu and roof_faces(demo.town)==hot,"cold publication reproduces actual mesh/normal/UV/index and collision buffers")
	await open_editor();var at:Vector2=control.handle.get_global_rect().get_center();before=demo.state.snapshot();depth=demo.state._undo.size();await pointer(at);await send(at,true)
	for i in range(1,5):await pointer(at+Vector2(0,8.*i),Vector2(0,8))
	check(control.dragging and demo.state.snapshot()==before and control.desired<78.,"native roof-space handle changes round preview without writing State");await send(at+Vector2(0,32),false);await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.state._undo.size()==depth+1 and float(demo.state.houses[0].roof_pitch.degrees)<78.,"released native round handle publishes one continuous pitch edit")
	await open_editor();await ui_click(control.reset);await settle();quiet();check(not demo.state.houses[0].has("roof_pitch") and body_faces(demo.town)==original_body,"original button restores curved round roof and leaves body intact")
	var renaissance:RefCounted=RoundFixture.fixture();renaissance.add_cell("h1",0,0,2);renaissance.set_house_era("h1","renaissance");await show(renaissance,Vector2(-25,-20),"文艺圆塔原顶");await settle();quiet()
	check(demo.town.house_roots.h1.get_meta("round_tower",{}).get("dome",false),"legacy renaissance round lantern dome is genuinely present before custom pitch")
	await open_editor();await drag_slider(45.);await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet()
	check(not demo.town.house_roots.h1.get_meta("round_tower",{}).get("dome",false) and not roof_faces(demo.town).is_empty(),"authored round slope replaces legacy dome with actual selected conical skin")
	await open_editor();await ui_click(control.reset);await settle();quiet();check(demo.town.house_roots.h1.get_meta("round_tower",{}).get("dome",false) and not demo.state.houses[0].has("roof_pitch"),"original round roof restores exact renaissance dome branch")
	var historical:RefCounted=RoundFixture.fixture();historical.houses[0].roof_pitch={"version":1,"degrees":78.};await show(historical,Vector2(-25,-20),"旧35作品休眠坡度");await settle();quiet();await open_editor()
	var old:Dictionary=demo.town.house_roots.h1.get_meta("round_tower");var old_faces:PackedVector3Array=roof_faces(demo.town);var old_gpu:=gpu(demo.town)
	var plain:RefCounted=preload("res://scripts/world/city_creation_chemistry_preview.gd").fork(demo.state);plain.houses[0]=plain.houses[0].duplicate(true);plain.houses[0].erase("roof_pitch")
	var compare=preload("res://scripts/visual/city_creation_batch_preview.gd").new();compare.start(demo,{"city":plain,"changed":["h1"]})
	while not compare.ready:compare.step();await process_frame
	var legacy_good:bool=roof_faces(compare.renderer)==old_faces and gpu(compare.renderer)==old_gpu;compare.clear()
	facts.legacy_curve={"schema":demo.state.snapshot().schema,"version":demo.state.houses[0].roof_pitch.version,"same_as_original_roof":legacy_good,"label":control.label.text,"metadata":old}
	check(demo.state.snapshot().schema==35 and demo.state.houses[0].roof_pitch.version==1 and legacy_good and "原顶" in control.label.text,"actual schema35 dormant slope retains exact original roof collision/GPU and original label")
	before=demo.state.snapshot();await drag_slider(45.);await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet()
	check(demo.state.snapshot().schema==36 and demo.state.houses[0].roof_pitch.version==2 and control.backup.get("ok",false),"explicit native author edit alone upgrades dormant round record to schema36")
	var archived:Dictionary=demo.gallery.library.read(str(control.backup.id));var archived_city:=State.new()
	check(archived.ok and archived_city.restore(archived.world).ok and archived_city.snapshot().schema==35 and archived_city.houses==before.houses,"actual before-round-upgrade collection preserves the old dormant author record")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and demo.town.house_roots.h1.get_meta("round_tower").radius_power==.78,"native Undo restores old dormant parameter and real legacy curved round skin")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses[0].roof_pitch.version==2 and demo.town.house_roots.h1.get_meta("round_tower").radius_power==1.,"native Redo restores explicitly authored straight conical skin")
	# Invalid high cone stays a round tower and writes nothing.
	var blocked:RefCounted=RoundFixture.blocked_fixture();await show(blocked,Vector2(-25,-20),"高处邻屋净空");await settle();quiet();await open_editor();before=demo.state.snapshot();depth=demo.state._undo.size();await drag_slider(78.,false)
	check(await wait_for(func():return control.prepared>77. and control.pending==null,12000) and control.current==null and "净空" in control.label.text,"invalid round slope shows actual clearance reason and preserves original tower")
	await release_slider();await process_frame;check(demo.state.snapshot()==before and demo.state._undo.size()==depth and demo.town.house_roots.h1.has_meta("round_tower"),"invalid release cannot switch cylindrical tower into a square fallback or consume history")
	await capture("round_clearance_rejected");await open_editor();await drag_slider(15.,false);await wait_for(latest_preview,15000)
	var replacement:=State.new();replacement.initialize_free();await show(replacement,Vector2(-25,-20),"换城撤回圆塔预演");await settle();quiet();check(not control.dragging and control.current==null and demo.state.houses.is_empty(),"city switch retracts pending round roof preview")
	await complete_report(personal)
