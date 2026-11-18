extends "res://tools/check_game_music_live.gd"
const Context=preload("res://scripts/audio/city_creation_expression_context.gd")
func waterfront(manifest:String)->void:
	var fixture:=Fixture.courtyard("ring","none");var city:RefCounted=fixture.city
	var pond:Dictionary=city.add_water([Fixture.ORIGIN+Vector2(0,-2.5)] as Array[Vector2],2.,"pond")
	check(fixture.ok and pond.ok,"author closed courtyard beside water")
	await show(city,Fixture.ORIGIN+Vector2(3.6,3.6),"临水院落");quiet();city=demo.state
	var ticket:=GamePlayer.request(demo.music,manifest);var node:Node=ticket.node
	check(await wait_for(func():return node.active,30000),"same city activates candidate player")
	var water_id:String=city.waters[0].id
	check(await wait_for(func():return node.values.get("body",0.)>.94 and node.values.get("motion",0.)>.94,35000),"both recorded layers build up beside the enclosed shore")
	var wave:AudioStream=node.player.stream;var clock:float=node.clock
	facts.closed={"body":node.values.body,"motion":node.values.motion,"enclosure":node.spatial_facts.enclosure,"flow":node.spatial_facts.flow}
	var removed:Dictionary={};var cells:Array=city.houses[0].cells.filter(func(cell):return cell.z==4 and cell.x>0 and cell.x<4)
	check(cells.size()==3,"opening targets the three middle rooms on one side")
	for cell:Dictionary in cells:
		removed=city.remove_cell("h1",cell.id);check(removed.ok,"open courtyard room "+str(cell.id))
	demo._after_edit(removed,"erase");await settle()
	var min_motion:float=node.values.motion
	var end:=Time.get_ticks_msec()+16000
	while Time.get_ticks_msec()<end:
		await process_frame;min_motion=minf(min_motion,node.values.motion)
	facts.open={"body":node.values.body,"motion":node.values.motion,"min_motion":min_motion,"enclosure":node.spatial_facts.enclosure,"flow":node.spatial_facts.flow,"flow_sources":node.spatial_facts.flow_sources}
	check(node.spatial_facts.enclosure<facts.closed.enclosure and node.values.body<facts.closed.body-.1,"opening the court reduces body on the playing song")
	check(node.spatial_facts.flow_sources.has(water_id) and min_motion>.9,"surviving shore keeps its source and motion gain throughout observation")
	check(node.player.stream==wave and node.clock>clock,"the original stream and song clock continue")
	node.stop();await process_frame
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not OS.get_cmdline_user_args().has("--isolated-session") or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60;var began:=Time.get_ticks_msec();var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"));var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.catalog));var manifest:String=catalog.packs[0].manifest
	demo=Scene.instantiate();demo.persistence=false;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input()
	if "--waterfront" in OS.get_cmdline_user_args():
		await waterfront(manifest);check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save unchanged")
		var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
		FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("WATERFRONT_MIX ",JSON.stringify(result));demo.queue_free();await process_frame;quit(0 if result.ok else 1);return
	var f:=Fixture.courtyard("U","none");await show(f.city,Fixture.ORIGIN+Vector2(3.6,3.6),"半围合 · 独立暖度");quiet();demo.life.set_process(false)
	var ticket:=GamePlayer.request(demo.music,manifest);var node:Node=ticket.node;check(await wait_for(func():return node.active,30000),"real half court candidate loads")
	var record:=Span.start();await create_timer(18.).timeout
	check(node.spatial_facts.enclosure>=.55 and node.spatial_facts.enclosure<=.8 and node.values.body>.73,"actual half court warms same source after observation")
	var signature:String=node.prepared.signature;var position:float=node.player.get_playback_position();var clock:float=node.clock;node.set_paused(true);await create_timer(.3).timeout;check(node.clock==clock,"new warm expression pauses observation");node.set_paused(false)
	facts.pcm=Span.finish(record,OUT+"/half_court_Master.wav");check(facts.pcm.ok,"actual adapted WASAPI PCM non-silent and unclipped");await capture("half_court")
	node.stop();await process_frame
	var hill:=State.new();hill.initialize_free();var plan:Dictionary=hill.plan_terrain_target([Vector2(-28,-20)] as Array[Vector2],5.,3.2,true)
	check(plan.ok and hill.apply_terrain_target(plan).ok and hill.add_house(Vector2(-28,-20)).ok and hill.add_house(Vector2(-19,-20)).ok,"actual high and low terrain houses")
	await show(hill,Vector2(-24,-20),"高差轮廓 · 独立慢染色");quiet();demo.life.set_process(false)
	ticket=GamePlayer.request(demo.music,manifest);node=ticket.node;check(await wait_for(func():return node.active,30000),"highland candidate activates")
	await create_timer(5.).timeout;check(node.values.motion==.35 and node.contour_value==0.,"brief highland focus cannot bypass common observation")
	await create_timer(13.).timeout;check(node.spatial_facts.flow==0. and node.contour_value>.55 and node.values.motion>.43,"pure highland contour changes real motion gain through independent observed envelope")
	await capture("highland_contour");node.stop();await process_frame
	var tea:RefCounted=preload("res://tests/test_city_creation_tea_deck.gd").populated(OUT)
	await show(tea,Vector2(-28,-20),"真实茶叙 · 点缀归因");quiet();demo.life.set_process(false)
	var seated:=false
	for i in range(6000):
		if demo.life.cafe_status("h1").phase=="tea":seated=true;break
		demo.life._process(.05)
	check(seated and demo.state.bakery_status("h4").served>=2,"scene owns actual paid and seated tea activity")
	var facts_before:Dictionary=demo.state.snapshot();ticket=GamePlayer.request(demo.music,manifest);node=ticket.node;check(await wait_for(func():return node.active,30000),"candidate binds to actual scene Life")
	await process_frame;await process_frame
	check(node.spatial_facts.visible_activity.value>0. and node.spatial_facts.visible_activity.source_ids==["h1"],"automatic player attributes real visible tea once per cafe")
	check(demo.state.snapshot()==facts_before,"activity audio sampling changes no city state")
	await capture("tea_activity");node.stop();await process_frame
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal default file remains byte-identical")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"pcm":facts.pcm,"default_changed":false,"listening_approved":false};FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("EXPRESSION_CONTEXT_LIVE ",JSON.stringify(report));demo.queue_free();await process_frame;quit(0 if report.ok else 1)
