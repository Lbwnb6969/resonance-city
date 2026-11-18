extends "res://tools/check_game_music_live.gd"
## Controlled enclosure A/B on one actual packet; no manual expression override.
var ab_rows:Array=[]
func observe(node:Node,label:String,seconds:float)->void:
	var trace:Array=[];var end:=Time.get_ticks_msec()+int(seconds*1000.)
	while Time.get_ticks_msec()<end:
		await create_timer(.2).timeout;trace.append(game_packet())
	ab_rows.append({"label":label,"packet":game_packet(),"trace":trace})
func excerpt(node:Node,label:String)->Dictionary:
	node.set_paused(true);check(node.seek(20.),"same full-song position for "+label)
	var gains:Dictionary=node.values.duplicate();var record:=Span.start();node.set_paused(false)
	await create_timer(2.).timeout;node.set_paused(true)
	var pcm:Dictionary=Span.finish(record,OUT+"/"+label+"_Master.wav")
	check(pcm.ok,"actual synchronized source excerpt "+label)
	return {"start_seconds":20.,"gains_before":gains,"gains_after":node.values.duplicate(),"pcm":pcm}
func run()->void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--out-dir="):OUT=arg.trim_prefix("--out-dir=")
	if not "--isolated-session" in OS.get_cmdline_user_args() or not OUT.begins_with("res://验证记录/") or DirAccess.dir_exists_absolute(OUT):quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));root.size=Vector2i(1440,900);Engine.max_fps=60
	var personal:=FileAccess.get_file_as_bytes(State.DEFAULT_PATH);var began:=Time.get_ticks_msec()
	demo=Scene.instantiate();demo.persistence=false;demo.start_empty=true;demo.collection_directory=OUT+"/works";root.add_child(demo);await settle();isolate_input();quiet();var voices:=pool()
	if "--color-ab" in OS.get_cmdline_user_args():await colors(personal,voices,began);return
	if "--topology-ab" in OS.get_cmdline_user_args():await topology(personal,voices,began);return
	var fixture:=Fixture.courtyard("ring","none")
	await show(fixture.city,Fixture.ORIGIN+Vector2(3.6,3.6),"同源空间 A/B · 围合与留白");quiet();demo.life.set_process(false)
	var city:RefCounted=demo.state;var original:Dictionary=city.snapshot()
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/游戏音乐包/20261103_v1/catalog.json"))
	var path:String=catalog.packs[0].manifest;var requested:Dictionary=GamePlayer.request(demo.music,path)
	check(requested.ok,"existing same-source candidate request")
	if not requested.ok:quit(1);return
	var node:Node=requested.node
	check(await wait_for(func():return node.active,30000),"real four-layer packet prepared")
	if not node.active:quit(1);return
	var signature:String=node.prepared.signature;var source:String=node.prepared.manifest.source_id
	var player_id:int=node.player.get_instance_id();var stream_id:int=node.player.stream.get_instance_id()
	var core:AudioStreamWAV=node.prepared.stream.get_sync_stream(0);var core_id:int=core.get_instance_id()
	check(not node.manual_expression and node.values.core==1. and city.roads.is_empty(),"automatic expression from actual unconnected court with intact core")
	print("SAME_SOURCE_AB closed")
	await observe(node,"closed",18.)
	check(node.spatial_facts.enclosure==1. and node.values.body>.95,"real enclosure reaches observed warm gain")
	var closed:Dictionary=await excerpt(node,"A_closed");await capture("A_closed")
	node.set_paused(false);var result:Dictionary=city.remove_house("h1");check(result.ok,"remove only actual courtyard owner")
	demo._after_edit(result,"erase");await settle();quiet();demo.life.set_process(false)
	print("SAME_SOURCE_AB open")
	await observe(node,"open",7.)
	check(node.spatial_facts.source_ids.is_empty() and is_equal_approx(node.values.body,.35),"deleted enclosure withdraws facts and resolves open gain")
	var opened:Dictionary=await excerpt(node,"B_open");await capture("B_open")
	node.set_paused(false);await key(KEY_Z,true);await settle();quiet();demo.life.set_process(false)
	print("SAME_SOURCE_AB undo")
	await observe(node,"restored",18.)
	check(city.houses==original.houses and node.spatial_facts.enclosure==1. and node.values.body>.95,"native Undo restores exact authored geometry and warm expression")
	var restored:Dictionary=await excerpt(node,"A_restored")
	check(node.prepared.signature==signature and node.prepared.manifest.source_id==source and node.player.get_instance_id()==player_id and node.player.stream.get_instance_id()==stream_id and node.prepared.stream.get_sync_stream(0).get_instance_id()==core_id and node.values.core==1.,"one full-source player stream and core remain identical across real A/B/Undo")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and pool()==voices,"personal save and pooled voice limits unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"rows":ab_rows,"excerpts":{"closed":closed,"open":opened,"restored":restored},"source_id":source,"manifest":path,"signature":signature,"listening_approved":false,"boundary":"same complete source/core and seek20s; automatic color layers only; no claim of equal loudness, altered lead, new instrumentation, or human listening approval","works":demo.collection_directory}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("SAME_SOURCE_AB ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}));node.stop();demo.queue_free();await process_frame;quit(0 if report.ok else 1)

