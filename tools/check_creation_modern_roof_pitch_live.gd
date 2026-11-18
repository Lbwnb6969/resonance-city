extends "res://tools/check_creation_roof_pitch_live.gd"
const Fixture=preload("res://tests/test_city_creation_modern_roof_pitch.gd")
const ModernGeometry=Pitch.Modern
const Batch=preload("res://scripts/visual/city_creation_batch_preview.gd")
var legacy_path:=""
func construction(renderer,id:String="h1")->Array:
	var rows:Array=[];var house:Node3D=renderer.house_roots[id]
	for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
		var at:Node=mesh.get_parent();var rest:Transform3D=mesh.transform
		while at!=house:
			var transform:Transform3D=at.transform
			if at.name=="ResonanceVisualPivot":transform.basis=Basis.IDENTITY
			rest=transform*rest;at=at.get_parent()
		for i in range(mesh.mesh.get_surface_count()):rows.append(hash([mesh.mesh.surface_get_arrays(i),rest]))
	rows.sort();return rows
func roof_signature(root_node:Node3D)->Array:
	var rows:Array=[]
	for mesh:MeshInstance3D in root_node.find_children("*","MeshInstance3D",true,false):
		var at:Node=mesh.get_parent();var rest:Transform3D=mesh.transform
		while at!=root_node:rest=(at as Node3D).transform*rest;at=at.get_parent()
		for i in range(mesh.mesh.get_surface_count()):rows.append(hash([mesh.mesh.surface_get_arrays(i),rest]))
	rows.sort();return rows
func legacy_check()->void:
	if legacy_path.is_empty():return
	var old:RefCounted=load(legacy_path).new();var h:Dictionary=demo.state.houses[0];var baseline:=Node3D.new();var current:=Node3D.new();demo.add_child(baseline);demo.add_child(current)
	for parent:Node3D in [baseline,current]:
		for cell:Dictionary in h.cells:
			var node:=Node3D.new();node.name=str(cell.id);node.position=demo.town._cell_position(h,cell);parent.add_child(node)
	var records:Array=[];var actual:Array=[]
	for cell:Dictionary in demo.town.Modern.prepare(demo.state,h).roofs:
		old.roof(demo.town,baseline,h,demo.town.house_roots.h1.get_meta("palette_colors"),cell);demo.town.Modern.roof(demo.town,current,h,demo.town.house_roots.h1.get_meta("palette_colors"),cell)
		for frame:Node3D in baseline.get_node(str(cell.id)).get_children():records.append_array(roof_signature(frame))
		for frame:Node3D in current.get_node(str(cell.id)).get_children():actual.append_array(roof_signature(frame))
	records.sort();actual.sort();check(records==actual,"unmerged production roof buffers exactly equal pre-feature builder "+str(h.architecture));baseline.queue_free();current.queue_free()
func body_physics(renderer)->Array:
	var result:Array=[]
	for cell:Dictionary in renderer.state.houses[0].cells:
		var node:Node3D=renderer.house_roots.h1.get_node(str(cell.id))
		for child:Node in node.get_children():
			if child is StaticBody3D:
				for shape:CollisionShape3D in child.get_children():
					if shape.shape is BoxShape3D:result.append([str(cell.id),shape.shape.size,shape.transform,node.transform])
	return result
func actual_faces(renderer)->PackedVector3Array:
	var faces:=PackedVector3Array();var house:Node3D=renderer.house_roots.h1;var inverse:=house.global_transform.affine_inverse()
	for shape:CollisionShape3D in house.find_children("ModernRoofPitchPick","CollisionShape3D",true,false):
		for p:Vector3 in shape.shape.get_faces():faces.append(inverse*shape.global_transform*p)
	return faces
