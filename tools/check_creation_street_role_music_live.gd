extends "res://tools/check_creation_three_road_modes_live.gd"
const Street=preload("res://tools/fixtures/city_creation_market_frontages_fixture.gd")
const GamePlayer=preload("res://scripts/audio/city_creation_game_music_player.gd")
const Recording=preload("res://tools/fixtures/city_creation_recording_span.gd")

func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):
		quit(1)
		return
	var began:=Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size=Vector2i(1440,900)
	Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH)
	demo=Scene.instantiate()
	demo.persistence=false
	demo.collection_directory=OUT+"/works"
	root.add_child(demo)
	await settle()
	isolate_input()
	var street:=Street.mixed_street()
	var city:RefCounted=street.city
	var shore_start:=Vector2(-30,-23.)
	var pond:Dictionary=city.add_water([shore_start] as Array[Vector2],2.4,"pond")
	var channel:Dictionary=city.add_water([shore_start,Vector2(-14,-23.)] as Array[Vector2],2.4,"channel")
	check(street.ok and pond.ok and channel.ok,"build four connected shops and an independent watercourse")
	await show(city,Vector2(-22,-20),"沿街用途与水岸音乐")
	quiet()
	demo.select_tool(4)
	city=demo.state
	var snapshot:Dictionary=city.snapshot()
	var pointer:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/active_game_music.json"))
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(pointer.catalog))
	var ticket:=GamePlayer.request(demo.music,catalog.packs[0].manifest)
	check(ticket.ok,"request the real opted-in game music candidate")
	var node:Node=ticket.get("node")
	var active:=await wait_for(func():return is_instance_valid(node) and node.active,30000)
	check(active,"candidate borrows the scene player")
	if active:
		await verify_edit(node,snapshot)
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH),"personal save remains byte-identical")
	var result:={"checks":checks,"failures":failures,"facts":facts,"seconds":(Time.get_ticks_msec()-began)/1000.}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("STREET_ROLE_MUSIC ",JSON.stringify(result))
	demo.queue_free()
	await process_frame
	quit(int(not failures.is_empty()))

func sample(node:Node)->Dictionary:
	return {"clock":node.clock,"position":node.player.get_playback_position(),"motion":node.values.get("motion"),"flow":node.spatial_facts.flow,"flow_sources":node.spatial_facts.flow_sources.duplicate(),"craft":node.spatial_facts.craft,"craft_sources":node.spatial_facts.craft_sources.duplicate()}

func verify_edit(node:Node,snapshot:Dictionary)->void:
	var city:RefCounted=demo.state
	var pop=demo.spatial_popover
	var root_before:Node=demo.town.house_roots.h3
	check(root_before.find_child("WorkshopLute",true,false)!=null,"connected workshop has its wooden lute sign")
	demo.selected_house="h3"
	pop.open_for_house("h3")
	await settle()
	await ui_click(pop.inspector.appearance_button)
	await settle()
	await ui_click(pop.inspector.purpose_button)
	check(pop.inspector.roles.panel.is_visible_in_tree(),"purpose palette opens from the house inspector")
	check(await wait_for(func():return node.values.get("motion",0.)>.53,28000),"water motion enters before the purpose edit")
	var wave:AudioStream=node.player.stream
	facts.before=sample(node)
	var recording:=Recording.start()
	await ui_click(pop.inspector.roles.buttons.residential)
	await settle()
	check(city.houses[2].role=="residential","purpose button changes the workshop to a home")
	check(demo.town.house_roots.h3.find_child("WorkshopLute",true,false)==null,"published housing facade drops the workshop sign")
	facts.changed=sample(node)
	await key(KEY_Z,true)
	await settle()
	var restored:Dictionary=city.snapshot()
	check(restored.houses==snapshot.houses and restored.roads==snapshot.roads and restored.waters==snapshot.waters,"Ctrl+Z restores houses and keeps road and water geometry")
	check(demo.town.house_roots.h3.find_child("WorkshopLute",true,false)!=null,"Undo restores the workshop sign")
	facts.restored=sample(node)
	for label:String in ["changed","restored"]:
		var stage:Dictionary=facts[label]
		check(stage.flow_sources==facts.before.flow_sources and is_equal_approx(stage.flow,facts.before.flow),"water facts survive "+label)
		check(stage.craft_sources==facts.before.craft_sources and is_equal_approx(stage.craft,facts.before.craft),"ordinary use label leaves shape-based craft facts unchanged: "+label)
		check(stage.motion>=facts.before.motion-.02 and stage.position>=facts.before.position and stage.clock>facts.before.clock,"playing water layer continues: "+label)
	check(node.player.stream==wave,"role edit and Undo keep the original stream")
	facts.pcm=Recording.finish(recording,OUT+"/Master.wav")
	check(facts.pcm.ok,"WASAPI Master recording is non-silent and unclipped")
	node.stop()