func colors(personal:PackedByteArray,voices:Dictionary,began:int)->void:
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/游戏音乐包/20261103_v1/catalog.json"))
	var path:String=catalog.packs[0].manifest;var runs:Array=[]
	for kind:String in ["water","craft"]:
		var city:=State.new();city.initialize_free()
		if kind=="water":
			check(city.add_house(Fixture.ORIGIN).ok and city.add_water([Fixture.ORIGIN+Vector2(0,-2.5)] as Array[Vector2],2.,"pond").ok,"actual water beside ordinary inland dwelling")
		else:
			for f:Dictionary in Fixture.other_kinds():
				if f.kind=="artisan":city=f.city
			check(city.remove_road(city.roads[0].id).ok,"artisan geometry works without a connected business")
		await show(city,Fixture.ORIGIN,"同源空间 A/B · "+kind);quiet();demo.life.set_process(false);city=demo.state
		var authored:Dictionary=city.snapshot();var requested:Dictionary=GamePlayer.request(demo.music,path)
		check(requested.ok,"explicit same source request "+kind)
		if not requested.ok:continue
		var node:Node=requested.node;check(await wait_for(func():return node.active,30000),"actual packet activation "+kind)
		if not node.active:node.stop();continue
		var signature:String=node.prepared.signature;var player_id:int=node.player.get_instance_id();var stream_id:int=node.player.stream.get_instance_id()
		var record:=Span.start();ab_rows=[]
		print("COLOR_AB active ",kind);await observe(node,kind+"_active",18.)
		var field:String="flow" if kind=="water" else "craft";var layer:String="motion" if kind=="water" else "detail"
		check(not node.manual_expression and node.spatial_facts[field]>=.55 and not node.spatial_facts[field+"_sources"].is_empty() and node.values[layer]>.65,"actual geometry warms automatic "+field)
		await capture(kind+"_active")
		var result:Dictionary=city.remove_water_at(Fixture.ORIGIN+Vector2(0,-2.5)) if kind=="water" else city.PlacedLandmarks.place(city,"courtyard",Fixture.ORIGIN+Vector2(3.1,3.8))
		check(result.ok,"real source withdrawal or forecourt obstruction "+kind)
		demo._after_edit(result,"water" if kind=="water" else "landmark");await settle();quiet();demo.life.set_process(false)
		print("COLOR_AB withdrawn ",kind);await observe(node,kind+"_withdrawn",7.)
		check(node.spatial_facts[field]==0. and node.spatial_facts[field+"_sources"].is_empty() and is_equal_approx(node.values[layer],.35),"withdrawn facts and finite color tail "+kind)
		await capture(kind+"_withdrawn");await key(KEY_Z,true);await settle();quiet();demo.life.set_process(false)
		print("COLOR_AB undo ",kind);await observe(node,kind+"_restored",18.)
		check(city.houses==authored.houses and city.waters==authored.waters and city.placed_landmarks==authored.placed_landmarks and node.spatial_facts[field]>=.55 and node.values[layer]>.65,"native Undo restores geometry and automatic "+field)
		check(node.values.core==1. and node.prepared.signature==signature and node.player.get_instance_id()==player_id and node.player.stream.get_instance_id()==stream_id,"unchanged source core and synchronized player "+kind)
		var pcm:Dictionary=Span.finish(record,OUT+"/"+kind+"_continuous_Master.wav");check(pcm.ok and pcm.seconds>40.,"continuous actual transition PCM "+kind)
		runs.append({"kind":kind,"source_id":node.prepared.manifest.source_id,"signature":signature,"rows":ab_rows.duplicate(true),"pcm":pcm})
		node.stop();await process_frame;await settle()
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and pool()==voices,"personal city and pooled voice limits unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"runs":runs,"manifest":path,"listening_approved":false,"works":demo.collection_directory,"boundary":"automatic same-source color envelopes, real geometry edits and native Undo; no manual gain injection, no new instruments or equal-loudness/human quality claim"}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("COLOR_AB ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}));demo.queue_free();await process_frame;quit(0 if report.ok else 1)