func release_slider()->void:await send(control.slider.get_global_rect().get_center(),false)
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
		if arg.begins_with("--baseline-modern="):legacy_path=arg.trim_prefix("--baseline-modern=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control")
	if "--build-hit-only" in OS.get_cmdline_user_args():
		await roof_build_case();await modern_report(personal);return
	if "--garden-bounds-only" in OS.get_cmdline_user_args():
		await garden_bounds_case();await modern_report(personal);return
	if "--bakery-only" in OS.get_cmdline_user_args():
		await bakery_case();await modern_report(personal);return
	for kind:String in Fixture.KINDS:
		await show(Fixture.fixture(kind),Vector2(-25,-20),"现代调坡 "+kind);quiet();await legacy_check();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size();var original_body:=body_physics(demo.town)
		await open_editor();check(control.row.visible and control.slider.editable and "原顶" in control.label.text,"original modern roof exposes same native controls "+kind)
		await drag_slider(45.,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and control.prepared>44.,18000),"actual six-family detached preview completes "+kind)
		check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"modern slope preview is author/history pure "+kind)
		if control.current==null:quit(1);return
		var expected:=construction(control.current.renderer);await capture(kind+"_preview45");await release_slider();check(await wait_for(func():return not control.dragging and not control.committing,18000),"native release completes "+kind);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
		check(demo.state.snapshot().schema==38 and demo.state.houses[0].roof_pitch.version==3 and demo.state._undo.size()==depth+1 and demo.state.houses[0].cells==before.houses[0].cells,"one native transaction retains modern family/body and writes explicit schema38 "+kind)
		check(construction(demo.town)==expected and not actual_faces(demo.town).is_empty(),"candidate and published construction GPU buffers/rest transforms match with actual roof physics "+kind)
		var archived:Dictionary=demo.gallery.library.read(str(control.backup.id));var archived_city:=State.new();check(archived.ok and archived_city.restore(archived.world).ok and archived_city.houses==before.houses and int(archived_city.snapshot().schema)==int(before.schema),"first modern upgrade actually archives original recipe and old schema "+kind)
		var cold:=State.new();var saved:Dictionary=demo.state.snapshot();check(cold.restore(saved).ok and cold.houses==demo.state.houses,"actual published modern author data cold restores "+kind)
		var cold_preview:=Batch.new();cold_preview.start(demo,{"city":cold,"changed":["h1"]});var deadline:=Time.get_ticks_msec()+15000
		while not cold_preview.ready and Time.get_ticks_msec()<deadline:cold_preview.step();await process_frame
		check(cold_preview.ready and construction(cold_preview.renderer)==construction(demo.town),"independent cold State production renderer exactly matches published construction "+kind);cold_preview.clear()
		check(body_physics(demo.town)==original_body,"roof gesture preserves actual lower wall/floor collision geometry "+kind)
		await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h1.has_meta("modern_roof_pitch"),"one native Undo restores original family recipe "+kind)
		await key(KEY_Y,true);await settle();quiet();check(demo.state.houses[0].roof_pitch.version==3,"native Redo retains modern profile "+kind)
		for angle:float in [0.,78.]:
			await open_editor();await drag_slider(angle,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(float(control.current.renderer.state.houses[0].roof_pitch.degrees)-angle)<.2,18000),"flat/extreme preview completes before release "+kind+str(angle));var candidate:=construction(control.current.renderer);await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
			check(construction(demo.town)==candidate,"flat/extreme construction including garden stays identical through publication "+kind+str(angle))
			var h:Dictionary=demo.state.houses[0];var plan:=ModernGeometry.cell_plan(demo.state,h,h.cells[-1]);check(absf(float(h.roof_pitch.degrees)-angle)<.2 and demo.town.house_roots.h1.get_meta("modern_roofs")[0].alpine_kind==Fixture.KINDS.find(kind),"native flat/steep choices retain actual modern family "+kind+str(angle));await capture(kind+"_"+str(int(angle)))
			var apex:Vector3=demo.town.house_roots.h1.get_meta("modern_roof_pitch").apex;var hit:Dictionary=demo._ray_hit(demo.camera.unproject_position(apex-Vector3.UP*.03));check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1","actual modern roof apex is pickable "+kind+str(angle))
		await open_editor();await ui_click(control.reset);await settle();quiet();check(demo.state.houses==before.houses,"native original button restores exact older recipe "+kind)
	await modern_bridge_case()
	# Old schema35 recipe on modern architecture must not silently activate.
	var old:=Fixture.fixture("chalet");old.houses[0].roof_pitch={"version":1,"degrees":78.};await show(old,Vector2(-25,-20),"旧休眠坡度");await settle();quiet();check(not demo.town.house_roots.h1.has_meta("modern_roof_pitch"),"schema35 dormant ordinary data keeps old modern roof")
	await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(15.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);await key(KEY_ESCAPE);await release_slider();check(demo.state.snapshot()==before,"Esc retracts modern preview without activating old dormant recipe")
	root.size=Vector2i(1024,768);await settle();await open_editor();check(root.get_visible_rect().encloses(control.slider.get_global_rect()) and root.get_visible_rect().encloses(control.handle.get_global_rect()),"modern controls reachable at 1024 width")
	await drag_slider(45.,false);await wait_for(func():return control.current!=null and control.current.ready,18000);var empty:=State.new();empty.initialize_free();await show(empty,Vector2(-25,-20),"过期现代预演撤回");await settle();quiet();check(control.current==null and control.pending==null and demo.state.houses.is_empty(),"changing city retracts unfinished modern geometry")
	await modern_report(personal)

