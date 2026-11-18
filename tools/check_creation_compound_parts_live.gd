extends "res://tools/check_creation_roof_pitch_live.gd"
const CompoundFixture=preload("res://tests/test_city_creation_compound_parts.gd")
const Parts=preload("res://scripts/world/city_creation_compound_parts.gd")
var compound:Node
func open_compound()->void:
	await open_editor();await ui_click(compound.box.find_child("CompoundOpen",true,false));await wait_for(func():return compound.preview!=null and compound.preview.ready,15000)
func geometry(renderer,id:String)->Array:
	var rows:Array=[]
	var house:Node3D=renderer.house_roots[id]
	for mesh:MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		if mesh.name in ["ResonanceVisualRig","ResonanceArc"]:continue
		var at:Node=mesh.get_parent();var rest:Transform3D=mesh.transform
		while at!=house:
			var transform:Transform3D=at.transform
			if at.name=="ResonanceVisualPivot":transform.basis=Basis.IDENTITY
			rest=transform*rest;at=at.get_parent()
		for i in range(mesh.mesh.get_surface_count()):rows.append(hash([mesh.mesh.surface_get_arrays(i),rest]))
	rows.sort();return rows
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();control=demo.get_meta("roof_pitch_control");compound=demo.get_meta("compound_controls")
	await show(CompoundFixture.fixture(),Vector2(-23,-19.5),"主楼与独立屋顶塔楼");await settle();quiet();var before:Dictionary=demo.state.snapshot();var depth:int=demo.state._undo.size()
	await open_compound();check(compound.preview!=null and compound.preview.ready and compound.choices.is_visible_in_tree(),"native details opens detached real compound preview")
	check(demo.state.snapshot()==before and demo.state._undo.size()==depth,"pure preview preserves real authors, history and IDs")
	check(root.get_visible_rect().encloses(compound.accept.get_global_rect()),"compound commit remains inside 1440 window")
	var id:String=str(compound.plan.house_id);var expected_palette:Array=compound.preview.renderer.house_roots[id].get_meta("palette_colors");var expected:=geometry(compound.preview.renderer,id);var root_preview:Node3D=compound.preview.renderer.house_roots[id];var joints:Array=root_preview.get_meta("round_joints",[])
	check(joints.size()==2 and root_preview.get_meta("round_windows",[]).size()+root_preview.get_meta("round_door_frames",[]).size()==10,"real two-floor masonry seam suppresses buried tower windows")
	check(root_preview.find_children("RoundTowerWallJointPick*","CollisionShape3D",true,false).size()==2,"actual connecting masonry has real picking shapes")
	await capture("castle_pure_preview");await ui_click(compound.accept);check(await wait_for(func():return demo.state.houses.size()==2 and not compound.committing,18000),"native commit creates real independently selectable tower")
	await settle();quiet();await wait_for(func():return not demo.town.touch.active.has(id),2500)
	if not demo.town.house_roots.has(id):await capture("commit_failed");print("COMPOUND_COMMIT_FAILED");quit(1);return
	check(demo.state._undo.size()==depth+1 and demo.state.houses[0]==before.houses[0] and demo.state.snapshot().schema==37,"native compound edit is one Undo and main author data remains exact")
	check(demo.town.house_roots[id].get_meta("palette_colors")==expected_palette and geometry(demo.town,id)==expected,"detached candidate and actual published tower have identical construction GPU buffers")
	var archived:Dictionary=demo.gallery.library.entries();var retained:=false
	for entry:Dictionary in archived.items:
		if entry.reason=="before_compound_parts":
			var old:Dictionary=demo.gallery.library.read(str(entry.id));var old_city:=State.new();retained=old.ok and old_city.restore(old.world).ok and old_city.houses==before.houses
	check(retained,"first schema37 edit actually archives exact original city before committing")
	var saved:Dictionary=demo.state.snapshot();var cold:=State.new();check(cold.restore(saved).ok and cold.houses==demo.state.houses,"native published compound cold restores all part recipes")
	await capture("castle_published");await key(KEY_Z,true);await settle();quiet();check(demo.state.houses==before.houses and not demo.town.house_roots.has(id),"native Undo removes complete real tower and seam")
	await key(KEY_Y,true);await settle();quiet();check(demo.state.houses==saved.houses and demo.town.house_roots[id].has_meta("round_tower"),"native Redo restores cylindrical part without square fallback")
	await open_editor();var protected:Dictionary=demo.state.snapshot();depth=demo.state._undo.size();await drag_slider(78.,false)
	check(await wait_for(func():return control.prepared>77. and control.pending==null,15000) and control.current==null and "塔檐" in control.label.text,"native steep main preview rejects actual tower-eave conflict without square fallback")
	await send(control.slider.get_global_rect().get_center(),false);await process_frame;check(demo.state.snapshot()==protected and demo.state._undo.size()==depth,"invalid main roof release preserves all compound author data and history")
	demo.spatial_popover.close();await settle();var tower:Dictionary=demo.town.house_roots[id].get_meta("round_tower");var at:Vector2=demo.camera.unproject_position(Vector3(tower.center.x,float(tower.roof_top_y)-.02,tower.center.y));await pointer(at);await send(at,true);await send(at,false);await process_frame
	check(demo.spatial_popover.target_house_id==id,"native roof picking directly selects tower part instead of main building")
	# Open the tower, not the main: existing pitch control targets this part alone.
	demo.spatial_popover.open_for_house(id);await settle();await ui_click(demo.spatial_popover.inspector.appearance_button);await settle();check(control.row.visible,"tower has its own existing roof editing controls")
	var main:Dictionary=demo.state.houses[0].duplicate(true);await drag_slider(0.);await wait_for(func():return not control.dragging and not control.committing,18000);await settle();quiet();check(demo.state.houses[0]==main and demo.state.houses[1].roof_pitch.degrees<.2,"native tower slider makes flat cap without flattening main roof")
	await capture("castle_flat_tower");await open_compound();await ui_click(compound.box.find_child("CompoundSide0",true,false));await wait_for(func():return compound.preview!=null and compound.preview.ready,18000)
	check(demo.state.houses.size()==2,"second local part preview has no author side effects")
	await key(KEY_ESCAPE);await process_frame;check(compound.preview==null and demo.state.houses.size()==2,"native Esc cancels compound preview and preserves existing tower")
	await open_compound();await ui_click(compound.box.find_child("CompoundSide0",true,false));await ui_click(compound.kinds[1])
	check(await wait_for(func():return compound.kind==1 and compound.preview!=null and compound.preview.ready,18000),"native shape selector chooses real independently roofed square wing")
	if compound.plan.get("ok",false):
		var square_id:String=str(compound.plan.house_id);var expected_square:=geometry(compound.preview.renderer,square_id);await ui_click(compound.accept);await settle();quiet();await wait_for(func():return not demo.town.touch.active.has(square_id),2500)
		check(demo.state.houses.size()==3 and demo.state.houses[-1].roof_pitch.degrees==0. and geometry(demo.town,square_id)==expected_square,"native flat square wing publishes exact preview beside pitched main and cylindrical tower")
		var low:=INF;var high:=-INF;var points:=0
		for body:StaticBody3D in demo.town.house_roots[square_id].find_children("RoofPitchPick*","StaticBody3D",true,false):
			for shape:CollisionShape3D in body.get_children():
				for p:Vector3 in shape.shape.get_faces():low=minf(low,p.y);high=maxf(high,p.y);points+=1
		check(points>0 and high-low<.0001,"flat square part is an actual horizontal picked roof plane in the published game")
		await capture("three_part_castle")
	root.size=Vector2i(1024,768);await settle();await open_compound();check(root.get_visible_rect().encloses(compound.accept.get_global_rect()),"actual compound controls fit 1024 window")
	await capture("castle_controls_1024");var replacement:=State.new();replacement.initialize_free();await show(replacement,Vector2(-25,-20),"撤回过期组合预演");await settle();quiet();check(compound.preview==null and demo.state.houses.is_empty(),"city switch retracts every unpublished compound root")
	check(FileAccess.get_file_as_bytes(State.DEFAULT_PATH)==personal and not demo.persistence,"personal bytes unchanged and persistence stays false")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("COMPOUND_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