func topology(personal:PackedByteArray,voices:Dictionary,began:int)->void:
	var f:=Fixture.courtyard("ring","none");var city:RefCounted=f.city
	var road:Dictionary=city.add_road([Fixture.ORIGIN+Vector2(-2,3.6),Vector2(16,Fixture.ORIGIN.y+3.6)] as Array[Vector2],"path","none")
	check(road.ok,"legal opposite-wall portal and real cross-river path")
	if not road.ok:quit(1);return
	await show(city,Fixture.ORIGIN+Vector2(3.6,3.6),"桥路与地标 · 空间资格分离");quiet();demo.life.set_process(false);city=demo.state
	var bridge_fact:Dictionary={"bridge":city.roads[0].bridge,"connected":demo.life.connected_houses,"house_ids":city.houses.map(func(h:Dictionary)->String:return str(h.id))}
	check(city.roads[0].bridge and demo.life.connected_houses.has("h1"),"actual published bridge route connects real courtyard")
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://数据/音乐资产/游戏音乐包/20261103_v1/catalog.json"));var requested:Dictionary=GamePlayer.request(demo.music,catalog.packs[0].manifest)
	check(requested.ok,"same-source topology audition accepted")
	if not requested.ok:quit(1);return
	var node:Node=requested.node;check(await wait_for(func():return node.active,30000),"topology packet activates")
	if not node.active:quit(1);return
	var signature:String=node.prepared.signature;var player_id:int=node.player.get_instance_id();var original:Dictionary=city.snapshot();var record:=Span.start();ab_rows=[]
	await observe(node,"bridge_connected",18.);var enclosure:float=node.spatial_facts.enclosure
	check(enclosure==1. and node.values.body>.95,"connected court warm expression")
	var result:Dictionary=city.remove_road(road.road_id);check(result.ok,"actual bridge removal");demo._after_edit(result,"road");await settle();quiet();demo.life.set_process(false)
	await observe(node,"bridge_removed",3.)
	check(not demo.life.connected_houses.has("h1") and node.spatial_facts.enclosure==enclosure and node.values.body>.95,"disconnected eligibility does not mute true enclosure geometry")
	await key(KEY_Z,true);await settle();quiet();demo.life.set_process(false);await observe(node,"bridge_restored",3.)
	check(city.roads==original.roads and demo.life.connected_houses.has("h1") and node.spatial_facts.enclosure==enclosure,"native Undo restores bridge and public connection without changing court facts")
	result=city.PlacedLandmarks.place(city,"courtyard",Vector2(-14,-28));check(result.ok,"actual distant independent landmark through public placement")
	demo._after_edit(result,"landmark");await settle();quiet();demo.life.set_process(false);await observe(node,"landmark_placed",3.)
	check(city.placed_landmarks.size()==1 and node.spatial_facts.enclosure==enclosure and node.values.core==1. and node.prepared.ids==["core","body","motion","detail"],"independent landmark preserves implemented four-layer packet rather than inventing a P4 voice")
	await capture("bridge_and_landmark");await key(KEY_Z,true);await settle();quiet();demo.life.set_process(false);await observe(node,"landmark_undo",3.)
	check(city.placed_landmarks==original.placed_landmarks and node.prepared.signature==signature and node.player.get_instance_id()==player_id,"landmark Undo keeps original content and player identity")
	var pcm:Dictionary=Span.finish(record,OUT+"/topology_continuous_Master.wav");check(pcm.ok,"continuous actual bridge landmark transition PCM")
	check(personal==FileAccess.get_file_as_bytes(State.DEFAULT_PATH) and pool()==voices,"personal save and original voice limits unchanged")
	var report:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"seconds":(Time.get_ticks_msec()-began)/1000.,"bridge_fact":bridge_fact,"rows":ab_rows,"pcm":pcm,"listening_approved":false,"boundary":"bridge eligibility versus true enclosure; distant independent landmark and original four-layer candidate; no claim that a new P4 musical part is implemented","works":demo.collection_directory}
	FileAccess.open(OUT+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("TOPOLOGY_AB ",JSON.stringify({"ok":report.ok,"checks":checks,"failures":failures}));node.stop();demo.queue_free();await process_frame;quit(0 if report.ok else 1)
