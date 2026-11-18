extends "res://tools/check_creation_clockwork_roof_pitch_live.gd"
const RenaFixture=preload("res://tests/test_city_creation_renaissance_roof_pitch.gd")
const Rena=Pitch.Renaissance
var baseline_rena:=""
func verify_rena(label:String)->void:
	var h:Dictionary=demo.state.houses[0];var plan:=Rena.for_house(demo.state,h);var points:Array=[]
	for patch:Dictionary in plan.patches:points.append_array(patch.vertices)
	check(same_triangles(actual_clock_faces(demo.town),points),"complete actual renaissance picking equals CPU triangles within 0.15mm "+label)
	var apex:Vector3=demo.town.house_roots.h1.get_meta("renaissance_roof_pitch").apex;var world:=Pitch.Frame.world3(h,apex);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.08,world-Vector3.UP*.08))
	check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and absf(hit.position.y-world.y)<.001,"independent physics ray confirms true renaissance roof handle surface "+label)
func material_key(material:Material)->Array:
	if material is StandardMaterial3D:return [material.get_class(),material.albedo_color,material.roughness,material.metallic,material.cull_mode]
	return [material.get_class(),material.shader.code.sha256_text(),material.get_shader_parameter("roof_color"),material.get_shader_parameter("albedo_color"),material.get_shader_parameter("surface_kind")] if material is ShaderMaterial else []
func appearance(renderer)->Array:
	var result:Array=[];var house:Node3D=renderer.house_roots.h1
	for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
		var at:Node=mesh.get_parent();var pose:Transform3D=mesh.transform
		while at!=house:
			var frame:Transform3D=at.transform
			if at.name=="ResonanceVisualPivot":frame.basis=Basis.IDENTITY
			pose=frame*pose;at=at.get_parent()
		for i in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.mesh.surface_get_arrays(i),RenderingServer.mesh_get_surface(mesh.mesh.get_rid(),i).get("attribute_data",PackedByteArray()),pose,material_key(mesh.material_override)]))
	result.sort();return result
func original_signature(node:Node3D)->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		var pose:=node.global_transform.affine_inverse()*mesh.global_transform
		for i in range(mesh.mesh.get_surface_count()):result.append(hash([mesh.mesh.surface_get_arrays(i),pose,material_key(mesh.material_override)]))
	result.sort();return result
