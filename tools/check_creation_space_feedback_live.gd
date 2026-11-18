extends "res://tools/check_creation_wall_shadow_live.gd"
const Fixture=preload("res://tools/fixtures/city_creation_space_contract_fixture.gd")
const Guidance=preload("res://scripts/ui/city_creation_free_spatial_guidance.gd")
const Description=preload("res://scripts/ui/city_creation_space_description.gd")

func inspect(label:String,expected:String)->void:
	demo.select_tool(0);demo.spatial_popover.open_for_house("h1")
	await create_timer(.65).timeout
	var status:Label=demo.spatial_popover.status
	var text:String=Guidance.inspector(demo.state,"h1").text
	check(expected in text and status.text==text and status.tooltip_text==text,"selected house explains actual space: "+label)
	var before:Dictionary=demo.state.snapshot()
	await ui_click(demo.spatial_popover.inspector.business_button)
	await create_timer(.3).timeout
	check(demo.ledger.visible(),"existing house action opens L: "+label)
	for space:Dictionary in demo.state.functional_zones().spaces:
		if "h1" in space.members:
			check(Description.detail(space,true) in demo.ledger.body.text,"L and inspector share published reason: "+label)
	check(before==demo.state.snapshot(),"reading house and L preserves author data: "+label)
	await key(KEY_ESCAPE)

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if DisplayServer.get_name()=="headless" or not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1024,768);Engine.max_fps=60
	var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet()
	var built:=Fixture.courtyard();check(built.ok,"public courtyard and real through road")
	await show(built.city,Vector2(-24.4,-16.4),"空间营造反馈");quiet();await inspect("connected courtyard","成区 · 真实院落")
	demo.spatial_popover.open_for_house("h1");await create_timer(.65).timeout;await capture("court_selected_day")
	demo._set_light_phase(2);await capture("court_selected_night")
	demo.spatial_popover.close();demo._after_edit(demo.state.remove_road("r1"),"history");await settle();quiet()
	var disconnected:Dictionary=Guidance.inspector(demo.state,"h1")
	check("局部空间 · 真实院落 · 需要通向院内的公共入口" in disconnected.text and disconnected.tool==2,"road removal exposes missing public portal and retains road action")
	await key(KEY_Z,true);await settle();quiet();await inspect("Undo","成区 · 真实院落")
	var path:=OUT+"/court.json";check(demo.state.save_city(path).ok,"isolated work saves")
	var cold:=State.new();check(cold.load_city(path).ok,"independent disk cold read")
	await show(cold,Vector2(-24.4,-16.4),"空间反馈冷读");quiet();await inspect("cold read","成区 · 真实院落")
	var half:=Fixture.courtyard("U");check(half.ok,"public half enclosure")
	await show(half.city,Vector2(-24.4,-16.4),"半院反馈");quiet();await inspect("half enclosure","半围合")
	for item:Dictionary in Fixture.other_kinds():
		check(item.ok,"public "+item.kind+" fixture")
		await show(item.city,Fixture.ORIGIN,"混合时代空间");quiet()
		await inspect(item.kind,{"waterfront":"面水公共界面","artisan":"百工前庭","civic":"礼乐前场"}[item.kind])
		var spaces:Array=demo.state.functional_zones().spaces.filter(func(space):return "h1" in space.members)
		var rank:={"trait":0,"cluster":1,"district":2};var highest:=0
		for space:Dictionary in spaces:highest=maxi(highest,rank[space.stage])
		check(Guidance.inspector(demo.state,"h1").text.begins_with(["特色","局部空间","成区"][highest]),"caption matches strongest actual stage without granting eligibility: "+item.kind)
	check(not demo.persistence and personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"scope":"Published spatial feedback only; no music, author schema or eligibility changes."}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SPACE_FEEDBACK ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