func modern_report(personal:PackedByteArray)->void:
	check(FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal and not demo.persistence,"personal bytes remain unchanged after complete modern case")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("MODERN_ROOF_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)

func modern_bridge_case()->void:
	var city:=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.set_house_era("h1","modern_eco");city.set_house_architecture("h1","pavilion");city.set_house_roof_pitch("h1",0.)
	for at:Vector2 in [Vector2(-30,-20),Vector2(-21.5,-20)]:city.add_house(at)
	for id:String in ["h2","h3"]:city.set_house_era(id,"modern_eco");city.add_cell(id,0,0,1);city.add_cell(id,0,0,2)
	city.set_house_skybridge_span("h3",true);await show(city,Vector2(-25,-20),"现代坡顶与九米云廊净空");await settle();quiet()
	check(not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"actual nine-metre cloud bridge clears low modern roof")
	await open_editor();var before:Dictionary=demo.state.snapshot();await drag_slider(78.,false);check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and control.prepared>77.,18000),"steep modern preview includes affected cloud bridge roofs")
	if control.current==null:return
	check(control.current.ids.has("h2") and control.current.renderer.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.snapshot()==before,"pure modern geometry preview retracts physically blocked existing cloud bridge")
	await capture("modern_bridge_blocked_preview");await release_slider();await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty() and demo.state.houses[2].skybridge_span==before.houses[2].skybridge_span,"publication removes obstructed cloud bridge while retaining nine-metre author choice")
	await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.h2.get_meta("skybridges",[]).is_empty(),"one Undo restores physical modern roof and real cloud bridge")

func bakery_case()->void:
	var city:=Fixture.fixture("pavilion");city.set_house_role("h1","bakery");city.set_house_roof_pitch("h1",78.);await show(city,Vector2(-25,-20),"陡坡面包房烟囱");await settle();quiet()
	var house:Dictionary=demo.state.houses[0];var plan:=ModernGeometry.cell_plan(demo.state,house,house.cells[-1]);var caps:Array=plan.parts.filter(func(p):return p.name=="ModernChimneyCap");var root_node:Node3D=demo.town.house_roots.h1
	check(caps.size()==1 and root_node.get_meta("chimneys",[]).size()==1 and not root_node.find_children("BakerySmoke*","MeshInstance3D",true,false).is_empty(),"actual steep modern bakery retains physical stack and bound smoke emitter")
	if caps.is_empty():return
	var local:Vector3=caps[0].at+Vector3.UP*.035;var angle:=atan2(float(plan.front.x),float(plan.front.y));var cap_top:Vector3=Pitch.Frame.world3(house,demo.town._cell_position(house,house.cells[-1])+Basis(Vector3.UP,angle)*local)
	var hit:Dictionary=demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cap_top+Vector3.UP*2.,cap_top-Vector3.UP*.1))
	check(not hit.is_empty() and hit.collider.get_meta("house_id","")=="h1" and absf(hit.position.y-cap_top.y)<.001,"vertical ray hits actual generated cap at its measured height")
	check(root_node.get_meta("chimneys")[0].distance_to(cap_top+Vector3.UP*.01)<.001,"smoke outlet follows actual sloped roof chimney cap")
	await capture("steep_modern_bakery")