func original_rena_check()->void:
	if baseline_rena.is_empty():return
	var roots:Array=[];var old=load(baseline_rena);var h:Dictionary=demo.state.houses[0]
	for ignored in range(2):var node:=Node3D.new();demo.add_child(node);roots.append(node)
	old.build(demo.town,roots[0],h,[]);demo.town.Renaissance.build(demo.town,roots[1],h,[]);check(original_signature(roots[0])==original_signature(roots[1]),"original renaissance buffers, rest transforms and material properties match previous builder "+str(h.architecture))
	for node:Node3D in roots:node.queue_free()
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-renaissance="):baseline_rena=arg.trim_prefix("--baseline-renaissance=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--extras-only" in OS.get_cmdline_user_args():await rena_extras();await modern_report(personal);return
	if "--support-only" in OS.get_cmdline_user_args():await support_cases();await modern_report(personal);return
	if "--colors-only" in OS.get_cmdline_user_args():await hot_color_cases();await modern_report(personal);return
	for kind:String in Rena.IDS:
		var city:=RenaFixture.fixture(kind);await show(city,Vector2(-28,-20),"文艺时代真实调坡 "+kind);await settle();quiet();await original_rena_check();var original:Dictionary=demo.state.snapshot();var walls:=body_physics(demo.town)
		await open_editor();check(control.slider.editable and control.handle.visible and root.get_visible_rect().encloses(control.handle.get_global_rect()),"existing native roof controls expose original special family "+kind)
		var source_anchor:=Rena.source_anchor(demo.state,demo.state.houses[0]);var source_world:=Pitch.Frame.world3(demo.state.houses[0],source_anchor);var pick:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(source_world+Vector3.UP*.08,source_world-Vector3.UP*.08));check(not pick.is_empty() and pick.collider.get_meta("house_id","")=="h1","original roof-space handle is anchored on actual original roof "+kind)
		for angle:float in [0.,45.,78.]:
			await open_editor();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();await drag_slider(angle,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-angle)<.2,18000),"renaissance detached production preview completes "+kind+str(angle))
			if control.current==null:await modern_report(personal);return
			var expected:=construction(control.current.renderer);var expected_appearance:=appearance(control.current.renderer);check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"renaissance preview preserves all author data and history "+kind+str(angle));await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
			check(demo.state.snapshot().schema==40 and demo.state.houses[0].roof_pitch.profile=="renaissance" and demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==original.houses[0].cells,"one native schema40 roof edit retains exact original rooms "+kind+str(angle));check(construction(demo.town)==expected and body_physics(demo.town)==walls,"candidate/published geometry and materials stay identical; original walls remain "+kind+str(angle));verify_rena(kind+str(angle));await capture(kind+"_"+str(int(angle)))
			check(appearance(demo.town)==expected_appearance,"actual candidate and published GPU/material mappings match "+kind+str(angle))
			var cold:=State.new();var file:=OUT+"/cold_"+kind+str(int(angle))+".json";check(demo.state.save_city(file).ok and cold.load_city(file).ok and cold.houses==demo.state.houses,"actual renaissance schema40 disk round trip "+kind+str(angle));var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
			while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
			check(preview.ready and construction(preview.renderer)==construction(demo.town) and appearance(preview.renderer)==appearance(demo.town),"independent cold production renderer matches exact renaissance construction and materials "+kind+str(angle));preview.clear()
			if angle==0.:
				var archived:Dictionary=demo.gallery.library.read(str(control.backup.get("id","")));var old:=State.new();check(archived.get("ok",false) and old.restore(archived.world).ok and old.houses==before.houses,"first schema40 edit actually archives original older city "+kind)
			await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one native Undo restores exact previous renaissance author data "+kind+str(angle));await key(KEY_Y,true);await settle();quiet()
		await open_editor();var before_cancel:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(control.current==null and demo.state.snapshot()==before_cancel,"Esc cancels unfinished renaissance roof preview "+kind);await open_editor();await ui_click(control.reset);await settle();quiet();check(demo.state.houses==original.houses and not demo.town.house_roots.h1.has_meta("renaissance_roof_pitch"),"original button restores exact old special roof "+kind)
	await rena_extras();await support_cases();await hot_color_cases();await modern_report(personal)
func rena_extras()->void:
	for kind:String in Rena.IDS:
		var city:=RenaFixture.fixture(kind,2,2,2);city.houses[0].base_y=1.25;city.rotate_house("h1",.35);city.set_house_roof_pitch("h1",78.);await show(city,Vector2(-27.1,-19.1),"旋转抬基多房间文艺屋面");await settle();quiet();demo.spatial_popover.close();demo.select_tool(0);demo.focus=Vector3(-27.1,4.5,-19.1);demo.zoom=26.;demo._update_camera();await process_frame;verify_rena("multi_"+kind)
		var apex:Vector3=demo.town.house_roots.h1.get_meta("renaissance_roof_pitch").apex;var at:Vector2=demo.camera.unproject_position(Pitch.Frame.world3(demo.state.houses[0],apex-Vector3.UP*.03));var hit:Dictionary=demo._ray_hit(at);var before:Dictionary=demo.state.snapshot();var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(-28,-20))
		check(root.get_visible_rect().has_point(at) and resolved.has("cell") and resolved.cell.level==2 and resolved.valid,"real rotated raised steep roof resolves one true upper room "+kind);await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==2,"native steep special roof click creates one real upper room "+kind);await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one native Undo restores full rotated special house "+kind)
	await corner_openings();await rena_bridge()
func corner_openings()->void:
	var city:=RenaFixture.fixture("corner_loggia_tower");city.set_house_roof_pitch("h1",45.);await show(city,Vector2(-28,-20),"文艺望楼真实拱洞");await settle();quiet();var plan:=Rena.for_house(demo.state,demo.state.houses[0]);var row:Dictionary=plan.crown;var pose:=Transform3D(Basis(Vector3.UP,float(row.angle)),Vector3(row.center.x,row.base,row.center.y))
	for index in range(2):
		var angle:=index*PI*.5;var wall:=pose*Transform3D(Basis(Vector3.UP,angle),Vector3(sin(angle)*.735,0,cos(angle)*.735))
		for x:float in [-.47,0.,.47]:
			var a:=wall*Vector3(x,.8,.25);var b:=wall*Vector3(x,.8,-.25);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b));check(hit.is_empty(),"actual open triple arcade stays physically empty "+str(index)+"/"+str(x))
		var a:=wall*Vector3(.235,.8,.25);var b:=wall*Vector3(.235,.8,-.25);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","actual stone jamb remains physically solid "+str(index))
	await capture("real_open_corner_gallery")
func rena_bridge()->void:
	var city:=RenaFixture.fixture("venetian_loggia");city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-33,-20),Vector2(-24.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.houses[city._house_index(id)].base_y=.2;city.set_house_era(id,"modern_eco");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-28,-20),"文艺屋面与真实九米云廊");await settle();quiet();var before:Dictionary=demo.state.snapshot();check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"actual nine-metre modern bridge clears flat renaissance roof");await open_editor();await drag_slider(78.,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and control.prepared>77.,18000),"renaissance preview prepares affected modern bridge roots")
	if control.current==null:return
	check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure renaissance preview retracts actual obstructed cloud bridge");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"published renaissance roof blocks bridge while retaining nine-metre choice");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"native Undo restores real renaissance roof and nine-metre cloud bridge")