func garden_bounds_case()->void:
	var city:=Fixture.fixture("terrace");city.set_house_roof_pitch("h1",15.);await show(city,Vector2(-25,-20),"屋顶花园实际包络");await settle();quiet();await open_editor();await drag_slider(0.,false)
	check(await wait_for(func():return control.current!=null and control.current.ready and control.pending==null and absf(float(control.current.renderer.state.houses[0].roof_pitch.degrees))<.2,15000),"supported low-slope garden preview completes")
	var expected:=construction(control.current.renderer);await release_slider();await wait_for(func():return not control.dragging and not control.committing,15000);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has("h1"),2500)
	check(construction(demo.town)==expected,"grounded garden and physical support preserve exact preview/published buffers")
	var seen:Array=[];var details:Array=[]
	for index in range(1,100):
		var house:Dictionary=demo.state.houses[0].duplicate(true);house.id="h"+str(index);var cell:Dictionary=house.cells[-1];var kind:int=demo.town.Modern.Archetypes.roof_kind(house,cell)
		if kind in seen:continue
		seen.append(kind);var stub:=Node3D.new();demo.add_child(stub)
		var node:=Node3D.new();node.name=str(cell.id);stub.add_child(node);demo.town.Modern.roof(demo.town,stub,house,demo.town.house_roots.h1.get_meta("palette_colors"),cell)
		var roof:Node3D=node.get_child(0);var garden:Node3D=roof.find_child("PitchedRoofGarden",true,false);var inverse:=roof.global_transform.affine_inverse();var bounds:=AABB();var first:=true
		for mesh:MeshInstance3D in garden.find_children("*","MeshInstance3D",true,false):
			var actual: AABB=inverse*mesh.global_transform*mesh.get_aabb();bounds=actual if first else bounds.merge(actual);first=false
		var plan:=ModernGeometry.cell_plan(demo.state,house,cell);var parts:Array=plan.parts.filter(func(p):return p.type=="garden");var part:Dictionary=parts[0];var declared:=AABB(part.at-Vector3(part.size.x*.5,0,part.size.z*.5),part.size)
		check(not first and declared.grow(.001).encloses(bounds),"actual complete roof garden stays within CPU clearance envelope "+str(kind))
		var supports:Array=plan.parts.filter(func(p):return p.name=="RoofGardenPlinth");var support:Dictionary=supports[0];check(absf(bounds.position.y-(support.at.y+support.size.y*.5))<.001,"actual retained garden feet contact the real supporting plinth "+str(kind));details.append({"kind":kind,"actual":str(bounds),"declared":str(declared)});stub.queue_free()
		if seen.size()==4:break
	check(seen.size()==4,"all four retained modern garden recipes measured");facts.garden_bounds=details

func roof_build_case()->void:
	for kind:String in Fixture.KINDS+["ordinary","round_tower"]:
		var city:RefCounted
		if kind in ["ordinary","round_tower"]:
			city=State.new();city.initialize_free();city.add_house(Vector2(-25,-20));city.add_cell("h1",0,0,1)
			if kind=="round_tower":city.set_house_style("h1","round_tower")
		else:city=Fixture.fixture(kind)
		city.set_house_roof_pitch("h1",78.);await show(city,Vector2(-25,-20),"陡屋面真实加层 "+kind);await settle();quiet();demo.spatial_popover.close();demo.select_tool(0);demo.focus=Vector3(-25,4.5,-20);demo.zoom=24.;demo._update_camera();await process_frame
		var house_root:Node3D=demo.town.house_roots.h1;var apex:=Vector3.ZERO
		if house_root.has_meta("modern_roof_pitch"):apex=house_root.get_meta("modern_roof_pitch").apex
		elif house_root.has_meta("round_tower"):
			var tower:Dictionary=house_root.get_meta("round_tower");apex=Vector3(tower.center.x,tower.roof_top_y,tower.center.y)
		else:
			var highest:=-INF
			for patch:Dictionary in Pitch.patches(demo.state,demo.state.houses[0]):
				for point:Vector3 in patch.vertices:
					if point.y>highest:highest=point.y;apex=point
		var at:Vector2=demo.camera.unproject_position(apex-Vector3.UP*.03);var hit:Dictionary=demo._ray_hit(at);var before:Dictionary=demo.state.snapshot();var resolved:Dictionary=preload("res://scripts/ui/city_creation_unified_build.gd").resolve(demo.state,hit,Vector2(-25,-20))
		check(not hit.is_empty() and resolved.has("cell") and resolved.cell.level==2 and resolved.cell.kind=="room" and resolved.valid,"actual steep roof hit still means add floor above, not a lateral terrace "+kind)
		await pointer(at);await send(at,true);await send(at,false);await settle();quiet();check(demo.state.houses[0].cells.size()==before.houses[0].cells.size()+1 and demo.state.houses[0].cells[-1].level==2 and demo.state.houses[0].roof_pitch==before.houses[0].roof_pitch,"native click on steep roof creates one real upper room and retains slope "+kind)
		await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses,"one Undo returns exact two-floor pitched building "+kind)