func support_cases()->void:
	var city:=RenaFixture.fixture("corner_loggia_tower");city.set_house_roof_pitch("h1",45.);await show(city,Vector2(-28,-20),"望楼外角占用");await settle();quiet();var recipe:Dictionary=demo.state.houses[0].roof_pitch.duplicate(true)
	var last_edit:Dictionary={}
	for offset:Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var added:Dictionary=demo.state.add_house(Vector2(-28,-20)+offset*1.8)
		if added.ok:demo.state.set_house_era(added.house_id,"renaissance");last_edit=demo.state.add_cell(added.house_id,0,0,1)
	demo._after_edit(last_edit,"room",true,"h1");await settle();quiet();await open_editor()
	check(not demo.town.house_roots.h1.get_meta("corner_loggia_clear",true) and not control.slider.editable and "外角净空不足" in control.label.text and demo.state.houses[0].roof_pitch==recipe,"blocked real roof corner withdraws gallery, explains support and preserves authored slope")
	var plan:=Rena.for_house(demo.state,demo.state.houses[0]);check(plan.crown.is_empty() and Pitch.active(demo.state,demo.state.houses[0]),"blocked authored gallery still uses actual fallback platform geometry for clearance");var points:Array=[]
	for patch:Dictionary in plan.patches:points.append_array(patch.vertices)
	check(same_triangles(actual_clock_faces(demo.town),points),"actual blocked-gallery fallback picking equals complete CPU platform geometry")
	city=RenaFixture.fixture("stepped_guildhouse",2,1);city.set_house_roof_pitch("h1",45.);await show(city,Vector2(-27.1,-20),"缺格阶梯屋保坡度");await settle();quiet();var before:Dictionary=demo.state.snapshot();var changed:Dictionary=demo.state.add_cell("h1",0,0,2);demo._after_edit(changed,"room",true,"h1");await settle();quiet();await open_editor();check(not control.slider.editable and "完整矩形屋形" in control.label.text and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"irregular guildhouse keeps original slope and gives accurate shape explanation");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and demo.town.house_roots.h1.has_meta("renaissance_roof_pitch"),"one native Undo restores exact supported stepped roof")
	city=RenaFixture.fixture("stepped_guildhouse",2,1);city.set_house_role("h1","bakery");city.set_house_colors("h1",Color("99b3c2"),Color("db946d"));city.set_house_roof_pitch("h1",78.);await show(city,Vector2(-27.1,-20),"自选色阶梯面包房");await settle();quiet();verify_rena("custom_bakery");var shared:=Rena.for_house(demo.state,demo.state.houses[0]);var cap:Array=shared.records[0].parts.filter(func(p):return p.name=="GuildChimneyCap");var p:=Vector3.ZERO;var top:=-INF
	for point:Vector3 in cap[0].vertices:
		p+=point;top=maxf(top,point.y)
	p/=cap[0].vertices.size();p.y=top;var world:=Pitch.Frame.world3(demo.state.houses[0],p);var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(world+Vector3.UP*.3,world-Vector3.UP*.1));check(not hit.is_empty() and absf(hit.position.y-world.y)<.001 and demo.town.house_roots.h1.get_meta("chimneys",[]).size()==1 and Vector3(demo.town.house_roots.h1.get_meta("chimneys")[0]).distance_to(p+Vector3.UP*.01)<.001,"actual bakery cap and one smoke outlet follow steep roof")
	await open_editor();before=demo.state.snapshot();await drag_slider(15.,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(control.prepared-15.)<.2,18000),"custom-color stepped roof preview completes");var expected:=appearance(control.current.renderer);await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500);check(appearance(demo.town)==expected and demo.state.houses[0].custom_colors==before.houses[0].custom_colors,"custom roof and wall colors retain actual candidate/published material mapping")
	for kind:String in ["venetian_loggia","belvedere_villa"]:
		city=RenaFixture.fixture(kind);city.set_house_colors("h1",Color("99b3c2"),Color("db946d"));city.set_house_roof_pitch("h1",45.);await show(city,Vector2(-28,-20),"自选瓦顶颜色保持");await settle();quiet();var raw:=Node3D.new();demo.add_child(raw);preload("res://scripts/visual/city_creation_renaissance_roof_pitch.gd").build(demo.town,raw,demo.state.houses[0]);var tiles:Array=raw.find_children("RenaissanceHippedRoof*","MeshInstance3D",true,false);check(not tiles.is_empty() and tiles.all(func(mesh):return mesh.material_override is StandardMaterial3D and mesh.material_override.albedo_color==Color("db946d")),"explicit authored roof uses actual chosen roof color "+kind);raw.queue_free();await process_frame
	root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"renaissance roof controls remain reachable at 1024 width");await drag_slider(78.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-28,-20),"文艺预演过期撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"changing city retracts unfinished renaissance roof preview")
func hot_color_cases()->void:
	for kind:String in Rena.IDS:
		var city:=RenaFixture.fixture(kind);city.set_house_roof_pitch("h1",45.);await show(city,Vector2(-28,-20),"现屋配色与冷读保持");await settle();quiet();var rooms:Array=demo.state.houses[0].cells.duplicate(true);var recipe:Dictionary=demo.state.houses[0].roof_pitch.duplicate(true)
		for phase in range(3):
			var edit:Dictionary=demo.state.set_house_palette("h1",2) if phase==2 else demo.state.set_house_colors("h1",Color("99b3c2") if phase==0 else Color("e8d7b7"),Color("db946d") if phase==0 else Color("e8d7b7"));demo._after_edit(edit,"colors",true,"h1");await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
			var cold:=State.new();cold.restore(demo.state.snapshot());var preview:=Batch.new();preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
			while not preview.ready and Time.get_ticks_msec()<deadline:preview.step();await process_frame
			check(preview.ready and appearance(preview.renderer)==appearance(demo.town),"live GPU color update equals independent cold materials and vertex attributes "+kind+str(phase));check(demo.state.houses[0].cells==rooms and demo.state.houses[0].roof_pitch==recipe,"live color change preserves all author rooms and slope "+kind+str(phase));preview.clear()
